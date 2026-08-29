#!/usr/bin/env bash
# File: scripts/tests/test-session-loop.sh
# Purpose: session-loop.sh against stub children — no model, no vendor (spec:
#          "Testing" -> "Supervisor, no model"). The stubs stand in for a session:
#          they bump the counter and write (or fail to write) a sentinel, which is
#          the entire contract the supervisor depends on.
set -u
SRC_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
MAIN="$TMP/main"
mkdir -p "$MAIN/scripts" "$MAIN/work/testproj" "$MAIN/.context-budget/sessions"
cp "$SRC_ROOT/scripts/session-loop.sh" "$SRC_ROOT/scripts/launch-next-session.sh" \
   "$SRC_ROOT/scripts/context-budget.sh" "$MAIN/scripts/"
chmod +x "$MAIN/scripts/"*.sh
printf 'ROLLOVER_RELAUNCH=manual\nROLLOVER_RUNTIME=claude\n' > "$MAIN/context-budget.env"
echo "# launcher" > "$MAIN/work/testproj/next-session.md"
# The same live-session ignores the real workspace carries (.gitignore, "Live-
# session runtime state under work/"). Not cosmetic: without them a stub doing
# `git add -A` commits the supervisor's own coordination files, every one of
# which changes on every iteration — so the P-series would see progress in every
# session and pass while testing nothing. The suite must model the repo the
# guard actually runs against.
printf '%s\n' 'work/*/.session-seq' 'work/*/.session-seq.provenance.json' \
  'work/*/.rollover-complete' 'work/*/.next-command' 'work/*/.session-loop' \
  'work/*/.session-loop.log' 'work/*/.session-loop.alarm-stop' \
  'work/*/.active-session' > "$MAIN/.gitignore"
git -C "$MAIN" init -q
git -C "$MAIN" config user.email t@t; git -C "$MAIN" config user.name t
git -C "$MAIN" add -A; git -C "$MAIN" commit -qm init
SL="$MAIN/scripts/session-loop.sh"
W="$MAIN/work/testproj"
SEQF="$W/.session-seq"; SENT="$W/.rollover-complete"; NEXT="$W/.next-command"

PASS=0; FAIL=0
ok()  { PASS=$((PASS+1)); echo "  ok: $1"; }
bad() { FAIL=$((FAIL+1)); echo "  FAIL: $1" >&2; }
assert_eq()       { [ "$2" = "$3" ] && ok "$1" || bad "$1 (want [$3] got [$2])"; }
assert_contains() { case "$2" in *"$3"*) ok "$1" ;; *) bad "$1 (no [$3] in [$2])" ;; esac; }

# A stub "session": bumps the counter the way --emit would, stages the next
# command, and writes a sentinel carrying its own number. $STUB_BEHAVIOUR selects
# which contract it honours or breaks.
mk_stub() {
  cat > "$TMP/stub.sh" <<'EOF'
#!/usr/bin/env bash
set -u
W="$STUB_W"
me="$(tr -cd '0-9' < "$W/.session-seq")"
echo "stub: running as session #$me"
case "${STUB_BEHAVIOUR:-normal}" in
  normal)
    echo $((me + 1)) > "$W/.session-seq"
    printf '%s\n' "$STUB_SELF" > "$W/.next-command"
    printf '{"mode":"%s","seq":%s,"reason":"stub","session_id":"sid-%s","runtime":"stub","cwd":"%s"}\n' \
      "${STUB_MODE:-handsoff}" "$me" "$me" "$W" > "$W/.rollover-complete" ;;
  quit)          # human typed /exit: no bump, no sentinel
    : ;;
  stage-nothing) # the s184 shape: a clean rollover that stages no successor
    echo $((me + 1)) > "$W/.session-seq"
    printf '{"mode":"%s","seq":%s,"reason":"stub","session_id":"sid-%s","runtime":"stub","cwd":"%s"}\n' \
      "${STUB_MODE:-handsoff}" "$me" "$me" "$W" > "$W/.rollover-complete" ;;
  died-mid)      # died between --emit and the sentinel (failure mode 8)
    echo $((me + 1)) > "$W/.session-seq"
    printf '%s\n' "$STUB_SELF" > "$W/.next-command" ;;
  stranded)      # sentinel written at a bare relative path, into a worktree
    echo $((me + 1)) > "$W/.session-seq"
    printf '%s\n' "$STUB_SELF" > "$W/.next-command"
    mkdir -p "$STUB_STRAND"
    printf '{"mode":"handsoff","seq":%s,"reason":"stranded","session_id":"sid","runtime":"stub","cwd":"%s"}\n' \
      "$me" "$STUB_STRAND" > "$STUB_STRAND/.rollover-complete" ;;
  double-bump)   # numbering rule 5: a delta of 2 must halt the chain
    echo $((me + 2)) > "$W/.session-seq"
    printf '%s\n' "$STUB_SELF" > "$W/.next-command"
    printf '{"mode":"handsoff","seq":%s,"reason":"stub","session_id":"sid","runtime":"stub","cwd":"%s"}\n' \
      "$me" "$W" > "$W/.rollover-complete" ;;
esac
EOF
  chmod +x "$TMP/stub.sh"
}
mk_stub
export STUB_W="$W" STUB_SELF="$TMP/stub.sh"

reset() { printf '8\n' > "$SEQF"; rm -f "$SENT" "$NEXT" "$W/.session-loop";
          printf '%s\n' "$TMP/stub.sh" > "$NEXT"; }

