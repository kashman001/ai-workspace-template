#!/usr/bin/env bash
# File: scripts/tests/test-session-lib.sh
# Purpose: Contract of the record helper (scripts/lib/session-lib.sh,
#          `session_record_update`): concurrent writers under the mkdir lock
#          leave exactly one valid record with the exact expected total; a lost
#          compare-and-set race is a silent no-op; a false precondition leaves
#          the record byte-identical; wrong schema / unreadable / empty or
#          invalid filter results are refused with their reason and the record
#          untouched; a stale lock is reclaimed. Runs against a temp directory.
set -u
SRC_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
LIB="$SRC_ROOT/scripts/lib/session-lib.sh"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
REC="$TMP/session-state.json"

PASS=0; FAIL=0
ok()  { PASS=$((PASS+1)); echo "  ok: $1"; }
bad() { FAIL=$((FAIL+1)); echo "  FAIL: $1" >&2; }
assert_eq()       { [ "$2" = "$3" ] && ok "$1" || bad "$1 (want [$3] got [$2])"; }
assert_contains() { case "$2" in *"$3"*) ok "$1" ;; *) bad "$1 (no [$3] in [$2])" ;; esac; }
no_leftovers() { # no temp file, no lock dir beside the record
  if ls "$REC".tmp.* >/dev/null 2>&1; then bad "$1: temp file left behind"
  elif [ -e "$REC.lock" ]; then bad "$1: lock left behind"
  else ok "$1: no temp file or lock left"; fi
}

[ -f "$LIB" ] || { echo "FAIL: $LIB does not exist" >&2; exit 1; }
. "$LIB"

echo "S1: usage — fewer than three arguments returns 3"
session_record_update "$REC" 'true' 2>/dev/null; assert_eq "S1a: two args" "$?" "3"

echo "S2: absent record — a write creates it as schema 1 with the block"
rm -f "$REC"
session_record_update "$REC" '.seq == null' '.seq = $n' --argjson n 7; rc=$?
assert_eq "S2a: return 0"          "$rc" "0"
assert_eq "S2b: schema"            "$(jq -r '.schema' "$REC")" "1"
assert_eq "S2c: seq"               "$(jq -r '.seq' "$REC")" "7"
no_leftovers "S2d"

echo "S3: precondition false — return 1, silent, record byte-identical"
cp "$REC" "$TMP/before"
out="$(session_record_update "$REC" '.seq == null' '.seq = 99' 2>&1)"; rc=$?
assert_eq "S3a: return 1"          "$rc" "1"
assert_eq "S3b: nothing printed"   "$out" ""
cmp -s "$REC" "$TMP/before" && ok "S3c: byte-identical" || bad "S3c: record changed"
no_leftovers "S3d"

echo "S4: a block writer — session block written, other blocks kept, values via --arg"
session_record_update "$REC" '.seq == 7' \
  '.session = {seq: .seq, runtime: $rt, session_id: $sid}' --arg rt claude --arg sid abc; rc=$?
assert_eq "S4a: return 0"          "$rc" "0"
assert_eq "S4b: session.runtime"   "$(jq -r '.session.runtime' "$REC")" "claude"
assert_eq "S4c: seq kept"          "$(jq -r '.seq' "$REC")" "7"

echo "S5: wrong schema — return 4, reason=schema_mismatch, record untouched"
printf '{"schema":2,"seq":7}\n' > "$REC"; cp "$REC" "$TMP/before"
out="$(session_record_update "$REC" 'true' '.seq += 1' 2>&1)"; rc=$?
assert_eq       "S5a: return 4"    "$rc" "4"
assert_contains "S5b: reason"      "$out" "reason=schema_mismatch"
cmp -s "$REC" "$TMP/before" && ok "S5c: byte-identical" || bad "S5c: record changed"
printf '{"seq":7}\n' > "$REC"
out="$(session_record_update "$REC" 'true' '.seq += 1' 2>&1)"; rc=$?
assert_eq       "S5d: no schema field is a mismatch" "$rc" "4"
assert_contains "S5e: reason"      "$out" "reason=schema_mismatch"

