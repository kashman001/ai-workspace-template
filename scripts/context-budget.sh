#!/usr/bin/env bash
# File: scripts/context-budget.sh
# Purpose: Measure the current agent session's context-window usage from its
#          on-disk transcript and compare it against the workspace "dumb zone"
#          threshold. Agents invoke this at checkpoints — they never estimate
#          their own usage (they can't; the numbers live in the API envelope).
# Usage:   context-budget.sh check|register|record|watch|release|close|supervised
#            [--runtime claude|codex|copilot-vscode|copilot-cli|gemini|opencode|auto]
#            [--transcript <path>] [--project <work-item>] [--label "<text>"]
#            [--parent-session <sid>] [--agent-id <id>] [--takeover]
#            [--interval <secs>] [--quiet]
#            [--session-id <sid>]   (check only; read-only pin on a NAMED session)
#            [--check]              (close only; run the checks, write nothing)
#          The fleet verbs (children, dispatch-*) live in scripts/fleet.sh.
#          register/release/close write the work item's session record
#          (work/<item>/session-state.json, block `session`) through
#          scripts/lib/session-lib.sh; seq-sync/opts-sync/rollover-complete
#          were retired with the side files they wrote (Stage 4 phase 3).
# Output:  runtime= method= tokens= threshold= warn= pct= status= artifact=
# Exit:    0 OK / 1 WARN / 2 STOP / 3 error / 4 refused (`reason=<code>` on
#          stderr: jq_missing, not_owner, ledger_seq_mismatch, ledger_shape,
#          and the record library's codes). release exits 1 for a non-owner.
# Design notes: D1–D9 in docs/archive/context-budget-design.html + docs/context-budget.md.

set -u

# Workspace identity = repository identity, not checkout path (issue 05):
# resolve through git's common dir so every worktree converges on the main
# checkout's coordination state. Fallbacks: not a git repo (template pre-
# `git init`), or the git root is not this workspace (workspace nested in an
# unrelated repo) — then the checkout containing the script is the root.
resolve_workspace_root() {  # $1 = script-relative candidate root
  local root common repo
  root="$(cd "$1" && pwd -P)"
  if common="$(git -C "$root" rev-parse --git-common-dir 2>/dev/null)"; then
    case "$common" in /*) : ;; *) common="$root/$common" ;; esac
    repo="$(cd "$common/.." 2>/dev/null && pwd -P)"
    if [ -n "$repo" ] && [ -f "$repo/scripts/context-budget.sh" ]; then
      printf '%s' "$repo"; return
    fi
  fi
  printf '%s' "$root"
}
WORKSPACE_ROOT="$(resolve_workspace_root "$(dirname "$0")/..")"
STATE_DIR="$WORKSPACE_ROOT/.context-budget"
LEDGER="$STATE_DIR/context-ledger.jsonl"
# The record helper: one function, `session_record_update` (Stage 4 phase 1).
# Sourced from beside this script, so a worktree copy finds its own.
. "$(cd "$(dirname "$0")" && pwd -P)/lib/session-lib.sh"
# One-time migration (2026-08-11, backlog M19): the ledger used to live in
# work/context-decay/ — a research dir adopters prune. Fold any old ledger
# into the new location so measurement history stays in one file.
_cb_old_ledger="$WORKSPACE_ROOT/work/context-decay/context-ledger.jsonl"
if [ -f "$_cb_old_ledger" ]; then
  mkdir -p "$STATE_DIR"
  cat "$_cb_old_ledger" >> "$LEDGER" && rm -f "$_cb_old_ledger"
fi

# Precedence is per-variable: explicit env > context-budget.env > built-in
# default (same capture/restore pattern as launch-next-session.sh).
EXPLICIT_TOTAL="${CONTEXT_DUMB_ZONE_TOKENS:-}"
EXPLICIT_WARN="${CONTEXT_DUMB_ZONE_WARN_TOKENS:-}"
EXPLICIT_STALE="${CONTEXT_LOCK_STALE_SECS:-}"
if [ -f "$WORKSPACE_ROOT/context-budget.env" ]; then
  . "$WORKSPACE_ROOT/context-budget.env" >/dev/null 2>&1 || true
fi
[ -n "$EXPLICIT_TOTAL" ] && CONTEXT_DUMB_ZONE_TOKENS="$EXPLICIT_TOTAL"
[ -n "$EXPLICIT_WARN" ] && CONTEXT_DUMB_ZONE_WARN_TOKENS="$EXPLICIT_WARN"
[ -n "$EXPLICIT_STALE" ] && CONTEXT_LOCK_STALE_SECS="$EXPLICIT_STALE"
THRESHOLD="${CONTEXT_DUMB_ZONE_TOKENS:-150000}"
WARN="${CONTEXT_DUMB_ZONE_WARN_TOKENS:-$(( THRESHOLD * 80 / 100 ))}"
LOCK_STALE="${CONTEXT_LOCK_STALE_SECS:-10800}"

COMMAND="check"; RUNTIME="auto"; ARTIFACT=""; PROJECT=""; LABEL=""; INTERVAL=30; QUIET=0
# Set by copilot_vscode_discover when it pins by newest-mtime while >1 Copilot
# session is concurrently active (no authoritative id) — an unsafe guess.
COPILOT_PIN_AMBIGUOUS=0
PARENT_SESSION=""; AGENT_ID=""; TAKEOVER=0; CHECK=0
# --session-id: ask the budget question about a session that is NOT this
# process. check only, and never a writer — see the guard below resolve_session.
PIN_SESSION_ID=""
case "${1:-}" in
  check|register|record|watch|release|close|supervised) COMMAND="$1"; shift ;;
  children|dispatch-contract|dispatch-open|dispatch-close|dispatch-list)
    echo "error: $1 moved to scripts/fleet.sh — run: scripts/fleet.sh $1 [options]" >&2; exit 3 ;;
  seq-sync|opts-sync|rollover-complete)
    echo "error: $1 was retired (Stage 4 phase 3) — the session record work/<item>/session-state.json replaced the counter, the options file and the sentinel; see register/release/close" >&2; exit 3 ;;
esac
while [ $# -gt 0 ]; do
  case "$1" in
    --runtime) RUNTIME="$2"; shift 2 ;;
    --transcript) ARTIFACT="$2"; shift 2 ;;
    --project) PROJECT="$2"; shift 2 ;;
    --parent-session) PARENT_SESSION="$2"; shift 2 ;;
    --session-id) PIN_SESSION_ID="$2"; shift 2 ;;
    --agent-id) AGENT_ID="$2"; shift 2 ;;
    --takeover) TAKEOVER=1; shift ;;
    --check) CHECK=1; shift ;;
    --label) LABEL="$2"; shift 2 ;;
    --interval) INTERVAL="$2"; shift 2 ;;
    --quiet) QUIET=1; shift ;;
    *) echo "unknown option: $1" >&2; exit 3 ;;
  esac
done

note() { [ "$QUIET" -eq 1 ] || echo "$@" >&2; }
die()  { echo "error: $*" >&2; exit 3; }
# Refusal: exit 4 with a reason code, detail as key=value on the same line.
refuse() { echo "context-budget: refused reason=$1${2:+ $2}" >&2; exit 4; }
# jq is a hard requirement (phase 0), checked before anything is read or written.
command -v jq >/dev/null 2>&1 || refuse jq_missing "jq is required"
[ "$CHECK" -eq 0 ] || [ "$COMMAND" = close ] \
  || die "--check is the dry run of close only (got: $COMMAND)"

# The pin names a session other than this one, so every command that WRITES is
# refused: register/record under a pin would stamp this process's measurement
# onto a foreign identity, which is M13 with extra steps. And two identities in
# one invocation is ambiguous -- silently preferring either is how a read ends
# up measuring a session nobody asked about.
if [ -n "$PIN_SESSION_ID" ]; then
  [ "$COMMAND" = check ] \
    || die "--session-id is a read-only pin and works with check only (got: $COMMAND)"
  [ -z "$ARTIFACT" ] \
    || die "--session-id and --transcript both name a session; pass one"
fi

newest_of() { ls -t "$@" 2>/dev/null | head -1; }

glob_artifact_for() {
  # $1 = runtime, $2 = session id. Id-keyed artifact resolution across every
  # project slug dir — survives EnterWorktree relocating a claude transcript
  # to the worktree's slug mid-session (M16). The id is unique, so this never
  # binds a sibling; the newest match wins when a stale copy remains at the
  # old path. rc 1 when the runtime's artifacts don't relocate or no match.
  local rt="$1" sid="$2" f
  [ -n "$sid" ] || return 1
  case "$rt" in
    claude) f=$(newest_of "$HOME"/.claude/projects/*/"$sid".jsonl) ;;
    *) return 1 ;;
  esac
  [ -n "$f" ] && [ -f "$f" ] && echo "$f"
}

