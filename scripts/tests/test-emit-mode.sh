#!/usr/bin/env bash
# File: scripts/tests/test-emit-mode.sh
# Purpose: launch-next-session.sh --emit on the session record. Golden-files the
#          emitted command against --dry-run for the five attached runtimes
#          (copilot-vscode is refused under --emit), and pins the side effects
#          --dry-run skips: the record's `staged` block, and nothing else —
#          no command file, no bump record, no counter (phase 8). Throwaway
#          git workspace; nested so the record's location (WORKSPACE_ROOT,
#          not the git root) is observable.
set -u
SRC_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TMP="$(mktemp -d)"; TMP="$(cd "$TMP" && pwd -P)"; trap 'rm -rf "$TMP"' EXIT
MAIN="$TMP/main"
mkdir -p "$MAIN/scripts/lib" "$MAIN/work/testproj" "$MAIN/.context-budget/sessions"
cp "$SRC_ROOT/scripts/launch-next-session.sh" "$SRC_ROOT/scripts/context-budget.sh" "$MAIN/scripts/"
cp "$SRC_ROOT/scripts/lib/session-lib.sh" "$MAIN/scripts/lib/"
chmod +x "$MAIN/scripts/"*.sh
printf 'ROLLOVER_RELAUNCH=manual\nROLLOVER_RUNTIME=claude\n' > "$MAIN/context-budget.env"
echo "# launcher" > "$MAIN/work/testproj/next-session.md"
git -C "$TMP" init -q
git -C "$TMP" config user.email t@t; git -C "$TMP" config user.name t
git -C "$TMP" add -A; git -C "$TMP" commit -qm init
LNS="$MAIN/scripts/launch-next-session.sh"
REC="$MAIN/work/testproj/session-state.json"
# Retired mirrors (phase 8): asserted ABSENT, never written by anything.
SEQF="$MAIN/work/testproj/.session-seq"
EMITF="$MAIN/work/testproj/.next-command"
LOOPF="$MAIN/work/testproj/.session-loop"
unset TF_SESSION_PROJECT TF_SESSION_SEQ TF_SESSION_LOOP TF_SESSION_LOOP_PROJECT

PASS=0; FAIL=0
ok()  { PASS=$((PASS+1)); echo "  ok: $1"; }
bad() { FAIL=$((FAIL+1)); echo "  FAIL: $1" >&2; }
assert_eq()       { [ "$2" = "$3" ] && ok "$1" || bad "$1 (want [$3] got [$2])"; }
assert_contains() { case "$2" in *"$3"*) ok "$1" ;; *) bad "$1 (no [$3] in [$2])" ;; esac; }
assert_same() { cmp -s "$2" "$3" && ok "$1" || bad "$1 (record changed)"; }
reason_of() { printf '%s\n' "$1" | sed -n 's/.*launch-next-session: refused reason=\([a-z_]*\).*/\1/p' | head -1; }
run_lns() { env -u CLAUDE_CODE_SESSION_ID -u CODEX_THREAD_ID -u OPENCODE_SESSION_ID \
  -u COPILOT_AGENT_SESSION_ID -u VSCODE_TARGET_SESSION_LOG -u TF_SESSION_LOOP \
  -u ROLLOVER_RELAUNCH -u ROLLOVER_RUNTIME "$@"; }
as_me() { run_lns CLAUDE_CODE_SESSION_ID=sid-me "$LNS" testproj "$@"; }
rec() { jq -r "$1" "$REC" 2>/dev/null; }
# The owner: seq 7, transcript live by age (no pid), launcher rewritten since
# registration, ledger block 7 in place.
reset() {
  rm -f "$EMITF" "$EMITF.json" "$SEQF" "$SEQF.bump.json" "$LOOPF"
  echo live > "$TMP/art-me"
  jq -n --arg af "$TMP/art-me" \
    '{schema:1, seq:7, launch:{launched_at:"2026-01-01T00:00:00Z", by:"session", mode:"handsoff", predecessor:null, pending:null},
      session:{seq:7, runtime:"claude", session_id:"sid-me", artifact:$af, registered_at:"2026-09-18T00:00:00Z",
               launcher_hash:"old-launcher-hash", user:"t", ended:null}}' > "$REC"
  printf '# Session Handoff — 7 (2026-09-18): the block\n' > "$MAIN/work/testproj/handoff.md"
}

