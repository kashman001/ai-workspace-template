#!/usr/bin/env bash
# File: scripts/session-loop.sh
# Purpose: Run a chain of rollover sessions unattended. The only new process in
#          the session-loop design, and the only one that never talks to a model:
#          it evals a command a dying session staged, waits, and then proves the
#          iteration against two facts it can read itself — the session counter
#          and the rollover sentinel.
# Usage:   session-loop.sh <project> [--runtime <rt>] [--max-sessions <N>]
# Exit:    0 clean end of chain / 1 halt-and-notify / 3 startup refusal
# Spec:    docs/superpowers/specs/2026-08-21-session-loop-design.md
set -u

# Workspace identity = repository identity, not checkout path. Every path below
# is anchored to $ROOT, and that is not a style choice: a bare relative
# work/<proj>/.rollover-complete lands in an isolated child's own worktree, the
# supervisor reads the main checkout, finds nothing, and exits reporting a clean
# shutdown ("Worktrees" -> layer 3, rule 1). Same resolver as
# launch-next-session.sh:49-58.
SCRIPT_ROOT="$(cd "$(dirname "$0")/.." && pwd -P)"
resolve_workspace_root() {
  local common repo
  if common="$(git -C "$SCRIPT_ROOT" rev-parse --git-common-dir 2>/dev/null)"; then
    case "$common" in /*) : ;; *) common="$SCRIPT_ROOT/$common" ;; esac
    repo="$(cd "$common/.." 2>/dev/null && pwd -P)"
    if [ -n "$repo" ] && [ -f "$repo/scripts/launch-next-session.sh" ]; then
      printf '%s' "$repo"; return
    fi
  fi
  printf '%s' "$SCRIPT_ROOT"
}
ROOT="$(resolve_workspace_root)"

# Knobs come from context-budget.env (checked in — raise in one place), with a
# committed work/<proj>/context-budget.env overriding per work item, the same
# precedence ROLLOVER_RELAUNCH already uses.
[ -f "$ROOT/context-budget.env" ] && . "$ROOT/context-budget.env"

PROJECT=""; RUNTIME=""; MAX_SESSIONS=""; MIN_LIFETIME=""; STALL_LIMIT=""
while [ $# -gt 0 ]; do
  case "$1" in
    --runtime) RUNTIME="$2"; shift 2 ;;
    --max-sessions) MAX_SESSIONS="$2"; shift 2 ;;
    --min-lifetime) MIN_LIFETIME="$2"; shift 2 ;;
    --stall-limit) STALL_LIMIT="$2"; shift 2 ;;
    -*) echo "unknown option: $1" >&2; exit 3 ;;
    *) [ -z "$PROJECT" ] && PROJECT="$1" || { echo "unexpected argument: $1" >&2; exit 3; }; shift ;;
  esac
done
[ -n "$PROJECT" ] || { echo "usage: session-loop.sh <project> [--runtime <rt>] [--max-sessions <N>] [--min-lifetime <secs>] [--stall-limit <N>]" >&2; exit 3; }

S="$ROOT/work/$PROJECT"
[ -d "$S" ] || { echo "error: no such work directory: work/$PROJECT" >&2; exit 3; }
[ -f "$S/context-budget.env" ] && . "$S/context-budget.env"
[ -n "$MAX_SESSIONS" ] || MAX_SESSIONS="${SESSION_LOOP_MAX_SESSIONS:-10}"
[ -n "$MIN_LIFETIME" ] || MIN_LIFETIME="${SESSION_LOOP_MIN_LIFETIME:-60}"
[ -n "$STALL_LIMIT" ] || STALL_LIMIT="${SESSION_LOOP_STALL_LIMIT:-3}"
LOOPF="$S/.session-loop"; NEXTF="$S/.next-command"; SENTF="$S/.rollover-complete"
LOGF="$S/.session-loop.log"

say()  { printf '[session-loop] %s\n' "$*" >&2; printf '%s %s\n' "$(date -u +%FT%TZ)" "$*" >> "$LOGF"; }

# Every inherited `die` in launch-next-session.sh was written for a watching
# human; unattended, a stopped chain is silent (failure mode 11). So a halt is
# never just a stop: it is a stop plus a notification a human can find later.
notify() {
  say "HALT: $*"
  printf '\a' >&2
  [ -n "${SESSION_LOOP_NOTIFY:-}" ] && "$SESSION_LOOP_NOTIFY" "session-loop $PROJECT: $*" >/dev/null 2>&1
  return 0
}
halt() { notify "$*"; rm -f "$LOOPF"; exit 1; }

# One supervisor per work item. Two chains driving the same counter would each
# see the other's increments and both would halt on a delta != 1 — a confusing
# way to discover a mistake that is cheap to refuse up front.
if [ -f "$LOOPF" ]; then
  other="$(jq -r '.pid // empty' "$LOOPF" 2>/dev/null)"
  if [ -n "$other" ] && kill -0 "$other" 2>/dev/null; then
    echo "error: a supervisor is already running for $PROJECT (pid $other)" >&2; exit 3
  fi
  say "clearing a stale .session-loop (pid ${other:-unknown} is gone)"
fi

# Failure mode 6: fail fast on an untrusted workspace rather than hanging on a
# dialog nobody is there to answer.
git -C "$ROOT" rev-parse --git-dir >/dev/null 2>&1 \
  || { echo "error: $ROOT is not a git repository" >&2; exit 3; }
[ -f "$S/next-session.md" ] \
  || { echo "error: work/$PROJECT has no next-session.md — nothing to launch" >&2; exit 3; }

cd "$ROOT" || exit 3
export TF_SESSION_LOOP=1
# The turn-end exit hooks need the work item to locate their sentinel:
# no vendor Stop payload carries it, so the supervisor supplies it.
export TF_SESSION_LOOP_PROJECT="$PROJECT"
jq -n --argjson pid "$$" --arg project "$PROJECT" --arg started_at "$(date -u +%FT%TZ)" \
  '{pid:$pid, project:$project, started_at:$started_at}' > "$LOOPF"
trap 'rm -f "$LOOPF"' EXIT

read_seq() { tr -cd '0-9' < "$S/.session-seq" 2>/dev/null; }

# Stall detection (failure mode 2; spec open question 5, answered 2026-08-25).
# Progress = a commit touching something OUTSIDE the rollover bookkeeping set.
# The exclusion is the entire guard: rollover writes the ledger and the launcher
# every single session, verified on this work item — session 5's 7266007 touched
# handoff.md and next-session.md and nothing else. Without the clause, "did this
# session commit?" is always yes and the signal measures the supervisor's own
# machinery instead of the agent's progress.
#
# Ticket-state transitions need no separate mechanism: work/<proj>/issues/ is not
# in the bookkeeping set, so a commit touching it already counts here.
#
# Files-touched never counts on its own — a stuck agent rewrites the same file
# every session. Only committed changes are read.
session_made_progress() {  # $1 = HEAD before the session
  local before after f
  before="$1"
  after="$(git -C "$ROOT" rev-parse HEAD 2>/dev/null)" || return 0
  [ "$before" = "$after" ] && return 1
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    case "$f" in
      "work/$PROJECT/next-session.md") continue ;;
      "work/$PROJECT/handoff.md") continue ;;
      "work/$PROJECT/handoff-archive.md") continue ;;
      "work/$PROJECT/.session-seq") continue ;;
      "work/$PROJECT/.session-seq.provenance.json") continue ;;
    esac
    return 0
  done < <(git -C "$ROOT" log --format= --name-only "$before..$after" 2>/dev/null | sort -u)
  return 1
}

# Bootstrap: iteration 1 has no dying session to stage its command, so the
# supervisor stages it. Every later iteration's command is written by the
# previous session's rollover step 6.
if [ ! -s "$NEXTF" ]; then
  say "staging the first session"
  "$ROOT/scripts/launch-next-session.sh" "$PROJECT" \
    ${RUNTIME:+--runtime "$RUNTIME"} --emit "$NEXTF" \
    || halt "could not stage the first session"
fi

n=0
stalled=0
while [ "$n" -lt "$MAX_SESSIONS" ]; do
  [ -s "$NEXTF" ] || { say "no staged command — nothing to run"; break; }
  CMD="$(cat "$NEXTF")"
  # Consumed BEFORE the run, never after: a stale command that survives an
  # iteration is a runaway relaunch waiting to happen (failure mode 5).
  rm -f "$NEXTF" "$SENTF"

  seq_before="$(read_seq)"; [ -n "$seq_before" ] || seq_before=0
  n=$((n + 1))
  say "starting session #$seq_before ($n of $MAX_SESSIONS)"

  # Foreground, inheriting the tty — the child behaves exactly as a directly
  # launched session (the same inheritance launch-next-session.sh:470-475 relies
  # on when it execs an attached run). Ctrl-C reaches the child here, as today.
  started_at="$(date +%s)"
  head_before="$(git -C "$ROOT" rev-parse HEAD 2>/dev/null || echo none)"
  eval "$CMD"
  rc=$?
  say "session #$seq_before ended rc=$rc"

  seq_after="$(read_seq)"; [ -n "$seq_after" ] || seq_after=0
  delta=$((seq_after - seq_before))

  if [ ! -f "$SENTF" ]; then
    # The layer-3 rule-2 discriminator. The counter is the one fact readable
    # WITHOUT the sentinel, which is what lets absence mean one thing.
    if [ "$delta" -eq 0 ]; then
      say "no sentinel and the counter did not move — deliberate quit; ending the chain"
      exit 0
    fi
    halt "the counter moved ${seq_before}->${seq_after} but no sentinel is in the main checkout — a session ended somewhere I did not look (check for a stranded .rollover-complete inside a worktree)"
  fi

  jq -e . "$SENTF" >/dev/null 2>&1 \
    || halt "the sentinel at $SENTF is unreadable — refusing to guess whether this was a clean end"

  [ "$delta" -eq 1 ] \
    || halt "session-number delta was $delta, not 1 (${seq_before}->${seq_after}) — numbering rule 5"

  sent_seq="$(jq -r '.seq' "$SENTF")"
  [ "$sent_seq" = "$seq_before" ] \
    || halt "the sentinel claims session #$sent_seq but #$seq_before is what ran"

  # failure mode 1 + layer 3 rule 4. A session that rolled over faster than
  # MIN_LIFETIME did not do work — the overwhelmingly likely cause is a
  # first-turn budget check reading a PREDECESSOR's token count from shared
  # telemetry (docs/context-budget.md, the gemini hook row, recorded as
  # "accepted" precisely because a human catches it). There is no human here.
  #
  # Lifetime alone is necessary but not sufficient: a successor that isolates
  # into a worktree without re-registering measures nothing at all, and would
  # look identical to a healthy long session. So also require that THIS session
  # produced a measurement of its own after it started.
  elapsed=$(( $(date +%s) - started_at ))
  if [ "$MIN_LIFETIME" -gt 0 ] && [ "$elapsed" -lt "$MIN_LIFETIME" ]; then
    halt "session #$sent_seq rolled over after ${elapsed}s, under the ${MIN_LIFETIME}s min-lifetime — this is the shape of a first-turn spurious STOP, not of work"
  fi
  if [ "$MIN_LIFETIME" -gt 0 ]; then
    rec="$ROOT/.context-budget/sessions/$(jq -r '.runtime' "$SENTF")-$(jq -r '.session_id' "$SENTF").json"
    if [ -f "$rec" ]; then
      rec_mtime="$(stat -f %m "$rec" 2>/dev/null || stat -c %Y "$rec" 2>/dev/null || echo 0)"
      [ "$rec_mtime" -ge "$started_at" ] \
        || halt "session #$sent_seq left no measurement of its own after it started ($rec is older than the session) — it was almost certainly measuring a predecessor's transcript"
    fi
  fi

  mode="$(jq -r '.mode' "$SENTF")"
  reason="$(jq -r '.reason // ""' "$SENTF")"
  say "session #$sent_seq rolled over cleanly (mode=$mode reason=$reason)"

  # The [ "$mode" = "handsoff" ] condition is deliberate and matches the spec's
  # guards table: under interactive the human is the stall detector, and halting
  # a chain someone is sitting in front of would be the supervisor overruling the
  # one observer who can actually judge.
  if [ "$STALL_LIMIT" -gt 0 ] && [ "$mode" = "handsoff" ] && [ "$head_before" != "none" ]; then
    if session_made_progress "$head_before"; then
      stalled=0
    else
      stalled=$((stalled + 1))
      say "session #$sent_seq committed nothing outside the rollover bookkeeping set ($stalled of $STALL_LIMIT)"
      [ "$stalled" -lt "$STALL_LIMIT" ] \
        || halt "$STALL_LIMIT consecutive sessions made no progress — every commit touched only the launcher, the ledger, and the counter. The chain is running its own bookkeeping, not the work."
    fi
  fi

  if [ "$mode" = "interactive" ]; then
    # A keypress, not a countdown: if the human is mid-sentence when a countdown
    # fires, the unsubmitted text dies. Waiting also lets them scroll back and
    # copy from the dead session first. Ctrl-C here stops the loop rather than
    # being swallowed (failure mode 7).
    trap 'say "interrupted at the pause — ending the chain"; exit 0' INT
    printf '[session-loop] session #%s ended. Press Enter to start #%s (Ctrl-C to stop). ' \
      "$sent_seq" "$seq_after" >&2
    read -r _ </dev/tty || { say "no tty for the interactive pause — ending the chain"; exit 0; }
    trap - INT
  fi
done

if [ "$n" -ge "$MAX_SESSIONS" ]; then
  say "chain cap reached ($MAX_SESSIONS sessions) — stopping"
fi
exit 0
