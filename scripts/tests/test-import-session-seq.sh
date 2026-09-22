#!/usr/bin/env bash
# File: scripts/tests/test-import-session-seq.sh
# Purpose: Contract of the one-time counter import (scripts/import-session-seq.sh):
#          record `seq` equals the old .session-seq value; a second run is a
#          no-op; a moved-on counter is re-imported; a record already ahead is
#          refused; every refusal names its reason; `--status` classifies an
#          item (fresh / old / imported / new / conflict) without writing.
#          Runs against a throwaway work item in a temp tree.
set -u
SRC_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/scripts" "$TMP/work/throwaway"
cp "$SRC_ROOT/scripts/import-session-seq.sh" "$TMP/scripts/"
chmod +x "$TMP/scripts/import-session-seq.sh"
IMP="$TMP/scripts/import-session-seq.sh"
CTR="$TMP/work/throwaway/.session-seq"
REC="$TMP/work/throwaway/session-state.json"

PASS=0; FAIL=0
ok()  { PASS=$((PASS+1)); echo "  ok: $1"; }
bad() { FAIL=$((FAIL+1)); echo "  FAIL: $1" >&2; }
assert_eq()       { [ "$2" = "$3" ] && ok "$1" || bad "$1 (want [$3] got [$2])"; }
assert_contains() { case "$2" in *"$3"*) ok "$1" ;; *) bad "$1 (no [$3] in [$2])" ;; esac; }
seq_of() { jq -r '.seq' "$REC" 2>/dev/null; }

echo "I1: usage — no project / unknown project exit 3"
"$IMP" >/dev/null 2>&1; assert_eq "I1a: no arg" "$?" "3"
"$IMP" nosuch >/dev/null 2>&1; assert_eq "I1b: unknown project" "$?" "3"

echo "I2: no old counter — refused, no record created"
out="$("$IMP" throwaway 2>&1)"; rc=$?
assert_eq       "I2a: exit 4"            "$rc" "4"
assert_contains "I2b: reason"            "$out" "reason=no_old_counter"
[ ! -e "$REC" ] && ok "I2c: no record written" || bad "I2c: record was created"

echo "I3: counter 10 — record seq equals the counter"
printf '10\n' > "$CTR"
out="$("$IMP" throwaway 2>&1)"; rc=$?
assert_eq "I3a: exit 0"                  "$rc" "0"
assert_contains "I3b: says imported"     "$out" "imported seq=10"
assert_eq "I3c: record seq"              "$(seq_of)" "10"
assert_eq "I3d: record schema"           "$(jq -r '.schema' "$REC")" "1"
[ ! -e "$REC.tmp."* ] 2>/dev/null && ok "I3e: no temp file left" || bad "I3e: temp file left behind"

echo "I4: second run — no-op, record byte-identical"
before="$(cksum < "$REC")"
out="$("$IMP" throwaway 2>&1)"; rc=$?
assert_eq       "I4a: exit 0"            "$rc" "0"
assert_contains "I4b: says noop"         "$out" "noop seq=10"
assert_eq       "I4c: record unchanged"  "$(cksum < "$REC")" "$before"

echo "I5: counter moved on to 11 (old scripts still running) — re-imported forward"
printf '11\n' > "$CTR"
"$IMP" throwaway >/dev/null 2>&1; rc=$?
assert_eq "I5a: exit 0"                  "$rc" "0"
assert_eq "I5b: record seq"              "$(seq_of)" "11"

echo "I6: record already ahead of the counter — refused, record untouched"
printf '10\n' > "$CTR"
before="$(cksum < "$REC")"
out="$("$IMP" throwaway 2>&1)"; rc=$?
assert_eq       "I6a: exit 4"            "$rc" "4"
assert_contains "I6b: reason"            "$out" "reason=seq_conflict"
assert_eq       "I6c: record unchanged"  "$(cksum < "$REC")" "$before"

echo "I7: unreadable inputs name their reason"
printf 'ten\n' > "$CTR"
out="$("$IMP" throwaway 2>&1)"; assert_contains "I7a: bad counter" "$out" "reason=counter_unreadable"
printf '11\n' > "$CTR"; echo 'not json' > "$REC"
out="$("$IMP" throwaway 2>&1)"; rc=$?
assert_eq       "I7b: exit 4"            "$rc" "4"
assert_contains "I7c: bad record"        "$out" "reason=record_unreadable"

