#!/usr/bin/env bash
# File: scripts/hooks/context-budget-claude-session-hook.sh
# Purpose: Claude Code SessionStart / SessionEnd hook (.claude/settings.json) —
#          `register` or `release` this session's registry record. Acts only on a
#          Claude Code transcript (budget_hook_is_claude_transcript): other
#          runtimes run .claude/settings.json too. Fail-open, rc 0.
. "$(cd "$(dirname "$0")" && pwd)/context-budget-hook-lib.sh" 2>/dev/null || exit 0
command -v jq >/dev/null 2>&1 || exit 0
c="$(cd "$(dirname "$0")/.." && pwd)/context-budget.sh"
[ -x "$c" ] || exit 0
t=$(jq -r '.transcript_path // empty' 2>/dev/null)
budget_hook_is_claude_transcript "$t" || exit 0
case "${1:-}" in
  register) "$c" register --runtime claude --transcript "$t" ;;
  release)  "$c" release --runtime claude --transcript "$t" --quiet ;;
esac
exit 0
