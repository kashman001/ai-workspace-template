#!/bin/sh
# Notification hook for session-loop.sh — wire via SESSION_LOOP_NOTIFY in
# context-budget.env (global or work/<proj>/). Called with the halt/stall
# message as $1. Desktop notification where available; also echoes the
# message, as a fallback for callers that do no logging of their own
# (manual runs, other wiring). session-loop.sh itself silences hook output
# deliberately — its notify() has already written the message to stderr and
# .session-loop.log via say() before the hook runs, so there the hook only
# adds the desktop notification.
MSG="${1:-session-loop notification}"
if command -v osascript >/dev/null 2>&1; then
  ESC="$(printf '%s' "$MSG" | sed 's/\\/\\\\/g; s/"/\\"/g')"
  osascript -e "display notification \"$ESC\" with title \"session-loop\" sound name \"Basso\"" >/dev/null 2>&1 || true
elif command -v notify-send >/dev/null 2>&1; then
  notify-send "session-loop" "$MSG" >/dev/null 2>&1 || true
fi
printf '%s\n' "$MSG"