echo "S6: unreadable record — reason=record_unreadable, record untouched"
printf 'not json\n' > "$REC"; cp "$REC" "$TMP/before"
out="$(session_record_update "$REC" 'true' '.seq += 1' 2>&1)"; rc=$?
assert_eq       "S6a: return 4"    "$rc" "4"
assert_contains "S6b: reason"      "$out" "reason=record_unreadable"
cmp -s "$REC" "$TMP/before" && ok "S6c: byte-identical" || bad "S6c: record changed"
printf '[1,2]\n' > "$REC"
out="$(session_record_update "$REC" 'true' '.seq += 1' 2>&1)"
assert_contains "S6d: not an object" "$out" "reason=record_unreadable"
: > "$REC"
out="$(session_record_update "$REC" 'true' '.seq += 1' 2>&1)"
assert_contains "S6e: empty file"  "$out" "reason=record_unreadable"
printf '{"schema":1,"seq":7}\n' > "$REC"; chmod 000 "$REC"
out="$(session_record_update "$REC" 'true' '.seq += 1' 2>&1)"; rc=$?
chmod 644 "$REC"
if [ "$(id -u)" = "0" ]; then ok "S6f: skipped (root reads anything)"
else assert_contains "S6f: unreadable file" "$out" "reason=record_unreadable"; fi
no_leftovers "S6g"

echo "S7: empty or invalid filter result — refused, record untouched"
printf '{"schema":1,"seq":7}\n' > "$REC"; cp "$REC" "$TMP/before"
out="$(session_record_update "$REC" 'true' 'empty' 2>&1)"; rc=$?
assert_eq       "S7a: empty → 4"   "$rc" "4"
assert_contains "S7b: reason"      "$out" "reason=filter_empty"
out="$(session_record_update "$REC" 'true' '.seq' 2>&1)"; rc=$?
assert_eq       "S7c: scalar → 4"  "$rc" "4"
assert_contains "S7d: reason"      "$out" "reason=filter_invalid"
out="$(session_record_update "$REC" 'true' '.seq +' 2>&1)"; rc=$?
assert_eq       "S7e: jq error → 4" "$rc" "4"
assert_contains "S7f: reason"      "$out" "reason=filter_invalid"
out="$(session_record_update "$REC" 'true' '., .' 2>&1)"
assert_contains "S7g: two values"  "$out" "reason=filter_invalid"
out="$(session_record_update "$REC" 'true' '.schema = 2' 2>&1)"
assert_contains "S7h: schema changed" "$out" "reason=filter_invalid"
out="$(session_record_update "$REC" '.seq ==' '.seq += 1' 2>&1)"; rc=$?
assert_eq       "S7i: bad precondition → 4" "$rc" "4"
assert_contains "S7j: reason"      "$out" "reason=precondition_invalid"
cmp -s "$REC" "$TMP/before" && ok "S7k: byte-identical after all refusals" || bad "S7k: record changed"
no_leftovers "S7l"

echo "S8: race — 3 concurrent writers x 20 increments each, one valid record, exact total"
printf '{"schema":1,"seq":0,"chain":{"used":0}}\n' > "$REC"
for w in 1 2 3; do
  ( . "$LIB"; i=0; while [ $i -lt 20 ]; do
      session_record_update "$REC" 'true' '.seq += 1' || echo "writer $w: rc=$? at $i" >> "$TMP/race.err"
      i=$((i+1)); done ) &
done
wait
[ -e "$TMP/race.err" ] && bad "S8a: a writer failed: $(cat "$TMP/race.err")" || ok "S8a: every increment returned 0"
jq -e 'type=="object"' "$REC" >/dev/null 2>&1 && ok "S8b: one valid JSON record" || bad "S8b: record is not valid JSON"
assert_eq "S8c: seq == 60"         "$(jq -r '.seq' "$REC")" "60"
assert_eq "S8d: other block kept"  "$(jq -r '.chain.used' "$REC")" "0"
no_leftovers "S8e"

echo "S9: compare-and-set race — two writers on the same precondition, exactly one wins"
printf '{"schema":1,"seq":0}\n' > "$REC"
for w in a b; do
  ( . "$LIB"; session_record_update "$REC" '.seq == 0' '.seq = 1 | .launch = {by: $w}' --arg w "$w"
    echo "$?" > "$TMP/cas.$w" ) &
