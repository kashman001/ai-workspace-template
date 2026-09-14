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
  'work/*/.session-seq.bump.json' \
  'work/*/.rollover-complete' 'work/*/.next-command' 'work/*/.session-loop' \
  'work/*/.session-loop.log' 'work/*/.session-loop.alarm-stop' \
  'work/*/.session-loop.budget' 'work/*/.chain-closed' \
  'work/*/.active-session' > "$MAIN/.gitignore"
git -C "$MAIN" init -q
git -C "$MAIN" config user.email t@t; git -C "$MAIN" config user.name t
git -C "$MAIN" add -A; git -C "$MAIN" commit -qm init
SL="$MAIN/scripts/session-loop.sh"
W="$MAIN/work/testproj"
SEQF="$W/.session-seq"; SENT="$W/.rollover-complete"; NEXT="$W/.next-command"
BUDGET="$W/.session-loop.budget"; CLOSED="$W/.chain-closed"

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
# What launch-next-session.sh --emit writes at the bump (R2.17 §1): the record
# the supervisor reads its verdict from. `written_by` is the field that says a
# sanctioned writer produced it; a stub standing in for the launcher must
# therefore claim it, and the mutation cases below deliberately do not.
stub_bump() {
  # R2.17 §7 — the supervisor halts a session that rolled over without touching
  # either flush artifact, so a stub standing in for a CLEAN rollover has to
  # produce one. next-session.md rather than handoff.md because it is the file a
  # real rollover always rewrites, and because it is in the stall guard's
  # bookkeeping exclusion set, so writing it here cannot fake progress for the
  # P-series.
  # A monotone nonce, not just the session number: consecutive cases both reset
  # the counter to 8, so "session 8 wrote its number" is byte-identical to the
  # previous case's last write and the post-condition would read it as no flush.
  # Kept outside $W so `git add -A` in the P-series stubs cannot commit it and
  # manufacture progress.
  _nf="$(dirname "$STUB_SELF")/.stub-flush-nonce"
  _n=$(( $(cat "$_nf" 2>/dev/null || echo 0) + 1 )); printf '%s\n' "$_n" > "$_nf"
  printf '# launcher (session %s, flush %s)\n' "$1" "$_n" > "$W/next-session.md"
  printf '{"seq":%s,"successor":%s,"runtime":"stub","session_id":"sid-%s","cwd":"%s","written_at":"%s","mode":"%s","reason":"stub","written_by":"launch-next-session.sh"}\n' \
    "$1" "$(($1 + 1))" "$1" "$W" "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "${STUB_MODE:-handsoff}" \
    > "$W/.session-seq.bump.json"
}
case "${STUB_BEHAVIOUR:-normal}" in
  normal)
    echo $((me + 1)) > "$W/.session-seq"
    printf '%s\n' "$STUB_SELF" > "$W/.next-command"
    printf '{"mode":"%s","seq":%s,"reason":"stub","session_id":"sid-%s","runtime":"stub","cwd":"%s"}\n' \
      "${STUB_MODE:-handsoff}" "$me" "$me" "$W" > "$W/.rollover-complete"
    stub_bump "$me" ;;
  quit)          # human typed /exit: no bump, no sentinel
    : ;;
  stage-nothing) # the s184 shape: a clean rollover that stages no successor
    echo $((me + 1)) > "$W/.session-seq"
    printf '{"mode":"%s","seq":%s,"reason":"stub","session_id":"sid-%s","runtime":"stub","cwd":"%s"}\n' \
      "${STUB_MODE:-handsoff}" "$me" "$me" "$W" > "$W/.rollover-complete" ;;
  died-mid)      # staged, then died before it could do anything else.
                 # Pre-R2.17 this was failure mode 8 (no sentinel -> halt);
                 # under R2.17 the staging call IS the rollover, so the bump
                 # record the launcher wrote at --emit is already the verdict
                 # and this reads CLEAN (R2.17 residual risk 3).
    echo $((me + 1)) > "$W/.session-seq"
    printf '%s\n' "$STUB_SELF" > "$W/.next-command"
    stub_bump "$me" ;;
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
  # --- the mutation floor (R2.17 test plan 1-3) ---------------------------
  # Each writes a BROKEN verdict record and stages a successor correctly, so
  # the only thing under test is whether the supervisor believes the record.
  # Both artifacts are mutated identically: the sentinel is what the pre-R2.17
  # gate reads, the bump record is what the post-R2.17 gate reads, so the same
  # case is meaningful on either side of the fix.
  bare-scalar)   # a bare number where an object belongs: D11's fingerprint
    echo $((me + 1)) > "$W/.session-seq"
    printf '%s\n' "$STUB_SELF" > "$W/.next-command"
    printf '%s\n' "$me" > "$W/.rollover-complete"
    printf '%s\n' "$me" > "$W/.session-seq.bump.json" ;;
  non-json)      # shell-ish key=value, the other hand-written shape
    echo $((me + 1)) > "$W/.session-seq"
    printf '%s\n' "$STUB_SELF" > "$W/.next-command"
    printf 'seq=%s\n' "$me" > "$W/.rollover-complete"
    printf 'seq=%s\n' "$me" > "$W/.session-seq.bump.json" ;;
  # --- R2.21 / D12: a vendor logout (rc 0, no bump, no stage) ------------
  # All three write the artifact a real logout leaves and the session record
  # that attributes it to THIS supervisor (a stub's parent is the supervisor,
  # so $PPID is the same value register would record). They differ only in how
  # the transcript ends, which is the whole of the R2.21 discriminator.
  logout*)
    _d="$(dirname "$STUB_SELF")"; _t="$_d/transcript-$me.jsonl"
    _err='{"type":"assistant","isApiErrorMessage":true,"error":"authentication_failed","message":{"role":"assistant","model":"<synthetic>","content":[{"type":"text","text":"Not logged in \u00b7 Please run /login"}]}}'
    printf '{"type":"user","message":{"role":"user","content":"go"}}\n' > "$_t"
    case "${STUB_BEHAVIOUR}" in
      logout)           # terminal: the error is the last assistant turn, and
                        # the trailing non-assistant lines are what a real
                        # logout transcript carries after it (measured s32)
        printf '%s\n' "$_err" >> "$_t"
        printf '{"type":"system","subtype":"turn_duration"}\n' >> "$_t"
        printf '{"type":"file-history-snapshot"}\n' >> "$_t" ;;
      logout-transient) # the same error, RETRIED successfully: the session
                        # carried on afterwards, so it is not a D12 logout.
                        # This is the 48-of-57 case in the live corpus.
        printf '%s\n' "$_err" >> "$_t"
        printf '{"type":"assistant","message":{"role":"assistant","content":[{"type":"text","text":"back on the air"}]}}\n' >> "$_t" ;;
      logout-textonly)  # a session that merely QUOTED the marker: same text,
                        # no error shape. Text-only matching calls this a
                        # logout; R2.21 must not.
        printf '{"type":"assistant","message":{"role":"assistant","content":[{"type":"text","text":"Not logged in \u00b7 Please run /login"}]}}\n' >> "$_t" ;;
    esac
    printf '{"runtime":"stub","session_id":"logout-%s","artifact":"%s","project":"testproj","supervisor_pid":%s}\n' \
      "$me" "$_t" "$PPID" \
      > "$(cd "$W/../.." && pwd)/.context-budget/sessions/stub-logout-$me-$$.json"
    ;;
  no-identity)   # the s16 class: well-formed JSON, right numbers, no identity
                 # and no writer — nothing sanctioned produced it
    echo $((me + 1)) > "$W/.session-seq"
    printf '%s\n' "$STUB_SELF" > "$W/.next-command"
    printf '{"seq":%s,"successor":%s}\n' "$me" "$((me + 1))" > "$W/.rollover-complete"
    printf '{"seq":%s,"successor":%s}\n' "$me" "$((me + 1))" > "$W/.session-seq.bump.json" ;;
esac
EOF
  chmod +x "$TMP/stub.sh"
}
mk_stub
export STUB_W="$W" STUB_SELF="$TMP/stub.sh"

# D18 — stage a command the way launch-next-session.sh --emit does: the command
# itself AND the identity sidecar the supervisor's bootstrap reads to decide
# whether a staged command is this chain's own unconsumed work or debris left by
# an earlier one. Every PRE-START staging in this suite goes through here; hand-
# writing the pair in twenty-five places is how the next edit forgets one, and a
# forgotten sidecar is indistinguishable from the R3 case below.
#
# The stubs deliberately do NOT write one: they stage mid-chain, and the sidecar
# is read at the bootstrap and nowhere else (every later iteration consumes
# $NEXTF before its run, so a non-empty file there is provably the chain's own).
#
# $2 overrides written_at, which is what makes an ALREADY-CONSUMED command
# expressible: a staging that predates a session record for the same work item.
stage_next() {   # $1 = command line, $2 = written_at override (optional)
  printf '%s\n' "$1" > "$NEXT"
  jq -n --arg project testproj \
        --argjson seq "$(( $(tr -cd '0-9' < "$SEQF") - 1 ))" \
        --argjson successor "$(tr -cd '0-9' < "$SEQF")" \
        --arg runtime stub \
        --arg session_id "sid-staged" \
        --arg written_at "${2:-$(date -u +%Y-%m-%dT%H:%M:%SZ)}" \
        --arg command_cksum "$(cksum < "$NEXT")" \
        '{project:$project, seq:$seq, successor:$successor, runtime:$runtime,
          session_id:$session_id, written_at:$written_at,
          command_cksum:$command_cksum, written_by:"launch-next-session.sh"}' \
    > "$NEXT.json"
}

reset() { printf '8\n' > "$SEQF"; rm -f "$SENT" "$NEXT" "$NEXT.json" "$NEXT.stale" \
                                        "$W/.session-loop" "$BUDGET" "$CLOSED";
          stage_next "$TMP/stub.sh"; }

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

echo "L3 (R2.17): a session that staged and then died reads CLEAN, not as a halt"
# RE-POINTED, deliberately (R2.17 test plan 4). Before R2.17 the sentinel was
# written after staging, so "staged, no sentinel" meant the session died
# mid-rollover and the chain halted for a human. R2.17 removes the sentinel:
# the staging call IS the rollover and the bump record is the verdict, so the
# same crash now continues the chain, with a successor reading artifacts that
# were finished at step 5. A deliberate loosening; this is where it is reviewed.
reset; export STUB_BEHAVIOUR=died-mid
"$SL" testproj --max-sessions 2 --min-lifetime 0 --stall-limit 0 >"$TMP/o3" 2>&1 </dev/null; rc=$?
assert_eq       "L3a: exit 0, not a halt"     "$rc" "0"
case "$(cat "$TMP/o3")" in *"HALT"*) bad "L3b: a staged-then-died session halted the chain" ;;
                           *) ok "L3b: a staged-then-died session did not halt the chain" ;; esac
assert_contains "L3c: it was judged a clean rollover" "$(cat "$TMP/o3")" "rolled over cleanly"

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

echo "M1-M3: the mutation floor — a verdict record the supervisor cannot trust"
# R2.17 test plan 1-3. These are the mutations D11 actually produced on live
# chains: an agent that hand-wrote the verdict instead of running the sanctioned
# writer. Each stub stages its successor correctly and bumps the counter by
# exactly 1, so nothing EXCEPT the record's trustworthiness is under test — if
# the supervisor reads it and shrugs, it will relaunch a chain whose last
# session never really finished.
for mut in bare-scalar non-json no-identity; do
  reset; export STUB_BEHAVIOUR="$mut"
  "$SL" testproj --max-sessions 2 --min-lifetime 0 --stall-limit 0 >"$TMP/om" 2>&1 </dev/null; rc=$?
  assert_eq       "M-$mut a: exit 1 (halt)"        "$rc" "1"
  assert_contains "M-$mut b: halted and notified"  "$(cat "$TMP/om")" "HALT"
  # A halt that names no session number is the D11 fingerprint itself: the
  # supervisor read a field that was not there and printed the empty string.
  case "$(cat "$TMP/om")" in
    *"session # "*|*"session #  "*|*"claims session # "*)
      bad "M-$mut c: the halt message names an empty session number" ;;
    *) ok "M-$mut c: the halt message is not itself malformed" ;;
  esac
