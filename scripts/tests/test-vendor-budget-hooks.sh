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

echo "T5: codex wrapper JSON envelope"
reset_state
payload="{\"session_id\":\"s5\",\"transcript_path\":\"$TMP/fake-transcript\"}"
out=$(echo "$payload" | CHECK_EVERY=0 FAKE_STATUS=WARN FAKE_TOKENS=125000 \
      "$HOOKS/context-budget-codex-hook.sh"); rc=$?
assert_eq "T5a: exit 0" "$rc" "0"
ctx=$(echo "$out" | jq -r '.hookSpecificOutput.additionalContext')
assert_contains "T5b: additionalContext carries WARN text" "$ctx" "CONTEXT BUDGET WARN"
assert_eq "T5c: hookEventName" "$(echo "$out" | jq -r '.hookSpecificOutput.hookEventName')" "UserPromptSubmit"
reset_state
out=$(echo "$payload" | CHECK_EVERY=0 FAKE_STATUS=OK "$HOOKS/context-budget-codex-hook.sh")
assert_empty "T5d: OK silent" "$out"

echo "T9: opencode runtime measurement (real script, fake sqlite db)"
if command -v sqlite3 >/dev/null 2>&1; then
  OTMP="$(mktemp -d)"
  mkdir -p "$OTMP/scripts" "$OTMP/.context-budget/sessions"
  cp "$SRC_ROOT/scripts/context-budget.sh" "$OTMP/scripts/"
  cp "$SRC_ROOT/context-budget.env" "$OTMP/" 2>/dev/null || true
  DB="$OTMP/opencode.db"
  sqlite3 "$DB" <<'SQL'
CREATE TABLE session (id text PRIMARY KEY, directory text, time_updated integer,
  tokens_input integer DEFAULT 0, tokens_output integer DEFAULT 0,
  tokens_reasoning integer DEFAULT 0, tokens_cache_read integer DEFAULT 0);
CREATE TABLE message (id text PRIMARY KEY, session_id text, data text);
INSERT INTO session VALUES ('ses_test','/tmp',0,128,9,31,12416);
INSERT INTO message VALUES ('msg_1','ses_test',
  '{"role":"assistant","tokens":{"total":12584,"input":128,"output":9,"reasoning":31,"cache":{"write":0,"read":12416}}}');
INSERT INTO message VALUES ('msg_2','ses_other',
  '{"role":"assistant","tokens":{"total":999999}}');
SQL
  out=$(cd "$OTMP" && OPENCODE_SESSION_ID=ses_test \
        ./scripts/context-budget.sh check --runtime opencode --transcript "$DB" 2>&1); rc=$?
  assert_contains "T9a: exact token count from message.data" "$out" "tokens=12584"
  assert_contains "T9b: method exact" "$out" "method=exact"
  assert_eq "T9c: OK exit code" "$rc" "0"
  out=$(cd "$OTMP" && OPENCODE_SESSION_ID=ses_missing \
        ./scripts/context-budget.sh check --runtime opencode --transcript "$DB" 2>&1); rc=$?
  [ "$rc" -ne 0 ] && [ "$rc" -ne 1 ] && [ "$rc" -ne 2 ] \
    && ok "T9d: unknown session -> error exit" || bad "T9d: unknown session -> error exit (rc=$rc)"
  rm -rf "$OTMP"
else
  echo "  skip: sqlite3 not available"
fi

echo "T6: gemini wrapper JSON-only stdout"
reset_state
out=$(echo '{"session_id":"s6"}' | CHECK_EVERY=0 FAKE_STATUS=OK "$HOOKS/context-budget-gemini-hook.sh"); rc=$?
assert_eq "T6a: silent case prints {}" "$out" "{}"
assert_eq "T6b: exit 0" "$rc" "0"
reset_state
out=$(echo '{"session_id":"s6"}' | CHECK_EVERY=0 FAKE_STATUS=STOP FAKE_TOKENS=151000 \
      "$HOOKS/context-budget-gemini-hook.sh")
echo "$out" | jq -e . >/dev/null 2>&1 && ok "T6c: stdout is valid JSON" || bad "T6c: stdout is valid JSON"
assert_contains "T6d: STOP text present" "$(echo "$out" | jq -r '.hookSpecificOutput.additionalContext')" "CONTEXT BUDGET STOP"

echo "T10: repo .gemini/settings.json carries both hooks"
S="$SRC_ROOT/.gemini/settings.json"
assert_contains "T10a: graphify BeforeTool preserved" "$(jq -r '.hooks.BeforeTool[0].hooks[0].command' "$S")" "graphify"
assert_contains "T10b: BeforeAgent budget hook wired" "$(jq -r '.hooks.BeforeAgent[0].hooks[0].command' "$S")" "context-budget-gemini-hook.sh"
assert_eq "T10c: telemetry block intact" "$(jq -r '.telemetry.enabled' "$S")" "true"

echo; echo "pass=$PASS fail=$FAIL"; [ "$FAIL" -eq 0 ]
