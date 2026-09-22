#!/usr/bin/env bash
# File: scripts/tests/test-session-loop.sh
# Purpose: session-loop.sh against stub children on a throwaway git workspace —
#          no model, no vendor. The stubs stand in for a session: they register
#          against the record (the `session` block), then either stage through
#          the REAL launcher, quit, fail, log out, or corrupt the record. Every
#          case pins the exit code, the reason/verdict code and record fields —
#          never log prose (evaluation/stage3-design-v2.md, "Tests").
set -u
SRC_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
MAIN="$TMP/main"
mkdir -p "$MAIN/scripts/lib" "$MAIN/work/testproj" "$MAIN/.context-budget/sessions"
cp "$SRC_ROOT/scripts/session-loop.sh" "$SRC_ROOT/scripts/launch-next-session.sh" \
   "$SRC_ROOT/scripts/context-budget.sh" "$MAIN/scripts/"
cp "$SRC_ROOT/scripts/lib/session-lib.sh" "$MAIN/scripts/lib/"
chmod +x "$MAIN/scripts/"*.sh
printf 'ROLLOVER_RELAUNCH=manual\nROLLOVER_RUNTIME=claude\n' > "$MAIN/context-budget.env"
echo "# launcher" > "$MAIN/work/testproj/next-session.md"
echo "# testproj" > "$MAIN/work/testproj/README.md"
# The live-session ignores the real workspace carries: a stub doing `git add -A`
# must not commit the record or the supervisor's files, or every session would
# read as progress to the stall guard.
printf '%s\n' 'work/*/session-state.json*' 'work/*/.session-loop*' 'work/*/.next-command*' \
  'work/*/.session-seq*' 'work/*/.interactive' 'work/*/.hands-off' '.context-budget/' > "$MAIN/.gitignore"
git -C "$MAIN" init -q
git -C "$MAIN" config user.email t@t; git -C "$MAIN" config user.name t
git -C "$MAIN" add -A; git -C "$MAIN" commit -qm init
SL="$MAIN/scripts/session-loop.sh"; LN="$MAIN/scripts/launch-next-session.sh"
W="$MAIN/work/testproj"; REC="$W/session-state.json"; LOOPF="$W/.session-loop"
NOTED="$TMP/notify.log"
cat > "$TMP/notify.sh" <<EOF
#!/usr/bin/env bash
printf '%s\n' "\$1" >> "$NOTED"
EOF
chmod +x "$TMP/notify.sh"
export SESSION_LOOP_NOTIFY="$TMP/notify.sh"
# Every launcher-emitted command starts `claude …`: a shim on PATH routes it to
# the stub, so what runs is the command the launcher wrote, not one this suite wrote.
mkdir -p "$TMP/bin"; printf '#!/usr/bin/env bash\nexec "%s"\n' "$TMP/stub.sh" > "$TMP/bin/claude"; chmod +x "$TMP/bin/claude"
export PATH="$TMP/bin:$PATH"

PASS=0; FAIL=0
ok()  { PASS=$((PASS+1)); echo "  ok: $1"; }
bad() { FAIL=$((FAIL+1)); echo "  FAIL: $1" >&2; }
assert_eq()       { [ "$2" = "$3" ] && ok "$1" || bad "$1 (want [$3] got [$2])"; }
assert_contains() { case "$2" in *"$3"*) ok "$1" ;; *) bad "$1 (no [$3] in [$2])" ;; esac; }
rec() { jq -r "$1" "$REC" 2>/dev/null; }
# The two pinned facts of a run: exit code and the code on the supervisor's line.
run() {   # args = session-loop.sh options; sets RC and OUT
  "$SL" testproj --min-lifetime 0 --stall-limit 0 "$@" >"$TMP/out" 2>&1 </dev/null; RC=$?
  OUT="$(cat "$TMP/out")"
}
refused() { printf '%s\n' "$OUT" | grep -o 'session-loop: refused reason=[a-z_]*\( leg=[a-z_]*\)\?' | head -1 | sed 's/session-loop: refused reason=//'; }
broken()  { printf '%s\n' "$OUT" | grep -o 'session-loop: broken reason=[a-z_]*\( leg=[a-z_]*\)\?' | head -1 | sed 's/session-loop: broken reason=//'; }
verdicts() { printf '%s\n' "$OUT" | grep -o 'session-loop: verdict=[a-z_]* seq=[0-9]*' | sed 's/session-loop: verdict=//' | tr '\n' ' ' | sed 's/ $//'; }

