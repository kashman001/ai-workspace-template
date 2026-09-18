#!/usr/bin/env bash
# File: scripts/tests/test-emit-mode.sh
# Purpose: launch-next-session.sh --emit on the session record. Golden-files the
#          emitted command against --dry-run for the five attached runtimes
#          (copilot-vscode is refused under --emit), and pins the side effects
#          --dry-run skips: the record's `staged` block plus the two files the
#          turn-end hook still reads (the command, the bump record). Throwaway
#          git workspace; nested so the bare
#          --emit resolution (WORKSPACE_ROOT, not the git root) is observable.
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
  as_me --runtime "$rt" --emit "$EMITF" >/dev/null 2>&1
  assert_eq "E1-$rt: emitted command matches --dry-run" "$(cat "$EMITF" 2>/dev/null)" "$dry"
  assert_eq "E1-$rt: staged.command is the same line" "$(rec .staged.command)" "$dry"
done

echo "E2: --emit performs the side effects --dry-run skips"
reset
as_me --emit "$EMITF" >/dev/null 2>&1; rc=$?
assert_eq "E2a: exit 0"                          "$rc" "0"
assert_eq "E2b: seq advanced 7 -> 8"             "$(rec .seq)" "8"
assert_eq "E2c: staged.successor"                "$(rec .staged.successor)" "8"
assert_eq "E2d: staged.by is the caller"         "$(rec .staged.by)" "sid-me"
assert_eq "E2e: session emptied"                 "$(rec .session)" "null"
assert_eq "E2f: predecessor rolled_over"         "$(rec .launch.predecessor.disposition)" "rolled_over"
assert_eq "E2g: launch.mode default handsoff"    "$(rec .launch.mode)" "handsoff"
[ ! -f "$SEQF" ] && ok "E2h: no counter mirror" || bad "E2h: the counter mirror was written"
assert_eq "E2i: bump record for the supervisor"  \
  "$(jq -r '"\(.seq)/\(.successor)/\(.runtime)/\(.session_id)/\(.mode)/\(.written_by)"' "$SEQF.bump.json")" \
  "7/8/claude/sid-me/handsoff/launch-next-session.sh"
[ ! -f "$EMITF.json" ] && ok "E2j: no identity sidecar" || bad "E2j: the sidecar was written"
[ ! -f "$MAIN/.context-budget/successor-pending-testproj.json" ] \
  && ok "E2l: no successor-pending handshake file" || bad "E2l: handshake file written"
reset
as_me --emit "$EMITF" --loop-mode interactive --loop-reason "asked" >/dev/null 2>&1
assert_eq "E2m: --loop-mode reaches the record"      "$(rec .launch.mode)" "interactive"
assert_eq "E2n: --loop-reason reaches the bump record" "$(jq -r .reason "$SEQF.bump.json")" "asked"

echo "E3: --dry-run still mutates nothing"
reset; cp "$REC" "$TMP/rec.before"
as_me --dry-run >/dev/null 2>&1
assert_same "E3a: record untouched" "$TMP/rec.before" "$REC"
[ ! -f "$SEQF" ] && ok "E3b: no counter mirror" || bad "E3b: dry-run wrote the counter"

echo "E4: --emit refuses inputs that would strand or contradict it"
reset; cp "$REC" "$TMP/rec.before"
out="$(as_me --emit "work/testproj/.next-command" 2>&1)"; rc=$?
assert_eq       "E4a: a relative --emit path is a usage error" "$rc" "3"
assert_contains "E4a2: says absolute"                         "$out" "absolute"
out="$(as_me --emit "$EMITF" --dry-run 2>&1)"; rc=$?
assert_eq       "E4b: --emit with --dry-run is a usage error" "$rc" "3"
out="$(as_me --runtime copilot-vscode --emit "$EMITF" 2>&1)"; rc=$?
assert_eq "E4d: --emit x copilot-vscode is refused"  "$rc" "4"
assert_eq "E4e: reason runtime_path_unsupported"     "$(reason_of "$out")" "runtime_path_unsupported"
assert_same "E4f: refusals write nothing"            "$TMP/rec.before" "$REC"
[ ! -f "$EMITF" ] && ok "E4g: nothing staged" || bad "E4g: a refusal staged a command"

echo "E5: the emitted line is directly evaluable, env pair first"
reset
as_me --emit "$EMITF" >/dev/null 2>&1
line="$(cat "$EMITF")"
case "$line" in "TF_SESSION_PROJECT=testproj TF_SESSION_SEQ=8 claude "*) ok "E5a: env pair leads the command" ;;
  *) bad "E5a: no env pair prefix ([$line])" ;; esac
got="$(eval "set -- $(sed 's/^TF_SESSION_PROJECT=testproj TF_SESSION_SEQ=8 claude //' "$EMITF")"; echo "$*")"
assert_contains "E5b: the bootstrap prompt survived quoting" "$got" "rollover session #8"
assert_contains "E5c: the launcher wording is verbatim"     "$got" "continue from **First actions**"