# --min-lifetime 0 on every case that expects an iteration to be JUDGED CLEAN:
# stubs return instantly, so the Task 6 guard (default 60s) would halt the chain
# before the assertion under test is reached. The guard has its own cases, G1/G2.
#
# --stall-limit 0 for the same reason on every case that expects a chain to run
# to its cap: these stubs commit nothing at all, so the Task 7 guard reads every
# one of them as a stalled session and would halt a 3-session chain on its last
# iteration. The stall guard has its own cases, P1-P4.
echo "L1: a normal hands-off chain relaunches until the sentinel stops appearing"
reset; export STUB_BEHAVIOUR=normal STUB_MODE=handsoff
out="$("$SL" testproj --max-sessions 3 --min-lifetime 0 --stall-limit 0 2>&1 </dev/null || true)"
assert_contains "L1a: it ran more than one session" "$out" "session #9"
assert_eq       "L1b: the counter advanced by exactly 3" "$(cat "$SEQF")" "11"
assert_contains "L1c: the cap ended the chain"     "$out" "chain cap"

echo "L2: no sentinel + unchanged counter = deliberate quit, exit 0"
reset; export STUB_BEHAVIOUR=quit
"$SL" testproj --max-sessions 3 >"$TMP/o2" 2>&1 </dev/null; rc=$?
assert_eq       "L2a: exit 0"                 "$rc" "0"
assert_contains "L2b: reported as a quit"     "$(cat "$TMP/o2")" "deliberate quit"

echo "L3: THE LOAD-BEARING ONE — counter moved but no sentinel here = halt, not clean exit"
reset; export STUB_BEHAVIOUR=died-mid
"$SL" testproj --max-sessions 3 >"$TMP/o3" 2>&1 </dev/null; rc=$?
assert_eq       "L3a: exit 1 (halt), NOT 0"   "$rc" "1"
assert_contains "L3b: halted and notified"    "$(cat "$TMP/o3")" "HALT"
case "$(cat "$TMP/o3")" in *"deliberate quit"*) bad "L3c: a mid-death was called a clean quit" ;;
                           *) ok "L3c: a mid-death was not called a clean quit" ;; esac

echo "L4: a sentinel stranded in a worktree does not read as a clean shutdown"
reset; export STUB_BEHAVIOUR=stranded STUB_STRAND="$TMP/wt/work/testproj"
"$SL" testproj --max-sessions 3 >"$TMP/o4" 2>&1 </dev/null; rc=$?
assert_eq       "L4a: exit 1 (halt)"          "$rc" "1"
assert_contains "L4b: halted and notified"    "$(cat "$TMP/o4")" "HALT"

echo "L5: numbering rule 5 — a delta != 1 halts the chain"
reset; export STUB_BEHAVIOUR=double-bump
"$SL" testproj --max-sessions 3 >"$TMP/o5" 2>&1 </dev/null; rc=$?
assert_eq       "L5a: exit 1 (halt)"          "$rc" "1"
assert_contains "L5b: the delta is named"     "$(cat "$TMP/o5")" "delta"

echo "L6: sentinel.seq must match the session that just ran"
reset; export STUB_BEHAVIOUR=normal STUB_MODE=handsoff
"$SL" testproj --max-sessions 1 --min-lifetime 0 >/dev/null 2>&1 </dev/null || true
assert_eq "L6a: the sentinel recorded #8, the session that ran" "$(jq -r '.seq' "$SENT")" "8"

echo "L7: every coordination file resolves to the main checkout"
reset; export STUB_BEHAVIOUR=normal
git -C "$MAIN" worktree add -q -b wt2 "$TMP/wt2" 2>/dev/null || true
( cd "$TMP/wt2" && "$MAIN/scripts/session-loop.sh" testproj --max-sessions 1 --min-lifetime 0 >/dev/null 2>&1 </dev/null ) || true
# Probed via .session-loop.log, not .session-loop: the pidfile is removed by the
# EXIT trap (L8's stale-pid guard depends on that), so it cannot be observed once
# the run is over. Both files are "$S/..." — the log proves the same resolution
# and, unlike the pidfile, persists, so the worktree check below can actually
# fail if $S ever resolved to the child checkout.
[ -f "$W/.session-loop.log" ] && ok "L7a: coordination state landed in the main checkout" \
                              || bad "L7a: coordination state did not land in the main checkout"
[ -f "$TMP/wt2/work/testproj/.session-loop.log" ] \
  && bad "L7b: stray coordination state was left in the worktree" \
  || ok "L7b: nothing stranded in the worktree"

echo "L8: a second supervisor for the same work item is refused"
reset
printf '{"pid":%s,"project":"testproj","started_at":"now"}\n' "$$" > "$W/.session-loop"
out="$("$SL" testproj --max-sessions 1 2>&1 </dev/null || true)"
assert_contains "L8a: refused while another supervisor holds the file" "$out" "already running"
rm -f "$W/.session-loop"

echo "L9: a stale .next-command can never be re-run (failure mode 5)"
reset; export STUB_BEHAVIOUR=quit
"$SL" testproj --max-sessions 3 >/dev/null 2>&1 </dev/null || true
[ -f "$NEXT" ] && bad "L9a: the staged command outlived the iteration" \
               || ok "L9a: the staged command was consumed"

echo "G1: the minimum-lifetime guard catches a first-turn burn loop"
# failure mode 1: a successor gemini session reads the PREDECESSOR's token count
# from the shared telemetry log and spuriously reports STOP on turn one. Accepted
# in the human-driven world because a human notices. The supervisor is the human
# now, so a session that rolls over in under --min-lifetime seconds halts.
reset; export STUB_BEHAVIOUR=normal STUB_MODE=handsoff
"$SL" testproj --max-sessions 3 --min-lifetime 3600 >"$TMP/g1" 2>&1 </dev/null; rc=$?
assert_eq       "G1a: exit 1 (halt)"                "$rc" "1"
assert_contains "G1b: the lifetime is named"        "$(cat "$TMP/g1")" "min-lifetime"
assert_contains "G1c: it names the burn-loop shape" "$(cat "$TMP/g1")" "rolled over after"

