#!/usr/bin/env bash
# File: scripts/session-loop.sh
# Purpose: Run a chain of rollover sessions unattended. The only new process in
#          the session-loop design, and the only one that never talks to a model:
#          it evals a command a dying session staged, waits, and then proves the
#          iteration against two facts it can read itself — the session counter
#          and the rollover sentinel.
# Usage:   session-loop.sh <project> [--runtime <rt>] [--max-sessions <N>]
# Exit:    0 clean end of chain / 1 halt-and-notify / 3 startup refusal
#          130/143/129 honest signal deaths (INT untrapped; TERM/HUP re-raised)
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
# No CLI flag, deliberately, and for the same reason SESSION_LOOP_NOTIFY has
# none: this is an unattended-chain setting you commit next to the chain, not one
# you retype per launch. Refuse a non-numeric value rather than silently reading
# it as "off" — a knob that quietly does nothing is the defect class this whole
# work item is about.
ALARM="${SESSION_LOOP_ALARM:-0}"
case "$ALARM" in ''|*[!0-9]*)
  echo "error: SESSION_LOOP_ALARM must be a whole number of seconds, got '$ALARM'" >&2; exit 3 ;;
esac
LOOPF="$S/.session-loop"; NEXTF="$S/.next-command"; SENTF="$S/.rollover-complete"
LOGF="$S/.session-loop.log"; ALARM_STOPF="$S/.session-loop.alarm-stop"

say()  { printf '[session-loop] %s\n' "$*" >&2; printf '%s %s\n' "$(date -u +%FT%TZ)" "$*" >> "$LOGF"; }

# Every inherited `die` in launch-next-session.sh was written for a watching
# human; unattended, a stopped chain is silent (failure mode 11). So a halt is
# never just a stop: it is a stop plus a notification a human can find later.
#
# Two callers now: halt(), and the D5b stall alarm. The "HALT: " prefix therefore
# lives in halt() rather than here — a stall alarm is not a halt, and a hook that
# receives both has to be able to tell them apart.
notify() {
  say "$*"
  printf '\a' >&2
  [ -n "${SESSION_LOOP_NOTIFY:-}" ] && "$SESSION_LOOP_NOTIFY" "session-loop $PROJECT: $*" >/dev/null 2>&1
  return 0
}
halt() { notify "HALT: $*"; rm -f "$LOOPF"; exit 1; }

