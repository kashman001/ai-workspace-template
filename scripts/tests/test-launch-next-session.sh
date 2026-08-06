#!/usr/bin/env bash
# File: scripts/tests/test-launch-next-session.sh
# Purpose: Regression tests for launch-next-session.sh (ADR-0003/0004 item #2).
#          Self-contained: throwaway workspace in mktemp -d; --dry-run for flag
#          assembly, stub binaries on PATH for the real-launch path.
set -u
SRC_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/scripts" "$TMP/work/testproj" "$TMP/.context-budget/sessions" "$TMP/bin"
cp "$SRC_ROOT/scripts/launch-next-session.sh" "$TMP/scripts/" 2>/dev/null || true
printf 'ROLLOVER_RELAUNCH=manual\nROLLOVER_RUNTIME=claude\n' > "$TMP/context-budget.env"
echo "# launcher" > "$TMP/work/testproj/next-session.md"
cd "$TMP"
LNS="$TMP/scripts/launch-next-session.sh"
SESS="$TMP/.context-budget/sessions"

PASS=0; FAIL=0
ok()   { PASS=$((PASS+1)); echo "  ok: $1"; }
bad()  { FAIL=$((FAIL+1)); echo "  FAIL: $1" >&2; }
assert_eq() { [ "$2" = "$3" ] && ok "$1" || bad "$1 (want [$3] got [$2])"; }
assert_contains() { case "$2" in *"$3"*) ok "$1" ;; *) bad "$1 (no [$3] in [$2])" ;; esac; }
assert_not_contains() { case "$2" in *"$3"*) bad "$1 (unexpected [$3])" ;; *) ok "$1" ;; esac; }

mk_record() {  # $1=runtime $2=session-id $3=project
  jq -n --arg rt "$1" --arg sid "$2" --arg p "$3" \
    '{runtime:$rt, session_id:$sid, artifact:"/dev/null", project:$p, registered_at:"2026-08-05T00:00:00Z"}' \
    > "$SESS/$1-$2.json"
}
# All runtime-identity env vars cleared per call unless a test sets one.
run_lns() { env -u CLAUDE_CODE_SESSION_ID -u CODEX_THREAD_ID \
  -u COPILOT_AGENT_SESSION_ID -u VSCODE_TARGET_SESSION_LOG \
  -u ROLLOVER_RELAUNCH -u ROLLOVER_RUNTIME "$@"; }

PROMPT='Read `work/testproj/next-session.md` and continue from **First actions**.'

echo "T1: own registry record via CLAUDE_CODE_SESSION_ID resolves runtime=claude"
mk_record claude sid-aaa testproj
out=$(run_lns CLAUDE_CODE_SESSION_ID=sid-aaa "$LNS" testproj --dry-run 2>&1)
assert_contains "T1a: runtime resolved" "$out" "runtime=claude"
assert_contains "T1b: claude argv"      "$out" "cmd: claude"
assert_contains "T1c: verbatim prompt"  "$out" "continue from **First actions**"

echo "T2: codex identity resolves codex argv (positional prompt)"
mk_record codex th-bbb testproj
out=$(run_lns CODEX_THREAD_ID=th-bbb "$LNS" testproj --dry-run 2>&1)
assert_contains "T2a: runtime resolved" "$out" "runtime=codex"
assert_contains "T2b: codex argv"       "$out" "cmd: codex"

