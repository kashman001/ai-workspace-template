#!/usr/bin/env bash
# File: scripts/hooks/context-budget-claude-hook.sh
# Purpose: Claude Code PostToolUse hook — in-band WARN/STOP message to the agent
#          when the session crosses the context-budget threshold. Core logic
#          (throttle, escalation-only, fail-open) lives in
#          context-budget-hook-lib.sh, shared with the other runtimes' wrappers.
# Wiring:  .claude/settings.json "hooks" (see .claude/settings.json.example).
set -u
command -v jq >/dev/null 2>&1 || exit 0
. "$(cd "$(dirname "$0")" && pwd)/context-budget-hook-lib.sh"
input=$(cat)
session_id=$(echo "$input" | jq -r '.session_id // empty')
transcript=$(echo "$input" | jq -r '.transcript_path // empty')
[ -n "$transcript" ] && [ -f "$transcript" ] || exit 0
# Sidechain firings share the parent's session_id but must not consume its
# throttle/escalation slot (backlog L32) — key state per (session, chain).
# Main transcript basename = session id (docs/context-budget.md → adapters);
# any other transcript under the same session is a sidechain's.
chain=""
case "${transcript##*/}" in
  "$session_id.jsonl") : ;;
  *) chain="-sidechain" ;;
esac
out=$(budget_hook_check claude "$session_id$chain" "$transcript")
[ -n "$out" ] || exit 0
read -r status tokens threshold <<<"$out"
budget_hook_message "$status" "$tokens" "$threshold" >&2
exit 2