echo "E1: --emit produces the same command --dry-run prints, for the five attached runtimes"
# copilot-vscode is absent by contract: --emit with a detached-by-nature runtime
# is refused (E4d-f). Its --dry-run remains legal.
for rt in claude codex gemini opencode copilot; do
  reset
  dry="$(as_me --runtime "$rt" --dry-run 2>/dev/null | sed -n 's/^cmd: //p')"
  reset
  out="$(as_me --runtime "$rt" --emit 2>/dev/null | sed -n 's/^cmd: //p')"
  assert_eq "E1-$rt: --emit prints the command --dry-run prints" "$out" "$dry"
  assert_eq "E1-$rt: staged.command is the same line" "$(rec .staged.command)" "$dry"
done

echo "E2: --emit performs the side effects --dry-run skips"
reset
as_me --emit >/dev/null 2>&1; rc=$?
assert_eq "E2a: exit 0"                          "$rc" "0"
assert_eq "E2b: seq advanced 7 -> 8"             "$(rec .seq)" "8"
assert_eq "E2c: staged.successor"                "$(rec .staged.successor)" "8"
assert_eq "E2d: staged.by is the caller"         "$(rec .staged.by)" "sid-me"
assert_eq "E2e: session emptied"                 "$(rec .session)" "null"
assert_eq "E2f: predecessor rolled_over"         "$(rec .launch.predecessor.disposition)" "rolled_over"
assert_eq "E2g: launch.mode default handsoff"    "$(rec .launch.mode)" "handsoff"
[ ! -f "$SEQF" ] && ok "E2h: no counter mirror" || bad "E2h: the counter mirror was written"
[ ! -f "$SEQF.bump.json" ] && ok "E2i: no bump record" || bad "E2i: the bump record was written"
[ ! -f "$EMITF" ] && [ ! -f "$EMITF.json" ] && ok "E2j: no command file, no sidecar" || bad "E2j: a command file or sidecar was written"
[ ! -f "$MAIN/.context-budget/successor-pending-testproj.json" ] \
  && ok "E2l: no successor-pending handshake file" || bad "E2l: handshake file written"
reset
as_me --emit --loop-mode interactive --loop-reason "asked" >/dev/null 2>&1
assert_eq "E2m: --loop-mode reaches the record"      "$(rec .launch.mode)" "interactive"
assert_eq "E2n: --loop-reason reaches the record"    "$(rec .launch.reason)" "asked"

echo "E3: --dry-run still mutates nothing"
reset; cp "$REC" "$TMP/rec.before"
as_me --dry-run >/dev/null 2>&1
assert_same "E3a: record untouched" "$TMP/rec.before" "$REC"
[ ! -f "$SEQF" ] && ok "E3b: no counter mirror" || bad "E3b: dry-run wrote the counter"

echo "E4: --emit refuses inputs that would strand or contradict it"
reset; cp "$REC" "$TMP/rec.before"
out="$(as_me --emit "work/testproj/.next-command" 2>&1)"; rc=$?
assert_eq       "E4a: --emit takes no path (a path is an unexpected argument)" "$rc" "3"
out="$(as_me --emit --dry-run 2>&1)"; rc=$?
assert_eq       "E4b: --emit with --dry-run is a usage error" "$rc" "3"
out="$(as_me --runtime copilot-vscode --emit 2>&1)"; rc=$?
assert_eq "E4d: --emit x copilot-vscode is refused"  "$rc" "4"
assert_eq "E4e: reason runtime_path_unsupported"     "$(reason_of "$out")" "runtime_path_unsupported"
assert_same "E4f: refusals write nothing"            "$TMP/rec.before" "$REC"
assert_eq "E4g: nothing staged" "$(rec .staged)" "null"

echo "E5: the emitted line is directly evaluable, env pair first"
reset
as_me --emit >/dev/null 2>&1
line="$(rec .staged.command)"
case "$line" in "TF_SESSION_PROJECT=testproj TF_SESSION_SEQ=8 claude "*) ok "E5a: env pair leads the command" ;;
  *) bad "E5a: no env pair prefix ([$line])" ;; esac
