#!/usr/bin/env bash
# File: scripts/statusline-context-budget.sh
# Purpose: Claude Code statusLine command — shows this session's work-item
#          role (PRIMARY/AUXILIARY/SUPERSEDED), project, and the last
#          *measured* context percentage. Reads only small state files —
#          never the transcript: the statusline refreshes often, so live
#          measurement stays with `context-budget.sh record` at work-unit
#          boundaries and this just replays the newest ledger entry.
# Input:   Claude Code statusline JSON on stdin (session_id, workspace dirs).
# Wire-up: .claude/settings.json → "statusLine": {"type": "command",
#          "command": "\"$CLAUDE_PROJECT_DIR\"/scripts/statusline-context-budget.sh"}
#          (shipped in .claude/settings.json.example). Roles model:
#          docs/context-budget.md → "Session roles".
set -u

IN=$(cat 2>/dev/null || true)
SID=$(printf '%s' "$IN" | jq -r '.session_id // empty' 2>/dev/null)
ROOT=$(printf '%s' "$IN" | jq -r '.workspace.project_dir // .cwd // empty' 2>/dev/null)
[ -n "$ROOT" ] || ROOT=$(pwd)

REC="$ROOT/.context-budget/sessions/claude-$SID.json"
if [ -z "$SID" ] || [ ! -f "$REC" ]; then echo "no work item"; exit 0; fi
PROJECT=$(jq -r '.project // empty' "$REC" 2>/dev/null)
if [ -z "$PROJECT" ]; then echo "no work item"; exit 0; fi

# The lock is authoritative for primary; the record's role is a cached claim.
ROLE=$(jq -r '.role // "none"' "$REC" 2>/dev/null)
LOCK="$ROOT/work/$PROJECT/.active-session"
if [ -f "$LOCK" ] && \
   [ "$(jq -r '.session_id // empty' "$LOCK" 2>/dev/null)" = "$SID" ]; then
  ROLE="primary"
fi

# Context %: newest ledger entry for this session's artifact, if any.
PCT=""
LEDGER="$ROOT/work/context-decay/context-ledger.jsonl"
AF=$(jq -r '.artifact // empty' "$REC" 2>/dev/null)
if [ -f "$LEDGER" ] && [ -n "$AF" ]; then
  PCT=$(tail -200 "$LEDGER" | jq -rs --arg s "$(basename "$AF")" \
    '[.[] | select(.session == $s and .threshold > 0)] | last
     | if . then "\(.tokens * 100 / .threshold | floor)%" else empty end' \
    2>/dev/null)
fi

printf '%s · %s%s\n' \
  "$(printf '%s' "$ROLE" | tr '[:lower:]' '[:upper:]')" "$PROJECT" "${PCT:+ · $PCT}"
