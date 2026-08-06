#!/usr/bin/env bash
# File: scripts/context-budget.sh
# Purpose: Measure the current agent session's context-window usage from its
#          on-disk transcript and compare it against the workspace "dumb zone"
#          threshold. Agents invoke this at checkpoints — they never estimate
#          their own usage (they can't; the numbers live in the API envelope).
# Usage:   context-budget.sh check|register|record|watch|release|children
#            [--runtime claude|codex|copilot-vscode|copilot-cli|gemini|opencode|auto]
#            [--transcript <path>] [--project <work-item>] [--label "<text>"]
#            [--parent-session <sid>] [--agent-id <id>] [--takeover] [--all]
#            [--interval <secs>] [--quiet]
# Output:  runtime= method= tokens= threshold= warn= pct= status= artifact=
# Exit:    0 OK / 1 WARN / 2 STOP / 3 error. Requires jq.
# Design notes: D1–D9 in work/context-decay/design.html + docs/context-budget.md.

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
LEDGER="$WORKSPACE_ROOT/work/context-decay/context-ledger.jsonl"

if [ -z "${CONTEXT_DUMB_ZONE_TOKENS:-}" ] && [ -f "$WORKSPACE_ROOT/context-budget.env" ]; then
  . "$WORKSPACE_ROOT/context-budget.env" >/dev/null 2>&1 || true
fi
THRESHOLD="${CONTEXT_DUMB_ZONE_TOKENS:-150000}"
WARN="${CONTEXT_DUMB_ZONE_WARN_TOKENS:-$(( THRESHOLD * 80 / 100 ))}"
LOCK_STALE="${CONTEXT_LOCK_STALE_SECS:-10800}"

COMMAND="check"; RUNTIME="auto"; ARTIFACT=""; PROJECT=""; LABEL=""; INTERVAL=30; QUIET=0
PARENT_SESSION=""; AGENT_ID=""; TAKEOVER=0; ALL=0
case "${1:-}" in check|register|record|watch|release|children) COMMAND="$1"; shift ;; esac
while [ $# -gt 0 ]; do
  case "$1" in
    --runtime) RUNTIME="$2"; shift 2 ;;
    --transcript) ARTIFACT="$2"; shift 2 ;;
    --project) PROJECT="$2"; shift 2 ;;
    --parent-session) PARENT_SESSION="$2"; shift 2 ;;
    --agent-id) AGENT_ID="$2"; shift 2 ;;
    --takeover) TAKEOVER=1; shift ;;
    --all) ALL=1; shift ;;
    --label) LABEL="$2"; shift 2 ;;
    --interval) INTERVAL="$2"; shift 2 ;;
    --quiet) QUIET=1; shift ;;
    *) echo "unknown option: $1" >&2; exit 3 ;;
  esac
done

note() { [ "$QUIET" -eq 1 ] || echo "$@" >&2; }
die()  { echo "error: $*" >&2; exit 3; }

newest_of() { ls -t "$@" 2>/dev/null | head -1; }

