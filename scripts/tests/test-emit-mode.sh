#!/usr/bin/env bash
# File: scripts/tests/test-emit-mode.sh
# Purpose: launch-next-session.sh --emit (spec: "Architecture" -> 2). Golden-files
#          the emitted command against --dry-run for the five attached runtimes
#          (copilot-vscode is refused under --emit — TE6 A5), and pins the side
#          effects --dry-run deliberately skips: counter bump, options adopt,
#          lock release, successor-pending record.
set -u
SRC_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
MAIN="$TMP/main"
mkdir -p "$MAIN/scripts" "$MAIN/work/testproj" "$MAIN/.context-budget/sessions"
cp "$SRC_ROOT/scripts/launch-next-session.sh" "$SRC_ROOT/scripts/context-budget.sh" "$MAIN/scripts/"
chmod +x "$MAIN/scripts/"*.sh
printf 'ROLLOVER_RELAUNCH=manual\nROLLOVER_RUNTIME=claude\n' > "$MAIN/context-budget.env"
echo "# launcher" > "$MAIN/work/testproj/next-session.md"
git -C "$TMP" init -q
git -C "$TMP" config user.email t@t; git -C "$TMP" config user.name t
git -C "$TMP" add -A; git -C "$TMP" commit -qm init
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

echo "E1: --emit produces the same command --dry-run prints, for the five attached runtimes"
# copilot-vscode is absent by contract, not oversight: --emit with a
# detached-by-nature runtime is refused outright (TE6 A5) — asserted as E4d-f.
# --dry-run for copilot-vscode remains legal; only the --emit leg is gone.
for rt in claude codex gemini opencode copilot; do
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
# TE6 A5: copilot-vscode's CMD (`code chat`) is detached BY NATURE — the
# launcher forces BG=1 for it AFTER the parse-time --emit/--bg check, so E4c
# never sees it. The supervisor runs the emitted line in the foreground and
# waits: an instant clean return reads as delta 0 / deliberate quit, marker
# deleted, and the real session runs unsupervised (the 2026-08-27 --bg bug in
# a second costume). Mutation that makes E4d and E4e red: drop the
# emit x copilot-vscode refusal after runtime resolution
# (launch-next-session.sh) — staging then succeeds, rc=0, no message.
# Mutation that makes E4f red: move that refusal below the counter bump —
# the refusal then costs a bump (TE6 R3: a refusal must be side-effect-free).
printf '7\n' > "$SEQF"; rm -f "$EMITF"
out="$(run_lns "$LNS" testproj --runtime copilot-vscode --emit "$EMITF" 2>&1)"; rc=$?
assert_eq "E4d: --emit with detached-by-nature copilot-vscode exits 3" "$rc" "3"
# "detached", not "copilot-vscode": the runtime name appears in the normal
# project=/runtime= readout too, so matching on it could never go red.
assert_contains "E4e: the refusal names the detachment as the reason" "$out" "detached"
assert_eq "E4f: the refusal is side-effect-free — counter untouched" "$(cat "$SEQF")" "7"

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

# --- Lane B: C2 and C3 -------------------------------------------------------
# plan.md numbers these T16-T19; renumbered to the suite's own E-series.
# The plan's T17 ("--emit <abs-path> still honoured") and T18 ("a relative
# --emit is refused") are already asserted above — T17 six times over by E1
# plus E2a-c, T18 verbatim by E4a — so they are not duplicated here.