done

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
# R2.17: the verdict the supervisor now reads. Every aux stub below stands in
# for a session whose rollover ran the sanctioned writer, so it must produce the
# record that writer produces -- and must leave a flush behind (R2.17 section 7).
stub_r217() {
  _nf="$(dirname "$STUB_SELF")/.stub-flush-nonce"
  _n=$(( $(cat "$_nf" 2>/dev/null || echo 0) + 1 )); printf '%s\n' "$_n" > "$_nf"
  printf '# launcher (session %s, flush %s)\n' "$1" "$_n" > "$W/next-session.md"
  printf '{"seq":%s,"successor":%s,"runtime":"stub","session_id":"sid","cwd":"%s","written_at":"2026-01-01T00:00:00Z","mode":"%s","reason":"stub","written_by":"launch-next-session.sh"}\n' \
    "$1" "$(($1 + 1))" "$W" "${STUB_MODE:-handsoff}" > "$W/.session-seq.bump.json"
}
printf 'block %s\n' "$me" >> "$W/handoff.md"
printf 'launcher %s\n' "$me" > "$W/next-session.md"
git -C "$R" add work/testproj/handoff.md work/testproj/next-session.md
git -C "$R" commit -qm "work(testproj): rollover bookkeeping $me"
echo $((me + 1)) > "$W/.session-seq"
printf '%s\n' "$STUB_SELF" > "$W/.next-command"
printf '{"mode":"%s","seq":%s,"reason":"stub","session_id":"sid","runtime":"stub","cwd":"%s"}\n' \
  "${STUB_MODE:-handsoff}" "$me" "$W" > "$W/.rollover-complete"
stub_r217 "$me"
EOF
chmod +x "$TMP/stub-bookkeeping.sh"
stage_next "$TMP/stub-bookkeeping.sh"
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
# R2.17: the verdict the supervisor now reads. Every aux stub below stands in
# for a session whose rollover ran the sanctioned writer, so it must produce the
# record that writer produces -- and must leave a flush behind (R2.17 section 7).
stub_r217() {
  _nf="$(dirname "$STUB_SELF")/.stub-flush-nonce"
  _n=$(( $(cat "$_nf" 2>/dev/null || echo 0) + 1 )); printf '%s\n' "$_n" > "$_nf"
  printf '# launcher (session %s, flush %s)\n' "$1" "$_n" > "$W/next-session.md"
  printf '{"seq":%s,"successor":%s,"runtime":"stub","session_id":"sid","cwd":"%s","written_at":"2026-01-01T00:00:00Z","mode":"%s","reason":"stub","written_by":"launch-next-session.sh"}\n' \
    "$1" "$(($1 + 1))" "$W" "${STUB_MODE:-handsoff}" > "$W/.session-seq.bump.json"
}
printf 'block %s\n' "$me" >> "$W/handoff.md"
printf 'real work %s\n' "$me" >> "$R/README.md"
git -C "$R" add -A
git -C "$R" commit -qm "feat: real work $me"
echo $((me + 1)) > "$W/.session-seq"
printf '%s\n' "$STUB_SELF" > "$W/.next-command"
printf '{"mode":"%s","seq":%s,"reason":"stub","session_id":"sid","runtime":"stub","cwd":"%s"}\n' \
  "${STUB_MODE:-handsoff}" "$me" "$W" > "$W/.rollover-complete"
stub_r217 "$me"
EOF
chmod +x "$TMP/stub-progress.sh"
stage_next "$TMP/stub-progress.sh"
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
# R2.17: the verdict the supervisor now reads. Every aux stub below stands in
# for a session whose rollover ran the sanctioned writer, so it must produce the
# record that writer produces -- and must leave a flush behind (R2.17 section 7).
stub_r217() {
  _nf="$(dirname "$STUB_SELF")/.stub-flush-nonce"
  _n=$(( $(cat "$_nf" 2>/dev/null || echo 0) + 1 )); printf '%s\n' "$_n" > "$_nf"
  printf '# launcher (session %s, flush %s)\n' "$1" "$_n" > "$W/next-session.md"
  printf '{"seq":%s,"successor":%s,"runtime":"stub","session_id":"sid","cwd":"%s","written_at":"2026-01-01T00:00:00Z","mode":"%s","reason":"stub","written_by":"launch-next-session.sh"}\n' \
    "$1" "$(($1 + 1))" "$W" "${STUB_MODE:-handsoff}" > "$W/.session-seq.bump.json"
}
printf 'block %s\n' "$me" >> "$W/handoff.md"
printf 'status: done\n' > "$W/issues/t$me.md"
git -C "$R" add -A
git -C "$R" commit -qm "chore: ticket $me"
echo $((me + 1)) > "$W/.session-seq"
printf '%s\n' "$STUB_SELF" > "$W/.next-command"
printf '{"mode":"%s","seq":%s,"reason":"stub","session_id":"sid","runtime":"stub","cwd":"%s"}\n' \
  "${STUB_MODE:-handsoff}" "$me" "$W" > "$W/.rollover-complete"
stub_r217 "$me"
EOF
chmod +x "$TMP/stub-ticket.sh"
stage_next "$TMP/stub-ticket.sh"
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
stage_next "$TMP/stub-bookkeeping.sh"
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
# R2.17: the verdict the supervisor now reads. Every aux stub below stands in
# for a session whose rollover ran the sanctioned writer, so it must produce the
# record that writer produces -- and must leave a flush behind (R2.17 section 7).
stub_r217() {
  _nf="$(dirname "$STUB_SELF")/.stub-flush-nonce"
  _n=$(( $(cat "$_nf" 2>/dev/null || echo 0) + 1 )); printf '%s\n' "$_n" > "$_nf"
  printf '# launcher (session %s, flush %s)\n' "$1" "$_n" > "$W/next-session.md"
  printf '{"seq":%s,"successor":%s,"runtime":"stub","session_id":"sid","cwd":"%s","written_at":"2026-01-01T00:00:00Z","mode":"%s","reason":"stub","written_by":"launch-next-session.sh"}\n' \
    "$1" "$(($1 + 1))" "$W" "${STUB_MODE:-handsoff}" > "$W/.session-seq.bump.json"
}
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
stub_r217 "$me"
EOF
chmod +x "$TMP/stub-alternating.sh"
stage_next "$TMP/stub-alternating.sh"
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
reset; stage_next "$TMP/no-such-binary-anywhere"
"$SL" testproj --max-sessions 3 --min-lifetime 0 --stall-limit 0 >"$TMP/a6" 2>&1 </dev/null; rc=$?
assert_eq       "A6a: exit 1 (halt), not 0" "$rc" "1"
# Asserted on the HALT line, not the whole output: the routine per-session
# "ended rc=127" say-line would keep a whole-output grep green under the
# mutation above.
assert_contains "A6b: the HALT names the child's rc" "$(grep 'HALT' "$TMP/a6")" "rc=127"
case "$(cat "$TMP/a6")" in *"deliberate quit"*) bad "A6c: a failed command was called a deliberate quit" ;;
                           *) ok "A6c: a failed command was not called a deliberate quit" ;; esac

echo "T22 (R2.21/D12): a vendor logout is not a human quit"
# A logout exits 0, stages nothing and leaves the counter unmoved -- byte for
# byte the A6 quit shape, which is why it was misreported as a deliberate quit
# on seven live sessions. The only thing that separates them is the child's own
# transcript, so these cases vary ONLY the transcript and hold everything else
# fixed.
#
# Mutation that makes T22a-T22e red: delete the `if ... dead_child_artifact`
# block from the no-sentinel/delta-0/rc-0 branch in session-loop.sh (restore
# the unconditional quit path). T22h-T22k are the discrimination cases and stay
# green under that mutation on purpose -- see below.
reset; export STUB_BEHAVIOUR=logout
"$SL" testproj --max-sessions 3 --min-lifetime 0 --stall-limit 0 >"$TMP/t22" 2>&1 </dev/null; rc=$?
assert_eq       "T22a: exit 1 (halt), not 0" "$rc" "1"
case "$(cat "$TMP/t22")" in *"deliberate quit"*) bad "T22b: a logout was called a deliberate quit" ;;
                            *) ok "T22b: a logout was not called a deliberate quit" ;; esac
assert_contains "T22c: the HALT names the cause" "$(grep 'HALT' "$TMP/t22")" "vendor logout"
assert_contains "T22d: it says nothing was lost" "$(grep 'HALT' "$TMP/t22")" "Nothing was lost"
assert_contains "T22e: it prints the resume command" \
  "$(grep 'HALT' "$TMP/t22")" "scripts/session-loop.sh testproj"
# Part 4: budget_write runs at session START, so without the refund a logout
# would permanently spend a slot for four minutes of nothing. The refund reads
# no file -- it writes back the count this process incremented itself -- so it
# cannot turn an unreadable budget into a zero (the D9 invariant R2.19 closed).
assert_eq       "T22f: the logout did not charge a budget slot" \
  "$(jq -r '.used' "$BUDGET")" "0"
assert_eq       "T22g: and the budget is otherwise intact" \
  "$(jq -r '.cap' "$BUDGET")" "3"

# The two discriminators. Both are rc-0/no-stage/delta-0 sessions whose
# transcripts CONTAIN the marker, and both must still be read as quits: a
# terminal auth failure is the last assistant turn in the file, and it is
# matched on the error shape rather than on the text.
reset; export STUB_BEHAVIOUR=logout-transient
"$SL" testproj --max-sessions 3 --min-lifetime 0 --stall-limit 0 >"$TMP/t22h" 2>&1 </dev/null; rc=$?
assert_eq       "T22h: an auth error the session recovered from is still a quit" "$rc" "0"
assert_contains "T22i: and is classified as one" "$(cat "$TMP/t22h")" "deliberate quit"

reset; export STUB_BEHAVIOUR=logout-textonly
"$SL" testproj --max-sessions 3 --min-lifetime 0 --stall-limit 0 >"$TMP/t22j" 2>&1 </dev/null; rc=$?
assert_eq       "T22j: a session that merely quoted the marker is still a quit" "$rc" "0"
assert_contains "T22k: and is classified as one" "$(cat "$TMP/t22j")" "deliberate quit"

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
reset; stage_next 'sleep 3'; : > "$NOTED"
SESSION_LOOP_ALARM=1 SESSION_LOOP_NOTIFY="$TMP/alarm-notify.sh" \
  "$SL" testproj --max-sessions 1 --min-lifetime 0 --stall-limit 0 >/dev/null 2>&1 </dev/null
[ -s "$NOTED" ] && ok "D5b-a: the alarm notified" || bad "D5b-a: the alarm was silent"
assert_contains "D5b-b: the message names the stall" "$(cat "$NOTED")" "running with no exit"
[ "$(wc -l < "$NOTED" | tr -d ' ')" -ge 2 ] \
  && ok "D5b-c: the alarm repeats, so a 03:00 hang keeps signalling" \
  || bad "D5b-c: the alarm fired once and gave up"

echo "D5b-d: SESSION_LOOP_ALARM defaults to off -- today's behaviour, exactly"
reset; stage_next 'sleep 2'; : > "$NOTED"
SESSION_LOOP_NOTIFY="$TMP/alarm-notify.sh" \
  "$SL" testproj --max-sessions 1 --min-lifetime 0 --stall-limit 0 >/dev/null 2>&1 </dev/null
# The quit-path chain-ended notification lands in the log too (N-series);
# "off by default" means no STALL message, not an empty log.
grep -q "running with no exit" "$NOTED" \
  && bad "D5b-d: the alarm fired without being asked for" \
  || ok "D5b-d: no alarm when the knob is unset"

