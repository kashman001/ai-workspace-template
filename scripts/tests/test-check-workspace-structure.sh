#!/usr/bin/env bash
# File: scripts/tests/test-check-workspace-structure.sh
# Purpose: check-workspace-structure.sh fails on a broken workspace: a minimal
#          valid fixture exits 0, then a missing dir, a broken entrypoint
#          symlink, and a non-executable script each exit 1 with a ✗ reason.
#          (The date-line warning is covered by test-context-prefix-stability.sh.)
set -u
SRC_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT

PASS=0; FAIL=0
ok()  { PASS=$((PASS+1)); echo "  ok: $1"; }
bad() { FAIL=$((FAIL+1)); echo "  FAIL: $1" >&2; }
assert_eq()       { [ "$2" = "$3" ] && ok "$1" || bad "$1 (want [$3] got [$2])"; }
assert_contains() { case "$2" in *"$3"*) ok "$1" ;; *) bad "$1 (no [$3] in [$2])" ;; esac; }

# fixture <dir>: the smallest workspace the check accepts.
fixture() {
  rm -rf "$1"
  mkdir -p "$1"/{docs/repo-context/_templates,skills,work,prompt-library,references,repos,scripts,.github}
  cp "$SRC_ROOT/scripts/check-workspace-structure.sh" "$1/scripts/"
  printf '# ctx\n' > "$1/CONTEXT.md"
  for l in CLAUDE.md AGENTS.md GEMINI.md; do ln -s CONTEXT.md "$1/$l"; done
  ln -s ../CONTEXT.md "$1/.github/copilot-instructions.md"
  printf '# registry\n' > "$1/docs/repos-registry.md"
  ln -s ../docs/repos-registry.md "$1/repos/README.md"
  for f in code-structure.md design.md api.md; do : > "$1/docs/repo-context/_templates/$f"; done
}
run() { bash "$1/scripts/check-workspace-structure.sh" 2>&1; }

echo "W1: minimal valid workspace — exit 0"
fixture "$TMP/w"; out="$(run "$TMP/w")"; rc=$?
assert_eq "W1 exit 0" "$rc" "0"

echo "W2: missing required dir — exit 1"
fixture "$TMP/w"; rmdir "$TMP/w/references"; out="$(run "$TMP/w")"; rc=$?
assert_eq "W2 exit 1" "$rc" "1"
assert_contains "W2 reason" "$out" "missing dir references"

echo "W3: broken entrypoint symlink — exit 1"
fixture "$TMP/w"; rm "$TMP/w/AGENTS.md"; ln -s NOPE.md "$TMP/w/AGENTS.md"; out="$(run "$TMP/w")"; rc=$?
assert_eq "W3 exit 1" "$rc" "1"
assert_contains "W3 reason" "$out" "broken/missing symlink AGENTS.md"

echo "W4: script not executable — exit 1"
fixture "$TMP/w"; printf '#!/bin/sh\n' > "$TMP/w/scripts/x.sh"; chmod -x "$TMP/w/scripts/x.sh"
out="$(run "$TMP/w")"; rc=$?
assert_eq "W4 exit 1" "$rc" "1"
assert_contains "W4 reason" "$out" "not executable scripts/x.sh"

echo
echo "check-workspace-structure: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