claude_discover() {
  local slug proj t
  slug="$(pwd | tr '/.' '--')"
  proj="$HOME/.claude/projects/$slug"
  # Transcript basename = the exported session id; newest-mtime alone races
  # with a concurrent session in the same workspace. The id-keyed glob also
  # finds a transcript EnterWorktree relocated out of the cwd slug (M16).
  if [ -n "${CLAUDE_CODE_SESSION_ID:-}" ]; then
    t=$(glob_artifact_for claude "$CLAUDE_CODE_SESSION_ID") && { echo "$t"; return 0; }
  fi
  [ -d "$proj" ] || return 1
  newest_of "$proj"/*.jsonl
}

codex_discover() {
  local base f
  base="$HOME/.codex/sessions"
  [ -d "$base" ] || return 1
  # CODEX_THREAD_ID is exported to every shell Codex spawns and equals the UUID
  # suffix of this session's own rollout filename; newest-mtime alone races with
  # a concurrent session in the same workspace.
  if [ -n "${CODEX_THREAD_ID:-}" ]; then
    f="$(find "$base" -name "rollout-*-${CODEX_THREAD_ID}.jsonl" 2>/dev/null | head -1)"
    [ -n "$f" ] && [ -f "$f" ] && { echo "$f"; return 0; }
  fi
  while IFS= read -r f; do
    if head -c 8192 "$f" 2>/dev/null | grep -qF "$(pwd)"; then echo "$f"; return 0; fi
  done < <(find "$base" -name 'rollout-*.jsonl' -mtime -7 2>/dev/null | xargs ls -t 2>/dev/null)
  # No cwd-matching rollout: fail rather than bind another project's session.
  return 1
}

copilot_vscode_discover() {
  # Copilot terminal sessions export VSCODE_TARGET_SESSION_LOG. On some builds it
  # is the token .jsonl itself; on others (Copilot 0.58+/VS Code 1.130) it is a
  # debug-logs dir whose basename is the session id — and the chatSessions token
  # file is named after that same id. Either way we pin the live session
  # deterministically instead of racing on newest-mtime, which pins a stale
  # sibling session whose log happened to flush later (the silent-freeze bug),
  # or — at session start, before VS Code has flushed our own token file — a
  # *larger* sibling, producing a false STOP (fresh-session false-STOP bug).
  local t="${VSCODE_TARGET_SESSION_LOG:-}" sid=""
  if [ -n "$t" ]; then
    [ -f "$t" ] && { echo "$t"; return 0; }
    sid="$(basename "$t")"; sid="${sid%.jsonl}"
    # Authoritative id in hand: the token file is
    # <workspaceStorage>/<hash>/chatSessions/<sid>.jsonl, fully determined by $t
    # (exact root, no workspaceStorage listing — sandboxed terminals block
    # readdir on that parent). Return it whether or not it exists yet: a fresh
    # session must measure as ITSELF (0 tokens), never a sibling by newest-mtime
    # (fatal with concurrent sessions).
    case "$t" in
      */workspaceStorage/*/GitHub.copilot-chat/debug-logs/*)
        echo "${t%/GitHub.copilot-chat/debug-logs/*}/chatSessions/$sid.jsonl"
        return 0 ;;
    esac
  fi
  local root ws d
  for root in "Code" "Code - Insiders" "VSCodium"; do
    ws="$HOME/Library/Application Support/$root/User/workspaceStorage"
    [ -d "$ws" ] || continue
    for d in "$ws"/*/; do
      [ -f "$d/workspace.json" ] || continue
      if grep -qF "$(pwd)" "$d/workspace.json" 2>/dev/null; then
        # Authoritative sid (VSCODE_TARGET_SESSION_LOG in .jsonl form): its own
        # token file, existing or not. Only with NO sid may we fall back to
        # newest-mtime — a last resort unsafe across concurrent sessions, so it
        # never runs once an sid is known.
        [ -n "$sid" ] && { echo "$d""chatSessions/$sid.jsonl"; return 0; }
        # No authoritative id (VSCODE_TARGET_SESSION_LOG absent — e.g. an agent's
        # run_in_terminal shell, which does not export it). If >1 chatSessions
        # file was written in the last 2 min, sibling sessions are live and
        # newest-mtime would pin the wrong one (false STOP off another context).
        # Flag it so register refuses to guess (resolve_session).
        if [ "$(find "${d}chatSessions" -name '*.jsonl' -mmin -2 2>/dev/null | wc -l | tr -d ' ')" -gt 1 ]; then
          COPILOT_PIN_AMBIGUOUS=1
          note "warning: multiple Copilot sessions active and VSCODE_TARGET_SESSION_LOG unset — pinning by newest-mtime may bind a sibling session's context"
        fi
        newest_of "$d"chatSessions/*.jsonl "$d"chatSessions/*.json && return 0
      fi
    done
  done
  return 1
}

copilot_cli_discover() {
  # Best-effort/unverified against a live install: paths + env var are sourced
  # from the CLI changelog, not probed. COPILOT_AGENT_SESSION_ID (CLI >=1.0.29)
  # is exported to shell commands and names this session's session-state dir;
  # newest-mtime alone races a concurrent session.
  local root d
  root="${COPILOT_HOME:-$HOME/.copilot}"
  if [ -n "${COPILOT_AGENT_SESSION_ID:-}" ]; then
    local t="$root/session-state/$COPILOT_AGENT_SESSION_ID/events.jsonl"
    [ -f "$t" ] && { echo "$t"; return 0; }
  fi
  # Current format (session-state/) then legacy (history-session-state/).
  for d in "$root/session-state" "$root/history-session-state"; do
    [ -d "$d" ] || continue
    find "$d" -type f \( -name '*.json' -o -name '*.jsonl' \) 2>/dev/null | xargs ls -t 2>/dev/null | head -1 && return 0
  done
  return 1
}

gemini_discover() {
  # Workspace telemetry log first (exact counts; wired in .gemini/settings.json),
  # else the global chat log (estimate-only).
  local t="$WORKSPACE_ROOT/.gemini/telemetry.log"
  [ -s "$t" ] && { echo "$t"; return 0; }
  local base="$HOME/.gemini/tmp"
  [ -d "$base" ] || return 1
  find "$base" -name 'logs.json' 2>/dev/null | xargs ls -t 2>/dev/null | head -1
}

estimate_from_size() {
  local bytes
  bytes=$(stat -f%z "$1" 2>/dev/null || stat -c%s "$1" 2>/dev/null) || return 1
  echo "$(( bytes / 4 )) estimate"
}

claude_measure() {
  local f="$1" jq_prog tokens
  # Sidechain (sub-agent) entries excluded — separate windows. tail-then-full
  # keeps multi-MB transcripts fast.
  jq_prog='[.[] | select(.message.usage.input_tokens != null) | select(.isSidechain != true)]
    | last | if . == null then empty else
      (.message.usage.input_tokens + (.message.usage.cache_read_input_tokens // 0)
       + (.message.usage.cache_creation_input_tokens // 0)) end'
  tokens=$(tail -n 2000 "$f" | jq -s -r "$jq_prog" 2>/dev/null)
  [ -z "$tokens" ] && tokens=$(jq -s -r "$jq_prog" "$f" 2>/dev/null)
  [ -n "$tokens" ] && echo "$tokens exact" || estimate_from_size "$f"
}

codex_measure() {
  local f="$1" tokens
  tokens=$(grep -o '"last_token_usage":{[^}]*}' "$f" 2>/dev/null | tail -1 \
    | grep -o '"total_tokens":[0-9]*' | grep -o '[0-9]*$')
  [ -n "$tokens" ] && echo "$tokens exact" || estimate_from_size "$f"
}

copilot_vscode_measure() {
  local f="$1" tokens
  # Authoritative token file not flushed yet (fresh session at register time):
  # report empty context, never fail or bind a sibling's transcript.
  [ -f "$f" ] || { echo "0 fresh"; return 0; }
  # grep -o, not jq: multi-MB single-line records; survives nesting changes.
  tokens=$(grep -o '"promptTokens":[0-9]*' "$f" 2>/dev/null | tail -1 | grep -o '[0-9]*$')
  [ -n "$tokens" ] && echo "$tokens exact" || estimate_from_size "$f"
}

copilot_cli_measure() {
  local f="$1" tokens
  tokens=$(grep -o '"\(promptTokens\|input_tokens\|inputTokens\)":[0-9]*' "$f" 2>/dev/null \
    | tail -1 | grep -o '[0-9]*$')
  [ -n "$tokens" ] && echo "$tokens exact" || estimate_from_size "$f"
}

gemini_measure() {
  local f="$1" tokens
  case "$f" in *telemetry.log)
    # OTLP file export: last response's input tokens = live context. Two attribute
    # spellings: legacy api_response `input_token_count`, OTel semconv
    # `gen_ai.usage.input_tokens` (0.46 logs use gen_ai.* names).
    tokens=$(grep -o '"\(input_token_count\|gen_ai\.usage\.input_tokens\)": *[0-9]*' "$f" 2>/dev/null \
      | tail -1 | grep -o '[0-9]*$')
    [ -n "$tokens" ] && { echo "$tokens exact"; return 0; }
    # No completed response yet — the telemetry log's size says nothing about
    # context; estimate from the newest chat log instead.
    f=$(find "$HOME/.gemini/tmp" -name 'logs.json' 2>/dev/null | xargs ls -t 2>/dev/null | head -1)
    # Fresh session with no responses and no chat log: context is empty.
    [ -n "$f" ] || { echo "0 estimate"; return 0; } ;;
  esac
  estimate_from_size "$f"
}

opencode_discover() {
  local db="$HOME/.local/share/opencode/opencode.db"
  [ -f "$db" ] && echo "$db"
}

opencode_measure() {
  # $1 = opencode.db (sqlite, verified v1.18.14). Context size = last assistant
  # message's tokens.total (= input+output+reasoning+cache.read) for the
  # session in OPENCODE_SESSION_ID (exported by the chat.message plugin);
  # fallback: newest session for this cwd. No size-estimate fallback — the
  # shared db spans all sessions, its size says nothing about one context.
  local db="$1" sid="${OPENCODE_SESSION_ID:-}" tokens dir_sql sid_sql
  command -v sqlite3 >/dev/null 2>&1 || return 1
  dir_sql="${PWD//\'/\'\'}"  # SQL-escape embedded single quotes
  [ -n "$sid" ] || sid=$(sqlite3 "$db" \
    "select id from session where directory='$dir_sql' order by time_updated desc limit 1" 2>/dev/null)
  [ -n "$sid" ] || return 1
  sid_sql="${sid//\'/\'\'}"
  tokens=$(sqlite3 "$db" "select json_extract(data,'\$.tokens.total') from message
    where session_id='$sid_sql' and json_extract(data,'\$.tokens.total') is not null
    order by rowid desc limit 1" 2>/dev/null)
  if [ -z "$tokens" ]; then
    tokens=$(sqlite3 "$db" "select tokens_input+tokens_output+tokens_reasoning+tokens_cache_read
      from session where id='$sid_sql'" 2>/dev/null)
  fi
  [ -n "$tokens" ] && echo "$tokens exact" || return 1
}

detect_runtime() {
  if [ -n "${CLAUDECODE:-}" ] || [ -n "${CLAUDE_CODE_ENTRYPOINT:-}" ]; then echo "claude"; return; fi
  if [ -n "${CODEX_SANDBOX:-}" ] || [ -n "${CODEX_HOME:-}" ]; then echo "codex"; return; fi
  if [ -n "${OPENCODE_SESSION_ID:-}" ]; then echo "opencode"; return; fi
  # VSCODE_TARGET_SESSION_LOG is Copilot-chat-terminal specific and
  # authoritative; trust it over the newest-file heuristic, which at session
  # start (our token file not flushed) would misdetect a stale sibling runtime.
  if [ -n "${VSCODE_TARGET_SESSION_LOG:-}" ]; then echo "copilot-vscode"; return; fi
  local best_rt="" best_file="" f
  for rt in claude codex copilot-vscode copilot-cli gemini; do
    f=$(discover_for "$rt") || continue
    [ -n "$f" ] || continue
    if [ -z "$best_file" ] || [ "$f" -nt "$best_file" ]; then best_rt="$rt"; best_file="$f"; fi
  done
  [ -n "$best_rt" ] && echo "$best_rt"
}

discover_for() {
  case "$1" in
    claude) claude_discover ;; codex) codex_discover ;;
    copilot-vscode) copilot_vscode_discover ;; copilot-cli) copilot_cli_discover ;;
    gemini) gemini_discover ;; opencode) opencode_discover ;; *) return 1 ;;
  esac
}

measure_for() {
  case "$1" in
    claude) claude_measure "$2" ;; codex) codex_measure "$2" ;;
    copilot-vscode) copilot_vscode_measure "$2" ;; copilot-cli) copilot_cli_measure "$2" ;;
    gemini) gemini_measure "$2" ;; opencode) opencode_measure "$2" ;; *) return 1 ;;
  esac
}

session_id_for() {
  # $1 = runtime, $2 = artifact path or empty. Env-var identity first (exact,
  # exported by the runtime itself), else derived from the artifact path so the
  # same session resolves to the same id either way. rc 1 when underivable.
  local rt="$1" af="${2:-}" b
  case "$rt" in
    claude)  [ -n "${CLAUDE_CODE_SESSION_ID:-}" ] && { echo "$CLAUDE_CODE_SESSION_ID"; return 0; } ;;
    codex)   [ -n "${CODEX_THREAD_ID:-}" ] && { echo "$CODEX_THREAD_ID"; return 0; } ;;
    copilot-cli) [ -n "${COPILOT_AGENT_SESSION_ID:-}" ] && { echo "$COPILOT_AGENT_SESSION_ID"; return 0; } ;;
    copilot-vscode)
      if [ -n "${VSCODE_TARGET_SESSION_LOG:-}" ]; then
        b="$(basename "$VSCODE_TARGET_SESSION_LOG")"; echo "${b%.jsonl}"; return 0
      fi ;;
    gemini)  echo "workspace"; return 0 ;;  # no per-session identity exists (see docs)
    opencode) [ -n "${OPENCODE_SESSION_ID:-}" ] && { echo "$OPENCODE_SESSION_ID"; return 0; } ;;
  esac
  [ -n "$af" ] || return 1
  session_id_for_artifact_only "$rt" "$af"
}

session_id_for_artifact_only() {
  # $1 = runtime, $2 = artifact path. Artifact-derived identity only (used
  # directly for parent-side child registration, where env identity is the
  # parent's, not the child's).
  local rt="$1" af="$2" b
  b="$(basename "$af")"
  case "$rt" in
    claude)         echo "${b%.jsonl}" ;;
    codex)          b="${b%.jsonl}"; echo "${b#rollout-????-??-??T??-??-??-}" ;;
    copilot-cli)    basename "$(dirname "$af")" ;;
    copilot-vscode) b="${b%.jsonl}"; echo "${b%.json}" ;;
    *) return 1 ;;
  esac
}

resolve_session() {
  # The --session-id pin (P4a plumbing, session-chain-observability spec.md 4.1).
  # A supervisor needs its child's budget level, and it cannot get it by running
  # check in its own environment: that resolves to the caller, or -- when no env
  # identity matches -- to the newest artifact by mtime, which is the false-STOP
  # bug. The pin answers about the session NAMED, or refuses; it never guesses.
  # Read-only by construction: it returns before the re-pin below, and every
  # writing command was refused at the guard after die().
  if [ -n "$PIN_SESSION_ID" ]; then
    local rec cand
    if [ "$RUNTIME" = "auto" ]; then
      # NOT detect_runtime: that reads the ASKER's environment, and a claude
      # supervisor can be running a codex child. The record knows its own.
      rec=$(parent_record_path "$PIN_SESSION_ID") \
        || die "no registered session $PIN_SESSION_ID in $STATE_DIR/sessions"
      RUNTIME=$(jq -r '.runtime // empty' "$rec" 2>/dev/null)
      [ -n "$RUNTIME" ] || die "session record ${rec##*/} names no runtime"
    else
      rec="$STATE_DIR/sessions/$RUNTIME-$PIN_SESSION_ID.json"
      [ -f "$rec" ] || die "no registered session $RUNTIME-$PIN_SESSION_ID in $STATE_DIR/sessions"
    fi
    SESSION_ID="$PIN_SESSION_ID"
    ARTIFACT=$(jq -r '.artifact // empty' "$rec" 2>/dev/null)
    # M16: the recorded path stales when a transcript is relocated mid-session.
    # Adopt the freshest id-keyed match as the read below does -- but do not
    # write the record back, which is the one thing the pinned path must not do.
    if cand=$(glob_artifact_for "$RUNTIME" "$SESSION_ID") \
       && { [ ! -f "$ARTIFACT" ] || [ "$cand" -nt "$ARTIFACT" ]; }; then
      ARTIFACT="$cand"
    fi
    [ -n "$ARTIFACT" ] && [ -f "$ARTIFACT" ] \
      || die "session $RUNTIME-$PIN_SESSION_ID has no readable artifact"
    return 0
  fi
  if [ "$RUNTIME" = "auto" ]; then
    RUNTIME=$(detect_runtime)
    [ -n "$RUNTIME" ] || die "could not detect runtime; pass --runtime"
  fi
  # Child registration is parent-side: the registering process is the parent,
  # so the child's identity must come from its artifact, never the env.
  if [ -n "$PARENT_SESSION" ]; then
    [ -n "$ARTIFACT" ] && [ -f "$ARTIFACT" ] \
      || die "--parent-session requires --transcript <child artifact>"
    SESSION_ID="$(session_id_for_artifact_only "$RUNTIME" "$ARTIFACT")" \
      || die "cannot derive child session id from $ARTIFACT"
    return 0
  fi
  SESSION_ID="$(session_id_for "$RUNTIME" "")" || SESSION_ID=""
  # Resolve-self: only this session's own file is ever trusted — the scalar
  # per-runtime registry let session A measure session B's artifact (M13).
  # register must always re-discover; the registry is what it's there to (re)write.
  if [ -z "$ARTIFACT" ] && [ "$COMMAND" != "register" ] && [ -n "$SESSION_ID" ]; then
    local reg="$STATE_DIR/sessions/$RUNTIME-$SESSION_ID.json" cand
    if [ -f "$reg" ]; then
      ARTIFACT=$(jq -r '.artifact // empty' "$reg" 2>/dev/null)
      # M16: EnterWorktree relocates a claude transcript mid-session, staling
      # the pinned path (a stale copy may remain behind). The session id is
      # stable across the move: adopt the freshest id-keyed match and re-pin
      # the record so other sessions' liveness checks read a live path again.
      if cand=$(glob_artifact_for "$RUNTIME" "$SESSION_ID") \
         && [ "$cand" != "$ARTIFACT" ] \
         && { [ ! -f "$ARTIFACT" ] || [ "$cand" -nt "$ARTIFACT" ]; }; then
        ARTIFACT="$cand"
        if jq --arg af "$ARTIFACT" '.artifact = $af' "$reg" > "$reg.tmp" \
           && mv "$reg.tmp" "$reg"; then
          note "artifact moved — re-pinned $RUNTIME-$SESSION_ID to $ARTIFACT"
        else
          rm -f "$reg.tmp"
        fi
      fi
      [ -f "$ARTIFACT" ] || ARTIFACT=""
    fi
  fi
  if [ -z "$ARTIFACT" ]; then
    ARTIFACT=$(discover_for "$RUNTIME") || true
    [ -n "$ARTIFACT" ] || die "no session artifact found for runtime=$RUNTIME"
    # copilot-vscode may return an authoritative-but-not-yet-flushed path at
    # session start; accept it (measures as fresh) rather than dying or, worse,
    # rediscovering into a sibling. Every other runtime requires it to exist.
    [ -f "$ARTIFACT" ] || [ "$RUNTIME" = copilot-vscode ] \
      || die "no session artifact found for runtime=$RUNTIME"
    # register pins identity, so it must never guess: an ambiguous newest-mtime
    # pin here would write a sibling session's context as ours (the false-STOP
    # bug). Fail loud with the fix instead. check/record only warned (above) and
    # fall through — a read is less harmful than a wrong pin, and they prefer the
    # registry when one exists.
    if [ "$COMMAND" = register ] && [ "$RUNTIME" = copilot-vscode ] \
       && [ "$COPILOT_PIN_AMBIGUOUS" = 1 ]; then
      die "cannot identify this Copilot VS Code session: several are active and \$VSCODE_TARGET_SESSION_LOG is unset, so register would pin a sibling and mis-report context. Re-run with the session log, e.g.: VSCODE_TARGET_SESSION_LOG=\"<...>/GitHub.copilot-chat/debug-logs/<your-session-id>\" scripts/context-budget.sh register"
    fi
  fi
  [ -n "$SESSION_ID" ] || SESSION_ID="$(session_id_for "$RUNTIME" "$ARTIFACT")" || SESSION_ID="unknown"
}