# A stub session. Reads its number from the env pair the supervisor exports,
# registers the way `register` would (the `session` block), then does what
# STUB_BEHAVIOUR says. The stage-* behaviours run the REAL launcher --emit, so
# the staged verdict is a contract test between launcher writes and supervisor
# reads, not between a stub and itself.
cat > "$TMP/stub.sh" <<'EOF'
#!/usr/bin/env bash
set -u
. "$STUB_MAIN/scripts/lib/session-lib.sh"
W="$STUB_MAIN/work/testproj"; REC="$W/session-state.json"; me="${TF_SESSION_SEQ:?}"
printf 'project=%s loop=%s loopproj=%s\n' "${TF_SESSION_PROJECT:-}" "${TF_SESSION_LOOP:-}" "${TF_SESSION_LOOP_PROJECT:-}" > "$STUB_DIR/env-$me"
cp "$REC" "$STUB_DIR/seen-$me.json"
now() { date -u +%FT%TZ; }
edit() { session_record_update "$REC" true "$@" || { echo "stub: record edit failed" >&2; exit 9; }; }
register() {  # $1 = registered_at (default now)
  edit '.session = {seq: ($me|tonumber), runtime: "claude", session_id: ("sid-" + $me), pid: ($pid|tonumber),
                    pid_start: $ps, artifact: $art, registered_at: $at, launcher_hash: "seeded", user: "t", ended: null}' \
    --arg me "$me" --arg pid "$$" --arg ps "$(ps -o lstart= -p $$ | sed 's/^ *//;s/ *$//')" \
    --arg art "$STUB_DIR/transcript-$me.jsonl" --arg at "${1:-$(now)}"
}
transcript() {  # $1 = terminal | transient | textonly
  t="$STUB_DIR/transcript-$me.jsonl"
  err='{"type":"assistant","isApiErrorMessage":true,"error":"authentication_failed","message":{"role":"assistant","model":"<synthetic>","content":[{"type":"text","text":"Not logged in · Please run /login"}]}}'
  printf '{"type":"user","message":{"role":"user","content":"go"}}\n' > "$t"
  case "$1" in
    terminal)  printf '%s\n{"type":"system","subtype":"turn_duration"}\n' "$err" >> "$t" ;;
    transient) printf '%s\n{"type":"assistant","message":{"role":"assistant","content":[{"type":"text","text":"back"}]}}\n' "$err" >> "$t" ;;
    textonly)  printf '{"type":"assistant","message":{"role":"assistant","content":[{"type":"text","text":"Not logged in · Please run /login"}]}}\n' >> "$t" ;;
  esac
}
bump() {  # $1 = delta, $2 = disposition, $3 = staged.by ("" = nothing staged)
  edit '.seq += ($d|tonumber)
        | .launch.predecessor = {seq: ($me|tonumber), session_id: ("sid-" + $me), registered_at: .session.registered_at, disposition: $disp}
        | .session = null
        | .staged = (if $by == "" then null else {successor: .seq, command: "true", by: $by} end)' \
    --arg d "$1" --arg me "$me" --arg disp "$2" --arg by "$3"
}
case "${STUB_BEHAVIOUR:-quit}" in
  stage|stage-commit|stage-bookkeeping)
    register
    printf '# launcher (session %s, %s)\n' "$me" "$RANDOM$RANDOM" > "$W/next-session.md"
    printf '# Session Handoff — session %s\n' "$me" > "$W/handoff.md"
    [ "$STUB_BEHAVIOUR" = stage-commit ] && printf 'work %s\n' "$me" >> "$STUB_MAIN/src.txt"
    [ "$STUB_BEHAVIOUR" != stage ] && { git -C "$STUB_MAIN" add -A; git -C "$STUB_MAIN" commit -qm "session $me"; }
    CLAUDE_CODE_SESSION_ID="sid-$me" "$STUB_MAIN/scripts/launch-next-session.sh" testproj --emit --skip-freshness \
      >"$STUB_DIR/launcher-$me.log" 2>&1 || { echo "stub: launcher rc=$? $(cat "$STUB_DIR/launcher-$me.log")" >&2; exit 9; }
    kill -TERM $$ ;;                  # what the turn-end hook does to a session that staged
  quit)      register; exit 0 ;;
  quit-stop) register; edit '.session.ended = {at: $at, door: "stop"}' --arg at "$(now)"; exit 0 ;;
  fail)      register; exit 7 ;;
  noreg)     exit 0 ;;
  old-reg)   register "2020-01-01T00:00:00Z"; exit 0 ;;
  logout)    transcript terminal;  register; exit 0 ;;
  logout-transient) transcript transient; register; exit 0 ;;
  logout-textonly)  transcript textonly;  register; exit 0 ;;
  seq2)      register; bump 2 rolled_over "sid-$me"; exit 0 ;;
  pred-bad)  register; bump 1 abandoned  "sid-$me"; exit 0 ;;
  by-bad)    register; bump 1 rolled_over "sid-other"; exit 0 ;;
  nostage)   register; bump 1 rolled_over ""; exit 0 ;;
  garbage)   register; echo 'not json' > "$REC"; exit 0 ;;
  schema2)   register; jq '.schema = 2' "$REC" > "$REC.new" && mv "$REC.new" "$REC"; exit 0 ;;
  sleep)     : > "$STUB_DIR/transcript-$me.jsonl"; register; sleep "${STUB_SLEEP:-3}"; exit 0 ;;
  sleep-touch) register; t="$STUB_DIR/transcript-$me.jsonl"
             printf '{"message":{"usage":{"input_tokens":%s,"cache_read_input_tokens":0,"cache_creation_input_tokens":0}},"isSidechain":false}\n' \
               "${STUB_TOKENS:-1000}" > "$t"
             n=$(( ${STUB_SLEEP:-3} * 2 )); while [ "$n" -gt 0 ]; do touch "$t"; sleep 0.5; n=$((n-1)); done; exit 0 ;;
