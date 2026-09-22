#!/usr/bin/env bash
# File: scripts/tests/test-attach-session.sh
# Purpose: Regression tests for attach-session.sh (Task 9, vendor-hook-
#          deployments plan; ticket 01 of work/session-management-followups
#          moved ownership onto the record). Self-contained: throwaway
#          workspace in mktemp -d; the owner is work/<p>/session-state.json's
#          `session` block, alive while its pid is (ADR-0010) — a live pid is
#          this test shell, a dead one a reaped child; the fallback paths keep
#          the artifact-mtime liveness (touch -t) against CONTEXT_LOCK_STALE_SECS.
set -u
SRC_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/scripts/lib" "$TMP/work/testproj" "$TMP/.context-budget/sessions" "$TMP/artifacts"
cp "$SRC_ROOT/scripts/attach-session.sh" "$TMP/scripts/"
cp "$SRC_ROOT/scripts/lib/session-lib.sh" "$TMP/scripts/lib/"
printf 'CONTEXT_LOCK_STALE_SECS=10800\n' > "$TMP/context-budget.env"
cd "$TMP"
AS="$TMP/scripts/attach-session.sh"
SESS="$TMP/.context-budget/sessions"
REC="$TMP/work/testproj/session-state.json"
STRAY="$TMP/work/testproj/.active-session"

PASS=0; FAIL=0
ok()   { PASS=$((PASS+1)); echo "  ok: $1"; }
bad()  { FAIL=$((FAIL+1)); echo "  FAIL: $1" >&2; }
assert_eq() { [ "$2" = "$3" ] && ok "$1" || bad "$1 (want [$3] got [$2])"; }
assert_contains() { case "$2" in *"$3"*) ok "$1" ;; *) bad "$1 (no [$3] in [$2])" ;; esac; }
assert_not_contains() { case "$2" in *"$3"*) bad "$1 (unexpected [$3] in [$2])" ;; *) ok "$1" ;; esac; }

LIVE_PID=$$
LIVE_START="$(ps -o lstart= -p "$LIVE_PID" | sed 's/^ *//;s/ *$//')"
sh -c 'exit 0' & DEAD_PID=$!; wait "$DEAD_PID"

mk_record() {  # $1=runtime $2=session-id $3=project $4=artifact
  jq -n --arg rt "$1" --arg sid "$2" --arg p "$3" --arg af "$4" \
    '{runtime:$rt, session_id:$sid, artifact:$af, project:$p, registered_at:"2026-08-06T00:00:00Z"}' \
    > "$SESS/$1-$2.json"
}
mk_owner() {  # $1=runtime $2=session-id $3=pid $4=pid_start $5=artifact -> the item's record
  jq -n --arg rt "$1" --arg sid "$2" --argjson pid "$3" --arg ps "$4" --arg af "$5" \
    '{schema:1, seq:4, session:{seq:4, runtime:$rt, session_id:$sid, pid:$pid, pid_start:$ps,
      artifact:$af, registered_at:"2026-09-22T00:00:00Z", ended:null}}' > "$REC"
}
fresh_artifact() { echo hi > "$TMP/artifacts/$1"; }         # mtime = now (live)
stale_artifact()  { echo hi > "$TMP/artifacts/$1"; touch -t 202601010000 "$TMP/artifacts/$1"; }

echo "T1: live owner + claude -> attach command in dry-run output"
fresh_artifact sid-aaa.jsonl
mk_record claude sid-aaa testproj "$TMP/artifacts/sid-aaa.jsonl"
mk_owner claude sid-aaa "$LIVE_PID" "$LIVE_START" "$TMP/artifacts/sid-aaa.jsonl"
out=$("$AS" testproj --dry-run 2>&1); rc=$?
assert_eq       "T1a: exit 0"         "$rc" "0"
assert_contains "T1b: status line"    "$out" "project=testproj runtime=claude session=sid-aaa"
assert_contains "T1c: live=yes"       "$out" "live=yes"
assert_contains "T1d: locked=yes"     "$out" "locked=yes"
assert_contains "T1e: resume command" "$out" "run: claude --resume sid-aaa"