emit_check() {
  local tokens method status pct
  read -r tokens method < <(measure_for "$RUNTIME" "$ARTIFACT") || die "measurement failed"
  [ -n "$tokens" ] || die "measurement failed for $ARTIFACT"
  if [ "$tokens" -ge "$THRESHOLD" ]; then status="STOP"
  elif [ "$tokens" -ge "$WARN" ]; then status="WARN"
  else status="OK"; fi
  pct=$(( tokens * 100 / THRESHOLD ))
  echo "runtime=$RUNTIME method=$method tokens=$tokens threshold=$THRESHOLD warn=$WARN pct=$pct status=$status artifact=$ARTIFACT"
  LAST_TOKENS="$tokens"; LAST_METHOD="$method"; LAST_STATUS="$status"
  case "$status" in OK) return 0 ;; WARN) return 1 ;; STOP) return 2 ;; esac
}

# P1' (session-chain-observability, B1) — a supervised session that is past its
# budget with nothing staged cannot see, from the inside, that its chain is
# about to strand: the handshake it believes it completed left no successor.
# record/register are the two commands the workspace discipline already makes an
# agent run at every boundary, so the fact is delivered there rather than in a
# skill file that three incidents show is not opened at the moment of need.
#
# Three legs, all necessary. The budget leg is load-bearing: without it the
# predicate is "supervisor live AND nothing staged", which is true of every
# healthy session for its whole life, because session-loop.sh consumes
# .next-command BEFORE the run. Neither of the other two is agent-authored --
# .next-command is written only by --emit, the budget is measured from the
# transcript -- so there is nothing here to talk your way past.
#
# stderr only (like note(), and suppressed by --quiet), and exit codes are
# untouched: 0/1/2 keep meaning OK/WARN/STOP. That is deliberate, and it is the
# difference from the rejected P5 -- this never tells a compliant rollover it
# did something wrong.
#
# NOT in emit_check(): cmd_watch calls that for OTHER sessions,
# where .next-command says nothing about the caller.
successor_advisory() {
  case "$LAST_STATUS" in WARN|STOP) ;; *) return 0 ;; esac
  local proj="$PROJECT" rec="$STATE_DIR/sessions/$RUNTIME-$SESSION_ID.json"
  # `record --label "<checkpoint>"` is prescribed without --project, so fall
  # back to this session's OWN record -- cmd_release's idiom, never a
  # newest-mtime guess at whose project this is.
  [ -n "$proj" ] || proj=$(jq -r '.project // empty' "$rec" 2>/dev/null)
  [ -n "$proj" ] || return 0
  # A sub-agent is not the chain: it has no successor to stage, and telling it
  # to stage the parent's would be the wrong signal.
  [ -n "$(jq -r '.parent_session_id // empty' "$rec" 2>/dev/null)" ] && return 0
  # Strictly 0. An ambiguous 2 stays silent: a spurious advisory is cheap, but a
  # wrong one trains the reader to ignore the signal. Subshell so a die() inside
  # the query cannot take the caller down with it.
  ( PROJECT="$proj" cmd_supervised ) >/dev/null 2>&1 || return 0
  [ -s "$WORKSPACE_ROOT/work/$proj/.next-command" ] && return 0
  # Two-sided by necessity: the predicate is also true throughout H3, a session
  # that has decided to END the chain -- which is a correct ending, not a fault.
  note "successor: NOT STAGED — this chain continues only if you stage one."
  note "  to continue: scripts/launch-next-session.sh $proj --emit --loop-mode <interactive|handsoff> --loop-reason \"<why>\""
  note "  to end it:   quit. A deliberate quit with nothing staged ends the chain (that is a correct ending)."
}

