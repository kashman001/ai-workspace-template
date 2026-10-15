#!/usr/bin/env bash
# File: scripts/hooks/context-budget-precompact-hook.sh
# Purpose: Claude Code PreCompact hook (.claude/settings.json, matcher `auto`) —
#          opt-in block on auto-compaction while this session owns a work item,
#          so a deliberate rollover is not pre-empted by compaction.
#   Blocks (exit 2, reason on stderr) only when all hold:
#     trigger == auto                       — a manual /compact is never blocked
#     CONTEXT_BLOCK_AUTOCOMPACT=1           — explicit env > work/<p>/context-budget.env
#                                             > global context-budget.env; default off
#     this session owns work/<p>/           — the registry stamps the project and the
#                                             record still names this session
#   Off by default: on a session that ignored STOP, a blocked compaction is a
#   hard wall at the model's window, not a rollover. Fail-open (exit 0) on every
#   error — no jq, no payload, no registry entry, unreadable record.
. "$(cd "$(dirname "$0")" && pwd)/context-budget-hook-lib.sh" 2>/dev/null || exit 0
command -v jq >/dev/null 2>&1 || exit 0
input=$(cat)
[ "$(printf '%s' "$input" | jq -r '.trigger // empty' 2>/dev/null)" = auto ] || exit 0
sid=$(printf '%s' "$input" | jq -r '.session_id // empty' 2>/dev/null)
[ -n "$sid" ] || exit 0
proj=$(jq -r '.project // empty' "$BUDGET_STATE_DIR/sessions/claude-$sid.json" 2>/dev/null)
[ -n "$proj" ] || exit 0
jq -e --arg sid "$sid" '.session.session_id == $sid' "$WORKSPACE_ROOT/work/$proj/session-state.json" >/dev/null 2>&1 || exit 0

knob="${CONTEXT_BLOCK_AUTOCOMPACT:-}"
if [ -z "$knob" ]; then
  for f in "$WORKSPACE_ROOT/context-budget.env" "$WORKSPACE_ROOT/work/$proj/context-budget.env"; do
    [ -f "$f" ] || continue
    v=$(. "$f" >/dev/null 2>&1; printf '%s' "${CONTEXT_BLOCK_AUTOCOMPACT:-}")
    [ -n "$v" ] && knob="$v"
  done
fi
[ "$knob" = 1 ] || exit 0

echo "context-budget: auto-compaction blocked — this session owns work/$proj (CONTEXT_BLOCK_AUTOCOMPACT=1). Roll over now: skills/session-rollover/SKILL.md." >&2
exit 2
