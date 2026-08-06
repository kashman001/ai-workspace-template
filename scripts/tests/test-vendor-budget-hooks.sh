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

echo "T7: opencode wrapper plain-text output"
reset_state
out=$(CHECK_EVERY=0 FAKE_STATUS=WARN FAKE_TOKENS=125000 \
      "$HOOKS/context-budget-opencode-hook.sh" ses_x); rc=$?
assert_eq "T7a: exit 0" "$rc" "0"
assert_contains "T7b: WARN text" "$out" "CONTEXT BUDGET WARN: this session is at 125000 tokens"
reset_state
out=$(CHECK_EVERY=0 FAKE_STATUS=OK "$HOOKS/context-budget-opencode-hook.sh" ses_x)
assert_empty "T7c: OK silent" "$out"
out=$(CHECK_EVERY=0 FAKE_STATUS=WARN "$HOOKS/context-budget-opencode-hook.sh")
assert_empty "T7d: missing sessionID -> silent fail-open" "$out"

echo "T8: copilot wrapper — additionalContext at start, block only at STOP"
reset_state
mkdir -p "$TMP/copilot-state/s8"; touch "$TMP/copilot-state/s8/events.jsonl"
start_payload='{"sessionId":"s8","cwd":"/x","source":"resume"}'
out=$(echo "$start_payload" | CHECK_EVERY=0 FAKE_STATUS=WARN FAKE_TOKENS=125000 \
      COPILOT_STATE_DIR="$TMP/copilot-state" "$HOOKS/context-budget-copilot-hook.sh" sessionStart)
assert_contains "T8a: sessionStart WARN -> additionalContext" \
  "$(echo "$out" | jq -r '.additionalContext')" "CONTEXT BUDGET WARN"
reset_state
stop_payload="{\"sessionId\":\"s8\",\"transcriptPath\":\"$TMP/fake-transcript\",\"stopReason\":\"end_turn\",\"stop_hook_active\":false}"
out=$(echo "$stop_payload" | CHECK_EVERY=0 FAKE_STATUS=WARN FAKE_TOKENS=125000 \
      "$HOOKS/context-budget-copilot-hook.sh" agentStop)
assert_empty "T8b: agentStop WARN -> silent (block only at STOP)" "$out"
out=$(echo "$stop_payload" | CHECK_EVERY=0 FAKE_STATUS=STOP FAKE_TOKENS=151000 \
      "$HOOKS/context-budget-copilot-hook.sh" agentStop)
assert_eq "T8c: agentStop STOP -> block" "$(echo "$out" | jq -r '.decision')" "block"
assert_contains "T8d: reason carries STOP text" "$(echo "$out" | jq -r '.reason')" "CONTEXT BUDGET STOP"
active_payload="{\"sessionId\":\"s8\",\"transcriptPath\":\"$TMP/fake-transcript\",\"stopReason\":\"end_turn\",\"stop_hook_active\":true}"
reset_state
out=$(echo "$active_payload" | CHECK_EVERY=0 FAKE_STATUS=STOP FAKE_TOKENS=151000 \
      "$HOOKS/context-budget-copilot-hook.sh" agentStop)
assert_empty "T8e: stop_hook_active -> never re-block" "$out"

echo "T11: copilot-vscode wrapper — additionalContext at start, exit-2 block only at STOP"
reset_state
WS="$TMP/vscode-ws/User/workspaceStorage/hash1"
mkdir -p "$WS/GitHub.copilot-chat/transcripts" "$WS/chatSessions"
touch "$WS/GitHub.copilot-chat/transcripts/s11.jsonl" "$WS/chatSessions/s11.jsonl"
vs_payload="{\"session_id\":\"s11\",\"transcript_path\":\"$WS/GitHub.copilot-chat/transcripts/s11.jsonl\",\"cwd\":\"/x\"}"
out=$(echo "$vs_payload" | CHECK_EVERY=0 FAKE_STATUS=WARN FAKE_TOKENS=125000 \
      "$HOOKS/context-budget-copilot-vscode-hook.sh" SessionStart); rc=$?
assert_eq "T11a: SessionStart WARN exits 0" "$rc" "0"
assert_contains "T11b: WARN in hookSpecificOutput.additionalContext" \
  "$(echo "$out" | jq -r '.hookSpecificOutput.additionalContext')" "CONTEXT BUDGET WARN"
reset_state
out=$(echo "$vs_payload" | CHECK_EVERY=0 FAKE_STATUS=WARN FAKE_TOKENS=125000 \
      "$HOOKS/context-budget-copilot-vscode-hook.sh" Stop 2>&1); rc=$?
assert_eq "T11c: Stop WARN -> exit 0 (block only at STOP)" "$rc" "0"
assert_empty "T11d: Stop WARN silent" "$out"
reset_state
err=$(echo "$vs_payload" | CHECK_EVERY=0 FAKE_STATUS=STOP FAKE_TOKENS=151000 \
      "$HOOKS/context-budget-copilot-vscode-hook.sh" Stop 2>&1 >/dev/null); rc=$?
assert_eq "T11e: Stop STOP -> exit 2" "$rc" "2"
assert_contains "T11f: STOP text on stderr" "$err" "CONTEXT BUDGET STOP: this session is at 151000 tokens"
vs_active="{\"session_id\":\"s11\",\"transcript_path\":\"$WS/GitHub.copilot-chat/transcripts/s11.jsonl\",\"stop_hook_active\":true}"
reset_state
out=$(echo "$vs_active" | CHECK_EVERY=0 FAKE_STATUS=STOP FAKE_TOKENS=151000 \
      "$HOOKS/context-budget-copilot-vscode-hook.sh" Stop 2>&1); rc=$?
assert_eq "T11g: stop_hook_active -> exit 0 (never re-block)" "$rc" "0"
assert_empty "T11h: stop_hook_active silent" "$out"
cli_payload="{\"sessionId\":\"s11\",\"transcript_path\":\"$WS/GitHub.copilot-chat/transcripts/s11.jsonl\"}"
reset_state
out=$(echo "$cli_payload" | CHECK_EVERY=0 FAKE_STATUS=STOP FAKE_TOKENS=151000 \
      "$HOOKS/context-budget-copilot-vscode-hook.sh" Stop 2>&1); rc=$?
assert_eq "T11i: camelCase (Copilot CLI) payload -> exit 0" "$rc" "0"
assert_empty "T11j: camelCase payload silent" "$out"
vs_fresh="{\"session_id\":\"s12\",\"transcript_path\":\"$WS/GitHub.copilot-chat/transcripts/s12.jsonl\"}"
touch "$WS/GitHub.copilot-chat/transcripts/s12.jsonl"
reset_state
out=$(echo "$vs_fresh" | CHECK_EVERY=0 FAKE_STATUS=STOP FAKE_TOKENS=151000 \
      "$HOOKS/context-budget-copilot-vscode-hook.sh" SessionStart 2>&1); rc=$?
assert_eq "T11k: missing chatSessions file -> exit 0 (fail-open)" "$rc" "0"
assert_empty "T11l: missing chatSessions file silent" "$out"

echo; echo "pass=$PASS fail=$FAIL"; [ "$FAIL" -eq 0 ]