claude_discover() {
  local slug proj
  slug="$(pwd | tr '/.' '--')"
  proj="$HOME/.claude/projects/$slug"
  [ -d "$proj" ] || return 1
  # Transcript basename = the exported session id; newest-mtime alone races
  # with a concurrent session in the same workspace.
  local t="$proj/${CLAUDE_CODE_SESSION_ID:-}.jsonl"
  [ -n "${CLAUDE_CODE_SESSION_ID:-}" ] && [ -f "$t" ] && { echo "$t"; return 0; }
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
  # sibling session whose log happened to flush later (the silent-freeze bug).
  local t="${VSCODE_TARGET_SESSION_LOG:-}" sid=""
  if [ -n "$t" ]; then
    [ -f "$t" ] && { echo "$t"; return 0; }
    sid="$(basename "$t")"; sid="${sid%.jsonl}"
  fi
  local root ws d
  for root in "Code" "Code - Insiders" "VSCodium"; do
    ws="$HOME/Library/Application Support/$root/User/workspaceStorage"
    [ -d "$ws" ] || continue
    for d in "$ws"/*/; do
      [ -f "$d/workspace.json" ] || continue
      if grep -qF "$(pwd)" "$d/workspace.json" 2>/dev/null; then
        # Deterministic: the session-id-named token file wins over newest-mtime.
        [ -n "$sid" ] && [ -f "$d""chatSessions/$sid.jsonl" ] \
          && { echo "$d""chatSessions/$sid.jsonl"; return 0; }
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
  local db="$1" sid="${OPENCODE_SESSION_ID:-}" tokens
  command -v sqlite3 >/dev/null 2>&1 || return 1
  [ -n "$sid" ] || sid=$(sqlite3 "$db" \
    "select id from session where directory='$PWD' order by time_updated desc limit 1" 2>/dev/null)
  [ -n "$sid" ] || return 1
  tokens=$(sqlite3 "$db" "select json_extract(data,'\$.tokens.total') from message
    where session_id='$sid' and json_extract(data,'\$.tokens.total') is not null
    order by rowid desc limit 1" 2>/dev/null)
  if [ -z "$tokens" ]; then
    tokens=$(sqlite3 "$db" "select tokens_input+tokens_output+tokens_reasoning+tokens_cache_read
      from session where id='$sid'" 2>/dev/null)
  fi
  [ -n "$tokens" ] && echo "$tokens exact" || return 1
}

detect_runtime() {
  if [ -n "${CLAUDECODE:-}" ] || [ -n "${CLAUDE_CODE_ENTRYPOINT:-}" ]; then echo "claude"; return; fi
  if [ -n "${CODEX_SANDBOX:-}" ] || [ -n "${CODEX_HOME:-}" ]; then echo "codex"; return; fi
  if [ -n "${OPENCODE_SESSION_ID:-}" ]; then echo "opencode"; return; fi
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
    local reg="$STATE_DIR/sessions/$RUNTIME-$SESSION_ID.json"
    if [ -f "$reg" ]; then
      ARTIFACT=$(jq -r '.artifact // empty' "$reg" 2>/dev/null)
      [ -f "$ARTIFACT" ] || ARTIFACT=""
    fi
  fi
  if [ -z "$ARTIFACT" ]; then
    ARTIFACT=$(discover_for "$RUNTIME") || true
    [ -n "$ARTIFACT" ] && [ -f "$ARTIFACT" ] \
      || die "no session artifact found for runtime=$RUNTIME"
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

lock_holder_age() {
  # Age in seconds of the lock holder's artifact (its liveness signal), via the
  # holder's own session file; rc 1 when unknowable (treated as stale — a
  # holder with no session record cannot be confirmed live).
  local rt="$1" sid="$2" af mt
  af=$(jq -r '.artifact // empty' "$STATE_DIR/sessions/$rt-$sid.json" 2>/dev/null)
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

parent_chain_holds_lock() {
  # Transitive validity (research §6): the chain of parent pointers must
  # terminate at the current project-lock holder. Structural check only;
  # liveness is enforced by the stale sweep at release time.
  local sid="$1" holder hops f found
  holder=$(jq -r '.session_id // empty' \
    "$WORKSPACE_ROOT/work/$PROJECT/.active-session" 2>/dev/null)
  [ -n "$holder" ] || return 1
  hops=0
  while [ "$hops" -lt 10 ]; do
    [ "$sid" = "$holder" ] && return 0
    found=""
    for f in "$WORKSPACE_ROOT/work/$PROJECT/.agent-locks/"*.json; do
      [ -f "$f" ] || continue
      if [ "$(jq -r '.session_id // empty' "$f" 2>/dev/null)" = "$sid" ]; then
        found=$(jq -r '.parent_session_id // empty' "$f" 2>/dev/null); break
      fi
    done
    [ -n "$found" ] || return 1
    sid="$found"; hops=$((hops+1))
  done
  return 1
}

acquire_child_lock() {
  local dir="$WORKSPACE_ROOT/work/$PROJECT"
  [ -d "$dir" ] || die "no such work directory: work/$PROJECT"
  if ! parent_chain_holds_lock "$PARENT_SESSION"; then
    ROLE="auxiliary"
    note "child lock: parent $PARENT_SESSION does not hold work/$PROJECT/.active-session (directly or via a valid chain); NOT granted — continuing as role=auxiliary"
    return 0
  fi
  mkdir -p "$dir/.agent-locks"
  jq -n --arg rt "$RUNTIME" --arg sid "$SESSION_ID" --arg aid "$AGENT_ID" \
    --arg psid "$PARENT_SESSION" --arg proj "$PROJECT" --argjson depth "$DEPTH" \
    --arg ts "$(date -u +%FT%TZ)" \
    '{runtime:$rt, session_id:$sid, parent_session_id:$psid, depth:$depth,
      project:$proj, acquired_at:$ts}
     + (if $aid == "" then {} else {agent_id:$aid} end)' \
    > "$dir/.agent-locks/$RUNTIME-$SESSION_ID.json"
  ROLE="child"
  note "lock: acquired work/$PROJECT/.agent-locks/$RUNTIME-$SESSION_ID.json under parent $PARENT_SESSION role=child"
}

backstamp_superseded() {
  # Successor side of the rollover chain: launch-next-session.sh stamps the
  # dying record role=superseded; the successor's primary acquisition completes
  # it with superseded_by — newest same-project superseded record not yet
  # claimed by a successor.
  local f ts best="" best_ts=""
  for f in "$STATE_DIR/sessions/"*.json; do
    [ -f "$f" ] || continue
    [ "$f" = "$STATE_DIR/sessions/$RUNTIME-$SESSION_ID.json" ] && continue
    ts=$(jq -r --arg proj "$PROJECT" \
      'select(.project == $proj and .role == "superseded"
              and (.superseded_by // "") == "")
       | .superseded_at // .registered_at // ""' "$f" 2>/dev/null)
    [ -n "$ts" ] || continue
    if [ -z "$best" ] || [ "$ts" \> "$best_ts" ]; then best="$f"; best_ts="$ts"; fi
  done
  [ -n "$best" ] || return 0
  jq --arg by "$RUNTIME-$SESSION_ID" '.superseded_by = $by' "$best" \
    > "$best.tmp" && mv "$best.tmp" "$best"
  note "role: ${best##*/} back-stamped superseded_by=$RUNTIME-$SESSION_ID"
}