got="$(eval "set -- $(printf '%s' "$line" | sed 's/^TF_SESSION_PROJECT=testproj TF_SESSION_SEQ=8 claude //')"; echo "$*")"
assert_contains "E5b: the bootstrap prompt survived quoting" "$got" "rollover session #8"
assert_contains "E5c: the launcher wording is verbatim"     "$got" "continue from **First actions**"

echo "E6: ROLLOVER_RELAUNCH=auto emits the same foreground command"
printf 'ROLLOVER_RELAUNCH=auto\nROLLOVER_RUNTIME=claude\n' > "$MAIN/context-budget.env"
reset
as_me --emit >/dev/null 2>&1
case "$(rec .staged.command)" in
  *--bg*) bad "E6a: emitted command carries --bg" ;;
  ''|null) bad "E6a: nothing was staged under auto" ;;
  *) ok "E6a: emitted command is foreground under auto" ;;
esac
printf 'ROLLOVER_RELAUNCH=manual\nROLLOVER_RUNTIME=claude\n' > "$MAIN/context-budget.env"

echo "E7: --emit stages in the record at WORKSPACE_ROOT; no command file at either root"
reset; mkdir -p "$TMP/work/testproj"
GITROOT_EMITF="$TMP/work/testproj/.next-command"; rm -f "$GITROOT_EMITF"
( cd "$MAIN" && as_me --emit >/dev/null 2>&1 )
assert_eq "E7a: staged in the record" "$(rec .staged.successor)" "8"
[ ! -e "$EMITF" ] && [ ! -e "$GITROOT_EMITF" ] && ok "E7b: no command file at either root" || bad "E7b: a command file was written"

echo "E9: ROLLOVER_RELAUNCH=off must not swallow --emit"
printf 'ROLLOVER_RELAUNCH=off\nROLLOVER_RUNTIME=claude\n' > "$MAIN/context-budget.env"
reset
out=$(as_me --emit 2>/dev/null); rc=$?
assert_eq "E9a: mode=off + --emit exits 0" "$rc" "0"
assert_contains "E9b: the staged command is printed under mode=off" "$out" "cmd: "
assert_eq "E9c: record staged" "$(rec .staged.successor)" "8"
printf 'ROLLOVER_RELAUNCH=manual\nROLLOVER_RUNTIME=claude\n' > "$MAIN/context-budget.env"

echo "E10: the ownership gate exempts the supervisor's own bootstrap (strict parent), nothing else"
mk_sup() {  # $1 = pid: a chain.supervisor block naming it, merged into the record (created if absent)
  [ -f "$REC" ] || echo '{"schema":1}' > "$REC"
  jq --argjson pid "$1" --arg ps "$(ps -o lstart= -p "$1" | sed 's/^ *//;s/ *$//')" \
    '.chain.supervisor = {pid:$pid, pid_start:$ps, started_at:"now"}' "$REC" > "$REC.t" && mv "$REC.t" "$REC"
}
# Leg 1 — the bootstrap. Direct call, never $(...): a command substitution puts a
# subshell between the launcher and this shell, and the exemption keys on the
# strict parent. No session identity, no owner.
reset; rm -f "$REC"; mk_sup "$$"
run_lns "$LNS" testproj --emit >"$TMP/e10a" 2>&1; rc=$?
assert_eq "E10a: the bootstrap is not refused"   "$rc" "0"
assert_eq "E10b: the first session was staged"   "$(rec .staged.successor)" "8"
assert_eq "E10c: seq opened from the ledger (7 -> 8)" "$(rec .seq)" "8"
assert_eq "E10d: staged.by=supervisor"           "$(rec .staged.by)" "supervisor"
assert_contains "E10e: the exemption is visible" "$(cat "$TMP/e10a")" "not a session"
# Leg 2 — a session with no identity under a live supervisor that is not its parent.
sleep 60 & other=$!
reset; rm -f "$REC"; mk_sup "$other"
run_lns "$LNS" testproj --emit >"$TMP/e10b" 2>&1; rc=$?
assert_eq "E10f: refused"              "$rc" "4"
assert_eq "E10g: reason not_owner"     "$(reason_of "$(cat "$TMP/e10b")")" "not_owner"
assert_eq "E10h: nothing written (no seq opened)" "$(rec .seq)" "null"
kill "$other" 2>/dev/null; wait "$other" 2>/dev/null

echo "passed=$PASS failed=$FAIL"
[ "$FAIL" -eq 0 ]
