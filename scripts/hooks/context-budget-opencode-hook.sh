#!/usr/bin/env bash
# File: scripts/hooks/context-budget-opencode-hook.sh
# Purpose: called by .opencode/plugins/context-budget.js on each user message
#          with the sessionID; prints the WARN/STOP text on escalation (plugin
#          appends it as an in-band message Part), nothing otherwise.
set -u
sid="${1:-}"
[ -n "$sid" ] || exit 0
. "$(cd "$(dirname "$0")" && pwd)/context-budget-hook-lib.sh"
export OPENCODE_SESSION_ID="$sid"
out=$(budget_hook_check opencode "$sid" "")
[ -n "$out" ] || exit 0
read -r status tokens threshold <<<"$out"
budget_hook_message "$status" "$tokens" "$threshold"
exit 0