done
wait
codes="$(cat "$TMP/cas.a" "$TMP/cas.b" | sort | tr '\n' ' ')"
assert_eq "S9a: one 0 and one 1"   "$codes" "0 1 "
assert_eq "S9b: seq == 1"          "$(jq -r '.seq' "$REC")" "1"
winner="$(jq -r '.launch.by' "$REC")"
assert_eq "S9c: winner is the one that returned 0" "$(cat "$TMP/cas.$winner")" "0"

echo "S10: lock — a held lock is waited for; a stale lock is reclaimed; timeout is refused"
printf '{"schema":1,"seq":1}\n' > "$REC"
mkdir "$REC.lock"
( sleep 0.5; rmdir "$REC.lock" ) &
session_record_update "$REC" 'true' '.seq += 1'; rc=$?
wait
assert_eq "S10a: waited for release, return 0" "$rc" "0"
assert_eq "S10b: seq == 2"         "$(jq -r '.seq' "$REC")" "2"
mkdir "$REC.lock"; touch -t 202001010000 "$REC.lock"
session_record_update "$REC" 'true' '.seq += 1'; rc=$?
assert_eq "S10c: stale lock reclaimed, return 0" "$rc" "0"
assert_eq "S10d: seq == 3"         "$(jq -r '.seq' "$REC")" "3"
no_leftovers "S10e"
mkdir "$REC.lock"; cp "$REC" "$TMP/before"
out="$(SESSION_RECORD_LOCK_WAIT_SECS=1 session_record_update "$REC" 'true' '.seq += 1' 2>&1)"; rc=$?
rmdir "$REC.lock"
assert_eq       "S10f: live lock beyond the wait → 4" "$rc" "4"
assert_contains "S10g: reason"     "$out" "reason=lock_timeout"
cmp -s "$REC" "$TMP/before" && ok "S10h: byte-identical" || bad "S10h: record changed"
# The lost race (three flake sightings in S8/S10a): the holder released the
# lock between this writer's failed mkdir and its `-d` check. Deterministic
# here: a mkdir shadow fails once without creating anything, then defers.
( . "$LIB"; _n=0
  mkdir() { _n=$((_n+1)); [ "$_n" -gt 1 ] || return 1; command mkdir "$@"; }
  session_record_update "$REC" 'true' '.seq += 1' 2>"$TMP/s10i.err" ); rc=$?
assert_eq       "S10i: lock gone by the existence check → retried, return 0" "$rc" "0"
assert_eq       "S10j: seq == 4"   "$(jq -r '.seq' "$REC")" "4"
no_leftovers "S10k"
t0=$(date +%s)
out="$(session_record_update "$TMP/nodir/session-state.json" 'true' '.seq = 1' 2>&1)"; rc=$?
assert_eq       "S10l: a record whose directory does not exist → 4" "$rc" "4"
assert_contains "S10m: reason"     "$out" "reason=record_unwritable"
[ $(( $(date +%s) - t0 )) -lt 5 ] && ok "S10n: refused at once, not after the lock wait" || bad "S10n: waited for a lock that cannot exist"
touch "$REC.lock"; cp "$REC" "$TMP/before"
out="$(session_record_update "$REC" 'true' '.seq += 1' 2>&1)"; rc=$?
rm -f "$REC.lock"
assert_eq       "S10o: a file at the lock path → 4" "$rc" "4"
assert_contains "S10p: reason"     "$out" "reason=record_unwritable"
cmp -s "$REC" "$TMP/before" && ok "S10q: byte-identical" || bad "S10q: record changed"

echo "S11: jq missing — refused before anything is read or written"
mkdir -p "$TMP/bin"
for t in bash sleep mkdir rmdir mv rm cat ls cmp stat date; do p="$(command -v "$t")" && ln -sf "$p" "$TMP/bin/$t"; done
cp "$REC" "$TMP/before"
out="$( (PATH="$TMP/bin"; hash -r; session_record_update "$REC" 'true' '.seq += 1') 2>&1 )"; rc=$?
assert_eq       "S11a: return 4"   "$rc" "4"
assert_contains "S11b: reason"     "$out" "reason=jq_missing"
cmp -s "$REC" "$TMP/before" && ok "S11c: byte-identical" || bad "S11c: record changed"

echo
echo "test-session-lib: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
