#!/usr/bin/env bash
# File: scripts/tests/test-check-dependencies.sh
# Purpose: Regression tests for the runtime-aware context-budget hooks check in
#          check-dependencies.sh (backlog M24): committed non-Claude wiring must
#          satisfy the check on a pristine clone, the Claude settings copy is
#          required only when `claude` is installed, and a tree with no wiring
#          at all still fails.
set -u
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

PASS=0; FAIL=0
ok()  { PASS=$((PASS+1)); echo "  ok: $1"; }
bad() { FAIL=$((FAIL+1)); echo "  FAIL: $1" >&2; }

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# Sandbox workspace: the script under test resolves ROOT from its own path,
# so a copy under $TMP/ws/scripts sees $TMP/ws as the workspace.
WS="$TMP/ws"
mkdir -p "$WS/scripts"
cp "$ROOT/scripts/check-dependencies.sh" "$WS/scripts/"

# A PATH without user-local/homebrew dirs, so a real `claude` install on this
# machine can't leak into the "claude absent" scenarios. Core tools the script
# needs (grep, ls, uname, head, git) live in /usr/bin:/bin.
BASE_PATH="/usr/bin:/bin"
STUB="$TMP/stub-bin"
mkdir -p "$STUB"
printf '#!/bin/sh\necho claude stub 1.0\n' > "$STUB/claude"
chmod +x "$STUB/claude"

wire_committed() {  # the wiring a pristine clone ships
  mkdir -p "$WS/.codex" "$WS/.gemini" "$WS/.opencode/plugins" "$WS/.github/hooks"
  echo 'command = "scripts/hooks/context-budget-codex-hook.sh"' > "$WS/.codex/config.toml"
  echo '{"command": "scripts/hooks/context-budget-gemini-hook.sh"}' > "$WS/.gemini/settings.json"
  : > "$WS/.opencode/plugins/context-budget.js"
  : > "$WS/.github/hooks/context-budget.json"
}
unwire_all() {
  rm -rf "$WS/.codex" "$WS/.gemini" "$WS/.opencode" "$WS/.github" "$WS/.claude"
}

echo "D1: pristine clone, claude not installed — committed wiring satisfies the hooks check"
unwire_all; wire_committed
out="$(PATH="$BASE_PATH" "$WS/scripts/check-dependencies.sh" 2>&1)"
if echo "$out" | grep -q 'hooks.*wired:.*codex.*gemini.*opencode.*copilot'; then
  ok "D1: hooks reported wired for the committed runtimes"
else
  bad "D1: expected committed wiring to pass; got: $(echo "$out" | grep hooks)"
fi
if echo "$out" | grep -q 'hooks.*MISSING'; then
  bad "D1: hooks flagged MISSING on a pristine clone"
else
  ok "D1: no hooks MISSING line"
fi

echo "D2: claude installed but its settings copy absent — required failure"
out="$(PATH="$STUB:$BASE_PATH" "$WS/scripts/check-dependencies.sh" 2>&1)"; rc=$?
if [ "$rc" -ne 0 ] && echo "$out" | grep -q 'claude is installed but its context-budget hooks are not wired'; then
  ok "D2: exit $rc with the claude-specific MISSING message"
else
  bad "D2: expected exit 1 + claude MISSING message; rc=$rc, hooks line: $(echo "$out" | grep hooks)"
fi

echo "D3: claude installed and settings copy wired — check passes and lists claude"
mkdir -p "$WS/.claude"
echo '{"hooks": "context-budget-claude-hook"}' > "$WS/.claude/settings.local.json"
out="$(PATH="$STUB:$BASE_PATH" "$WS/scripts/check-dependencies.sh" 2>&1)"
if echo "$out" | grep -q 'hooks.*wired:.*claude'; then
  ok "D3: hooks wired line includes claude"
else
  bad "D3: expected wired line including claude; got: $(echo "$out" | grep hooks)"
fi

echo "D4: no wiring for any runtime — required failure"
unwire_all
out="$(PATH="$BASE_PATH" "$WS/scripts/check-dependencies.sh" 2>&1)"; rc=$?
if [ "$rc" -ne 0 ] && echo "$out" | grep -q 'no runtime has context-budget hooks wired'; then
  ok "D4: exit $rc with the no-runtime MISSING message"
else
  bad "D4: expected exit 1 + no-runtime message; rc=$rc, hooks line: $(echo "$out" | grep hooks)"
fi

echo
echo "check-dependencies tests: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
