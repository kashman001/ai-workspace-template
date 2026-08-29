#!/usr/bin/env bash
# File: scripts/hooks/context-budget-stop-hook.sh
# Purpose: turn-end exit hook for the Claude-shaped runtimes — under the
#          session-loop supervisor only, terminate this session at the turn
#          boundary once its own rollover sentinel is on disk. Inert otherwise.
# Usage:   context-budget-stop-hook.sh <runtime>     (payload on stdin)
# Wiring:  claude — .claude/settings.json "hooks" -> "Stop"
#            (committed — M31)
#          codex  — .codex/config.toml [[hooks.Stop]]
#
# One file rather than one per runtime: claude 2.x and codex 0.149.0 send the
# same Stop payload (session_id + stop_hook_active), so a per-vendor copy would
# differ only in a string. The 2026-08-26 live probe confirmed codex's Stop
# fires and that SIGTERM to $PPID actually terminates the agent
# (work/session-loop-automation/probe-results.md).
set -u
rt="${1:-}"
[ -n "$rt" ] || exit 0
command -v jq >/dev/null 2>&1 || exit 0
. "$(cd "$(dirname "$0")" && pwd)/context-budget-hook-lib.sh"
input=$(cat)
# Re-entrancy: Stop re-fires for a hook-continued turn. Acting twice would send a
# second SIGTERM to a process already terminating (failure mode 9).
[ "$(echo "$input" | jq -r '.stop_hook_active // false')" = "true" ] && exit 0
session_id=$(echo "$input" | jq -r '.session_id // empty')
[ -n "$session_id" ] || exit 0
# The work item is not in the Stop payload; the supervisor exports it.
[ -n "${TF_SESSION_LOOP_PROJECT:-}" ] || exit 0
budget_hook_exit "$rt" "$session_id" "$TF_SESSION_LOOP_PROJECT"
exit 0