lock_holder_age() {
  # Age in seconds of the lock holder's artifact (its liveness signal), via the
  # holder's own session file; rc 1 when unknowable (treated as stale — a
  # holder with no artifact anywhere cannot be confirmed live). The recorded
  # path can be stale mid-session (EnterWorktree relocation, M16): trust the
  # freshest of the recorded path and the id-keyed glob.
  local rt="$1" sid="$2" af mt cand
  af=$(jq -r '.artifact // empty' "$STATE_DIR/sessions/$rt-$sid.json" 2>/dev/null)
  if cand=$(glob_artifact_for "$rt" "$sid") \
     && { [ ! -f "$af" ] || [ "$cand" -nt "$af" ]; }; then
    af="$cand"
  fi
  [ -n "$af" ] && [ -f "$af" ] || return 1
  mt=$(stat -f%m "$af" 2>/dev/null || stat -c%Y "$af" 2>/dev/null) || return 1
  echo $(( $(date +%s) - mt ))
}

parent_record_path() {
  # $1 = parent session id -> its registry record path (any runtime; mixed
  # fleets register children under a parent from another runtime).
  local f
  for f in "$STATE_DIR/sessions/"*.json; do
    [ -f "$f" ] || continue
    [ "$(jq -r '.session_id // empty' "$f" 2>/dev/null)" = "$1" ] && { echo "$f"; return 0; }
  done
  return 1
}
# D8/R2.10 — give the project lock a process identity. The refusal in
# launch-next-session.sh ("held by LIVE session …, roll over from the holding
# session instead") is correct but unactionable when the holder is a detached
# child the operator never started: liveness here is artifact-mtime based, so
# nothing in the machinery held a handle on the holder at all.
#
# $PPID is useless — register runs from a SessionStart hook whose parent is a
# throwaway shell — so walk the ancestry for the runtime binary. Measured shape
# (session 23, live chain): hook shell -> `claude …` -> `bash scripts/session-loop.sh`.
# The runtime's PARENT is therefore the supervisor when there is one, because
# session-loop.sh runs its child in the foreground; that gives the refusal the
# "is anything supervising it" half for free.
#
# This adds a NAME, not a second liveness authority: artifact mtime stays the
# predicate for who holds the lock (TE6 R1). Never fails the caller — an
# unresolvable pid degrades to today's message.
RUNTIME_PID=""; RUNTIME_PID_START=""; SUPERVISOR_PID=""
resolve_runtime_pid() {
  RUNTIME_PID=""; RUNTIME_PID_START=""; SUPERVISOR_PID=""
  # copilot-vscode has no runtime process to find: the "session" is VS Code
  # itself, which an operator must not be told to kill.
  [ "$RUNTIME" = "copilot-vscode" ] && return 0
  local p="$$" hops=0 ppid cmd argv0
  while [ "${p:-0}" -gt 1 ] && [ "$hops" -lt 12 ]; do
    hops=$((hops + 1))
    ppid=$(ps -o ppid= -p "$p" 2>/dev/null | tr -d ' ')
    [ -n "$ppid" ] || return 0
    cmd=$(ps -o command= -p "$p" 2>/dev/null)
    argv0=${cmd%% *}; argv0=${argv0##*/}
    if [ "$argv0" = "$RUNTIME" ]; then
      RUNTIME_PID="$p"
      # pid_start is not decoration: pids are recycled and a lock record
      # outlives its process by construction, so a bare pid would eventually
      # name an unrelated process with confidence.
      RUNTIME_PID_START=$(ps -o lstart= -p "$p" 2>/dev/null | sed 's/^ *//;s/ *$//')
      cmd=$(ps -o command= -p "$ppid" 2>/dev/null)
      case "$cmd" in *session-loop.sh*) SUPERVISOR_PID="$ppid" ;; esac
      return 0
    fi
    p="$ppid"
  done
  return 0
}