echo "G2: a normal-length session is not caught by the guard"
reset; export STUB_BEHAVIOUR=normal STUB_MODE=handsoff
"$SL" testproj --max-sessions 2 --min-lifetime 0 --stall-limit 0 >"$TMP/g2" 2>&1 </dev/null; rc=$?
assert_eq "G2a: exit 0 with the guard disabled" "$rc" "0"

echo "G3: the chain cap is honoured and reported"
reset; export STUB_BEHAVIOUR=normal STUB_MODE=handsoff
out="$("$SL" testproj --max-sessions 2 --min-lifetime 0 --stall-limit 0 2>&1 </dev/null || true)"
assert_eq       "G3a: exactly 2 sessions ran" "$(cat "$SEQF")" "10"
assert_contains "G3b: the cap is reported"    "$out" "chain cap reached (2"

echo "G4: an unstageable successor halts rather than ending quietly"
# failure mode 11: every die in launch-next-session.sh (three launch
# preconditions, the stale-launcher refusal, ff-push divergence) was written for
# a watching human. Unattended, a die is just a stopped chain.
reset; export STUB_BEHAVIOUR=normal STUB_MODE=handsoff
rm -f "$NEXT"; rm -f "$MAIN/work/testproj/next-session.md"
out="$("$SL" testproj --max-sessions 1 2>&1 </dev/null || true)"
assert_contains "G4a: refused with a reason" "$out" "next-session.md"
echo "# launcher" > "$MAIN/work/testproj/next-session.md"

echo "G5: the notify hook receives the halt message"
reset; export STUB_BEHAVIOUR=double-bump
cat > "$TMP/notify.sh" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$1" >> "$TF_NOTIFY_LOG"
EOF
chmod +x "$TMP/notify.sh"
export TF_NOTIFY_LOG="$TMP/notify.log"; : > "$TF_NOTIFY_LOG"
SESSION_LOOP_NOTIFY="$TMP/notify.sh" "$SL" testproj --max-sessions 2 --min-lifetime 0 \
  >/dev/null 2>&1 </dev/null || true
assert_contains "G5a: the notify hook was called" "$(cat "$TF_NOTIFY_LOG")" "session-loop testproj"
assert_contains "G5b: it carries the reason"      "$(cat "$TF_NOTIFY_LOG")" "delta"
unset SESSION_LOOP_NOTIFY

echo "P1: THE CLAUSE THAT MATTERS — bookkeeping-only commits are not progress"
# An unqualified 'did this session commit?' test passes this trivially, which is
# precisely the defect. Every session below commits, every session below is stuck.
reset; export STUB_BEHAVIOUR=normal STUB_MODE=handsoff
export STUB_ROOT="$MAIN"
cat > "$TMP/stub-bookkeeping.sh" <<'EOF'
#!/usr/bin/env bash
set -u
W="$STUB_W"; R="$STUB_ROOT"
me="$(tr -cd '0-9' < "$W/.session-seq")"
printf 'block %s\n' "$me" >> "$W/handoff.md"
printf 'launcher %s\n' "$me" > "$W/next-session.md"
git -C "$R" add work/testproj/handoff.md work/testproj/next-session.md
git -C "$R" commit -qm "work(testproj): rollover bookkeeping $me"
echo $((me + 1)) > "$W/.session-seq"
printf '%s\n' "$STUB_SELF" > "$W/.next-command"
printf '{"mode":"%s","seq":%s,"reason":"stub","session_id":"sid","runtime":"stub","cwd":"%s"}\n' \
  "${STUB_MODE:-handsoff}" "$me" "$W" > "$W/.rollover-complete"
EOF
chmod +x "$TMP/stub-bookkeeping.sh"
printf '%s\n' "$TMP/stub-bookkeeping.sh" > "$NEXT"
STUB_SELF="$TMP/stub-bookkeeping.sh" "$SL" testproj --max-sessions 9 --min-lifetime 0 \
  --stall-limit 3 >"$TMP/p1" 2>&1 </dev/null; rc=$?
assert_eq       "P1a: exit 1 (halt)"                 "$rc" "1"
assert_contains "P1b: it halted on the stall guard"  "$(cat "$TMP/p1")" "no progress"
assert_eq       "P1c: it halted at the limit, not the cap" "$(cat "$SEQF")" "11"

echo "P2: a commit outside the bookkeeping set resets the counter"
reset
cat > "$TMP/stub-progress.sh" <<'EOF'
#!/usr/bin/env bash
set -u
W="$STUB_W"; R="$STUB_ROOT"
me="$(tr -cd '0-9' < "$W/.session-seq")"
printf 'block %s\n' "$me" >> "$W/handoff.md"
printf 'real work %s\n' "$me" >> "$R/README.md"
git -C "$R" add -A
git -C "$R" commit -qm "feat: real work $me"
echo $((me + 1)) > "$W/.session-seq"
printf '%s\n' "$STUB_SELF" > "$W/.next-command"
printf '{"mode":"%s","seq":%s,"reason":"stub","session_id":"sid","runtime":"stub","cwd":"%s"}\n' \
  "${STUB_MODE:-handsoff}" "$me" "$W" > "$W/.rollover-complete"
EOF
chmod +x "$TMP/stub-progress.sh"
printf '%s\n' "$TMP/stub-progress.sh" > "$NEXT"
STUB_SELF="$TMP/stub-progress.sh" "$SL" testproj --max-sessions 5 --min-lifetime 0 \
  --stall-limit 3 >"$TMP/p2" 2>&1 </dev/null; rc=$?
assert_eq "P2a: exit 0 — the chain ran to the cap" "$rc" "0"
case "$(cat "$TMP/p2")" in *"no progress"*) bad "P2b: real work was called a stall" ;;
                           *) ok "P2b: real work was not called a stall" ;; esac

