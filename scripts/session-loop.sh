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
main() {

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
RESET_CAP=0; REOPEN=0; RELAUNCH_OVERRIDE=0
while [ $# -gt 0 ]; do
  case "$1" in
    --runtime) RUNTIME="$2"; shift 2 ;;
    --reset-cap) RESET_CAP=1; shift ;;
    --reopen) REOPEN=1; shift ;;
    --relaunch-override) RELAUNCH_OVERRIDE=1; shift ;;
    --max-sessions) MAX_SESSIONS="$2"; shift 2 ;;
    --min-lifetime) MIN_LIFETIME="$2"; shift 2 ;;
    --stall-limit) STALL_LIMIT="$2"; shift 2 ;;
    -*) echo "unknown option: $1" >&2; exit 3 ;;
    *) [ -z "$PROJECT" ] && PROJECT="$1" || { echo "unexpected argument: $1" >&2; exit 3; }; shift ;;
  esac
done
[ -n "$PROJECT" ] || { echo "usage: session-loop.sh <project> [--runtime <rt>] [--max-sessions <N>] [--min-lifetime <secs>] [--stall-limit <N>] [--reset-cap] [--reopen] [--relaunch-override]" >&2; exit 3; }

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
# R2.18 — the alarm's repeat ceiling. A genuinely dead session is dead for days
# (3d 20h measured, D7), and at a flat 900s that is ~368 identical pages. The
# interval doubles from $ALARM up to this after each stall notification and
# resets whenever the session is seen alive again.
ALARM_MAX="${SESSION_LOOP_ALARM_MAX:-3600}"
case "$ALARM_MAX" in ''|*[!0-9]*)
  echo "error: SESSION_LOOP_ALARM_MAX must be a whole number of seconds, got '$ALARM_MAX'" >&2; exit 3 ;;
esac
[ "$ALARM_MAX" -ge "$ALARM" ] || ALARM_MAX="$ALARM"
# R2.18 — kill-on-silence (D7 item 3). Seconds of TRANSCRIPT silence, not of
# wall-clock: see child_probe() for why those are not the same question. 0 is
# off and is today's behaviour exactly. Same no-CLI-flag reasoning as $ALARM.
KILL_AFTER="${SESSION_LOOP_KILL_AFTER:-0}"
case "$KILL_AFTER" in ''|*[!0-9]*)
  echo "error: SESSION_LOOP_KILL_AFTER must be a whole number of seconds, got '$KILL_AFTER'" >&2; exit 3 ;;
esac
LOOPF="$S/.session-loop"; NEXTF="$S/.next-command"; SENTF="$S/.rollover-complete"
# D18 — the staged command's identity, written alongside it by
# launch-next-session.sh --emit. Read at the bootstrap and nowhere else: every
# later iteration consumes $NEXTF before its run, so a non-empty file there is
# provably this chain's own work. Iteration 1 has no such proof and used to
# assume one.
NEXTIDF="$NEXTF.json"
# Where a rejected staged command is parked. Kept rather than deleted: it is the
# evidence of whatever wrote it, and the halt/log line names it.
NEXTSTALEF="$NEXTF.stale"
# R2.17 — the verdict. Written by launch-next-session.sh at the counter bump,
# which is the only moment anything knows both the ending session's number and
# its successor's. It replaces $SENTF entirely as the thing this supervisor
# judges on; $SENTF survives here only to be deleted, for one release.
BUMPF="$S/.session-seq.bump.json"
FLUSHF1="$S/next-session.md"; FLUSHF2="$S/handoff.md"
LOGF="$S/.session-loop.log"; ALARM_STOPF="$S/.session-loop.alarm-stop"
# R2.19 (D9) — the chain budget. `n` used to live only in this process, so every
# supervisor restart handed the work item a fresh MAX_SESSIONS and the cap
# measured "iterations since the last restart" rather than sessions of work:
# work/policy-dev-onboarding/.session-loop.log shows #18, #19, #20 and #27 each
# opening at "1 of 10" straight after a HALT, so sixteen sessions ran under a cap
# of ten and it never once fired. The count therefore has to outlive the
# supervisor, which means a file next to the work item.
BUDGETF="$S/.session-loop.budget"
# P6 (scenario table B2) — the record that this chain was DELIBERATELY ended.
# Machine-local by decision (spec section 5): every work/*/ dotfile is gitignored
# and .gitignore:71-102 is load-bearing for the lineage gate's dirty-evidence
# leg, so widening this to a tracked file is its own change, not a drive-by.
# What it buys is exactly B2 — this machine's supervisor will not restart a
# chain this machine's supervisor ended.
CLOSEDF="$S/.chain-closed"

say()  { printf '[session-loop] %s\n' "$*" >&2; printf '%s %s\n' "$(date -u +%FT%TZ)" "$*" >> "$LOGF"; }

# Content, not mtime (R2.17 §7). A missing file hashes to a constant, so
# "absent before and absent after" is correctly read as unchanged.
hash_file() { if [ -f "$1" ]; then cksum < "$1"; else echo absent; fi; }