echo "D5b-e: no alarm subshell outlives the child"
# Measured as "the log stops growing once the supervisor has returned". The
# plan's pgrep probe cannot work: a bash subshell keeps its parent's argv, so the
# alarm message never appears in a process line and the probe would pass
# vacuously whether or not the subshell leaked.
reset; stage_next 'sleep 2'; : > "$NOTED"
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
reset; stage_next 'sleep 1'
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
# The chain-ended quit notification runs the same hook synchronously on the
# way out; let it through fast so elapsed still measures only the alarm reap,
# keeping the tuned 3s margins intact.
cat > "$TMP/slow-hook.sh" <<'EOF'
#!/usr/bin/env bash
case "$1" in *"chain ended"*) exit 0 ;; esac
exec sleep 4
EOF
chmod +x "$TMP/slow-hook.sh"
reset; stage_next 'sleep 7'
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
reset; stage_next "sh -c 'sleep 6; : > $W/.h-child-done'"; : > "$NOTED"
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
# R2.17: the verdict the supervisor now reads. Every aux stub below stands in
# for a session whose rollover ran the sanctioned writer, so it must produce the
# record that writer produces -- and must leave a flush behind (R2.17 section 7).
stub_r217() {
  _nf="$(dirname "$STUB_SELF")/.stub-flush-nonce"
  _n=$(( $(cat "$_nf" 2>/dev/null || echo 0) + 1 )); printf '%s\n' "$_n" > "$_nf"
  printf '# launcher (session %s, flush %s)\n' "$1" "$_n" > "$W/next-session.md"
  printf '{"seq":%s,"successor":%s,"runtime":"stub","session_id":"sid","cwd":"%s","written_at":"2026-01-01T00:00:00Z","mode":"%s","reason":"stub","written_by":"launch-next-session.sh"}\n' \
    "$1" "$(($1 + 1))" "$W" "${STUB_MODE:-handsoff}" > "$W/.session-seq.bump.json"
}
: > "$W/.stub-int-running"          # fixture handshake: the INT may be sent now
n=0
while [ "$got_int" -eq 0 ] && [ "$n" -lt 40 ]; do sleep 0.25 || true; n=$((n+1)); done
[ "$got_int" -eq 1 ] && : > "$W/.stub-int-caught"
echo $((me + 1)) > "$W/.session-seq"
printf '%s\n' "$STUB_SELF" > "$W/.next-command"
printf '{"mode":"handsoff","seq":%s,"reason":"stub","session_id":"sid-%s","runtime":"stub","cwd":"%s"}\n' \
  "$me" "$me" "$W" > "$W/.rollover-complete"
stub_r217 "$me"
EOF
chmod +x "$TMP/stub-int-survivor.sh"
reset; rm -f "$W/.stub-int-running" "$W/.stub-int-caught"
stage_next "$TMP/stub-int-survivor.sh"
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

# ---------------------------------------------------------------------------
# R2.18 (D7 items 1 and 3) — the alarm's trigger is transcript silence, not
# wall-clock. Every case below stands a child that maintains its OWN
# .active-session record and transcript, which is what a registered session
# does: child_probe reads the pid from that record, checks it is a live child of
# this supervisor, then ages the artifact the session record names.
# ---------------------------------------------------------------------------
cat > "$TMP/probe-child.sh" <<'EOF'
#!/usr/bin/env bash
# $1 = session_id, $2 = touches, $3 = seconds between touches, $4 = tail sleep
set -u
sid="$1"; touches="$2"; gap="$3"; tail_sleep="$4"
art="$PC_TMP/transcript-$sid.jsonl"
: > "$art"; : > "$PC_TMP/touches-$sid.log"; date +%s >> "$PC_TMP/touches-$sid.log"
printf '{"runtime":"stub","session_id":"%s","project":"testproj","pid":%s,"pid_start":"x","supervisor_pid":%s}\n' \
  "$sid" "$$" "$PPID" > "$PC_W/.active-session"
printf '{"runtime":"stub","session_id":"%s","artifact":"%s","project":"testproj","pid":%s}\n' \
  "$sid" "$art" "$$" > "$PC_MAIN/.context-budget/sessions/stub-$sid.json"
# Session 34: record every write, so the test can check the fixture's premise
# ("this child writes every ${gap}s") actually held. Under load the child can be
# starved off-CPU for longer than the alarm interval, at which point a silence
# report is CORRECT and asserting against it tests nothing.
i=0
while [ "$i" -lt "$touches" ]; do
  : > "$art"; date +%s >> "$PC_TMP/touches-$sid.log"; sleep "$gap"; i=$((i+1))
done
sleep "$tail_sleep"
: > "$PC_W/.probe-child-done"
EOF
chmod +x "$TMP/probe-child.sh"
export PC_TMP="$TMP" PC_W="$W" PC_MAIN="$MAIN"

echo "R2.18-a: a child that is still writing draws a log line, never a page"
# Constants retuned in session 34, against measurement, for BOTH flakes this
# case carried for four sessions. The old pair was `live 8 1 0` at ALARM=2.
#  - a3 (quantization): child_probe ages the transcript with two whole-second
#    clocks, so its answer carries +/-1s. A 1s touch gap against `age < ALARM=2`
#    is a one-second margin against a one-second error, and `quant.sh` in the
#    work directory reproduces the crossing deterministically (a real 1.2s gap
#    reports as 2s once the write lands past ~0.7 into a wall-clock second).
#    ALARM=4 against the same 1s gap gives 3s of margin. The field runs
#    ALARM=900, so this was never a production defect.
#  - a2 (pre-registration): the alarm subshell is forked BEFORE `eval "$CMD"`,
#    so its clock starts before the child exists. Under load the first tick beat
#    the child's own `.active-session` write, child_probe returned nothing, and
#    the deliberate unidentified branch paged. Measured session 34: 6/12 loaded
#    runs, and in every one the unidentified tick was the FIRST tick of the run
#    and the only one (instrumented per-return-point trace; the `ps -o ppid=`
#    liveness race that session 33 hypothesised fired zero times in 35 ticks).
#    12 touches keep three ticks inside the writing phase, so a1 stays
#    conclusive.
reset; rm -f "$W/.active-session" "$W/.probe-child-done"; : > "$NOTED"
# The supervisor log is CUMULATIVE across this whole suite, and the D5b cases
# above deliberately emit "running with no exit" and "is still running". Truncate
# it here so a1's conclusiveness check and a2's window below are scoped to THIS
# case's own run — otherwise a1 can pass on an earlier test's line while this
# child was never identified at all, and a2's window can open on a line that is
# not ours. Safe: L7a only checks the file exists, and it runs long before this.
: > "$W/.session-loop.log"
_a_alarm=4        # one name for the constant a3's premise guard has to agree with
stage_next "$TMP/probe-child.sh live 14 1 0"
SESSION_LOOP_ALARM="$_a_alarm" SESSION_LOOP_NOTIFY="$TMP/alarm-notify.sh" \
  "$SL" testproj --max-sessions 1 --min-lifetime 0 --stall-limit 0 >/dev/null 2>&1 </dev/null
# Vacuity guard: with no alarm tick at all, a-2 and a-3 pass while proving
# nothing. The supervisor log is where the fresh-path line lands.
grep -q "is still running (transcript written" "$W/.session-loop.log" \
  && ok "R2.18-a1: fixture conclusive — the probe identified the child and ran" \
  || bad "R2.18-a1: INCONCLUSIVE — the probe never identified the child, so a2/a3 prove nothing"
# a2 is WINDOW-aware, and margin alone is not what makes it sound. `notify`
# calls `say`, so pages and still-running lines land in ONE file, in order. a2
# fails only for a no-exit page that lands BETWEEN the first and last successful
# identification — the window in which the child was demonstrably alive and
# writing, so losing it is the R2.18 defect shape. Session 34 measured two
# distinct benign causes at the two boundaries, neither of them a production
# defect, and a blanket grep cannot tell either from a real regression:
#   - BEFORE the first identification: the alarm subshell is forked before
#     `eval "$CMD"`, so its clock starts before the child exists; under load the
#     first tick beat the child's own `.active-session` write (5-6 of 12 loaded
#     runs, always the first tick).
#   - AFTER the last identification: the tick due at the child's exit races it,
#     `ps -o ppid=` finds the pid already gone (traced: `ps_ppid=[] alive=n`),
#     and the unidentified branch pages a session that ended cleanly (1 tick in
#     41 loaded ticks, always the last). 14 touches against ALARM=4 put ticks at
#     t=4/8/12 and the child's exit at t=14, so the exit no longer COLLIDES with
#     a due tick the way the old 8-touch/ALARM=2 pair did (exit and tick both at
#     t=8, which made the race a coin flip on every run) — while still leaving
#     three identifications, so a2's window below is real and not a single point.
# Both reach the same deliberate branch — no identification, no verdict, never a
# kill — and the field's ALARM=900 puts both boundaries seconds from a 15-minute
# tick. Limitation, stated: a2 cannot see a defect that pages ONLY on the very
# first or very last tick. That is the price of not re-chasing these two for a
# fifth session, and a1 still covers the case where nothing is ever identified.
_a_idents="$(grep -n "is still running (transcript written" "$W/.session-loop.log" | cut -d: -f1)"
_a_first_ident="$(printf '%s\n' "$_a_idents" | head -1)"
_a_last_ident="$(printf '%s\n' "$_a_idents" | tail -1)"
if [ -z "$_a_first_ident" ]; then
  echo "  note: R2.18-a2 not evaluated — nothing was ever identified, which is a1's case"
else
  _a_mid_noexit="$(grep -n "running with no exit" "$W/.session-loop.log" | cut -d: -f1 \
    | awk -v f="$_a_first_ident" -v l="$_a_last_ident" '$1 > f && $1 < l' | wc -l | tr -d ' ')"
  [ "$_a_mid_noexit" -gt 0 ] \
    && bad "R2.18-a2: a session the probe had identified as writing was paged as a stall — the R2.18 defect itself" \
    || ok "R2.18-a2: no page for a session the probe had identified as writing"
  grep -q "running with no exit" "$W/.session-loop.log" \
    && echo "  note: R2.18-a2 saw a boundary no-exit tick (pre-registration or exit race — fixture timing, measured session 34, not a defect)"
fi
# a3 is PREMISE-GUARDED. It asserts "a session that IS writing is not called
# silent", so it is only a real assertion while the fixture child really was
# writing faster than the alarm interval. Under load the child gets starved off
# -CPU: session 34 measured a true 4s gap at ALARM=4 (the alarm's own `sleep 4`
# stretched to 7s in the same run), and a silence report against a genuinely 4s
# -silent transcript is the supervisor being RIGHT. Both a3 reds seen in 24
# loaded runs were this, at age=4 — not the +/-1s quantization `quant.sh`
# reproduces, which the ALARM 2->4 retune above already put 3 steps out of
# reach. Starvation cannot be fixed by margin, because load stretches the
# interval the margin is measured against; it can only be detected, so an
# unmet premise reports INCONCLUSIVE rather than red — the same discipline a1
# and D5b-i1 already use.
_a3_max_gap="$(awk 'NR>1{d=$1-p; if(d>m)m=d} {p=$1} END{print m+0}' \
               "$TMP/touches-live.log" 2>/dev/null)"
if [ -z "$_a3_max_gap" ]; then
  bad "R2.18-a3: INCONCLUSIVE — the child recorded no writes, so its premise is unknown"
elif [ "$_a3_max_gap" -ge "$_a_alarm" ]; then
  echo "  note: R2.18-a3 INCONCLUSIVE — the child was starved ${_a3_max_gap}s (>= ALARM=$_a_alarm), so a silence report would be correct; not evaluated"
else
  grep -q "written nothing" "$NOTED" \
    && bad "R2.18-a3: a writing session was reported as silent (child's worst gap was only ${_a3_max_gap}s)" \
    || ok "R2.18-a3: a writing session was not called silent"
fi

echo "R2.18-b: a child that has stopped writing IS paged, and named as silent"
reset; rm -f "$W/.active-session" "$W/.probe-child-done"; : > "$NOTED"
stage_next "$TMP/probe-child.sh mute 1 0 6"
SESSION_LOOP_ALARM=1 SESSION_LOOP_NOTIFY="$TMP/alarm-notify.sh" \
  "$SL" testproj --max-sessions 1 --min-lifetime 0 --stall-limit 0 >/dev/null 2>&1 </dev/null
[ -s "$NOTED" ] && ok "R2.18-b1: the silent child was paged" \
                || bad "R2.18-b1: a silent child drew no page"
assert_contains "R2.18-b2: the page names transcript silence, not wall-clock" \
  "$(cat "$NOTED")" "has written nothing for"
[ -f "$W/.probe-child-done" ] \
  && ok "R2.18-b3: KILL_AFTER defaults to 0 — the silent child ran to completion" \
  || bad "R2.18-b3: the child was killed with SESSION_LOOP_KILL_AFTER unset"

echo "R2.18-c: SESSION_LOOP_KILL_AFTER ends a silent child, and the chain halts"
reset; rm -f "$W/.active-session" "$W/.probe-child-done"; : > "$NOTED"
stage_next "$TMP/probe-child.sh dead 1 0 60"
c_start="$(date +%s)"
SESSION_LOOP_ALARM=1 SESSION_LOOP_KILL_AFTER=3 SESSION_LOOP_NOTIFY="$TMP/alarm-notify.sh" \
  "$SL" testproj --max-sessions 1 --min-lifetime 0 --stall-limit 0 >"$TMP/c18" 2>&1 </dev/null; c_rc=$?
c_elapsed=$(( $(date +%s) - c_start ))
[ "$c_elapsed" -lt 30 ] \
  && ok "R2.18-c1: the supervisor returned in ${c_elapsed}s, not after the child's 60s" \
  || bad "R2.18-c1: the supervisor blocked ${c_elapsed}s — the kill never landed"
[ ! -f "$W/.probe-child-done" ] \
  && ok "R2.18-c2: the child died before its completion marker" \
  || bad "R2.18-c2: the child survived the kill"
assert_contains "R2.18-c3: the kill was announced before it was delivered" \
  "$(cat "$NOTED")" "ending it"
# A killed child leaves no successor and an unmoved counter. R2.17 §2 / TE6 A6
# must call that broken, NOT a deliberate quit — a kill is the supervisor's own
# doing and is the loudest thing it can report.
assert_eq       "R2.18-c4: exit 1 (halt), not a clean chain end" "$c_rc" "1"
assert_contains "R2.18-c5: the HALT names the signal death" \
  "$(grep 'HALT' "$TMP/c18")" "rc=143"
case "$(cat "$TMP/c18")" in *"deliberate quit"*) bad "R2.18-c6: a killed session was called a deliberate quit" ;;
                            *) ok "R2.18-c6: a killed session was not called a deliberate quit" ;; esac