esac
EOF
chmod +x "$TMP/stub.sh"
export STUB_MAIN="$MAIN" STUB_DIR="$TMP"

# The seeded record: a migrated item whose session #7 rolled over and staged
# #8 (the stub) before it ended. `chain` is absent: the supervisor opens it.
seed() {   # $1 = staged.by (default sid-7), $2 = launch.mode (default handsoff)
  jq -n --arg cmd "$TMP/stub.sh" --arg by "${1:-sid-7}" --arg mode "${2:-handsoff}" \
    '{schema: 1, seq: 8,
      launch: {launched_at: "2026-09-18T00:00:00Z", by: "session", mode: $mode,
               predecessor: {seq: 7, session_id: "sid-7", registered_at: "2026-09-17T00:00:00Z", disposition: "rolled_over"},
               pending: null},
      session: null,
      staged: {successor: 8, command: $cmd, by: $by}}' > "$REC"
}
reset() {
  rm -f "$LOOPF" "$W/.next-command" "$W/.session-loop.log" "$W/context-budget.env" "$W/handoff.md" "$W/.interactive" \
        "$TMP"/env-* "$TMP"/seen-* "$TMP"/launcher-* "$TMP"/transcript-*
  echo "# launcher" > "$W/next-session.md"
  git -C "$MAIN" checkout -q -- . 2>/dev/null; git -C "$MAIN" clean -qfd 2>/dev/null
  seed; : > "$NOTED"
  export STUB_BEHAVIOUR=quit; unset STUB_SLEEP STUB_TOKENS
}