# R2.18 — the liveness probe, and the whole of what separates a hang from a
# long session.
#
# The alarm's wall-clock never could: session #28 of this very chain was healthy
# for 59 minutes and drew three identical alarms, #27 drew two while a human sat
# at the keyboard re-running /login after a vendor logout, and every session here
# draws at least one. A knob whose false-positive rate for "hang" is ~100% can be
# a progress ticker but must never be a trigger.
#
# What does separate them is whether the runtime is still WRITING. The
# transcript context-budget.sh already measures grows every turn — measured 11s
# old mid-turn (s29) against a 3d 20h block on ~/projects/token-factory that
# wrote nothing at all. So the probe is that artifact's mtime.
#
# Identity is checked FIRST, always. work/<proj>/.active-session is written by
# the session's own `register`, so early in an iteration it can still name the
# PREVIOUS session, and pids recycle. A record counts only when its pid is live
# AND is a child of this supervisor. No identification -> no verdict -> the
# unconditional notify this alarm has always done, and never a kill. Nothing
# below kills on missing evidence.
SUP_PID=$$
mtime_of() { stat -f %m "$1" 2>/dev/null || stat -c %Y "$1" 2>/dev/null; }
# Echoes "<pid> <transcript-age-seconds>"; rc 1 (and silence) when the running
# child cannot be positively identified or its transcript cannot be read.
child_probe() {
  _rec="$S/.active-session"; [ -f "$_rec" ] || return 1
  _pid="$(jq -r '.pid // empty' "$_rec" 2>/dev/null)"
  _rt="$(jq -r '.runtime // empty' "$_rec" 2>/dev/null)"
  _sid="$(jq -r '.session_id // empty' "$_rec" 2>/dev/null)"
  [ -n "$_pid" ] && [ -n "$_rt" ] && [ -n "$_sid" ] || return 1
  [ "$(ps -o ppid= -p "$_pid" 2>/dev/null | tr -d ' ')" = "$SUP_PID" ] || return 1
  _art="$(jq -r '.artifact // empty' \
    "$ROOT/.context-budget/sessions/$_rt-$_sid.json" 2>/dev/null)"
  [ -n "$_art" ] && [ -f "$_art" ] || return 1
  _m="$(mtime_of "$_art")"; [ -n "$_m" ] || return 1
  printf '%s %s\n' "$_pid" "$(( $(date +%s) - _m ))"
}

# P4a (session-chain-observability, spec.md 4.1) — "is the child past STOP?",
# asked about the child BY NAME. rc 0 = yes; rc 1 = no, or unknowable.
#
# The pin is what makes this askable at all: an unpinned `check` here would
# measure the SUPERVISOR's environment and answer about a session nobody asked
# about (context-budget.sh, "Asking about another session"). Unknowable degrades
# to no, so an unmeasurable child leaves the alarm saying exactly what it says
# today — this branch adds a sharper page, never a new reason to be noisy.
child_past_stop() {
  _psrec="$S/.active-session"; [ -f "$_psrec" ] || return 1
  _prt="$(jq -r '.runtime // empty' "$_psrec" 2>/dev/null)"
  _psid="$(jq -r '.session_id // empty' "$_psrec" 2>/dev/null)"
  [ -n "$_prt" ] && [ -n "$_psid" ] || return 1
  _prc=0
  "$ROOT/scripts/context-budget.sh" check --runtime "$_prt" \
    --session-id "$_psid" --quiet >/dev/null 2>&1 || _prc=$?
  [ "$_prc" -eq 2 ]
}