echo "R2.18-d: the probe refuses a record that does not name OUR live child"
# The identity gate, and the reason nothing here kills on missing evidence: a
# stale .active-session naming a foreign pid (1 = always live, never our child)
# must fall back to the pre-R2.18 unconditional message and must not be killed.
reset; rm -f "$W/.probe-child-done"; : > "$NOTED"
printf '{"runtime":"stub","session_id":"foreign","project":"testproj","pid":1,"pid_start":"x","supervisor_pid":1}\n' \
  > "$W/.active-session"
printf '{"runtime":"stub","session_id":"foreign","artifact":"%s","project":"testproj"}\n' \
  "$TMP/foreign-transcript" > "$MAIN/.context-budget/sessions/stub-foreign.json"
: > "$TMP/foreign-transcript"; touch -t 200001010000 "$TMP/foreign-transcript"
stage_next "sh -c 'sleep 4; : > $W/.probe-child-done'"
SESSION_LOOP_ALARM=1 SESSION_LOOP_KILL_AFTER=2 SESSION_LOOP_NOTIFY="$TMP/alarm-notify.sh" \
  "$SL" testproj --max-sessions 1 --min-lifetime 0 --stall-limit 0 >/dev/null 2>&1 </dev/null
assert_contains "R2.18-d1: an unidentified child keeps the pre-R2.18 message" \
  "$(cat "$NOTED")" "running with no exit"
[ -f "$W/.probe-child-done" ] \
  && ok "R2.18-d2: nothing was killed on a record the probe could not verify" \
  || bad "R2.18-d2: a child was killed on an unverified record"
rm -f "$W/.active-session"

echo "R2.18-e: repeat pages back off, so a multi-day hang is not 368 identical pages"
reset; rm -f "$W/.active-session" "$W/.probe-child-done"; : > "$NOTED"
stage_next "$TMP/probe-child.sh backoff 1 0 9"
SESSION_LOOP_ALARM=1 SESSION_LOOP_ALARM_MAX=4 SESSION_LOOP_NOTIFY="$TMP/alarm-notify.sh" \
  "$SL" testproj --max-sessions 1 --min-lifetime 0 --stall-limit 0 >/dev/null 2>&1 </dev/null
e_n="$(wc -l < "$NOTED" | tr -d ' ')"
# 1+2+4+4 over ~9s of silence is 3-4 pages; a flat 1s interval is 8-9. The upper
# bound is the assertion, the lower one is the vacuity guard.
[ "$e_n" -ge 2 ] \
  && ok "R2.18-e1: fixture conclusive — the silent child was paged ($e_n)" \
  || bad "R2.18-e1: INCONCLUSIVE — only $e_n pages, so e2 proves nothing"
[ "$e_n" -le 5 ] \
  && ok "R2.18-e2: the interval backed off ($e_n pages over ~9s at a 1s base)" \
  || bad "R2.18-e2: no backoff — $e_n pages over ~9s at a 1s base"
rm -f "$W/.active-session"

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
# R2.17 section 1: the launcher refuses to bump without an identity while a
# supervisor is live. A real session has one because `register` writes BOTH the
# lock and this record; the fixture wrote only the lock, so it modelled a state
# no registered session is ever in.
jq -n '{session_id:"pre-fork",runtime:"claude",project:"testproj"}' \
  > "$MAIN/.context-budget/sessions/claude-pre-fork.json"
export V4_MAIN="$MAIN"
cat > "$TMP/forked-session.sh" <<'FORK'
#!/usr/bin/env bash
set -u
unset TF_SESSION_LOOP TF_SESSION_LOOP_PROJECT     # the fork loses them
# D17: a real claude session names itself by exporting this, and the launcher's
# supervised identity refusal now keys on that positive identity rather than on
# the newest record claiming the project. The record below is still required --
# it is the other half of the same check.
export CLAUDE_CODE_SESSION_ID=pre-fork
cd "$V4_MAIN" || exit 9
me="$(tr -cd '0-9' < work/testproj/.session-seq)"
# 0. the flush (R2.17 section 7): the supervisor halts a rollover that left both
#    next-session.md and handoff.md byte-identical, so the fork has to do what a
#    real rollover's step 1 does.
printf '# launcher (V4 session %s)\n' "$me" > work/testproj/next-session.md
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
stage_next "$TMP/forked-session.sh"
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

echo "V5 (D10): a chain where seq-sync has NEVER run still produces an acceptable sentinel"
# The regression D10 names. V4 above passes only because its child calls
# seq-sync, which writes the provenance sidecar rollover-complete used to read.
# An ordinary chain never needs a counter repair, so that sidecar is never
# refreshed and the sentinel stamped a months-old number — the supervisor then
# halted a chain in which nothing was wrong. This child is V4's minus step 5:
# same REAL single-writers, no seq-sync anywhere, and (below) no sidecar on disk
# at all, which is the state a fresh work item is actually in.
reset; export STUB_BEHAVIOUR=normal STUB_MODE=handsoff
rm -f "$W/.session-seq.provenance.json" "$W/.session-seq.bump.json"
jq -n '{session_id:"nosync",runtime:"claude",project:"testproj"}' \
  > "$MAIN/.context-budget/sessions/claude-nosync.json"
export V5_MAIN="$MAIN"
cat > "$TMP/nosync-session.sh" <<'NOSYNC'
#!/usr/bin/env bash
set -u
cd "$V5_MAIN" || exit 9
export CLAUDE_CODE_SESSION_ID=nosync     # D17: see the V4 fixture above
printf '# launcher (V5 %s)\n' "$(tr -cd '0-9' < work/testproj/.session-seq)" \
  > work/testproj/next-session.md
./scripts/launch-next-session.sh testproj --emit || exit 9
./scripts/context-budget.sh rollover-complete --project testproj --mode handsoff || exit 9
NOSYNC
chmod +x "$TMP/nosync-session.sh"
stage_next "$TMP/nosync-session.sh"
"$SL" testproj --max-sessions 1 --min-lifetime 0 --stall-limit 0 >"$TMP/v5" 2>&1; rc=$?
assert_eq       "V5a: the sentinel carries the number that actually ran" \
                "$(jq -r '.seq' "$SENT" 2>/dev/null)" "8"
assert_contains "V5b: the supervisor accepted the handover" "$(cat "$TMP/v5")" "rolled over cleanly"
assert_eq       "V5c: the chain ended on the cap, not a halt" "$rc" "0"
[ ! -f "$W/.session-seq.provenance.json" ] \
  && ok "V5d: no seq-sync ran — the sidecar the old code read does not even exist" \
  || bad "V5d: something ran seq-sync; the case is not testing what it claims"

echo "V5e-g (D10): a seq-sync repair retires the bump record rather than losing to it"
# The precedence has to run both ways. After a repair the counter no longer
# matches what the bump recorded, so the stale bump record must step aside for
# the sidecar the repair just wrote.
reset
rm -f "$W/.session-seq.provenance.json" "$W/.session-seq.bump.json" "$SENT"
( cd "$MAIN" && ./scripts/launch-next-session.sh testproj --emit >/dev/null 2>&1 )
assert_eq "V5e: --emit recorded its own number in the bump record" \
          "$(jq -r '.seq' "$W/.session-seq.bump.json" 2>/dev/null)" "8"
"$MAIN/scripts/context-budget.sh" seq-sync --project testproj --session 12 >/dev/null 2>&1
( cd "$MAIN" && ./scripts/context-budget.sh rollover-complete --project testproj --mode handsoff >/dev/null 2>&1 )
assert_eq "V5f: the repaired number wins over the retired bump record" \
          "$(jq -r '.seq' "$SENT" 2>/dev/null)" "12"
assert_eq "V5g: and the bump record itself was left alone, not rewritten" \
          "$(jq -r '.successor' "$W/.session-seq.bump.json" 2>/dev/null)" "9"
unset V5_MAIN; rm -f "$W/.session-seq.provenance.json" "$W/.session-seq.bump.json"

# Unconditional teardown: leave the exported fixture state as the suite's
# default so a later case can never inherit stage-nothing or a live alarm.
unset TF_ALARM_LOG; export STUB_BEHAVIOUR=normal STUB_MODE=handsoff; reset

echo "N: notify-on-quit — a chain end is pushed through notify, not just logged"
cat > "$TMP/notify.sh" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$1" >> "$NOTIFY_LOG"
EOF
chmod +x "$TMP/notify.sh"
export NOTIFY_LOG="$TMP/notify.log"

echo "N1: quit with no ledger — generic chain-ended notification, external path fires"
reset; rm -f "$W/handoff.md" "$W/session_handoff.md"; export STUB_BEHAVIOUR=quit
: > "$NOTIFY_LOG"
SESSION_LOOP_NOTIFY="$TMP/notify.sh" "$SL" testproj --max-sessions 3 >"$TMP/n1" 2>&1 </dev/null; rc=$?
assert_eq       "N1a: exit 0 stays"               "$rc" "0"
assert_contains "N1b: chain-ended in output"      "$(cat "$TMP/n1")" "chain ended"
assert_contains "N1c: external notify path fired" "$(cat "$NOTIFY_LOG")" "chain ended: session #8 quit"

echo "N2: top ledger block == the quitting session — quit was recorded"
printf '# Session Handoff — 8 (2026-08-31): wrapped up\n' > "$W/handoff.md"
reset; export STUB_BEHAVIOUR=quit
: > "$NOTIFY_LOG"
SESSION_LOOP_NOTIFY="$TMP/notify.sh" "$SL" testproj --max-sessions 3 >"$TMP/n2" 2>&1 </dev/null; rc=$?
assert_eq       "N2a: exit 0 stays"              "$rc" "0"
assert_contains "N2b: recorded-quit message"     "$(cat "$NOTIFY_LOG")" "quit after writing its ledger block"

echo "N3: top ledger block behind the quitting session — unrecorded quit named"
printf '# Session Handoff — 7 (2026-08-30): older block\n' > "$W/handoff.md"
reset; export STUB_BEHAVIOUR=quit
: > "$NOTIFY_LOG"
SESSION_LOOP_NOTIFY="$TMP/notify.sh" "$SL" testproj --max-sessions 3 >"$TMP/n3" 2>&1 </dev/null; rc=$?
assert_eq       "N3a: exit 0 stays"               "$rc" "0"
assert_contains "N3b: unrecorded quit named"      "$(cat "$NOTIFY_LOG")" "WITHOUT a rollover"
assert_contains "N3c: names the actual top block" "$(cat "$NOTIFY_LOG")" "top block is session 7"
rm -f "$W/handoff.md"; unset NOTIFY_LOG; export STUB_BEHAVIOUR=normal STUB_MODE=handsoff; reset