echo "E7: --emit bare resolves from WORKSPACE_ROOT, not the git root (C2)"
printf '7\n' > "$SEQF"; rm -f "$EMITF"
# TE6 B1: the git-root landing zone must EXIST, or E7b is vacuous — with no
# $TMP/work/testproj directory, a git-root-resolving mutation just fails its
# write and E7b stays green while asserting nothing (E7a is then the only
# detector). Mutation that makes E7b red (and E7a with it): resolve the bare
# --emit path from `git rev-parse --show-toplevel` instead of WORKSPACE_ROOT
# (launch-next-session.sh, the EMIT="@auto" resolution) — the D2 shape.
mkdir -p "$TMP/work/testproj"
GITROOT_EMITF="$TMP/work/testproj/.next-command"; rm -f "$GITROOT_EMITF"
( cd "$MAIN" && run_lns ./scripts/launch-next-session.sh testproj --emit >/dev/null 2>&1 )
[ -s "$EMITF" ] && ok "E7a: bare --emit wrote $EMITF" || bad "E7a: nothing at $EMITF"
[ ! -e "$GITROOT_EMITF" ] \
  && ok "E7b: nothing written at the git root" \
  || bad "E7b: wrote to the git root — the D2 shape"

echo "E8: a failed emit is loud and rolls back the pending record (C3)"
if [ "$(id -u)" -eq 0 ]; then
  echo "  skipped (root: chmod 500 does not deny writes)"
else
  RO="$TMP/ro"; mkdir -p "$RO"; chmod 500 "$RO"
  PENDF="$MAIN/.context-budget/successor-pending-testproj.json"
  printf '7\n' > "$SEQF"; rm -f "$PENDF"
  ( cd "$MAIN" && run_lns ./scripts/launch-next-session.sh testproj --emit "$RO/.next-command" >/dev/null 2>&1 ); rc=$?
  [ "$rc" -ne 0 ] && ok "E8a: failed emit exits non-zero" || bad "E8a: failed emit reported success"
  [ ! -f "$PENDF" ] && ok "E8b: pending record rolled back" || bad "E8b: stale pending record left behind"
  printf '7\n' > "$SEQF"; rm -f "$PENDF"
  err=$( cd "$MAIN" && run_lns ./scripts/launch-next-session.sh testproj --emit "$RO/.next-command" 2>&1 >/dev/null )
  assert_contains "E8c: error names the attempted path" "$err" "$RO/.next-command"
  assert_contains "E8d: error names the rewind remedy" "$err" "seq-sync"
  chmod 700 "$RO"; rm -f "$PENDF"
fi

echo "E9: ROLLOVER_RELAUNCH=off must not swallow --emit (TE6 A4)"
# --emit stages a command for a supervisor and launches nothing itself, so a
# committed mode=off has nothing to refuse — the supervisor bootstrap
# (session-loop.sh, the `--emit "$NEXTF" || halt` call) relies on this: its
# `|| halt` only fires on a non-zero exit, and an exit-0-with-nothing-staged
# dissolves the chain later with a fabricated story.
# Mutation that makes E9b/E9c red: reinstate the unconditional MODE=off
# early exit-0 (drop the `[ -z "$EMIT" ]` clause from the launcher's MODE=off
# branch) — --emit then reports success having staged nothing.
# Mutation that makes E9a red: the REJECTED alternative fix — refuse
# mode=off + --emit at parse time (exit 3). Rejected because the supervisor's
# own bootstrap would break under a committed `off`; staging must succeed.
printf 'ROLLOVER_RELAUNCH=off\nROLLOVER_RUNTIME=claude\n' > "$MAIN/context-budget.env"
printf '7\n' > "$SEQF"; rm -f "$EMITF" "$pend"
run_lns "$LNS" testproj --runtime claude --emit "$EMITF" >/dev/null 2>&1; rc=$?
assert_eq "E9a: mode=off + --emit exits 0 (staging is not refused)" "$rc" "0"
[ -s "$EMITF" ] && ok "E9b: the successor command was staged under mode=off" \
                || bad "E9b: mode=off swallowed --emit — nothing staged at $EMITF"
[ -f "$pend" ] && ok "E9c: the successor-pending record was written under mode=off" \
               || bad "E9c: no successor-pending record at $pend"
printf 'ROLLOVER_RELAUNCH=manual\nROLLOVER_RUNTIME=claude\n' > "$MAIN/context-budget.env"

echo "passed=$PASS failed=$FAIL"
[ "$FAIL" -eq 0 ]