acquire_lock() {
  local dir="$WORKSPACE_ROOT/work/$PROJECT" lock hrt hsid age
  [ -d "$dir" ] || die "no such work directory: work/$PROJECT"
  lock="$dir/.active-session"
  if [ -f "$lock" ]; then
    hrt=$(jq -r '.runtime // empty' "$lock" 2>/dev/null)
    hsid=$(jq -r '.session_id // empty' "$lock" 2>/dev/null)
    if [ "$hrt-$hsid" != "$RUNTIME-$SESSION_ID" ]; then
      if age=$(lock_holder_age "$hrt" "$hsid") && [ "$age" -lt "$LOCK_STALE" ]; then
        if [ "$TAKEOVER" -eq 1 ]; then
          # Explicit recorded steal (S33 — human authority beats liveness):
          # the old holder's record is stamped, never silently orphaned.
          local hrec="$STATE_DIR/sessions/$hrt-$hsid.json"
          if [ -f "$hrec" ]; then
            jq --arg ts "$(date -u +%FT%TZ)" --arg by "$RUNTIME-$SESSION_ID" \
              '.role="superseded" | .superseded_at=$ts | .superseded_by=$by' \
              "$hrec" > "$hrec.tmp" && mv "$hrec.tmp" "$hrec"
          fi
          note "lock: takeover — stealing work/$PROJECT/.active-session from live holder $hrt-$hsid (artifact active ${age}s ago); old holder stamped superseded"
        else
          ROLE="auxiliary"
          note "lock: work/$PROJECT/.active-session held by $hrt-$hsid (artifact active ${age}s ago); NOT acquired — one primary session per work item; continuing as role=auxiliary"
          return 0
        fi
      else
        note "lock: reclaiming stale lock from $hrt-$hsid"
      fi
    fi
  fi
  jq -n --arg rt "$RUNTIME" --arg sid "$SESSION_ID" --arg proj "$PROJECT" \
    --arg ts "$(date -u +%FT%TZ)" \
    '{runtime:$rt, session_id:$sid, project:$proj, acquired_at:$ts}' > "$lock"
  ROLE="primary"
  note "lock: acquired work/$PROJECT/.active-session as $RUNTIME-$SESSION_ID role=primary"
}