# ---------------------------------------------------------------------------
# B-series (R2.19 / D9): the chain budget outlives the supervisor process.
#
# The defect these pin: `n` was a shell variable, so every restart reopened the
# full cap. work/policy-dev-onboarding/.session-loop.log has #18, #19, #20 and
# #27 each opening at "1 of 10" straight after a HALT — sixteen sessions of work
# under a cap of ten, which never fired once.
# ---------------------------------------------------------------------------
echo "B1: a spent budget survives the supervisor and the next start resumes it"
reset; export STUB_BEHAVIOUR=normal STUB_MODE=handsoff
"$SL" testproj --max-sessions 2 --min-lifetime 0 --stall-limit 0 >/dev/null 2>&1 </dev/null || true
assert_eq "B1a: two sessions recorded as used" "$(jq -r '.used' "$BUDGET" 2>/dev/null)" "2"
assert_eq "B1b: the cap is recorded alongside" "$(jq -r '.cap'  "$BUDGET" 2>/dev/null)" "2"
# Restart the SUPERVISOR without resetting the chain: exactly what an operator
# does after a halt. Only .session-loop/.next-command are cleared, never $BUDGET.
rm -f "$W/.session-loop"; stage_next "$TMP/stub.sh"
out="$("$SL" testproj --max-sessions 5 --min-lifetime 0 --stall-limit 0 2>&1 </dev/null || true)"
assert_contains "B1c: the restart resumes, it does not reopen"        "$out" "resuming the chain budget at 2 of 5"
assert_contains "B1d: the counter continues, it does not restart at 1" "$out" "(3 of 5)"
assert_eq "B1e: the budget reached the cap" "$(jq -r '.used' "$BUDGET")" "5"
assert_eq "B1f: five sessions of work in total" "$(cat "$SEQF")" "13"

echo "B2: a start on a spent budget refuses without burning a session number"
# The refusal must land ahead of the bootstrap: --emit bumps .session-seq, so a
# supervisor that only discovered the cap at the `while` would spend a session
# number on a session it was never going to run.
rm -f "$W/.session-loop" "$NEXT"
seq_before_refusal="$(cat "$SEQF")"
out="$("$SL" testproj --max-sessions 5 --min-lifetime 0 --stall-limit 0 2>&1 </dev/null || true)"
assert_contains "B2a: refused with the cap verdict" "$out" "chain cap reached (5 of 5"
assert_contains "B2b: the remedy is named"          "$out" "--reset-cap"
assert_eq       "B2c: the counter did not move"     "$(cat "$SEQF")" "$seq_before_refusal"
assert_eq       "B2d: nothing was staged"           "$([ -s "$NEXT" ] && echo staged || echo none)" "none"

echo "B3: --reset-cap opens a new budget and the next start is fresh"
out="$("$SL" testproj --reset-cap 2>&1 </dev/null || true)"
assert_contains "B3a: the reset reports what it spent" "$out" "chain budget reset (5 of"
assert_eq       "B3b: the budget file is gone"         "$([ -f "$BUDGET" ] && echo present || echo gone)" "gone"
stage_next "$TMP/stub.sh"
out="$("$SL" testproj --max-sessions 2 --min-lifetime 0 --stall-limit 0 2>&1 </dev/null || true)"
assert_contains "B3c: the fresh budget starts at one" "$out" "(1 of 2)"

echo "B4: --reset-cap is refused under a live supervisor"
# R2.4's reason: the running loop persists .used before every child, so a reset
# landing underneath it is silently overwritten on the next iteration.
jq -n --argjson pid "$$" --arg project testproj --arg started_at now \
  '{pid:$pid, project:$project, started_at:$started_at}' > "$W/.session-loop"
out="$("$SL" testproj --reset-cap 2>&1 </dev/null || true)"
assert_contains "B4a: refused, naming the live supervisor" "$out" "already running for testproj"
assert_eq       "B4b: the budget was left alone"           "$(jq -r '.used' "$BUDGET" 2>/dev/null)" "2"
rm -f "$W/.session-loop"

echo "B5: a malformed budget halts rather than being read as zero"
# Reading an unparseable budget as "none used" would restore D9 exactly, and
# self-healing a malformed control file is declined on this work item (D11
# candidate 5). The remedy it names must itself survive the corruption.
reset; printf '{"used":"not-a-number"}\n' > "$BUDGET"
"$SL" testproj --max-sessions 5 --min-lifetime 0 --stall-limit 0 >"$TMP/b5" 2>&1 </dev/null; rc=$?
out="$(cat "$TMP/b5")"
assert_eq       "B5a: exit 1, not a quiet start"  "$rc" "1"
assert_contains "B5b: named as unreadable"        "$out" "chain budget"
assert_contains "B5c: the remedy is named"        "$out" "--reset-cap"
assert_eq       "B5d: it did not stage a session" "$(cat "$SEQF")" "8"
out="$("$SL" testproj --reset-cap 2>&1 </dev/null || true)"
assert_contains "B5e: --reset-cap survives the corruption it is the remedy for" "$out" "chain budget reset"
reset

# ---------------------------------------------------------------------------
# N-series (D18): the bootstrap's freshness test. Iteration 1 is the ONE place
# the supervisor runs a command it did not stage itself, and until R2.20 its test
# for "is this one safe to run" was `[ -s "$NEXTF" ]` — NON-EMPTY read as FRESH.
#
# The defect these pin is in work/*/handoff-archive.md (the session-18 addendum):
# a rollover staged the command that launched #18, a human ran it, the rollover
# that followed was hands-on and never refreshed the file, and a supervisor
# started afterwards inherited the spent command and ran it a second time. Two
# sessions numbered 18; the second took the work item's lock and committed
# nothing.
#
# N1 and N2 are the two halves of the same judgement and must be read together.
# The tempting one-line fix — stage unconditionally on iteration 1 — makes R1
# green and R2 red, because a supervisor killed between a child's --emit and the
# next iteration's consume leaves a command that is genuinely unrun. Discarding
# THAT burns a session number and loses the mode and options it carries. So the
# bootstrap does not ask "is something staged", it asks "has it been run".
#
# Mutation: replace the gate with `if [ ! -s "$NEXTF" ]` -> N1 and N3 red.
# Mutation: replace it with an unconditional stage -> N2 red.
# ---------------------------------------------------------------------------
# The bootstrap reaches its child through a `claude` shim on PATH, for F1's
# reason: what is under test is the command the LAUNCHER emits, not one this
# suite wrote.
mkdir -p "$TMP/bin"
printf '#!/usr/bin/env bash\nexec "%s"\n' "$TMP/stub.sh" > "$TMP/bin/claude"
chmod +x "$TMP/bin/claude"
# Every N case starts from a plain terminal, never from inside a session — the
# same env hygiene F1 needs, for the same reason.
run_bootstrap() {   # -> $out, $rc
  PATH="$TMP/bin:$PATH" env -u CLAUDE_CODE_SESSION_ID -u CODEX_THREAD_ID \
    -u COPILOT_AGENT_SESSION_ID -u VSCODE_TARGET_SESSION_LOG -u OPENCODE_SESSION_ID \
    "$SL" testproj --max-sessions 1 --min-lifetime 0 --stall-limit 0 \
    >"$TMP/rout" 2>&1 </dev/null; rc=$?
  out="$(cat "$TMP/rout")"
}

echo "N1: a staged command that has ALREADY been run is not inherited (the s18 defect)"
reset; export STUB_BEHAVIOUR=normal STUB_MODE=handsoff
# The shape of a spent command: staged at T, and a session registered against
# this work item after T. That session IS the consumer — nothing else can say so,
# because "staged for #8" and "staged for #8 and already run" both leave the
# counter at 8.
stage_next "$TMP/stub.sh" "2000-01-01T00:00:00Z"
N1REC="$MAIN/.context-budget/sessions/stub-already-ran.json"
# runtime is "claude", NOT the suite-wide "stub" convention, and that is load-
# bearing. N1 is one of the three cases that drive the REAL launcher (the rest
# pre-stage .next-command in reset(), so --emit never runs), and there this
# record is authoritative: own_record() picks the newest record for the project
# and launch-next-session.sh reads RUNTIME off it. "stub" is not in the
# launcher's valid-runtime enumeration, so the bootstrap's re-stage would die
# with "unknown runtime: stub" and the supervisor would halt — testing the
# enumeration instead of the consumption check. "claude" matches
# ROLLOVER_RUNTIME in context-budget.env and the fake claude run_bootstrap puts
# on PATH, and it is what a real consuming session's record would carry anyway.
printf '{"runtime":"claude","session_id":"already-ran","project":"testproj","registered_at":"2000-01-02T00:00:00Z"}\n' > "$N1REC"
run_bootstrap
assert_eq       "N1a: exit 0, not a halt"                    "$rc" "0"
assert_contains "N1b: the spent command was discarded"       "$out" "discarding the staged command"
assert_contains "N1c: named as already run"                  "$out" "already been run"
assert_contains "N1d: and a fresh session was staged"        "$out" "staging the first session"
assert_contains "N1e: the session that ran is the NEW one"   "$out" "starting session #9"
case "$out" in *"starting session #8"*)
    bad "N1f: session #8 ran a second time — the duplicate-session defect" ;;
  *) ok "N1f: no session number ran twice" ;; esac
assert_eq       "N1g: the counter advanced 8 -> 10 (bootstrap + the session)" "$(cat "$SEQF")" "10"
assert_eq       "N1h: the discarded command was kept as evidence" \
                "$([ -s "$NEXT.stale" ] && echo kept || echo lost)" "kept"
rm -f "$N1REC"

echo "N2: a staged command nobody has run IS inherited (a killed supervisor resumes)"
# The other half of R1. No session record postdates this staging, so the command
# is this chain's own unconsumed work and discarding it would burn a number.
reset; export STUB_BEHAVIOUR=normal STUB_MODE=handsoff
stage_next "$TMP/stub.sh"
run_bootstrap
assert_eq       "N2a: exit 0, not a halt"                  "$rc" "0"
assert_contains "N2b: the staged command was inherited"    "$out" "inheriting the staged command"
case "$out" in *"staging the first session"*)
    bad "N2c: it re-staged over an unrun command — a session number was burned" ;;
  *) ok "N2c: it did not re-stage over an unrun command" ;; esac
assert_contains "N2d: the staged session is the one that ran" "$out" "starting session #8"
assert_eq       "N2e: the counter advanced 8 -> 9 (the session alone)" "$(cat "$SEQF")" "9"

echo "N3: a staged command with no identity at all is not inherited"
# The pre-R2.20 shape, and anything hand-written since: a bare command string
# with nothing saying who wrote it or when. Unprovable is not fresh.
reset; export STUB_BEHAVIOUR=normal STUB_MODE=handsoff
rm -f "$NEXT.json"
run_bootstrap
assert_eq       "N3a: exit 0, not a halt"              "$rc" "0"
assert_contains "N3b: discarded for want of identity"  "$out" "no identity sidecar"
assert_contains "N3c: and a fresh session was staged"  "$out" "staging the first session"
assert_eq       "N3d: the counter advanced 8 -> 10"    "$(cat "$SEQF")" "10"

echo "N4: a staged command whose sidecar does not match it is not inherited"
# A half-pair: the sidecar is valid and unconsumed but describes different bytes,
# which is what a hand-edited .next-command looks like.
reset; export STUB_BEHAVIOUR=normal STUB_MODE=handsoff
stage_next "$TMP/stub.sh"
printf '%s\n' "$TMP/stub.sh --tampered" > "$NEXT"
run_bootstrap
assert_contains "N4a: discarded on the checksum"      "$out" "does not match the checksum"
assert_contains "N4b: and a fresh session was staged" "$out" "staging the first session"
reset