echo "P3: a ticket-state change under work/<proj>/issues/ counts as progress"
reset
mkdir -p "$W/issues"
cat > "$TMP/stub-ticket.sh" <<'EOF'
#!/usr/bin/env bash
set -u
W="$STUB_W"; R="$STUB_ROOT"
me="$(tr -cd '0-9' < "$W/.session-seq")"
printf 'block %s\n' "$me" >> "$W/handoff.md"
printf 'status: done\n' > "$W/issues/t$me.md"
git -C "$R" add -A
git -C "$R" commit -qm "chore: ticket $me"
echo $((me + 1)) > "$W/.session-seq"
printf '%s\n' "$STUB_SELF" > "$W/.next-command"
printf '{"mode":"%s","seq":%s,"reason":"stub","session_id":"sid","runtime":"stub","cwd":"%s"}\n' \
  "${STUB_MODE:-handsoff}" "$me" "$W" > "$W/.rollover-complete"
EOF
chmod +x "$TMP/stub-ticket.sh"
printf '%s\n' "$TMP/stub-ticket.sh" > "$NEXT"
STUB_SELF="$TMP/stub-ticket.sh" "$SL" testproj --max-sessions 5 --min-lifetime 0 \
  --stall-limit 3 >"$TMP/p3" 2>&1 </dev/null; rc=$?
assert_eq "P3a: exit 0 — ticket transitions are progress" "$rc" "0"

echo "P4: stall detection does not apply in interactive mode"
# The human at the keypress prompt IS the stall detector; halting on them would
# be the supervisor overruling someone who is right there watching.
#
# Run in the background on a bounded wait: under interactive mode the supervisor
# reaches the keypress pause and, on any machine that HAS a controlling terminal,
# correctly sits there forever. That is the behaviour under test, so the suite
# must not wait on it — and must not depend on the tty-less environment that
# would let it exit on its own.
reset
printf '%s\n' "$TMP/stub-bookkeeping.sh" > "$NEXT"
STUB_SELF="$TMP/stub-bookkeeping.sh" STUB_MODE=interactive \
  "$SL" testproj --max-sessions 5 --min-lifetime 0 --stall-limit 1 \
  >"$TMP/p4" 2>&1 </dev/null &
p4_pid=$!
for _ in 1 2 3 4 5 6 7 8 9 10; do
  kill -0 "$p4_pid" 2>/dev/null || break
  sleep 0.5
done
kill "$p4_pid" 2>/dev/null; wait "$p4_pid" 2>/dev/null
export STUB_MODE=handsoff
# P4b first: without it, P4a passes vacuously if the session never ran at all.
assert_contains "P4b: the session ran and was judged" "$(cat "$TMP/p4")" "mode=interactive"
case "$(cat "$TMP/p4")" in *"no progress"*) bad "P4a: interactive mode was stall-halted" ;;
                           *) ok "P4a: interactive mode was not stall-halted" ;; esac

echo "P5: the count is CONSECUTIVE — one real session clears an accrued stall"
# Not dictated by the plan, which leaves the stalled=0 reset uncovered: P1 only
# ever increments and P2/P3 only ever reset from zero. Without this case the
# guard would pass its whole suite while counting cumulatively, and a long,
# healthy chain would eventually halt for having had STALL_LIMIT bad sessions
# scattered across it.
reset
cat > "$TMP/stub-alternating.sh" <<'EOF'
#!/usr/bin/env bash
set -u
W="$STUB_W"; R="$STUB_ROOT"
me="$(tr -cd '0-9' < "$W/.session-seq")"
printf 'block %s\n' "$me" >> "$W/handoff.md"
if [ $((me % 2)) -eq 0 ]; then
  printf 'real work %s\n' "$me" >> "$R/README.md"
fi
git -C "$R" add -A
git -C "$R" commit -qm "session $me"
echo $((me + 1)) > "$W/.session-seq"
printf '%s\n' "$STUB_SELF" > "$W/.next-command"
printf '{"mode":"%s","seq":%s,"reason":"stub","session_id":"sid","runtime":"stub","cwd":"%s"}\n' \
  "${STUB_MODE:-handsoff}" "$me" "$W" > "$W/.rollover-complete"
EOF
chmod +x "$TMP/stub-alternating.sh"
printf '%s\n' "$TMP/stub-alternating.sh" > "$NEXT"
# Sessions 8,10,12 commit README.md; 9,11,13 commit only the ledger. With a limit
# of 2 the chain must reach the cap: a cumulative counter would halt at #11.
STUB_SELF="$TMP/stub-alternating.sh" "$SL" testproj --max-sessions 6 --min-lifetime 0 \
  --stall-limit 2 >"$TMP/p5" 2>&1 </dev/null; rc=$?
assert_eq       "P5a: exit 0 — an intermittent stall never accrues to the limit" "$rc" "0"
assert_eq       "P5b: all 6 sessions ran" "$(cat "$SEQF")" "14"
assert_contains "P5c: stalls WERE counted (1 of 2), not silently ignored" \
                "$(cat "$TMP/p5")" "(1 of 2)"
case "$(cat "$TMP/p5")" in *"(2 of 2)"*) bad "P5d: the counter never reset" ;;
                           *) ok "P5d: the counter reset after each real session" ;; esac