# ---------------------------------------------------------------------------
echo "V1: staged — a child that rolls over through the launcher; the chain runs to its cap"
reset; export STUB_BEHAVIOUR=stage
run --max-sessions 2
assert_eq "V1a: exit 0 (cap is a clean end)"              "$RC" "0"
assert_eq "V1b: verdicts staged, staged, cap"             "$(verdicts)" "staged seq=8 staged seq=9 cap seq=10"
assert_eq "V1c: seq advanced 8 -> 10"                     "$(rec .seq)" "10"
assert_eq "V1d: session #10 stays staged for a restart"   "$(rec '.staged.successor')" "10"
assert_eq "V1e: staged.by is the child that staged it"    "$(rec '.staged.by')" "sid-9"
assert_eq "V1f: chain.used counts both sessions"          "$(rec '.chain.used')" "2"
assert_eq "V1g: chain.cap recorded"                       "$(rec '.chain.cap')" "2"
assert_eq "V1h: chain.supervisor cleared at exit"         "$(rec '.chain.supervisor')" "null"
assert_eq "V1i: no close on a cap"                        "$(rec '.chain.closed')" "null"
assert_eq "V1j: the child saw its number and item"        "$(cat "$TMP/env-8")" "project=testproj loop=1 loopproj=testproj"
assert_eq "V1k: staged was consumed before the child ran" "$(jq -r .staged "$TMP/seen-8.json")" "null"
assert_eq "V1l: chain.used was written before the child"  "$(jq -r .chain.used "$TMP/seen-8.json")" "1"
assert_eq "V1m: chain.supervisor named this supervisor"   "$(jq -r '.chain.supervisor | has("pid") and has("pid_start") and has("started_at")' "$TMP/seen-8.json")" "true"
[ ! -f "$LOOPF" ] && [ ! -f "$W/.next-command" ] && [ ! -f "$W/.session-seq.bump.json" ] \
  && ok "V1n: no marker, command file or bump record written (the record is the only state)" || bad "V1n: a retired mirror file was written"

echo "V2: quit_plain — a child that registered and exited 0 with nothing staged"
reset; export STUB_BEHAVIOUR=quit
run --max-sessions 3
assert_eq "V2a: exit 0"                          "$RC" "0"
assert_eq "V2b: verdict quit_plain"              "$(verdicts)" "quit_plain seq=8"
assert_eq "V2c: seq unchanged"                   "$(rec .seq)" "8"
assert_eq "V2d: chain.closed names the session"  "$(rec '.chain.closed.by_seq')" "8"
assert_eq "V2e: chain.closed.reason"             "$(rec '.chain.closed.reason')" "quit_plain"
assert_eq "V2f: chain.used charged"              "$(rec '.chain.used')" "1"
assert_contains "V2g: the notify hook was paged" "$(cat "$NOTED")" "quit_plain"

echo "V3: quit_stop — the child closed through the stop door"
reset; export STUB_BEHAVIOUR=quit-stop
run --max-sessions 3
assert_eq "V3a: exit 0"                 "$RC" "0"
assert_eq "V3b: verdict quit_stop"      "$(verdicts)" "quit_stop seq=8"
assert_eq "V3c: chain.closed.reason"    "$(rec '.chain.closed.reason')" "quit_stop"

echo "V4: cap — a start on a spent chain ends without staging or starting anything"
reset; jq '.chain = {supervisor: null, used: 3, cap: 3, closed: null}' "$REC" > "$REC.new" && mv "$REC.new" "$REC"
cp "$REC" "$TMP/before"
run --max-sessions 3
assert_eq "V4a: exit 0"              "$RC" "0"
assert_eq "V4b: verdict cap"         "$(verdicts)" "cap seq=8"
cmp -s "$REC" "$TMP/before" && ok "V4c: the record is byte-identical" || bad "V4c: a refused start wrote the record"
[ -f "$TMP/env-8" ] && bad "V4d: the staged session ran" || ok "V4d: nothing ran"

# ---------------------------------------------------------------------------
echo "B1: rc_nonzero — a child that registered and failed"
reset; export STUB_BEHAVIOUR=fail
run --max-sessions 3
assert_eq "B1a: exit 1"            "$RC" "1"
assert_eq "B1b: reason rc_nonzero" "$(broken)" "rc_nonzero"
assert_eq "B1c: no close"          "$(rec '.chain.closed')" "null"
assert_contains "B1d: the notify hook carries the code" "$(cat "$NOTED")" "rc_nonzero"

