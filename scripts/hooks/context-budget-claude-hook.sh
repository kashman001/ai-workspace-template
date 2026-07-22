#!/usr/bin/env bash
# File: scripts/hooks/context-budget-claude-hook.sh
# Purpose: Claude Code PostToolUse hook — in-band WARN/STOP message to the agent
#          when the session crosses the context-budget threshold. Speaks only on
#          status escalation, throttled to one check per minute, and fails open
#          (any error → exit 0) so it can never block real work.
# Wiring:  .claude/settings.json "hooks" (see .claude/settings.json.example).
set -u
CHECK_EVERY=60
WORKSPACE_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
STATE_DIR="$WORKSPACE_ROOT/.context-budget"
command -v jq >/dev/null 2>&1 || exit 0
input=$(cat)
session_id=$(echo "$input" | jq -r '.session_id // empty')
transcript=$(echo "$input" | jq -r '.transcript_path // empty')
[ -n "$transcript" ] && [ -f "$transcript" ] || exit 0
[ -n "$session_id" ] || session_id="unknown"
mkdir -p "$STATE_DIR"
stamp="$STATE_DIR/hook-$session_id.stamp"
state="$STATE_DIR/hook-$session_id.status"
if [ -f "$stamp" ]; then
  now=$(date +%s)
  last=$(stat -f%m "$stamp" 2>/dev/null || stat -c%Y "$stamp" 2>/dev/null || echo 0)
  [ $(( now - last )) -lt "$CHECK_EVERY" ] && exit 0
fi
touch "$stamp"
# PITFALL: exit codes 1/2 from the script mean WARN/STOP, not failure —
# do NOT `|| exit 0` on the command substitution.
line=$("$WORKSPACE_ROOT/scripts/context-budget.sh" check \
        --runtime claude --transcript "$transcript" --quiet 2>/dev/null) || true
[ -n "$line" ] || exit 0
status=$(echo "$line" | grep -o 'status=[A-Z]*' | cut -d= -f2)
tokens=$(echo "$line" | grep -o 'tokens=[0-9]*' | cut -d= -f2)
threshold=$(echo "$line" | grep -o 'threshold=[0-9]*' | cut -d= -f2)
prev="OK"; [ -f "$state" ] && prev=$(cat "$state")
echo "$status" > "$state"
rank() { case "$1" in STOP) echo 2 ;; WARN) echo 1 ;; *) echo 0 ;; esac; }
[ "$(rank "$status")" -le "$(rank "$prev")" ] && exit 0
if [ "$status" = "STOP" ]; then
  echo "CONTEXT BUDGET STOP: this session is at $tokens tokens, past the $threshold-token dumb-zone threshold. Finish the current atomic step only, then tell the user and run the session-rollover workflow (skills/session-rollover/SKILL.md). Do not start new work in this session." >&2
else
  echo "CONTEXT BUDGET WARN: this session is at $tokens tokens, approaching the $threshold-token dumb-zone threshold. Wrap up the current work unit and avoid loading large files; prepare to run the session-rollover workflow (skills/session-rollover/SKILL.md) soon. Mention this warning to the user in your next reply." >&2
fi
exit 2
