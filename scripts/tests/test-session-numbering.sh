#!/usr/bin/env bash
# File: scripts/tests/test-session-numbering.sh
# Purpose: Session-number progression on the per-item record (Stage 4 phase 3):
#          register opens `seq` exactly once, never regresses it, and a session
#          only ever carries the record's number. The launcher advances `seq`
#          (phase 4); registration never does.
set -u
SRC_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TMP="$(mktemp -d)"; TMP="$(cd "$TMP" && pwd -P)"; trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/scripts/lib" "$TMP/work/testproj" "$TMP/home"
cp "$SRC_ROOT/scripts/context-budget.sh" "$SRC_ROOT/scripts/import-session-seq.sh" "$TMP/scripts/"
cp "$SRC_ROOT/scripts/lib/session-lib.sh" "$TMP/scripts/lib/"
printf 'CONTEXT_DUMB_ZONE_TOKENS=150000\n' > "$TMP/context-budget.env"
printf '# launcher\n' > "$TMP/work/testproj/next-session.md"
export HOME="$TMP/home"
cd "$TMP"
CB="$TMP/scripts/context-budget.sh"
REC="$TMP/work/testproj/session-state.json"
HF="$TMP/work/testproj/handoff.md"
PROJ_DIR="$HOME/.claude/projects/$(pwd | tr '/.' '--')"; mkdir -p "$PROJ_DIR"
unset TF_SESSION_PROJECT TF_SESSION_SEQ TF_SESSION_LOOP_PROJECT

PASS=0; FAIL=0
ok()  { PASS=$((PASS+1)); echo "  ok: $1"; }
bad() { FAIL=$((FAIL+1)); echo "  FAIL: $1" >&2; }
assert_eq() { [ "$2" = "$3" ] && ok "$1" || bad "$1 (want [$3] got [$2])"; }
assert_contains() { case "$2" in *"$3"*) ok "$1" ;; *) bad "$1 (no [$3] in [$2])" ;; esac; }
mk_transcript() {
  jq -cn '{message:{usage:{input_tokens:1000,cache_read_input_tokens:0,cache_creation_input_tokens:0}},isSidechain:false}' \
    > "$PROJ_DIR/$1.jsonl"
}
run_as() { local sid="$1"; shift; CLAUDE_CODE_SESSION_ID="$sid" "$CB" "$@" --runtime claude; }
rec() { jq -r "$1" "$REC" 2>/dev/null; }

echo "N1: a record-less item with no ledger opens at 1"
rm -f "$REC" "$HF"; mk_transcript s1
run_as s1 register --project testproj --quiet >/dev/null
assert_eq "N1a: seq 1"          "$(rec .seq)" "1"
assert_eq "N1b: session.seq 1"  "$(rec .session.seq)" "1"

echo "N2: a record-less item opens at ledger top + 1 (the ad-hoc self-heal)"
rm -f "$REC"
printf '# Session Handoff — 3 (2026-09-01): three\n\n# Session Handoff — 2 (2026-08-30): two\n' > "$HF"
run_as s1 register --project testproj --quiet >/dev/null
assert_eq "N2a: seq is 4"       "$(rec .seq)" "4"
assert_eq "N2b: session.seq 4"  "$(rec .session.seq)" "4"

echo "N3: registration never advances or lowers an existing seq"
jq '.seq = 9 | .session = null' "$REC" > "$REC.t" && mv "$REC.t" "$REC"   # record ahead of the ledger
run_as s1 register --project testproj --quiet >/dev/null
assert_eq "N3a: seq 9 kept though the ledger top is 3" "$(rec .seq)" "9"
assert_eq "N3b: the session carries 9"                 "$(rec .session.seq)" "9"
run_as s1 register --project testproj --quiet >/dev/null
assert_eq "N3c: a second registration of the same session does not advance" "$(rec .seq)" "9"
mk_transcript s2
jq '.seq = 2' "$REC" > "$REC.t" && mv "$REC.t" "$REC"                     # record behind the ledger
run_as s2 register --project testproj --takeover --quiet >/dev/null
assert_eq "N3d: a takeover keeps seq as it is (2), never re-derives it" "$(rec .seq)" "2"

echo "N4: the successor's number comes from the record, and must match its env"
jq -n '{schema:1, seq:5, launch:{pending:null}, session:null}' > "$REC"; mk_transcript s5
TF_SESSION_PROJECT=testproj TF_SESSION_SEQ=5 run_as s5 register --quiet >/dev/null
assert_eq "N4a: bound at 5"          "$(rec .session.seq)" "5"
assert_eq "N4b: seq still 5"         "$(rec .seq)" "5"
jq '.session = null' "$REC" > "$REC.t" && mv "$REC.t" "$REC"; mk_transcript s6
err=$(TF_SESSION_PROJECT=testproj TF_SESSION_SEQ=6 run_as s6 register 2>&1 >/dev/null)
assert_eq       "N4c: a number the record does not hold binds nothing" "$(rec .session)" "null"
assert_contains "N4d: says why" "$err" "not bound"
assert_eq       "N4e: seq untouched" "$(rec .seq)" "5"

echo "N5: the phase-0 import feeds the same number; registration keeps it"
rm -f "$REC"; printf '7\n' > "$TMP/work/testproj/.session-seq"
"$TMP/scripts/import-session-seq.sh" testproj >/dev/null 2>&1
run_as s1 register --project testproj --quiet >/dev/null
assert_eq "N5a: imported seq kept" "$(rec .seq)" "7"
assert_eq "N5b: session numbered 7" "$(rec .session.seq)" "7"

echo "N6: close accepts only the record's number in the ledger"
printf '# Session Handoff — 7 (2026-09-17): seven\n' > "$HF"
run_as s1 close --project testproj --check --quiet >/dev/null 2>&1; rc=$?
assert_eq "N6a: ledger 7 == seq 7 passes" "$rc" "0"
printf '# Session Handoff — 8 (2026-09-17): eight\n' > "$HF"
err=$(run_as s1 close --project testproj --check 2>&1 >/dev/null); rc=$?
assert_eq       "N6b: ledger 8 != seq 7 refused" "$rc" "4"
assert_contains "N6c: reason" "$err" "reason=ledger_seq_mismatch ledger=8 seq=7"

echo; echo "passed=$PASS failed=$FAIL"
[ "$FAIL" -eq 0 ]
