#!/usr/bin/env bash
# File: scripts/tests/test-rollover-sentinel.sh
# Purpose: `context-budget.sh rollover-complete` (spec: "Architecture" -> 3;
#          "Worktrees" -> layer 3, rules 1-2). The sentinel's identity fields are
#          what let a supervisor tell "no session ended" from "a session ended
#          somewhere I did not look", so they are pinned individually.
set -u
SRC_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
MAIN="$TMP/main"
mkdir -p "$MAIN/scripts" "$MAIN/work/testproj" "$MAIN/.context-budget/sessions"
cp "$SRC_ROOT/scripts/context-budget.sh" "$MAIN/scripts/"
chmod +x "$MAIN/scripts/"*.sh
printf 'CONTEXT_DUMB_ZONE_TOKENS=150000\n' > "$MAIN/context-budget.env"
echo "# launcher" > "$MAIN/work/testproj/next-session.md"
git -C "$MAIN" init -q
git -C "$MAIN" config user.email t@t; git -C "$MAIN" config user.name t
git -C "$MAIN" add -A; git -C "$MAIN" commit -qm init
CB="$MAIN/scripts/context-budget.sh"
SENT="$MAIN/work/testproj/.rollover-complete"
SEQF="$MAIN/work/testproj/.session-seq"

PASS=0; FAIL=0
ok()  { PASS=$((PASS+1)); echo "  ok: $1"; }
bad() { FAIL=$((FAIL+1)); echo "  FAIL: $1" >&2; }
assert_eq()       { [ "$2" = "$3" ] && ok "$1" || bad "$1 (want [$3] got [$2])"; }
assert_contains() { case "$2" in *"$3"*) ok "$1" ;; *) bad "$1 (no [$3] in [$2])" ;; esac; }

echo "S1: the sentinel carries the writing session's own number, not its successor's"
printf '8\n' > "$SEQF"
"$CB" seq-sync --project testproj --session 8 >/dev/null 2>&1
printf '9\n' > "$SEQF"          # --emit has since bumped the counter (failure mode 8)
"$CB" rollover-complete --project testproj --mode handsoff --label "STOP at 151K" >/dev/null 2>&1
assert_eq "S1a: seq is 8, the writer's own number" "$(jq -r '.seq' "$SENT")" "8"
assert_eq "S1b: mode recorded"     "$(jq -r '.mode' "$SENT")"   "handsoff"
assert_eq "S1c: reason recorded"   "$(jq -r '.reason' "$SENT")" "STOP at 151K"
assert_eq "S1d: cwd is absolute"   "$(jq -r '.cwd' "$SENT" | cut -c1)" "/"
[ "$(jq -r '.session_id' "$SENT")" != "null" ] && ok "S1e: session_id present" \
                                               || bad "S1e: session_id missing"
[ "$(jq -r '.runtime' "$SENT")" != "null" ]    && ok "S1f: runtime present" \
                                               || bad "S1f: runtime missing"

echo "S2: an invalid or missing mode is refused"
rm -f "$SENT"
out="$("$CB" rollover-complete --project testproj --mode sideways 2>&1 || true)"
assert_contains "S2a: an unknown mode is refused" "$out" "--mode must be"
[ -f "$SENT" ] && bad "S2b: a sentinel was written despite the refusal" \
               || ok "S2b: no sentinel written on refusal"
out="$("$CB" rollover-complete --project testproj 2>&1 || true)"
assert_contains "S2c: a missing mode is refused" "$out" "--mode"

echo "S3: the human override files win over the agent's inference"
touch "$MAIN/work/testproj/.interactive"
"$CB" rollover-complete --project testproj --mode handsoff >/dev/null 2>&1
assert_eq "S3a: .interactive overrides mode=handsoff" "$(jq -r '.mode' "$SENT")" "interactive"
rm -f "$MAIN/work/testproj/.interactive"
touch "$MAIN/work/testproj/.hands-off"
"$CB" rollover-complete --project testproj --mode interactive >/dev/null 2>&1
assert_eq "S3b: .hands-off overrides mode=interactive" "$(jq -r '.mode' "$SENT")" "handsoff"
touch "$MAIN/work/testproj/.interactive"
out="$("$CB" rollover-complete --project testproj --mode handsoff 2>&1 || true)"
assert_contains "S3c: both override files present is refused" "$out" "both"
rm -f "$MAIN/work/testproj/.interactive" "$MAIN/work/testproj/.hands-off"

echo "S4: THE LOAD-BEARING ONE — a worktree write still lands in the main checkout"
# This is the defect the whole layer-1 invariant exists to prevent. A sentinel
# that lands in the writer's worktree is invisible to the supervisor, which then
# reports a clean shutdown. The negative case must FAIL the test, not pass quietly.
git -C "$MAIN" worktree add -q -b wt "$TMP/wt"
rm -f "$SENT"
( cd "$TMP/wt" && "$MAIN/scripts/context-budget.sh" rollover-complete \
    --project testproj --mode handsoff >/dev/null 2>&1 )
[ -f "$SENT" ] && ok "S4a: the sentinel landed in the main checkout" \
               || bad "S4a: the sentinel did NOT land in the main checkout"
[ -f "$TMP/wt/work/testproj/.rollover-complete" ] \
  && bad "S4b: a stray sentinel was left inside the worktree" \
  || ok "S4b: nothing stranded in the worktree"
assert_contains "S4c: cwd records where the writer actually ran" \
  "$(jq -r '.cwd' "$SENT")" "wt"

echo "S5: a nonexistent work item is refused"
out="$("$CB" rollover-complete --project nosuch --mode handsoff 2>&1 || true)"
assert_contains "S5a: refused" "$out" "no such work directory"

echo "passed=$PASS failed=$FAIL"
[ "$FAIL" -eq 0 ]