echo "T2: owner whose pid is dead -> launch hint, exit 0 (artifact freshness does not revive it)"
mk_owner claude sid-aaa "$DEAD_PID" "$LIVE_START" "$TMP/artifacts/sid-aaa.jsonl"
out=$("$AS" testproj --dry-run 2>&1); rc=$?
assert_eq       "T2a: exit 0"      "$rc" "0"
assert_contains "T2b: live=no"     "$out" "live=no"
assert_contains "T2c: launch hint" "$out" "no live session — run: scripts/launch-next-session.sh testproj"
echo "T2d: a recycled pid (start time differs) is dead too"
mk_owner claude sid-aaa "$LIVE_PID" "Mon Jan  1 00:00:00 2001" "$TMP/artifacts/sid-aaa.jsonl"
out=$("$AS" testproj --dry-run 2>&1)
assert_contains "T2d: live=no on pid_start mismatch" "$out" "live=no"
echo "T2e: an ended owner is not an owner"
mk_owner claude sid-aaa "$LIVE_PID" "$LIVE_START" "$TMP/artifacts/sid-aaa.jsonl"
jq '.session.ended = {at:"2026-09-22T01:00:00Z", door:"stop"}' "$REC" > "$REC.new" && mv "$REC.new" "$REC"
out=$("$AS" testproj --dry-run 2>&1)
assert_contains "T2e: locked=no once ended" "$out" "locked=no"

echo "T3: live owner + non-claude -> cannot-attach message, exit 0"
fresh_artifact sid-bbb.log
mk_record codex sid-bbb testproj "$TMP/artifacts/sid-bbb.log"
mk_owner codex sid-bbb "$LIVE_PID" "$LIVE_START" "$TMP/artifacts/sid-bbb.log"
out=$("$AS" testproj --dry-run 2>&1); rc=$?
assert_eq       "T3a: exit 0"            "$rc" "0"
assert_contains "T3b: live=yes locked=yes" "$out" "live=yes locked=yes"
assert_contains "T3c: cannot attach"     "$out" "cannot attach"
assert_contains "T3d: names runtime"     "$out" "codex has no background sessions"

echo "T4: no record but registry entry -> resolved via fallback"
rm -f "$REC" "$SESS"/*.json
fresh_artifact sid-ccc.jsonl
mk_record claude sid-ccc testproj "$TMP/artifacts/sid-ccc.jsonl"
out=$("$AS" testproj --dry-run 2>&1); rc=$?
assert_eq       "T4a: exit 0"                "$rc" "0"
assert_contains "T4b: fallback resolved sid" "$out" "runtime=claude session=sid-ccc"
assert_contains "T4c: locked=no"             "$out" "locked=no"
assert_contains "T4d: launch hint (unlocked, no attach)" "$out" "live but does not hold the work-item lock — not attaching; run:"

echo "T5: nothing known -> exit 3"
rm -f "$REC" "$SESS"/*.json
out=$("$AS" testproj --dry-run 2>&1); rc=$?
assert_eq       "T5a: exit 3"        "$rc" "3"
assert_contains "T5b: names the dir" "$out" "no session known for work/testproj"

echo "T6: bad args -> exit 3"
out=$("$AS" 2>&1); rc=$?
assert_eq "T6a: missing project exits 3" "$rc" "3"

echo "T7: status line reports the session's role"
fresh_artifact sid-aaa.jsonl
mk_record claude sid-aaa testproj "$TMP/artifacts/sid-aaa.jsonl"
mk_owner claude sid-aaa "$LIVE_PID" "$LIVE_START" "$TMP/artifacts/sid-aaa.jsonl"
out=$("$AS" testproj --dry-run 2>&1)
assert_contains "T7a: owner shows role=primary" "$out" "role=primary"
rm -f "$REC"
jq '.role="superseded"' "$SESS/claude-sid-aaa.json" > "$SESS/tmp.json" \
  && mv "$SESS/tmp.json" "$SESS/claude-sid-aaa.json"
out=$("$AS" testproj --dry-run 2>&1)
assert_contains "T7b: recorded role shown when unowned" "$out" "role=superseded"
jq 'del(.role)' "$SESS/claude-sid-aaa.json" > "$SESS/tmp.json" \
  && mv "$SESS/tmp.json" "$SESS/claude-sid-aaa.json"
out=$("$AS" testproj --dry-run 2>&1)
assert_contains "T7c: no role recorded -> role=none" "$out" "role=none"

echo "T8: a stray .active-session file changes nothing"
jq -n '{runtime:"claude", session_id:"sid-aaa", project:"testproj", acquired_at:"2026-08-06T00:00:00Z"}' > "$STRAY"
out=$("$AS" testproj --dry-run 2>&1)
assert_contains     "T8a: stray lock does not confer ownership" "$out" "locked=no"
assert_not_contains "T8b: no attach command" "$out" "run: claude"
mk_owner claude sid-ddd "$LIVE_PID" "$LIVE_START" "$TMP/artifacts/sid-aaa.jsonl"
out=$("$AS" testproj --dry-run 2>&1)
assert_contains "T8c: record wins over the stray file" "$out" "session=sid-ddd role=primary"
rm -f "$STRAY" "$REC" "$SESS"/*.json

echo; echo "passed=$PASS failed=$FAIL"
[ "$FAIL" -eq 0 ]