# D5b reap, one function so every exit path agrees on the order. The stop flag
# is written FIRST (TE6 A2): pkill can land while the subshell is inside
# notify(), and without the flag the loop would fork a FRESH sleep in the gap
# before `kill` arrives — an orphan that keeps the stdout it inherited, so a
# caller running the supervisor inside $(...) blocks for up to a full alarm
# interval after the chain finished (measured 6/6, 6-11s holds, pre-fix). The
# flag makes "we are reaping" a fact the subshell can read at its loop top:
# the flag closes the *respawn loop* — a reap landing in the microsecond gap
# between the flag check and the `sleep` fork can still orphan that one sleep,
# bounded by one interval; accepted, TE6 R7. Killing the child
# sleep (pkill -P) stays load-bearing for the in-sleep case: an orphaned sleep
# also holds stdout (measured 21s on a 1s session at SESSION_LOOP_ALARM=20).
# The kill is belt-and-braces and the wait is the reap. Pinned by D5b-e/f/g.
alarm=""
reap_alarm() {
  [ -n "$alarm" ] || return 0
  : > "$ALARM_STOPF"
  pkill -P "$alarm" 2>/dev/null
  kill "$alarm" 2>/dev/null
  wait "$alarm" 2>/dev/null
  alarm=""
  rm -f "$ALARM_STOPF"
}

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
# The universal backstop: reap_alarm and the rm are both idempotent, so EXIT
# can safely re-run them after a signal handler (or an untrapped signal death,
# where bash still runs the EXIT trap — measured during A3) already did the
# work. Widened from rm-only per TE6 R5.
trap 'reap_alarm; rm -f "$LOOPF"' EXIT
# TE6 A3 + R5/R6: an EXIT trap alone leaves a plain `kill <supervisor>` — the
# documented operator move against a hung chain — with an init-reparented
# alarm subshell paging forever. The TERM/HUP legs reap it; bash defers the
# trap until the in-flight child returns, so the reap always sees the alarm's
# real state. Each handler then untraps and RE-RAISES its own signal, so the
# supervisor dies BY the signal (observed 143/129): to a wait()-level reader
# (launchd, a wrapper) a killed chain is a signal death, never rc 0's
# documented "clean end of chain". A signal death is not a verdict and does
# not route through notify() — the killer is standing right there. Pinned by
# D5b-h/h1/h2/h3.
#
# INT is deliberately NOT trapped (TE6 R5): a keyboard Ctrl-C — the documented
# cancel-a-turn gesture — is delivered to the whole foreground process group,
# so the child AND the alarm subshell receive it directly and the terminal
# does the reaping; no trap is needed. A trapped-but-deferred INT would
# instead end the chain silently (before sentinel evaluation) the moment a
# child SURVIVED the cancel — the A3 regression. Untrapped, bash's
# wait-and-cooperative-exit does the right thing in both directions: child
# survives INT -> chain continues; child dies of INT -> supervisor exits 130
# with the EXIT trap cleaning up. The leak A3 closed was a targeted kill,
# which is TERM — still trapped. Pinned by D5b-i.
on_signal() {   # $1 = TERM | HUP
  reap_alarm
  rm -f "$LOOPF"
  trap - "$1"
  kill -s "$1" $$   # re-raise: die BY the signal, not with a number
}
trap 'on_signal TERM' TERM
trap 'on_signal HUP'  HUP

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
  # C4 — reached here, an empty .next-command is unambiguously BROKEN, and the
  # loop's own order is the proof: the bootstrap above guarantees the file is
  # non-empty on entry or halts, and reaching here on a later iteration means the
  # previous one already passed every check below — a readable sentinel, delta
  # == 1, a matching seq, min-lifetime, a fresh measurement. The sentinel is
  # SKILL.md step 8, written AFTER step 6 stages, so a clean sentinel asserts a
  # successor was staged. "Clean sentinel, nothing staged" is a contradiction:
  # the s184 shape. The three legitimate endings never reach here — MAX_SESSIONS
  # exits after the loop, a deliberate quit exits on the no-sentinel/delta-0/
  # rc-0 path, and Ctrl-C exits at the interactive pause.
  #
  # seq_before carries the previous iteration's value here, which is exactly the
  # session that just ended. The default only covers the unreachable first
  # iteration, so the message can never trip `set -u`.
  if [ ! -s "$NEXTF" ]; then
    halt "session #${seq_before:-$(read_seq)} ended with a clean sentinel but staged no successor — the chain is broken (expected a non-empty $NEXTF)"
  fi
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
  # D5b — the stall alarm. It repeats, so a chain that hangs at 03:00 keeps
  # signalling, and it routes through notify() so SESSION_LOOP_NOTIFY — already
  # the documented escape hatch for an unattended chain — can page a human.
  # Default 0 (off) preserves today's behaviour exactly.
  #
  # It does NOT touch the child. The eval below is foreground and tty-inheriting
  # on purpose (see just above); backgrounding the child to get a killable pid
  # takes the terminal away from it, and an interactive session would then take
  # SIGTTIN/SIGTTOU on its first read. So the alarm is a background subshell
  # started before the eval and reaped after it, and the child is untouched.
  #
  # Kill-on-timeout is deliberately NOT here (design.md §5): it is a genuinely
  # riskier change for that same tty reason, and it is not what s184 needed — a
  # supervisor that TELLS you it has been blocked for two hours is the whole of
  # the reported gap. Deferred, not declined.
  if [ "$ALARM" -gt 0 ]; then
    rm -f "$ALARM_STOPF"
    # The loop-top stop-flag check is the A2 respawn guard (see reap_alarm);
    # the post-sleep check only spares one spurious notify when the reap lands
    # exactly between a completed sleep and the notify.
    ( while :; do
        [ -e "$ALARM_STOPF" ] && exit 0
        sleep "$ALARM" || exit 0
        [ -e "$ALARM_STOPF" ] && exit 0
        notify "session #$seq_before has been running with no exit"
      done ) &
    alarm=$!
  fi

  eval "$CMD"
  rc=$?
  # Reap order (stop flag, then child sleep, then subshell) and why each half
  # is load-bearing: see reap_alarm above. Pinned by D5b-e/D5b-f/D5b-g.
  reap_alarm
  say "session #$seq_before ended rc=$rc"

  seq_after="$(read_seq)"; [ -n "$seq_after" ] || seq_after=0
  delta=$((seq_after - seq_before))

  if [ ! -f "$SENTF" ]; then
    # The layer-3 rule-2 discriminator. The counter is the one fact readable
    # WITHOUT the sentinel, which is what lets absence mean one thing.
    if [ "$delta" -eq 0 ]; then
      # TE6 A6: a quit verdict additionally requires the child to have EXITED
      # 0. rc!=0 with no sentinel and an unmoved counter is a command that
      # never ran (127: missing binary in a cron/launchd start) or a session
      # that crashed before its first counter write — the s184 class through
      # the seam C4 left open — never a human typing /exit. Supervisor signal
      # deaths are NOT this branch: TERM/HUP re-raise in on_signal (TE6 R6)
      # and never reach the classifier; A6 owns only the classifier-reachable
      # child-rc cases.
      [ "$rc" -eq 0 ] \
        || halt "session #$seq_before exited rc=$rc with no sentinel and an unmoved counter — the command failed to run or died before its first counter write; refusing to call this a quit"
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
    # The bare reset is now CORRECT (TE6 R5): the loop level deliberately has
    # no INT trap, so `trap - INT` returns exactly to that state. The A3-era
    # restore re-installed a deferred INT leg here and would re-create the
    # Ctrl-C-ends-the-chain bug on every iteration after the first pause.
    trap - INT
  fi
done

if [ "$n" -ge "$MAX_SESSIONS" ]; then
  say "chain cap reached ($MAX_SESSIONS sessions) — stopping"
fi
exit 0
