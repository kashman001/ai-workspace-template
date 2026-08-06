#!/usr/bin/env bash
# File: scripts/hooks/context-budget-hook-lib.sh
# Purpose: shared core for the per-runtime context-budget hook wrappers
#          (claude/codex/gemini/opencode/copilot). Sourced, not executed.
#          Escalation-only, throttled, fail-open — the wrapper owns stdin
#          parsing and the vendor output envelope, nothing else.
#   budget_hook_check <runtime> <session_id> [transcript]
#     prints "STATUS TOKENS THRESHOLD" on escalation, else nothing; rc 0 always.
#   budget_hook_message <STATUS> <tokens> <threshold>
#     prints the canonical WARN/STOP text.

BUDGET_HOOK_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Workspace identity = repository identity, not checkout path (issue 05):
# resolve through git's common dir so hooks firing inside a worktree still
# read/write the main checkout's state. The explicit WORKSPACE_ROOT env
# override wins; fallback is the lib-relative root (non-git workspace).
budget_hook_resolve_root() {
  local root common repo
  root="$(cd "$BUDGET_HOOK_LIB_DIR/../.." && pwd -P)"
  if common="$(git -C "$root" rev-parse --git-common-dir 2>/dev/null)"; then
    case "$common" in /*) : ;; *) common="$root/$common" ;; esac
    repo="$(cd "$common/.." 2>/dev/null && pwd -P)"
    if [ -n "$repo" ] && [ -f "$repo/scripts/hooks/context-budget-hook-lib.sh" ]; then
      printf '%s' "$repo"; return
    fi
  fi
  printf '%s' "$root"
}
WORKSPACE_ROOT="${WORKSPACE_ROOT:-$(budget_hook_resolve_root)}"
BUDGET_STATE_DIR="$WORKSPACE_ROOT/.context-budget"
CHECK_EVERY="${CHECK_EVERY:-60}"

budget_hook_rank() { case "$1" in STOP) echo 2 ;; WARN) echo 1 ;; *) echo 0 ;; esac; }

budget_hook_check() {
  local runtime="$1" session_id="${2:-unknown}" transcript="${3:-}"
  [ -n "$session_id" ] || session_id="unknown"
  mkdir -p "$BUDGET_STATE_DIR" 2>/dev/null || return 0
  local stamp="$BUDGET_STATE_DIR/hook-$runtime-$session_id.stamp"
  local state="$BUDGET_STATE_DIR/hook-$runtime-$session_id.status"
  if [ -f "$stamp" ]; then
    local now last
    now=$(date +%s)
    last=$(stat -f%m "$stamp" 2>/dev/null || stat -c%Y "$stamp" 2>/dev/null || echo 0)
    [ $(( now - last )) -lt "$CHECK_EVERY" ] && return 0
  fi
  touch "$stamp"
  # PITFALL: exit codes 1/2 mean WARN/STOP, not failure — no `|| return` here.
  local line
  if [ -n "$transcript" ]; then
    line=$("$WORKSPACE_ROOT/scripts/context-budget.sh" check \
            --runtime "$runtime" --transcript "$transcript" --quiet 2>/dev/null) || true
  else
    line=$("$WORKSPACE_ROOT/scripts/context-budget.sh" check \
            --runtime "$runtime" --quiet 2>/dev/null) || true
  fi
  [ -n "$line" ] || return 0
  local status tokens threshold prev
  status=$(echo "$line" | grep -o 'status=[A-Z]*' | cut -d= -f2)
  tokens=$(echo "$line" | grep -o 'tokens=[0-9]*' | cut -d= -f2)
  threshold=$(echo "$line" | grep -o 'threshold=[0-9]*' | cut -d= -f2)
  [ -n "$status" ] || return 0
  prev="OK"; [ -f "$state" ] && prev=$(cat "$state")
  echo "$status" > "$state"
  [ "$(budget_hook_rank "$status")" -le "$(budget_hook_rank "$prev")" ] && return 0
  echo "$status $tokens $threshold"
  return 0
}

budget_hook_message() {
  local status="$1" tokens="$2" threshold="$3"
  if [ "$status" = "STOP" ]; then
    echo "CONTEXT BUDGET STOP: this session is at $tokens tokens, past the $threshold-token dumb-zone threshold. Finish the current atomic step only, then tell the user and run the session-rollover workflow (skills/session-rollover/SKILL.md). Do not start new work in this session."
  else
    echo "CONTEXT BUDGET WARN: this session is at $tokens tokens, approaching the $threshold-token dumb-zone threshold. Wrap up the current work unit and avoid loading large files; prepare to run the session-rollover workflow (skills/session-rollover/SKILL.md) soon. Mention this warning to the user in your next reply."
  fi
}
