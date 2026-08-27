#!/usr/bin/env bash
# File: scripts/hooks/context-budget-gemini-hook.sh
# Purpose: Gemini CLI BeforeAgent hook — WARN/STOP push appended to the turn's
#          prompt. Gemini hooks demand JSON-only stdout: {} when silent.
# Wiring:  .gemini/settings.json hooks.BeforeAgent. Measurement uses the
#          workspace telemetry log (exact), NOT the payload transcript_path —
#          the chat transcript carries no token counts.
#
# Turn-end exit: NOT wired. `AfterAgent` exists in 0.46.0 and supports
# `continue: false`, but the live firing test on 2026-08-26 recorded **blocked** —
# no auth is configured on this machine, so no turn runs and no hook can fire
# (work/session-loop-automation/probe-results.md). A blocked probe is not a
# passing probe, and Tier C would assert a negative that was never tested, so
# gemini stays UNDETERMINED for the supervisor: it prints the command and a human
# relaunches. Unblock with a `gemini` OAuth login (NO_BROWSER=true works
# cross-machine) or a GEMINI_API_KEY, then rerun the probe recipe in
# probe-results.md -> "Corrections to the plan".
set -u
emit_silent() { printf '%s' '{}'; exit 0; }
command -v jq >/dev/null 2>&1 || emit_silent
. "$(cd "$(dirname "$0")" && pwd)/context-budget-hook-lib.sh"
input=$(cat)
session_id=$(echo "$input" | jq -r '.session_id // empty')
out=$(budget_hook_check gemini "$session_id" "")
[ -n "$out" ] || emit_silent
read -r status tokens threshold <<<"$out"
jq -nc --arg ctx "$(budget_hook_message "$status" "$tokens" "$threshold")" \
  '{hookSpecificOutput:{additionalContext:$ctx}}'
exit 0
