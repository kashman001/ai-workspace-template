#!/usr/bin/env bash
# File: scripts/tests/test-attach-session.sh
# Purpose: Regression tests for attach-session.sh (Task 9, vendor-hook-
#          deployments plan). Self-contained: throwaway workspace in
#          mktemp -d; liveness driven via artifact mtime (touch -t) against
#          CONTEXT_LOCK_STALE_SECS, same fixture pattern as
#          scripts/tests/test-context-budget-registry.sh.
set -u
SRC_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/scripts" "$TMP/work/testproj" "$TMP/.context-budget/sessions" "$TMP/artifacts"
cp "$SRC_ROOT/scripts/attach-session.sh" "$TMP/scripts/"
printf 'CONTEXT_LOCK_STALE_SECS=10800\n' > "$TMP/context-budget.env"
cd "$TMP"
AS="$TMP/scripts/attach-session.sh"
SESS="$TMP/.context-budget/sessions"
LOCK="$TMP/work/testproj/.active-session"

PASS=0; FAIL=0
ok()   { PASS=$((PASS+1)); echo "  ok: $1"; }
bad()  { FAIL=$((FAIL+1)); echo "  FAIL: $1" >&2; }
assert_eq() { [ "$2" = "$3" ] && ok "$1" || bad "$1 (want [$3] got [$2])"; }
assert_contains() { case "$2" in *"$3"*) ok "$1" ;; *) bad "$1 (no [$3] in [$2])" ;; esac; }

mk_record() {  # $1=runtime $2=session-id $3=project $4=artifact
  jq -n --arg rt "$1" --arg sid "$2" --arg p "$3" --arg af "$4" \
    '{runtime:$rt, session_id:$sid, artifact:$af, project:$p, registered_at:"2026-08-06T00:00:00Z"}' \
    > "$SESS/$1-$2.json"
}
mk_lock() {  # $1=runtime $2=session-id $3=project
  jq -n --arg rt "$1" --arg sid "$2" --arg p "$3" \
    '{runtime:$rt, session_id:$sid, project:$p, acquired_at:"2026-08-06T00:00:00Z"}' \
    > "$LOCK"
}
fresh_artifact() { echo hi > "$TMP/artifacts/$1"; }         # mtime = now (live)
stale_artifact()  { echo hi > "$TMP/artifacts/$1"; touch -t 202601010000 "$TMP/artifacts/$1"; }

echo "T1: live + locked + claude -> attach command in dry-run output"
fresh_artifact sid-aaa.jsonl
mk_record claude sid-aaa testproj "$TMP/artifacts/sid-aaa.jsonl"
mk_lock claude sid-aaa testproj
out=$("$AS" testproj --dry-run 2>&1); rc=$?
assert_eq       "T1a: exit 0"         "$rc" "0"
assert_contains "T1b: status line"    "$out" "project=testproj runtime=claude session=sid-aaa"
assert_contains "T1c: live=yes"       "$out" "live=yes"
assert_contains "T1d: locked=yes"     "$out" "locked=yes"
assert_contains "T1e: resume command" "$out" "run: claude --resume sid-aaa"

echo "T2: stale lock -> launch hint, exit 0"
stale_artifact sid-aaa.jsonl
out=$("$AS" testproj --dry-run 2>&1); rc=$?
assert_eq       "T2a: exit 0"      "$rc" "0"
assert_contains "T2b: live=no"     "$out" "live=no"
assert_contains "T2c: launch hint" "$out" "no live session — run: scripts/launch-next-session.sh testproj"

echo "T3: live + locked + non-claude -> cannot-attach message, exit 0"
fresh_artifact sid-bbb.log
mk_record codex sid-bbb testproj "$TMP/artifacts/sid-bbb.log"
mk_lock codex sid-bbb testproj
out=$("$AS" testproj --dry-run 2>&1); rc=$?
assert_eq       "T3a: exit 0"            "$rc" "0"
assert_contains "T3b: live=yes locked=yes" "$out" "live=yes locked=yes"
assert_contains "T3c: cannot attach"     "$out" "cannot attach"
assert_contains "T3d: names runtime"     "$out" "codex has no background sessions"

echo "T4: no lock but registry record -> resolved via fallback"
rm -f "$LOCK" "$SESS"/*.json
fresh_artifact sid-ccc.jsonl
mk_record claude sid-ccc testproj "$TMP/artifacts/sid-ccc.jsonl"
out=$("$AS" testproj --dry-run 2>&1); rc=$?
assert_eq       "T4a: exit 0"                "$rc" "0"
assert_contains "T4b: fallback resolved sid" "$out" "runtime=claude session=sid-ccc"
assert_contains "T4c: locked=no"             "$out" "locked=no"
assert_contains "T4d: launch hint (unlocked, no attach)" "$out" "no live session — run:"

echo "T5: nothing known -> exit 3"
rm -f "$LOCK" "$SESS"/*.json
out=$("$AS" testproj --dry-run 2>&1); rc=$?
assert_eq       "T5a: exit 3"        "$rc" "3"
assert_contains "T5b: names the dir" "$out" "no session known for work/testproj"

echo "T6: bad args -> exit 3"
out=$("$AS" 2>&1); rc=$?
assert_eq "T6a: missing project exits 3" "$rc" "3"

echo; echo "passed=$PASS failed=$FAIL"
[ "$FAIL" -eq 0 ]
