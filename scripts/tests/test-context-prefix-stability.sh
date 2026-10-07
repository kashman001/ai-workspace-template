#!/usr/bin/env bash
# File: scripts/tests/test-context-prefix-stability.sh
# Purpose: check-workspace-structure.sh flags a date-like line in CONTEXT.md
#          (backlog L49, "Cache the prefix, vary the tail" in
#          docs/context-budget.md) and stays quiet on a date-free one.
#          Runs the check against a throwaway fixture; other checks fail
#          there by design, so only the date-rule message is asserted.
set -u
SRC_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT

PASS=0; FAIL=0
ok()  { PASS=$((PASS+1)); echo "  ok: $1"; }
bad() { FAIL=$((FAIL+1)); echo "  FAIL: $1" >&2; }

mkdir -p "$TMP/scripts"
cp "$SRC_ROOT/scripts/check-workspace-structure.sh" "$TMP/scripts/"
MSG="CONTEXT.md has a date-like line"

echo "P1: a dated line in CONTEXT.md is flagged"
printf '# ctx\n\nLast updated: 2026-10-07\n' > "$TMP/CONTEXT.md"
out=$("$TMP/scripts/check-workspace-structure.sh" 2>&1)
case "$out" in *"$MSG"*) ok "P1: flagged" ;; *) bad "P1: not flagged" ;; esac
case "$out" in *"CONTEXT.md:3"*) ok "P1: names the line" ;; *) bad "P1: line not named" ;; esac

echo "P2: a date-free CONTEXT.md is not flagged"
printf '# ctx\n\nNo dates here.\n' > "$TMP/CONTEXT.md"
out=$("$TMP/scripts/check-workspace-structure.sh" 2>&1)
case "$out" in *"$MSG"*) bad "P2: false flag" ;; *) ok "P2: quiet" ;; esac

echo "P3: the real CONTEXT.md is date-free"
if grep -qE '20[0-9][0-9]-[01][0-9]-' "$SRC_ROOT/CONTEXT.md"; then
  bad "P3: CONTEXT.md carries a date-like line"
else
  ok "P3: date-free"
fi

echo "PASS=$PASS FAIL=$FAIL"
[ "$FAIL" = 0 ]
