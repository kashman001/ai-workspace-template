#!/usr/bin/env bash
# File: work/template-improvement-review/evaluation/probes/v3-chain.sh
# Purpose: Probe V3 — a supervised chain (scenarios S3, I2), self-checking and
#          unattended. The supervisor bootstraps session #1 through the
#          launcher; each child binds by the env pair, writes its block and the
#          next launcher, stages its successor with `--emit`, and is ended by
#          the turn-end hook; the chain runs to its cap, or, with --stop-at N,
#          session N quits and the chain closes.
#          Criteria are three script facts and nothing else (the prose
#          `successor: NOT STAGED` advisory is not read): the verdict codes in
#          the supervisor's log (`staged` per rolled-over session, then `cap`
#          or `quit_plain`), the record (`chain.used`, `staged`/`chain.closed`,
#          `launch.predecessor`, `staged.by`), and the supervisor's exit code.
# Usage:   v3-chain.sh --root <workspace> --project <item> [--max-sessions N]
#            [--stop-at N] [--driver direct|expect]
#          --driver expect for a real TUI child (needs a pty); the twin runs direct.
set -u
PROBE_NAME="v3-chain"
. "$(cd "$(dirname "$0")" && pwd -P)/lib.sh"
probe_parse "$@"
probe_seed_item

if [ -n "$STOP_AT" ] && [ "$STOP_AT" -le "$MAX_SESSIONS" ]; then
  flavour=quit; last="$STOP_AT"
else
  flavour=cap; last="$MAX_SESSIONS"
fi
want=""; n=1
while [ "$n" -lt "$last" ]; do want="$want staged seq=$n"; n=$((n+1)); done
if [ "$flavour" = cap ]; then want="$want staged seq=$last cap seq=$((last + 1))"
else want="$want quit_plain seq=$last"; fi
want="${want# }"
pred_want="$last"; [ "$flavour" = quit ] && pred_want=$((last - 1))

echo "V3: supervised chain, --max-sessions $MAX_SESSIONS${STOP_AT:+ --stop-at $STOP_AT} ($flavour)"
probe_supervise --max-sessions "$MAX_SESSIONS" --min-lifetime 0 --stall-limit 0; rc=$?
probe_assert_eq "V3a: supervisor exit 0 (a verdict ended the chain)" "$rc" "0"
probe_assert_eq "V3b: verdicts in order"                           "$(log_verdicts)" "$want"
probe_assert_eq "V3c: no broken line"                              "$(log_broken)" ""
probe_assert_eq "V3d: no refusal"                                  "$(log_refused)" ""
probe_assert_eq "V3e: chain.used counts every session"             "$(rec '.chain.used')" "$last"
probe_assert_eq "V3f: chain.supervisor cleared at exit"            "$(rec '.chain.supervisor')" "null"
probe_assert_eq "V3g: the last rollover's predecessor"             "$(rec '.launch.predecessor.seq')" "$pred_want"
probe_assert_eq "V3h: launch.predecessor.disposition"              "$(rec '.launch.predecessor.disposition')" "rolled_over"
if [ "$flavour" = cap ]; then
  probe_assert_eq "V3i: seq advanced past the cap"                 "$(rec .seq)" "$((last + 1))"
  probe_assert_eq "V3j: the successor stays staged for a restart"  "$(rec '.staged.successor')" "$((last + 1))"
  probe_assert_eq "V3k: staged.by is the session that rolled over" "$(rec '.staged.by')" "$(rec '.launch.predecessor.session_id')"
  probe_assert_eq "V3l: no close on a cap"                         "$(rec '.chain.closed')" "null"
else
  probe_assert_eq "V3i: seq is the quitting session's"             "$(rec .seq)" "$last"
  probe_assert_eq "V3j: nothing staged"                            "$(rec '.staged')" "null"
  probe_assert_eq "V3k: the quitting session registered its number" "$(rec '.session.seq')" "$last"
  probe_assert_eq "V3l: chain.closed.reason"                       "$(rec '.chain.closed.reason')" "quit_plain"
fi
probe_assert_eq "V3m: every session wrote its ledger block"        "$(ledger_blocks)" "$last"
probe_assert_eq "V3n: check-ledger.py rc 0"                        "$(check_ledger_rc)" "0"
probe_assert_eq "V3o: no retired file under work/$PROJECT/"        "$(retired_present)" ""
probe_finish
