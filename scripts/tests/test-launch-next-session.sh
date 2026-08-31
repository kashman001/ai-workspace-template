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
# CONTEXT_LOCK_STALE_SECS is scrubbed too: a developer shell exporting a small
# value would make the live-holder fixtures (G1/G5/G9/G10) spuriously red.
run_lns() { env -u CLAUDE_CODE_SESSION_ID -u CODEX_THREAD_ID \
  -u COPILOT_AGENT_SESSION_ID -u VSCODE_TARGET_SESSION_LOG \
  -u ROLLOVER_RELAUNCH -u ROLLOVER_RUNTIME -u CONTEXT_LOCK_STALE_SECS "$@"; }

PROMPT='Work item testproj - rollover session #2. Read `work/testproj/next-session.md` and continue from **First actions**.'

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
assert_contains "T10b: --bg in argv"  "$out" "--bg"

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
ROLLOVER_OPT_APPROVAL=edits
ROLLOVER_OPT_MODEL=claude-sonnet-5
EOF
mk_record claude sid-opt testproj
out=$(run_lns CLAUDE_CODE_SESSION_ID=sid-opt "$LNS" testproj --dry-run 2>&1)
assert_contains "T14a: claude edits approval flag" "$out" "--permission-mode acceptEdits"
assert_contains "T14b: claude model flag" "$out" "--model claude-sonnet-5"
out=$(run_lns "$LNS" testproj --runtime codex --dry-run 2>&1)
assert_contains "T14c: codex edits maps to --ask-for-approval never" "$out" "--ask-for-approval never"
out=$(run_lns "$LNS" testproj --runtime gemini --dry-run 2>&1)
assert_contains "T14d: gemini edits maps to --approval-mode auto_edit" "$out" "--approval-mode auto_edit"
out=$(run_lns "$LNS" testproj --runtime copilot --dry-run 2>&1)
assert_contains "T14e: copilot edits maps to --allow-all-tools" "$out" "--allow-all-tools"
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
printf 'ROLLOVER_OPT_APPROVAL=auto\n' > "$TMP/work/testproj/.rollover-options"
out=$(run_lns CLAUDE_CODE_SESSION_ID=sid-opt "$LNS" testproj --dry-run 2>&1)
assert_contains "T14k: claude auto maps to classifier mode" "$out" "--permission-mode auto"
assert_not_contains "T14l: claude auto is not acceptEdits" "$out" "acceptEdits"
out=$(run_lns "$LNS" testproj --runtime codex --dry-run 2>&1)
assert_contains "T14m: codex auto falls back to nearest level" "$out" "--ask-for-approval never"
assert_contains "T14n: codex auto fallback is noted" "$out" "no classifier"
out=$(run_lns "$LNS" testproj --runtime gemini --dry-run 2>&1)
assert_contains "T14o: gemini auto falls back to auto_edit" "$out" "--approval-mode auto_edit"
out=$(run_lns "$LNS" testproj --runtime copilot --dry-run 2>&1)
assert_contains "T14p: copilot auto falls back to --allow-all-tools" "$out" "--allow-all-tools"
rm -f "$TMP/work/testproj/.rollover-options"

