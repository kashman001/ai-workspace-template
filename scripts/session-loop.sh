#!/usr/bin/env bash
# File: scripts/session-loop.sh
# Purpose: Run a chain of rollover sessions unattended, on the work item's
#          session record (work/<project>/session-state.json, Stage 4). The
#          supervisor owns the record's `chain` block. Each iteration it checks
#          the chain budget, stages the first session through the launcher when
#          nothing is staged, exports the successor's number, records the child
#          in `chain`, runs it in the foreground, and reads the verdict from what
#          the launcher wrote at the bump (`launch.predecessor`, `staged.by`)
#          plus `seq` before and after. It never talks to a model.
# Usage:   session-loop.sh <project> [--runtime <rt>] [--max-sessions <N>]
#            [--min-lifetime <secs>] [--stall-limit <N>] [--reset-cap] [--reopen]
#            [--relaunch-override]
# Exit:    0 chain ended (verdict quit_stop / quit_plain / cap, or the
#          interactive pause) / 1 broken / 3 usage / 4 refused at start
#          130/143/129 signal deaths (INT untrapped; TERM/HUP re-raised)
# Lines:   on stderr and in work/<project>/.session-loop.log; the code and the
#          exit status are the contract, the prose is not:
#            session-loop: refused reason=<code> [k=v …] — <remedy>
#            session-loop: verdict=<code> seq=<n> [k=v …]
#            session-loop: broken reason=<code> seq=<n> [k=v …] — <remedy>
#          Codes (evaluation/stage3-design-v2.md, gate table): start refusals
#          record_unreadable, schema_mismatch, chain_closed, supervisor_live,
#          relaunch_off, staged_invalid leg=spent, and the launcher's own code
#          when the bootstrap stage is refused; verdicts staged, quit_stop,
#          quit_plain, cap; broken rc_nonzero, logout, staged_invalid
#          leg=<seq|staged|predecessor|by|lifetime>, no_own_measurement,
#          record_unreadable, schema_mismatch, stall.
# Also written, for readers this phase may not change: the .session-loop
# marker (`context-budget.sh supervised` and the launcher's bootstrap exemption
# read it) — see plans/phase-5.md decision 1.
set -u
main() {

# Workspace identity = repository identity, not checkout path: a supervisor
# started from a worktree still drives the main checkout's record. Same
# resolver as launch-next-session.sh.
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
# shellcheck source=lib/session-lib.sh
. "$ROOT/scripts/lib/session-lib.sh"
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
command -v jq >/dev/null 2>&1 || { echo "session-loop: refused reason=jq_missing — jq is required" >&2; exit 4; }

S="$ROOT/work/$PROJECT"
[ -d "$S" ] || { echo "error: no such work directory: work/$PROJECT" >&2; exit 3; }
[ -f "$S/context-budget.env" ] && . "$S/context-budget.env"
[ -n "$MAX_SESSIONS" ] || MAX_SESSIONS="${SESSION_LOOP_MAX_SESSIONS:-10}"
[ -n "$MIN_LIFETIME" ] || MIN_LIFETIME="${SESSION_LOOP_MIN_LIFETIME:-60}"
[ -n "$STALL_LIMIT" ] || STALL_LIMIT="${SESSION_LOOP_STALL_LIMIT:-3}"
# The watchdog knobs: no CLI flag, committed next to the chain. A non-numeric
# value is refused rather than read as "off".
ALARM="${SESSION_LOOP_ALARM:-0}"; ALARM_MAX="${SESSION_LOOP_ALARM_MAX:-3600}"; KILL_AFTER="${SESSION_LOOP_KILL_AFTER:-0}"
for _k in ALARM ALARM_MAX KILL_AFTER; do
  eval "_v=\$$_k"
  case "$_v" in ''|*[!0-9]*) echo "error: SESSION_LOOP_$_k must be a whole number of seconds, got '$_v'" >&2; exit 3 ;; esac
done
[ "$ALARM_MAX" -ge "$ALARM" ] || ALARM_MAX="$ALARM"

REC="$S/session-state.json"; LOOPF="$S/.session-loop"; NEXTF="$S/.next-command"; LOGF="$S/.session-loop.log"
SUP_PID=$$
SUP_START="$(ps -o lstart= -p "$SUP_PID" 2>/dev/null | sed 's/^ *//;s/ *$//')"