cmd_register() {
  resolve_session
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
  fi
  ROLE=""
  if [ -n "$PROJECT" ]; then
    # Children never contend for the project lock (research §6).
    if [ -n "$PARENT_SESSION" ]; then acquire_child_lock; else acquire_lock; fi
    [ "$ROLE" = "primary" ] && backstamp_superseded
  fi
  jq -n --arg rt "$RUNTIME" --arg sid "$SESSION_ID" --arg af "$ARTIFACT" \
    --arg proj "$PROJECT" --arg ts "$(date -u +%FT%TZ)" --arg role "$ROLE" \
    --arg psid "$PARENT_SESSION" --arg aid "$AGENT_ID" --argjson depth "$DEPTH" \
    '{runtime:$rt, session_id:$sid, artifact:$af, project:$proj, registered_at:$ts}
     + (if $role == "" then {} else {role:$role} end)
     + (if $psid == "" then {} else {parent_session_id:$psid, depth:$depth} end)
     + (if $aid == "" then {} else {agent_id:$aid} end)' \
    > "$STATE_DIR/sessions/$RUNTIME-$SESSION_ID.json"
  note "registered $RUNTIME session $SESSION_ID artifact: $ARTIFACT"
  emit_check
}

cmd_record() {
  resolve_session
  local rc=0
  emit_check || rc=$?
  mkdir -p "$(dirname "$LEDGER")"
  jq -cn --arg ts "$(date -u +%FT%TZ)" --arg rt "$RUNTIME" \
    --arg session "$(basename "$ARTIFACT")" --arg method "$LAST_METHOD" \
    --arg status "$LAST_STATUS" --arg label "$LABEL" \
    --argjson tokens "$LAST_TOKENS" --argjson threshold "$THRESHOLD" \
    '{ts:$ts, runtime:$rt, session:$session, tokens:$tokens, method:$method,
      threshold:$threshold, status:$status, label:$label}' >> "$LEDGER"
  return $rc
}

sweep_child_locks() {
  # Sweep stale child locks (holder artifact older than LOCK_STALE, same
  # liveness rule as the project lock); the survivors — live child locks —
  # land in LIVE_CHILD_LOCKS, one path per line.
  local lockdir="$WORKSPACE_ROOT/work/$PROJECT/.agent-locks" f crt csid age
  LIVE_CHILD_LOCKS=""
  [ -d "$lockdir" ] || return 0
  for f in "$lockdir"/*.json; do
    [ -f "$f" ] || continue
    crt=$(jq -r '.runtime // empty' "$f" 2>/dev/null)
    csid=$(jq -r '.session_id // empty' "$f" 2>/dev/null)
    if age=$(lock_holder_age "$crt" "$csid") && [ "$age" -lt "$LOCK_STALE" ]; then
      LIVE_CHILD_LOCKS="$LIVE_CHILD_LOCKS$f
"
    else
      rm -f "$f"; note "release: swept stale child lock ${f##*/}"
    fi
  done
}

live_locks_naming_parent() {
  # $1 = session id. Live child locks whose parent pointer names it
  # (basenames, space-joined) — the I4 release-order blockers.
  local f out=""
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    [ "$(jq -r '.parent_session_id // empty' "$f" 2>/dev/null)" = "$1" ] \
      && out="$out ${f##*/}"
  done <<EOF
$LIVE_CHILD_LOCKS
EOF
  printf '%s' "${out# }"
}