echo "B2: logout — a transcript ending in a terminal authentication_failed is not a quit"
reset; export STUB_BEHAVIOUR=logout
run --max-sessions 3
assert_eq "B2a: exit 1"                 "$RC" "1"
assert_eq "B2b: reason logout"          "$(broken)" "logout"
assert_eq "B2c: the slot was refunded"  "$(rec '.chain.used')" "0"
assert_eq "B2d: no close"               "$(rec '.chain.closed')" "null"
reset; export STUB_BEHAVIOUR=logout-transient
run --max-sessions 3
assert_eq "B2e: an auth error the session recovered from is a quit" "$(verdicts)" "quit_plain seq=8"
reset; export STUB_BEHAVIOUR=logout-textonly
run --max-sessions 3
assert_eq "B2f: a session that merely quoted the marker is a quit"  "$(verdicts)" "quit_plain seq=8"

echo "B3: no_own_measurement — a child that never registered, or registered before it started"
reset; export STUB_BEHAVIOUR=noreg
run --max-sessions 3
assert_eq "B3a: exit 1"                       "$RC" "1"
assert_eq "B3b: reason no_own_measurement"    "$(broken)" "no_own_measurement"
reset; export STUB_BEHAVIOUR=old-reg
run --max-sessions 3
assert_eq "B3c: a stale registration is no measurement of its own" "$(broken)" "no_own_measurement"

echo "B4: staged_invalid — every leg of a staging the supervisor cannot trust"
reset; export STUB_BEHAVIOUR=seq2;     run --max-sessions 3
assert_eq "B4a: exit 1"                "$RC" "1"
assert_eq "B4b: leg=seq (delta 2)"     "$(broken)" "staged_invalid leg=seq"
reset; export STUB_BEHAVIOUR=pred-bad; run --max-sessions 3
assert_eq "B4c: leg=predecessor"       "$(broken)" "staged_invalid leg=predecessor"
reset; export STUB_BEHAVIOUR=by-bad;   run --max-sessions 3
assert_eq "B4d: leg=by"                "$(broken)" "staged_invalid leg=by"
reset; export STUB_BEHAVIOUR=nostage;  run --max-sessions 3
assert_eq "B4e: leg=staged (number moved, nothing staged)" "$(broken)" "staged_invalid leg=staged"
reset; export STUB_BEHAVIOUR=stage
"$SL" testproj --max-sessions 3 --min-lifetime 60 --stall-limit 0 >"$TMP/out" 2>&1 </dev/null; RC=$?; OUT="$(cat "$TMP/out")"
assert_eq "B4f: exit 1 under min-lifetime"  "$RC" "1"
assert_eq "B4g: leg=lifetime"               "$(broken)" "staged_invalid leg=lifetime"

echo "B5/B6: record_unreadable and schema_mismatch after the child"
reset; export STUB_BEHAVIOUR=garbage; run --max-sessions 3
assert_eq "B5a: exit 1"                  "$RC" "1"
assert_eq "B5b: reason record_unreadable" "$(broken)" "record_unreadable"
reset; export STUB_BEHAVIOUR=schema2; run --max-sessions 3
assert_eq "B6a: exit 1"                  "$RC" "1"
assert_eq "B6b: reason schema_mismatch"  "$(broken)" "schema_mismatch"

