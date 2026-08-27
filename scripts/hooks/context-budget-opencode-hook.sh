#!/usr/bin/env bash
# File: scripts/hooks/context-budget-opencode-hook.sh
# Purpose: called by .opencode/plugins/context-budget.js on each user message
#          with the sessionID; prints the WARN/STOP text on escalation (plugin
#          appends it as an in-band message Part), nothing otherwise.
#          Also answers the plugin's session.idle exit check:
#            context-budget-opencode-hook.sh --exit-check <sid>
#          prints "exit" when this session should end, nothing otherwise.
set -u
. "$(cd "$(dirname "$0")" && pwd)/context-budget-hook-lib.sh"
# Session-loop supervisor exit. Unlike every other runtime, opencode does NOT
# signal from here: the plugin runs inside the terminal-owning opencode process
# and self-kills with process.pid (verified end-to-end, 1.18.15 — see
# work/session-loop-automation/probe-results.md Q3). This hook only decides.
if [ "${1:-}" = "--exit-check" ]; then
  sid="${2:-}"
  [ -n "$sid" ] && [ -n "${TF_SESSION_LOOP_PROJECT:-}" ] || exit 0
  budget_hook_should_exit "$sid" "$TF_SESSION_LOOP_PROJECT" || exit 0
  echo "session-loop: terminating opencode session $sid at the turn boundary" >&2
  echo exit
  exit 0
fi
sid="${1:-}"
[ -n "$sid" ] || exit 0
export OPENCODE_SESSION_ID="$sid"
out=$(budget_hook_check opencode "$sid" "")
[ -n "$out" ] || exit 0
read -r status tokens threshold <<<"$out"
budget_hook_message "$status" "$tokens" "$threshold"
exit 0