cmd_release() {
  resolve_session
  if [ -z "$PROJECT" ]; then
    PROJECT=$(jq -r '.project // empty' "$STATE_DIR/sessions/$RUNTIME-$SESSION_ID.json" 2>/dev/null)
    [ -n "$PROJECT" ] || die "release: no --project given and none recorded for this session"
  fi
  sweep_child_locks
  # A child releases its own per-child lock, never the project lock — and
  # only bottom-up: refused while live child locks name it as parent (I4).
  local own_child_lock="$WORKSPACE_ROOT/work/$PROJECT/.agent-locks/$RUNTIME-$SESSION_ID.json"
  if [ -f "$own_child_lock" ]; then
    local blockers
    blockers=$(live_locks_naming_parent "$SESSION_ID")
    [ -z "$blockers" ] \
      || die "release: refusing — live child locks under $RUNTIME-$SESSION_ID: $blockers"
    rm -f "$own_child_lock"
    note "release: released work/$PROJECT/.agent-locks/$RUNTIME-$SESSION_ID.json"
    return 0
  fi
  local lock="$WORKSPACE_ROOT/work/$PROJECT/.active-session" hrt hsid
  [ -f "$lock" ] || { note "release: no lock at work/$PROJECT/.active-session"; return 0; }
  hrt=$(jq -r '.runtime // empty' "$lock" 2>/dev/null)
  hsid=$(jq -r '.session_id // empty' "$lock" 2>/dev/null)
  if [ "$hrt-$hsid" = "$RUNTIME-$SESSION_ID" ]; then
    # Release-order guard (I4): every live child lock descends from the
    # project lock, so any survivor blocks the holder's release.
    [ -z "$LIVE_CHILD_LOCKS" ] \
      || die "release: refusing — live child locks in work/$PROJECT/.agent-locks: $(printf '%s' "$LIVE_CHILD_LOCKS" | while IFS= read -r f; do printf '%s ' "${f##*/}"; done)"
    rm -f "$lock"; note "release: released work/$PROJECT/.active-session"
  else
    note "release: lock held by $hrt-$hsid, not by this session ($RUNTIME-$SESSION_ID); left in place"
  fi
}

claude_child_measure() {
  # Sidechain-INCLUSIVE variant of claude_measure: a subagent transcript's
  # entries are all isSidechain:true, so the self-measure filter would
  # silently degrade every child to size-estimate.
  local f="$1" jq_prog tokens
  jq_prog='[.[] | select(.message.usage.input_tokens != null)]
    | last | if . == null then empty else
      (.message.usage.input_tokens + (.message.usage.cache_read_input_tokens // 0)
       + (.message.usage.cache_creation_input_tokens // 0)) end'
  tokens=$(tail -n 2000 "$f" | jq -s -r "$jq_prog" 2>/dev/null)
  [ -z "$tokens" ] && tokens=$(jq -s -r "$jq_prog" "$f" 2>/dev/null)
  [ -n "$tokens" ] && echo "$tokens exact" || estimate_from_size "$f"
}

cmd_children() {
  # R1 sweep (research §10): no runtime reports per-child usage to the parent;
  # measure the child transcript artifacts directly. Escalation-only output —
  # WARN/STOP children print, OK children don't (unless --all). Exit code is
  # the worst child status, check-style. Direct children only (R8).
  if [ "$RUNTIME" != "auto" ] && [ "$RUNTIME" != "claude" ]; then
    die "children: only implemented for runtime=claude (got $RUNTIME)"
  fi
  if [ -n "$PARENT_SESSION" ]; then
    local prec
    prec=$(parent_record_path "$PARENT_SESSION") \
      || die "children: parent session $PARENT_SESSION is not registered"
    RUNTIME=$(jq -r '.runtime // empty' "$prec")
    ARTIFACT=$(jq -r '.artifact // empty' "$prec")
    [ -n "$ARTIFACT" ] && [ -f "$ARTIFACT" ] \
      || die "children: no artifact on record for parent $PARENT_SESSION"
  else
    resolve_session
  fi
  [ "$RUNTIME" = "claude" ] || die "children: only implemented for runtime=claude (got $RUNTIME)"
  local subdir="${ARTIFACT%.jsonl}/subagents"
  local worst=0 measured=0 escalated=0
  local f b tokens method status pct mt age atype
  if [ -d "$subdir" ]; then
    for f in "$subdir"/agent-*.jsonl; do
      [ -f "$f" ] || continue
      read -r tokens method < <(claude_child_measure "$f") || continue
      [ -n "$tokens" ] || continue
      measured=$((measured+1))
      if [ "$tokens" -ge "$THRESHOLD" ]; then status="STOP"; worst=2
      elif [ "$tokens" -ge "$WARN" ]; then status="WARN"; [ "$worst" -lt 1 ] && worst=1
      else status="OK"; fi
      [ "$status" = "OK" ] || escalated=$((escalated+1))
      if [ "$status" != "OK" ] || [ "$ALL" -eq 1 ]; then
        pct=$(( tokens * 100 / THRESHOLD ))
        mt=$(stat -f%m "$f" 2>/dev/null || stat -c%Y "$f" 2>/dev/null) || mt=$(date +%s)
        age=$(( $(date +%s) - mt ))
        atype=$(jq -r '.agentType // empty' "${f%.jsonl}.meta.json" 2>/dev/null)
        [ -n "$atype" ] || atype="?"
        b="${f##*/}"; b="${b%.jsonl}"
        echo "agent=$b tokens=$tokens threshold=$THRESHOLD warn=$WARN pct=$pct status=$status age=$age type=$atype artifact=$f"
      fi
    done
  fi
  note "children: $measured measured, $escalated escalated"
  return "$worst"
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

command -v jq >/dev/null 2>&1 || die "jq is required"

case "$COMMAND" in
  check) resolve_session; emit_check ;;
  register) cmd_register ;;
  record) cmd_record ;;
  watch) cmd_watch ;;
  release) cmd_release ;;
  children) cmd_children ;;
esac