say()    { printf 'session-loop: %s\n' "$*" >&2; printf '%s %s\n' "$(date -u +%FT%TZ)" "$*" >> "$LOGF"; }
# Unattended, a stopped chain is silent: every ending and every page also goes
# through the notify hook a human can find later.
notify() {
  say "$*"; printf '\a' >&2
  [ -n "${SESSION_LOOP_NOTIFY:-}" ] && "$SESSION_LOOP_NOTIFY" "session-loop $PROJECT: $*" >/dev/null 2>&1
  return 0
}
refuse()  { say "refused reason=$1${2:+ $2}"; exit 4; }
broken()  { notify "broken reason=$1${2:+ $2}"; exit 1; }
verdict() { say "verdict=$1${2:+ $2}"; }

# ---- the record --------------------------------------------------------------
REC_JSON=""; REC_STATE=""   # ok | absent | record_unreadable | schema_mismatch
rec_load() {
  REC_JSON='{"schema":1}'; REC_STATE=ok
  [ -e "$REC" ] || { REC_STATE=absent; return 0; }
  REC_JSON=$(cat "$REC" 2>/dev/null) && printf '%s' "$REC_JSON" | jq -e 'type=="object"' >/dev/null 2>&1 \
    || { REC_STATE=record_unreadable; return 0; }
  printf '%s' "$REC_JSON" | jq -e '.schema == 1' >/dev/null 2>&1 || REC_STATE=schema_mismatch
  return 0
}
rq() { printf '%s' "$REC_JSON" | jq -r "$@" 2>/dev/null; }
rec_write() { session_record_update "$REC" "$@"; }
supervisor_live() {   # the recorded supervisor: pid running and started when the record says
  local pid ps
  pid="$(rq '.chain.supervisor.pid // empty')"; ps="$(rq '.chain.supervisor.pid_start // empty')"
  [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null \
    && [ "$(ps -o lstart= -p "$pid" 2>/dev/null | sed 's/^ *//;s/ *$//')" = "$ps" ]
}
cap_stop() {   # $1 = used; the cap is the same verdict at start and at the end of the loop
  notify "verdict=cap seq=$(rq '.seq // "?"') used=$1 cap=$MAX_SESSIONS — chain cap reached; open a new budget with: scripts/session-loop.sh $PROJECT --reset-cap"
  exit 0
}

# ---- start gates, in order; a refused start leaves the record untouched --------
rec_load
case "$REC_STATE" in
  record_unreadable) refuse record_unreadable "record=$REC — not a JSON object; repair it or move it aside" ;;
  schema_mismatch)   refuse schema_mismatch "record=$REC schema=$(rq '.schema // "none"') want=1" ;;
esac
# Opening a new budget is the human checkpoint the cap is for: an explicit
# operator action, refused under a live supervisor (it persists `used` before
# every child and would overwrite the reset).
if [ "$RESET_CAP" -eq 1 ]; then
  supervisor_live && refuse supervisor_live "pid=$(rq '.chain.supervisor.pid') — stop it before opening a new budget"
  rec_write true '.chain = ((.chain // {}) + {used: 0, cap: $cap})' --argjson cap "$MAX_SESSIONS" || exit 4
  say "chain budget reset ($(rq '.chain.used // 0') of $(rq '.chain.cap // "?"') had been used) — the next start opens a fresh budget of $MAX_SESSIONS"
  exit 0
fi
# The item's committed ROLLOVER_RELAUNCH=off means "do not run me unattended".
if [ "${ROLLOVER_RELAUNCH:-}" = "off" ] && [ "$RELAUNCH_OVERRIDE" -eq 0 ]; then
  refuse relaunch_off "project=$PROJECT — work/$PROJECT/context-budget.env commits ROLLOVER_RELAUNCH=off; to run a supervised chain against it anyway: scripts/session-loop.sh $PROJECT --relaunch-override"
