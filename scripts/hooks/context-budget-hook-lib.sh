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

# --- session-loop supervisor: turn-end exit ---------------------------------
#
# The hook does NOT decide whether the session should end — the agent already
# did, by completing its rollover and writing a sentinel naming itself. The
# hook's whole job is to notice that its own sentinel is on disk and act. That
# is what keeps this vendor-specific surface as thin as it is: one condition,
# read from a file the design already requires.
#
# Three conditions, all necessary:
#   TF_SESSION_LOOP=1        — nobody is supervising otherwise (opt-in contract)
#   the sentinel exists      — a rollover actually completed
#   its session_id is MINE   — not a predecessor's leftover, not a sibling's
#
# The decision and the signal are separate functions because not every runtime
# signals: opencode's exit path runs inside its own plugin process and self-kills
# with process.pid, so it needs the predicate without the SIGTERM.

# budget_hook_should_exit <session_id> <project>
#   rc 0 when this session's own rollover sentinel is on disk under the
#   supervisor; rc 1 in every other case, including every error.
budget_hook_should_exit() {
  local sid="${1:-}" proj="${2:-}" sentf owner
  [ "${TF_SESSION_LOOP:-}" = "1" ] || return 1
  [ -n "$sid" ] && [ -n "$proj" ] || return 1
  command -v jq >/dev/null 2>&1 || return 1
  # WORKSPACE_ROOT, not budget_hook_resolve_root(): the resolver deliberately
  # ignores the env override so it can find the main checkout from a worktree,
  # and every other reader in this lib goes through WORKSPACE_ROOT.
  sentf="$WORKSPACE_ROOT/work/$proj/.rollover-complete"
  [ -f "$sentf" ] || return 1
  owner="$(jq -r '.session_id // empty' "$sentf" 2>/dev/null)"
  [ "$owner" = "$sid" ] || return 1
  return 0
}

# budget_hook_exit <runtime> <session_id> <project>
#   The predicate plus a SIGTERM to the agent that spawned this hook process.
#   SIGTERM only; no escalation (failure mode 9). Never returns non-zero — a
#   hook that fails must not block a turn.
budget_hook_exit() {
  local rt="${1:-}" sid="${2:-}" proj="${3:-}"
  budget_hook_should_exit "$sid" "$proj" || return 0
  echo "session-loop: terminating $rt session $sid at the turn boundary (pid $PPID)" >&2
  kill -TERM "$PPID" 2>/dev/null
  return 0
}