echo "T3: no env identity — newest record with matching project wins"
rm -f "$SESS"/*.json; mk_record gemini workspace testproj
out=$(run_lns "$LNS" testproj --dry-run 2>&1)
assert_contains "T3a: runtime from project record" "$out" "runtime=gemini"
assert_contains "T3b: gemini -i argv"              "$out" "cmd: gemini -i"

echo "T4: no records at all — ROLLOVER_RUNTIME fallback"
rm -f "$SESS"/*.json
out=$(env -u CLAUDE_CODE_SESSION_ID -u CODEX_THREAD_ID -u COPILOT_AGENT_SESSION_ID \
  -u VSCODE_TARGET_SESSION_LOG ROLLOVER_RELAUNCH=manual ROLLOVER_RUNTIME=opencode \
  "$LNS" testproj --dry-run 2>&1)
assert_contains "T4a: fallback runtime"    "$out" "runtime=opencode"
assert_contains "T4b: opencode argv"       "$out" "cmd: opencode --prompt"

echo "T5: --runtime flag overrides everything"
mk_record claude sid-ccc testproj
out=$(run_lns CLAUDE_CODE_SESSION_ID=sid-ccc "$LNS" testproj --runtime copilot --dry-run 2>&1)
assert_contains "T5a: flag wins"    "$out" "runtime=copilot"
assert_contains "T5b: copilot argv" "$out" "cmd: copilot -i"

echo "T6: bootstrap prompt is exact and verbatim"
out=$(run_lns "$LNS" testproj --runtime claude --dry-run 2>&1)
assert_contains "T6a: exact prompt text" "$out" "$PROMPT"

echo "T7: ROLLOVER_RELAUNCH=off prints prompt, launches nothing"
out=$(env ROLLOVER_RELAUNCH=off "$LNS" testproj --runtime claude --dry-run 2>&1)
assert_contains     "T7a: mode off"     "$out" "mode=off"
assert_contains     "T7b: prompt shown" "$out" "$PROMPT"
assert_not_contains "T7c: no cmd line"  "$out" "cmd: claude"

echo "T8: --bg on a non-claude runtime is an error (exit 3)"
out=$(run_lns "$LNS" testproj --runtime codex --bg --dry-run 2>&1); rc=$?
assert_eq       "T8a: exit 3"        "$rc" "3"
assert_contains "T8b: claude-only"   "$out" "claude-only"

echo "T9: missing next-session.md is an error (exit 3)"
out=$(run_lns "$LNS" nosuchproj --runtime claude --dry-run 2>&1); rc=$?
assert_eq       "T9a: exit 3"          "$rc" "3"
assert_contains "T9b: names the file"  "$out" "next-session.md"

echo "T10: ROLLOVER_RELAUNCH=auto + claude implies --bg"
out=$(env ROLLOVER_RELAUNCH=auto "$LNS" testproj --runtime claude --dry-run 2>&1)
assert_contains "T10a: bg=1"          "$out" "bg=1"
assert_contains "T10b: --bg in argv"  "$out" "cmd: claude --bg"

echo "T11: --bg launch with stub claude; successor registers -> confirmed"
rm -f "$SESS"/*.json; mk_record claude sid-old testproj
cat > "$TMP/bin/claude" <<STUB
#!/usr/bin/env bash
# Stub: pretend the successor session booted and registered (D8 heartbeat).
jq -n '{runtime:"claude", session_id:"sid-new", artifact:"/dev/null",
        project:"testproj", registered_at:"2026-08-05T00:00:01Z"}' \
  > "$SESS/claude-sid-new.json"
STUB
chmod +x "$TMP/bin/claude"
out=$(PATH="$TMP/bin:$PATH" ROLLOVER_CONFIRM_SECS=10 \
  run_lns CLAUDE_CODE_SESSION_ID=sid-old "$LNS" testproj --bg 2>&1); rc=$?
assert_eq       "T11a: exit 0"      "$rc" "0"
assert_contains "T11b: confirmed"   "$out" "successor=confirmed session=sid-new"

echo "T12: --bg launch, successor never registers -> unconfirmed (non-fatal)"
rm -f "$SESS"/*.json; mk_record claude sid-old testproj
cat > "$TMP/bin/claude" <<'STUB'
#!/usr/bin/env bash
exit 0
STUB
chmod +x "$TMP/bin/claude"
out=$(PATH="$TMP/bin:$PATH" ROLLOVER_CONFIRM_SECS=3 \
  run_lns CLAUDE_CODE_SESSION_ID=sid-old "$LNS" testproj --bg 2>&1); rc=$?
assert_eq       "T12a: exit 0 still" "$rc" "0"
assert_contains "T12b: unconfirmed"  "$out" "successor=unconfirmed"

echo "T13: manual mode without a tty prints the ready-to-run command, execs nothing"
rm -f "$SESS"/*.json
cat > "$TMP/bin/gemini" <<'STUB'
#!/usr/bin/env bash
echo "GEMINI_EXECUTED"; exit 0
STUB
chmod +x "$TMP/bin/gemini"
out=$(PATH="$TMP/bin:$PATH" run_lns "$LNS" testproj --runtime gemini </dev/null 2>&1); rc=$?
assert_eq           "T13a: exit 0"          "$rc" "0"
assert_contains     "T13b: run: line"       "$out" "run: gemini -i"
assert_not_contains "T13c: not executed"    "$out" "GEMINI_EXECUTED"

echo "T14: option inheritance from .rollover-options"
cat > "$TMP/work/testproj/.rollover-options" <<'EOF'
ROLLOVER_OPT_APPROVAL=auto
ROLLOVER_OPT_MODEL=claude-sonnet-5
EOF
mk_record claude sid-opt testproj
out=$(run_lns CLAUDE_CODE_SESSION_ID=sid-opt "$LNS" testproj --dry-run 2>&1)
assert_contains "T14a: claude approval flag" "$out" "--permission-mode acceptEdits"
assert_contains "T14b: claude model flag" "$out" "--model claude-sonnet-5"
out=$(run_lns "$LNS" testproj --runtime codex --dry-run 2>&1)
assert_contains "T14c: codex auto maps to --ask-for-approval never" "$out" "--ask-for-approval never"
out=$(run_lns "$LNS" testproj --runtime gemini --dry-run 2>&1)
assert_contains "T14d: gemini auto maps to --approval-mode auto_edit" "$out" "--approval-mode auto_edit"
out=$(run_lns "$LNS" testproj --runtime copilot --dry-run 2>&1)
assert_contains "T14e: copilot auto maps to --allow-all-tools" "$out" "--allow-all-tools"
printf 'ROLLOVER_OPT_APPROVAL=full\n' > "$TMP/work/testproj/.rollover-options"
out=$(run_lns "$LNS" testproj --runtime codex --dry-run 2>&1)
assert_contains "T14f: codex full maps to bypass flag" "$out" "--dangerously-bypass-approvals-and-sandbox"
printf 'ROLLOVER_OPT_APPROVAL=bogus\n' > "$TMP/work/testproj/.rollover-options"
out=$(run_lns "$LNS" testproj --runtime codex --dry-run 2>&1)
assert_contains "T14g: unknown approval warned" "$out" "unknown ROLLOVER_OPT_APPROVAL"
assert_not_contains "T14h: unknown approval adds no flags" "$out" "--ask-for-approval never"
rm -f "$TMP/work/testproj/.rollover-options"
out=$(run_lns "$LNS" testproj --runtime codex --dry-run 2>&1)
assert_not_contains "T14i: absent file -> unchanged argv" "$out" "--ask-for-approval never"
printf 'ROLLOVER_OPT_EXTRA="--add-dir /somewhere"\n' > "$TMP/work/testproj/.rollover-options"
out=$(run_lns "$LNS" testproj --runtime claude --dry-run 2>&1)
assert_contains "T14j: raw extra args pass through" "$out" "--add-dir /somewhere"
rm -f "$TMP/work/testproj/.rollover-options"

echo; echo "passed=$PASS failed=$FAIL"
[ "$FAIL" -eq 0 ]
