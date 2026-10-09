#!/usr/bin/env bash
# File: scripts/tests/test-check-plans.sh
# Purpose: check-plans.sh lints every committed plan: a workspace whose plans
#          are clean (or that has none, or only old flat plan files) exits 0;
#          a broken node in any work item's plan exits 1 naming the plan and
#          plan.sh's violation line.
set -u
SRC_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TMP="$(mktemp -d)"; TMP="$(cd "$TMP" && pwd -P)"; trap 'rm -rf "$TMP"' EXIT

PASS=0; FAIL=0
ok()  { PASS=$((PASS+1)); echo "  ok: $1"; }
bad() { FAIL=$((FAIL+1)); echo "  FAIL: $1" >&2; }
assert_eq()       { [ "$2" = "$3" ] && ok "$1" || bad "$1 (want [$3] got [$2])"; }
assert_contains() { case "$2" in *"$3"*) ok "$1" ;; *) bad "$1 (no [$3] in [$2])" ;; esac; }

# fixture <dir>: a workspace with one clean plan and one old flat plans/ dir.
fixture() {
  rm -rf "$1"
  mkdir -p "$1/scripts" "$1/work/demo/plans" "$1/work/old/plans"
  cp "$SRC_ROOT/scripts/plan.sh" "$SRC_ROOT/scripts/check-plans.sh" "$1/scripts/"
  cp -R "$SRC_ROOT/scripts/tests/fixtures/plan-01-concept" "$1/work/demo/plans/01-concept"
  printf '# an old-format plan, not linted\n' > "$1/work/old/plans/phase-1.md"
}
run() { (cd "$1" && unset TF_SESSION_PROJECT && bash scripts/check-plans.sh 2>&1); }

echo "P1: clean plans — exit 0"
fixture "$TMP/w"; out="$(run "$TMP/w")"; rc=$?
assert_eq "P1 exit 0" "$rc" "0"
assert_contains "P1 names the plan" "$out" "work/demo/plans/01-concept"

echo "P2: no node-directory plans at all — exit 0"
fixture "$TMP/w"; rm -rf "$TMP/w/work/demo"; out="$(run "$TMP/w")"; rc=$?
assert_eq "P2 exit 0" "$rc" "0"

echo "P3: a node with an unknown status — exit 1 naming the plan and the violation"
fixture "$TMP/w"
n="$(ls "$TMP/w/work/demo/plans/01-concept/nodes/"*.md | head -1)"
sed -i.bak 's/^status: .*/status: bogus/' "$n"; rm -f "$n.bak"
out="$(run "$TMP/w")"; rc=$?
assert_eq "P3 exit 1" "$rc" "1"
assert_contains "P3 names the plan" "$out" "work/demo/plans/01-concept"
assert_contains "P3 carries plan.sh's line" "$out" "bogus"

echo
echo "check-plans: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
