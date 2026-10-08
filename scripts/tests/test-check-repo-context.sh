#!/usr/bin/env bash
# File: scripts/tests/test-check-repo-context.sh
# Purpose: check-repo-context.sh is warn-only (always exit 0), so its failure
#          signal is the Status line: a covered repo whose code moved past the
#          recorded commit, or whose doc has no commit, → `degraded` with a ✗/?
#          reason line; an up-to-date repo → `ok`. Throwaway workspace.
set -u
SRC_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT

PASS=0; FAIL=0
ok()  { PASS=$((PASS+1)); echo "  ok: $1"; }
bad() { FAIL=$((FAIL+1)); echo "  FAIL: $1" >&2; }
assert_eq()       { [ "$2" = "$3" ] && ok "$1" || bad "$1 (want [$3] got [$2])"; }
assert_contains() { case "$2" in *"$3"*) ok "$1" ;; *) bad "$1 (no [$3] in [$2])" ;; esac; }

W="$TMP/ws"; R="$W/repos/foo"
mkdir -p "$W/scripts/lib" "$W/docs/repo-context/foo" "$R"
cp "$SRC_ROOT/scripts/check-repo-context.sh" "$W/scripts/"
cp "$SRC_ROOT/scripts/lib/repo-paths.sh" "$W/scripts/lib/"
g() { git -C "$R" -c user.name=t -c user.email=t@t "$@"; }
g init -q; echo a > "$R/a"; g add a; g commit -qm one
rec="$(g rev-parse --short HEAD)"
doc="$W/docs/repo-context/foo/code-structure.md"
run() { bash "$W/scripts/check-repo-context.sh" 2>&1; }

echo "C1: recorded commit is HEAD — ok"
printf 'Source commit: %s\n' "$rec" > "$doc"
out="$(run)"; rc=$?
assert_eq "C1 exit 0" "$rc" "0"
assert_contains "C1 status" "$out" "Status: repo-context=ok"

echo "C2: code changed since the recorded commit — degraded"
echo b > "$R/b"; g add b; g commit -qm two
out="$(run)"; rc=$?
assert_eq "C2 exit 0 (warn-only)" "$rc" "0"
assert_contains "C2 reason" "$out" "✗ foo: code changed since $rec"
assert_contains "C2 status" "$out" "Status: repo-context=degraded"

echo "C3: no recorded commit — degraded"
printf '# no provenance\n' > "$doc"
out="$(run)"
assert_contains "C3 reason" "$out" "? foo: no recorded source commit"
assert_contains "C3 status" "$out" "Status: repo-context=degraded"

echo
echo "check-repo-context: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
