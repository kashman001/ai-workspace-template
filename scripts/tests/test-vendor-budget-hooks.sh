#!/usr/bin/env bash
# File: scripts/tests/test-vendor-budget-hooks.sh
# Purpose: Regression tests for the context-budget vendor hook wrappers and
#          their shared lib (ADR-0003/0004 item #3). Self-contained: throwaway
#          workspace in mktemp -d, stub context-budget.sh driven by FAKE_* env.
set -u
SRC_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/scripts/hooks" "$TMP/.context-budget"
cp "$SRC_ROOT"/scripts/hooks/context-budget-*.sh "$TMP/scripts/hooks/" 2>/dev/null || true
cat > "$TMP/scripts/context-budget.sh" <<'STUB'
#!/usr/bin/env bash
[ "${1:-}" = "check" ] || exit 0
st="${FAKE_STATUS:-OK}"; tk="${FAKE_TOKENS:-1000}"
echo "runtime=stub method=exact tokens=$tk threshold=150000 warn=120000 pct=1 status=$st artifact=/dev/null"
case "$st" in OK) exit 0 ;; WARN) exit 1 ;; STOP) exit 2 ;; esac
STUB
chmod +x "$TMP/scripts/context-budget.sh"
touch "$TMP/fake-transcript"
cd "$TMP"
HOOKS="$TMP/scripts/hooks"

PASS=0; FAIL=0
ok()  { PASS=$((PASS+1)); echo "  ok: $1"; }
bad() { FAIL=$((FAIL+1)); echo "  FAIL: $1" >&2; }
assert_eq() { [ "$2" = "$3" ] && ok "$1" || bad "$1 (want [$3] got [$2])"; }
assert_contains() { case "$2" in *"$3"*) ok "$1" ;; *) bad "$1 (no [$3] in [$2])" ;; esac; }
assert_empty() { [ -z "$2" ] && ok "$1" || bad "$1 (expected empty, got [$2])"; }
reset_state() { rm -f "$TMP/.context-budget"/hook-*; }
# Each lib call in a fresh subshell so sourcing is isolated.
libcheck() { ( . "$HOOKS/context-budget-hook-lib.sh"; budget_hook_check "$@" ); }

echo "T1: lib escalation-only semantics"
reset_state
out=$(CHECK_EVERY=0 FAKE_STATUS=OK libcheck claude s1); assert_empty "T1a: OK silent" "$out"
out=$(CHECK_EVERY=0 FAKE_STATUS=WARN FAKE_TOKENS=125000 libcheck claude s1)
assert_eq "T1b: OK->WARN speaks" "$out" "WARN 125000 150000"
out=$(CHECK_EVERY=0 FAKE_STATUS=WARN FAKE_TOKENS=126000 libcheck claude s1)
assert_empty "T1c: WARN->WARN silent" "$out"
out=$(CHECK_EVERY=0 FAKE_STATUS=STOP FAKE_TOKENS=151000 libcheck claude s1)
assert_eq "T1d: WARN->STOP speaks" "$out" "STOP 151000 150000"
out=$(CHECK_EVERY=0 FAKE_STATUS=WARN FAKE_TOKENS=126000 libcheck claude s1)
assert_empty "T1e: STOP->WARN silent (never de-escalates loudly)" "$out"

echo "T2: lib throttle"
reset_state
out=$(CHECK_EVERY=9999 FAKE_STATUS=WARN FAKE_TOKENS=125000 libcheck claude s2)
assert_eq "T2a: first call runs" "$out" "WARN 125000 150000"
out=$(CHECK_EVERY=9999 FAKE_STATUS=STOP FAKE_TOKENS=151000 libcheck claude s2)
assert_empty "T2b: second call inside window is throttled" "$out"

echo "T3: lib fail-open"
reset_state
chmod -x "$TMP/scripts/context-budget.sh"
out=$(CHECK_EVERY=0 FAKE_STATUS=WARN libcheck claude s3); rc=$?
assert_eq "T3a: broken check script -> rc 0" "$rc" "0"
assert_empty "T3b: broken check script -> silent" "$out"
chmod +x "$TMP/scripts/context-budget.sh"

echo "T4: claude wrapper envelope preserved"
reset_state
payload="{\"session_id\":\"s4\",\"transcript_path\":\"$TMP/fake-transcript\"}"
err=$(echo "$payload" | CHECK_EVERY=0 FAKE_STATUS=WARN FAKE_TOKENS=125000 \
      "$HOOKS/context-budget-claude-hook.sh" 2>&1 >/dev/null); rc=$?
assert_eq "T4a: WARN exits 2" "$rc" "2"
assert_contains "T4b: WARN text on stderr" "$err" "CONTEXT BUDGET WARN: this session is at 125000 tokens"
reset_state
err=$(echo "$payload" | CHECK_EVERY=0 FAKE_STATUS=OK \
      "$HOOKS/context-budget-claude-hook.sh" 2>&1 >/dev/null); rc=$?
assert_eq "T4c: OK exits 0" "$rc" "0"
assert_empty "T4d: OK silent" "$err"

echo; echo "pass=$PASS fail=$FAIL"; [ "$FAIL" -eq 0 ]