echo "B7: stall — commits that touch only README, launcher and ledger are not progress"
reset; export STUB_BEHAVIOUR=stage-bookkeeping
"$SL" testproj --max-sessions 5 --min-lifetime 0 --stall-limit 2 >"$TMP/out" 2>&1 </dev/null; RC=$?; OUT="$(cat "$TMP/out")"
assert_eq "B7a: exit 1"            "$RC" "1"
assert_eq "B7b: reason stall"      "$(broken)" "stall"
assert_eq "B7c: two sessions ran"  "$(verdicts)" "staged seq=8 staged seq=9"
reset; export STUB_BEHAVIOUR=stage-commit
"$SL" testproj --max-sessions 3 --min-lifetime 0 --stall-limit 2 >"$TMP/out" 2>&1 </dev/null; RC=$?; OUT="$(cat "$TMP/out")"
assert_eq "B7d: a commit outside the three files is progress — chain runs to cap" "$(verdicts)" "staged seq=8 staged seq=9 staged seq=10 cap seq=11"
reset; touch "$W/.interactive"; export STUB_BEHAVIOUR=stage-bookkeeping   # the child stages with mode=interactive
"$SL" testproj --max-sessions 5 --min-lifetime 0 --stall-limit 1 >"$TMP/out" 2>&1 </dev/null; RC=$?; OUT="$(cat "$TMP/out")"
assert_eq "B7e: no stall verdict in interactive mode" "$(broken)" ""
assert_eq "B7f: the pause with no tty ends the chain, exit 0" "$RC" "0"
assert_eq "B7g: leaving at the pause is not a close"  "$(rec '.chain.closed')" "null"

# ---------------------------------------------------------------------------
echo "R1/R2: a start refuses an unreadable or foreign-schema record"
reset; echo 'not json' > "$REC"; run --max-sessions 3
assert_eq "R1a: exit 4"                    "$RC" "4"
assert_eq "R1b: reason record_unreadable"  "$(refused)" "record_unreadable"
reset; jq '.schema = 2' "$REC" > "$REC.new" && mv "$REC.new" "$REC"; cp "$REC" "$TMP/before"; run --max-sessions 3
assert_eq "R2a: exit 4"                    "$RC" "4"
assert_eq "R2b: reason schema_mismatch"    "$(refused)" "schema_mismatch"
cmp -s "$REC" "$TMP/before" && ok "R2c: record untouched" || bad "R2c: a refused start wrote the record"

echo "R3: chain_closed — a deliberately ended chain stays ended unless reopened"
reset; export STUB_BEHAVIOUR=quit; run --max-sessions 3
assert_eq "R3a: the quit closed the chain"   "$(rec '.chain.closed.reason')" "quit_plain"
run --max-sessions 3
assert_eq "R3b: exit 4"                       "$RC" "4"
assert_eq "R3c: reason chain_closed"          "$(refused)" "chain_closed"
run --max-sessions 3 --reopen
assert_eq "R3d: --reopen starts the chain"    "$RC" "0"
assert_eq "R3e: the dead owner #8 is bootstrapped past; #9 ran and quit" "$(verdicts)" "quit_plain seq=9"

echo "R4: supervisor_live — one supervisor per work item; a stale block is overwritten"
reset; jq --argjson pid "$$" --arg ps "$(ps -o lstart= -p $$ | sed 's/^ *//;s/ *$//')" \
  '.chain = {supervisor: {pid: $pid, pid_start: $ps, started_at: "2026-09-18T00:00:00Z"}, used: 0, cap: 10, closed: null}' \
  "$REC" > "$REC.new" && mv "$REC.new" "$REC"
run --max-sessions 3
assert_eq "R4a: exit 4"                   "$RC" "4"
assert_eq "R4b: reason supervisor_live"   "$(refused)" "supervisor_live"
reset; jq '.chain = {supervisor: {pid: 4194304, pid_start: "never", started_at: "2026-09-18T00:00:00Z"}, used: 0, cap: 10, closed: null}' \
  "$REC" > "$REC.new" && mv "$REC.new" "$REC"
run --max-sessions 3
assert_eq "R4c: a dead supervisor's block does not refuse" "$(verdicts)" "quit_plain seq=8"

echo "R5: relaunch_off — the item's committed ROLLOVER_RELAUNCH=off refuses an unattended chain"
reset; echo 'ROLLOVER_RELAUNCH=off' > "$W/context-budget.env"; cp "$REC" "$TMP/before"
run --max-sessions 3
assert_eq "R5a: exit 4"                 "$RC" "4"
assert_eq "R5b: reason relaunch_off"    "$(refused)" "relaunch_off"
cmp -s "$REC" "$TMP/before" && ok "R5c: record untouched" || bad "R5c: a refused start wrote the record"
run --max-sessions 3 --relaunch-override
assert_eq "R5d: --relaunch-override starts it" "$(verdicts)" "quit_plain seq=8"