# R2.21 §1 — the two halves of "was this a vendor logout, or a human?". Both
# are read-only and both degrade to silence: an unresolvable transcript means
# no evidence, and no evidence leaves today's verdict exactly as it was.
#
# Identity comes from the supervisor's own pid, recorded into the child's
# session record at registration — the same attribution session 31 used to tie
# cm_bugs #59 to its transcript. The lock file is deliberately NOT the
# authority here: child_probe can use it because the child is still alive,
# whereas by the time this runs the child's SessionEnd `release` may already
# have removed it. Session records survive the exit they are being asked
# about. The mtime floor is the iteration fence — it rejects a record left by
# an older supervisor that happened to hold this pid, and it rejects the
# earlier children of THIS supervisor, all of which stopped before the current
# child registered.
# The mtime fence is tested FIRST because it is a stat and the identity test is
# a jq: the workspace holds ~150 records on any given day and all but the
# current child's are older than this iteration, so the cheap test does the
# pruning and jq runs once or twice rather than 150 times.
dead_child_artifact() {   # $1 = epoch the child was launched
  _best=""; _best_m=0
  for _f in "$ROOT/.context-budget/sessions/"*.json; do
    [ -f "$_f" ] || continue
    _m="$(mtime_of "$_f")"; [ -n "$_m" ] || continue
    [ "$_m" -ge "$1" ] || continue
    [ "$_m" -ge "$_best_m" ] || continue
    _art="$(jq -r --argjson sup "$SUP_PID" \
      'select(.supervisor_pid == $sup) | .artifact // empty' "$_f" 2>/dev/null)"
    [ -n "$_art" ] && [ -f "$_art" ] || continue
    _best_m="$_m"; _best="$_art"
  done
  [ -n "$_best" ] || return 1
  printf '%s\n' "$_best"
}
# Terminal means terminal: the LAST assistant message in the transcript is the
# auth error, so nothing came after it. That is what separates D12 from the
# transient auth error the runtime retries through — measured, the string
# `authentication_failed` appears in 57 transcripts in this project directory
# and only 9 of them end on it (session 32; the three logouts session 31
# resolved are among the 9, and both of its long rc=0 sessions are not).
#
# The match is on the JSON shape, never on the text alone. A session that
# merely *quotes* the marker — this work item's own sessions do, every time
# they discuss D12 — writes the string into an assistant turn that carries no
# isApiErrorMessage field, and a text-only grep calls that a logout. Verified:
# the session that wrote this function trips a text grep and not this test.
#
# `fromjson?` skips unparsable lines rather than failing the file, and the tail
# window bounds the cost on a long transcript. The window can only ever cause a
# false NEGATIVE (a transcript whose last assistant turn is older than the
# window falls through to today's verdict), never a false positive.
child_logged_out() {   # $1 = transcript
  tail -n 200 "$1" 2>/dev/null \
    | jq -R -c 'fromjson? | select(.type == "assistant")' 2>/dev/null | tail -1 \
    | jq -e '.isApiErrorMessage == true
             and .error == "authentication_failed"
             and ([.message.content[]?.text // ""] | any(startswith("Not logged in")))' \
      >/dev/null 2>&1
}

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

# R2.19 — the budget's three operations. Kept together, above their first
# caller, because the read and the refusal have to agree about what a malformed
# file means: NOT zero. Reading an unparseable budget as "none used" would
# restore the exact defect this section exists to close, and self-healing a
# malformed control file is already declined on this work item (D11 candidate
# 5), so the read halts and names the remedy instead.
BUDGET_USED=0; BUDGET_OPENED_AT=""
budget_read() {
  BUDGET_OPENED_AT="$(date -u +%FT%TZ)"
  [ -f "$BUDGETF" ] || { BUDGET_USED=0; return 0; }
  BUDGET_USED="$(jq -r '.used // empty' "$BUDGETF" 2>/dev/null)"
  case "$BUDGET_USED" in ''|*[!0-9]*)
    halt "the chain budget at ${BUDGETF#"$ROOT/"} is unreadable — refusing to guess how many sessions this chain has already spent; inspect it, then either repair .used or open a new budget with: scripts/session-loop.sh $PROJECT --reset-cap" ;;
  esac
  _o="$(jq -r '.opened_at // empty' "$BUDGETF" 2>/dev/null)"
  [ -n "$_o" ] && BUDGET_OPENED_AT="$_o"
  return 0
}
# Written BEFORE the child starts, never after: a supervisor killed mid-session
# must not hand the chain that session back for free — which is the restart path
# D9 is about, arriving by a different route.
budget_write() {   # $1 = used, $2 = session number just started (optional)
  jq -n --argjson used "$1" --argjson cap "$MAX_SESSIONS" \
     --arg opened_at "$BUDGET_OPENED_AT" --arg at "$(date -u +%FT%TZ)" \
     --arg seq "${2:-}" \
     '{used:$used, cap:$cap, opened_at:$opened_at, last_start_at:$at}
      + (if $seq == "" then {} else {last_seq:$seq} end)' > "$BUDGETF.tmp.$$" \
    && mv "$BUDGETF.tmp.$$" "$BUDGETF" \
    || { rm -f "$BUDGETF.tmp.$$"; halt "could not record the chain budget at ${BUDGETF#"$ROOT/"}"; }
}
# One verdict, two moments. Before R2.19 the cap could only be reached by
# running the loop out; now a restart can arrive with the budget already spent,
# and a supervisor that refuses at start is the SAME verdict as one that stops
# at the end of the loop. They print the same line, name the same remedy, and
# route through notify() for failure mode 11 — the operator who is not watching
# is exactly the one a spent budget is meant to summon.
cap_stop() {   # $1 = sessions used
  notify "chain cap reached ($1 of $MAX_SESSIONS sessions used since $BUDGET_OPENED_AT) — stopping; open a new budget with: scripts/session-loop.sh $PROJECT --reset-cap"
  rm -f "$LOOPF"
  exit 0
}

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

# R2.19 — opening a new budget is the human checkpoint the cap was always meant
# to be, so it is an explicit operator action and nothing else may perform it.
# Refused under a live supervisor for R2.4's reason: the running loop persists
# .used before every child, so a reset landing underneath it would be silently
# overwritten on the next iteration and the operator would be told a lie.
if [ "$RESET_CAP" -eq 1 ]; then
  if [ -f "$LOOPF" ]; then
    rc_other="$(jq -r '.pid // empty' "$LOOPF" 2>/dev/null)"
    if [ -n "$rc_other" ] && kill -0 "$rc_other" 2>/dev/null; then
      echo "error: a supervisor is already running for $PROJECT (pid $rc_other) — stop it before opening a new budget" >&2; exit 3
    fi
  fi
  # Deliberately NOT budget_read: that halts on a malformed file and names
  # --reset-cap as the remedy, so routing the remedy through it would make the
  # one documented way out of a corrupt budget the one thing that cannot run.
  # The reset deletes the file, so it never needs to parse it — the numbers
  # below are for the operator's line and degrade to "?" rather than refusing.
  rc_used="$(jq -r '.used // empty' "$BUDGETF" 2>/dev/null)"
  rc_open="$(jq -r '.opened_at // empty' "$BUDGETF" 2>/dev/null)"
  [ -f "$BUDGETF" ] || rc_open="never"
  rm -f "$BUDGETF"
  say "chain budget reset (${rc_used:-?} of $MAX_SESSIONS had been used since ${rc_open:-?}) — the next start opens a fresh budget"
  exit 0
fi

# G1-a (scenario table B3) — a work item's own off switch stops a supervisor.
#
# B3: this very work item commits ROLLOVER_RELAUNCH=off and a chain started
# against it anyway, because the knob was only ever read at the rollover's
# CLOSING step — the dying session asked it whether to spawn a successor, and
# nobody asked it whether to start one. The user's Q1 decision widens the knob
# from "do not spawn a successor behind my back" to "do not run me unattended at
# all"; this is that second reading, at the only place that can honour it.
#
# No new state: the knob is already resolved above from the item's committed
# context-budget.env, and because it is committed it travels to another checkout
# — which .chain-closed, a machine-local dotfile, does not.
#
# ABOVE the P6 block, not below it, and that is P6's own placement argument
# taken one step further: --reopen DELETES .chain-closed before it returns, so a
# G1-a refusal underneath would refuse a start that had already destroyed the
# evidence P6 exists to keep. A refused start leaves the work item
# byte-identical, and that has to include the marker. Test: GA4.
if [ "${ROLLOVER_RELAUNCH:-}" = "off" ] && [ "$RELAUNCH_OVERRIDE" -eq 0 ]; then
  notify "refusing to start: work/$PROJECT/context-budget.env commits ROLLOVER_RELAUNCH=off, which this work item uses to say it must not be run unattended. Nothing has been started, staged or spent. If you really do want a supervised chain against it, say so explicitly: scripts/session-loop.sh $PROJECT --relaunch-override"
  exit 3
fi
[ "${ROLLOVER_RELAUNCH:-}" = "off" ] \
  && say "starting despite ROLLOVER_RELAUNCH=off in work/$PROJECT/context-budget.env — --relaunch-override was passed"

# P6 (scenario table B2) — a chain that was deliberately ended stays ended.
#
# B2 is the supervisor's half of this work item's blind spot: a session can end a
# chain on purpose, and nothing that outlives it says so, so the next supervisor
# start silently reopens finished work. Three rounds of prose in
# skills/session-rollover/SKILL.md failed on exactly this, which is why the
# countermeasure is a file rather than a paragraph.
#
# Placed HERE, above the lock and above budget_read, rather than at the bootstrap
# where the design first put it, for two reasons measured while writing K2:
#   (a) a refusal that has already acquired .session-loop or written a budget is
#       not free — the operator pays a session number for asking — and the whole
#       point is that a refused start leaves the work item byte-identical; and
#   (b) below budget_read, a closed chain whose budget is also spent would be
#       reported as a CAP problem and the operator told to run --reset-cap, which
#       does not unblock it. The first thing said has to be the true thing.
# The D16 constraint is untouched either way: this is a plain [ -f ] test and it
# is nowhere near the bootstrap's launcher call, which must stay a DIRECT
# invocation (test-session-loop.sh F1, test-emit-mode.sh E10).
if [ -f "$CLOSEDF" ]; then
  cc_seq="$(jq -r '.seq // empty' "$CLOSEDF" 2>/dev/null)"
  cc_at="$(jq -r '.closed_at // empty' "$CLOSEDF" 2>/dev/null)"
  cc_led="$(jq -r '.top_ledger_seq // empty' "$CLOSEDF" 2>/dev/null)"
  if [ "$REOPEN" -eq 1 ]; then
    # H9 must stay POSSIBLE — Round 2 of work/session-loop-hardening was exactly
    # the act of reopening a closed item, so a gate with no override would have
    # made that round unrunnable. It is an explicit human act and it is logged,
    # never silent: the marker is evidence, and destroying evidence quietly is
    # the same defect class one level down.
    rm -f "$CLOSEDF"
    say "reopening work/$PROJECT — session #${cc_seq:-?} had ended this chain at ${cc_at:-?}; --reopen cleared work/$PROJECT/.chain-closed"
  else
    if [ -z "$cc_led" ]; then cc_note="it left no ledger block"
    elif [ "$cc_led" = "$cc_seq" ]; then cc_note="it wrote its ledger block"
    else cc_note="the top ledger block is session $cc_led, not #$cc_seq"
    fi
    notify "refusing to start: session #${cc_seq:-?} deliberately ended this chain at ${cc_at:-?} ($cc_note), recorded in work/$PROJECT/.chain-closed. Nothing has been started, staged or spent. If this work item really does want another session, say so explicitly: scripts/session-loop.sh $PROJECT --reopen"
    exit 3
  fi
fi

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

# Session number in the ledger's top block, empty when absent/unnumbered.
# Extraction mirrors the launcher's lineage-gate grammar (strip ISO dates,
# then "session N"/"session #N" anywhere or "— N"/"— sN" after the heading
# dash); the canonical grammar lives in check-ledger.py.
top_ledger_seq() {
  local hf line
  for hf in "$S/handoff.md" "$S/session_handoff.md"; do
    [ -f "$hf" ] || continue
    line="$(grep -m1 -E '^#[[:space:]]*Session Handoff' "$hf" 2>/dev/null || true)"
    printf '%s\n' "$line" \
      | sed -E 's/[0-9]{4}-[0-9]{2}-[0-9]{2}//g' \
      | grep -oiE 'session[[:space:]]+#?[0-9]+|^#[[:space:]]*session handoff[[:space:]]*[—-][[:space:]]*s?[0-9]+' \
      | head -1 | grep -oE '[0-9]+' | head -1
    return 0
  done
  return 0
}

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
      "work/$PROJECT/.session-seq.bump.json") continue ;;
    esac
    return 0
  done < <(git -C "$ROOT" log --format= --name-only "$before..$after" 2>/dev/null | sort -u)
  return 1
}

