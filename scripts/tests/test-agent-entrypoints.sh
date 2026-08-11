#!/usr/bin/env bash
# File: scripts/tests/test-agent-entrypoints.sh
# Purpose: Static agent-entrypoint plumbing check — every runtime's discovery
#          file is a symlink that resolves to the single master CONTEXT.md,
#          and the onboarding canary token is present. This is the automated
#          prerequisite for the live per-runtime checks in
#          docs/agent-onboarding-check.md. Complements
#          check-workspace-structure.sh (which asserts symlinks resolve but
#          not what they point at).
set -u
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"

# Keep in sync with the canary line in CONTEXT.md (see
# docs/agent-onboarding-check.md → "Customizing the token").
CANARY_TOKEN="WORKSPACE-CONTEXT-OK"

# Entrypoint symlinks and their expected targets. Adding a runtime? Register
# it here, in setup.sh, and in check-workspace-structure.sh.
ENTRYPOINTS="CLAUDE.md AGENTS.md GEMINI.md"

PASS=0; FAIL=0
ok()  { PASS=$((PASS+1)); echo "  ok: $1"; }
bad() { FAIL=$((FAIL+1)); echo "  FAIL: $1" >&2; }

echo "E1: each entrypoint is a symlink whose target is CONTEXT.md"
for f in $ENTRYPOINTS; do
  if [ -L "$f" ] && [ "$(readlink "$f")" = "CONTEXT.md" ]; then
    ok "E1: $f -> CONTEXT.md"
  else
    bad "E1: $f is not a symlink to CONTEXT.md (got: $(readlink "$f" 2>/dev/null || echo 'not a symlink'))"
  fi
done

echo "E2: each entrypoint resolves and reads back CONTEXT.md's content"
for f in $ENTRYPOINTS; do
  if [ -r "$f" ] && head -1 "$f" 2>/dev/null | grep -q "Workspace Context"; then
    ok "E2: $f reads CONTEXT.md"
  else
    bad "E2: $f does not resolve to CONTEXT.md content (broken symlink?)"
  fi
done

echo "E3: the onboarding canary token is present in CONTEXT.md"
if grep -q "$CANARY_TOKEN" CONTEXT.md; then
  ok "E3: CONTEXT.md carries $CANARY_TOKEN"
else
  bad "E3: CONTEXT.md is missing the canary token $CANARY_TOKEN (see docs/agent-onboarding-check.md)"
fi

echo "E4: the live-check guide exists"
if [ -f docs/agent-onboarding-check.md ]; then
  ok "E4: docs/agent-onboarding-check.md exists"
else
  bad "E4: docs/agent-onboarding-check.md missing"
fi

echo
echo "pass=$PASS fail=$FAIL"
[ "$FAIL" -eq 0 ]
