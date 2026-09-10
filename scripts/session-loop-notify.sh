#!/bin/sh
# Notification hook for session-loop.sh — wire via SESSION_LOOP_NOTIFY in
# context-budget.env (global or work/<proj>/). Called with the halt/stall
# message as $1. Desktop notification where available; always echoes so the
# message lands in the supervisor's terminal/log regardless.
MSG="${1:-session-loop notification}"
if command -v osascript >/dev/null 2>&1; then
  ESC="$(printf '%s' "$MSG" | sed 's/\\/\\\\/g; s/"/\\"/g')"
  osascript -e "display notification \"$ESC\" with title \"session-loop\" sound name \"Basso\"" >/dev/null 2>&1 || true
elif command -v notify-send >/dev/null 2>&1; then
  notify-send "session-loop" "$MSG" >/dev/null 2>&1 || true
fi
printf '%s\n' "$MSG"