# R2.19 — the budget is read and enforced BEFORE the bootstrap below, because
# staging a first session is not free: launch-next-session.sh --emit bumps
# .session-seq, so a supervisor that started on a spent budget and only
# discovered it at the `while` would burn a session number on a session it was
# never going to run.
budget_read
[ "$BUDGET_USED" -lt "$MAX_SESSIONS" ] || cap_stop "$BUDGET_USED"
[ "$BUDGET_USED" -gt 0 ] \
  && say "resuming the chain budget at $BUDGET_USED of $MAX_SESSIONS used (opened $BUDGET_OPENED_AT)"

# D18, the consumption leg. A staged command's whole purpose is to start the
# session it names; if a session registered against this work item AFTER the
# command was staged, that session IS the command's consumer and the file left
# behind is spent. This is the only signal that separates "staged for #N" from
# "staged for #N and already run" — see the sidecar comment in
# launch-next-session.sh for why the counter cannot.
#
# Read-only, and it adds no writer to the emit channel: the registry records are
# written by context-budget.sh register, which every session runs at its first
# turn under every runtime. Timestamps are ISO-8601 Z, so a string compare is a
# chronological one.
#
# Strictly greater-than, deliberately. The comparison is second-granular, and an
# equal second is the tie between the staging session's own registration and its
# emit; calling that "consumed" would reject a command nobody has run. The error
# this direction can make is staging a fresh session one number early, which is
# recoverable and announced; the other direction is the duplicate-session defect.
consumer_since() {   # $1 = the ISO-8601 Z instant the command was staged at
  cs_hit=""
  for cs_f in "$ROOT/.context-budget/sessions/"*.json; do
    [ -f "$cs_f" ] || continue
    cs_out="$(jq -r --arg p "$PROJECT" --arg t "$1" \
      'select(.project == $p and (.registered_at // "") > $t)
       | "\(.runtime // "?")-\(.session_id // "?") (registered at \(.registered_at // "?"))"' \
      "$cs_f" 2>/dev/null)" || continue
    [ -n "$cs_out" ] || continue
    cs_hit="$cs_out"
    break
  done
  printf '%s' "$cs_hit"
}