echo "C4a-c: mid-chain, a clean sentinel with nothing staged is a BROKEN chain"
# The s184 shape. Iteration 1 bumps the counter and writes a clean sentinel --
# which ASSERTS a successor was staged, because the sentinel is SKILL.md step 8
# and staging is step 6 -- and stages nothing. Arriving back at the top of the
# loop on an empty .next-command is that contradiction, and it used to break to
# exit 0, indistinguishable from a chain that finished on purpose.
reset; export STUB_BEHAVIOUR=stage-nothing STUB_MODE=handsoff
"$SL" testproj --max-sessions 3 --min-lifetime 0 --stall-limit 0 >"$TMP/c4" 2>&1 </dev/null; rc=$?
assert_eq       "C4a: a broken chain exits 1, not 0" "$rc" "1"
assert_contains "C4b: it says what broke" "$(cat "$TMP/c4")" "staged no successor"
# C4c is CONSUMER-SHAPED (TE6 B2): it pins "no supervisor marker survives a
# halt" — the property L8's stale-pid refusal depends on — not halt()'s own
# `rm`. Under the current trap set (the universal EXIT backstop
# `reap_alarm; rm -f "$LOOPF"`; per-signal TERM/HUP handlers that reap, rm,
# untrap and re-raise; no loop-level INT trap) the exit-1 path always runs the
# EXIT backstop, so halt's own rm is belt-and-braces over it: deleting only
# halt's rm leaves this green, by design.
# Mutation that makes this red: drop `rm -f "$LOOPF"` from BOTH halt() and
# the EXIT trap.
[ ! -f "$W/.session-loop" ] && ok "C4c: no supervisor marker survives a halt" \
                            || bad "C4c: the supervisor marker survived the halt"

echo "C4d-f: the legitimate chain endings are untouched and still exit 0"
reset; export STUB_BEHAVIOUR=normal STUB_MODE=handsoff
"$SL" testproj --max-sessions 1 --min-lifetime 0 --stall-limit 0 >/dev/null 2>&1 </dev/null; rc=$?
assert_eq       "C4d: the MAX_SESSIONS cap still exits 0" "$rc" "0"
reset; export STUB_BEHAVIOUR=quit
"$SL" testproj --max-sessions 3 --min-lifetime 0 --stall-limit 0 >"$TMP/c4e" 2>&1 </dev/null; rc=$?
assert_eq       "C4e: a deliberate quit still exits 0" "$rc" "0"
assert_contains "C4f: and is still classified as deliberate" "$(cat "$TMP/c4e")" "deliberate quit"

echo "A6: a child that fails to run (rc!=0, no sentinel, counter unmoved) halts the chain"
# The s184 class through the seam C4 left open: a missing binary in a
# cron/launchd start makes eval return 127 instantly — no sentinel, delta 0 —
# and the pre-A6 classifier called that "deliberate quit", exit 0. A quit
# verdict now additionally requires the child to have exited 0. (Supervisor
# signal deaths are R6's territory — TERM/HUP re-raise as honest 143/129 and
# never reach this classifier; A6 owns only the classifier-reachable child-rc
# cases.)
# Mutation that makes A6a-A6c red: drop the rc gate from the
# no-sentinel/delta-0 branch (restore the unconditional quit-path exit 0).
reset; printf '%s\n' "$TMP/no-such-binary-anywhere" > "$NEXT"
"$SL" testproj --max-sessions 3 --min-lifetime 0 --stall-limit 0 >"$TMP/a6" 2>&1 </dev/null; rc=$?
assert_eq       "A6a: exit 1 (halt), not 0" "$rc" "1"
# Asserted on the HALT line, not the whole output: the routine per-session
# "ended rc=127" say-line would keep a whole-output grep green under the
# mutation above.
assert_contains "A6b: the HALT names the child's rc" "$(grep 'HALT' "$TMP/a6")" "rc=127"
case "$(cat "$TMP/a6")" in *"deliberate quit"*) bad "A6c: a failed command was called a deliberate quit" ;;
                           *) ok "A6c: a failed command was not called a deliberate quit" ;; esac

# The staged command below is a bare `sleep`, not a stub: these cases are about
# a child that has NOT returned yet, so it must not roll over. It therefore ends
# on the deliberate-quit path (no sentinel, counter unmoved), which is fine --
# nothing here asserts on the supervisor's exit, only on what it said meanwhile.
cat > "$TMP/alarm-notify.sh" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$1" >> "$TF_ALARM_LOG"
EOF
chmod +x "$TMP/alarm-notify.sh"
NOTED="$TMP/alarm-notify.log"; export TF_ALARM_LOG="$NOTED"

echo "D5b-a-c: the stall alarm fires while the child is still running"
reset; printf 'sleep 3\n' > "$NEXT"; : > "$NOTED"
SESSION_LOOP_ALARM=1 SESSION_LOOP_NOTIFY="$TMP/alarm-notify.sh" \
  "$SL" testproj --max-sessions 1 --min-lifetime 0 --stall-limit 0 >/dev/null 2>&1 </dev/null
[ -s "$NOTED" ] && ok "D5b-a: the alarm notified" || bad "D5b-a: the alarm was silent"
assert_contains "D5b-b: the message names the stall" "$(cat "$NOTED")" "running with no exit"
[ "$(wc -l < "$NOTED" | tr -d ' ')" -ge 2 ] \
  && ok "D5b-c: the alarm repeats, so a 03:00 hang keeps signalling" \
  || bad "D5b-c: the alarm fired once and gave up"

echo "D5b-d: SESSION_LOOP_ALARM defaults to off -- today's behaviour, exactly"
reset; printf 'sleep 2\n' > "$NEXT"; : > "$NOTED"
SESSION_LOOP_NOTIFY="$TMP/alarm-notify.sh" \
  "$SL" testproj --max-sessions 1 --min-lifetime 0 --stall-limit 0 >/dev/null 2>&1 </dev/null
[ ! -s "$NOTED" ] && ok "D5b-d: no alarm when the knob is unset" \
                  || bad "D5b-d: the alarm fired without being asked for"

echo "D5b-e: no alarm subshell outlives the child"
# Measured as "the log stops growing once the supervisor has returned". The
# plan's pgrep probe cannot work: a bash subshell keeps its parent's argv, so the
# alarm message never appears in a process line and the probe would pass
# vacuously whether or not the subshell leaked.
reset; printf 'sleep 2\n' > "$NEXT"; : > "$NOTED"
SESSION_LOOP_ALARM=1 SESSION_LOOP_NOTIFY="$TMP/alarm-notify.sh" \
  "$SL" testproj --max-sessions 1 --min-lifetime 0 --stall-limit 0 >/dev/null 2>&1 </dev/null
