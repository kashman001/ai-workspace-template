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
# DEFINITE auto-registration — does NOT depend on the agent running `register`.
# Both hook events carry the authoritative session id + transcript path, so the
# first invocation pins THIS session's artifact (once; cheap `[ -f ]` no-op
# thereafter). Must run BEFORE the [ -f "$cs" ] measurement guard: SessionStart
# fires on the first prompt seconds before VS Code creates the chatSessions
# token file (3s–49s observed), and `register` handles a missing artifact as
# method=deferred — gating registration on the file existing caused the s78/s79
# false negatives (2026-08-11 hook research; conclusions in docs/context-budget.md).
# The inline VSCODE_TARGET_SESSION_LOG gives the script the same session
# identity a Copilot terminal would export (the hook process does not inherit
# it).
reg="$BUDGET_STATE_DIR/sessions/copilot-vscode-$sid.json"
[ -f "$reg" ] || VSCODE_TARGET_SESSION_LOG="$cs" \
  "$WORKSPACE_ROOT/scripts/context-budget.sh" register \
  --runtime copilot-vscode --transcript "$cs" >/dev/null 2>&1 || true
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