# D18 — the bootstrap's freshness test, which until R2.20 was `[ -s "$NEXTF" ]`:
# NON-EMPTY read as FRESH. That is not a freshness test, and the cost of the
# mistake is in work/*/handoff-archive.md (the session-18 addendum) — a command
# that had already been run was inherited by a supervisor started afterwards and
# run a second time, producing two sessions with the same number, the second of
# which took the work item's lock and committed nothing.
#
# Prints a reason and returns 0 when the staged command must NOT be inherited;
# returns 1 (silently) when it is provably this chain's unconsumed work — the
# genuine resume case, where a supervisor was killed between a child's --emit and
# the next iteration's consume, and discarding the command would burn a session
# number and lose the mode and options it carries.
staged_stale_reason() {
  if [ ! -f "$NEXTIDF" ]; then
    printf 'it has no identity sidecar at %s, so nothing records which session wrote it, which successor it launches, or when' "${NEXTIDF#"$ROOT/"}"
    return 0
  fi
  if ! jq -e 'type == "object"' "$NEXTIDF" >/dev/null 2>&1; then
    printf 'its identity sidecar %s is missing or is not a JSON object' "${NEXTIDF#"$ROOT/"}"
    return 0
  fi
  ss_by="$(jq -r '.written_by // empty' "$NEXTIDF" 2>/dev/null)"
  if [ "$ss_by" != "launch-next-session.sh" ]; then
    printf "its identity sidecar carries written_by='%s' — nothing sanctioned produced it" "${ss_by:-<none>}"
    return 0
  fi
  ss_proj="$(jq -r '.project // empty' "$NEXTIDF" 2>/dev/null)"
  if [ "$ss_proj" != "$PROJECT" ]; then
    printf "its identity sidecar names work item '%s', not %s" "${ss_proj:-<none>}" "$PROJECT"
    return 0
  fi
  ss_ck="$(jq -r '.command_cksum // empty' "$NEXTIDF" 2>/dev/null)"
  ss_now="$(cksum < "$NEXTF" 2>/dev/null)"
  if [ "$ss_ck" != "$ss_now" ]; then
    printf 'the staged command does not match the checksum its sidecar recorded (%s vs %s) — the two were not written by the same run' "${ss_ck:-<none>}" "${ss_now:-<none>}"
    return 0
  fi
  ss_succ="$(jq -r '.successor // empty' "$NEXTIDF" 2>/dev/null)"
  ss_seq="$(read_seq)"; [ -n "$ss_seq" ] || ss_seq=0
  if [ "$ss_succ" != "$ss_seq" ]; then
    printf 'it stages session #%s but the counter stands at #%s — a later bump or a seq-sync retired it' "${ss_succ:-<none>}" "$ss_seq"
    return 0
  fi
  ss_when="$(jq -r '.written_at // empty' "$NEXTIDF" 2>/dev/null)"
  if [ -z "$ss_when" ]; then
    printf 'its identity sidecar has no written_at, so nothing can date it against the sessions that have run'
    return 0
  fi
  ss_ran="$(consumer_since "$ss_when")"
  if [ -n "$ss_ran" ]; then
    printf 'session %s started against this work item after it was staged at %s — the command has already been run, and running it again is the duplicate-session defect' "$ss_ran" "$ss_when"
    return 0
  fi
  return 1
}

