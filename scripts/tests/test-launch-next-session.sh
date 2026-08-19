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

echo "T17: a lock held by ANOTHER session is left in place"
mklock claude sid-other
out=$(run_lns CLAUDE_CODE_SESSION_ID=sid-old "$LNS" testproj --runtime claude </dev/null 2>&1)
[ -f "$LOCKF" ] && ok "T17a: foreign lock kept" || bad "T17a: foreign lock removed"
assert_contains "T17b: foreign holder noted" "$out" "not this session"

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

echo "W6: stranded worktree .session-seq — numeric max across checkouts wins (state-sync)"
printf '27\n' > "$GMAIN/work/testproj/.session-seq"
printf '29\n' > "$GMAIN/wt/work/testproj/.session-seq"
out=$(run_lns "$WLNS" testproj --dry-run 2>&1 </dev/null); rc=$?
assert_eq       "W6a: exit 0" "$rc" "0"
assert_contains "W6b: successor numbered from the worktree copy" "$out" "rollover session #30"
assert_contains "W6c: adoption noted" "$out" "session-seq: adopting 29"
out=$(run_lns "$WLNS" testproj 2>&1 </dev/null)
assert_eq "W6d: real run persists max+1 in main root" \
  "$(cat "$GMAIN/work/testproj/.session-seq")" "30"
assert_eq "W6e: worktree copy left alone" \
  "$(cat "$GMAIN/wt/work/testproj/.session-seq")" "29"
out=$(run_lns "$GMAIN/scripts/launch-next-session.sh" testproj --dry-run 2>&1 </dev/null)
assert_contains "W6f: main-checkout invocation reconciles too" "$out" "rollover session #31"
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

echo; echo "passed=$PASS failed=$FAIL"
[ "$FAIL" -eq 0 ]
