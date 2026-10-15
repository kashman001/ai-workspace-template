#!/usr/bin/env bash
# File: scripts/tests/test-precompact-hook.sh
# Purpose: Regression tests for scripts/hooks/context-budget-precompact-hook.sh —
#          the opt-in block on Claude Code auto-compaction while a session owns
#          a work item. Self-contained: throwaway workspace in mktemp -d; asserts
#          exit codes only (2 = block, 0 = allow), plus the settings entry.
set -u
SRC_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/scripts/hooks" "$TMP/.context-budget/sessions" "$TMP/work/p"
cp "$SRC_ROOT"/scripts/hooks/context-budget-* "$TMP/scripts/hooks/" 2>/dev/null || true
HOOK="$TMP/scripts/hooks/context-budget-precompact-hook.sh"

PASS=0; FAIL=0
ok()  { PASS=$((PASS+1)); echo "  ok: $1"; }
bad() { FAIL=$((FAIL+1)); echo "  FAIL: $1" >&2; }
assert_eq() { [ "$2" = "$3" ] && ok "$1" || bad "$1 (want [$3] got [$2])"; }

# Owner sid-1 of work item p: the registry stamps the project, the record names the session.
echo '{"runtime":"claude","session_id":"sid-1","project":"p"}' > "$TMP/.context-budget/sessions/claude-sid-1.json"
echo '{"schema":1,"seq":3,"session":{"runtime":"claude","session_id":"sid-1"}}' > "$TMP/work/p/session-state.json"
: > "$TMP/context-budget.env"

# run <trigger> <sid> [VAR=val ...] -> prints the hook's exit code
run() {
  local trig="$1" sid="$2"; shift 2
  [ -x "$HOOK" ] || { echo "missing"; return; }
  jq -cn --arg t "$trig" --arg s "$sid" '{hook_event_name:"PreCompact", trigger:$t, session_id:$s}' \
    | env -u CONTEXT_BLOCK_AUTOCOMPACT WORKSPACE_ROOT="$TMP" "$@" "$HOOK" >/dev/null 2>&1
  echo $?
}

echo "P1: off by default"
assert_eq "P1a: auto, owner, knob unset -> allow" "$(run auto sid-1)" "0"

echo "P2: blocks auto compaction for the owner when the knob is on"
assert_eq "P2a: auto, owner, explicit env -> block" "$(run auto sid-1 CONTEXT_BLOCK_AUTOCOMPACT=1)" "2"
echo 'CONTEXT_BLOCK_AUTOCOMPACT=1' > "$TMP/context-budget.env"
assert_eq "P2b: auto, owner, global env file -> block" "$(run auto sid-1)" "2"
: > "$TMP/context-budget.env"
echo 'CONTEXT_BLOCK_AUTOCOMPACT=1' > "$TMP/work/p/context-budget.env"
assert_eq "P2c: auto, owner, per-item env file -> block" "$(run auto sid-1)" "2"
assert_eq "P2d: explicit env 0 beats the per-item file" "$(run auto sid-1 CONTEXT_BLOCK_AUTOCOMPACT=0)" "0"

echo "P3: never blocks manual compaction or a non-owner"
assert_eq "P3a: manual, owner, knob on -> allow" "$(run manual sid-1)" "0"
assert_eq "P3b: auto, unregistered session -> allow" "$(run auto sid-2)" "0"
echo '{"runtime":"claude","session_id":"sid-3","project":"p"}' > "$TMP/.context-budget/sessions/claude-sid-3.json"
assert_eq "P3c: auto, registry names p but the record's owner is another session -> allow" "$(run auto sid-3)" "0"

echo "P4: fail-open"
echo 'not json' > "$TMP/work/p/session-state.json"
assert_eq "P4a: unreadable record -> allow" "$(run auto sid-1)" "0"
assert_eq "P4b: empty payload -> allow" \
  "$(printf '' | env WORKSPACE_ROOT="$TMP" CONTEXT_BLOCK_AUTOCOMPACT=1 "$HOOK" >/dev/null 2>&1; echo $?)" "0"

echo "P5: wired in .claude/settings.json for auto only"
m=$(jq -r '[.hooks.PreCompact[]? | select(any(.hooks[]?; .command | test("context-budget-precompact-hook"))) | .matcher] | join(",")' "$SRC_ROOT/.claude/settings.json" 2>/dev/null)
assert_eq "P5a: one PreCompact entry, matcher auto" "$m" "auto"

echo
echo "$PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