# Bootstrap: iteration 1 has no dying session to stage its command, so the
# supervisor stages it. Every later iteration's command is written by the
# previous session's rollover step 6.
#
# The two cases are not one: a genuinely unconsumed command IS inherited (a
# supervisor restarted after a kill must not discard its predecessor's staging),
# and everything else is parked and re-staged. Never silent either way — a
# discarded command and an inherited one look identical in a log that says
# nothing, and that is exactly how the original defect stayed invisible.
if [ -s "$NEXTF" ]; then
  if stale_why="$(staged_stale_reason)"; then
    say "discarding the staged command: $stale_why"
    mv -f "$NEXTF" "$NEXTSTALEF" 2>/dev/null || rm -f "$NEXTF"
    rm -f "$NEXTIDF"
    say "the discarded command is kept at ${NEXTSTALEF#"$ROOT/"}"
  else
    say "inheriting the staged command: session #$(read_seq) was staged by $(jq -r '.runtime + "-" + .session_id' "$NEXTIDF" 2>/dev/null) at $(jq -r '.written_at' "$NEXTIDF" 2>/dev/null) and has not been run"
  fi
fi
if [ ! -s "$NEXTF" ]; then
  say "staging the first session"
  "$ROOT/scripts/launch-next-session.sh" "$PROJECT" \
    ${RUNTIME:+--runtime "$RUNTIME"} --emit "$NEXTF" \
    || halt "could not stage the first session"
fi

