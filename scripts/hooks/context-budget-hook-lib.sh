#!/usr/bin/env bash
# File: scripts/hooks/context-budget-hook-lib.sh
# Purpose: shared core for the context-budget hook dispatcher
#          (context-budget-hook.sh over context-budget-adapters.conf). Sourced,
#          not executed. Escalation-only, throttled, fail-open — the dispatcher
#          owns stdin parsing and the vendor output envelope, nothing else.
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
  # Worktree sessions: share local-only work/<item>/ dirs in from the main
  # checkout (backlog L45). Before the throttle, on every firing — a write
  # must never race the link. No-op (one git call) in the main checkout.
  [ -x "$WORKSPACE_ROOT/scripts/link-local-work.sh" ] \
    && "$WORKSPACE_ROOT/scripts/link-local-work.sh" "$PWD" >/dev/null 2>&1
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

# P2 (session-chain-observability, B1). Both messages used to END at a pointer
# to skills/session-rollover/SKILL.md; three incidents show the pointer is not
# followed at the moment of need. So the STOP message now carries the operative
# sentence inline: step 6 IS the completion criterion, and --emit takes no path
# argument (a self-computed one resolves to the git root under nesting and to a
# worktree under isolation, and the supervisor then reads the main checkout,
# finds nothing, and reports a clean shutdown).
#
# WARN gains the step-6 clause only, not the invariant — WARN is not the moment
# to stage. Known cost, stated rather than hidden: the hook is runtime-side and
# project-agnostic, with no access to the record's `staged` or supervision
# state at message time, so a session deliberately ENDING the chain (H3) still reads
# "stage your successor" at STOP. Making the hook project-aware is not worth a
# new dependency for a prose nudge; context-budget.sh's successor_advisory is
# the leg that IS two-sided.
budget_hook_message() {
  local status="$1" tokens="$2" threshold="$3"
  if [ "$status" = "STOP" ]; then
    echo "CONTEXT BUDGET STOP: this session is at $tokens tokens, past the $threshold-token dumb-zone threshold. Finish the current atomic step only, then tell the user and run the session-rollover workflow (skills/session-rollover/SKILL.md). It is not finished until step 6 has staged your successor: run the launcher with a BARE --emit — never a path you computed yourself — and that is the last thing you do in this session. Do not start new work in this session."
  else
    echo "CONTEXT BUDGET WARN: this session is at $tokens tokens, approaching the $threshold-token dumb-zone threshold. Wrap up the current work unit and avoid loading large files; prepare to run the session-rollover workflow (skills/session-rollover/SKILL.md) soon — it is not finished until step 6 has staged your successor. Mention this warning to the user in your next reply."
  fi
}

# --- session-loop supervisor: turn-end exit ---------------------------------
#
# The hook does NOT decide whether the session should end — the agent already
# did, by staging its successor through the launcher. The hook's whole job is
# to notice that the record's `staged` block names this session and act. That
# is what keeps this vendor-specific surface as thin as it is: one condition,
# read from the one record the design already requires.
#
# Three conditions, all necessary:
#   TF_SESSION_LOOP=1        — nobody is supervising otherwise (opt-in contract)
#   staged != null           — a successor is staged (launch-next-session.sh --emit
#                              is the only writer, and the supervisor consumes the
#                              block BEFORE each run, so it can only be this run's)
#   staged.by is MINE        — not a predecessor's leftover, not a sibling's
#
# The decision and the signal are separate functions because not every runtime
# signals: opencode's exit path runs inside its own plugin process and self-kills
# with process.pid, so it needs the predicate without the SIGTERM.

# budget_hook_should_exit <session_id> <project>
#   rc 0 when the record says this session staged its successor under the
#   supervisor; rc 1 in every other case, including every error.
budget_hook_should_exit() {
  local sid="${1:-}" proj="${2:-}" rec
  [ "${TF_SESSION_LOOP:-}" = "1" ] || return 1
  [ -n "$sid" ] && [ -n "$proj" ] || return 1
  command -v jq >/dev/null 2>&1 || return 1
  # WORKSPACE_ROOT, not budget_hook_resolve_root(): the resolver deliberately
  # ignores the env override so it can find the main checkout from a worktree,
  # and every other reader in this lib goes through WORKSPACE_ROOT.
  rec="$WORKSPACE_ROOT/work/$proj/session-state.json"
  jq -e --arg sid "$sid" '.staged != null and .staged.by == $sid' "$rec" >/dev/null 2>&1
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
