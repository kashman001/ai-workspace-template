#!/usr/bin/env bash
# File: scripts/tests/test-statusline-context-budget.sh
# Purpose: Regression tests for statusline-context-budget.sh (work-item role
#          display). Self-contained: throwaway workspace in mktemp -d; the
#          statusline input JSON is fed on stdin as Claude Code does.
set -u
SRC_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/scripts" "$TMP/work/testproj" "$TMP/work/context-decay" \
  "$TMP/.context-budget/sessions" "$TMP/home/.claude"
export HOME="$TMP/home"   # isolate from the real user's global statusLine
cp "$SRC_ROOT/scripts/statusline-context-budget.sh" "$TMP/scripts/" 2>/dev/null || true
SL="$TMP/scripts/statusline-context-budget.sh"
SESS="$TMP/.context-budget/sessions"
LOCK="$TMP/work/testproj/.active-session"

PASS=0; FAIL=0
ok()   { PASS=$((PASS+1)); echo "  ok: $1"; }
bad()  { FAIL=$((FAIL+1)); echo "  FAIL: $1" >&2; }
assert_eq() { [ "$2" = "$3" ] && ok "$1" || bad "$1 (want [$3] got [$2])"; }
assert_contains() { case "$2" in *"$3"*) ok "$1" ;; *) bad "$1 (no [$3] in [$2])" ;; esac; }

sl_input() {  # $1=session-id
  jq -n --arg sid "$1" --arg d "$TMP" \
    '{session_id:$sid, workspace:{project_dir:$d}, cwd:$d}'
}
mk_record() {  # $1=session-id $2=project $3=role ("" = none)
  jq -n --arg sid "$1" --arg p "$2" --arg role "$3" --arg af "$TMP/artifact-$1.jsonl" \
    '{runtime:"claude", session_id:$sid, artifact:$af, project:$p,
      registered_at:"2026-08-06T00:00:00Z"}
     + (if $role == "" then {} else {role:$role} end)' \
    > "$SESS/claude-$1.json"
}

echo "T1: lock holder shows PRIMARY with project"
mk_record sid-aaa testproj primary
jq -n '{runtime:"claude", session_id:"sid-aaa", project:"testproj"}' > "$LOCK"
out=$(sl_input sid-aaa | bash "$SL")
assert_contains "T1a: PRIMARY shown" "$out" "PRIMARY"
assert_contains "T1b: project shown" "$out" "testproj"

echo "T2: recorded auxiliary role shown when another session holds the lock"
mk_record sid-bbb testproj auxiliary
out=$(sl_input sid-bbb | bash "$SL")
assert_contains "T2a: AUXILIARY shown" "$out" "AUXILIARY"

echo "T3: lock beats a stale record claim (record says auxiliary, lock says me)"
jq -n '{runtime:"claude", session_id:"sid-bbb", project:"testproj"}' > "$LOCK"
out=$(sl_input sid-bbb | bash "$SL")
assert_contains "T3a: lock wins -> PRIMARY" "$out" "PRIMARY"

echo "T4: superseded record shown after rollover"
rm -f "$LOCK"
mk_record sid-aaa testproj superseded
out=$(sl_input sid-aaa | bash "$SL")
assert_contains "T4a: SUPERSEDED shown" "$out" "SUPERSEDED"

echo "T5: unregistered or item-less session degrades gracefully"
out=$(sl_input sid-zzz | bash "$SL")
assert_eq "T5a: no record -> no work item" "$out" "no work item"
mk_record sid-ccc "" ""
out=$(sl_input sid-ccc | bash "$SL")
assert_eq "T5b: no project -> no work item" "$out" "no work item"

echo "T6: context percentage from the session's newest ledger entry"
mk_record sid-aaa testproj primary
printf '%s\n' \
  '{"ts":"2026-08-06T00:00:00Z","session":"artifact-sid-aaa.jsonl","tokens":45000,"threshold":150000}' \
  '{"ts":"2026-08-06T01:00:00Z","session":"artifact-sid-aaa.jsonl","tokens":97500,"threshold":150000}' \
  '{"ts":"2026-08-06T01:00:00Z","session":"other.jsonl","tokens":30000,"threshold":150000}' \
  > "$TMP/work/context-decay/context-ledger.jsonl"
out=$(sl_input sid-aaa | bash "$SL")
assert_contains "T6a: newest own entry pct" "$out" "65%"

echo "T7: user's global statusLine is chained, not replaced"
jq -n '{statusLine:{type:"command", command:"jq -r \"\\\"BASE:\\\" + .session_id\""}}' \
  > "$HOME/.claude/settings.json"
jq -n '{runtime:"claude", session_id:"sid-aaa", project:"testproj"}' > "$LOCK"
out=$(sl_input sid-aaa | bash "$SL")
assert_contains "T7a: base output shown (stdin forwarded)" "$out" "BASE:sid-aaa"
assert_contains "T7b: budget segment appended" "$out" "PRIMARY"
assert_eq "T7c: base line first, segment last" "$(printf '%s' "$out" | tail -1)" \
  "PRIMARY · testproj · 65%"
out=$(sl_input sid-zzz | bash "$SL")
assert_eq "T7d: no work item -> base output alone, no noise" "$out" "BASE:sid-zzz"
jq -n --arg c "$SL" '{statusLine:{type:"command", command:$c}}' \
  > "$HOME/.claude/settings.json"
out=$(sl_input sid-aaa | bash "$SL")
assert_eq "T7e: self-referencing global command not recursed" "$out" \
  "PRIMARY · testproj · 65%"
rm -f "$HOME/.claude/settings.json"
out=$(sl_input sid-zzz | bash "$SL")
assert_eq "T7f: no global command + no work item -> previous behavior" "$out" "no work item"

echo "T8: session in a git worktree resolves state from the shared root (issue 05)"
GW="$(mktemp -d)"; GW="$(cd "$GW" && pwd -P)"
trap 'rm -rf "$TMP" "$GW"' EXIT
mkdir -p "$GW/scripts" "$GW/work/testproj" "$GW/.context-budget/sessions"
cp "$SRC_ROOT/scripts/statusline-context-budget.sh" "$GW/scripts/"
git -C "$GW" -c init.defaultBranch=main init -q
git -C "$GW" -c user.email=t@t -c user.name=t add -A >/dev/null
git -C "$GW" -c user.email=t@t -c user.name=t commit -qm init
git -C "$GW" worktree add -q "$GW/wt" -b wt-branch
jq -n --arg af "$GW/artifact-sid-www.jsonl" \
  '{runtime:"claude", session_id:"sid-www", artifact:$af, project:"testproj",
    registered_at:"2026-08-06T00:00:00Z", role:"primary"}' \
  > "$GW/.context-budget/sessions/claude-sid-www.json"
jq -n '{runtime:"claude", session_id:"sid-www", project:"testproj"}' \
  > "$GW/work/testproj/.active-session"
out=$(jq -n --arg d "$GW/wt" \
  '{session_id:"sid-www", workspace:{project_dir:$d}, cwd:$d}' \
  | bash "$GW/wt/scripts/statusline-context-budget.sh")
assert_contains "T8a: PRIMARY resolved through shared root" "$out" "PRIMARY"
assert_contains "T8b: project resolved through shared root" "$out" "testproj"

echo; echo "passed=$PASS failed=$FAIL"
[ "$FAIL" -eq 0 ]