# ---------------------------------------------------------------------------
# W-series: the bootstrap run from inside a git WORKTREE. The N-series above is
# single-checkout only — not one of its cases resolves ROOT from a worktree, and
# the failure class is not hypothetical here: session-loop.sh:14-19 exists
# because a bare relative work/<proj>/.rollover-complete once landed in an
# isolated child's own worktree while the supervisor read the main checkout,
# found nothing, and exited reporting a clean shutdown.
#
# What CANNOT break, and therefore has no case here: the command and its sidecar
# cannot be separated by a worktree. The sidecar path is built by concatenation
# from the command path (launch-next-session.sh, emit_id="$EMIT.json"), so it is
# the same directory or neither file exists. There is no code path to test.
#
# The real question is WHICH work/<proj>/ the pair lives in, and the answer is
# the resolver: session-loop.sh:21-31 and launch-next-session.sh:60-70 are the
# same implementation byte for byte, and both anchor on SCRIPT_ROOT — the
# script's own location — then go through `git rev-parse --git-common-dir`. So
# even the WORKTREE'S OWN COPY of the supervisor resolves ROOT to the main
# checkout. That is what these cases invoke: not the main script with a worktree
# cwd (which the resolver never reads), but $WT/scripts/session-loop.sh, cwd
# inside $WT. If the resolver regresses to SCRIPT_ROOT, W1/W3/W4 go red.
#
# L7 already probes a worktree cwd, but through the MAIN checkout's script,
# where SCRIPT_ROOT is the main checkout whatever the resolver does — so it can
# only catch a path built relative to cwd, never a bad resolution. These cases
# are the other half: the resolver is the only thing standing between the
# supervisor and the wrong work/<proj>/, and iteration 1 is the only iteration
# that reads a pair it did not write.
#
# Deliberately named to parallel the W-series in test-launch-next-session.sh,
# which covers the third worktree guard — the sync-the-main-checkout refusals at
# launch-next-session.sh:233-252 — from the LAUNCHER's side. That one is already
# tested there (its W1/W2/W8); nothing here duplicates it.
#
# Mutation: make resolve_workspace_root print "$SCRIPT_ROOT" unconditionally
#   -> W1 (reads a worktree with no staged pair), W3 (registry invisible, the
#      spent command is inherited), W4 (the worktree's stale pair IS picked up).
# Mutation: relax the --emit absolute-path guard to accept a relative path
#   -> W2 red.
# ---------------------------------------------------------------------------
# wt3, not wt: $TMP/wt is the bare directory L4's `stranded` stub writes into,
# and $TMP/wt2 is L7's worktree. Reusing either name makes `worktree add` die
# "already exists" and every case below fails on a missing script — a fixture
# fault wearing a product fault's clothes, which is why the checkout is asserted
# as a precondition rather than assumed.
WT="$TMP/wt3"
git -C "$MAIN" worktree add -q --detach "$WT" HEAD
WTW="$WT/work/testproj"

# The supervisor as a worktree sees it: its own checked-out copy, cwd inside the
# worktree, same env hygiene every N case needs.
run_bootstrap_wt() {   # -> $out, $rc
  ( cd "$WT" && PATH="$TMP/bin:$PATH" env -u CLAUDE_CODE_SESSION_ID -u CODEX_THREAD_ID \
      -u COPILOT_AGENT_SESSION_ID -u VSCODE_TARGET_SESSION_LOG -u OPENCODE_SESSION_ID \
      "$WT/scripts/session-loop.sh" testproj --max-sessions 1 --min-lifetime 0 --stall-limit 0 \
      >"$TMP/rout" 2>&1 </dev/null ); rc=$?
  out="$(cat "$TMP/rout")"
}
# Runtime state the SUPERVISOR itself writes, as opposed to anything the stub
# does: if ROOT ever resolved to the worktree, these are the files that would
# appear there.
wt_state() { ls -A "$WTW" 2>/dev/null | grep -c '^\.'; }

echo "W1: the supervisor's own worktree copy still roots at the MAIN checkout"
# N2's scenario — an unrun staged command is inherited — run through the
# worktree. The pair exists only in the main checkout (.next-command is
# gitignored, so the worktree has no copy of it and never could).
reset; export STUB_BEHAVIOUR=normal STUB_MODE=handsoff
stage_next "$TMP/stub.sh"
assert_eq       "W1a: precondition — the worktree has its own copy of the supervisor" \
                "$([ -x "$WT/scripts/session-loop.sh" ] && echo present || echo missing)" "present"
assert_eq       "W1b: precondition — but no staged pair (.next-command is gitignored)" \
                "$([ -e "$WTW/.next-command" ] && echo present || echo absent)" "absent"
run_bootstrap_wt
assert_eq       "W1c: exit 0, not a halt"                    "$rc" "0"
assert_contains "W1d: it found the MAIN checkout's staged command" "$out" "inheriting the staged command"
assert_contains "W1e: and ran the session it names"          "$out" "starting session #8"
assert_eq       "W1f: the MAIN counter advanced 8 -> 9"      "$(cat "$SEQF")" "9"
assert_eq       "W1g: the supervisor's bookkeeping landed in the main checkout" \
                "$([ -f "$BUDGET" ] && echo main || echo missing)" "main"
assert_eq       "W1h: and NOTHING was written into the worktree's work dir" "$(wt_state)" "0"

echo "W2: --emit refuses a relative path — from inside a worktree, where it matters"
# The layer-1 invariant at launch-next-session.sh:129-133, pinned so it cannot be
# quietly relaxed. Parse time, above every side effect: a relative path would be
# resolved against the CALLER's cwd, which here is the worktree, and the pair
# would land where no supervisor will ever look for it.
( cd "$WT" && "$WT/scripts/launch-next-session.sh" testproj \
    --emit work/testproj/.next-command ) >"$TMP/w2" 2>&1; rc=$?
w2="$(cat "$TMP/w2")"
assert_eq       "W2a: exit 3 (a startup refusal)"        "$rc" "3"
assert_contains "W2b: refused for being relative"        "$w2" "requires an absolute path"
assert_contains "W2c: and the reason names this hazard"  "$w2" "caller's own worktree"
assert_eq       "W2d: no pair was written into the worktree" \
                "$([ -e "$WTW/.next-command" ] && echo written || echo none)" "none"

echo "W3: the consumption check reads the MAIN registry, not a worktree-local one"
# N1's scenario — a command already spent by a session that ran after it was
# staged — run through the worktree. The session registry lives at
# $ROOT/.context-budget/sessions and is untracked, so the worktree has no copy:
# a supervisor that rooted itself in the worktree would see an empty registry,
# find nothing postdating the staging, and re-run the spent command. That is the
# session-18 duplicate-session defect, reached by a different road.
reset; export STUB_BEHAVIOUR=normal STUB_MODE=handsoff
stage_next "$TMP/stub.sh" "2000-01-01T00:00:00Z"
W3REC="$MAIN/.context-budget/sessions/stub-wt-already-ran.json"
# "claude" rather than the suite-wide "stub" convention, for N1's reason: this
# case drives the REAL launcher at the re-stage, and "stub" is not in its
# valid-runtime enumeration.
printf '{"runtime":"claude","session_id":"wt-already-ran","project":"testproj","registered_at":"2000-01-02T00:00:00Z"}\n' > "$W3REC"
assert_eq       "W3a: precondition — the registry is invisible from the worktree" \
                "$([ -e "$WT/.context-budget/sessions" ] && echo visible || echo invisible)" "invisible"
run_bootstrap_wt
assert_eq       "W3b: exit 0, not a halt"                   "$rc" "0"
assert_contains "W3c: the spent command was discarded"      "$out" "discarding the staged command"
assert_contains "W3d: named as already run"                 "$out" "already been run"
assert_contains "W3e: and the session that ran is the NEW one" "$out" "starting session #9"
case "$out" in *"starting session #8"*)
    bad "W3f: session #8 ran a second time — the duplicate-session defect, via a worktree" ;;
  *) ok "W3f: no session number ran twice" ;; esac
# The bootstrap's own writes — the parked evidence and the re-staged pair — are
# where --emit @auto put them, which is the main checkout. This is the end-to-end
# proof that @auto resolves through the resolver and not through cwd.
assert_eq       "W3g: the discarded command was parked in the MAIN checkout" \
                "$([ -s "$NEXT.stale" ] && echo main || echo missing)" "main"
# The re-staged pair itself is NOT observable after the chain: the supervisor
# consumes $NEXTF and $NEXTIDF before the run (session-loop.sh:676), and the stub
# that follows stages mid-chain, which by design writes no sidecar. So the
# bootstrap's --emit @auto is proved by its effects on the MAIN checkout instead
# — the counter it bumped, and the session that ran off the command it wrote.
assert_eq       "W3h: the MAIN counter advanced 8 -> 10 (bootstrap + the session)" \
                "$(cat "$SEQF")" "10"
assert_eq       "W3i: the worktree's work dir is still untouched" "$(wt_state)" "0"
rm -f "$W3REC"

echo "W4: a stale pair sitting in a WORKTREE is never picked up by the main supervisor"
# The negative, and the one case where the pair in the worktree is deliberately
# perfect: fresh timestamp, matching checksum, sanctioned writer — everything the
# freshness test looks for. It is ignored not because it fails a check but
# because the supervisor never looks in that directory at all.
reset; rm -f "$NEXT" "$NEXT.json"   # the main checkout has nothing staged
export STUB_BEHAVIOUR=normal STUB_MODE=handsoff
mkdir -p "$WTW"
printf '%s\n' "$TMP/stub.sh --from-the-worktree" > "$WTW/.next-command"
jq -n --arg project testproj \
      --argjson seq 7 --argjson successor 8 \
      --arg runtime claude --arg session_id "sid-worktree" \
      --arg written_at "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
      --arg command_cksum "$(cksum < "$WTW/.next-command")" \
      '{project:$project, seq:$seq, successor:$successor, runtime:$runtime,
        session_id:$session_id, written_at:$written_at,
        command_cksum:$command_cksum, written_by:"launch-next-session.sh"}' \
  > "$WTW/.next-command.json"
run_bootstrap_wt
assert_eq       "W4a: exit 0, not a halt"                   "$rc" "0"
assert_contains "W4b: it staged a first session of its own"  "$out" "staging the first session"
case "$out" in *"inheriting the staged command"*)
    bad "W4c: it inherited a command from the worktree — the main checkout staged nothing" ;;
  *) ok "W4c: it inherited nothing" ;; esac
case "$out" in *--from-the-worktree*)
    bad "W4d: the worktree's command was executed" ;;
  *) ok "W4d: the worktree's command was never executed" ;; esac
assert_eq       "W4e: the MAIN counter advanced 8 -> 10 (bootstrap + the session)" \
                "$(cat "$SEQF")" "10"
assert_eq       "W4f: the worktree's pair was neither consumed nor parked" \
                "$([ -s "$WTW/.next-command" ] && [ ! -e "$WTW/.next-command.stale" ] && echo intact || echo touched)" "intact"
rm -f "$WTW/.next-command" "$WTW/.next-command.json"

# Teardown inside the case, not at EXIT: the suite rm -rf's $TMP, and a worktree
# registered against a directory that no longer exists leaves metadata behind in
# $MAIN/.git/worktrees for every later git call in this suite to trip over.
git -C "$MAIN" worktree remove --force "$WT" >/dev/null 2>&1 || rm -rf "$WT"
git -C "$MAIN" worktree prune >/dev/null 2>&1 || true
reset

