#!/usr/bin/env bash
# File: scripts/tests/test-check-skill-descriptions.sh
# Purpose: check-skill-descriptions.sh sums the description bytes of model-invoked
#          skills only: under budget exits 0 with the exact byte total; over
#          budget exits 1 naming the largest skill; a user-invoked skill is
#          neither listed nor counted; a folded `>` description counts as the
#          joined, trimmed text; a skill with no description counts 0.
set -u
SRC_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TMP="$(mktemp -d)"; TMP="$(cd "$TMP" && pwd -P)"; trap 'rm -rf "$TMP"' EXIT

PASS=0; FAIL=0
ok()  { PASS=$((PASS+1)); echo "  ok: $1"; }
bad() { FAIL=$((FAIL+1)); echo "  FAIL: $1" >&2; }
assert_eq()       { [ "$2" = "$3" ] && ok "$1" || bad "$1 (want [$3] got [$2])"; }
assert_contains() { case "$2" in *"$3"*) ok "$1" ;; *) bad "$1 (no [$3] in [$2])" ;; esac; }
assert_lacks()    { case "$2" in *"$3"*) bad "$1 (unexpected [$3] in [$2])" ;; *) ok "$1" ;; esac; }

SINGLE="Use when you need the single-line thing done."
FOLD1="Use when the folded thing is needed,"
FOLD2="and also when it spans a second line."
FOLDED="$FOLD1 $FOLD2"
HUGE="$(printf 'h%.0s' $(seq 1 500))"
bytes() { local LC_ALL=C; local s="$1"; echo "${#s}"; }

# fixture <dir>: four skills — single-line, folded, user-invoked huge, no description.
fixture() {
  rm -rf "$1"
  mkdir -p "$1/scripts" "$1/skills/single" "$1/skills/folded" "$1/skills/manual" "$1/skills/nodesc"
  cp "$SRC_ROOT/scripts/check-skill-descriptions.sh" "$1/scripts/"
  printf -- '---\nname: single\ndescription: %s\n---\n# body\n' "$SINGLE" > "$1/skills/single/SKILL.md"
  printf -- '---\nname: folded\ndescription: >\n  %s\n  %s\n---\n# body\n' "$FOLD1" "$FOLD2" > "$1/skills/folded/SKILL.md"
  printf -- '---\nname: manual\ndescription: %s\ndisable-model-invocation: true\n---\n# body\n' "$HUGE" > "$1/skills/manual/SKILL.md"
  printf -- '---\nname: nodesc\n---\n# body\n' > "$1/skills/nodesc/SKILL.md"
}
run() { (cd "$1" && env -u SKILL_DESC_MAX_BYTES -u CHECK_ROOT "$@" bash scripts/check-skill-descriptions.sh 2>&1); }
runb() { local d="$1"; shift; (cd "$d" && env -u CHECK_ROOT "$@" bash scripts/check-skill-descriptions.sh 2>&1); }

WANT=$(( $(bytes "$SINGLE") + $(bytes "$FOLDED") ))

echo "P1: under budget — exit 0, both model-invoked names, exact total"
fixture "$TMP/w"; out="$(runb "$TMP/w" SKILL_DESC_MAX_BYTES=9000)"; rc=$?
assert_eq "P1 exit 0" "$rc" "0"
assert_contains "P1 lists single" "$out" "single"
assert_contains "P1 lists folded" "$out" "folded"
assert_contains "P1 exact total" "$out" "total: $WANT bytes over 3 model-invoked skills"

echo "P2: over budget — exit 1, OVER BUDGET, names the largest skill"
fixture "$TMP/w"; out="$(runb "$TMP/w" SKILL_DESC_MAX_BYTES=10)"; rc=$?
assert_eq "P2 exit 1" "$rc" "1"
assert_contains "P2 OVER BUDGET" "$out" "OVER BUDGET"
assert_contains "P2 names largest" "$(printf '%s\n' "$out" | grep '^OVER BUDGET')" "folded"

echo "P3: user-invoked skill is not listed and not counted"
fixture "$TMP/w"; out="$(runb "$TMP/w" SKILL_DESC_MAX_BYTES=9000)"
assert_lacks "P3 manual absent" "$out" "manual"
assert_lacks "P3 huge bytes absent" "$out" "$(bytes "$HUGE")"

echo "P4: folded description counts as the joined trimmed text"
assert_contains "P4 folded bytes" "$out" "$(printf '%6d  folded' "$(bytes "$FOLDED")")"
assert_contains "P4 nodesc counts 0" "$out" "$(printf '%6d  nodesc' 0)"

echo
echo "check-skill-descriptions: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
