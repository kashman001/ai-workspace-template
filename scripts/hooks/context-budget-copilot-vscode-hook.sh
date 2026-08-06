#!/usr/bin/env bash
# File: scripts/hooks/context-budget-copilot-vscode-hook.sh
# Purpose: VS Code Copilot agent-mode hooks — SessionStart pushes WARN/STOP as
#          hookSpecificOutput.additionalContext (model may discount it: phrased
#          as tooling status); Stop blocks with the rollover instruction ONLY
#          at STOP, via exit 2 + stderr — the only working block channel
#          (JSON {decision:block} on Stop is IGNORED by VS Code; verified
#          issue 01, session 28).
# Wiring:  .github/hooks/context-budget-vscode.json (PascalCase events,
#          repo-relative command — hook-process cwd is the workspace root).
#          VS Code payloads are snake_case (session_id); the Copilot CLI sends
#          camelCase (sessionId), so it exits harmlessly at the guard below if
#          it ever loads this file.
set -u
event="${1:-}"
command -v jq >/dev/null 2>&1 || exit 0
. "$(cd "$(dirname "$0")" && pwd)/context-budget-hook-lib.sh"
input=$(cat)
sid=$(echo "$input" | jq -r '.session_id // empty')
[ -n "$sid" ] || exit 0   # camelCase payload = Copilot CLI, not ours
# Token counts live beside the transcript: …/GitHub.copilot-chat/transcripts/
# <sid>.jsonl -> ../../../chatSessions/<sid>.jsonl (verified live, session 28).
transcript=$(echo "$input" | jq -r '.transcript_path // empty')
[ -n "$transcript" ] || exit 0
cs="$(dirname "$(dirname "$(dirname "$transcript")")")/chatSessions/$sid.jsonl"
[ -f "$cs" ] || exit 0    # fresh session: nothing to measure yet
case "$event" in
  SessionStart)
    out=$(budget_hook_check copilot-vscode "$sid" "$cs")
    [ -n "$out" ] || exit 0
    read -r status tokens threshold <<<"$out"
    jq -n --arg ctx "$(budget_hook_message "$status" "$tokens" "$threshold")" \
      '{hookSpecificOutput:{additionalContext:$ctx}}'
    ;;
  Stop)
    active=$(echo "$input" | jq -r '.stop_hook_active // false')
    [ "$active" = "true" ] && exit 0
    out=$(budget_hook_check copilot-vscode "$sid" "$cs")
    [ -n "$out" ] || exit 0
    read -r status tokens threshold <<<"$out"
    [ "$status" = "STOP" ] || exit 0
    budget_hook_message STOP "$tokens" "$threshold" >&2
    exit 2
    ;;
esac
exit 0