echo "R6: an already-spent stage — the staged number has a registered owner — is refused"
reset; jq '.session = {seq: 8, runtime: "claude", session_id: "sid-8", artifact: "/nonexistent", registered_at: "2026-09-18T00:00:00Z", launcher_hash: "x", user: "t", ended: {at: "2026-09-18T01:00:00Z"}}' \
  "$REC" > "$REC.new" && mv "$REC.new" "$REC"
run --max-sessions 3
assert_eq "R6a: exit 4"                            "$RC" "4"
assert_eq "R6b: reason staged_invalid leg=spent"   "$(refused)" "staged_invalid leg=spent"
[ -f "$TMP/env-8" ] && bad "R6c: the spent command was run again" || ok "R6c: nothing ran"
assert_eq "R6d: staged left in place as evidence"  "$(rec '.staged.successor')" "8"

echo "R7: a hand stage from a supervised session with no live supervisor is refused (no_supervisor)"
reset
jq '.session = {seq: 8, runtime: "claude", session_id: "sid-8", registered_at: "2026-09-18T00:00:00Z", launcher_hash: "x", user: "t", ended: null} | .staged = null' \
  "$REC" > "$REC.new" && mv "$REC.new" "$REC"
printf '# Session Handoff — session 8\n' > "$W/handoff.md"
out="$(TF_SESSION_LOOP=1 CLAUDE_CODE_SESSION_ID=sid-8 "$LN" testproj --emit --skip-freshness 2>&1 </dev/null)"; rc=$?
assert_eq "R7a: exit 4"                "$rc" "4"
assert_contains "R7b: reason no_supervisor" "$out" "refused reason=no_supervisor"
assert_eq "R7c: nothing staged"        "$(rec '.staged')" "null"

echo "R8: a refused bootstrap stage relays the launcher's code"
reset; jq --argjson pid "$$" --arg ps "$(ps -o lstart= -p $$ | sed 's/^ *//;s/ *$//')" \
  '.session = {seq: 8, runtime: "claude", session_id: "sid-8", pid: $pid, pid_start: $ps, registered_at: "2026-09-18T00:00:00Z", launcher_hash: "x", user: "t", ended: null} | .staged = null' \
  "$REC" > "$REC.new" && mv "$REC.new" "$REC"
run --max-sessions 3
assert_eq "R8a: exit 4"                 "$RC" "4"
assert_eq "R8b: reason owner_live"      "$(refused)" "owner_live"
assert_eq "R8c: chain.supervisor cleared" "$(rec '.chain.supervisor')" "null"

# ---------------------------------------------------------------------------
echo "C1/C2: --reset-cap opens a new budget; refused under a live supervisor"
reset; jq '.chain = {supervisor: null, used: 3, cap: 3, closed: null}' "$REC" > "$REC.new" && mv "$REC.new" "$REC"
run --reset-cap
assert_eq "C1a: exit 0"                  "$RC" "0"
assert_eq "C1b: used reset"              "$(rec '.chain.used')" "0"
[ -f "$TMP/env-8" ] && bad "C1c: --reset-cap started the chain" || ok "C1c: --reset-cap did not start the chain"
run --max-sessions 3
assert_eq "C1d: the next start runs"     "$(verdicts)" "quit_plain seq=8"
reset; jq --argjson pid "$$" --arg ps "$(ps -o lstart= -p $$ | sed 's/^ *//;s/ *$//')" \
  '.chain = {supervisor: {pid: $pid, pid_start: $ps, started_at: "x"}, used: 3, cap: 3, closed: null}' \
  "$REC" > "$REC.new" && mv "$REC.new" "$REC"
run --reset-cap
assert_eq "C2a: exit 4"                  "$RC" "4"
assert_eq "C2b: reason supervisor_live"  "$(refused)" "supervisor_live"
assert_eq "C2c: used untouched"          "$(rec '.chain.used')" "3"

