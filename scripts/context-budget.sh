#!/usr/bin/env bash
# File: scripts/context-budget.sh
# Purpose: Measure the current agent session's context-window usage from its
#          on-disk transcript and compare it against the workspace "dumb zone"
#          threshold. Agents invoke this at checkpoints — they never estimate
#          their own usage (they can't; the numbers live in the API envelope).
# Usage:   context-budget.sh check|register|record|watch
#            [--runtime claude|codex|copilot-vscode|copilot-cli|gemini|auto]
#            [--transcript <path>] [--label "<text>"] [--interval <secs>] [--quiet]
# Output:  runtime= method= tokens= threshold= warn= pct= status= artifact=
# Exit:    0 OK / 1 WARN / 2 STOP / 3 error. Requires jq.
# Design notes: D1–D9 in work/context-decay/design.html + docs/context-budget.md.

set -u

WORKSPACE_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
STATE_DIR="$WORKSPACE_ROOT/.context-budget"
LEDGER="$WORKSPACE_ROOT/work/context-decay/context-ledger.jsonl"

if [ -z "${CONTEXT_DUMB_ZONE_TOKENS:-}" ] && [ -f "$WORKSPACE_ROOT/context-budget.env" ]; then
  . "$WORKSPACE_ROOT/context-budget.env" >/dev/null 2>&1 || true
fi
THRESHOLD="${CONTEXT_DUMB_ZONE_TOKENS:-150000}"
WARN="${CONTEXT_DUMB_ZONE_WARN_TOKENS:-$(( THRESHOLD * 80 / 100 ))}"

COMMAND="check"; RUNTIME="auto"; ARTIFACT=""; LABEL=""; INTERVAL=30; QUIET=0
case "${1:-}" in check|register|record|watch) COMMAND="$1"; shift ;; esac
while [ $# -gt 0 ]; do
  case "$1" in
    --runtime) RUNTIME="$2"; shift 2 ;;
    --transcript) ARTIFACT="$2"; shift 2 ;;
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
  local d
  for d in "$HOME/.copilot/history-session-state" "$HOME/.copilot/sessions"; do
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

detect_runtime() {
  if [ -n "${CLAUDECODE:-}" ] || [ -n "${CLAUDE_CODE_ENTRYPOINT:-}" ]; then echo "claude"; return; fi
  if [ -n "${CODEX_SANDBOX:-}" ] || [ -n "${CODEX_HOME:-}" ]; then echo "codex"; return; fi
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
    gemini) gemini_discover ;; *) return 1 ;;
  esac
}

measure_for() {
  case "$1" in
    claude) claude_measure "$2" ;; codex) codex_measure "$2" ;;
    copilot-vscode) copilot_vscode_measure "$2" ;; copilot-cli) copilot_cli_measure "$2" ;;
    gemini) gemini_measure "$2" ;; *) return 1 ;;
  esac
}

resolve_session() {
  if [ "$RUNTIME" = "auto" ]; then
    RUNTIME=$(detect_runtime)
    [ -n "$RUNTIME" ] || die "could not detect runtime; pass --runtime"
  fi
  # register must always re-discover; the registry is what it's there to (re)write.
  if [ -z "$ARTIFACT" ] && [ "$COMMAND" != "register" ]; then
    local reg="$STATE_DIR/session-$RUNTIME.json"
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

cmd_register() {
  resolve_session
  # Session boundary: the workspace telemetry log is shared append-only across
  # gemini sessions — reset it so a new session never reads the previous
  # session's counts (single-session-per-runtime assumption, see docs).
  if [ "$RUNTIME" = "gemini" ] && [ "$ARTIFACT" = "$WORKSPACE_ROOT/.gemini/telemetry.log" ]; then
    : > "$ARTIFACT"
  fi
  mkdir -p "$STATE_DIR"
  jq -n --arg rt "$RUNTIME" --arg af "$ARTIFACT" --arg ts "$(date -u +%FT%TZ)" \
    '{runtime:$rt, artifact:$af, registered_at:$ts}' > "$STATE_DIR/session-$RUNTIME.json"
  note "registered $RUNTIME session artifact: $ARTIFACT"
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
esac
