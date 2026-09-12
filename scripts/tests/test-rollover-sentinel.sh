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

echo "S6 (D10): the bump record outranks a stale provenance sidecar"
# The sidecar is written ONLY by seq-sync, so in a chain that never needed a
# counter repair it holds whatever session last ran one — session 3 here, while
# session 8 is the one rolling over. launch-next-session.sh records the writer's
# own number at the bump; this is that record's consumer contract, unit-tested
# without the launcher so a failure localises to the precedence itself.
BUMP="$MAIN/work/testproj/.session-seq.bump.json"
rm -f "$SENT"
printf '3\n' > "$SEQF"
"$CB" seq-sync --project testproj --session 3 >/dev/null 2>&1
printf '9\n' > "$SEQF"          # session 8 has staged 9
jq -n '{seq:8, successor:9, runtime:"stub", session_id:"sid-8",
        cwd:"/x", written_at:"2026-09-11T00:00:00Z"}' > "$BUMP"
"$CB" rollover-complete --project testproj --mode handsoff >/dev/null 2>&1
assert_eq "S6a: the bump record's number wins over the frozen sidecar" \
          "$(jq -r '.seq' "$SENT")" "8"

# ... but only while it is current. A seq-sync repair moves the counter off the
# successor the record named, which is what retires it — the sidecar the repair
# just refreshed is then the newer fact.
rm -f "$SENT"
"$CB" seq-sync --project testproj --session 12 >/dev/null 2>&1
"$CB" rollover-complete --project testproj --mode handsoff >/dev/null 2>&1
assert_eq "S6b: a bump record the counter has moved past is ignored" \
          "$(jq -r '.seq' "$SENT")" "12"

# A truncated or unparseable record must not poison the chain either: it falls
# through to the same two sources that existed before it.
rm -f "$SENT"
printf '9\n' > "$SEQF"
printf 'not json' > "$BUMP"
"$CB" rollover-complete --project testproj --mode handsoff >/dev/null 2>&1
assert_eq "S6c: an unreadable bump record falls back, it does not fail" \
          "$(jq -r '.seq' "$SENT")" "12"
rm -f "$BUMP"

echo "passed=$PASS failed=$FAIL"
[ "$FAIL" -eq 0 ]