at_return="$(wc -l < "$NOTED" | tr -d ' ')"
sleep 3
assert_eq "D5b-e: the alarm was reaped with the child" \
          "$(wc -l < "$NOTED" | tr -d ' ')" "$at_return"

echo "D5b-f: the alarm never holds its caller's pipe open after the loop returns"
# kill+wait reaps the alarm subshell, but its in-flight `sleep` is orphaned and
# an orphan keeps the stdout it inherited. A caller using $(...) then blocks for
# the remainder of the alarm interval -- half an hour at a realistic setting --
# after a chain that has already finished. Measured through a command
# substitution because that is the shape that exposes it: D5b-e cannot see this,
# since an orphaned sleep writes nothing to the notify log.
reset; printf 'sleep 1\n' > "$NEXT"
t0="$(date +%s)"
out="$(SESSION_LOOP_ALARM=20 "$SL" testproj --max-sessions 1 --min-lifetime 0 \
       --stall-limit 0 2>&1 </dev/null)"
elapsed=$(( $(date +%s) - t0 ))
[ "$elapsed" -lt 10 ] \
  && ok "D5b-f: the caller was released promptly (${elapsed}s)" \
  || bad "D5b-f: the caller was held ${elapsed}s by a leaked alarm sleep"

echo "D5b-g: a reap landing mid-notify forks no fresh orphan sleep (TE6 A2)"
# The respawn race D5b-f cannot see: eval returns while the alarm subshell is
# INSIDE notify(). pkill -P kills the in-flight hook, the loop then forks a
# fresh `sleep` before the parent's kill lands, and that orphan holds the
# caller's stdout for up to a full interval after the chain already finished.
# Forced deterministically: a hook slow enough (4s) that the child's exit (7s)
# lands inside the notify window (alarm fires at 6s, hook runs to 10s). A leaked
# fresh sleep then holds for a further ALARM=6s (elapsed >=13); a clean reap
# returns with the child (elapsed ~7). The constants are retuned per TE6
# R10(b)(ii): pass ~7s / fail ~13s against a < 10 threshold gives 3s margin
# both ways on a loaded machine (the old 5s/9s pair had only 2s around < 7).
# Measured through $(...) because that is the shape the orphan blocks.
# Mutation that makes this red: drop the stop-flag creation from reap_alarm,
# or the subshell's loop-top stop-flag check — the pre-A2 reap order (measured
# red 6/6 on the pre-fix code).
cat > "$TMP/slow-hook.sh" <<'EOF'
#!/usr/bin/env bash
exec sleep 4
EOF
chmod +x "$TMP/slow-hook.sh"
reset; printf 'sleep 7\n' > "$NEXT"
t0="$(date +%s)"
out="$(SESSION_LOOP_ALARM=6 SESSION_LOOP_NOTIFY="$TMP/slow-hook.sh" \
       "$SL" testproj --max-sessions 1 --min-lifetime 0 --stall-limit 0 2>&1 </dev/null)"
elapsed=$(( $(date +%s) - t0 ))
[ "$elapsed" -lt 10 ] \
  && ok "D5b-g: no orphan from a mid-notify reap (${elapsed}s)" \
  || bad "D5b-g: the reap raced notify and leaked a fresh sleep (held ${elapsed}s)"

echo "D5b-h: a plain kill of the supervisor does not leak the alarm forever (TE6 A3)"
# The operator's documented move against a hung chain: read the pid from
# .session-loop, `kill` it. With no TERM trap the alarm subshell survives
# init-reparented and pages forever. The signal traps defer until the
# in-flight child returns (bash runs a trap only once the foreground command
# completes), then reap and clean up. The alarm fires every 1s;
# frozen-after-exit is the proof of reap.
# Mutation that makes h1 red: drop reap_alarm from BOTH the EXIT trap and the
# TERM/HUP handlers (the pre-A3 rm-only form) — the alarm survives the kill
# and the log grows without bound. (Deleting only the TERM/HUP trap
# installations no longer reddens h1: bash runs the widened EXIT trap even on
# an untrapped signal death, so the alarm is reaped either way — that gap is
# what h4 pins.) h2 is a consumer-shaped
# property, not a pre-A3 detector: measured on the pre-fix code, bash ran the
# EXIT trap on this untrapped TERM and removed the marker anyway, so h2 pins
# "no marker survives a plain kill" under EITHER mechanism; it goes red only
# when the rm is dropped from both traps.
# The child is ONE process (sh -c) that sleeps, then writes a completion
# marker as its last act: the trap is deferred until the foreground CHILD
# returns, so on the trapped path the marker exists by the time the
# supervisor dies. A `sleep N; touch` compound staged bare would not do —
# the deferred trap fires between the two commands. The 6s sleep gives the
# kill (delivered ~1-2s in, after the first 1s alarm) >=3s of remaining
# child runtime either way, per the D5b-g margin retune (TE6 R10(b)(ii)).
reset; printf '%s\n' "sh -c 'sleep 6; : > $W/.h-child-done'" > "$NEXT"; : > "$NOTED"
rm -f "$W/.h-child-done"
SESSION_LOOP_ALARM=1 SESSION_LOOP_NOTIFY="$TMP/alarm-notify.sh" \
  "$SL" testproj --max-sessions 1 --min-lifetime 0 --stall-limit 0 >/dev/null 2>&1 </dev/null &