fi
[ "${ROLLOVER_RELAUNCH:-}" = "off" ] && say "starting despite ROLLOVER_RELAUNCH=off — --relaunch-override was passed"
# A chain that was deliberately ended stays ended; reopening is an explicit act.
if [ "$(rq '.chain.closed // null')" != null ]; then
  if [ "$REOPEN" -eq 1 ]; then
    rec_write '.chain.closed != null' '.chain.closed = null' || exit 4
    say "reopening work/$PROJECT — session #$(rq '.chain.closed.by_seq // "?"') had ended this chain at $(rq '.chain.closed.at // "?"') reason=$(rq '.chain.closed.reason // "?"')"
    rec_load
  else
    refuse chain_closed "seq=$(rq '.chain.closed.by_seq // "?"') at=$(rq '.chain.closed.at // "?"') reason=$(rq '.chain.closed.reason // "?"') — the chain for work/$PROJECT was deliberately ended; reopen it explicitly: scripts/session-loop.sh $PROJECT --reopen"
  fi
fi
# One supervisor per work item.
supervisor_live && refuse supervisor_live "pid=$(rq '.chain.supervisor.pid') project=$PROJECT — a supervisor is already running for this work item"
USED="$(rq '.chain.used // 0')"
[ "$USED" -lt "$MAX_SESSIONS" ] || cap_stop "$USED"
[ "$USED" -gt 0 ] && say "resuming the chain budget at $USED of $MAX_SESSIONS used"
git -C "$ROOT" rev-parse --git-dir >/dev/null 2>&1 || { echo "error: $ROOT is not a git repository" >&2; exit 3; }

