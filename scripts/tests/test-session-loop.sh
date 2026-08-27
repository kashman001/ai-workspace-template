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
  'work/*/.session-loop.log' 'work/*/.active-session' > "$MAIN/.gitignore"
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

echo "passed=$PASS failed=$FAIL"
[ "$FAIL" -eq 0 ]