echo "F1: a chain starts from a fresh work item — the supervisor stages session 1 itself"
# The bootstrap, end to end, and the only case in this suite that exercises it:
# reset() pre-stages .next-command for every other case, so the real launcher
# call at "staging the first session" never runs in them. That gap is how the
# identity refusal in launch-next-session.sh came to make a fresh chain
# unstartable while all 64 cases here stayed green — the supervisor writes
# .session-loop before it stages, and the supervisor is not a session, so the
# refusal fired on the one caller that cannot register.
#
# The child is reached through a `claude` shim on PATH rather than a staged
# path, because what is under test is the command the LAUNCHER emits, not one
# this suite wrote: the bootstrap's whole job is producing that command.
#
# Mutation: drop the invoked_by_supervisor clause from the launcher's identity
# refusal -> F1a-F1d red on "HALT: could not stage the first session".
# Mutation: wrap session-loop.sh's bootstrap call in $(...) or a pipeline -> the
# launcher's parent becomes a subshell instead of the supervisor, and the same
# halt returns. This case is that tripwire.
reset; rm -f "$NEXT"   # the fresh-work-item state: nothing staged for iteration 1
export STUB_BEHAVIOUR=normal STUB_MODE=handsoff
mkdir -p "$TMP/bin"
printf '#!/usr/bin/env bash\nexec "%s"\n' "$TMP/stub.sh" > "$TMP/bin/claude"
chmod +x "$TMP/bin/claude"
# A fresh work item has no session record ANYWHERE, and that is load-bearing
# rather than tidiness: the launcher's identity read falls back past the env
# table to the newest record claiming this project, so the records the cases
# above leave behind would supply an identity a new work item cannot have — and
# the refusal under test would never be reached (measured: with them in place
# this case passes against the unfixed launcher). Moved aside, not deleted, so
# the suite stays re-runnable in any order.
mkdir -p "$TMP/f1-aside"
mv "$MAIN/.context-budget/sessions/"*.json "$TMP/f1-aside/" 2>/dev/null || true
# ...and no inherited session id either: the supervisor is started from a plain
# terminal, never from inside a session, so the env leg must be empty too.
PATH="$TMP/bin:$PATH" env -u CLAUDE_CODE_SESSION_ID -u CODEX_THREAD_ID \
  -u COPILOT_AGENT_SESSION_ID -u VSCODE_TARGET_SESSION_LOG -u OPENCODE_SESSION_ID \
  "$SL" testproj --max-sessions 1 --min-lifetime 0 --stall-limit 0 \
  >"$TMP/f1" 2>&1 </dev/null; rc=$?
mv "$TMP/f1-aside/"*.json "$MAIN/.context-budget/sessions/" 2>/dev/null || true
out="$(cat "$TMP/f1")"
assert_eq       "F1a: exit 0, not a halt"                    "$rc" "0"
assert_contains "F1b: the supervisor staged the first session" "$out" "staging the first session"
case "$out" in *"could not stage the first session"*)
    bad "F1c: the bootstrap was refused — a fresh chain cannot start" ;;
  *) ok "F1c: the bootstrap was not refused" ;; esac
assert_contains "F1d: the staged session actually ran"       "$out" "starting session #9"
assert_contains "F1e: and was judged a clean rollover"       "$out" "rolled over cleanly"
assert_eq       "F1f: the counter advanced 8 -> 10 (bootstrap + the session)" "$(cat "$SEQF")" "10"
reset

# ---------------------------------------------------------------------------
# K: P6 — .chain-closed. A chain that ended on a DELIBERATE QUIT leaves a
# marker, and a supervisor refuses to restart that work item without an
# explicit human act. This is scenario-table row B2: three prose countermeasures
# in skills/session-rollover/SKILL.md failed on it, so the countermeasure here is
# mechanical.
#
# The K-series is written around one asymmetry: there is exactly ONE writer
# (the deliberate-quit branch, below the logout discriminator) and that is the
# whole argument that every H-row stays silent. K4/K5/K6 are that argument as
# tests — each is an exit path that must leave NO marker, and each was a live
# chain-ending shape before P6 existed.
# ---------------------------------------------------------------------------

echo "K1: a deliberate quit leaves a .chain-closed marker naming the session"
reset; export STUB_BEHAVIOUR=quit
"$SL" testproj --max-sessions 3 >"$TMP/k1" 2>&1 </dev/null; rc=$?
assert_eq       "K1a: still exit 0 — a quit is not an error"  "$rc" "0"
assert_contains "K1b: still classified as a quit" "$(cat "$TMP/k1")" "deliberate quit"
[ -f "$CLOSED" ] && ok "K1c: the marker was written" || bad "K1c: no .chain-closed marker"
assert_eq       "K1d: it names the session that ended the chain" \
  "$(jq -r '.seq' "$CLOSED" 2>/dev/null)" "8"
assert_contains "K1e: it carries a UTC timestamp" \
  "$(jq -r '.closed_at' "$CLOSED" 2>/dev/null)" "Z"
# The ledger verdict already computed at the notify branches, reused rather than
# recomputed: the refusal can then say whether the closing session left a block.
assert_eq       "K1f: it carries the ledger verdict (no block for this stub)" \
  "$(jq -r '.top_ledger_seq' "$CLOSED" 2>/dev/null)" ""
assert_eq       "K1g: and says who wrote it" \
  "$(jq -r '.written_by' "$CLOSED" 2>/dev/null)" "session-loop.sh"

echo "K2: a supervisor refuses to restart a chain that was deliberately ended"
# B2 itself. The refusal must land BEFORE anything is written, so the work item
# is byte-identical afterwards — otherwise a refused restart still burns a
# session number or leaves a lock, and the operator pays for asking.
reset; export STUB_BEHAVIOUR=normal STUB_MODE=handsoff
printf '{"seq":8,"closed_at":"2026-09-13T00:00:00Z","top_ledger_seq":"","written_by":"session-loop.sh"}\n' > "$CLOSED"
"$SL" testproj --max-sessions 3 --min-lifetime 0 --stall-limit 0 >"$TMP/k2" 2>&1 </dev/null; rc=$?
out="$(cat "$TMP/k2")"
assert_eq       "K2a: refused with a non-zero status"  "$rc" "3"
assert_contains "K2b: it names the marker file"        "$out" ".chain-closed"
assert_contains "K2c: it names the session that ended the chain" "$out" "session #8"
assert_contains "K2d: it names the explicit override"  "$out" "--reopen"
assert_eq       "K2e: the counter did not move"        "$(cat "$SEQF")" "8"
[ -f "$W/.session-loop" ] && bad "K2f: a refused start left a lock behind" \
  || ok "K2f: no lock left behind"
[ -f "$BUDGET" ] && bad "K2g: a refused start spent a budget slot" \
  || ok "K2g: no budget slot spent"
case "$out" in *"staging the first session"*) bad "K2h: it staged despite the refusal" ;;
                *) ok "K2h: nothing was staged" ;; esac

echo "K3: --reopen is the explicit human act that reopens a closed chain (H9)"
# H9 must stay POSSIBLE. Round 2 of work/session-loop-hardening was exactly this
# act — deliberately reopening a closed item — so a gate with no override would
# have made that round unrunnable.
reset; export STUB_BEHAVIOUR=normal STUB_MODE=handsoff
printf '{"seq":8,"closed_at":"2026-09-13T00:00:00Z","top_ledger_seq":"","written_by":"session-loop.sh"}\n' > "$CLOSED"
"$SL" testproj --reopen --max-sessions 1 --min-lifetime 0 --stall-limit 0 \
  >"$TMP/k3" 2>&1 </dev/null; rc=$?
out="$(cat "$TMP/k3")"
assert_eq       "K3a: the chain ran"                   "$rc" "0"
assert_contains "K3b: the reopen is logged, not silent" "$out" "reopening"
assert_contains "K3c: and it names the session that had closed it" "$out" "session #8"
[ -f "$CLOSED" ] && bad "K3d: --reopen did not clear the marker" \
  || ok "K3d: the marker was cleared"
assert_contains "K3e: the session actually ran"        "$out" "starting session #8"

echo "K4: a VENDOR LOGOUT leaves no marker — the ordering that matters most"
# The single most important line in P6's implementation. The logout
# discriminator halts at session-loop.sh:594-598, ABOVE the write site at :599+.
# Move the write above the discriminator and a logged-out chain is recorded as
# deliberately closed, which breaks its documented recovery — re-running
# session-loop.sh <p> — because the supervisor would then refuse to start.
# T22 owns the classification; this case owns the ordering.
#
# Mutation: hoist the .chain-closed write above the `if ... child_logged_out`
# block -> K4b and K4c go red together.
reset; export STUB_BEHAVIOUR=logout
"$SL" testproj --max-sessions 3 --min-lifetime 0 --stall-limit 0 >"$TMP/k4" 2>&1 </dev/null; rc=$?
assert_eq       "K4a: still a halt, not a quit"        "$rc" "1"
[ -f "$CLOSED" ] && bad "K4b: a logout was recorded as a deliberate close" \
  || ok "K4b: a logout left no marker"
# The recovery in T22e must still work, not merely be printed.
export STUB_BEHAVIOUR=normal STUB_MODE=handsoff
stage_next "$TMP/stub.sh"
"$SL" testproj --max-sessions 1 --min-lifetime 0 --stall-limit 0 >"$TMP/k4b" 2>&1 </dev/null; rc=$?
assert_eq       "K4c: the documented recovery still starts the chain" "$rc" "0"

echo "K5: the chain CAP leaves no marker (H5) — the item stays resumable"
# cap_stop is a different exit path (:430/:720) and the table requires the work
# item to remain resumable after it: the cap means "this budget is spent", never
# "this work is finished".
reset; export STUB_BEHAVIOUR=normal STUB_MODE=handsoff
"$SL" testproj --max-sessions 2 --min-lifetime 0 --stall-limit 0 >"$TMP/k5" 2>&1 </dev/null
assert_contains "K5a: the cap ended the chain"         "$(cat "$TMP/k5")" "chain cap"
[ -f "$CLOSED" ] && bad "K5b: the cap was recorded as a deliberate close" \
  || ok "K5b: the cap left no marker"
# ...and resumable means the next start is not refused.
"$SL" testproj --reset-cap >/dev/null 2>&1 </dev/null
stage_next "$TMP/stub.sh"
"$SL" testproj --max-sessions 1 --min-lifetime 0 --stall-limit 0 >"$TMP/k5b" 2>&1 </dev/null; rc=$?
assert_eq       "K5c: and the item restarts after a cap" "$rc" "0"

echo "K6: the interactive pause leaves no marker (H6)"
# A human stepping out of an interactive chain at the pause exits at :707/:710,
# never reaching the deliberate-quit branch. Ctrl-C and a closed stdin land on
# the same two lines; the closed-stdin leg is the one a test can drive.
reset; export STUB_BEHAVIOUR=normal STUB_MODE=interactive
"$SL" testproj --max-sessions 3 --min-lifetime 0 --stall-limit 0 \
  >"$TMP/k6" 2>&1 </dev/null; rc=$?
assert_eq       "K6a: exit 0 at the pause"             "$rc" "0"
[ -f "$CLOSED" ] && bad "K6b: leaving at the pause was recorded as a deliberate close" \
  || ok "K6b: the pause left no marker"
reset

# ---------------------------------------------------------------------------
# P4a (session-chain-observability, spec.md 4.1) — the supervisor says "blocked
# on the handshake" instead of "still running". Three legs, all read by the
# supervisor itself: the child is identified and alive, .next-command is empty,
# and the child is past STOP when asked about BY NAME. The child cannot report
# this: from the inside it believes its rollover completed.
#
# The fixture registers as runtime `claude` (the R2.18 probe-child registers as
# `stub`, which has no measurement path) so the pinned budget read has a real
# transcript to measure. Everything else is the R2.18 shape: the child writes
# its own .active-session naming its pid under this supervisor.
# ---------------------------------------------------------------------------
cat > "$TMP/p4a-child.sh" <<'EOF'
#!/usr/bin/env bash
# $1 = session_id, $2 = input tokens to report, $3 = seconds alive,
# $4 = touch|quiet (keep the transcript fresh, or let it go silent),
# $5 = stage|nostage (stage a successor — i.e. look like B4, not B1)
set -u
sid="$1"; tokens="$2"; live="$3"; mode="$4"; stage="$5"
art="$PC_TMP/transcript-$sid.jsonl"
printf '{"message":{"usage":{"input_tokens":%s,"cache_read_input_tokens":0,"cache_creation_input_tokens":0}},"isSidechain":false}\n' \
  "$tokens" > "$art"
printf '{"runtime":"claude","session_id":"%s","project":"testproj","pid":%s,"pid_start":"x","supervisor_pid":%s}\n' \
  "$sid" "$$" "$PPID" > "$PC_W/.active-session"
printf '{"runtime":"claude","session_id":"%s","artifact":"%s","project":"testproj","pid":%s}\n' \
  "$sid" "$art" "$$" > "$PC_MAIN/.context-budget/sessions/claude-$sid.json"
[ "$stage" = stage ] && printf 'true\n' > "$PC_W/.next-command"
while [ "$live" -gt 0 ]; do
  [ "$mode" = touch ] && touch "$art"
  sleep 1; live=$((live - 1))
done
exit 0
EOF
chmod +x "$TMP/p4a-child.sh"

