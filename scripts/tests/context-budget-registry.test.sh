#!/usr/bin/env bash
# File: scripts/tests/context-budget-registry.test.sh
# Purpose: Regression tests for the session-keyed registry + per-project lock
#          in context-budget.sh (backlog M13 / ADR-0004). Self-contained:
#          builds a throwaway workspace + fake $HOME in mktemp -d.
set -u
SRC_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/scripts" "$TMP/work/testproj" "$TMP/home"
cp "$SRC_ROOT/scripts/context-budget.sh" "$TMP/scripts/"
printf 'CONTEXT_DUMB_ZONE_TOKENS=150000\nCONTEXT_DUMB_ZONE_WARN_TOKENS=120000\n' \
  > "$TMP/context-budget.env"
export HOME="$TMP/home"
cd "$TMP"
CB="$TMP/scripts/context-budget.sh"
SLUG="$(pwd | tr '/.' '--')"
PROJ_DIR="$HOME/.claude/projects/$SLUG"; mkdir -p "$PROJ_DIR"

PASS=0; FAIL=0
ok()   { PASS=$((PASS+1)); echo "  ok: $1"; }
bad()  { FAIL=$((FAIL+1)); echo "  FAIL: $1" >&2; }
assert_eq() { [ "$2" = "$3" ] && ok "$1" || bad "$1 (want [$3] got [$2])"; }
assert_contains() { case "$2" in *"$3"*) ok "$1" ;; *) bad "$1 (no [$3] in [$2])" ;; esac; }

mk_transcript() {  # $1=session-id $2=input-tokens
  jq -cn --argjson t "$2" \
    '{message:{usage:{input_tokens:$t,cache_read_input_tokens:0,cache_creation_input_tokens:0}},isSidechain:false}' \
    > "$PROJ_DIR/$1.jsonl"
}
run_as() {  # $1=claude-session-id, rest = context-budget.sh args
  local sid="$1"; shift
  CLAUDE_CODE_SESSION_ID="$sid" "$CB" "$@" --runtime claude
}

echo "T1: two concurrent sessions each measure their own transcript (M13)"
mk_transcript aaa 50000
mk_transcript bbb 90000
run_as aaa register --quiet >/dev/null
run_as bbb register --quiet >/dev/null          # must NOT clobber aaa's registration
out=$(run_as aaa check)
assert_contains "T1a: aaa check binds aaa's transcript" "$out" "artifact=$PROJ_DIR/aaa.jsonl"
assert_contains "T1b: aaa check measures aaa's tokens"  "$out" "tokens=50000"
out=$(run_as bbb check)
assert_contains "T1c: bbb check measures bbb's tokens"  "$out" "tokens=90000"

echo "T2: register --project acquires the lock; a live holder is not stolen"
LOCK="$TMP/work/testproj/.active-session"
mk_transcript aaa 50000; mk_transcript bbb 90000; touch "$PROJ_DIR/aaa.jsonl"
run_as aaa register --project testproj --quiet >/dev/null
assert_eq "T2a: lock holder is aaa" "$(jq -r .session_id "$LOCK" 2>/dev/null)" "aaa"
err=$(run_as bbb register --project testproj 2>&1 >/dev/null)
assert_eq "T2b: live lock not stolen" "$(jq -r .session_id "$LOCK")" "aaa"
assert_contains "T2c: holder warning emitted" "$err" "held by claude-aaa"

echo "T3: stale lock (holder artifact untouched for hours) is reclaimed"
touch -t 202601010000 "$PROJ_DIR/aaa.jsonl"
run_as bbb register --project testproj --quiet >/dev/null
assert_eq "T3a: stale lock reclaimed by bbb" "$(jq -r .session_id "$LOCK")" "bbb"

echo; echo "passed=$PASS failed=$FAIL"
[ "$FAIL" -eq 0 ]
