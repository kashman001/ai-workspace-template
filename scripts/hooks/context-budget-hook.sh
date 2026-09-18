#!/usr/bin/env bash
# File: scripts/hooks/context-budget-hook.sh
# Purpose: the hook dispatcher — one script produces every runtime's context-
#          budget hook payload from the adapter table (context-budget-adapters.conf,
#          one row per runtime). The per-vendor files beside it are one-line shims
#          onto this one; the throttle, escalation-only rule, message text and
#          turn-end exit predicate live in context-budget-hook-lib.sh.
# Usage:   context-budget-hook.sh <runtime> <event> [arg]      (payload on stdin)
#          <event> is the vendor's own hook name: the row's check hook measures the
#          session and speaks on escalation only; its turn-end hook runs the
#          session-loop exit and, where the vendor supports it, blocks at STOP.
# Contract: fail-open. Every early exit is silent (gemini: `{}`), rc 0; the only
#          non-zero exits are the vendor-defined ones (exit 2 = stderr-exit2 /
#          block-stderr). jq is required and its absence is reported as
#          `refused reason=jq_missing` on stderr BEFORE anything is read or parsed.
set -u
HOOK_DIR="$(cd "$(dirname "$0")" && pwd)"
rt="${1:-}"; ev="${2:-}"; arg="${3:-}"

trim() { local s="$1"; s="${s#"${s%%[![:space:]]*}"}"; printf '%s' "${s%"${s##*[![:space:]]}"}"; }

# --- the row -----------------------------------------------------------------
row=""
[ -n "$rt" ] && while IFS= read -r line; do
  case "$line" in ''|'#'*) continue ;; esac
  [ "$(trim "${line%%|*}")" = "$rt" ] && { row="$line"; break; }
done < "$HOOK_DIR/context-budget-adapters.conf"
if [ -z "$row" ]; then
  echo "context-budget-hook: usage: <runtime> <event> [arg]; no adapter row for '${rt}'" >&2
  exit 0
fi
IFS='|' read -r _ sid_src tx_check tx_end measure_as register pin check_hook end_hook _ <<<"$row"
sid_src=$(trim "$sid_src"); tx_check=$(trim "$tx_check"); tx_end=$(trim "$tx_end")
measure_as=$(trim "$measure_as"); register=$(trim "$register"); pin=$(trim "$pin")
check_hook=$(trim "$check_hook"); end_hook=$(trim "$end_hook")
check_ev="${check_hook%%:*}"; envelope="${check_hook#*:}"
end_ev="${end_hook%%:*}"; action="${end_hook#*:}"

silent() { [ "$envelope" = hso-json-only ] && printf '%s' '{}'; exit 0; }

# --- jq, before any parsing ---------------------------------------------------
command -v jq >/dev/null 2>&1 || {
  echo "context-budget-hook: refused reason=jq_missing runtime=$rt event=$ev" >&2
  silent
}
. "$HOOK_DIR/context-budget-hook-lib.sh"

# --- session id ---------------------------------------------------------------
input=""
case "$sid_src" in
  payload:*) input=$(cat); sid=$(printf '%s' "$input" | jq -r "${sid_src#payload:} // empty") ;;
  arg)       sid="$arg" ;;
  *)         sid="" ;;
esac
[ -n "$sid" ] || silent

case "$ev" in
  "$check_ev") mode=check ;;
  "$end_ev")   mode=end ;;
  *) silent ;;   # not this row's hook: silent, as the wrappers were
esac

# --- turn-end: guard, then the session-loop exit ------------------------------
# Re-entrancy: a Stop re-fires for a hook-continued turn; acting twice would
# send a second SIGTERM to a process already terminating (failure mode 9).
guard() { [ "$(printf '%s' "$input" | jq -r '.stop_hook_active // false')" = "true" ] && silent; return 0; }
if [ "$mode" = end ]; then
  case "$action" in
    sigterm)
      guard; [ -n "${TF_SESSION_LOOP_PROJECT:-}" ] || silent
      budget_hook_exit "$rt" "$sid" "$TF_SESSION_LOOP_PROJECT"; exit 0 ;;
    sigterm+block)
      # Before the measurement below: that returns early on a missing transcript
      # or a non-STOP status, and the exit must not depend on either.
      guard; [ -n "${TF_SESSION_LOOP_PROJECT:-}" ] \
        && budget_hook_exit "$rt" "$sid" "$TF_SESSION_LOOP_PROJECT" ;;
    block-stderr) guard ;;
    decide)
      # opencode kills from inside its own plugin process, so it needs the
      # decision without the signal.
      [ -n "${TF_SESSION_LOOP_PROJECT:-}" ] || silent
      budget_hook_should_exit "$sid" "$TF_SESSION_LOOP_PROJECT" || silent
      echo "session-loop: terminating $rt session $sid at the turn boundary" >&2
      echo exit; exit 0 ;;
  esac
