#!/usr/bin/env bash
# File: scripts/tests/test-emit-mode.sh
# Purpose: launch-next-session.sh --emit (spec: "Architecture" -> 2). Golden-files
#          the emitted command against --dry-run for all six runtimes, and pins
#          the side effects --dry-run deliberately skips: counter bump, options
#          adopt, lock release, successor-pending record.
set -u
SRC_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
MAIN="$TMP/main"
mkdir -p "$MAIN/scripts" "$MAIN/work/testproj" "$MAIN/.context-budget/sessions"
cp "$SRC_ROOT/scripts/launch-next-session.sh" "$SRC_ROOT/scripts/context-budget.sh" "$MAIN/scripts/"
chmod +x "$MAIN/scripts/"*.sh
printf 'ROLLOVER_RELAUNCH=manual\nROLLOVER_RUNTIME=claude\n' > "$MAIN/context-budget.env"
echo "# launcher" > "$MAIN/work/testproj/next-session.md"
git -C "$MAIN" init -q
git -C "$MAIN" config user.email t@t; git -C "$MAIN" config user.name t
git -C "$MAIN" add -A; git -C "$MAIN" commit -qm init
LNS="$MAIN/scripts/launch-next-session.sh"
SEQF="$MAIN/work/testproj/.session-seq"
EMITF="$MAIN/work/testproj/.next-command"

PASS=0; FAIL=0
ok()  { PASS=$((PASS+1)); echo "  ok: $1"; }
bad() { FAIL=$((FAIL+1)); echo "  FAIL: $1" >&2; }
assert_eq()       { [ "$2" = "$3" ] && ok "$1" || bad "$1 (want [$3] got [$2])"; }
assert_contains() { case "$2" in *"$3"*) ok "$1" ;; *) bad "$1 (no [$3] in [$2])" ;; esac; }
run_lns() { env -u CLAUDE_CODE_SESSION_ID -u CODEX_THREAD_ID \
  -u COPILOT_AGENT_SESSION_ID -u VSCODE_TARGET_SESSION_LOG \
  -u ROLLOVER_RELAUNCH -u ROLLOVER_RUNTIME "$@"; }

echo "E1: --emit produces the same command --dry-run prints, for all six runtimes"
for rt in claude codex gemini opencode copilot copilot-vscode; do
  printf '7\n' > "$SEQF"
  # --dry-run prints the bootstrap-prompt banner before the command
  # (launch-next-session.sh:319), so pull the "cmd: " line specifically rather
  # than stripping a prefix off the whole of stdout.
  dry="$(run_lns "$LNS" testproj --runtime "$rt" --dry-run 2>/dev/null | sed -n 's/^cmd: //p')"
  printf '7\n' > "$SEQF"; rm -f "$EMITF"
  run_lns "$LNS" testproj --runtime "$rt" --emit "$EMITF" >/dev/null 2>&1
  assert_eq "E1-$rt: emitted command matches --dry-run" "$(cat "$EMITF" 2>/dev/null)" "$dry"
done

echo "E2: --emit performs the side effects --dry-run skips"
printf '7\n' > "$SEQF"; rm -f "$EMITF"
run_lns "$LNS" testproj --runtime claude --emit "$EMITF" >/dev/null 2>&1
assert_eq "E2a: the counter advanced 7 -> 8" "$(cat "$SEQF")" "8"
pend="$MAIN/.context-budget/successor-pending-testproj.json"
[ -f "$pend" ] && ok "E2b: the successor-pending record was written" \
               || bad "E2b: no successor-pending record at $pend"
assert_eq "E2c: pending carries the successor's number" \
  "$(jq -r '.seq' "$pend" 2>/dev/null)" "8"

echo "E3: --dry-run still mutates nothing (the contract --emit must not break)"
printf '7\n' > "$SEQF"
run_lns "$LNS" testproj --runtime claude --dry-run >/dev/null 2>&1
assert_eq "E3a: the counter is untouched" "$(cat "$SEQF")" "7"

echo "E4: --emit refuses inputs that would strand or contradict it"
out="$(run_lns "$LNS" testproj --runtime claude --emit "work/testproj/.next-command" 2>&1 || true)"
assert_contains "E4a: a relative --emit path is refused" "$out" "absolute"
out="$(run_lns "$LNS" testproj --runtime claude --emit "$EMITF" --dry-run 2>&1 || true)"
assert_contains "E4b: --emit with --dry-run is refused" "$out" "--dry-run"
out="$(run_lns "$LNS" testproj --runtime claude --emit "$EMITF" --bg 2>&1 || true)"
assert_contains "E4c: --emit with --bg is refused" "$out" "--bg"

echo "E5: the emitted line is directly evaluable"
printf '7\n' > "$SEQF"; rm -f "$EMITF"
run_lns "$LNS" testproj --runtime claude --emit "$EMITF" >/dev/null 2>&1
# Replace the real binary with an echo so eval is safe, and confirm the prompt
# survives %q quoting intact — a mis-quoted prompt is the failure that would
# silently launch a successor with a truncated mission.
got="$(eval "set -- $(sed 's/^claude //' "$EMITF")"; echo "$*")"
assert_contains "E5a: the bootstrap prompt survived quoting" "$got" "rollover session #8"
assert_contains "E5b: the launcher wording is verbatim" "$got" "continue from **First actions**"

echo "E6: ROLLOVER_RELAUNCH=auto must not slip --bg into the emitted command"
# The regression this pins: --bg is refused as a flag (E4c), but BG is ALSO set
# from the mode, later in the script. The supervisor evals the emitted line in
# the foreground and waits on it, so a --bg there returns at once and the chain
# reads the missing sentinel as a deliberate quit. Every case above runs under
# the fixture's ROLLOVER_RELAUNCH=manual, which is exactly why this went unseen.
printf 'ROLLOVER_RELAUNCH=auto\nROLLOVER_RUNTIME=claude\n' > "$MAIN/context-budget.env"
printf '7\n' > "$SEQF"; rm -f "$EMITF"
run_lns "$LNS" testproj --runtime claude --emit "$EMITF" >/dev/null 2>&1
emitted="$(cat "$EMITF" 2>/dev/null)"
case "$emitted" in
  *--bg*) bad "E6a: emitted command carries --bg under auto ([$emitted])" ;;
  '') bad "E6a: nothing was emitted under auto" ;;
  *) ok "E6a: emitted command is foreground under auto" ;;
esac
# %q-quoted, like E5 — unquote by eval before matching on the prompt text.
got="$(eval "set -- $(sed 's/^claude //' "$EMITF")"; echo "$*")"
assert_contains "E6b: it is still a real launch command" "$got" "rollover session #8"
# --bg remains correct for a NON-emit auto launch: that path backgrounds by
# design (ADR-0003) and confirms the successor via the poll loop.
printf '7\n' > "$SEQF"
dry="$(run_lns "$LNS" testproj --runtime claude --dry-run 2>/dev/null | sed -n 's/^cmd: //p')"
assert_contains "E6c: a non-emit auto launch still backgrounds" "$dry" "--bg"
printf 'ROLLOVER_RELAUNCH=manual\nROLLOVER_RUNTIME=claude\n' > "$MAIN/context-budget.env"

echo "passed=$PASS failed=$FAIL"
[ "$FAIL" -eq 0 ]
