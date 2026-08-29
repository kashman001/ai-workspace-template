#!/usr/bin/env bash
# File: scripts/hooks/rollover-clear-seed.sh
# Purpose: SessionStart hook. When a session is reset with /clear as the
#          relaunch step of session-rollover, seed the fresh context with the
#          canonical bootstrap prompt so the human types nothing.
#          Half of ADR-0009; the other half is `launch-next-session.sh --clear`.
#
# Contract: reads the SessionStart hook payload on stdin. Emits the prompt as
#          additionalContext ONLY when BOTH hold:
#            1. payload .source == "clear"  (never on startup/resume/compact —
#               those paths already carry a prompt from launch-next-session.sh)
#            2. a pending seed marker exists (written by
#               `launch-next-session.sh <project> --clear`)
#          The marker is DRAINED (deleted) on emit, so an unrelated /clear
#          later in the day does not re-seed a stale prompt.
#
# The prompt wording is NOT authored here — it is read verbatim from the
# marker, which launch-next-session.sh wrote. ADR-0003 keeps that wording in
# exactly one place.
#
# Fails open, always: any error exits 0 emitting nothing. A broken seed must
# never block session startup.
set -u

exit_quiet() { exit 0; }
trap 'exit_quiet' ERR

payload="$(cat 2>/dev/null || true)"
[ -n "$payload" ] || exit 0

command -v jq >/dev/null 2>&1 || exit 0

source_kind="$(printf '%s' "$payload" | jq -r '.source // empty' 2>/dev/null || true)"
[ "$source_kind" = "clear" ] || exit 0

# Workspace identity = repository identity, not checkout path (issue 05), and
# NOT $CLAUDE_PROJECT_DIR: the writer (launch-next-session.sh) resolves its
# root the same way, so a hook firing inside a worktree must still look in the
# main checkout or it would never find the seed. Same shape as
# context-budget-hook-lib.sh -> budget_hook_resolve_root.
HOOK_DIR="$(cd "$(dirname "$0")" 2>/dev/null && pwd -P)" || exit 0
ROOT="$(cd "$HOOK_DIR/../.." 2>/dev/null && pwd -P)" || exit 0
if common="$(git -C "$ROOT" rev-parse --git-common-dir 2>/dev/null)"; then
  case "$common" in /*) : ;; *) common="$ROOT/$common" ;; esac
  repo="$(cd "$common/.." 2>/dev/null && pwd -P)" || repo=""
  if [ -n "$repo" ] && [ -f "$repo/scripts/context-budget.sh" ]; then ROOT="$repo"; fi
fi
[ -d "$ROOT/work" ] || exit 0

# Exactly one pending marker is expected. If several exist (two projects rolled
# over without clearing), take the newest and leave the others — seeding two
# missions into one context would be worse than seeding none.
marker=""
for f in "$ROOT"/work/*/.pending-clear-seed; do
  [ -f "$f" ] || continue
  if [ -z "$marker" ] || [ "$f" -nt "$marker" ]; then marker="$f"; fi
done
[ -n "$marker" ] || exit 0

prompt="$(cat "$marker" 2>/dev/null || true)"
rm -f "$marker" 2>/dev/null || true
[ -n "$prompt" ] || exit 0

jq -n --arg ctx "$prompt" '{
  hookSpecificOutput: {
    hookEventName: "SessionStart",
    additionalContext: $ctx
  }
}' 2>/dev/null || exit 0
