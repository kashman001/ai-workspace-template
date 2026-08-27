#!/usr/bin/env bash
# File: scripts/tests/test-turn-end-exit.sh
# Purpose: Prove the Tier-A exit mechanism (spec: "The exit mechanism — a tiered,
#          vendor-neutral contract"): a turn-end hook SIGTERMs its grandparent
#          agent process, the supervisor regains the terminal, and the tty is
#          left usable. Stub-only by default so CI needs no vendor binary;
#          --live <runtime> runs the same assertions against a real one.
#          T1/T2 need a controlling terminal; without one they SKIP loudly
#          rather than reporting failures that look like a regression.
set -u
SRC_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT

PASS=0; FAIL=0; SKIP=0
ok()   { PASS=$((PASS+1)); echo "  ok: $1"; }
bad()  { FAIL=$((FAIL+1)); echo "  FAIL: $1" >&2; }
skip() { SKIP=$((SKIP+1)); echo "  skip: $1"; }
assert_eq()       { [ "$2" = "$3" ] && ok "$1" || bad "$1 (want [$3] got [$2])"; }
assert_contains() { case "$2" in *"$3"*) ok "$1" ;; *) bad "$1 (no [$3] in [$2])" ;; esac; }

LIVE=""
[ "${1:-}" = "--live" ] && LIVE="${2:?--live needs a runtime}"

# script(1) is what gives the stub agent a real pty, and T1/T2 are meaningless
# without one. Under a detached harness (background job, nohup) stdin can be a
# socket rather than a terminal, and script aborts with
#   script: tcgetattr/ioctl: Operation not supported on socket
# which used to surface as two *false* failures indistinguishable from a real
# regression in the exit mechanism. Probe with a no-op rather than testing
# [ -t 0 ]: stdin is not a tty in plenty of contexts where script works fine,
# and a false skip hides real bugs just as badly as a false failure.
# BSD script (macOS) takes the typescript file first, then the command.
run_script() {   # run_script <executable> -> combined output; script's rc
  case "$(uname -s)" in
    Darwin) script -q /dev/null "$1" 2>&1 ;;
    *)      script -q -c "$1" /dev/null 2>&1 ;;
  esac
}

printf '#!/usr/bin/env bash\nexit 0\n' > "$TMP/noop.sh"; chmod +x "$TMP/noop.sh"
NO_PTY=""
if ! probe="$(run_script "$TMP/noop.sh")"; then
  NO_PTY="${probe%%$'\n'*}"
  [ -n "$NO_PTY" ] || NO_PTY="script(1) exited nonzero"
else
  case "$probe" in *tcgetattr*|*ioctl*) NO_PTY="${probe%%$'\n'*}" ;; esac
fi
[ -n "$NO_PTY" ] && NO_PTY="no controlling terminal — $NO_PTY"

summary() {
  if [ "$SKIP" -gt 0 ]; then
    echo "passed=$PASS failed=$FAIL skipped=$SKIP"
    echo "SKIPPED $SKIP assertion(s): $NO_PTY." >&2
    echo "Re-run this suite in the foreground for full coverage." >&2
  else
    echo "passed=$PASS failed=$FAIL"
  fi
}

# The hook under test. Stands in for a vendor turn-end hook: it is spawned by the
# "agent" process, and it terminates that process by signalling its own parent.
# SIGTERM only — failure mode 9 forbids escalation.
cat > "$TMP/hook.sh" <<'EOF'
#!/usr/bin/env bash
set -u
echo "hook: terminating agent pid $PPID" >> "$TF_EXIT_LOG"
kill -TERM "$PPID"
exit 0
EOF
chmod +x "$TMP/hook.sh"

# The stub agent: prints a line, "ends a turn" by running the hook, then would
# otherwise run forever. If the mechanism works it never reaches the sleep's end.
cat > "$TMP/agent.sh" <<'EOF'
#!/usr/bin/env bash
set -u
echo "agent: turn start"
"$TF_HOOK"
sleep 30
echo "agent: STILL ALIVE"    # must never appear
EOF
chmod +x "$TMP/agent.sh"

# The stub supervisor: runs the agent in the foreground on the inherited tty,
# waits, and reports that it regained control. This is the shape session-loop.sh
# uses (spec: "Architecture" -> 1), reduced to the part under test.
cat > "$TMP/sup.sh" <<'EOF'
#!/usr/bin/env bash
set -u
"$TF_CHILD"
echo "supervisor: terminal regained rc=$?"
EOF
chmod +x "$TMP/sup.sh"

