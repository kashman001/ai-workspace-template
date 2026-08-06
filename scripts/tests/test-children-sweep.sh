#!/usr/bin/env bash
# File: scripts/tests/test-children-sweep.sh
# Purpose: Regression tests for the per-child transcript sweep (`children`
#          subcommand) in context-budget.sh — R1 of the subagent-rollover
#          research (work/automatic-session-rollover, slice 2). Self-contained:
#          builds a throwaway workspace + fake $HOME in mktemp -d.
set -u
SRC_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/scripts" "$TMP/work/testproj" "$TMP/home"
cp "$SRC_ROOT/scripts/context-budget.sh" "$TMP/scripts/"
printf 'CONTEXT_DUMB_ZONE_TOKENS=150000\nCONTEXT_DUMB_ZONE_WARN_TOKENS=120000\n' \
  > "$TMP/context-budget.env"
export HOME="$TMP/home"
cd "$TMP"
CB="$TMP/scripts/context-budget.sh"
SLUG="$(pwd | tr '/.' '--')"
PROJ_DIR="$HOME/.claude/projects/$SLUG"; mkdir -p "$PROJ_DIR"

PASS=0; FAIL=0
ok()   { PASS=$((PASS+1)); echo "  ok: $1"; }
bad()  { FAIL=$((FAIL+1)); echo "  FAIL: $1" >&2; }
assert_eq() { [ "$2" = "$3" ] && ok "$1" || bad "$1 (want [$3] got [$2])"; }
assert_contains() { case "$2" in *"$3"*) ok "$1" ;; *) bad "$1 (no [$3] in [$2])" ;; esac; }
assert_not_contains() { case "$2" in *"$3"*) bad "$1 (unwanted [$3] in [$2])" ;; *) ok "$1" ;; esac; }

mk_transcript() {  # $1=session-id $2=input-tokens — parent (main-chain) transcript
  jq -cn --argjson t "$2" \
    '{message:{usage:{input_tokens:$t,cache_read_input_tokens:0,cache_creation_input_tokens:0}},isSidechain:false}' \
    > "$PROJ_DIR/$1.jsonl"
}
mk_child() {  # $1=parent-session-id $2=agent-hash $3=tokens [$4=agentType]
  local dir="$PROJ_DIR/$1/subagents"
  mkdir -p "$dir"
  jq -cn --argjson t "$3" \
    '{message:{usage:{input_tokens:2,cache_read_input_tokens:($t-2),cache_creation_input_tokens:0}},isSidechain:true}' \
    > "$dir/agent-$2.jsonl"
  if [ $# -ge 4 ]; then
    jq -cn --arg at "$4" '{agentType:$at,description:"test child",spawnDepth:1}' \
      > "$dir/agent-$2.meta.json"
  fi
}
run_as() {  # $1=claude-session-id, rest = context-budget.sh args
  local sid="$1"; shift
  CLAUDE_CODE_SESSION_ID="$sid" "$CB" "$@" --runtime claude
}

echo "C1: children under WARN — no lines, exit 0, summary counts"
mk_transcript ppp 50000
run_as ppp register --quiet >/dev/null
mk_child ppp aaa111 30000 general-purpose
mk_child ppp bbb222 60000 Explore
out=$(run_as ppp children 2>"$TMP/c1.err"); rc=$?
err=$(cat "$TMP/c1.err")
assert_eq "C1a: exit 0 when all children OK" "$rc" "0"
assert_eq "C1b: no per-child lines below WARN" "$out" ""
assert_contains "C1c: summary counts measured children" "$err" "children: 2 measured, 0 escalated"

echo "C2: one child at WARN — its line prints, exit 1"
mk_child ppp ccc333 125000 general-purpose
out=$(run_as ppp children 2>"$TMP/c2.err"); rc=$?
assert_eq "C2a: exit 1 on WARN child" "$rc" "1"
assert_contains "C2b: WARN child line printed" "$out" "agent=agent-ccc333 tokens=125000"
assert_contains "C2c: line carries status=WARN" "$out" "status=WARN"
assert_not_contains "C2d: OK children stay silent" "$out" "agent=agent-aaa111"
assert_contains "C2e: summary counts escalation" "$(cat "$TMP/c2.err")" "children: 3 measured, 1 escalated"

echo "C3: STOP child among WARN — worst wins, exit 2"
mk_child ppp ddd444 160000 general-purpose
out=$(run_as ppp children 2>/dev/null); rc=$?
assert_eq "C3a: exit 2 when any child at STOP" "$rc" "2"
assert_contains "C3b: STOP child line printed" "$out" "agent=agent-ddd444 tokens=160000"
assert_contains "C3c: line carries status=STOP" "$out" "status=STOP"
assert_contains "C3d: WARN child still printed" "$out" "agent=agent-ccc333"

echo "C4: --all lists OK children too"
out=$(run_as ppp children --all 2>/dev/null)
assert_contains "C4a: OK child listed with --all" "$out" "agent=agent-aaa111 tokens=30000"
assert_contains "C4b: OK line carries status=OK" "$out" "status=OK"

echo "C5: meta.json agentType surfaced; missing meta tolerated"
out=$(run_as ppp children --all 2>/dev/null)
assert_contains "C5a: agentType from meta.json" "$out" "type=Explore"
mk_child ppp eee555 130000            # no meta.json
out=$(run_as ppp children 2>/dev/null)
assert_contains "C5b: missing meta tolerated as type=?" "$out" "agent=agent-eee555 tokens=130000"
assert_contains "C5c: placeholder type" "$out" "type=?"

echo "C6: sidechain-true entries measured exact, not size-estimate"
out=$(run_as ppp children --all 2>/dev/null)
assert_not_contains "C6a: no estimate fallback for children" "$out" "method=estimate"

echo "C7: parent with no subagents dir — exit 0, note"
mk_transcript qqq 40000
run_as qqq register --quiet >/dev/null
out=$(run_as qqq children 2>"$TMP/c7.err"); rc=$?
assert_eq "C7a: exit 0 with no children" "$rc" "0"
assert_eq "C7b: no lines" "$out" ""
assert_contains "C7c: zero summary" "$(cat "$TMP/c7.err")" "children: 0 measured, 0 escalated"

echo "C8: --parent-session sweeps another registered session's children"
out=$(run_as qqq children --parent-session ppp 2>/dev/null); rc=$?
assert_eq "C8a: worst status of ppp's children" "$rc" "2"
assert_contains "C8b: ppp's STOP child reported" "$out" "agent=agent-ddd444"
err=$(run_as qqq children --parent-session nosuch 2>&1 >/dev/null); rc=$?
assert_eq "C8c: unregistered parent dies" "$rc" "3"
assert_contains "C8d: loud error" "$err" "not registered"

echo "C9: non-claude runtime — loud die, exit 3"
err=$(CODEX_THREAD_ID=zzz "$CB" children --runtime codex 2>&1 >/dev/null); rc=$?
assert_eq "C9a: exit 3 for non-claude runtime" "$rc" "3"
assert_contains "C9b: loud claude-only error" "$err" "only implemented for runtime=claude"

echo "results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
