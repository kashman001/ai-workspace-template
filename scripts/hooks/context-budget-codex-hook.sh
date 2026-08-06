#!/usr/bin/env bash
# File: scripts/hooks/context-budget-codex-hook.sh
# Purpose: Codex CLI UserPromptSubmit hook — same WARN/STOP push as the claude
#          hook, emitted as Claude-compatible hookSpecificOutput JSON.
# Wiring:  .codex/config.toml [[hooks.UserPromptSubmit]]. Codex trust gate:
#          first run in this repo prompts to trust the hook (hash-recorded;
#          editing this file re-prompts). CI: --dangerously-bypass-hook-trust.
set -u
command -v jq >/dev/null 2>&1 || exit 0
. "$(cd "$(dirname "$0")" && pwd)/context-budget-hook-lib.sh"
input=$(cat)
session_id=$(echo "$input" | jq -r '.session_id // empty')
transcript=$(echo "$input" | jq -r '.transcript_path // empty')
[ -n "$transcript" ] && [ -f "$transcript" ] || exit 0
out=$(budget_hook_check codex "$session_id" "$transcript")
[ -n "$out" ] || exit 0
read -r status tokens threshold <<<"$out"
jq -n --arg ctx "$(budget_hook_message "$status" "$tokens" "$threshold")" \
  '{hookSpecificOutput:{hookEventName:"UserPromptSubmit",additionalContext:$ctx}}'
exit 0