echo "T1: a turn-end hook terminates the agent at the turn boundary"
export TF_EXIT_LOG="$TMP/exit.log"; : > "$TF_EXIT_LOG"
export TF_HOOK="$TMP/hook.sh"
export TF_CHILD="$TMP/agent.sh"
if [ -n "$NO_PTY" ]; then
  skip "T1a: the hook ran and saw the agent pid ($NO_PTY)"
  skip "T1b: the supervisor regained the terminal ($NO_PTY)"
  skip "T1c: the agent did not survive the hook ($NO_PTY)"
else
  out="$(run_script "$TMP/sup.sh")"
  assert_contains "T1a: the hook ran and saw the agent pid" "$(cat "$TF_EXIT_LOG")" "terminating agent pid"
  assert_contains "T1b: the supervisor regained the terminal" "$out" "supervisor: terminal regained"
  case "$out" in *"STILL ALIVE"*) bad "T1c: the agent survived the hook" ;;
                 *) ok "T1c: the agent did not survive the hook" ;; esac
fi

echo "T2: the tty is usable after the child is terminated"
# The failure this pins: a child killed mid-raw-mode leaves the terminal without
# echo, and every later session in the chain is typed into a dead-looking shell.
if [ -n "$NO_PTY" ]; then
  skip "T2a: tty settings unchanged across the run ($NO_PTY)"
else
  before="$(stty -g 2>/dev/null || echo unavailable)"
  run_script "$TMP/sup.sh" >/dev/null 2>&1
  after="$(stty -g 2>/dev/null || echo unavailable)"
  assert_eq "T2a: tty settings unchanged across the run" "$after" "$before"
fi

echo "T3: SIGTERM only — no SIGKILL anywhere in the mechanism"
# failure mode 9. Grep the shipped hook wrappers, not the stub.
hits="$(grep -rn 'kill -9\|-KILL\|SIGKILL' "$SRC_ROOT/scripts/hooks/" "$SRC_ROOT/scripts/session-loop.sh" 2>/dev/null || true)"
assert_eq "T3a: no SIGKILL in hooks or supervisor" "$hits" ""

if [ -n "$LIVE" ]; then
  echo "T4: LIVE firing test — runtime=$LIVE"
  echo "  (see docs/superpowers/plans/2026-08-26-session-supervisor.md Task 2"
  echo "   for the per-runtime wiring this mode expects to be in place)"
  : > "$TF_EXIT_LOG"
  # Wiring the probe hook is per-runtime. Where a runtime can take it on the
  # command line we do that, because the alternative — editing the user-global
  # config — leaves a hook that SIGTERMs every session on the machine if the
  # cleanup step is ever missed. Set TF_LIVE_HOOK to the absolute path of the
  # hook; leave it unset to run against whatever is already configured.
  #   codex  0.149.0: `-c` overrides config per-invocation. Schema is
  #                   Claude-Code-shaped ([[hooks.Stop]] / [[hooks.Stop.hooks]]),
  #                   and a CLI-supplied hook has no persisted trust, hence
  #                   --dangerously-bypass-hook-trust.
  #   gemini 0.46.0: hooks come only from settings.json, so TF_LIVE_HOOK cannot
  #                   be injected here — wire a workspace-level
  #                   .gemini/settings.json next to the run instead.
  LIVE_PRE=()
  if [ -n "${TF_LIVE_HOOK:-}" ]; then
    case "$LIVE" in
      codex) LIVE_PRE=(--dangerously-bypass-hook-trust
                       -c "hooks.Stop=[{hooks=[{type=\"command\",command=\"$TF_LIVE_HOOK\"}]}]") ;;
      *)     echo "  note: TF_LIVE_HOOK is not injectable for $LIVE; wire it in that runtime's settings" ;;
    esac
  fi
  case "$LIVE" in
    codex)  LIVE_CMD=(codex ${LIVE_PRE[@]+"${LIVE_PRE[@]}"} exec "Reply with the single word: ack") ;;
    gemini) LIVE_CMD=(gemini -p "Reply with the single word: ack") ;;
    claude) LIVE_CMD=(claude -p "Reply with the single word: ack") ;;
    opencode) LIVE_CMD=(opencode run "Reply with the single word: ack") ;;
    copilot) LIVE_CMD=(copilot -p "Reply with the single word: ack") ;;
    *) echo "unknown runtime: $LIVE" >&2; exit 1 ;;
  esac
  command -v "${LIVE_CMD[0]}" >/dev/null 2>&1 \
    || { bad "T4a: ${LIVE_CMD[0]} is not on PATH"; summary; exit 1; }
  TF_SESSION_LOOP=1 TF_EXIT_LOG="$TF_EXIT_LOG" "${LIVE_CMD[@]}" >"$TMP/live.out" 2>&1 || true
  assert_contains "T4a: the turn-end hook fired" "$(cat "$TF_EXIT_LOG")" "terminating agent pid"
fi

summary
[ "$FAIL" -eq 0 ]
