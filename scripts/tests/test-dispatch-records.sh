#!/usr/bin/env bash
# File: scripts/tests/test-dispatch-records.sh
# Purpose: Regression tests for the dispatch-record subcommands in
#          context-budget.sh (dispatch-open / dispatch-close / dispatch-list)
#          — R4 of the subagent-rollover research (parent-persisted dispatch
#          records + generation fencing). Self-contained: builds a throwaway
#          workspace + fake $HOME in mktemp -d.
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

PASS=0; FAIL=0
ok()   { PASS=$((PASS+1)); echo "  ok: $1"; }
bad()  { FAIL=$((FAIL+1)); echo "  FAIL: $1" >&2; }
assert_eq() { [ "$2" = "$3" ] && ok "$1" || bad "$1 (want [$3] got [$2])"; }
assert_contains() { case "$2" in *"$3"*) ok "$1" ;; *) bad "$1 (no [$3] in [$2])" ;; esac; }
assert_not_contains() { case "$2" in *"$3"*) bad "$1 (unwanted [$3] in [$2])" ;; *) ok "$1" ;; esac; }

REPORT="work/testproj/task-1-report.md"
BRIEF="work/testproj/task-1-brief.md"
REC="work/testproj/.agent-dispatch/task-1.json"

echo "L1: dispatch-open creates gen-1 record and emits the contract"
out=$("$CB" dispatch-open --project testproj --task task-1 --report "$REPORT" \
  --brief "$BRIEF" --agent-type general-purpose --model sonnet --effort low \
  2>/dev/null); rc=$?
assert_eq "L1a: exit 0" "$rc" "0"
assert_contains "L1b: contract labels generation 1" "$out" "generation 1"
assert_contains "L1c: report path in contract" "$out" "$REPORT"
[ -f "$REC" ] && ok "L1d: record file created" || bad "L1d: record file created"
assert_eq "L1e: one generation" "$(jq -r '.generations | length' "$REC")" "1"
assert_eq "L1f: gen 1 open" "$(jq -r '.generations[0].status' "$REC")" "open"
assert_eq "L1g: report persisted" "$(jq -r '.report' "$REC")" "$REPORT"
assert_eq "L1h: brief persisted" "$(jq -r '.brief' "$REC")" "$BRIEF"
assert_eq "L1i: agent-type persisted" "$(jq -r '.agent_type' "$REC")" "general-purpose"
assert_eq "L1j: model persisted" "$(jq -r '.model' "$REC")" "sonnet"
assert_eq "L1k: effort persisted" "$(jq -r '.effort' "$REC")" "low"
ts=$(jq -r '.generations[0].dispatched_at' "$REC")
[ -n "$ts" ] && [ "$ts" != "null" ] && ok "L1l: dispatched_at stamped" \
  || bad "L1l: dispatched_at stamped"

echo "L2: required flags enforced; --gen rejected"
err=$("$CB" dispatch-open --task t --report r 2>&1 >/dev/null); rc=$?
assert_eq "L2a: no --project dies 3" "$rc" "3"
err=$("$CB" dispatch-open --project testproj --report r 2>&1 >/dev/null); rc=$?
assert_eq "L2b: no --task dies 3" "$rc" "3"
assert_contains "L2c: error names --task" "$err" "--task"
err=$("$CB" dispatch-open --project testproj --task t 2>&1 >/dev/null); rc=$?
assert_eq "L2d: no --report dies 3" "$rc" "3"
err=$("$CB" dispatch-open --project testproj --task t --report r --gen 2 \
  2>&1 >/dev/null); rc=$?
assert_eq "L2e: --gen dies 3" "$rc" "3"
assert_contains "L2f: error says gen is computed" "$err" "computed"
err=$("$CB" dispatch-open --project nosuch --task t --report r 2>&1 >/dev/null); rc=$?
assert_eq "L2g: unknown work dir dies 3" "$rc" "3"

echo "L3: generation fencing — open refuses while a generation is open"
err=$("$CB" dispatch-open --project testproj --task task-1 --report "$REPORT" \
  2>&1 >/dev/null); rc=$?
assert_eq "L3a: second open dies 3" "$rc" "3"
assert_contains "L3b: error names the open generation" "$err" "open"
assert_eq "L3c: record unchanged" "$(jq -r '.generations | length' "$REC")" "1"

echo "L4: close then reopen — gen 2 with successor clause"
err=$("$CB" dispatch-close --project testproj --task task-1 --status DONE \
  2>&1 >/dev/null); rc=$?