# ---- the work item's session record (work/<item>/session-state.json) --------
record_path() { printf '%s' "$WORKSPACE_ROOT/work/$1/session-state.json"; }

# Ledger grammar, copied from launch-next-session.sh (which mirrors
# check-ledger.py): the top "# Session Handoff" heading's session number.
ledger_file() {  # $1 = project
  local hf
  for hf in "$WORKSPACE_ROOT/work/$1/handoff.md" "$WORKSPACE_ROOT/work/$1/session_handoff.md"; do
    [ -f "$hf" ] && { printf '%s' "$hf"; return 0; }
  done
  return 1
}
top_ledger_session() {
  grep -m1 -E '^#[[:space:]]*Session Handoff' "$1" 2>/dev/null \
    | sed -E 's/[0-9]{4}-[0-9]{2}-[0-9]{2}//g' \
    | grep -oiE 'session[[:space:]]+#?[0-9]+|^#[[:space:]]*session handoff[[:space:]]*[—-][[:space:]]*s?[0-9]+' \
    | head -1 | grep -oE '[0-9]+' | head -1 || true
}

launcher_hash() {  # $1 = project; digest of next-session.md, empty when absent
  local f="$WORKSPACE_ROOT/work/$1/next-session.md"
  [ -f "$f" ] || return 0
  if command -v shasum >/dev/null 2>&1; then shasum -a 256 "$f" | cut -d' ' -f1
  elif command -v sha256sum >/dev/null 2>&1; then sha256sum "$f" | cut -d' ' -f1
  else cksum "$f" | cut -d' ' -f1; fi
}