sup=$!
for _ in 1 2 3 4 5; do [ -s "$NOTED" ] && break; sleep 1; done
# D5b-h0 (TE6 R10(b)(iii)): vacuity guard — if the supervisor already exited
# (the alarm never fired, the NOTED-poll timed out), the kill below is a no-op
# and h1/h2/h3 pass while proving nothing. Fail loudly as inconclusive instead.
# Mutation that makes THIS guard red: stage `sleep 0` as the child — the
# supervisor finishes before the kill and the old fixture passed vacuously.
if kill -0 "$sup" 2>/dev/null; then
  ok "D5b-h0: fixture conclusive — the supervisor is live before the TERM"
else
  bad "D5b-h0: INCONCLUSIVE — the supervisor exited before the TERM was delivered, so h1-h3 prove nothing"
fi
kill "$sup" 2>/dev/null
wait "$sup" 2>/dev/null; h_rc=$?
# Captured the instant wait() returns, for h4 below: in the untrapped world
# the orphaned child writes the marker ~4s LATER, so a delayed check would
# pass vacuously.
[ -f "$W/.h-child-done" ] && h_done=1 || h_done=0
at_exit="$(wc -l < "$NOTED" | tr -d ' ')"
sleep 3
assert_eq "D5b-h1: the alarm died with the TERM'd supervisor" \
          "$(wc -l < "$NOTED" | tr -d ' ')" "$at_exit"
[ ! -f "$W/.session-loop" ] \
  && ok "D5b-h2: the supervisor marker was removed on the signal path" \
  || bad "D5b-h2: .session-loop survived a plain kill — it claims a live supervisor"
# D5b-h3 (TE6 R6): a TERM'd supervisor must die BY the signal — wait() sees
# 128+15=143, a true signal death, not "clean end of chain". The handler
# reaps, removes the marker, untraps, and re-raises.
# Mutation that makes this red: restore the shared bare-`exit` signal trap
# (the post-A3 form, `trap 'reap_alarm; rm -f "$LOOPF"; exit' TERM HUP`) —
# bare `exit` adopts rm's status and wait() reports 0.
assert_eq "D5b-h3: wait() saw a true signal death (143), not a clean exit" "$h_rc" "143"
# D5b-h4: the handlers' distinguishing behavior is DEFERRAL — the TERM landed
# mid-child, yet the supervisor let the child run to completion (its marker
# exists the instant wait() returns) before dying. h1-h3 cannot see this:
# Mutation that makes this red: delete the TERM/HUP trap installations
# (`trap 'on_signal TERM' TERM` / `trap 'on_signal HUP' HUP`) — the untrapped
# TERM kills the supervisor mid-child, before the child's completion marker
# is written; the EXIT trap alone keeps h1-h3 green (bash runs it even on an
# untrapped signal death: alarm reaped, marker removed, wait() still 143).
assert_eq "D5b-h4: the TERM was deferred — the child completed before the supervisor died" \
          "$h_done" "1"
# Red-world hygiene: an un-reaped alarm loops forever; kill it by the unique
# fixture path so a failing run cannot pollute the cases after it.
pkill -f "$MAIN/scripts/session-loop.sh" 2>/dev/null
rm -f "$W/.h-child-done"

echo "D5b-i: a keyboard Ctrl-C the child survives does not end the chain (TE6 R5)"
# Claude's documented cancel-a-turn gesture is a terminal Ctrl-C: INT delivered
# to the whole foreground process group. A real session traps INT and survives
# the cancelled turn; the supervisor must then proceed to normal sentinel
# evaluation, not treat the cancel as the end of the chain. Pre-R5 the
# loop-level trap list included INT: bash deferred the trap until the child
# returned, then ran reap/rm/exit — chain over, rc 0, no evaluation. The
# supervisor is started under `set -m` so it owns a process group the INT can
# be delivered to group-wide, exactly as a terminal would.
cat > "$TMP/stub-int-survivor.sh" <<'EOF'
#!/usr/bin/env bash
set -u
W="$STUB_W"
got_int=0
trap 'got_int=1' INT
me="$(tr -cd '0-9' < "$W/.session-seq")"
: > "$W/.stub-int-running"          # fixture handshake: the INT may be sent now
n=0
while [ "$got_int" -eq 0 ] && [ "$n" -lt 40 ]; do sleep 0.25 || true; n=$((n+1)); done
[ "$got_int" -eq 1 ] && : > "$W/.stub-int-caught"
echo $((me + 1)) > "$W/.session-seq"
printf '%s\n' "$STUB_SELF" > "$W/.next-command"
printf '{"mode":"handsoff","seq":%s,"reason":"stub","session_id":"sid-%s","runtime":"stub","cwd":"%s"}\n' \
  "$me" "$me" "$W" > "$W/.rollover-complete"
EOF
chmod +x "$TMP/stub-int-survivor.sh"
reset; rm -f "$W/.stub-int-running" "$W/.stub-int-caught"
printf '%s\n' "$TMP/stub-int-survivor.sh" > "$NEXT"
set -m
STUB_SELF="$TMP/stub-int-survivor.sh" \
  "$SL" testproj --max-sessions 1 --min-lifetime 0 --stall-limit 0 \
  >"$TMP/d5bi" 2>&1 </dev/null &
i_sup=$!
set +m
n=0
while [ ! -e "$W/.stub-int-running" ] && [ "$n" -lt 40 ]; do sleep 0.25; n=$((n+1)); done
sleep 0.3   # let the stub settle into its wait loop before the "keyboard" INT
kill -INT -"$i_sup" 2>/dev/null
wait "$i_sup" 2>/dev/null; i_rc=$?
# D5b-i1: vacuity guard — the assertions below prove nothing unless the child
# really received AND survived the INT. Mutation that makes i1 red: drop the
# group-wide `kill -INT` delivery above.
[ -e "$W/.stub-int-caught" ] \
  && ok "D5b-i1: fixture conclusive — the child caught the INT and survived it" \
  || bad "D5b-i1: INCONCLUSIVE — the child never saw the INT, so i2/i3 prove nothing"
