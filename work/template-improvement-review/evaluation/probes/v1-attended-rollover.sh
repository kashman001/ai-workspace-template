#!/usr/bin/env bash
# File: work/template-improvement-review/evaluation/probes/v1-attended-rollover.sh
# Purpose: Probe V1 — an attended rollover (scenarios S1, E9, I3, I4, I8;
#          stage2-design-part2.md probe table), self-checking and unattended.
#          Session #1 binds the item, writes its ledger block and the
#          successor's launcher, and runs the launcher attached from its tool
#          shell (which prints the `run:` line); the probe runs that line as
#          session #2, which registers by the env pair and stops.
#          Criteria: launch.predecessor.disposition = rolled_over, seq advanced
#          by 1, successor session.seq == seq, ledger 2 blocks, check-ledger.py
#          rc 0, no retired file under work/<p>/.
# Usage:   v1-attended-rollover.sh --root <workspace> --project <item> [--runtime claude]
#          Needs a logged-in `claude` on PATH (or the stub twin's shim).
set -u
PROBE_NAME="v1-attended-rollover"
. "$(cd "$(dirname "$0")" && pwd -P)/lib.sh"
probe_parse "$@"
STOP_AT="${STOP_AT:-2}"          # the successor arrives, writes its block, stops
probe_seed_item

echo "V1: session #1 (attended) rolls over; session #2 arrives by the run: line"
probe_session 1 "$(probe_prompt 1)"
probe_assert_eq "V1a: session #1 exited 0"                      "$?" "0"
probe_assert_eq "V1b: it bound the item as #1 (ledger block 1)" "$(ledger_blocks)" "1"
run_line="$(probe_run_line 1)"
probe_assert_ne "V1c: the launcher printed the run: line"       "$run_line" ""
probe_assert_eq "V1d: seq advanced 1 -> 2"                      "$(rec .seq)" "2"
probe_assert_eq "V1e: launch.predecessor.seq"                   "$(rec '.launch.predecessor.seq')" "1"
probe_assert_eq "V1f: launch.predecessor.disposition"           "$(rec '.launch.predecessor.disposition')" "rolled_over"
pred_sid="$(rec '.launch.predecessor.session_id')"
probe_assert_ne "V1g: the predecessor is a real session id"     "$pred_sid" "null"
probe_assert_eq "V1h: launch.by = session (not a supervisor)"   "$(rec '.launch.by')" "session"
probe_assert_eq "V1i: nothing staged on the attached path"      "$(rec '.staged')" "null"
probe_assert_eq "V1j: the record awaits the successor"          "$(rec '.session')" "null"

[ -n "$run_line" ] && probe_session 2 "" "$run_line"
probe_assert_eq "V1k: session #2 exited 0"                      "$?" "0"
probe_assert_eq "V1l: successor session.seq == seq"             "$(rec '.session.seq')" "$(rec .seq)"
probe_assert_eq "V1m: seq still 2 (the successor staged nothing)" "$(rec .seq)" "2"
probe_assert_ne "V1n: the successor is another session"         "$(rec '.session.session_id')" "$pred_sid"
probe_assert_ne "V1o: SessionEnd released it (ended.at)"        "$(rec '.session.ended.at')" "null"
probe_assert_eq "V1p: ledger has 2 blocks"                      "$(ledger_blocks)" "2"
probe_assert_eq "V1q: check-ledger.py rc 0"                     "$(check_ledger_rc)" "0"
probe_assert_eq "V1r: no retired file under work/$PROJECT/"     "$(retired_present)" ""
probe_finish