session_block_json() {  # $1 = seq -> this session's `session` block
  jq -cn --argjson seq "$1" --arg rt "$RUNTIME" --arg sid "$SESSION_ID" --arg af "$ARTIFACT" \
    --arg ts "$(date -u +%FT%TZ)" --arg lh "$(launcher_hash "$PROJECT")" \
    --arg user "$USER@$(hostname -s)" --arg pid "$RUNTIME_PID" --arg pstart "$RUNTIME_PID_START" \
    '{seq:$seq, runtime:$rt, session_id:$sid}
     + (if $pid == "" then {} else {pid:($pid|tonumber), pid_start:$pstart} end)
     + {artifact:$af, registered_at:$ts, launcher_hash:$lh, user:$user, ended:null}'
}

# Liveness of a recorded owner: the pid is running AND started when the record
# says (pids recycle). A record without a pid (registered from outside the
# process tree: copilot-vscode, gemini, or a hook whose walk found nothing)
# falls back to the owner's transcript age, as the old lock did.
owner_live() {  # $1 = session block json; 0 live / 1 dead or unknowable
  local pid pstart cur rt sid age
  pid=$(printf '%s' "$1" | jq -r '.pid // empty')
  pstart=$(printf '%s' "$1" | jq -r '.pid_start // empty')
  if [ -n "$pid" ]; then
    kill -0 "$pid" 2>/dev/null || return 1
    cur=$(ps -o lstart= -p "$pid" 2>/dev/null | sed 's/^ *//;s/ *$//')
    [ -n "$cur" ] && [ "$cur" = "$pstart" ]
    return
  fi
  rt=$(printf '%s' "$1" | jq -r '.runtime // empty')
  sid=$(printf '%s' "$1" | jq -r '.session_id // empty')
  age=$(lock_holder_age "$rt" "$sid") || return 1
  [ "$age" -lt "$LOCK_STALE" ]
}

# How the successor finds its number (stage3-design-v2 "How the successor finds
# its number"): explicit --project; else TF_SESSION_PROJECT + TF_SESSION_SEQ
# (attached launch, supervisor); else a record whose launch.pending names this
# very process (in-place restart); else nothing — registered project-less,
# measures only. Never a guess from file mtimes.
BOUND=""
bind_work_item() {
  local via="" want_seq="" rec p
  if [ -n "$PROJECT" ]; then
    [ -d "$WORKSPACE_ROOT/work/$PROJECT" ] || die "no such work directory: work/$PROJECT"
    via="project"
  elif [ -n "${TF_SESSION_PROJECT:-}" ]; then
    if [ -z "${TF_SESSION_SEQ:-}" ]; then
      note "register: TF_SESSION_PROJECT=$TF_SESSION_PROJECT without TF_SESSION_SEQ — not bound"
    elif [ ! -d "$WORKSPACE_ROOT/work/$TF_SESSION_PROJECT" ]; then
      note "register: TF_SESSION_PROJECT=$TF_SESSION_PROJECT names no work directory — not bound"
    elif [ ! -f "$(record_path "$TF_SESSION_PROJECT")" ]; then
      note "register: work/$TF_SESSION_PROJECT has no record to bind TF_SESSION_SEQ=$TF_SESSION_SEQ to — not bound"
    else
      PROJECT="$TF_SESSION_PROJECT"; via="env"; want_seq="$TF_SESSION_SEQ"
    fi
  fi
  if [ -z "$via" ] && [ -n "$RUNTIME_PID" ]; then
    for rec in "$WORKSPACE_ROOT"/work/*/session-state.json; do
      [ -f "$rec" ] || continue
      jq -e --argjson pid "$RUNTIME_PID" --arg ps "$RUNTIME_PID_START" \
        '.session == null and .launch.pending.pid == $pid and .launch.pending.pid_start == $ps' \
        "$rec" >/dev/null 2>&1 || continue
      p="${rec%/session-state.json}"; PROJECT="${p##*/}"; via="pending"; break
    done
  fi
  [ -n "$via" ] || return 0
  bind_record "$via" "$want_seq"
  PROJECT="$BOUND"
}

