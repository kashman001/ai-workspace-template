#!/usr/bin/env bash
# File: scripts/tests/test-session-numbering.sh
# Purpose: End-to-end session-numbering behaviour across launch-next-session.sh
#          and seq-sync, including the 2026-08-25 regression pin (spec:
#          "Session number progression"; ADR-0008).
set -u
SRC_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
MAIN="$TMP/main"
mkdir -p "$MAIN/scripts" "$MAIN/work/testproj" "$MAIN/.context-budget/sessions"
cp "$SRC_ROOT/scripts/launch-next-session.sh" "$SRC_ROOT/scripts/context-budget.sh" "$MAIN/scripts/"
chmod +x "$MAIN/scripts/"*.sh
printf 'ROLLOVER_RELAUNCH=manual\nROLLOVER_RUNTIME=claude\n' > "$MAIN/context-budget.env"
echo "# launcher" > "$MAIN/work/testproj/next-session.md"
git -C "$MAIN" init -q
git -C "$MAIN" config user.email t@t; git -C "$MAIN" config user.name t
git -C "$MAIN" add -A; git -C "$MAIN" commit -qm init
LNS="$MAIN/scripts/launch-next-session.sh"
CB="$MAIN/scripts/context-budget.sh"
SEQF="$MAIN/work/testproj/.session-seq"

PASS=0; FAIL=0
ok()  { PASS=$((PASS+1)); echo "  ok: $1"; }
bad() { FAIL=$((FAIL+1)); echo "  FAIL: $1" >&2; }
assert_eq() { [ "$2" = "$3" ] && ok "$1" || bad "$1 (want [$3] got [$2])"; }
assert_contains() { case "$2" in *"$3"*) ok "$1" ;; *) bad "$1 (no [$3] in [$2])" ;; esac; }
run_lns() { env -u CLAUDE_CODE_SESSION_ID -u CODEX_THREAD_ID \
  -u COPILOT_AGENT_SESSION_ID -u VSCODE_TARGET_SESSION_LOG \
  -u ROLLOVER_RELAUNCH -u ROLLOVER_RUNTIME "$@"; }

echo "N1: REGRESSION PIN (2026-08-25) — a session prompted #3 cannot produce a #5"
# The defect: session 3 wrote its SUCCESSOR's number (4); the launcher added one
# and launched #5. With step 6 an assertion, session 3 records 3 and gets #4.
printf '3\n' > "$SEQF"
out=$("$CB" seq-sync --project testproj --session 3 2>&1)
assert_contains "N1a: session 3 is a noop"   "$out" "seq-sync: noop"
assert_eq       "N1b: counter still 3"       "$(cat "$SEQF")" "3"
out=$(run_lns "$LNS" testproj --runtime claude --dry-run 2>&1)
assert_contains "N1c: successor is #4"       "$out" "session #4"
case "$out" in *"session #5"*) bad "N1d: a #5 successor was produced" ;;
               *) ok "N1d: no #5 successor" ;; esac

echo "N2: the launcher increments by exactly one on a real run"
printf '3\n' > "$SEQF"
run_lns "$LNS" testproj --runtime claude >/dev/null 2>&1 </dev/null || true
assert_eq "N2a: counter advanced 3 -> 4" "$(cat "$SEQF")" "4"

echo "N3: a stray worktree copy no longer floors the main counter"
git -C "$MAIN" worktree add -q -b wt "$TMP/wt"
mkdir -p "$TMP/wt/work/testproj"
printf '99\n' > "$TMP/wt/work/testproj/.session-seq"   # the stranded over-count
printf '4\n'  > "$SEQF"
out=$(run_lns "$LNS" testproj --runtime claude --dry-run 2>&1)
assert_contains "N3a: successor is #5, not #100" "$out" "session #5"
assert_contains "N3b: the stray is reported"     "$out" "stray"

echo "N4: downward correction lands even with a stray present"
printf '9\n' > "$SEQF"
out=$("$CB" seq-sync --project testproj --session 4 2>&1)
assert_contains "N4a: lowered"      "$out" "seq-sync: lowered"
assert_eq       "N4b: counter is 4" "$(cat "$SEQF")" "4"
out=$(run_lns "$LNS" testproj --runtime claude --dry-run 2>&1)
assert_contains "N4c: successor is #5" "$out" "session #5"

echo; echo "passed=$PASS failed=$FAIL"
[ "$FAIL" -eq 0 ]