p4a_run() {  # $1 = alarm interval, rest = p4a-child.sh args
  _al="$1"; shift
  reset; rm -f "$W/.active-session" "$NEXT"; : > "$NOTED"; : > "$W/.session-loop.log"
  # N1 above unsets TF_ALARM_LOG; the hook is what proves these cases PAGE
  # rather than merely log, so re-export it here instead of inheriting.
  export TF_ALARM_LOG="$NOTED"
  stage_next "$TMP/p4a-child.sh $*"
  SESSION_LOOP_ALARM="$_al" SESSION_LOOP_NOTIFY="$TMP/alarm-notify.sh" \
    "$SL" testproj --max-sessions 1 --min-lifetime 0 --stall-limit 0 \
    >/dev/null 2>&1 </dev/null || true
  rm -f "$W/.active-session" "$NEXT"
}
p4a_absent() { case "$2" in *"$3"*) bad "$1 (unwanted [$3] in [$2])" ;; *) ok "$1" ;; esac; }

echo "P4a-a: a child past STOP with nothing staged is named as blocked, not as slow"
p4a_run 2 p4a-stop 155000 9 quiet nostage
p4a_absent "P4a-a1: fixture conclusive — the probe identified the child" \
  "$(cat "$NOTED")" "has been running with no exit"
assert_contains "P4a-a2: the page names the blocked handshake" \
  "$(cat "$NOTED")" "past its context budget with no successor staged"
assert_contains "P4a-a3: and the file that is empty" "$(cat "$NOTED")" "$NEXT"
p4a_absent "P4a-a4: it replaces the silence report, which says nothing about why" \
  "$(cat "$NOTED")" "has written nothing for"

echo "P4a-b: the same child, still WRITING, is paged too — writing is not progress here"
# The R2.18 log-only branch exists to stop false pages. This is not one: the
# three legs are all true, and a session busily writing its handoff while its
# successor was never staged is exactly B1. Timing is untouched — the writing
# branch still ticks at ALARM, this only changes what it says.
p4a_run 4 p4a-write 155000 11 touch nostage
p4a_absent "P4a-b1: fixture conclusive — the probe identified the child" \
  "$(cat "$NOTED")" "has been running with no exit"
assert_contains "P4a-b2: the writing branch pages when the handshake is blocked" \
  "$(cat "$NOTED")" "past its context budget with no successor staged"
p4a_absent "P4a-b3: and does not merely log 'still running'" \
  "$(cat "$W/.session-loop.log")" "is still running (transcript written"

echo "P4a-c: a child INSIDE its budget keeps today's message (H1 stays silent)"
# The budget leg is the load-bearing one: without it the predicate is true of
# every healthy session for its whole life, because .next-command is consumed
# BEFORE the run.
p4a_run 2 p4a-ok 1000 9 quiet nostage
assert_contains "P4a-c1: today's silence report, unchanged" \
  "$(cat "$NOTED")" "has written nothing for"
p4a_absent "P4a-c2: no blocked-handshake page for a healthy session" \
  "$(cat "$NOTED")" "past its context budget with no successor staged"

echo "P4a-d: a child past STOP that HAS staged is not P4a's case (that is B4/P4b)"
p4a_run 2 p4a-staged 155000 9 quiet stage
assert_contains "P4a-d1: today's silence report, unchanged" \
  "$(cat "$NOTED")" "has written nothing for"
p4a_absent "P4a-d2: a staged successor is not a blocked handshake" \
  "$(cat "$NOTED")" "past its context budget with no successor staged"

# ---------------------------------------------------------------------------
# P4b (session-chain-observability, spec.md 4.2) — the mirror leg. Predicate:
# the child is identified and alive AND .next-command is non-empty, observed on
# TWO CONSECUTIVE intervals. Staging is the last thing a session does and the
# turn-end hook terminates it, so a child that has staged and is still alive an
# interval later means the self-kill never fired — D17's shape, or a plain hook
# misconfiguration. From the inside that session believes it is done, so the
# supervisor is the only party that can see it.
#
# The second interval is the false-page guard, NOT an optimisation: every
# healthy H2 rollover has a real window between --emit writing .next-command
# and SIGTERM landing, and one interval of grace makes a fire mean "this has
# persisted" rather than "I caught the handshake mid-flight".
#
# Fixture is p4a-child.sh with `stage` — the same child case P4a-d uses.
# ---------------------------------------------------------------------------
echo "P4b-a: a child that staged and is STILL alive two intervals later is paged"
# Tokens are deliberately INSIDE the budget: P4b must not borrow P4a's
# past-STOP leg. Ticks land at ~3s and ~9s, NOT ~3s and ~6s: the silent branch
# doubles its interval after each page, so "two consecutive intervals" is two
# consecutive TICKS and the second one arrives late. The child must outlive it.
p4a_run 3 p4b-stuck 1000 12 quiet stage
p4a_absent "P4b-a1: fixture conclusive — the probe identified the child" \
  "$(cat "$NOTED")" "has been running with no exit"
assert_contains "P4b-a2: the page names the self-kill that did not fire" \
  "$(cat "$NOTED")" "staged a successor and is still running"
assert_contains "P4b-a3: and points at the bump record to check" \
  "$(cat "$NOTED")" ".session-seq.bump.json"
p4a_absent "P4b-a4: a staged successor is never a blocked handshake (P4a's leg)" \
  "$(cat "$NOTED")" "past its context budget with no successor staged"

echo "P4b-b: ONE interval is the healthy H2 window and must stay silent"
# Exactly one tick lands (~6s) before the child exits (~8s). This is the guard:
# the same predicate, one interval short, says nothing.
p4a_run 6 p4b-brief 1000 8 quiet stage
assert_contains "P4b-b1: today's silence report, unchanged" \
  "$(cat "$NOTED")" "has written nothing for"
p4a_absent "P4b-b2: no page after a single interval" \
  "$(cat "$NOTED")" "staged a successor and is still running"

echo "P4b-c: the same child, still WRITING, is paged too"
# The R2.18 log-only branch exists to stop false pages. A child writing away
# after it staged is not a false page — it is the same stuck handshake seen
# from the other branch. Ticks at ~4s and ~8s; the child exits at ~11s.
p4a_run 4 p4b-write 1000 11 touch stage
assert_contains "P4b-c1: the writing branch pages once the staging persists" \
  "$(cat "$NOTED")" "staged a successor and is still running"
# The other half of the same rule, and the reason this is not P4a-b3's
# assertion: P4a fires on its first tick, so "still running" never appears.
# P4b's first tick MUST still be the healthy log line — that is the guard.
assert_contains "P4b-c2: the first interval was still the plain log line — the guard held" \
  "$(cat "$W/.session-loop.log")" "is still running (transcript written"

echo "P4b-d: a child with NOTHING staged never draws a P4b page (H1 stays silent)"
p4a_run 2 p4b-none 1000 9 quiet nostage
p4a_absent "P4b-d1: no self-kill page for a session that has not staged" \
  "$(cat "$NOTED")" "staged a successor and is still running"
reset

# ---------------------------------------------------------------------------
# G1-a (session-chain-observability, spec.md 6.1, approved as 8 Q1) — a work
# item's own off switch stops a supervisor. B3: this item committed
# ROLLOVER_RELAUNCH=off and a chain started against it anyway, because the knob
# was only ever read at the rollover's closing step. Q1 widened its meaning from
# "do not spawn a successor behind my back" to "do not run me unattended at
# all", so the supervisor reads the same committed knob at start.
#
# Placed ABOVE the P6 gate rather than below it, for P6's own reason taken one
# step further: --reopen DELETES .chain-closed before it returns, so a G1-a
# refusal underneath it would refuse a start that had already destroyed
# evidence. A refused start leaves the work item byte-identical, and that has to
# include the marker. GA4 is the test of exactly that ordering.
# ---------------------------------------------------------------------------
ENVF="$W/context-budget.env"

echo "GA1: a committed ROLLOVER_RELAUNCH=off refuses the chain before anything moves"
reset; export STUB_BEHAVIOUR=normal STUB_MODE=handsoff
printf 'ROLLOVER_RELAUNCH=off\n' > "$ENVF"
"$SL" testproj --max-sessions 3 --min-lifetime 0 --stall-limit 0 \
  >"$TMP/ga1" 2>&1 </dev/null; rc=$?
out="$(cat "$TMP/ga1")"
assert_eq       "GA1a: refused with a non-zero status"  "$rc" "3"
assert_contains "GA1b: it names the knob"               "$out" "ROLLOVER_RELAUNCH=off"
assert_contains "GA1c: and the committed file it came from"   "$out" "work/testproj/context-budget.env"
assert_contains "GA1d: and the explicit override"       "$out" "--relaunch-override"
assert_eq       "GA1e: the counter did not move"        "$(cat "$SEQF")" "8"
[ -f "$W/.session-loop" ] && bad "GA1f: a refused start left a lock behind" \
  || ok "GA1f: no lock left behind"
[ -f "$BUDGET" ] && bad "GA1g: a refused start spent a budget slot" \
  || ok "GA1g: no budget slot spent"
case "$out" in *"staging the first session"*) bad "GA1h: it staged despite the refusal" ;;
                *) ok "GA1h: nothing was staged" ;; esac

echo "GA2: --relaunch-override is the explicit human act that starts it anyway"
reset; export STUB_BEHAVIOUR=normal STUB_MODE=handsoff
printf 'ROLLOVER_RELAUNCH=off\n' > "$ENVF"
"$SL" testproj --relaunch-override --max-sessions 1 --min-lifetime 0 --stall-limit 0 \
  >"$TMP/ga2" 2>&1 </dev/null; rc=$?
out="$(cat "$TMP/ga2")"
assert_eq       "GA2a: the chain ran"                   "$rc" "0"
assert_contains "GA2b: the override is logged, not silent" "$out" "ROLLOVER_RELAUNCH=off"
assert_contains "GA2c: the session actually ran"        "$out" "starting session #8"

echo "GA3: any other value leaves today's behaviour exactly as it is"
# The root context-budget.env in this fixture commits `manual`; an item that
# says `auto`, or says nothing, must not be refused. Only the literal `off`.
reset; export STUB_BEHAVIOUR=normal STUB_MODE=handsoff
printf 'ROLLOVER_RELAUNCH=auto\n' > "$ENVF"
"$SL" testproj --max-sessions 1 --min-lifetime 0 --stall-limit 0 \
  >"$TMP/ga3" 2>&1 </dev/null; rc=$?
assert_eq       "GA3a: the chain ran"                   "$rc" "0"
assert_contains "GA3b: no refusal"                      "$(cat "$TMP/ga3")" "starting session #8"
rm -f "$ENVF"
reset; export STUB_BEHAVIOUR=normal STUB_MODE=handsoff
"$SL" testproj --max-sessions 1 --min-lifetime 0 --stall-limit 0 \
  >"$TMP/ga3b" 2>&1 </dev/null; rc=$?
assert_eq       "GA3c: no per-item file at all — still runs" "$rc" "0"

echo "GA4: a refused start must not have already cleared .chain-closed"
# The ordering invariant. Both gates are armed and --reopen is passed: G1-a
# refuses first, so P6's marker — the evidence — is still on disk afterwards.
reset; export STUB_BEHAVIOUR=normal STUB_MODE=handsoff
printf 'ROLLOVER_RELAUNCH=off\n' > "$ENVF"
printf '{"seq":8,"closed_at":"2026-09-13T00:00:00Z","top_ledger_seq":"","written_by":"session-loop.sh"}\n' > "$CLOSED"
"$SL" testproj --reopen --max-sessions 1 --min-lifetime 0 --stall-limit 0 \
  >"$TMP/ga4" 2>&1 </dev/null; rc=$?
assert_eq       "GA4a: refused"                         "$rc" "3"
assert_contains "GA4b: and the refusal is the knob's, not the marker's" \
  "$(cat "$TMP/ga4")" "ROLLOVER_RELAUNCH=off"
[ -f "$CLOSED" ] && ok "GA4c: the .chain-closed evidence survived the refusal" \
  || bad "GA4c: a refused start destroyed the .chain-closed marker"
rm -f "$ENVF"
reset

echo "passed=$PASS failed=$FAIL"
[ "$FAIL" -eq 0 ]