# Fill the `session` block of work/$PROJECT's record, or leave it alone.
# Register never blocks: every outcome is a note, and the exit code stays the
# measurement's. Sets BOUND=$PROJECT when this session now owns the item.
bind_record() {  # $1 = via (project|env|pending), $2 = seq the env demands or empty
  local rec cur seq owner osid ort action loser="" seen_sid=null seen_seq=null hf top block rc=0
  rec="$(record_path "$PROJECT")"
  if [ -f "$rec" ]; then
    cur=$(cat "$rec" 2>/dev/null) || cur=""
    printf '%s' "$cur" | jq -e 'type=="object" and .schema == 1' >/dev/null 2>&1 \
      || { note "register: work/$PROJECT/session-state.json is unreadable or not schema 1 — not bound"; return 0; }
    seq=$(printf '%s' "$cur" | jq -r '.seq // empty')
  else
    seq=""
  fi
  if [ -z "$seq" ]; then
    # Registration may open seq once, on an item that has no record yet, and
    # only when the item was named explicitly: ledger top block + 1, else 1.
    [ "$1" = project ] || { note "register: work/$PROJECT has no numbered record — not bound"; return 0; }
    seq=1
    if hf=$(ledger_file "$PROJECT"); then
      top=$(top_ledger_session "$hf"); [ -n "$top" ] && seq=$((top + 1))
    fi
    action="opened"
  else
    seen_seq="$seq"
    if [ -n "$2" ] && [ "$2" != "$seq" ]; then
      note "register: TF_SESSION_SEQ=$2 but work/$PROJECT record seq=$seq — not bound"; return 0
    fi
    owner=$(printf '%s' "$cur" | jq -c '.session // null')
    if [ "$owner" = null ]; then
      action="filled"
    else
      osid=$(printf '%s' "$owner" | jq -r '.session_id // empty')
      ort=$(printf '%s' "$owner" | jq -r '.runtime // empty')
      seen_sid=$(printf '%s' "$osid" | jq -R .)
      loser="$ort-$osid"
      if [ "$loser" = "$RUNTIME-$SESSION_ID" ]; then
        action="refreshed"
      elif [ "$TAKEOVER" -eq 1 ]; then
        action="takeover"
      elif [ -n "$RUNTIME_PID" ] \
           && [ "$(printf '%s' "$owner" | jq -r '.pid // empty')" = "$RUNTIME_PID" ] \
           && [ "$(printf '%s' "$owner" | jq -r '.pid_start // empty')" = "$RUNTIME_PID_START" ]; then
        action="adopted"     # same process, new session id: an in-place restart
      elif owner_live "$owner"; then
        note "register: reason=owner_live owner=$loser — work/$PROJECT is measured, not owned by $RUNTIME-$SESSION_ID (--takeover to override)"
        return 0
      else
        action="adopted"     # owner dead: the number is kept, the slot is taken
      fi
    fi
  fi
  block=$(session_block_json "$seq")
  # Compare-and-set on what was just read: a record that moved in between is a
  # silent no-op (rc 1), never a blind overwrite. Binding also empties
  # launch.pending — the one cross-block write registration is allowed.
  session_record_update "$rec" \
    '(.seq // null) == $seen_seq and ((.session.session_id) // null) == $seen_sid' \
    '.seq = $seq | .session = $s | (if (.launch | type) == "object" then .launch.pending = null else . end)' \
    --argjson seen_seq "$seen_seq" --argjson seen_sid "$seen_sid" \
    --argjson seq "$seq" --argjson s "$block" || rc=$?
  case "$rc" in
    0) BOUND="$PROJECT"
       case "$action" in
         takeover|adopted) note "register: reason=$action loser=$loser seq=$seq" ;;
       esac
       note "register: bound work/$PROJECT seq=$seq via=$1 ($action)" ;;
    1) note "register: work/$PROJECT/session-state.json changed underneath — not bound" ;;
    *) note "register: could not write work/$PROJECT/session-state.json — not bound" ;;
  esac
  return 0
}

cmd_register() {
  resolve_session
  # D8/R2.10 — resolved once, here, and used by the session block, the
  # registry record and the pending-pid binding below.
  resolve_runtime_pid
  # From a worktree, share local-only work/<item>/ dirs in before the session
  # reads its launcher (backlog L45); prints one line per new link.
  [ -x "$WORKSPACE_ROOT/scripts/link-local-work.sh" ] \
    && "$WORKSPACE_ROOT/scripts/link-local-work.sh" "$PWD" 2>/dev/null
  # Session boundary: the workspace telemetry log is shared append-only and
  # single-session — normally reset it so a new session never reads the previous
  # session's counts. But a non-empty log written in the last 10 min means
  # another live gemini session owns it — don't corrupt its counts; this session
  # degrades to estimate-only from the chat log (docs: "a second concurrent
  # gemini session falls back to estimate-only").
  if [ "$RUNTIME" = "gemini" ] && [ "$ARTIFACT" = "$WORKSPACE_ROOT/.gemini/telemetry.log" ]; then
    local mt age
    mt=$(stat -f%m "$ARTIFACT" 2>/dev/null || stat -c%Y "$ARTIFACT" 2>/dev/null || echo 0)
    age=$(( $(date +%s) - mt ))
    if [ -s "$ARTIFACT" ] && [ "$age" -lt 600 ]; then
      note "gemini: telemetry log active ${age}s ago — concurrent session suspected; falling back to estimate-only"
      ARTIFACT=$(find "$HOME/.gemini/tmp" -name 'logs.json' 2>/dev/null | xargs ls -t 2>/dev/null | head -1)
      [ -n "$ARTIFACT" ] || die "no gemini chat log to fall back to"
    else
      : > "$ARTIFACT"
    fi
  fi
  mkdir -p "$STATE_DIR/sessions"
  rm -f "$STATE_DIR/session-$RUNTIME.json"                      # legacy scalar registry
  find "$STATE_DIR/sessions" -name '*.json' -mtime +7 -delete 2>/dev/null  # dead sessions
  DEPTH=0
  if [ -n "$PARENT_SESSION" ]; then
    local prec
    prec=$(parent_record_path "$PARENT_SESSION") \
      || die "parent session $PARENT_SESSION is not registered"
    DEPTH=$(( $(jq -r '.depth // 0' "$prec" 2>/dev/null) + 1 ))
  else
    # Children never own a work item (fleet is its own module): only a
    # top-level registration binds.
    bind_work_item
  fi
  # The per-session measurement record: what check/record measure from, what
  # the launcher, the supervisor and fleet.sh read. `project` names the item
  # this session OWNS (bound above), never one it merely asked about.
  jq -n --arg rt "$RUNTIME" --arg sid "$SESSION_ID" --arg af "$ARTIFACT" \
    --arg proj "$BOUND" --arg ts "$(date -u +%FT%TZ)" \
    --arg psid "$PARENT_SESSION" --arg aid "$AGENT_ID" --argjson depth "$DEPTH" \
    --arg user "$USER@$(hostname -s)" \
    --arg pid "$RUNTIME_PID" --arg pstart "$RUNTIME_PID_START" \
    --arg sup "$SUPERVISOR_PID" \
    '{runtime:$rt, session_id:$sid, artifact:$af, project:$proj, registered_at:$ts, user:$user}
     + (if $pid == "" then {} else {pid:($pid|tonumber), pid_start:$pstart} end)
     + (if $sup == "" then {} else {supervisor_pid:($sup|tonumber)} end)
     + (if $psid == "" then {} else {parent_session_id:$psid, depth:$depth} end)
     + (if $aid == "" then {} else {agent_id:$aid} end)' \
    > "$STATE_DIR/sessions/$RUNTIME-$SESSION_ID.json"
  note "registered $RUNTIME session $SESSION_ID artifact: $ARTIFACT"
  # SessionStart hooks fire before the runtime writes its first transcript
  # bytes — a missing/empty artifact at register time is expected, not an error.
  if [ ! -s "$ARTIFACT" ]; then
    echo "runtime=$RUNTIME method=deferred tokens=0 threshold=$THRESHOLD warn=$WARN pct=0 status=OK artifact=$ARTIFACT"
    return 0
  fi
  local rc=0
  emit_check || rc=$?
  successor_advisory
  return $rc
}

