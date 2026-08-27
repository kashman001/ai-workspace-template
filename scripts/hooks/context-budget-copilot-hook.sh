#!/usr/bin/env bash
# File: scripts/hooks/context-budget-copilot-hook.sh
# Purpose: Copilot CLI hooks — sessionStart pushes WARN/STOP as
#          additionalContext (model may discount it: phrased as tooling
#          status); agentStop blocks with the rollover instruction ONLY at
#          STOP (the strong lever; avoids the 8-block continuation guard).
# Wiring:  .github/hooks/context-budget.json. Repo hooks silently no-op unless
#          the folder is in ~/.copilot/config.json trustedFolders.
set -u
event="${1:-}"
command -v jq >/dev/null 2>&1 || exit 0
. "$(cd "$(dirname "$0")" && pwd)/context-budget-hook-lib.sh"
input=$(cat)
sid=$(echo "$input" | jq -r '.sessionId // empty')
[ -n "$sid" ] || exit 0
case "$event" in
  sessionStart)
    transcript="${COPILOT_STATE_DIR:-$HOME/.copilot/session-state}/$sid/events.jsonl"
    [ -f "$transcript" ] || exit 0   # fresh session: nothing to measure yet
    out=$(budget_hook_check copilot-cli "$sid" "$transcript")
    [ -n "$out" ] || exit 0
    read -r status tokens threshold <<<"$out"
    jq -n --arg ctx "$(budget_hook_message "$status" "$tokens" "$threshold")" \
      '{additionalContext:$ctx}'
    ;;
  agentStop)
    active=$(echo "$input" | jq -r '.stop_hook_active // false')
    [ "$active" = "true" ] && exit 0
    # Session-loop supervisor exit, before the budget checks below: those return
    # early on a missing transcript or a non-STOP status, and the exit must not
    # depend on either. Inert unless TF_SESSION_LOOP=1.
    [ -n "${TF_SESSION_LOOP_PROJECT:-}" ] \
      && budget_hook_exit copilot "$sid" "$TF_SESSION_LOOP_PROJECT"
    transcript=$(echo "$input" | jq -r '.transcriptPath // empty')
    [ -n "$transcript" ] && [ -f "$transcript" ] || exit 0
    out=$(budget_hook_check copilot-cli "$sid" "$transcript")
    [ -n "$out" ] || exit 0
    read -r status tokens threshold <<<"$out"
    [ "$status" = "STOP" ] || exit 0
    jq -n --arg r "$(budget_hook_message STOP "$tokens" "$threshold")" \
      '{decision:"block",reason:$r}'
    ;;
esac
exit 0