# ---------------------------------------------------------------------------
echo "F1: a fresh work item — no record — the supervisor stages session 1 through the launcher"
# The child is reached through a `claude` shim on PATH: what is under test is
# the command the launcher emits at the bootstrap. The bootstrap call must be
# DIRECT (the launcher's exemption tests its strict parent pid): wrapping it in
# $(...) turns F1 red.
reset; rm -f "$REC" "$W/handoff.md"; export STUB_BEHAVIOUR=stage
env -u CLAUDE_CODE_SESSION_ID -u CODEX_THREAD_ID -u COPILOT_AGENT_SESSION_ID \
  -u VSCODE_TARGET_SESSION_LOG -u OPENCODE_SESSION_ID \
  "$SL" testproj --max-sessions 1 --min-lifetime 0 --stall-limit 0 >"$TMP/out" 2>&1 </dev/null; RC=$?; OUT="$(cat "$TMP/out")"
assert_eq "F1a: exit 0"                          "$RC" "0"
assert_eq "F1b: session 1 ran and rolled over"   "$(verdicts)" "staged seq=1 cap seq=2"
assert_eq "F1c: the bootstrap stage was the supervisor's" "$(jq -r '.launch.by' "$TMP/seen-1.json")" "supervisor"
assert_eq "F1d: seq opened at 1 and advanced"    "$(rec .seq)" "2"

echo "A1-A3: the watchdog reads the record — pages a silent child, kills it past SESSION_LOOP_KILL_AFTER, and never outlives it"
reset; export STUB_BEHAVIOUR=sleep STUB_SLEEP=3
SESSION_LOOP_ALARM=1 SESSION_LOOP_ALARM_MAX=1 \
  "$SL" testproj --max-sessions 1 --min-lifetime 0 --stall-limit 0 >"$TMP/out" 2>&1 </dev/null
pages() { grep -c 'page=' "$NOTED" | tr -d ' '; }
[ "$(pages)" -ge 1 ] && ok "A1a: the alarm paged" || bad "A1a: the alarm was silent"
[ "$(pages)" -ge 2 ] && ok "A1b: it repeats" || bad "A1b: it fired once"
at_return="$(pages)"; sleep 2
assert_eq "A1c: no page after the supervisor returned" "$(pages)" "$at_return"
reset; export STUB_BEHAVIOUR=sleep STUB_SLEEP=20
t0="$(date +%s)"
SESSION_LOOP_ALARM=1 SESSION_LOOP_KILL_AFTER=1 \
  "$SL" testproj --max-sessions 1 --min-lifetime 0 --stall-limit 0 >"$TMP/out" 2>&1 </dev/null; RC=$?; OUT="$(cat "$TMP/out")"
[ $(( $(date +%s) - t0 )) -lt 15 ] && ok "A2a: the silent child was ended" || bad "A2a: the child ran to its own end"
assert_eq "A2b: a killed child is rc_nonzero"      "$(broken)" "rc_nonzero"
reset; export STUB_BEHAVIOUR=sleep-touch STUB_SLEEP=3   # touches its transcript every 0.5s: age is always under 2
SESSION_LOOP_ALARM=2 SESSION_LOOP_KILL_AFTER=2 \
  "$SL" testproj --max-sessions 1 --min-lifetime 0 --stall-limit 0 >"$TMP/out" 2>&1 </dev/null; RC=$?; OUT="$(cat "$TMP/out")"
assert_eq "A3a: a child still writing its transcript is not killed" "$(verdicts)" "quit_plain seq=8"
[ "$(pages)" -eq 0 ] && ok "A3b: a writing child draws no page" || bad "A3b: a writing child was paged"
reset; export STUB_BEHAVIOUR=sleep STUB_SLEEP=1
t0="$(date +%s)"
out="$(SESSION_LOOP_ALARM=20 "$SL" testproj --max-sessions 1 --min-lifetime 0 --stall-limit 0 2>&1 </dev/null)"
[ $(( $(date +%s) - t0 )) -lt 10 ] && ok "A4: the alarm never holds the caller's pipe after the loop returns" \
  || bad "A4: the caller was held by a leaked alarm sleep"

echo
echo "passed=$PASS failed=$FAIL"
[ "$FAIL" -eq 0 ]