echo "T15: per-item work/<proj>/context-budget.env overrides global knobs"
rm -f "$SESS"/*.json
printf 'ROLLOVER_RELAUNCH=auto\n' > "$TMP/work/testproj/context-budget.env"
out=$(run_lns "$LNS" testproj --runtime claude --dry-run 2>&1)
assert_contains "T15a: per-item file beats global (mode=auto)" "$out" "mode=auto"
out=$(env ROLLOVER_RELAUNCH=off "$LNS" testproj --runtime claude --dry-run 2>&1)
assert_contains "T15b: explicit env beats per-item file (mode=off)" "$out" "mode=off"
rm -f "$TMP/work/testproj/context-budget.env"
out=$(run_lns "$LNS" testproj --runtime claude --dry-run 2>&1)
assert_contains "T15c: no per-item file -> global applies (mode=manual)" "$out" "mode=manual"
printf 'ROLLOVER_RUNTIME=opencode\n' > "$TMP/work/testproj/context-budget.env"
out=$(run_lns "$LNS" testproj --dry-run 2>&1)
assert_contains "T15d: per-item ROLLOVER_RUNTIME beats global fallback" "$out" "runtime=opencode"
rm -f "$TMP/work/testproj/context-budget.env"

echo "T16: dying session's own work-item lock is released before launch"
LOCKF="$TMP/work/testproj/.active-session"
mklock() {  # $1=runtime $2=session-id
  jq -n --arg rt "$1" --arg sid "$2" \
    '{runtime:$rt, session_id:$sid, project:"testproj", acquired_at:"2026-08-05T00:00:00Z"}' \
    > "$LOCKF"
}
rm -f "$SESS"/*.json; mk_record claude sid-old testproj
mklock claude sid-old
cat > "$TMP/bin/claude" <<STUB
#!/usr/bin/env bash
# Stub successor: the lock must already be gone when the launch happens.
[ -f "$LOCKF" ] && echo "LOCK_STILL_HELD_AT_LAUNCH"
jq -n '{runtime:"claude", session_id:"sid-new", artifact:"/dev/null",
        project:"testproj", registered_at:"2026-08-05T00:00:01Z"}' \
  > "$SESS/claude-sid-new.json"
STUB
chmod +x "$TMP/bin/claude"
out=$(PATH="$TMP/bin:$PATH" ROLLOVER_CONFIRM_SECS=10 \
  run_lns CLAUDE_CODE_SESSION_ID=sid-old "$LNS" testproj --bg 2>&1); rc=$?
assert_eq           "T16a: exit 0"                   "$rc" "0"
assert_not_contains "T16b: lock gone at launch time" "$out" "LOCK_STILL_HELD_AT_LAUNCH"
assert_contains     "T16c: release noted"            "$out" "lock: released"

echo "T17: a lock recorded to a DIFFERENT session id is released anyway (C5, D4)"
# At rollover the rollover is the authority (design.md §3 C5). This launcher has
# already passed the lineage gate and is minting the successor, so the recorded
# holder is by definition the session that is ending -- including when a fork
# gave it a new session id, which the old id-equality rule could never satisfy
# and which left the successor racing an unreleased lock.
mklock claude forked-parent
out=$(run_lns CLAUDE_CODE_SESSION_ID=sid-old "$LNS" testproj --runtime claude </dev/null 2>&1)
[ ! -f "$LOCKF" ] && ok "T17a: foreign-id lock released at rollover" \
  || bad "T17a: lock survived the rollover -- the D4 shape"
assert_contains "T17b: previous holder named"    "$out" "claude-forked-parent"
assert_contains "T17c: rollover authority noted" "$out" "rollover authority"

echo "T18: --dry-run never mutates the lock"
mklock claude sid-old
out=$(run_lns CLAUDE_CODE_SESSION_ID=sid-old "$LNS" testproj --dry-run 2>&1)
[ -f "$LOCKF" ] && ok "T18a: dry-run keeps lock" || bad "T18a: dry-run removed lock"

echo "T19: mode=off still releases own lock (rollover ends this session regardless)"
mklock claude sid-old
out=$(run_lns ROLLOVER_RELAUNCH=off CLAUDE_CODE_SESSION_ID=sid-old \
  "$LNS" testproj --runtime claude 2>&1)
[ -f "$LOCKF" ] && bad "T19a: off mode kept lock" || ok "T19a: off mode released lock"
rm -f "$LOCKF"

echo "T20: rollover stamps the dying session's registry record superseded"
rm -f "$SESS"/*.json; mk_record claude sid-old testproj
mklock claude sid-old
run_lns ROLLOVER_RELAUNCH=off CLAUDE_CODE_SESSION_ID=sid-old \
  "$LNS" testproj --runtime claude >/dev/null 2>&1
assert_eq "T20a: role stamped superseded" \
  "$(jq -r .role "$SESS/claude-sid-old.json")" "superseded"
assert_contains "T20b: superseded_at stamped" \
  "$(jq -r '.superseded_at // empty' "$SESS/claude-sid-old.json")" "20"
rm -f "$SESS"/*.json; mk_record claude sid-old testproj
mklock claude sid-old
run_lns CLAUDE_CODE_SESSION_ID=sid-old "$LNS" testproj --dry-run >/dev/null 2>&1
assert_eq "T20c: dry-run does not stamp" \
  "$(jq -r '.role // "none"' "$SESS/claude-sid-old.json")" "none"
rm -f "$LOCKF"

echo "T21: session sequence + claude display name (work item + number)"
rm -f "$TMP/work/testproj/.session-seq" "$SESS"/*.json
out=$(run_lns "$LNS" testproj --runtime claude --dry-run 2>&1)
assert_contains "T21a: first successor is session #2" "$out" "rollover session #2"
assert_contains "T21b: claude argv carries --name" "$out" "--name testproj"
[ ! -f "$TMP/work/testproj/.session-seq" ] \
  && ok "T21c: dry-run does not persist seq" || bad "T21c: dry-run wrote seq file"
printf '15\n' > "$TMP/work/testproj/.session-seq"
out=$(run_lns ROLLOVER_RELAUNCH=off "$LNS" testproj --runtime claude 2>&1)
assert_contains "T21d: seq continues from file" "$out" "rollover session #16"
assert_eq "T21e: real run persists seq" "$(cat "$TMP/work/testproj/.session-seq")" "16"
out=$(run_lns "$LNS" testproj --runtime codex --dry-run 2>&1)
assert_contains "T21f: non-claude prompt still carries item+seq" "$out" "Work item testproj - rollover session #17"
assert_not_contains "T21g: no --name on non-claude argv" "$out" "--name"
rm -f "$TMP/work/testproj/.session-seq"

echo "T22: copilot-vscode seeded launch — code chat argv, BG confirm loop implied"
rm -f "$SESS"/*.json
out=$(run_lns "$LNS" testproj --runtime copilot-vscode --dry-run 2>&1)
assert_contains "T22a: runtime resolved"  "$out" "runtime=copilot-vscode"
assert_contains "T22b: bg implied (detached launch)" "$out" "bg=1"
assert_contains "T22c: code chat argv"    "$out" "cmd: code chat -r -m agent"
assert_contains "T22d: verbatim prompt"   "$out" "continue from"

echo "T23: lineage gate — counter must match the handoff top block's session number"
rm -f "$SESS"/*.json "$TMP/work/testproj/.session-seq" "$TMP/work/testproj/handoff.md"
HF="$TMP/work/testproj/handoff.md"

# No counter yet (session #1): nothing to compare, gate must stay inert.
printf '# Session Handoff — 2026-08-20 (session 9: a ledger block)\n' > "$HF"
out=$(run_lns "$LNS" testproj --runtime claude --dry-run 2>&1); rc=$?
assert_eq       "T23a: no counter -> gate inert" "$rc" "0"
assert_contains "T23b: still first successor"    "$out" "rollover session #2"

# Counter agrees with the ledger: launch, and the +1 is the launcher's alone.
printf '9\n' > "$TMP/work/testproj/.session-seq"
out=$(run_lns "$LNS" testproj --runtime claude --dry-run 2>&1); rc=$?
assert_eq       "T23c: agreement -> exit 0"   "$rc" "0"
assert_contains "T23d: successor is ledger+1" "$out" "rollover session #10"

# Counter holds the SUCCESSOR's number instead of its own — the s102/#104
# off-by-one — AND the staged session left evidence of work (a work-unit
# record newer than the counter's staging mtime). Refuse with a diagnosis
# rather than reclaim a number that did real work. (The no-evidence
# one-ahead case auto-heals instead — T24.)
printf '10\n' > "$TMP/work/testproj/.session-seq"
touch -t 202001010100 "$TMP/work/testproj/.session-seq"
printf '{"ts":"%s","label":"t23-work"}\n' "$(date -u +%FT%TZ)" \
  > "$TMP/.context-budget/context-ledger.jsonl"
out=$(run_lns "$LNS" testproj --runtime claude --dry-run 2>&1); rc=$?
assert_eq       "T23e: one-ahead + evidence -> exit 3" "$rc" "3"
assert_contains "T23f: gate named"                  "$out" "lineage gate"
assert_contains "T23g: counter value reported"      "$out" ".session-seq=10"
assert_contains "T23h: ledger value reported"       "$out" "top block is session 9"
assert_contains "T23i: remediation names seq-sync"  "$out" "seq-sync --project testproj --session 9"
assert_not_contains "T23j: refusal launches nothing" "$out" "cmd: claude"
assert_contains "T23j2: evidence label shown"       "$out" "t23-work"
rm -f "$TMP/.context-budget/context-ledger.jsonl"

# Unparseable top block: prose may VETO a number, never DERIVE one — skip.
printf '# Session Handoff — no number in this block\n' > "$HF"
out=$(run_lns "$LNS" testproj --runtime claude --dry-run 2>&1); rc=$?
assert_eq "T23k: unparseable ledger -> gate skips" "$rc" "0"

# Absent ledger: projects without a numbered ledger pass trivially.
rm -f "$HF"
out=$(run_lns "$LNS" testproj --runtime claude --dry-run 2>&1); rc=$?
assert_eq "T23l: absent ledger -> gate skips" "$rc" "0"

# The session_handoff.md spelling is gated too.
printf '# Session Handoff — 2026-08-20 (session 4: older spelling)\n' \
  > "$TMP/work/testproj/session_handoff.md"
out=$(run_lns "$LNS" testproj --runtime claude --dry-run 2>&1); rc=$?
assert_eq       "T23m: session_handoff.md spelling gates too" "$rc" "3"
assert_contains "T23n: names that ledger's number"            "$out" "top block is session 4"
rm -f "$TMP/work/testproj/session_handoff.md" "$TMP/work/testproj/.session-seq"

# Widened heading grammar (backlog M33): the gate must see the number in every
# numbered title form check-ledger.py accepts, not just "session N".
printf '# Session Handoff — s202 (dateless sNNN form)\n' > "$HF"
printf '9\n' > "$TMP/work/testproj/.session-seq"
out=$(run_lns "$LNS" testproj --runtime claude --dry-run 2>&1); rc=$?
assert_eq       "T23o: sNNN form gates too"        "$rc" "3"
assert_contains "T23p: sNNN number extracted"      "$out" "top block is session 202"

printf '# Session Handoff — 2026-08-29 (session #9: hash-number form)\n' > "$HF"
out=$(run_lns "$LNS" testproj --runtime claude --dry-run 2>&1); rc=$?
assert_eq "T23q: 'session #N' form agrees -> exit 0" "$rc" "0"

printf '# Session Handoff — 9 (2026-08-29): current numbered form\n' > "$HF"
out=$(run_lns "$LNS" testproj --runtime claude --dry-run 2>&1); rc=$?
assert_eq "T23r: current '— N (date)' form agrees -> exit 0" "$rc" "0"

# Date-only heading: the year must not be misread as a session number, and
# the skip must be visible, not silent.
printf '# Session Handoff — 2026-08-07 (date-only title, no number)\n' > "$HF"
out=$(run_lns "$LNS" testproj --runtime claude --dry-run 2>&1); rc=$?
assert_eq       "T23s: date-only heading -> gate skips"  "$rc" "0"
assert_contains "T23t: skip is announced"                "$out" "carries no session number"
rm -f "$TMP/work/testproj/.session-seq" "$HF"

echo "T24: lineage gate one-ahead — no-trace auto-heal vs evidence refusal"
# One-ahead with NO trace of work (fresh staging mtime, no work-unit records,
# non-git workspace): the staged session was launched but never did anything —
# reclaim its number and continue the launch instead of dying.
printf '# Session Handoff — 2026-08-20 (session 9: a ledger block)\n' > "$HF"
printf '10\n' > "$TMP/work/testproj/.session-seq"
rm -f "$TMP/.context-budget/context-ledger.jsonl"
out=$(run_lns "$LNS" testproj --runtime claude --dry-run 2>&1); rc=$?
assert_eq       "T24a: no-trace one-ahead heals -> exit 0" "$rc" "0"
assert_contains "T24b: reclaim announced"                  "$out" "reclaiming its number"
assert_contains "T24c: successor reuses the number"        "$out" "rollover session #10"
assert_eq "T24c2: dry-run leaves counter untouched" "$(cat "$TMP/work/testproj/.session-seq")" "10"

# Real run (mode=off exits after the bump): heal writes 9, bump writes 10 —
# net effect the phantom number is reused, and the ledger stays consistent.
out=$(run_lns ROLLOVER_RELAUNCH=off "$LNS" testproj --runtime claude 2>&1); rc=$?
assert_eq "T24d: real-run heal -> exit 0" "$rc" "0"
assert_eq "T24e: number reclaimed (heal to 9 + bump = 10 reused)" \
  "$(cat "$TMP/work/testproj/.session-seq")" "10"

# Evidence via a work-unit record: message contract — labels listed and
# reconstruction guidance present (mechanics already covered in T23e).
touch -t 202001010100 "$TMP/work/testproj/.session-seq"
printf '{"ts":"%s","label":"t24-evidence"}\n' "$(date -u +%FT%TZ)" \
  > "$TMP/.context-budget/context-ledger.jsonl"
out=$(run_lns "$LNS" testproj --runtime claude --dry-run 2>&1); rc=$?
assert_eq       "T24f: record evidence -> exit 3"    "$rc" "3"
assert_contains "T24f2: evidence label listed"       "$out" "t24-evidence"
assert_contains "T24f3: reconstruction guidance"     "$out" "Reconstruct"
rm -f "$TMP/.context-budget/context-ledger.jsonl"

# Git evidence needs a repo, and the main $TMP must stay non-git (C/W-series
# depend on it) — isolated mini-workspace instead.
EV="$(mktemp -d)"
mkdir -p "$EV/scripts" "$EV/work/testproj" "$EV/.context-budget/sessions"
cp "$SRC_ROOT/scripts/launch-next-session.sh" "$EV/scripts/"
printf 'ROLLOVER_RELAUNCH=manual\nROLLOVER_RUNTIME=claude\n' > "$EV/context-budget.env"
echo "# launcher" > "$EV/work/testproj/next-session.md"
printf '# Session Handoff — 2026-08-20 (session 9: a ledger block)\n' \
  > "$EV/work/testproj/handoff.md"
printf '10\n' > "$EV/work/testproj/.session-seq"
touch -t 202001010100 "$EV/work/testproj/.session-seq"
git -C "$EV" init -q
git -C "$EV" add -A >/dev/null 2>&1
git -C "$EV" -c user.email=t@t -c user.name=t commit -qm "t24g work landed" >/dev/null 2>&1
out=$(run_lns "$EV/scripts/launch-next-session.sh" testproj --runtime claude --dry-run 2>&1); rc=$?
assert_eq       "T24g: commit since staging -> exit 3" "$rc" "3"
assert_contains "T24g2: commit shown as evidence"      "$out" "t24g work landed"

# Dirty-tree variant: backdate the commit so only the dirty work item remains
# as evidence.
GIT_COMMITTER_DATE="2019-01-01T00:00:00Z" git -C "$EV" -c user.email=t@t -c user.name=t \
  commit -q --amend --no-edit --date "2019-01-01T00:00:00Z" >/dev/null 2>&1
echo scratch > "$EV/work/testproj/scratch.txt"
out=$(run_lns "$EV/scripts/launch-next-session.sh" testproj --runtime claude --dry-run 2>&1); rc=$?
assert_eq       "T24h: dirty work item -> exit 3"     "$rc" "3"
assert_contains "T24h2: dirty path shown as evidence" "$out" "scratch.txt"
rm -rf "$EV"

# C-series must inherit nothing from T24.
rm -f "$TMP/work/testproj/.session-seq" "$HF" "$TMP/.context-budget/context-ledger.jsonl"

echo "C: --clear in-place rollover (closes issue 04; ADR-0009)"
SEEDF="$TMP/work/testproj/.pending-clear-seed"
SEQF="$TMP/work/testproj/.session-seq"
CLEAR_PROMPT='Work item testproj - rollover session #2. Read `work/testproj/next-session.md` and continue from **First actions**.'

echo "C1: --clear --dry-run announces mode=clear, seeds nothing, bumps nothing"
rm -f "$SESS"/*.json "$SEEDF" "$SEQF" "$LOCKF"
out=$(run_lns "$LNS" testproj --runtime claude --clear --dry-run 2>&1); rc=$?
assert_eq           "C1a: exit 0"           "$rc" "0"
assert_contains     "C1b: mode=clear"       "$out" "mode=clear"
assert_contains     "C1c: canonical prompt" "$out" "$CLEAR_PROMPT"
assert_not_contains "C1d: launches nothing" "$out" "cmd: claude"
[ ! -f "$SEEDF" ] && ok "C1e: no seed written"   || bad "C1e: dry-run wrote a seed"
[ ! -f "$SEQF" ]  && ok "C1f: counter not bumped" || bad "C1f: dry-run bumped the counter"

echo "C2: --clear seeds the canonical prompt verbatim, bumps the counter, execs nothing"
out=$(run_lns "$LNS" testproj --runtime claude --clear 2>&1); rc=$?
assert_eq "C2a: exit 0" "$rc" "0"
assert_eq "C2b: seed holds the prompt verbatim" "$(cat "$SEEDF" 2>/dev/null)" "$CLEAR_PROMPT"
assert_eq "C2c: counter bumped to 2"            "$(cat "$SEQF" 2>/dev/null)" "2"
assert_not_contains "C2d: no process launched"  "$out" "cmd: claude"
assert_contains "C2e: names the seed file"      "$out" ".pending-clear-seed"
assert_contains "C2f: tells the human to clear" "$out" "/clear"
assert_contains "C2g: rewind hint is exact"     "$out" "seq-sync --project testproj --session 1"
rm -f "$SEEDF" "$SEQF"

echo "C3: --clear keeps the lock and the registry record — the process is still alive"
rm -f "$SESS"/*.json; mk_record claude sid-old testproj
mklock claude sid-old
out=$(run_lns CLAUDE_CODE_SESSION_ID=sid-old "$LNS" testproj --clear 2>&1)
[ -f "$LOCKF" ] && ok "C3a: own lock NOT released" || bad "C3a: --clear released its own lock"
assert_eq "C3b: record NOT stamped superseded" \
  "$(jq -r '.role // "none"' "$SESS/claude-sid-old.json")" "none"
assert_not_contains "C3c: no release note" "$out" "lock: released"
rm -f "$LOCKF" "$SEEDF" "$SEQF"

echo "C4: --clear refuses the combinations that cannot mean anything"
rm -f "$SESS"/*.json
out=$(run_lns "$LNS" testproj --runtime claude --clear --emit "$TMP/cmd.txt" 2>&1); rc=$?
assert_eq       "C4a: with --emit, exit 3" "$rc" "3"
assert_contains "C4b: --emit named"        "$out" "--emit"
out=$(run_lns "$LNS" testproj --runtime claude --clear --bg 2>&1); rc=$?
assert_eq       "C4c: with --bg, exit 3"   "$rc" "3"
assert_contains "C4d: --bg named"          "$out" "--bg"
[ ! -f "$SEQF" ] && ok "C4e: parse-time refusals bump no counter" || bad "C4e: refusal bumped the counter"
out=$(run_lns "$LNS" testproj --runtime codex --clear 2>&1); rc=$?
assert_eq       "C4f: non-claude runtime, exit 3" "$rc" "3"
assert_contains "C4g: claude-only"                "$out" "claude-only"
[ ! -f "$SEEDF" ] && ok "C4h: no seed written on any refusal" || bad "C4h: a refusal still seeded"
rm -f "$SEQF"

echo "C5: --clear is an explicit request — ROLLOVER_RELAUNCH=off does not neuter it"
out=$(run_lns ROLLOVER_RELAUNCH=off "$LNS" testproj --runtime claude --clear 2>&1); rc=$?
assert_eq       "C5a: exit 0"     "$rc" "0"
assert_contains "C5b: mode=clear" "$out" "mode=clear"
assert_eq "C5c: seed still written" "$(cat "$SEEDF" 2>/dev/null)" "$CLEAR_PROMPT"
rm -f "$SEEDF" "$SEQF" "$SESS"/*.json

echo "W: worktree-invoked launch — sync the main checkout, launch from it (issue 05)"
GW="$(mktemp -d)"; GW="$(cd "$GW" && pwd -P)"
trap 'rm -rf "$TMP" "$GW"' EXIT
GMAIN="$GW/main"
mkdir -p "$GMAIN/scripts" "$GMAIN/work/testproj"
cp "$SRC_ROOT/scripts/launch-next-session.sh" "$GMAIN/scripts/"
printf 'ROLLOVER_RELAUNCH=manual\nROLLOVER_RUNTIME=claude\n' > "$GMAIN/context-budget.env"
echo "# launcher v1" > "$GMAIN/work/testproj/next-session.md"
GITC() { git -c user.email=t@t -c user.name=t "$@"; }
GITC -C "$GMAIN" init -q -b main
GITC -C "$GMAIN" add -A; GITC -C "$GMAIN" commit -qm init
git init -q --bare "$GW/origin.git"
git -C "$GMAIN" remote add origin "$GW/origin.git"
git -C "$GMAIN" push -q -u origin main
git -C "$GMAIN" worktree add -q "$GMAIN/wt" -b session-branch
WLNS="$GMAIN/wt/scripts/launch-next-session.sh"

echo "W1: pushed worktree, clean main — main ff-pulled, launch from main root"
echo "# launcher v2" > "$GMAIN/wt/work/testproj/next-session.md"
GITC -C "$GMAIN/wt" commit -qam "rollover: new launcher"
git -C "$GMAIN/wt" push -q origin session-branch:main
out=$(run_lns "$WLNS" testproj 2>&1 </dev/null); rc=$?
assert_eq "W1a: exit 0" "$rc" "0"
assert_contains "W1b: worktree-invoked sync noted" "$out" "worktree-invoked"
assert_eq "W1c: main checkout ff-pulled (launcher current)" \
  "$(cat "$GMAIN/work/testproj/next-session.md")" "# launcher v2"
assert_contains "W1d: non-tty manual prints run: line" "$out" "run: claude"
[ -f "$GMAIN/work/testproj/.session-seq" ] \
  && ok "W1e: session-seq written in main root" || bad "W1e: no main-root seq"
[ ! -f "$GMAIN/wt/work/testproj/.session-seq" ] \
  && ok "W1f: no session-seq in the worktree" || bad "W1f: worktree seq written"

echo "W2: unpushed worktree commits / dirty worktree launcher — loud refusal"
echo "# launcher v3" > "$GMAIN/wt/work/testproj/next-session.md"
out=$(run_lns "$WLNS" testproj 2>&1 </dev/null); rc=$?
assert_eq "W2a: dirty worktree work/ dies" "$rc" "3"
assert_contains "W2b: names the uncommitted state" "$out" "uncommitted"
GITC -C "$GMAIN/wt" commit -qam "rollover v3"
out=$(run_lns "$WLNS" testproj 2>&1 </dev/null); rc=$?
assert_eq "W2c: unpushed worktree commit dies" "$rc" "3"
assert_contains "W2d: says push first" "$out" "push"
git -C "$GMAIN/wt" push -q origin session-branch:main

echo "W3: dirty main checkout under work/<proj> — loud refusal"
git -C "$GMAIN" pull -q --ff-only
echo "local edit" >> "$GMAIN/work/testproj/next-session.md"
out=$(run_lns "$WLNS" testproj 2>&1 </dev/null); rc=$?
assert_eq "W3a: dirty main dies" "$rc" "3"
assert_contains "W3b: names the main checkout" "$out" "main checkout"
git -C "$GMAIN" checkout -q -- work/testproj

echo "W4: diverged main checkout — ff-only pull fails, loud refusal"
echo "# main-local" > "$GMAIN/work/testproj/next-session.md"
GITC -C "$GMAIN" commit -qam "main-local commit"
echo "# launcher v4" > "$GMAIN/wt/work/testproj/next-session.md"
GITC -C "$GMAIN/wt" commit -qam "rollover v4"
git -C "$GMAIN/wt" push -q origin session-branch:main
out=$(run_lns "$WLNS" testproj 2>&1 </dev/null); rc=$?
assert_eq "W4a: diverged main dies" "$rc" "3"
assert_contains "W4b: ff-only failure surfaced" "$out" "ff-only"
git -C "$GMAIN" reset -q --hard origin/main

echo "W5: main-checkout invocation — sync path not taken"
out=$(run_lns "$GMAIN/scripts/launch-next-session.sh" testproj --dry-run 2>&1 </dev/null); rc=$?
assert_eq "W5a: exit 0" "$rc" "0"
assert_not_contains "W5b: no worktree sync attempted" "$out" "worktree-invoked"
cd "$TMP"

echo "W6: stranded worktree .session-seq — main checkout is authoritative, stray reported"
# Max-wins was retired once seq-sync became the counter's only writer: it could
# only increase, so a stranded over-count was ratified forever (ADR-0008).
printf '27\n' > "$GMAIN/work/testproj/.session-seq"
printf '29\n' > "$GMAIN/wt/work/testproj/.session-seq"
out=$(run_lns "$WLNS" testproj --dry-run 2>&1 </dev/null); rc=$?
assert_eq       "W6a: exit 0" "$rc" "0"
assert_contains "W6b: successor numbered from the main copy" "$out" "rollover session #28"
assert_contains "W6c: stray reported, not adopted" "$out" "ignoring stray copy"
assert_not_contains "W6c2: the stray does not floor the number" "$out" "rollover session #30"
out=$(run_lns "$WLNS" testproj 2>&1 </dev/null)
assert_eq "W6d: real run persists main+1 in main root" \
  "$(cat "$GMAIN/work/testproj/.session-seq")" "28"
assert_eq "W6e: worktree copy left alone" \
  "$(cat "$GMAIN/wt/work/testproj/.session-seq")" "29"
out=$(run_lns "$GMAIN/scripts/launch-next-session.sh" testproj --dry-run 2>&1 </dev/null)
assert_contains "W6f: main-checkout invocation reads the same copy" "$out" "rollover session #29"
rm -f "$GMAIN/work/testproj/.session-seq" "$GMAIN/wt/work/testproj/.session-seq"

echo "W7: stranded newer worktree .rollover-options — adopted, persisted to main"
printf 'ROLLOVER_OPT_APPROVAL=default\n' > "$GMAIN/work/testproj/.rollover-options"
touch -t 202001010000 "$GMAIN/work/testproj/.rollover-options"
printf 'ROLLOVER_OPT_APPROVAL=edits\n' > "$GMAIN/wt/work/testproj/.rollover-options"
out=$(run_lns "$WLNS" testproj --runtime claude --dry-run 2>&1 </dev/null)
assert_contains "W7a: dry-run reads the newest copy in place" "$out" "--permission-mode acceptEdits"
assert_contains "W7b: dry-run does not persist (would-adopt note)" "$out" "would adopt"
assert_contains "W7c: main copy untouched by dry-run" \
  "$(cat "$GMAIN/work/testproj/.rollover-options")" "ROLLOVER_OPT_APPROVAL=default"
out=$(run_lns "$WLNS" testproj --runtime claude 2>&1 </dev/null)
assert_contains "W7d: real run persists the adopted copy to main" \
  "$(cat "$GMAIN/work/testproj/.rollover-options")" "ROLLOVER_OPT_APPROVAL=edits"
rm -f "$GMAIN/work/testproj/.rollover-options" "$GMAIN/wt/work/testproj/.rollover-options" \
  "$GMAIN/work/testproj/.session-seq"

echo "W8: dry-run from a worktree announces the sync, never claims it happened"
# The note sat outside the `[ "$DRY" -eq 0 ]` guard, so --dry-run reported
# "main checkout synced" while pulling nothing. A dry-run that describes work it
# did not do is worse than silence: it is the one mode whose whole contract is
# that the operator can trust the readout without checking.
echo "# launcher v4b" > "$GMAIN/wt/work/testproj/next-session.md"
GITC -C "$GMAIN/wt" commit -qam "rollover v4b"
git -C "$GMAIN/wt" push -q origin session-branch:main
before="$(cat "$GMAIN/work/testproj/next-session.md")"
out=$(run_lns "$WLNS" testproj --dry-run 2>&1 </dev/null); rc=$?
assert_eq "W8a: exit 0" "$rc" "0"
assert_not_contains "W8b: does not claim a completed sync" "$out" "checkout synced"
assert_contains     "W8c: announces the sync as pending" "$out" "would sync"
assert_eq "W8d: the main checkout was genuinely not pulled" \
  "$(cat "$GMAIN/work/testproj/next-session.md")" "$before"
git -C "$GMAIN" reset -q --hard origin/main
rm -f "$GMAIN/work/testproj/.session-seq"


echo "F1: newer launcher on an unmerged local branch — stale-launcher refusal (L33)"
echo "# launcher v5" > "$GMAIN/wt/work/testproj/next-session.md"
GITC -C "$GMAIN/wt" commit -qam "rollover v5"
out=$(run_lns "$GMAIN/scripts/launch-next-session.sh" testproj --dry-run 2>&1 </dev/null); rc=$?
assert_eq       "F1a: exit 3"            "$rc" "3"
assert_contains "F1b: stale launcher named" "$out" "stale launcher"
assert_contains "F1c: carrying ref named"   "$out" "session-branch"

echo "F2: --skip-freshness overrides the guard"
out=$(run_lns "$GMAIN/scripts/launch-next-session.sh" testproj --dry-run --skip-freshness 2>&1 </dev/null); rc=$?
assert_eq       "F2a: exit 0"    "$rc" "0"
assert_contains "F2b: launches"  "$out" "cmd: claude"

echo "F3: branch merged — guard passes"
GITC -C "$GMAIN" merge -q session-branch
out=$(run_lns "$GMAIN/scripts/launch-next-session.sh" testproj --dry-run 2>&1 </dev/null); rc=$?
assert_eq "F3a: exit 0 after merge" "$rc" "0"

echo "F4: origin/main ahead of the local checkout — refusal until pulled"
echo "# launcher v6" > "$GMAIN/wt/work/testproj/next-session.md"
GITC -C "$GMAIN/wt" commit -qam "rollover v6"
git -C "$GMAIN/wt" push -q origin session-branch:main
out=$(run_lns "$GMAIN/scripts/launch-next-session.sh" testproj --dry-run 2>&1 </dev/null); rc=$?
assert_eq       "F4a: exit 3 while lagging" "$rc" "3"
assert_contains "F4b: stale launcher named" "$out" "stale launcher"
git -C "$GMAIN" pull -q --ff-only
out=$(run_lns "$GMAIN/scripts/launch-next-session.sh" testproj --dry-run 2>&1 </dev/null); rc=$?
assert_eq "F4c: exit 0 after pull" "$rc" "0"

echo "G: pre-launch lock release guards (TE6 A1) — role/liveness + I4 child-lock sweep"
# Mutations that make these red: G1 — drop the role/liveness check before the
# rm (the pre-A1 unconditional release); G2 — invert it to refuse on ANY
# non-self holder; G3 — drop the live-child-lock refusal; G4 — drop the
# stale-child-lock sweep (the child lock file survives).
cd "$TMP"
mk_live_record() {  # $1=runtime $2=session-id $3=project $4=role — live artifact
  echo live > "$TMP/art-$2"
  jq -n --arg rt "$1" --arg sid "$2" --arg p "$3" --arg role "$4" \
    --arg af "$TMP/art-$2" \
    '{runtime:$rt, session_id:$sid, artifact:$af, project:$p,
      registered_at:"2026-08-05T00:00:00Z", role:$role}' \
    > "$SESS/$1-$2.json"
}

echo "G1: an auxiliary session must NOT release a LIVE primary's lock"
rm -f "$SESS"/*.json "$LOCKF" "$TMP/work/testproj/.session-seq"; rm -rf "$TMP/work/testproj/.agent-locks"
mk_live_record claude sid-primary testproj primary
mk_live_record claude sid-aux testproj auxiliary
mklock claude sid-primary
out=$(run_lns CLAUDE_CODE_SESSION_ID=sid-aux "$LNS" testproj --runtime claude </dev/null 2>&1); rc=$?
assert_eq       "G1a: exit 3 (loud refusal)"    "$rc" "3"
assert_contains "G1b: names the live holder"    "$out" "claude-sid-primary"
[ -f "$LOCKF" ] && ok "G1c: live primary's lock intact" \
  || bad "G1c: aux destroyed the live primary's lock (two-primaries shape)"
assert_eq "G1d: primary record not stamped superseded" \
  "$(jq -r '.role' "$SESS/claude-sid-primary.json")" "primary"
# G1e (amended, TE6 R3): a refusal must be side-effect-free — the old form
# asserted the seq-sync rewind remedy, whose defect (counter bumped before the
# guard) is now removed. Mutation that makes G1e red: move the counter bump
# back above the authorization guard (the pre-R3 order).
[ ! -f "$TMP/work/testproj/.session-seq" ] \
  && ok "G1e: refusal leaves .session-seq untouched" \
  || bad "G1e: refusal bumped the counter"

echo "G2: aux with a DEAD/unknowable holder still releases (rollover authority, D4 preserved)"
rm -f "$SESS"/*.json "$LOCKF" "$TMP/work/testproj/.session-seq"
mk_live_record claude sid-aux testproj auxiliary
mklock claude sid-ghost   # no registry record -> liveness unknowable -> stale
out=$(run_lns CLAUDE_CODE_SESSION_ID=sid-aux "$LNS" testproj --runtime claude </dev/null 2>&1); rc=$?
assert_eq "G2a: exit 0" "$rc" "0"
[ ! -f "$LOCKF" ] && ok "G2b: dead holder's lock released" \
  || bad "G2b: lock survived — successor will race it"
assert_contains "G2c: rollover authority noted" "$out" "rollover authority"

echo "G3: live child lock blocks the pre-launch release (I4)"
rm -f "$SESS"/*.json "$LOCKF" "$TMP/work/testproj/.session-seq"; rm -rf "$TMP/work/testproj/.agent-locks"
mk_live_record claude sid-old testproj primary
mk_live_record claude sid-kid testproj child
mklock claude sid-old
mkdir -p "$TMP/work/testproj/.agent-locks"
jq -n '{runtime:"claude", session_id:"sid-kid", parent_session_id:"sid-old",
        project:"testproj", acquired_at:"2026-08-05T00:00:00Z"}' \
  > "$TMP/work/testproj/.agent-locks/claude-sid-kid.json"
out=$(run_lns CLAUDE_CODE_SESSION_ID=sid-old "$LNS" testproj --runtime claude </dev/null 2>&1); rc=$?
assert_eq       "G3a: exit 3 (refused)"       "$rc" "3"
assert_contains "G3b: names the child lock"   "$out" "claude-sid-kid"
[ -f "$LOCKF" ] && ok "G3c: project lock intact (release order kept)" \
  || bad "G3c: project lock released above a live child lock"
# G3d (TE6 R3): the I4 refusal is side-effect-free too. Mutation that makes
# G3d red: move the counter bump back above the authorization guard.
[ ! -f "$TMP/work/testproj/.session-seq" ] \
  && ok "G3d: refusal leaves .session-seq untouched" \
  || bad "G3d: refusal bumped the counter"

echo "G4: stale child lock is swept, release proceeds"
rm -f "$SESS"/*.json "$LOCKF" "$TMP/work/testproj/.session-seq"; rm -rf "$TMP/work/testproj/.agent-locks"
mk_live_record claude sid-old testproj primary
mklock claude sid-old
mkdir -p "$TMP/work/testproj/.agent-locks"
jq -n '{runtime:"claude", session_id:"sid-dead-kid", parent_session_id:"sid-old",
        project:"testproj", acquired_at:"2026-08-05T00:00:00Z"}' \
  > "$TMP/work/testproj/.agent-locks/claude-sid-dead-kid.json"  # no record -> stale
out=$(run_lns CLAUDE_CODE_SESSION_ID=sid-old "$LNS" testproj --runtime claude </dev/null 2>&1); rc=$?
assert_eq "G4a: exit 0" "$rc" "0"
[ ! -f "$TMP/work/testproj/.agent-locks/claude-sid-dead-kid.json" ] \
  && ok "G4b: stale child lock swept" || bad "G4b: stale child lock survived"
[ ! -f "$LOCKF" ] && ok "G4c: project lock released" || bad "G4c: project lock survived"
rm -f "$SESS"/*.json "$LOCKF" "$TMP"/art-*; rm -rf "$TMP/work/testproj/.agent-locks"

echo "G5: a SUPERSEDED-role caller (takeover backstory) must NOT release a LIVE holder's lock"
# Mutation that makes G5a/G5c/G5f red: reinstate the role allowlist
# ([ "$own_role" = "auxiliary" ]) in the pre-release guard — a caller whose
# record says role=superseded is not on the list, passes, and releases the
# live holder's lock (the TE6 R1 two-primaries shape).
# Mutation that makes G5b red: drop the holder's name from the refusal
# message (the refusal must name who it is protecting).
rm -f "$SESS"/*.json "$LOCKF" "$TMP/work/testproj/.session-seq"; rm -rf "$TMP/work/testproj/.agent-locks"
mk_live_record claude sid-primary testproj primary
mk_live_record claude sid-super testproj superseded
mklock claude sid-primary
out=$(run_lns CLAUDE_CODE_SESSION_ID=sid-super "$LNS" testproj --runtime claude </dev/null 2>&1); rc=$?
assert_eq       "G5a: exit 3 (loud refusal)"    "$rc" "3"
assert_contains "G5b: names the live holder"    "$out" "claude-sid-primary"
[ -f "$LOCKF" ] && ok "G5c: live holder's lock intact" \
  || bad "G5c: superseded caller destroyed the live holder's lock"
# Mutation that makes G5d red: reinstate the role allowlist AND stamp the
# released holder's record (the record named by the lock) instead of stamping
# $REC only when it is provably the caller's own — the wrongly-passing
# release then marks the live primary superseded.
assert_eq "G5d: holder record not stamped superseded" \
  "$(jq -r '.role' "$SESS/claude-sid-primary.json")" "primary"
# Mutation that makes G5e red: move the counter bump back above the guard.
[ ! -f "$TMP/work/testproj/.session-seq" ] \
  && ok "G5e: refusal leaves .session-seq untouched" \
  || bad "G5e: refusal bumped the counter"
assert_contains "G5f: one-primary invariant named" "$out" "one primary per work item"

echo "G6: no env identity, fallback resolves an aux's record — release proceeds (C5/R2)"
# Mutation that makes G6a/G6b red: key the guard on the fallback-resolved
# record (the pre-R1 shape: own_role read from \$REC wherever it came from) —
# the attended primary (no exported session id) resolves to the newer aux
# record and its legitimate rollover is wrongly refused.
rm -f "$SESS"/*.json "$LOCKF" "$TMP/work/testproj/.session-seq"
mk_live_record claude sid-primary testproj primary
mk_live_record claude sid-aux testproj auxiliary
touch -t 202001010000 "$SESS/claude-sid-primary.json"   # aux record is newest
mklock claude sid-primary
out=$(run_lns "$LNS" testproj --runtime claude </dev/null 2>&1); rc=$?
assert_eq "G6a: exit 0 (rollover authority retained)" "$rc" "0"
[ ! -f "$LOCKF" ] && ok "G6b: lock released" \
  || bad "G6b: attended rollover wrongly refused — lock survived"

echo "G7: in G6's scenario the fallback-resolved aux record is NOT stamped superseded"
# Mutation that makes G7a red: stamp \$REC unconditionally after the release
# (the pre-R2 shape at :524-528) — the LIVE aux's record, which merely
# happened to be newest, gets marked superseded.
assert_eq "G7a: aux record role unchanged" \
  "$(jq -r '.role' "$SESS/claude-sid-aux.json")" "auxiliary"

echo "G9: --clear from an env-identified non-holder while the holder is LIVE — refused"
# Mutation that makes G9a/G9b/G9c red: keep the --clear early-exit above the
# authorization guard (the pre-R4 order) — the aux's --clear exits 0 having
# bumped the shared counter and written .pending-clear-seed (an in-place
# successor with no lock authority).
rm -f "$SESS"/*.json "$LOCKF" "$SEEDF" "$TMP/work/testproj/.session-seq"
mk_live_record claude sid-primary testproj primary
mk_live_record claude sid-aux testproj auxiliary
mklock claude sid-primary
out=$(run_lns CLAUDE_CODE_SESSION_ID=sid-aux "$LNS" testproj --clear </dev/null 2>&1); rc=$?
assert_eq "G9a: exit 3" "$rc" "3"
[ ! -f "$SEEDF" ] && ok "G9b: no .pending-clear-seed written" \
  || bad "G9b: refused --clear still seeded"
[ ! -f "$TMP/work/testproj/.session-seq" ] \
  && ok "G9c: refusal leaves .session-seq untouched" \
  || bad "G9c: refusal bumped the counter"
# Mutation that makes G9d red: run the release ACTION at the guard's decision
# site (hoist rm with the decision) — a passing-through --clear would lose its
# own lock; here the refusal path must equally leave the holder's lock alone.
[ -f "$LOCKF" ] && ok "G9d: live holder's lock intact" \
  || bad "G9d: --clear touched the live holder's lock"

echo "G10: per-item CONTEXT_LOCK_STALE_SECS is GLOBAL-ONLY for lock liveness (R8)"
# Mutation that makes G10a/G10c red: let the per-item context-budget.env
# override LOCK_STALE (the pre-R8 knob loop) — the 1s per-item value calls
# the 60s-old holder "stale" and the guard releases a live lock that
# context-budget.sh still calls live (split-brain).
rm -f "$SESS"/*.json "$LOCKF" "$TMP/work/testproj/.session-seq"
printf 'CONTEXT_LOCK_STALE_SECS=1\n' > "$TMP/work/testproj/context-budget.env"
mk_live_record claude sid-primary testproj primary
mk_live_record claude sid-aux testproj auxiliary
past="$(date -v-60S +%Y%m%d%H%M.%S 2>/dev/null || date -d '-60 seconds' +%Y%m%d%H%M.%S)"
touch -t "$past" "$TMP/art-sid-primary"   # 60s old: live globally, "stale" per-item
mklock claude sid-primary
out=$(run_lns CLAUDE_CODE_SESSION_ID=sid-aux "$LNS" testproj --runtime claude </dev/null 2>&1); rc=$?
assert_eq "G10a: exit 3 (holder live under the global rule)" "$rc" "3"
[ -f "$LOCKF" ] && ok "G10c: live holder's lock intact" \
  || bad "G10c: per-item stale override released a live lock"
# G10b: the ignored knob is called out loudly. Mutation that makes G10b red:
# drop the ignore-note (silently discard the per-item value).
assert_contains "G10b: per-item value loudly ignored" "$out" "global-only"
rm -f "$TMP/work/testproj/context-budget.env"
rm -f "$SESS"/*.json "$LOCKF" "$TMP"/art-* "$TMP/work/testproj/.session-seq"

echo "G11: --clear from the LIVE holder with a live CHILD lock — allowed (I4 protects the release; --clear releases nothing)"
# Mutation that makes G11a/G11b/G11c/G11d red: apply guard (b)'s child-lock
# refusal to the --clear path (the unscoped hoist, TE6 R4 verifier finding) —
# the holder's own in-place relaunch is refused over a child its surviving
# process still owns, violating R4(c)'s "--clear from the holder ... unchanged
# behaviour".
rm -f "$SESS"/*.json "$LOCKF" "$SEEDF" "$TMP/work/testproj/.session-seq"
rm -rf "$TMP/work/testproj/.agent-locks"
mk_live_record claude sid-old testproj primary
mk_live_record claude sid-kid testproj child
mklock claude sid-old
mkdir -p "$TMP/work/testproj/.agent-locks"
jq -n '{runtime:"claude", session_id:"sid-kid", parent_session_id:"sid-old",
        project:"testproj", acquired_at:"2026-08-05T00:00:00Z"}' \
  > "$TMP/work/testproj/.agent-locks/claude-sid-kid.json"
out=$(run_lns CLAUDE_CODE_SESSION_ID=sid-old "$LNS" testproj --clear </dev/null 2>&1); rc=$?
assert_eq "G11a: exit 0 (holder's --clear proceeds)" "$rc" "0"
assert_eq "G11b: seed written verbatim" "$(cat "$SEEDF" 2>/dev/null)" "$CLEAR_PROMPT"
[ -f "$LOCKF" ] && ok "G11c: own project lock intact (--clear releases nothing)" \
  || bad "G11c: --clear touched the project lock"
assert_eq "G11d: counter bumped normally" \
  "$(cat "$TMP/work/testproj/.session-seq" 2>/dev/null)" "2"
# Mutation that makes G11e red: make --clear pass guard (b) by force-removing
# the child locks instead of scoping the guard off the --clear path — the
# surviving process's live child loses its lock.
[ -f "$TMP/work/testproj/.agent-locks/claude-sid-kid.json" ] \
  && ok "G11e: live child lock untouched" \
  || bad "G11e: --clear disturbed a live child lock"
rm -f "$SESS"/*.json "$LOCKF" "$SEEDF" "$TMP"/art-* "$TMP/work/testproj/.session-seq"
rm -rf "$TMP/work/testproj/.agent-locks"

echo "G12: exported CONTEXT_LOCK_STALE_SECS reaches the successor at the launcher's resolution, not the per-item value (R8 env-inheritance leg)"
# Mutation that makes G12a red: drop the post-resolution re-set of
# CONTEXT_LOCK_STALE_SECS (leave the exported copy holding the per-item
# file's value) — the --bg successor inherits the per-item value as explicit
# env, which outranks the global file inside context-budget.sh (split oracle).
rm -f "$SESS"/*.json "$LOCKF" "$TMP/work/testproj/.session-seq" "$TMP/child-env.txt"
printf 'CONTEXT_LOCK_STALE_SECS=1\n' > "$TMP/work/testproj/context-budget.env"
mk_record claude sid-old testproj
cat > "$TMP/bin/claude" <<STUB
#!/usr/bin/env bash
echo "STALE=\${CONTEXT_LOCK_STALE_SECS:-unset}" > "$TMP/child-env.txt"
jq -n '{runtime:"claude", session_id:"sid-new", artifact:"/dev/null",
        project:"testproj", registered_at:"2026-08-05T00:00:01Z"}' \
  > "$SESS/claude-sid-new.json"
STUB
chmod +x "$TMP/bin/claude"
out=$(PATH="$TMP/bin:$PATH" ROLLOVER_CONFIRM_SECS=10 \
  run_lns CLAUDE_CODE_SESSION_ID=sid-old CONTEXT_LOCK_STALE_SECS=7777 \
  "$LNS" testproj --bg 2>&1); rc=$?
assert_eq "G12a: successor sees the launcher's resolved value" \
  "$(grep -o 'STALE=[0-9a-z]*' "$TMP/child-env.txt" 2>/dev/null)" "STALE=7777"
rm -f "$TMP/work/testproj/context-budget.env" "$TMP/child-env.txt" "$SESS"/*.json \
  "$TMP/work/testproj/.session-seq"

echo "H: runtime-conditioned refusals are decided PRE-bump (s15 follow-on (a))"
# RUNTIME resolves before the counter bump, so the three refusals that depend
# on it (--clear claude-only, --bg claude-only, unknown runtime) must be
# decided in the pre-bump refusal zone: a refusal costs no side effects — no
# counter bump, no seed, no lock release, no superseded stamp.

echo "H1: --clear on a non-claude runtime — refused with no side effects"
rm -f "$SESS"/*.json "$LOCKF" "$SEEDF" "$TMP/work/testproj/.session-seq"
out=$(run_lns "$LNS" testproj --runtime codex --clear </dev/null 2>&1); rc=$?
assert_eq       "H1a: exit 3"          "$rc" "3"
assert_contains "H1b: claude-only"     "$out" "claude-only"
# Mutation that makes H1c red: move the --clear claude-only die back below
# the counter bump (the pre-hoist placement in the --clear block).
[ ! -f "$TMP/work/testproj/.session-seq" ] \
  && ok "H1c: refusal leaves .session-seq untouched" \
  || bad "H1c: refusal bumped the counter"
# Mutation that makes H1d red: move the die below the seed write.
[ ! -f "$SEEDF" ] && ok "H1d: no seed written" || bad "H1d: refusal seeded"

echo "H2: --bg on a non-claude runtime — refused with no side effects"
rm -f "$SESS"/*.json "$TMP/work/testproj/.session-seq"
mklock claude sid-old
out=$(run_lns "$LNS" testproj --runtime codex --bg </dev/null 2>&1); rc=$?
assert_eq       "H2a: exit 3"          "$rc" "3"
assert_contains "H2b: claude-only"     "$out" "claude-only"
# Mutation that makes H2c red: move the --bg claude-only die back below the
# counter bump (the pre-hoist placement after the BG-derivation assignments).
[ ! -f "$TMP/work/testproj/.session-seq" ] \
  && ok "H2c: refusal leaves .session-seq untouched" \
  || bad "H2c: refusal bumped the counter"
# Mutation that makes H2d red: move the die below the pre-launch lock release.
[ -f "$LOCKF" ] && ok "H2d: lock untouched" || bad "H2d: refusal released the lock"

echo "H3: unknown runtime — refused with no side effects"
rm -f "$SESS"/*.json "$TMP/work/testproj/.session-seq" "$LOCKF"
mk_record claude sid-old testproj
mklock claude sid-old
out=$(run_lns CLAUDE_CODE_SESSION_ID=sid-old "$LNS" testproj --runtime bogus </dev/null 2>&1); rc=$?
assert_eq       "H3a: exit 3"              "$rc" "3"
assert_contains "H3b: names the runtime"   "$out" "unknown runtime: bogus"
# Mutation that makes H3c red: drop the pre-bump valid-runtime enumeration and
# fall back to the launch case statement's `*)` die (the pre-hoist placement,
# which sat below the bump, the lock release, and the superseded stamp).
[ ! -f "$TMP/work/testproj/.session-seq" ] \
  && ok "H3c: refusal leaves .session-seq untouched" \
  || bad "H3c: refusal bumped the counter"
# Mutation that makes H3d red: same as H3c (the old `*)` die sat below the
# pre-launch lock release, so the refusal destroyed the caller's own lock).
[ -f "$LOCKF" ] && ok "H3d: lock untouched" || bad "H3d: refusal released the lock"
# Mutation that makes H3e red: same as H3c (the old placement also stamped the
# dying session's record superseded before refusing to launch anything).
assert_eq "H3e: record not stamped superseded" \
  "$(jq -r '.role // "none"' "$SESS/claude-sid-old.json")" "none"
rm -f "$SESS"/*.json "$LOCKF" "$TMP/work/testproj/.session-seq"

echo; echo "passed=$PASS failed=$FAIL"
[ "$FAIL" -eq 0 ]