# D5b-i2: THE R5 ASSERTION. Mutation that makes it red: restore INT to the
# loop-level signal-trap list (the post-A3, pre-R5 form) — the deferred trap
# ends the chain before evaluation and "rolled over cleanly" never prints.
assert_contains "D5b-i2: the chain proceeded to normal sentinel evaluation" \
                "$(cat "$TMP/d5bi")" "rolled over cleanly"
# D5b-i3: the supervisor's exit reflects the chain, not the INT. Mutation that
# makes it red: trap INT with a re-raising per-signal handler
# (`trap 'on_signal INT' INT`) — the deferred re-raise kills the supervisor
# with 130 even though the child survived the cancel.
assert_eq "D5b-i3: supervisor exit reflects the chain, not the INT" "$i_rc" "0"
rm -f "$W/.stub-int-running" "$W/.stub-int-caught"

echo "V4: a FORKED agent under a supervisor still stages its successor"
# README success criterion 3, and the only case that spans all four lanes. The
# fork is simulated exactly as it occurs in the wild: the staged command runs
# with TF_SESSION_LOOP and TF_SESSION_LOOP_PROJECT scrubbed from its environment,
# and the work-item lock is held under a DIFFERENT session id than the one that
# will release it. Unlike every stub above, this child drives the REAL
# single-writers -- context-budget.sh supervised/seq-sync/rollover-complete and
# launch-next-session.sh --emit -- so the four lanes are exercised as shipped:
#   C1 (lane A) the fork decides supervision from disk, not from the environment
#   C2 (lane B) it stages with a BARE --emit; it cannot compute the path
#      itself. Caveat (TE6 B4): this fixture is non-nested ($MAIN is its own
#      git root), so a git-root-resolution bug in the bare emit lands in the
#      same place either way and is INVISIBLE here — E7a in test-emit-mode.sh
#      is the sole detector for that regression class
#   C3 (lane B) a failed emit would be loud, so `|| exit 9` can actually fire
#   C5 (lane C) the launcher releases a lock recorded to the pre-fork session id
# --max-sessions 1 deliberately: the successor --emit stages is the real
# `claude ...` command, and a second iteration would eval it for real.
reset; export STUB_BEHAVIOUR=normal STUB_MODE=handsoff
jq -n '{session_id:"pre-fork",runtime:"claude",project:"testproj",role:"primary"}' \
  > "$W/.active-session"
export V4_MAIN="$MAIN"
cat > "$TMP/forked-session.sh" <<'FORK'
#!/usr/bin/env bash
set -u
unset TF_SESSION_LOOP TF_SESSION_LOOP_PROJECT     # the fork loses them
cd "$V4_MAIN" || exit 9
me="$(tr -cd '0-9' < work/testproj/.session-seq)"
# 1. C1: decide from disk, not from the environment. 0 supervised / 2 ambiguous
#    both stage (design.md R3); 1 unsupervised here means C1 read the env.
./scripts/context-budget.sh supervised --project testproj; sup=$?
[ "$sup" -eq 0 ] || [ "$sup" -eq 2 ] || { echo "V4: read itself as unsupervised (rc=$sup)"; exit 9; }
# 2. the counter's single writer, which also leaves the provenance sidecar
#    rollover-complete reads for its own number (SKILL.md step 5).
./scripts/context-budget.sh seq-sync --project testproj --session "$me" || exit 9
# 3. C2/C3: stage with a bare --emit, loudly (SKILL.md step 6).
./scripts/launch-next-session.sh testproj --emit || exit 9
# 4. the sentinel, SKILL.md step 8.
./scripts/context-budget.sh rollover-complete --project testproj --mode handsoff || exit 9
FORK
chmod +x "$TMP/forked-session.sh"
printf '%s\n' "$TMP/forked-session.sh" > "$NEXT"
"$SL" testproj --max-sessions 1 --min-lifetime 0 --stall-limit 0 >"$TMP/v4" 2>&1; rc=$?
[ -s "$NEXT" ] && ok "V4a: the forked session staged a successor" \
               || bad "V4a: nothing staged -- C1/C2/C3 regression"
[ ! -f "$W/.active-session" ] && ok "V4b: the pre-fork lock was released" \
                             || bad "V4b: lock survived -- C5 regression"
# The emitted prompt is %q-quoted, so the successor's number is matched in the
# quoted form the file actually holds -- not the prose form it reads as.
assert_contains "V4c: what it staged is the real successor command" \
                "$(cat "$NEXT" 2>/dev/null)" 'rollover\ session\ #9.'
assert_contains "V4d: the supervisor judged the iteration clean" "$(cat "$TMP/v4")" "rolled over cleanly"
assert_eq       "V4e: and the chain ended on the cap, not a halt" "$rc" "0"
# V4f (TE6 B3): V4e alone is mis-aimed — rc=0 is ALSO the deliberate-quit
# exit, so a regression that dissolved the chain as a quit kept V4e green
# during a real V4 regression. "chain cap" is printed only on the cap path.
# Mutation that makes V4f red: any fork regression that ends the chain on the
# quit path with rc 0 — the forked session exiting 0 having bumped no counter
# and written no sentinel (demonstrated by staging `true` as the child: rc=0,
# no "chain cap"). The finding's original demonstration (C1 revert -> fork
# exits 9) now halts via the A6 rc gate instead; V4f pins the residual rc-0
# quit shapes.
assert_contains "V4f: 'chain cap' printed — the chain ended on the cap path, not the quit path" \
                "$(cat "$TMP/v4")" "chain cap"
unset V4_MAIN; rm -f "$W/.active-session"

# Unconditional teardown: leave the exported fixture state as the suite's
# default so a later case can never inherit stage-nothing or a live alarm.
unset TF_ALARM_LOG; export STUB_BEHAVIOUR=normal STUB_MODE=handsoff; reset

echo "passed=$PASS failed=$FAIL"
[ "$FAIL" -eq 0 ]