cmd_record() {
  resolve_session
  # Record-file mtime = time of last measured activity: register's 7-day
  # `-mtime +7` purge must never collect a live, record-ing session's record
  # (R9). `record` at boundaries is the standing workspace discipline, so
  # this one touch keeps every disciplined session's record alive.
  [ -f "$STATE_DIR/sessions/$RUNTIME-$SESSION_ID.json" ] \
    && touch "$STATE_DIR/sessions/$RUNTIME-$SESSION_ID.json"
  local rc=0
  emit_check || rc=$?
  mkdir -p "$(dirname "$LEDGER")"
  jq -cn --arg ts "$(date -u +%FT%TZ)" --arg rt "$RUNTIME" \
    --arg session "$(basename "$ARTIFACT")" --arg method "$LAST_METHOD" \
    --arg status "$LAST_STATUS" --arg label "$LABEL" \
    --argjson tokens "$LAST_TOKENS" --argjson threshold "$THRESHOLD" \
    '{ts:$ts, runtime:$rt, session:$session, tokens:$tokens, method:$method,
      threshold:$threshold, status:$status, label:$label}' >> "$LEDGER"
  successor_advisory
  return $rc
}
# C1 — the supervision query (design.md §3). Read-only, and it NEVER deletes a
# stale marker: sweeping belongs to the supervisor (session-loop.sh:76-82), and
# an agent deleting a marker belonging to a supervisor mid-start would create
# the exact failure this work item exists to remove.
#
# Exit 0 supervised / 1 not supervised / 2 ambiguous. Ambiguity resolves to
# "stage" at the caller (R3): a spurious staged command is harmless, a missing
# one strands the chain. Note die() exits 3, so ambiguity must return, not die.
cmd_supervised() {
  [ -n "$PROJECT" ] || die "supervised: --project is required"
  local loopf="$WORKSPACE_ROOT/work/$PROJECT/.session-loop"
  local pid="" started=""
  if [ -f "$loopf" ]; then
    pid="$(jq -r '.pid // empty' "$loopf" 2>/dev/null)"
    started="$(jq -r '.started_at // empty' "$loopf" 2>/dev/null)"
    if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
      [ "$QUIET" -eq 1 ] || echo "supervised pid=$pid project=$PROJECT started_at=$started"
      return 0
    fi
    [ "$QUIET" -eq 1 ] || echo "ambiguous marker work/$PROJECT/.session-loop exists but pid ${pid:-unknown} is not alive"
    return 2
  fi
  if [ "${TF_SESSION_LOOP_PROJECT:-}" = "$PROJECT" ]; then
    [ "$QUIET" -eq 1 ] || echo "ambiguous TF_SESSION_LOOP_PROJECT names $PROJECT but no .session-loop marker exists"
    return 2
  fi
  [ "$QUIET" -eq 1 ] || echo "unsupervised"
  return 1
}

# The item this session owns: --project, else its own registry record. The
# registry stamps `project` only on a binding registration, so a non-owner
# resolves nothing here (cmd_release's idiom, never a newest-mtime guess).
resolve_own_project() {
  [ -n "$PROJECT" ] && return 0
  PROJECT=$(jq -r '.project // empty' "$STATE_DIR/sessions/$RUNTIME-$SESSION_ID.json" 2>/dev/null)
  [ -n "$PROJECT" ]
}
record_owner() {  # $1 = record path -> "<rt>-<sid>" of the recorded owner ("-" when none)
  jq -r '"\(.session.runtime // "")-\(.session.session_id // "")"' "$1" 2>/dev/null
}

# release: the session-end door (SessionEnd hook, `|| true`). Merges ended.at
# into the record iff it still names the caller; a non-owner is a no-op that
# says so (exit 1 — the lib's "answer was no"), never a write, never a
# refusal a hook would report as a failure.
cmd_release() {
  [ "$TAKEOVER" -eq 0 ] || die "release: --takeover is not a release option — takeover belongs to register (and the launcher)"
  resolve_session
  resolve_own_project || { note "release: no work item bound to $RUNTIME-$SESSION_ID — nothing to release"; return 0; }
  local rec rc=0
  rec="$(record_path "$PROJECT")"
  session_record_update "$rec" \
    '.session.runtime == $rt and .session.session_id == $sid' \
    '.session.ended = ((.session.ended // {}) + {at: $ts})' \
    --arg rt "$RUNTIME" --arg sid "$SESSION_ID" --arg ts "$(date -u +%FT%TZ)" || rc=$?
  case "$rc" in
    0) note "release: ended work/$PROJECT session $(jq -r '.session.seq // "?"' "$rec" 2>/dev/null) ($RUNTIME-$SESSION_ID)"; return 0 ;;
    1) note "release: no-op reason=not_owner owner=$(record_owner "$rec") — work/$PROJECT is not this session's ($RUNTIME-$SESSION_ID); nothing written"; return 1 ;;
    *) return "$rc" ;;
  esac
}

# close: the stop door. The ledger checks the launcher runs at a rollover run
# here, inline, at the moment the session ends the chain: the top block of
# work/<item>/handoff.md must carry this session's number. --check runs the
# same checks and writes nothing, for the agent to use while writing.
cmd_close() {
  resolve_session
  resolve_own_project || die "close: no --project given and none recorded for this session"
  local rec owner seq hf top rc=0
  rec="$(record_path "$PROJECT")"
  [ -f "$rec" ] || refuse not_owner "project=$PROJECT — no record; nothing registered on this item"
  owner=$(record_owner "$rec") || refuse record_unreadable "record=$rec"
  [ "$owner" = "$RUNTIME-$SESSION_ID" ] \
    || refuse not_owner "project=$PROJECT owner=${owner#-} me=$RUNTIME-$SESSION_ID"
  seq=$(jq -r '.seq // empty' "$rec" 2>/dev/null)
  [ -n "$seq" ] || refuse record_unreadable "record=$rec — no seq"
  hf=$(ledger_file "$PROJECT") \
    || refuse ledger_shape "project=$PROJECT — no handoff.md (nor session_handoff.md)"
  grep -q -E '^#[[:space:]]*Session Handoff' "$hf" 2>/dev/null \
    || refuse ledger_shape "file=$hf — no '# Session Handoff' heading"
  top=$(top_ledger_session "$hf")
  [ -n "$top" ] || refuse ledger_shape "file=$hf — the top heading carries no session number"
  [ "$top" = "$seq" ] || refuse ledger_seq_mismatch "ledger=$top seq=$seq file=$hf"
  if [ "$CHECK" -eq 1 ]; then
    echo "close: check ok seq=$seq project=$PROJECT"
    return 0
  fi
  session_record_update "$rec" \
    '.session.runtime == $rt and .session.session_id == $sid' \
    '.session.ended = ((.session.ended // {}) + {at: $ts, door: "stop"})' \
    --arg rt "$RUNTIME" --arg sid "$SESSION_ID" --arg ts "$(date -u +%FT%TZ)" || rc=$?
  case "$rc" in
    0) echo "close: ok seq=$seq project=$PROJECT door=stop"; return 0 ;;
    1) refuse not_owner "project=$PROJECT — the record changed underneath" ;;
    *) return "$rc" ;;
  esac
}

cmd_watch() {
  resolve_session
  note "watching $RUNTIME session every ${INTERVAL}s; threshold=$THRESHOLD warn=$WARN"
  local prev="OK" rc
  while true; do
    rc=0; emit_check || rc=$?
    if { [ "$LAST_STATUS" = "WARN" ] && [ "$prev" = "OK" ]; } \
       || { [ "$LAST_STATUS" = "STOP" ] && [ "$prev" != "STOP" ]; }; then
      if command -v osascript >/dev/null 2>&1; then
        osascript -e "display notification \"$RUNTIME session at $LAST_TOKENS tokens (threshold $THRESHOLD)\" with title \"Context budget: $LAST_STATUS\" sound name \"Basso\"" || true
      fi
    fi
    prev="$LAST_STATUS"
    sleep "$INTERVAL"
  done
}

case "$COMMAND" in
  check) resolve_session; emit_check ;;
  register) cmd_register ;;
  record) cmd_record ;;
  watch) cmd_watch ;;
  release) cmd_release ;;
  close) cmd_close ;;
  supervised) cmd_supervised ;;
esac
