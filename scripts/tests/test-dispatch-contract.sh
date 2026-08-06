#!/usr/bin/env bash
# File: scripts/tests/test-dispatch-contract.sh
# Purpose: Regression tests for the `dispatch-contract` subcommand in
#          context-budget.sh — R2/R3 of the subagent-rollover research
#          (work/automatic-session-rollover, slice 3). Self-contained:
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

PASS=0; FAIL=0
ok()   { PASS=$((PASS+1)); echo "  ok: $1"; }
bad()  { FAIL=$((FAIL+1)); echo "  FAIL: $1" >&2; }
assert_eq() { [ "$2" = "$3" ] && ok "$1" || bad "$1 (want [$3] got [$2])"; }
assert_contains() { case "$2" in *"$3"*) ok "$1" ;; *) bad "$1 (no [$3] in [$2])" ;; esac; }
assert_not_contains() { case "$2" in *"$3"*) bad "$1 (unwanted [$3] in [$2])" ;; *) ok "$1" ;; esac; }

REPORT="work/testproj/task-1-report.md"
BRIEF="work/testproj/task-1-brief.md"

echo "K1: --report emits the contract with all load-bearing clauses"
out=$("$CB" dispatch-contract --report "$REPORT" 2>/dev/null); rc=$?
assert_eq "K1a: exit 0" "$rc" "0"
assert_contains "K1b: report path in contract" "$out" "$REPORT"
assert_contains "K1c: checkpoint-at-boundary clause" "$out" "work-unit boundary"
assert_contains "K1d: progress block appended to report" "$out" "append a progress block"
assert_contains "K1e: return cap clause" "$out" "15 lines"
assert_contains "K1f: status DONE" "$out" "DONE"
assert_contains "K1g: status DONE_WITH_CONCERNS" "$out" "DONE_WITH_CONCERNS"
assert_contains "K1h: status BLOCKED" "$out" "BLOCKED"
assert_contains "K1i: status NEEDS_CONTEXT" "$out" "NEEDS_CONTEXT"
assert_contains "K1j: status ROLLOVER_NEEDED" "$out" "ROLLOVER_NEEDED"
assert_contains "K1k: never from self-assessment (D1)" "$out" "self-assessment"
assert_contains "K1l: checkpoint-request behaviour" "$out" "If asked to checkpoint"

echo "K2: missing --report dies loudly"
err=$("$CB" dispatch-contract 2>&1 >/dev/null); rc=$?
assert_eq "K2a: exit 3 without --report" "$rc" "3"
assert_contains "K2b: error names the missing flag" "$err" "--report"

echo "K3: --brief line present iff given"
out=$("$CB" dispatch-contract --report "$REPORT" --brief "$BRIEF" 2>/dev/null)
assert_contains "K3a: brief path in contract" "$out" "$BRIEF"
out=$("$CB" dispatch-contract --report "$REPORT" 2>/dev/null)
assert_not_contains "K3b: no Brief label without --brief" "$out" "Brief:"

echo "K4: generation clause — default 1, successor adds read-report-first"
out=$("$CB" dispatch-contract --report "$REPORT" 2>/dev/null)
assert_contains "K4a: default generation 1" "$out" "generation 1"
assert_not_contains "K4b: no successor clause at gen 1" "$out" "Read the report file before starting"
out=$("$CB" dispatch-contract --report "$REPORT" --gen 2 2>/dev/null)
assert_contains "K4c: generation 2 labeled" "$out" "generation 2"
assert_contains "K4d: successor reads report first" "$out" "Read the report file before starting"

echo "K5: output is pure ASCII (survives %q / BSD sed launch paths)"
out=$("$CB" dispatch-contract --report "$REPORT" --brief "$BRIEF" --gen 2 2>/dev/null)
nonascii=$(printf '%s' "$out" | LC_ALL=C tr -d '\11\12\15\40-\176')
assert_eq "K5a: no non-ASCII bytes" "$nonascii" ""

echo "K6: stateless and runtime-agnostic — no session, non-claude runtime"
out=$("$CB" dispatch-contract --report "$REPORT" --runtime codex 2>/dev/null); rc=$?
assert_eq "K6a: exit 0 with no registered session, runtime=codex" "$rc" "0"
assert_contains "K6b: contract still emitted" "$out" "$REPORT"

echo "K7: usage header lists dispatch-contract"
hdr=$(head -15 "$CB")
assert_contains "K7a: dispatch-contract in usage" "$hdr" "dispatch-contract"

echo "results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