echo "I8: other blocks in an existing record survive the import"
printf '{"schema":1,"seq":5,"chain":{"used":2}}\n' > "$REC"; printf '12\n' > "$CTR"
"$IMP" throwaway >/dev/null 2>&1
assert_eq "I8a: seq updated"             "$(seq_of)" "12"
assert_eq "I8b: chain block kept"        "$(jq -r '.chain.used' "$REC")" "2"

echo "I9: jq missing — refused before anything is read or written"
mkdir -p "$TMP/bin"
for t in bash dirname tr mv; do p="$(command -v "$t")" && ln -s "$p" "$TMP/bin/$t"; done
rm -f "$REC"
out="$(PATH="$TMP/bin" "$IMP" throwaway 2>&1)"; rc=$?
assert_eq       "I9a: exit 4"            "$rc" "4"
assert_contains "I9b: reason"            "$out" "reason=jq_missing"
[ ! -e "$REC" ] && ok "I9c: no record written" || bad "I9c: record was created"

echo "I10: --status classifies the item without writing"
rm -f "$CTR" "$REC" "$TMP/work/throwaway/.session-seq.provenance.json"
out="$("$IMP" --status throwaway 2>&1)"; rc=$?
assert_eq       "I10a: fresh exit 0"        "$rc" "0"
assert_contains "I10b: fresh"               "$out" "throwaway state=fresh loop=no counter=- seq=- next=nothing leftovers=-"
printf '4\n' > "$CTR"
out="$("$IMP" --status throwaway 2>&1)"; rc=$?
assert_eq       "I10c: old exit 1"          "$rc" "1"
assert_contains "I10d: old attended"        "$out" "state=old loop=no counter=4 seq=- next=import leftovers=.session-seq"
touch "$TMP/work/throwaway/.session-seq.provenance.json"
out="$("$IMP" --status throwaway 2>&1)"
assert_contains "I10e: old loop"            "$out" "state=old loop=yes counter=4"
[ ! -e "$REC" ] && ok "I10f: status wrote no record" || bad "I10f: status wrote a record"
"$IMP" throwaway >/dev/null 2>&1
out="$("$IMP" --status throwaway 2>&1)"; rc=$?
assert_eq       "I10g: imported exit 0"     "$rc" "0"
assert_contains "I10h: imported"            "$out" "state=imported loop=yes counter=4 seq=4 next=delete-leftovers leftovers=.session-seq,.session-seq.provenance.json"
printf '9\n' > "$CTR"
out="$("$IMP" --status throwaway 2>&1)"; rc=$?
assert_eq       "I10i: moved-on exit 1"     "$rc" "1"
assert_contains "I10j: moved-on is old"     "$out" "state=old loop=yes counter=9 seq=4 next=import"
printf '2\n' > "$CTR"
out="$("$IMP" --status throwaway 2>&1)"; rc=$?
assert_eq       "I10k: conflict exit 1"     "$rc" "1"
assert_contains "I10l: conflict"            "$out" "state=conflict loop=yes counter=2 seq=4 next=check"
rm -f "$CTR" "$TMP/work/throwaway/.session-seq.provenance.json"
out="$("$IMP" --status throwaway 2>&1)"; rc=$?
assert_eq       "I10m: new exit 0"          "$rc" "0"
assert_contains "I10n: new attended"        "$out" "state=new loop=no counter=- seq=4 next=nothing leftovers=-"
jq '.chain = {used: 1, cap: 10}' "$REC" > "$REC.t" && mv "$REC.t" "$REC"
out="$("$IMP" --status throwaway 2>&1)"
assert_contains "I10o: new loop"            "$out" "state=new loop=yes"
out="$("$IMP" --status 2>&1)"; rc=$?
assert_eq       "I10p: all items exit 0"    "$rc" "0"
assert_contains "I10q: all items lists it"  "$out" "throwaway state=new"
"$IMP" --status a b >/dev/null 2>&1; assert_eq "I10r: too many args exit 3" "$?" "3"

echo
echo "test-import-session-seq: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