fi

# --- transcript ---------------------------------------------------------------
tx_src="$tx_check"; [ "$mode" = end ] && tx_src="$tx_end"
key="$sid"; transcript=""
case "$tx_src" in
  -) ;;
  payload:*)
    spec="${tx_src#payload:}"; spec="${spec%+chain}"
    transcript=$(printf '%s' "$input" | jq -r "$spec // empty")
    [ -n "$transcript" ] || silent
    # Sidechain firings share the parent's session_id but must not consume its
    # throttle/escalation slot: main transcript basename = session id.
    case "$tx_src" in *+chain)
      case "${transcript##*/}" in "$sid.jsonl") : ;; *) key="$sid-sidechain" ;; esac ;;
    esac ;;
  copilot-state)
    transcript="${COPILOT_STATE_DIR:-$HOME/.copilot/session-state}/$sid/events.jsonl" ;;
  chat-sessions)
    # Token counts live beside the transcript: …/GitHub.copilot-chat/transcripts/
    # <sid>.jsonl -> ../../../chatSessions/<sid>.jsonl (verified live, session 28).
    t=$(printf '%s' "$input" | jq -r '.transcript_path // empty')
    [ -n "$t" ] || silent
    transcript="$(dirname "$(dirname "$(dirname "$t")")")/chatSessions/$sid.jsonl" ;;
esac
case "$pin" in
  -|'') ;;
  *=sid)        export "${pin%=sid}=$sid" ;;
  *=transcript) export "${pin%=transcript}=$transcript" ;;
esac
# Definite auto-registration (register=hook): does not depend on the agent
# running `register`. Runs BEFORE the transcript guard — the first hook fires
# before the vendor creates the token file, and `register` handles a missing
# artifact as method=deferred.
if [ "$register" = hook ]; then
  [ -f "$BUDGET_STATE_DIR/sessions/$measure_as-$sid.json" ] \
    || "$WORKSPACE_ROOT/scripts/context-budget.sh" register \
         --runtime "$measure_as" --transcript "$transcript" >/dev/null 2>&1 || true
fi
[ "$tx_src" = - ] || [ -f "$transcript" ] || silent   # fresh session: nothing to measure yet

# --- measure ------------------------------------------------------------------
out=$(budget_hook_check "$measure_as" "$key" "$transcript")
[ -n "$out" ] || silent
read -r status tokens threshold <<<"$out"
if [ "$mode" = end ]; then
  [ "$status" = "STOP" ] || silent          # block only at STOP (the strong lever)
  case "$action" in
    sigterm+block)
      jq -n --arg r "$(budget_hook_message STOP "$tokens" "$threshold")" \
        '{decision:"block",reason:$r}' ;;
    block-stderr) budget_hook_message STOP "$tokens" "$threshold" >&2; exit 2 ;;
  esac
  exit 0
fi
msg=$(budget_hook_message "$status" "$tokens" "$threshold")
case "$envelope" in
  stderr-exit2)  echo "$msg" >&2; exit 2 ;;
  text)          echo "$msg" ;;
  hso-event)     jq -n --arg ev "$ev" --arg ctx "$msg" \
                   '{hookSpecificOutput:{hookEventName:$ev,additionalContext:$ctx}}' ;;
  hso)           jq -n --arg ctx "$msg" '{hookSpecificOutput:{additionalContext:$ctx}}' ;;
  hso-json-only) jq -nc --arg ctx "$msg" '{hookSpecificOutput:{additionalContext:$ctx}}' ;;
  ctx)           jq -n --arg ctx "$msg" '{additionalContext:$ctx}' ;;
esac
exit 0
