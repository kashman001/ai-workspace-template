#!/usr/bin/env bash
# File: scripts/statusline-context-budget.sh
# Purpose: Claude Code statusLine command — shows this session's work-item
#          role (PRIMARY/AUXILIARY/SUPERSEDED), project, and the last
#          *measured* context percentage. Reads only small state files —
#          never the transcript: the statusline refreshes often, so live
#          measurement stays with `context-budget.sh record` at work-unit
#          boundaries and this just replays the newest ledger entry.
#          A project statusLine REPLACES the user's global one, so this
#          script chains it: the global command's output comes first and the
#          work-item segment is appended as an extra line.
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

# Workspace identity = repository identity, not checkout path (issue 05): a
# session isolated into a git worktree reports the worktree as project_dir,
# but the coordination state lives in the main checkout — resolve through
# git's common dir. Fallback: the reported dir itself (non-git workspace).
if common="$(git -C "$ROOT" rev-parse --git-common-dir 2>/dev/null)"; then
  case "$common" in /*) : ;; *) common="$ROOT/$common" ;; esac
  repo="$(cd "$common/.." 2>/dev/null && pwd -P)"
  [ -n "$repo" ] && [ -f "$repo/scripts/statusline-context-budget.sh" ] && ROOT="$repo"
fi

REC="$ROOT/.context-budget/sessions/claude-$SID.json"
PROJECT=""
[ -n "$SID" ] && [ -f "$REC" ] && PROJECT=$(jq -r '.project // empty' "$REC" 2>/dev/null)

SEGMENT=""
if [ -n "$PROJECT" ]; then
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
  SEGMENT=$(printf '%s · %s%s' \
    "$(printf '%s' "$ROLE" | tr '[:lower:]' '[:upper:]')" "$PROJECT" "${PCT:+ · $PCT}")
fi

# Chain the user's global statusLine command (skipped when absent or when it
# points back at this script, which would recurse).
BASE=""
GCMD=$(jq -r '.statusLine.command // empty' "$HOME/.claude/settings.json" 2>/dev/null)
case "$GCMD" in
  ""|*statusline-context-budget*) : ;;
  *) BASE=$(printf '%s' "$IN" | sh -c "$GCMD" 2>/dev/null) || BASE="" ;;
esac

if [ -n "$BASE" ] && [ -n "$SEGMENT" ]; then printf '%s\n%s\n' "$BASE" "$SEGMENT"
elif [ -n "$BASE" ]; then printf '%s\n' "$BASE"
elif [ -n "$SEGMENT" ]; then printf '%s\n' "$SEGMENT"
else echo "no work item"; fi