assert_eq "L4a: close exits 0" "$rc" "0"
assert_eq "L4b: gen 1 status DONE" "$(jq -r '.generations[0].status' "$REC")" "DONE"
ts=$(jq -r '.generations[0].closed_at' "$REC")
[ -n "$ts" ] && [ "$ts" != "null" ] && ok "L4c: closed_at stamped" \
  || bad "L4c: closed_at stamped"
out=$("$CB" dispatch-open --project testproj --task task-1 --report "$REPORT" \
  2>/dev/null); rc=$?
assert_eq "L4d: reopen exits 0" "$rc" "0"
assert_contains "L4e: contract labels generation 2" "$out" "generation 2"
assert_contains "L4f: successor reads report first" "$out" \
  "Read the report file before starting"
assert_eq "L4g: two generations" "$(jq -r '.generations | length' "$REC")" "2"
assert_eq "L4h: gen 2 open" "$(jq -r '.generations[1].status' "$REC")" "open"

echo "L5: close validation + agent-id merge"
err=$("$CB" dispatch-close --project testproj --task task-1 --status NOPE \
  2>&1 >/dev/null); rc=$?
assert_eq "L5a: invalid status dies 3" "$rc" "3"
err=$("$CB" dispatch-close --project testproj --task task-1 2>&1 >/dev/null); rc=$?
assert_eq "L5b: missing status dies 3" "$rc" "3"
"$CB" dispatch-close --project testproj --task task-1 --status KILLED \
  --agent-id agent-abc123 >/dev/null 2>&1
assert_eq "L5c: KILLED accepted" "$(jq -r '.generations[1].status' "$REC")" "KILLED"
assert_eq "L5d: agent-id merged" "$(jq -r '.generations[1].agent_id' "$REC")" "agent-abc123"
err=$("$CB" dispatch-close --project testproj --task task-1 --status DONE \
  2>&1 >/dev/null); rc=$?
assert_eq "L5e: close with nothing open dies 3" "$rc" "3"
err=$("$CB" dispatch-close --project testproj --task nosuch --status DONE \
  2>&1 >/dev/null); rc=$?
assert_eq "L5f: close on unknown task dies 3" "$rc" "3"

echo "L6: dispatch-list — per-task lines, exit 1 iff any generation open"
"$CB" dispatch-open --project testproj --task task-2 --report \
  work/testproj/task-2-report.md >/dev/null 2>&1
out=$("$CB" dispatch-list --project testproj 2>/dev/null); rc=$?
assert_eq "L6a: exit 1 with an open generation" "$rc" "1"
assert_contains "L6b: task-1 line" "$out" "task=task-1"
assert_contains "L6c: task-1 shows last status" "$out" "status=KILLED"
assert_contains "L6d: task-2 open" "$out" "status=open"
assert_contains "L6e: gen counter shown" "$out" "gen=2"
assert_contains "L6f: report path shown" "$out" "report=work/testproj/task-2-report.md"
"$CB" dispatch-close --project testproj --task task-2 --status DONE >/dev/null 2>&1
out=$("$CB" dispatch-list --project testproj 2>/dev/null); rc=$?
assert_eq "L6g: exit 0 when all closed" "$rc" "0"
out=$("$CB" dispatch-list --project emptyproj 2>&1); rc=$?
[ "$rc" = "3" ] && ok "L6h: unknown work dir dies 3" || bad "L6h: unknown work dir dies 3 (got $rc)"

echo "L7: contract carries the generation-label clause, pure ASCII"
out=$("$CB" dispatch-contract --report "$REPORT" 2>/dev/null)
assert_contains "L7a: generation-label clause" "$out" "[gen"
nonascii=$(printf '%s' "$out" | LC_ALL=C grep -c '[^ -~\t]' || true)
assert_eq "L7b: pure ASCII" "$nonascii" "0"
out=$("$CB" dispatch-open --project testproj --task task-3 --report \
  work/testproj/task-3-report.md 2>/dev/null)
assert_contains "L7c: open emits the same clause" "$out" "[gen"

echo "L8: records live under the workspace root's .agent-dispatch"
[ -f "$TMP/work/testproj/.agent-dispatch/task-2.json" ] \
  && ok "L8a: record under work/<proj>/.agent-dispatch/" \
  || bad "L8a: record under work/<proj>/.agent-dispatch/"

echo "L9: usage header lists the dispatch-record subcommands"
head=$(head -20 "$CB")
assert_contains "L9a: dispatch-open in usage" "$head" "dispatch-open"
assert_contains "L9b: dispatch-close in usage" "$head" "dispatch-close"
assert_contains "L9c: dispatch-list in usage" "$head" "dispatch-list"

echo
echo "passed=$PASS failed=$FAIL"
[ "$FAIL" -eq 0 ]