echo "E6: ROLLOVER_RELAUNCH=auto emits the same foreground command"
printf 'ROLLOVER_RELAUNCH=auto\nROLLOVER_RUNTIME=claude\n' > "$MAIN/context-budget.env"
reset
as_me --emit "$EMITF" >/dev/null 2>&1
case "$(cat "$EMITF" 2>/dev/null)" in
  *--bg*) bad "E6a: emitted command carries --bg" ;;
  '') bad "E6a: nothing was emitted under auto" ;;
  *) ok "E6a: emitted command is foreground under auto" ;;
esac
printf 'ROLLOVER_RELAUNCH=manual\nROLLOVER_RUNTIME=claude\n' > "$MAIN/context-budget.env"

echo "E7: --emit bare resolves from WORKSPACE_ROOT, not the git root"
reset; mkdir -p "$TMP/work/testproj"
GITROOT_EMITF="$TMP/work/testproj/.next-command"; rm -f "$GITROOT_EMITF"
( cd "$MAIN" && as_me --emit >/dev/null 2>&1 )
[ -s "$EMITF" ] && ok "E7a: bare --emit wrote $EMITF" || bad "E7a: nothing at $EMITF"
[ ! -e "$GITROOT_EMITF" ] && ok "E7b: nothing written at the git root" || bad "E7b: wrote to the git root"

echo "E8: a failed emit is loud and leaves the record untouched"
if [ "$(id -u)" -eq 0 ]; then
  echo "  skipped (root: chmod 500 does not deny writes)"
else
  RO="$TMP/ro"; mkdir -p "$RO"; chmod 500 "$RO"
  reset; cp "$REC" "$TMP/rec.before"
  err=$(as_me --emit "$RO/.next-command" 2>&1 >/dev/null); rc=$?
  [ "$rc" -ne 0 ] && ok "E8a: failed emit exits non-zero" || bad "E8a: failed emit reported success"
  assert_same     "E8b: record untouched (the emit path is probed before the write)" "$TMP/rec.before" "$REC"
  assert_contains "E8c: error names the attempted path" "$err" "$RO/.next-command"
  case "$err" in *seq-sync*) bad "E8d: remedy still names seq-sync" ;; *) ok "E8d: no seq-sync remedy" ;; esac
  chmod 700 "$RO"
fi

echo "E9: ROLLOVER_RELAUNCH=off must not swallow --emit"
printf 'ROLLOVER_RELAUNCH=off\nROLLOVER_RUNTIME=claude\n' > "$MAIN/context-budget.env"
reset
as_me --emit "$EMITF" >/dev/null 2>&1; rc=$?
assert_eq "E9a: mode=off + --emit exits 0" "$rc" "0"
[ -s "$EMITF" ] && ok "E9b: staged under mode=off" || bad "E9b: mode=off swallowed --emit"
assert_eq "E9c: record staged" "$(rec .staged.successor)" "8"
printf 'ROLLOVER_RELAUNCH=manual\nROLLOVER_RUNTIME=claude\n' > "$MAIN/context-budget.env"

echo "E10: the ownership gate exempts the supervisor's own bootstrap (strict parent), nothing else"
mk_marker() { jq -n --argjson pid "$1" '{pid:$pid, project:"testproj", started_at:"now"}' > "$LOOPF"; }
# Leg 1 — the bootstrap. Direct call, never $(...): a command substitution puts a
# subshell between the launcher and this shell, and the exemption keys on the
# strict parent. No session identity, no owner.
reset; rm -f "$REC"; mk_marker "$$"
run_lns "$LNS" testproj --emit "$EMITF" >"$TMP/e10a" 2>&1; rc=$?
assert_eq "E10a: the bootstrap is not refused"   "$rc" "0"
[ -s "$EMITF" ] && ok "E10b: the first session was staged" || bad "E10b: nothing staged"
assert_eq "E10c: seq opened from the ledger (7 -> 8)" "$(rec .seq)" "8"
assert_eq "E10d: staged.by=supervisor"           "$(rec .staged.by)" "supervisor"
assert_contains "E10e: the exemption is visible" "$(cat "$TMP/e10a")" "not a session"
# Leg 2 — a session with no identity under a live supervisor that is not its parent.
sleep 60 & other=$!
reset; rm -f "$REC"; mk_marker "$other"
run_lns "$LNS" testproj --emit "$EMITF" >"$TMP/e10b" 2>&1; rc=$?
assert_eq "E10f: refused"              "$rc" "4"
assert_eq "E10g: reason not_owner"     "$(reason_of "$(cat "$TMP/e10b")")" "not_owner"
[ ! -f "$REC" ] && ok "E10h: nothing written" || bad "E10h: refusal wrote a record"
kill "$other" 2>/dev/null; wait "$other" 2>/dev/null
rm -f "$LOOPF"

echo "passed=$PASS failed=$FAIL"
[ "$FAIL" -eq 0 ]