n="$BUDGET_USED"
stalled=0
while [ "$n" -lt "$MAX_SESSIONS" ]; do
  # C4 — reached here, an empty .next-command is unambiguously BROKEN, and the
  # loop's own order is the proof: the bootstrap above guarantees the file is
  # non-empty on entry or halts, and reaching here on a later iteration means the
  # previous one already passed every check below — a readable sentinel, delta
  # == 1, a matching seq, min-lifetime, a fresh measurement. Under R2.17 the
  # end-of-iteration gate catches "bumped but staged nothing" directly, so this
  # is now a backstop rather than the s184 detector it was. The three
  # legitimate endings never reach here — MAX_SESSIONS
  # exits after the loop, a deliberate quit exits on the no-sentinel/delta-0/
  # rc-0 path, and Ctrl-C exits at the interactive pause.
  #
  # seq_before carries the previous iteration's value here, which is exactly the
  # session that just ended. The default only covers the unreachable first
  # iteration, so the message can never trip `set -u`.
  if [ ! -s "$NEXTF" ]; then
    halt "session #${seq_before:-$(read_seq)} ended with a clean verdict but staged no successor — the chain is broken (expected a non-empty $NEXTF)"
  fi
  CMD="$(cat "$NEXTF")"
  # Consumed BEFORE the run, never after: a stale command that survives an
  # iteration is a runaway relaunch waiting to happen (failure mode 5).
  # $SENTF is removed for one release only — nothing reads it after R2.17, but
  # an in-flight session may still write one and it must not accumulate.
  rm -f "$NEXTF" "$NEXTIDF" "$SENTF"

  # R2.17 §7 — the flush post-condition, taken here rather than inferred later
  # from mtimes. R2.15 proposed an mtime guard inside the rollover and it fails
  # both ways: rollover-prep.sh's rotate_handoff rewrites handoff.md at step 1,
  # so mtime passes when the flush never happened, and context-budget.sh touches
  # the session record on every `record`, so it fails when the flush did happen.
  # Content hashes taken by the one process that never talks to a model have
  # neither problem.
  flush_before_1="$(hash_file "$FLUSHF1")"
  flush_before_2="$(hash_file "$FLUSHF2")"

  seq_before="$(read_seq)"; [ -n "$seq_before" ] || seq_before=0
  n=$((n + 1))
  budget_write "$n" "$seq_before"
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
    ( _int="$ALARM"; _stagedticks=0
      while :; do
        [ -e "$ALARM_STOPF" ] && exit 0
        sleep "$_int" || exit 0
        [ -e "$ALARM_STOPF" ] && exit 0
        _probe="$(child_probe || true)"
        # P4a — the one question asked per tick, and only of an identified
        # child: three legs, all read by the supervisor itself. The budget leg
        # is load-bearing. Without it the predicate is "alive and nothing
        # staged", which is true of every healthy session for its whole life,
        # because $NEXTF is consumed BEFORE the run. Cheapest test first.
        _blocked=""
        [ -n "$_probe" ] && [ ! -s "$NEXTF" ] && child_past_stop && _blocked=1
        _blockmsg="session #$seq_before is past its context budget with no successor staged — it may believe its rollover is complete. Nothing is staged at $NEXTF; this chain is blocked until it stages one or quits."
        # P4b — the mirror leg, and the mirror is exact: P4a asks about an
        # EMPTY $NEXTF, this asks about a non-empty one, so the two can never
        # both be set. $NEXTF is consumed before the run, so its presence here
        # proves this child staged. Staging is the last thing a session does
        # and the turn-end hook terminates it, so a child still alive after it
        # staged means the self-kill never fired.
        #
        # The counter is what makes that "still", and it is the false-page
        # guard rather than an optimisation: every healthy H2 rollover has a
        # real window between --emit writing $NEXTF and SIGTERM landing, so one
        # tick catches the handshake mid-flight. Two consecutive ticks mean it
        # persisted. It counts ticks, not time — the timing of the alarm is
        # untouched, exactly as in P4a. Consequence worth knowing: the silent
        # branch doubles $_int after each page, so at the 900s default the
        # second tick lands ~45 min in there and ~30 min in the writing branch,
        # which resets. Both are trivial against the failure this catches — a
        # stuck self-kill otherwise runs the chain to its cap with no report.
        if [ -n "$_probe" ] && [ -s "$NEXTF" ]; then
          _stagedticks=$(( _stagedticks + 1 ))
        else
          _stagedticks=0
        fi
        _staged=""
        [ "$_stagedticks" -ge 2 ] && _staged=1
        _stagedmsg="session #$seq_before staged a successor and is still running — the turn-end self-kill did not fire. Check .session-seq.bump.json's session_id against the live session (the D17 shape), or the runtime's turn-end hook."
        if [ -z "$_probe" ]; then
          # Unidentified: every pre-R2.18 chain, and any session that hangs
          # before it registers. Today's message, today's behaviour.
          notify "session #$seq_before has been running with no exit"
        elif [ "${_probe#* }" -lt "$ALARM" ]; then
          # Alive and writing. Kept as a log line so the per-interval telemetry
          # these handoffs cite survives, but no bell and no hook: this is the
          # false page R2.18 exists to stop.
          _int="$ALARM"
          # Writing is not progress when the handshake is already blocked: a
          # session busily writing its handoff whose successor was never staged
          # is precisely B1, so this one case is a page rather than a log line.
          # Timing is untouched — the branch still ticks at $ALARM.
          if [ -n "$_blocked" ]; then
            notify "$_blockmsg"
          elif [ -n "$_staged" ]; then
            notify "$_stagedmsg"
          else
            say "session #$seq_before is still running (transcript written ${_probe#* }s ago)"
          fi
        elif [ "$KILL_AFTER" -gt 0 ] && [ "${_probe#* }" -ge "$KILL_AFTER" ]; then
          notify "session #$seq_before has written nothing for ${_probe#* }s (limit ${KILL_AFTER}s) — ending it"
          # No backgrounding, no job control, and so no SIGTTIN: the D5b tty
          # objection was about restructuring the launch to GET a pid, and
          # R2.10 put the pid in the record instead. child_probe has already
          # proved this pid is our own live child.
          kill "${_probe% *}" 2>/dev/null
          exit 0
        else
          # Same backoff, same interval; only the words change. "Written nothing
          # for Ns" is true here too, but it points at the wrong thing — the
          # chain is not slow, it is stranded.
          if [ -n "$_blocked" ]; then
            notify "$_blockmsg"
          elif [ -n "$_staged" ]; then
            notify "$_stagedmsg"
          else
            notify "session #$seq_before has written nothing for ${_probe#* }s"
          fi
          [ "$_int" -lt "$ALARM_MAX" ] && _int=$(( _int * 2 ))
          [ "$_int" -gt "$ALARM_MAX" ] && _int="$ALARM_MAX"
        fi
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

  # R2.17 §2 — the gate. Two script-written facts decide everything: whether
  # THIS session staged a successor, and what the launcher recorded at the bump.
  # No agent is told to write either one. $NEXTF was removed above, before the
  # run, so its presence here proves this session staged — the same argument
  # that made the sentinel's presence meaningful, resting on a file whose only
  # writer is `--emit` itself.
  if [ ! -s "$NEXTF" ]; then
    # The layer-3 rule-2 discriminator. The counter is the one fact readable
    # WITHOUT any verdict record, which is what lets absence mean one thing.
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
        || halt "session #$seq_before exited rc=$rc having staged nothing and left the counter unmoved — the command failed to run or died before its first counter write; refusing to call this a quit"
      # R2.21 (D12) — a vendor logout exits 0 too, and reaches here looking
      # exactly like a quit: nothing staged, counter unmoved, rc 0. It has
      # already ended seven sessions across two live chains, every one of them
      # logged as a deliberate quit that no human performed. So rc 0 is
      # necessary for a quit verdict and no longer sufficient: the child's own
      # transcript is asked first, and only a transcript that ENDS in a
      # terminal authentication_failed overrides. No transcript, or a
      # transcript that ends any other way, leaves the quit path untouched.
      #
      # The budget is refunded before the halt, because a logout did no work:
      # budget_write runs at session START (by design — a supervisor killed
      # mid-session must not hand that session back for free), so six 4-minute
      # logouts would otherwise exhaust a cap of 10 having achieved nothing.
      # The refunded number is $n, which this process read through budget_read
      # and incremented itself; nothing is re-read from disk, so there is no
      # path here where an unreadable budget becomes a zero — the D9 invariant
      # R2.19 closed stays closed.
      #
      # Auto-retry is deliberately absent: every logout measured on this
      # machine is the credential kind, which cannot clear without a human
      # (design.md -> R2.21, "Decided against").
      if _art="$(dead_child_artifact "$started_at")" && child_logged_out "$_art"; then
        [ "$n" -gt 0 ] && { n=$((n - 1)); budget_write "$n" "$seq_before"; }
        halt "session #$seq_before ended in a vendor logout, not a human quit — its transcript ends in a terminal authentication_failed (\"Not logged in · Please run /login\"). Nothing was lost: the counter is still at $seq_after, nothing was staged, and the chain budget was refunded ($n of $MAX_SESSIONS used), so work/$PROJECT is byte-identical to its state before session #$seq_before started. Log in, then resume the chain at the same session number with: scripts/session-loop.sh $PROJECT"
      fi
      say "nothing staged and the counter did not move — deliberate quit; ending the chain"
      # A quit ends the chain silently for anyone not watching the log; push
      # it through notify, and say whether the ledger recorded the session.
      top_n="$(top_ledger_seq)"
      if [ -z "$top_n" ]; then
        notify "chain ended: session #$seq_before quit"
      elif [ "$top_n" = "$seq_before" ]; then
        notify "chain ended: session #$seq_before quit after writing its ledger block"
      else
        notify "chain ended: session #$seq_before quit WITHOUT a rollover or checkpoint — no ledger block for it (top block is session $top_n)"
      fi
      # P6 — the marker, written at EXACTLY ONE SITE, and this is it.
      #
      # Its position is the single most important line in P6: it sits BELOW the
      # vendor-logout discriminator above, which halts before reaching here. Hoist
      # it above that block and a logged-out chain is recorded as deliberately
      # closed, so its documented recovery — re-running session-loop.sh <proj> —
      # is refused by the gate near the top of this script, and a credential
      # expiry becomes an ended work item. test-session-loop.sh K4 is that
      # tripwire; T22 owns the classification, K4 owns the ordering.
      #
      # One writer is also the whole argument that the silent rows stay silent:
      # the cap exits through cap_stop, Ctrl-C and the pause exit at the
      # interactive read, and an unsupervised rollover never runs this script at
      # all — none of them reach this line, so none of them can end a work item
      # (K5, K6). $top_n is reused rather than recomputed so the refusal can say
      # whether the closing session left a ledger block behind.
      jq -n --arg seq "$seq_before" --arg closed_at "$(date -u +%FT%TZ)" \
            --arg top_ledger_seq "$top_n" --arg written_by "session-loop.sh" \
            '{seq:$seq, closed_at:$closed_at, top_ledger_seq:$top_ledger_seq, written_by:$written_by}' \
            > "$CLOSEDF" 2>/dev/null \
        || say "warning: could not record the chain close at $CLOSEDF"
      exit 0
    fi
    # The worktree clause is gone with the sentinel: the bump record is written
    # at launch-next-session.sh's own resolved $SEQF, which is anchored to the
    # main checkout, so it cannot strand the way a bare-relative-path sentinel
    # could. What is left is the s184 shape.
    halt "the counter moved ${seq_before}->${seq_after} but session #$seq_before staged no successor — the chain is broken (expected a non-empty $NEXTF)"
  fi

  # Delta first, deliberately: it is the one fact readable without the record,
  # so a miscounted chain is named for what it is rather than reported as an
  # untrustworthy verdict.
  [ "$delta" -eq 1 ] \
    || halt "session-number delta was $delta, not 1 (${seq_before}->${seq_after}) — numbering rule 5"

  # The verdict record. Every check below names $seq_before, never a field read
  # out of the record — a halt message that interpolates a field the record does
  # not have prints an empty session number, which is D11's own fingerprint.
  jq -e 'type == "object"' "$BUMPF" >/dev/null 2>&1 \
    || halt "session #$seq_before staged a successor but its bump record at $BUMPF is missing or is not a JSON object — refusing to guess whether this was a clean end (it is written by scripts/launch-next-session.sh at the counter bump; a hand-written one is D11)"

  rec_by="$(jq -r '.written_by // empty' "$BUMPF" 2>/dev/null)"
  [ "$rec_by" = "launch-next-session.sh" ] \
    || halt "the bump record at $BUMPF carries written_by='${rec_by:-<none>}' — nothing sanctioned produced it, so it is not a verdict this supervisor can act on (session #$seq_before)"

  rec_seq="$(jq -r '.seq // empty' "$BUMPF" 2>/dev/null)"
  [ "$rec_seq" = "$seq_before" ] \
    || halt "the bump record claims session '${rec_seq:-<none>}' but #$seq_before is what ran — seq-sync: the record at $BUMPF is not this session's"

  rec_succ="$(jq -r '.successor // empty' "$BUMPF" 2>/dev/null)"
  [ "$rec_succ" = "$seq_after" ] \
    || halt "the bump record names successor '${rec_succ:-<none>}' but the counter is at $seq_after — seq-sync: the record at $BUMPF has been retired by a later counter write (session #$seq_before)"

  sent_seq="$seq_before"

  # R2.17 §7 — the flush. A session that staged a successor and bumped the
  # counter has, by definition, run its rollover; a rollover that changed
  # neither next-session.md nor handoff.md did not flush, and its successor
  # would start from the predecessor's instructions. Checked on the staged path
  # only: a deliberate quit (above) is a human's call and never reaches here.
  if [ "$(hash_file "$FLUSHF1")" = "$flush_before_1" ] \
     && [ "$(hash_file "$FLUSHF2")" = "$flush_before_2" ]; then
    halt "session #$seq_before rolled over without changing work/$PROJECT/next-session.md or handoff.md — byte-identical across the whole session, so the flush did not happen and the successor would read its predecessor's instructions"
  fi

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
    rec="$ROOT/.context-budget/sessions/$(jq -r '.runtime' "$BUMPF")-$(jq -r '.session_id' "$BUMPF").json"
    if [ -f "$rec" ]; then
      rec_mtime="$(stat -f %m "$rec" 2>/dev/null || stat -c %Y "$rec" 2>/dev/null || echo 0)"
      [ "$rec_mtime" -ge "$started_at" ] \
        || halt "session #$sent_seq left no measurement of its own after it started ($rec is older than the session) — it was almost certainly measuring a predecessor's transcript"
    else
      # Not a halt — the identity in the record may name a runtime this checkout
      # has no telemetry for — but never silent either: a skipped freshness check
      # that nobody can see reads exactly like a passed one (R2.17 §2).
      say "min-lifetime: no session record at $rec — freshness of the measurement not checked for session #$sent_seq"
    fi
  fi

  mode="$(jq -r '.mode // "handsoff"' "$BUMPF")"
  reason="$(jq -r '.reason // ""' "$BUMPF")"
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
  cap_stop "$n"
fi
exit 0
}
main "$@"