cd "$ROOT" || exit 3
export TF_SESSION_LOOP=1
export TF_SESSION_LOOP_PROJECT="$PROJECT"   # the turn-end hooks locate the work item through it
rec_write true \
  '.chain = {supervisor: {pid: $pid, pid_start: $ps, started_at: $at},
             used: ((.chain // {}).used // 0), cap: $cap, closed: ((.chain // {}).closed // null)}' \
  --argjson pid "$SUP_PID" --arg ps "$SUP_START" --arg at "$(date -u +%FT%TZ)" --argjson cap "$MAX_SESSIONS" || exit 4
jq -n --argjson pid "$SUP_PID" --arg project "$PROJECT" --arg started_at "$(date -u +%FT%TZ)" \
  '{pid:$pid, project:$project, started_at:$started_at}' > "$LOOPF"

# ---- the watchdog ------------------------------------------------------------
# A background subshell per child: the child is foreground and tty-inheriting,
# so the alarm never touches it except for the one kill-on-silence case. It
# identifies the child from the record (session.pid a child of this
# supervisor) and reads liveness from its transcript's mtime. Pages carry a
# `page=` token: unidentified, silent, blocked (past STOP with nothing staged),
# staged_alive (staged, still running two ticks later).
ALARM_STOPF="$(mktemp "${TMPDIR:-/tmp}/session-loop.XXXXXX")"; rm -f "$ALARM_STOPF"
mtime_of() { stat -f %m "$1" 2>/dev/null || stat -c %Y "$1" 2>/dev/null; }
child_probe() {   # echoes "<pid> <transcript-age-seconds>"; rc 1 when the child cannot be identified
  local pid art m
  rec_load; [ "$REC_STATE" = ok ] || return 1
  pid="$(rq '.session.pid // empty')"; art="$(rq '.session.artifact // empty')"
  [ -n "$pid" ] && [ "$(ps -o ppid= -p "$pid" 2>/dev/null | tr -d ' ')" = "$SUP_PID" ] || return 1
  [ -n "$art" ] && [ -f "$art" ] || return 1
  m="$(mtime_of "$art")"; [ -n "$m" ] || return 1
  printf '%s %s\n' "$pid" "$(( $(date +%s) - m ))"
}
child_past_stop() {   # asked about the child's own transcript, never this process's
  local rc=0
  "$ROOT/scripts/context-budget.sh" check --runtime "$(rq '.session.runtime // "claude"')" \
    --transcript "$(rq '.session.artifact')" --quiet >/dev/null 2>&1 || rc=$?
  [ "$rc" -eq 2 ]
}
alarm=""
alarm_start() {   # $1 = session number
  rm -f "$ALARM_STOPF"
  ( _int="$ALARM"; _staged_ticks=0
    while :; do
      [ -e "$ALARM_STOPF" ] && exit 0
      sleep "$_int" || exit 0
      [ -e "$ALARM_STOPF" ] && exit 0
      _probe="$(child_probe || true)"
      _staged=""; [ "$REC_STATE" = ok ] && [ "$(rq '.staged // null')" != null ] && _staged=1
      if [ -n "$_probe" ] && [ -n "$_staged" ]; then _staged_ticks=$((_staged_ticks + 1)); else _staged_ticks=0; fi
      if [ -z "$_probe" ]; then
        notify "page=unidentified seq=$1 — session #$1 has been running with no exit and cannot be identified from the record"
      elif [ "$_staged_ticks" -ge 2 ]; then
        notify "page=staged_alive seq=$1 — session #$1 staged a successor and is still running; the turn-end self-kill did not fire"
      elif [ -z "$_staged" ] && child_past_stop; then
        notify "page=blocked seq=$1 — session #$1 is past its context budget with no successor staged"
      elif [ "${_probe#* }" -lt "$ALARM" ]; then
        _int="$ALARM"; say "session #$1 is still running (transcript written ${_probe#* }s ago)"
      elif [ "$KILL_AFTER" -gt 0 ] && [ "${_probe#* }" -ge "$KILL_AFTER" ]; then
        notify "page=silent seq=$1 — session #$1 has written nothing for ${_probe#* }s (limit ${KILL_AFTER}s); ending it"
        kill "${_probe% *}" 2>/dev/null; exit 0
      else
        notify "page=silent seq=$1 — session #$1 has written nothing for ${_probe#* }s"
        [ "$_int" -lt "$ALARM_MAX" ] && _int=$((_int * 2)); [ "$_int" -gt "$ALARM_MAX" ] && _int="$ALARM_MAX"
      fi
    done ) &
  alarm=$!
}
# Stop flag first (so the loop cannot fork a fresh sleep mid-reap), then the
# in-flight sleep (an orphan holds the caller's stdout), then the subshell.
reap_alarm() {
  [ -n "$alarm" ] || return 0
  : > "$ALARM_STOPF"
  pkill -P "$alarm" 2>/dev/null; kill "$alarm" 2>/dev/null; wait "$alarm" 2>/dev/null
  alarm=""; rm -f "$ALARM_STOPF"
}
cleanup() {
  reap_alarm
  rec_write '.chain.supervisor.pid == $pid' '.chain.supervisor = null' --argjson pid "$SUP_PID" >/dev/null 2>&1
  rm -f "$LOOPF"
}
trap cleanup EXIT
# TERM/HUP: clean up, then die BY the signal — a killed chain is never a verdict.
# INT is untrapped: Ctrl-C reaches the child and the alarm directly, and bash's
# cooperative exit does the right thing in both directions.
on_signal() { cleanup; trap - "$1"; kill -s "$1" $$; }
trap 'on_signal TERM' TERM
trap 'on_signal HUP'  HUP

# A vendor logout exits 0 with nothing staged and the number unmoved — the quit
# shape. Only a transcript that ENDS on a terminal authentication_failed (the
# JSON shape, never the text alone) overrides.
child_logged_out() {   # $1 = transcript
  tail -n 200 "$1" 2>/dev/null \
    | jq -R -c 'fromjson? | select(.type == "assistant")' 2>/dev/null | tail -1 \
    | jq -e '.isApiErrorMessage == true and .error == "authentication_failed"
             and ([.message.content[]?.text // ""] | any(startswith("Not logged in")))' >/dev/null 2>&1
}
# Progress = a commit touching something outside the three markdown files a
# rollover always rewrites (README, launcher, ledger and its archive).
session_made_progress() {  # $1 = HEAD before the session
  local after f
  after="$(git -C "$ROOT" rev-parse HEAD 2>/dev/null)" || return 0
  [ "$1" = "$after" ] && return 1
  while IFS= read -r f; do
    case "$f" in
      ""|"work/$PROJECT/README.md"|"work/$PROJECT/next-session.md"|"work/$PROJECT/handoff.md"|"work/$PROJECT/handoff-archive.md") continue ;;
    esac
    return 0
  done < <(git -C "$ROOT" log --format= --name-only "$1..$after" 2>/dev/null | sort -u)
  return 1
}

# ---- the loop ----------------------------------------------------------------
stalled=0
while :; do
  rec_load
  case "$REC_STATE" in record_unreadable|schema_mismatch) broken "$REC_STATE" "record=$REC" ;; esac
  if [ "$(rq '.staged // null')" = null ]; then
    # The bootstrap: iteration 1 has no dying session to stage its command. A
    # DIRECT call — the launcher's exemption for this caller tests its strict
    # parent pid (test-session-loop.sh F1 is the tripwire).
    say "staging the first session"
    lrc=0; lerr="$(mktemp "${TMPDIR:-/tmp}/session-loop.XXXXXX")"
    "$ROOT/scripts/launch-next-session.sh" "$PROJECT" ${RUNTIME:+--runtime "$RUNTIME"} --emit 2>"$lerr" || lrc=$?
    cat "$lerr" >&2
    lcode="$(grep -o 'refused reason=[a-z_]*' "$lerr" | head -1 | sed 's/.*=//')"; rm -f "$lerr"
    [ "$lrc" -eq 0 ] || refuse "${lcode:-stage_failed}" "rc=$lrc project=$PROJECT — the launcher refused to stage the first session (its line is above)"
    rec_load
    case "$REC_STATE" in ok) ;; *) refuse "${REC_STATE/absent/record_unreadable}" "record=$REC — after the bootstrap stage" ;; esac
  fi
  seq="$(rq '.seq // empty')"; succ="$(rq '.staged.successor // empty')"; CMD="$(rq '.staged.command // empty')"
  [ -n "$seq" ] && [ "$succ" = "$seq" ] && [ -n "$CMD" ] \
    || broken staged_invalid "leg=staged seq=${seq:-none} successor=${succ:-none} — the staged block does not name the record's number"
  # A successor number that already has a registered owner means the staged
  # command has been run (by hand, or by another chain); running it again is
  # the duplicate-session defect.
  [ "$(rq '.session // null')" = null ] \
    || refuse staged_invalid "leg=spent seq=$seq owner=$(rq '"\(.session.runtime)-\(.session.session_id)"') — session #$seq already has a registered owner, so the staged command was already run; roll over from that session, or null the record's staged block by hand"
  USED="$(rq '.chain.used // 0')"
  [ "$USED" -lt "$MAX_SESSIONS" ] || cap_stop "$USED"
  mode="$(rq '.launch.mode // "handsoff"')"
  # Consume BEFORE the run, and charge the budget before the run: a supervisor
  # killed mid-session must not hand that session back for free.
  rec_write '.staged.successor == $seq' '.staged = null | .chain.used = ((.chain.used // 0) + 1)' --argjson seq "$seq" \
    || broken staged_invalid "leg=staged seq=$seq — the staged block changed underneath the consume"
  rm -f "$NEXTF"
  USED=$((USED + 1))
  export TF_SESSION_PROJECT="$PROJECT" TF_SESSION_SEQ="$seq"
  say "starting session #$seq ($USED of $MAX_SESSIONS)"
  started_at="$(date +%s)"; started_iso="$(date -u +%FT%TZ)"
  head_before="$(git -C "$ROOT" rev-parse HEAD 2>/dev/null || echo none)"
  [ "$ALARM" -gt 0 ] && alarm_start "$seq"

  eval "$CMD"
  rc=$?
  reap_alarm
  say "session #$seq ended rc=$rc"

  rec_load
  case "$REC_STATE" in ok) ;; *) broken "${REC_STATE/absent/record_unreadable}" "seq=$seq record=$REC — the record is unreadable after session #$seq" ;; esac
  seq_after="$(rq '.seq // 0')"
  if [ "$seq_after" = "$seq" ] && [ "$(rq '.staged // null')" = null ]; then
    # Nothing staged, number unchanged: a quit, if the child registered and
    # exited 0 and its transcript does not end in a logout.
    [ "$rc" -eq 0 ] \
      || broken rc_nonzero "seq=$seq rc=$rc — the command failed to run or session #$seq died; nothing was staged and the number did not move"
    reg_at="$(rq '.session.registered_at // empty')"
    [ "$(rq '.session.seq // empty')" = "$seq" ] && [ -n "$reg_at" ] && [ ! "$reg_at" \< "$started_iso" ] \
      || broken no_own_measurement "seq=$seq registered_at=${reg_at:-none} started=$started_iso — session #$seq never registered against work/$PROJECT after it started"
    art="$(rq '.session.artifact // empty')"
    if [ -n "$art" ] && child_logged_out "$art"; then
      rec_write '.chain.used > 0' '.chain.used -= 1' >/dev/null   # a logout did no work: refund the slot
      broken logout "seq=$seq — session #$seq ended in a vendor logout (its transcript ends in a terminal authentication_failed); log in, then resume: scripts/session-loop.sh $PROJECT"
    fi
    v=quit_plain; [ "$(rq '.session.ended.door // empty')" = stop ] && v=quit_stop
    rec_write '.chain.closed == null' '.chain.closed = {at: $at, by_seq: $seq, reason: $v}' \
      --arg at "$(date -u +%FT%TZ)" --argjson seq "$seq" --arg v "$v" >/dev/null \
      || say "warning: could not record the chain close"
    notify "verdict=$v seq=$seq — session #$seq quit; the chain is closed (reopen: scripts/session-loop.sh $PROJECT --reopen)"
    exit 0
  fi
  # The number moved or something is staged: only a staging the launcher wrote
  # for THIS child, at its own bump, is a rollover. The child's exit status is
  # not consulted — the turn-end hook ends a session that staged with TERM.
  [ "$seq_after" = "$((seq + 1))" ] \
    || broken staged_invalid "leg=seq seq=$seq seq_after=$seq_after — the number moved by $((seq_after - seq)), not 1"
  [ "$(rq '.staged // null')" != null ] \
    || broken staged_invalid "leg=staged seq=$seq seq_after=$seq_after — the number advanced but nothing is staged"
  pred_sid="$(rq '.launch.predecessor.session_id // empty')"
  [ "$(rq '.launch.predecessor.seq // empty')" = "$seq" ] && [ "$(rq '.launch.predecessor.disposition // empty')" = rolled_over ] \
    || broken staged_invalid "leg=predecessor seq=$seq predecessor=$(rq '.launch.predecessor.seq // "none"') disposition=$(rq '.launch.predecessor.disposition // "none"') — the launcher did not record session #$seq as rolled over"
  [ -n "$pred_sid" ] && [ "$(rq '.staged.by // empty')" = "$pred_sid" ] \
    || broken staged_invalid "leg=by seq=$seq by=$(rq '.staged.by // "none"') session=${pred_sid:-none} — the staged command was not written by session #$seq"
  reg_at="$(rq '.launch.predecessor.registered_at // empty')"
  [ -n "$reg_at" ] && [ ! "$reg_at" \< "$started_iso" ] \
    || broken no_own_measurement "seq=$seq registered_at=${reg_at:-none} started=$started_iso — session #$seq's registration predates its start"
  elapsed=$(( $(date +%s) - started_at ))
  [ "$MIN_LIFETIME" -le 0 ] || [ "$elapsed" -ge "$MIN_LIFETIME" ] \
    || broken staged_invalid "leg=lifetime seq=$seq elapsed=${elapsed}s min=${MIN_LIFETIME}s — a rollover this fast is not work"
  mode="$(rq '.launch.mode // "handsoff"')"
  verdict staged "seq=$seq successor=$seq_after mode=$mode"

  # Hands-off only: in interactive mode the human at the keyboard is the stall detector.
  if [ "$STALL_LIMIT" -gt 0 ] && [ "$mode" = "handsoff" ] && [ "$head_before" != "none" ]; then
    if session_made_progress "$head_before"; then stalled=0
    else
      stalled=$((stalled + 1))
      say "session #$seq committed nothing outside README, the launcher and the ledger ($stalled of $STALL_LIMIT)"
      [ "$stalled" -lt "$STALL_LIMIT" ] \
        || broken stall "seq=$seq limit=$STALL_LIMIT — $STALL_LIMIT consecutive sessions made no progress; the chain is running its own bookkeeping, not the work"
    fi
  fi
  if [ "$mode" = "interactive" ]; then
    # A keypress, not a countdown; Ctrl-C here ends the chain.
    trap 'say "interrupted at the pause — ending the chain"; exit 0' INT
    printf 'session-loop: session #%s ended. Press Enter to start #%s (Ctrl-C to stop). ' "$seq" "$seq_after" >&2
    read -r _ </dev/tty || { say "no tty for the interactive pause — ending the chain"; exit 0; }
    trap - INT
  fi
done
}
main "$@"
