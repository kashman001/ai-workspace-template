#!/usr/bin/env bash
# File: scripts/tests/test-rollover-clear-seed.sh
# Purpose: Regression tests for scripts/hooks/rollover-clear-seed.sh, the
#          SessionStart drain half of ADR-0009 (--clear in-place rollover).
#          Self-contained: throwaway workspace in mktemp -d, hook fed synthetic
#          SessionStart payloads on stdin.
set -u
SRC_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TMP="$(mktemp -d)"; TMP="$(cd "$TMP" && pwd -P)"; trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/scripts/hooks" "$TMP/work/projA" "$TMP/work/projB"
cp "$SRC_ROOT/scripts/hooks/rollover-clear-seed.sh" "$TMP/scripts/hooks/"
HOOK="$TMP/scripts/hooks/rollover-clear-seed.sh"
SEED_A="$TMP/work/projA/.pending-clear-seed"
SEED_B="$TMP/work/projB/.pending-clear-seed"

PASS=0; FAIL=0
ok()   { PASS=$((PASS+1)); echo "  ok: $1"; }
bad()  { FAIL=$((FAIL+1)); echo "  FAIL: $1" >&2; }
assert_eq() { [ "$2" = "$3" ] && ok "$1" || bad "$1 (want [$3] got [$2])"; }
assert_contains() { case "$2" in *"$3"*) ok "$1" ;; *) bad "$1 (no [$3] in [$2])" ;; esac; }

PROMPT='Work item projA - rollover session #7. Read `work/projA/next-session.md` and continue from **First actions**.'
payload() { printf '{"source":"%s","session_id":"sid-x"}' "$1"; }

echo "H1: source=clear with a pending marker — prompt emitted, marker drained"
printf '%s\n' "$PROMPT" > "$SEED_A"
out=$(payload clear | "$HOOK" 2>/dev/null); rc=$?
assert_eq       "H1a: exit 0"             "$rc" "0"
assert_eq       "H1b: hookEventName"      "$(printf '%s' "$out" | jq -r '.hookSpecificOutput.hookEventName')" "SessionStart"
assert_eq       "H1c: prompt verbatim"    "$(printf '%s' "$out" | jq -r '.hookSpecificOutput.additionalContext')" "$PROMPT"
[ ! -f "$SEED_A" ] && ok "H1d: marker drained" || bad "H1d: marker survived the emit"

echo "H2: a second /clear after the drain emits nothing (no stale re-seed)"
out=$(payload clear | "$HOOK" 2>/dev/null); rc=$?
assert_eq "H2a: exit 0"       "$rc" "0"
assert_eq "H2b: no output"    "$out" ""

echo "H3: non-clear sources never seed, and never drain"
printf '%s\n' "$PROMPT" > "$SEED_A"
for src in startup resume compact; do
  out=$(payload "$src" | "$HOOK" 2>/dev/null); rc=$?
  assert_eq "H3-$src: exit 0"    "$rc" "0"
  assert_eq "H3-$src: silent"    "$out" ""
done
[ -f "$SEED_A" ] && ok "H3d: marker untouched by non-clear sources" || bad "H3d: marker drained on a non-clear source"

echo "H4: two pending markers — newest wins, the older is left in place"
printf 'older mission\n' > "$SEED_B"
touch -t 202001010000 "$SEED_B"
out=$(payload clear | "$HOOK" 2>/dev/null)
assert_contains "H4a: newest marker seeded" "$(printf '%s' "$out" | jq -r '.hookSpecificOutput.additionalContext')" "rollover session #7"
[ ! -f "$SEED_A" ] && ok "H4b: newest drained"        || bad "H4b: newest survived"
[ -f "$SEED_B" ]   && ok "H4c: older left in place"   || bad "H4c: older was drained too"
rm -f "$SEED_B"

echo "H5: fails open — malformed, empty and non-JSON payloads emit nothing, exit 0"
printf '%s\n' "$PROMPT" > "$SEED_A"
for p in '' 'not json at all' '{"unrelated":1}'; do
  out=$(printf '%s' "$p" | "$HOOK" 2>/dev/null); rc=$?
  assert_eq "H5: exit 0 on [${p:-<empty>}]" "$rc" "0"
  assert_eq "H5: silent on [${p:-<empty>}]" "$out" ""
done
[ -f "$SEED_A" ] && ok "H5d: marker untouched by bad payloads" || bad "H5d: bad payload drained the marker"

echo "H6: an empty marker is not seeded (nothing to say), and is still drained"
: > "$SEED_A"
out=$(payload clear | "$HOOK" 2>/dev/null); rc=$?
assert_eq "H6a: exit 0"    "$rc" "0"
assert_eq "H6b: no output" "$out" ""

echo "H7: the hook is registered as a SessionStart hook in .claude/settings.json.example"
# Without registration the --clear flag is a trap: the counter advances and the
# seed is never drained. The example config is what scripts/setup.sh copies.
CFG="$SRC_ROOT/.claude/settings.json.example"
assert_eq "H7a: example config is valid JSON" \
  "$(jq -e . "$CFG" >/dev/null 2>&1 && echo yes || echo no)" "yes"
assert_eq "H7b: registered on SessionStart" \
  "$(jq -r '[.hooks.SessionStart[].hooks[].command | select(test("rollover-clear-seed[.]sh"))] | length' "$CFG")" "1"

echo; echo "passed=$PASS failed=$FAIL"
[ "$FAIL" -eq 0 ]
