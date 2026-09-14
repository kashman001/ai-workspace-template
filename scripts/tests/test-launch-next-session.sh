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
# context-budget.sh travels with the launcher: the live-supervisor guard
# (S-series) shells out to its `supervised` query rather than re-implementing
# the detector, so the fixture must carry both halves.
cp "$SRC_ROOT/scripts/context-budget.sh" "$TMP/scripts/" 2>/dev/null || true
chmod +x "$TMP/scripts/"*.sh
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
run_lns() { env -u CLAUDE_CODE_SESSION_ID -u CODEX_THREAD_ID -u OPENCODE_SESSION_ID \
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

# D17 note: gemini is now IN the env table (its id is the constant "workspace"),
# so this case resolves through the env leg, not the fallback. It still pins
# what it always pinned -- runtime resolved from the record rather than from
# ROLLOVER_RUNTIME. G6 and D17h are the fallback's own tests.
echo "T3: no exported session id — the record for this project resolves the runtime"
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
# Remediation is --unstage, not a hand-run seq-sync: e778de0 replaced the
# manual rewind after the 2026-09-03 cm_bugs incident, where seq-sync being a
# separate step from clearing the seed is exactly what got missed.
assert_contains "T23i: remediation names --unstage"  "$out" "launch-next-session.sh testproj --unstage"
assert_not_contains "T23j: refusal launches nothing" "$out" "cmd: claude"
assert_contains "T23j2: evidence label shown"       "$out" "t23-work"
rm -f "$TMP/.context-budget/context-ledger.jsonl"

# Counter more than one ahead: NOT the staged-bump signature, so neither the
# reclaim heuristic nor --unstage applies and the neutral branch must name the
# explicit seq-sync repair. (Untested until 2026-09-11 — T23i used to assert
# this string against the one-ahead branch, which stopped producing it in
# e778de0.)
printf '12\n' > "$TMP/work/testproj/.session-seq"
out=$(run_lns "$LNS" testproj --runtime claude --dry-run 2>&1); rc=$?
assert_eq       "T23i2: two-ahead -> exit 3"          "$rc" "3"
assert_contains "T23i3: neutral branch, not unstage"  "$out" "launch does the +1"
assert_contains "T23i4: remediation names seq-sync"   "$out" "seq-sync --project testproj --session 9"

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

echo "U: --unstage — atomic abandon of a staged-but-never-started successor"
# The rewind delegates to seq-sync (the counter's single writer, ADR-0008),
# so the fixture needs context-budget.sh beside the launcher.
cp "$SRC_ROOT/scripts/context-budget.sh" "$TMP/scripts/"
printf '# Session Handoff — 2026-08-20 (session 9: a ledger block)\n' > "$HF"
printf '10\n' > "$TMP/work/testproj/.session-seq"
printf 'seeded prompt\n' > "$TMP/work/testproj/.pending-clear-seed"

# Dry-run previews and mutates nothing.
out=$(run_lns "$LNS" testproj --unstage --dry-run 2>&1); rc=$?
assert_eq       "U1a: dry-run exit 0"            "$rc" "0"
assert_contains "U1b: removal previewed"         "$out" "would remove"
assert_contains "U1c: rewind previewed"          "$out" "would rewind"
assert_eq "U1d: seed untouched"   "$(cat "$TMP/work/testproj/.pending-clear-seed")" "seeded prompt"
assert_eq "U1e: counter untouched" "$(cat "$TMP/work/testproj/.session-seq")" "10"

# Real run: seed removed AND counter rewound in the one command.
out=$(run_lns "$LNS" testproj --unstage 2>&1); rc=$?
assert_eq       "U2a: unstage exit 0"            "$rc" "0"
assert_contains "U2b: seed removal announced"    "$out" "unstage: removed"
assert_eq "U2c: seed gone"      "$(test -f "$TMP/work/testproj/.pending-clear-seed" && echo present || echo gone)" "gone"
assert_eq "U2d: counter rewound to ledger" "$(cat "$TMP/work/testproj/.session-seq")" "9"
out=$(run_lns "$LNS" testproj --runtime claude --dry-run 2>&1); rc=$?
assert_eq       "U2e: launch passes after repair" "$rc" "0"
assert_contains "U2f: successor number reused"    "$out" "rollover session #10"

# Nothing staged: refuse loudly rather than report a repair that did nothing.
out=$(run_lns "$LNS" testproj --unstage 2>&1); rc=$?
assert_eq       "U3a: nothing staged -> exit 3"  "$rc" "3"
assert_contains "U3b: says so"                   "$out" "nothing staged"

# Counter beyond one-ahead is NOT staging debris: files are removed but the
# rewind is refused and the explicit seq-sync remedy named.
printf '12\n' > "$TMP/work/testproj/.session-seq"
printf 'stale\n' > "$TMP/work/testproj/.next-command"
out=$(run_lns "$LNS" testproj --unstage 2>&1); rc=$?
assert_eq       "U4a: files removed -> exit 0"    "$rc" "0"
assert_contains "U4b: rewind refused"             "$out" "refusing to rewind"
assert_eq "U4c: counter untouched" "$(cat "$TMP/work/testproj/.session-seq")" "12"
assert_eq "U4d: staged command gone" "$(test -f "$TMP/work/testproj/.next-command" && echo present || echo gone)" "gone"

# Contradictory modes are refused at parse time.
for bad in "--clear" "--emit /tmp/x" "--bg"; do
  # shellcheck disable=SC2086
  out=$(run_lns "$LNS" testproj --unstage $bad 2>&1); rc=$?
  assert_eq "U5: --unstage $bad refused" "$rc" "3"
done

# Fingerprint diagnosis: one-ahead where ALL post-staging evidence is
# rollover bookkeeping (a "rollover complete" record + commits touching only
# work/<project>/, clean tree) = the predecessor resumed under a new
# transcript id and finished its own rollover; the staged session never ran.
# The refusal must lead with that diagnosis and name --unstage. Git evidence
# needs a repo and $TMP must stay non-git — isolated mini-workspace.
EVU="$(mktemp -d)"
mkdir -p "$EVU/scripts" "$EVU/work/testproj" "$EVU/.context-budget/sessions"
cp "$SRC_ROOT/scripts/launch-next-session.sh" "$SRC_ROOT/scripts/context-budget.sh" "$EVU/scripts/"
printf 'ROLLOVER_RELAUNCH=manual\nROLLOVER_RUNTIME=claude\n' > "$EVU/context-budget.env"
printf '.context-budget/\n.session-seq*\n.pending-clear-seed\n.next-command\n' > "$EVU/.gitignore"
echo "# launcher" > "$EVU/work/testproj/next-session.md"
printf '# Session Handoff — 2026-08-20 (session 9: a ledger block)\n' \
  > "$EVU/work/testproj/handoff.md"
git -C "$EVU" init -q
git -C "$EVU" add -A >/dev/null 2>&1
GIT_COMMITTER_DATE="2019-01-01T00:00:00Z" git -C "$EVU" -c user.email=t@t -c user.name=t \
  commit -qm "init" --date "2019-01-01T00:00:00Z" >/dev/null 2>&1
printf '10\n' > "$EVU/work/testproj/.session-seq"
touch -t 202001010100 "$EVU/work/testproj/.session-seq"
printf '{"ts":"%s","label":"rollover complete: testproj (fresh-process handoff)"}\n' \
  "$(date -u +%FT%TZ)" > "$EVU/.context-budget/context-ledger.jsonl"
echo "# launcher v2" > "$EVU/work/testproj/next-session.md"
git -C "$EVU" add work/testproj/next-session.md >/dev/null 2>&1
git -C "$EVU" -c user.email=t@t -c user.name=t commit -qm "rollover finalized" >/dev/null 2>&1
out=$(run_lns "$EVU/scripts/launch-next-session.sh" testproj --runtime claude --dry-run 2>&1); rc=$?
assert_eq       "U6a: fingerprint still refuses"     "$rc" "3"
assert_contains "U6b: resumed-predecessor diagnosis" "$out" "resumed under a NEW transcript id"
assert_contains "U6c: --unstage is the remedy"       "$out" "launch-next-session.sh testproj --unstage"
# Mixed evidence (a commit outside work/<project>) falls back to the neutral
# reconstruct-first message.
echo x > "$EVU/other.txt"
git -C "$EVU" add other.txt >/dev/null 2>&1
git -C "$EVU" -c user.email=t@t -c user.name=t commit -qm "unrelated work" >/dev/null 2>&1
out=$(run_lns "$EVU/scripts/launch-next-session.sh" testproj --runtime claude --dry-run 2>&1); rc=$?
assert_eq       "U6d: mixed evidence still refuses"  "$rc" "3"
assert_contains "U6e: neutral reconstruct guidance"  "$out" "Reconstruct"
# --unstage repairs the halted chain end-to-end.
out=$(run_lns "$EVU/scripts/launch-next-session.sh" testproj --unstage 2>&1); rc=$?
assert_eq "U6f: unstage repairs -> exit 0" "$rc" "0"
assert_eq "U6g: counter rewound" "$(cat "$EVU/work/testproj/.session-seq")" "9"
out=$(run_lns "$EVU/scripts/launch-next-session.sh" testproj --runtime claude --dry-run 2>&1); rc=$?
assert_eq "U6h: launch passes after repair" "$rc" "0"
rm -rf "$EVU"

# C-series must inherit nothing from U. context-budget.sh is deliberately NOT
# removed: it is fixture-wide setup (see the top of this file), and the later
# S-series shells out to its `supervised` query — deleting it here left every
# S assertion failing on a missing-file warning instead of the guard's verdict.
rm -f "$TMP/work/testproj/.session-seq" "$TMP/work/testproj/.session-seq.provenance.json" "$HF"

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
assert_contains "C2g: rewind hint is exact"     "$out" "launch-next-session.sh testproj --unstage"
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

echo "S: the live-supervisor guard — a supervised chain may be STAGED, never launched (D6)"
# Round 2 D6. The supervisor runs its child in the foreground and waits on it;
# a launcher invocation that starts a session out-of-band leaves the supervisor
# blocked on a child that will never exit while the real work continues in a
# session it cannot see. Measured three times on live chains 2026-09-10.
# The refusal rests on POSITIVE evidence only (supervised exit 0); ambiguity
# warns and proceeds (design.md R2.3).
LOOPF="$TMP/work/testproj/.session-loop"
SEQF2="$TMP/work/testproj/.session-seq"
mk_marker() {  # $1 = pid to record as the supervisor
  printf '{"pid":%s,"project":"testproj","started_at":"2026-09-10T00:00:00Z"}\n' "$1" > "$LOOPF"
}
# A pid that is reliably NOT alive: start a process and reap it.
( exec true ) & DEADPID=$!; wait "$DEADPID" 2>/dev/null || true
s_reset() { rm -f "$SESS"/*.json "$LOCKF" "$SEEDF" "$SEQF2" "$LOOPF" "$EMITF2"; }
EMITF2="$TMP/work/testproj/.next-command"

echo "S1: live supervisor + bare launch — refused, with no side effects"
s_reset; mk_marker $$; mk_record claude sid-old testproj; mklock claude sid-old
out=$(run_lns "$LNS" testproj --runtime claude </dev/null 2>&1); rc=$?
assert_eq       "S1a: exit 3"                  "$rc" "3"
assert_contains "S1b: names the condition"     "$out" "supervisor is live"
assert_contains "S1c: points at the remedy"    "$out" "--emit"
# Mutation that makes S1d red: move the guard below the counter bump — the
# refusal would then consume a sequence number and produce the very delta != 1
# halt it exists to prevent.
[ ! -f "$SEQF2" ] && ok "S1d: refusal leaves .session-seq untouched" \
                  || bad "S1d: refusal bumped the counter"
[ -f "$LOCKF" ] && ok "S1e: lock untouched" || bad "S1e: refusal released the lock"
assert_eq "S1f: record not stamped superseded" \
  "$(jq -r '.role // "none"' "$SESS/claude-sid-old.json")" "none"

echo "S2: live supervisor + --emit — allowed; staging is the correct action"
# The session record is not decoration here (R2.17 section 1): under a live
# supervisor the launcher refuses to bump without an identity, because the bump
# record IS the rollover verdict and one with no session_id cannot be matched to
# the session that wrote it. A registered session always has this file.
# D17: the record alone is not identity -- the session must be able to name
# itself, which a real claude session does by exporting CLAUDE_CODE_SESSION_ID.
# Before D17's fix this fixture passed on the record alone, which is the hole.
s_reset; mk_marker $$; mk_record claude sid-emit testproj; printf '7\n' > "$SEQF2"
out=$(run_lns CLAUDE_CODE_SESSION_ID=sid-emit "$LNS" testproj --runtime claude --emit "$EMITF2" </dev/null 2>&1); rc=$?
assert_eq "S2a: exit 0"           "$rc" "0"
assert_eq "S2b: counter bumped"   "$(cat "$SEQF2" 2>/dev/null)" "8"
[ -s "$EMITF2" ] && ok "S2c: command staged" || bad "S2c: nothing staged at $EMITF2"

echo "S3: live supervisor + --dry-run — allowed; it starts nothing and mutates nothing"
s_reset; mk_marker $$
out=$(run_lns "$LNS" testproj --runtime claude --dry-run </dev/null 2>&1); rc=$?
assert_eq "S3a: exit 0" "$rc" "0"
[ ! -f "$SEQF2" ] && ok "S3b: dry-run still mutates nothing" \
                  || bad "S3b: dry-run bumped the counter"

echo "S4: live supervisor + --clear — refused (the successor is this pid, which never exits)"
s_reset; mk_marker $$
out=$(run_lns "$LNS" testproj --runtime claude --clear </dev/null 2>&1); rc=$?
assert_eq       "S4a: exit 3"              "$rc" "3"
assert_contains "S4b: names the condition" "$out" "supervisor is live"
[ ! -f "$SEEDF" ] && ok "S4c: no seed written" || bad "S4c: refusal seeded"
[ ! -f "$SEQF2" ] && ok "S4d: counter untouched" || bad "S4d: refusal bumped the counter"

echo "S5: live supervisor + --unstage — not refused by this guard (it rewinds, it launches nothing)"
s_reset; mk_marker $$
out=$(run_lns "$LNS" testproj --runtime claude --unstage </dev/null 2>&1); rc=$?
assert_not_contains "S5a: guard did not fire" "$out" "supervisor is live"

echo "S6: STALE marker (dead pid) + bare launch — allowed with a warning, not refused"
# The recovery path for a forked chain runs exactly here. Refusing would block
# the repair, and the only remedy available to the caller would be deleting a
# marker context-budget.sh:780 forbids agents to delete (design.md R2.3).
s_reset; mk_marker "$DEADPID"
out=$(run_lns "$LNS" testproj --runtime gemini </dev/null 2>&1); rc=$?
assert_eq           "S6a: exit 0"            "$rc" "0"
assert_not_contains "S6b: not refused"       "$out" "supervisor is live"
assert_contains     "S6c: warns about the marker" "$out" "warning"

echo "S7: TF_SESSION_LOOP_PROJECT with no marker — ambiguous; allowed with a warning"
s_reset
out=$(TF_SESSION_LOOP_PROJECT=testproj run_lns "$LNS" testproj --runtime gemini </dev/null 2>&1); rc=$?
assert_eq           "S7a: exit 0"       "$rc" "0"
assert_not_contains "S7b: not refused"  "$out" "supervisor is live"
assert_contains     "S7c: warns"        "$out" "warning"

echo "S8: no marker at all — the unsupervised path is unchanged and silent"
s_reset
out=$(run_lns "$LNS" testproj --runtime gemini </dev/null 2>&1); rc=$?
assert_eq           "S8a: exit 0"          "$rc" "0"
assert_not_contains "S8b: not refused"     "$out" "supervisor is live"
assert_not_contains "S8c: no stray warning" "$out" "supervisor"
s_reset

echo "S9-S12: R2.12/R2.13 — the daemon-launch condition is also the fork-RECOVERY condition"
# R2.12: a bare launch that would have backgrounded (mode=auto + runtime=claude
# + no --emit) STAGES instead when a supervisor marker is present, so recovery
# ends in one supervised foreground session rather than a fresh detached holder
# whose lock blocks the supervisor bootstrap (D8 again, one turn later).
# R2.13: --dry-run resolves BG under the same conditions, so it stops printing a
# runnable --bg recipe for the action the guard next to it exists to refuse.
#
# Mutations that make these red: drop the SUP_RC check from the BG derivation
# (S9/S12 go back to bg=1); make --dry-run skip the detector again (S11/S12);
# set EMIT for --dry-run too (S11d/S12d — dry-run must mutate nothing).
# The --bg assertions read the `cmd:` LINE, not the whole output: the dry-run
# note deliberately contains the literal "(no --bg)" for the human reading it.
printf 'ROLLOVER_RELAUNCH=auto\nROLLOVER_RUNTIME=claude\n' > "$TMP/context-budget.env"

echo "S9: STALE marker + bare launch (auto+claude) — stages, spawns nothing"
s_reset; mk_marker "$DEADPID"; mk_record claude sid-r212 testproj; printf '4\n' > "$SEQF2"
out=$(run_lns "$LNS" testproj --runtime claude </dev/null 2>&1); rc=$?
assert_eq           "S9a: exit 0"                "$rc" "0"
assert_contains     "S9b: did not background"    "$out" "bg=0"
assert_contains     "S9c: says it staged"        "$out" "staging to work/testproj/.next-command"
assert_contains     "S9d: names the reason"      "$out" "pid is not alive"
[ -s "$EMITF2" ] && ok "S9e: command staged" || bad "S9e: nothing staged at $EMITF2"
assert_not_contains "S9f: staged line has no --bg" "$(cat "$EMITF2" 2>/dev/null)" "--bg"
assert_eq           "S9g: counter bumped"        "$(cat "$SEQF2" 2>/dev/null)" "5"

echo "S10: no marker + --dry-run (auto+claude) — genuinely unsupervised, still backgrounds"
s_reset
out=$(run_lns "$LNS" testproj --runtime claude --dry-run </dev/null 2>&1); rc=$?
assert_eq       "S10a: exit 0"           "$rc" "0"
assert_contains "S10b: bg=1"             "$out" "bg=1"
assert_contains "S10c: --bg in the cmd"  "$(printf '%s\n' "$out" | grep '^cmd: ')" "--bg"

echo "S11: LIVE supervisor + --dry-run — prints the staging form, not a --bg recipe"
s_reset; mk_marker $$
out=$(run_lns "$LNS" testproj --runtime claude --dry-run </dev/null 2>&1); rc=$?
assert_eq           "S11a: exit 0"                 "$rc" "0"
assert_contains     "S11b: bg=0"                   "$out" "bg=0"
assert_not_contains "S11c: no --bg to paste"       "$(printf '%s\n' "$out" | grep '^cmd: ')" "--bg"
[ ! -f "$SEQF2" ] && ok "S11d: still mutates nothing" || bad "S11d: dry-run bumped the counter"
[ ! -f "$EMITF2" ] && ok "S11e: staged nothing"      || bad "S11e: dry-run staged a command"
assert_contains     "S11f: explains what a real launch would do" "$out" "would STAGE"

echo "S12: STALE marker + --dry-run — same staging form, for R2.12's reason"
s_reset; mk_marker "$DEADPID"
out=$(run_lns "$LNS" testproj --runtime claude --dry-run </dev/null 2>&1); rc=$?
assert_eq           "S12a: exit 0"              "$rc" "0"
assert_contains     "S12b: bg=0"                "$out" "bg=0"
assert_not_contains "S12c: no --bg to paste"    "$(printf '%s\n' "$out" | grep '^cmd: ')" "--bg"
[ ! -f "$SEQF2" ] && ok "S12d: still mutates nothing" || bad "S12d: dry-run bumped the counter"
assert_contains     "S12e: names the dead pid"  "$out" "pid is not alive"

printf 'ROLLOVER_RELAUNCH=manual\nROLLOVER_RUNTIME=claude\n' > "$TMP/context-budget.env"
s_reset

# ---------------------------------------------------------------------------
# D17 (work/session-loop-hardening/defects.md) — the supervised identity
# refusal above keyed on $REC, which own_record() resolves by falling back to
# the NEWEST record claiming this project when no env identity matches. That
# fallback is documented at its own definition as "a HINT for runtime
# resolution and logging only; it grants and denies nothing" — but the refusal
# read it, so it granted. A session that never registered, rolling over under a
# supervisor on a work item with ANY prior session record, passed the check and
# stamped the bump with a stranger's runtime/session_id. The supervisor then
# reads identity off that bump and the self-kill hook compares it to the live
# session's, so neither ever matches: the chain runs to its cap, silently,
# which is precisely the degradation R2.17 §1 exists to refuse.
#
# The refusal now keys on $OWN_ENV_REC — positive identity, an exported session
# id with a registry record under that exact id. $REC keeps doing runtime
# resolution and logging, where its own comment says it belongs.
#
# The tightening is only safe because env_session_record() was widened to the
# same SIX runtimes context-budget.sh session_id_for() covers (it carried four;
# design.md flagged the four-vs-six drift in session 25 and R2.17 §1 worked
# around it by widening own_record instead). opencode exports
# OPENCODE_SESSION_ID and registers under it, so it has real positive identity
# and keeps its chain; gemini's id is the constant "workspace", which is
# workspace-scoped rather than per-session — the strongest identity gemini has,
# and the same one context-budget.sh already registers it under.
#
# Mutation that makes D17a-d red: key the refusal on $REC again.
# Mutation that makes D17f/D17g red: drop the opencode/gemini rows from
# env_session_record() — those runtimes lose supervised rollover entirely.
# ---------------------------------------------------------------------------
echo "D17: the supervised identity refusal keys on POSITIVE identity, not on the newest record"
s_reset; mk_marker $$; mk_record claude sid-stranger testproj; printf '7\n' > "$SEQF2"
out=$(run_lns "$LNS" testproj --runtime claude --emit "$EMITF2" </dev/null 2>&1); rc=$?
assert_eq       "D17a: refused — a record this session cannot prove is its own grants nothing" "$rc" "3"
assert_contains "D17b: the refusal names the remedy" "$out" "register --project testproj"
assert_eq       "D17c: the refusal cost no counter bump" "$(cat "$SEQF2")" "7"
assert_eq       "D17d: and staged nothing" \
                "$([ -s "$EMITF2" ] && echo staged || echo none)" "none"

echo "D17e: the same session WITH its exported id is allowed, and stages"
s_reset; mk_marker $$; mk_record claude sid-own testproj; printf '7\n' > "$SEQF2"
out=$(run_lns CLAUDE_CODE_SESSION_ID=sid-own "$LNS" testproj --emit "$EMITF2" </dev/null 2>&1); rc=$?
assert_eq "D17e1: exit 0"         "$rc" "0"
assert_eq "D17e2: counter bumped" "$(cat "$SEQF2")" "8"
[ -s "$EMITF2" ] && ok "D17e3: command staged" || bad "D17e3: nothing staged at $EMITF2"

echo "D17f: opencode exports OPENCODE_SESSION_ID and registers under it — it keeps its chain"
# The population the tightening could have cost. R2.17 §1 widened own_record()
# for it on the belief that it had no env session id; context-budget.sh:390 and
# :346 show it does, and `register` names the record opencode-$OPENCODE_SESSION_ID.json.
s_reset; mk_marker $$; mk_record opencode oc-1 testproj; printf '7\n' > "$SEQF2"
out=$(run_lns OPENCODE_SESSION_ID=oc-1 "$LNS" testproj --emit "$EMITF2" </dev/null 2>&1); rc=$?
assert_eq "D17f1: exit 0"           "$rc" "0"
assert_eq "D17f2: counter bumped"   "$(cat "$SEQF2")" "8"
assert_eq "D17f3: the bump carries opencode's own id, not a stranger's" \
          "$(jq -r '.session_id' "$TMP/work/testproj/.session-seq.bump.json" 2>/dev/null)" "oc-1"

echo "D17g: gemini's constant id is the strongest identity it has, and it counts"
# session_id_for() registers every gemini session as gemini-workspace (no
# per-session identity exists for that runtime). Workspace-scoped, not
# session-scoped — accepted deliberately: refusing it instead would end gemini's
# supervised chains, and every other reader in the chain already keys on the
# same constant.
s_reset; mk_marker $$; mk_record gemini workspace testproj; printf '7\n' > "$SEQF2"
out=$(run_lns "$LNS" testproj --runtime gemini --emit "$EMITF2" </dev/null 2>&1); rc=$?
assert_eq "D17g1: exit 0"         "$rc" "0"
assert_eq "D17g2: counter bumped" "$(cat "$SEQF2")" "8"

echo "D17h: a stranger's record still resolves the RUNTIME — the fallback keeps its real job"
# The fix removes the fallback's authority, not the fallback. G6 is the same
# argument for the lock-release path.
s_reset; mk_record codex th-hint testproj
out=$(run_lns "$LNS" testproj --dry-run 2>&1)
assert_contains "D17h1: runtime still resolved from the project record" "$out" "runtime=codex"
s_reset

echo "K: D8/R2.10 — the live-lock refusal names the holding PROCESS, or says why it cannot"
# The refusal itself is G1's business; H pins what R2.10 added to it. Mutations
# that make these red: K2 — report .pid without re-checking pid_start (K2a goes
# green on a recycled pid); K3 — drop the supervisor lookup (K3a stops
# distinguishing the supervised holder from the orphan, which is the whole
# diagnosis D8 exists to deliver); K1 — report a pid when none was recorded.
cd "$TMP"
mklock_pid() {  # $1=runtime $2=sid $3=pid $4=pid_start $5=supervisor_pid ("" to omit)
  jq -n --arg rt "$1" --arg sid "$2" --argjson pid "$3" --arg ps "$4" --arg sup "$5" \
    '{runtime:$rt, session_id:$sid, project:"testproj", acquired_at:"2026-08-05T00:00:00Z",
      pid:$pid, pid_start:$ps} + (if $sup == "" then {} else {supervisor_pid:($sup|tonumber)} end)' \
    > "$LOCKF"
}
refuse() {  # run the launcher as a positively-identified non-holder; echo its output
  run_lns CLAUDE_CODE_SESSION_ID=sid-aux "$LNS" testproj --runtime claude </dev/null 2>&1
}
h_reset() { rm -f "$SESS"/*.json "$TMP/work/testproj/.session-seq"
  rm -rf "$TMP/work/testproj/.agent-locks"
  mk_live_record claude sid-primary testproj primary
  mk_live_record claude sid-aux testproj auxiliary; }

echo "K1: no pid in the lock — say so, do not invent one"
h_reset; mklock claude sid-primary
out=$(refuse)
assert_contains "K1a: refusal still fires" "$out" "refusing to release another session's live lock"
assert_contains "K1b: absence stated plainly" "$out" "records no pid"
assert_not_contains "K1c: no pid claimed"    "$out" "The holder is pid"

echo "K2: a recorded pid that is gone, or whose start time no longer matches, is SUPPRESSED"
# A dead pid. `kill -0` on it must fail for the fixture to mean anything.
h_reset
# A pid that is certainly dead: start one, reap it, reuse its number.
sleep 0.1 >/dev/null 2>&1 & dead=$!
wait "$dead" 2>/dev/null
mklock_pid claude sid-primary "$dead" "Tue Aug  5 00:00:00 2026" ""
out=$(refuse)
assert_contains "K2a: dead pid named as gone" "$out" "gone or has been reused"
assert_contains "K2b: recorded start shown"   "$out" "Tue Aug  5 00:00:00 2026"
assert_not_contains "K2c: not reported as a live holder" "$out" "The holder is pid"
# Same assertion for the recycled-pid shape: the pid IS live, the start disagrees.
sleep 600 >/dev/null 2>&1 & live=$!
mklock_pid claude sid-primary "$live" "Tue Aug  5 00:00:00 2026" ""
out=$(refuse)
assert_contains "K2d: live pid with a mismatched start is suppressed, not named" \
  "$out" "gone or has been reused"

echo "K3: a live holder — supervised says where to go, unsupervised says what to end"
h_reset
mkdir -p "$TMP/fakesup"
cat > "$TMP/fakesup/session-loop.sh" <<'EOS'
#!/usr/bin/env bash
sleep 600
EOS
bash "$TMP/fakesup/session-loop.sh" >/dev/null 2>&1 & sup=$!
lstart=$(ps -o lstart= -p "$live" 2>/dev/null | sed 's/^ *//;s/ *$//')
mklock_pid claude sid-primary "$live" "$lstart" "$sup"
out=$(refuse)
assert_contains "K3a: supervised holder points at the supervisor" "$out" "supervised by session-loop.sh pid $sup"
assert_not_contains "K3b: does not tell the operator to kill a supervised session" "$out" "kill $live"
# Same live holder, no supervisor: this is the shape that strands a chain.
mklock_pid claude sid-primary "$live" "$lstart" ""
out=$(refuse)
assert_contains "K3c: orphan named as such"      "$out" "NO supervisor is running it"
assert_contains "K3d: and given a concrete exit" "$out" "kill $live"
kill "$live" "$sup" 2>/dev/null; wait "$live" "$sup" 2>/dev/null
rm -f "$LOCKF"

# ---------------------------------------------------------------------------
# CL: P6 — the launcher half of the .chain-closed gate (scenario table B2).
# The supervisor carries its own copy of this gate, but it cannot be the only
# one: an UNSUPERVISED rollover never runs session-loop.sh, so without a read
# here the next session to roll over into a closed work item reopens it.
#
# Mutation: delete the CLOSEDF block from launch-next-session.sh -> CL1a-CL1c red.
# ---------------------------------------------------------------------------
echo "CL1: the launcher refuses to stage a successor into a closed chain"
CLOSEDF="$TMP/work/testproj/.chain-closed"
printf '{"seq":8,"closed_at":"2026-09-13T00:00:00Z","top_ledger_seq":"","written_by":"session-loop.sh"}\n' > "$CLOSEDF"
out=$(run_lns "$LNS" testproj --dry-run 2>&1); rc=$?
assert_eq       "CL1a: refused with the launcher's refusal status" "$rc" "3"
assert_contains "CL1b: it names the marker file"     "$out" ".chain-closed"
assert_contains "CL1c: it names the session that closed the chain" "$out" "session #8"
assert_contains "CL1d: it names the explicit reopen" "$out" "--reopen"
assert_contains "CL1e: and says nothing was staged"  "$out" "Nothing has been staged"
# The gate is a plain file test, so removing the marker restores the previous
# behaviour exactly — no residue, which is what makes --reopen a complete undo.
rm -f "$CLOSEDF"
out=$(run_lns "$LNS" testproj --dry-run 2>&1); rc=$?
assert_eq       "CL1f: with no marker the launcher is unaffected" "$rc" "0"

echo; echo "passed=$PASS failed=$FAIL"
[ "$FAIL" -eq 0 ]
