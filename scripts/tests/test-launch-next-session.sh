#!/usr/bin/env bash
# File: scripts/tests/test-launch-next-session.sh
# Purpose: launch-next-session.sh on the session record (Stage 4 phase 4 of
#          work/template-improvement-review). Pins exit codes, record fields and
#          reason codes only. Self-contained: a throwaway git workspace, a fake
#          $HOME for the stub claude transcripts the end-to-end slice registers.
set -u
SRC_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TMP="$(mktemp -d)"; TMP="$(cd "$TMP" && pwd -P)"
MAIN="$TMP/main"
mkdir -p "$MAIN/scripts/lib" "$MAIN/work/testproj" "$MAIN/.context-budget/sessions" "$TMP/home"
cp "$SRC_ROOT/scripts/launch-next-session.sh" "$SRC_ROOT/scripts/context-budget.sh" "$MAIN/scripts/"
cp "$SRC_ROOT/scripts/lib/session-lib.sh" "$MAIN/scripts/lib/"
chmod +x "$MAIN/scripts/"*.sh
printf 'ROLLOVER_RELAUNCH=manual\nROLLOVER_RUNTIME=claude\n' > "$MAIN/context-budget.env"
echo "# launcher" > "$MAIN/work/testproj/next-session.md"
printf '%s\n' '.context-budget/' 'work/*/session-state.json*' 'work/*/.session-seq*' \
  'work/*/.next-command*' 'work/*/.session-loop' 'work/*/.chain-closed' > "$MAIN/.gitignore"
GITC() { git -c user.email=t@t -c user.name=t "$@"; }
GITC -C "$MAIN" init -q -b main
GITC -C "$MAIN" add -A; GITC -C "$MAIN" commit -qm init
cd "$MAIN"
LNS="$MAIN/scripts/launch-next-session.sh"
CB="$MAIN/scripts/context-budget.sh"
REC="$MAIN/work/testproj/session-state.json"
HF="$MAIN/work/testproj/handoff.md"
NEXTF="$MAIN/work/testproj/next-session.md"
EMITF="$MAIN/work/testproj/.next-command"
LOOPF="$MAIN/work/testproj/.session-loop"
export HOME="$TMP/home"
SLUG="$(pwd | tr '/.' '--')"
PROJ_DIR="$HOME/.claude/projects/$SLUG"; mkdir -p "$PROJ_DIR"
# Hermetic: the suite may itself run under a supervised session.
unset TF_SESSION_PROJECT TF_SESSION_SEQ TF_SESSION_LOOP TF_SESSION_LOOP_PROJECT
# A process that is live for the whole suite, and one that is certainly dead.
sleep 600 & LIVE_PID=$!
LIVE_START="$(ps -o lstart= -p "$LIVE_PID" | sed 's/^ *//;s/ *$//')"
trap 'kill "$LIVE_PID" 2>/dev/null; wait "$LIVE_PID" 2>/dev/null; rm -rf "$TMP"' EXIT
sleep 0 & DEAD_PID=$!; wait "$DEAD_PID" 2>/dev/null
MY_START="$(ps -o lstart= -p "$$" | sed 's/^ *//;s/ *$//')"

PASS=0; FAIL=0
ok()   { PASS=$((PASS+1)); echo "  ok: $1"; }
bad()  { FAIL=$((FAIL+1)); echo "  FAIL: $1" >&2; }
assert_eq() { [ "$2" = "$3" ] && ok "$1" || bad "$1 (want [$3] got [$2])"; }
assert_contains() { case "$2" in *"$3"*) ok "$1" ;; *) bad "$1 (no [$3] in [$2])" ;; esac; }
assert_not_contains() { case "$2" in *"$3"*) bad "$1 (unexpected [$3])" ;; *) ok "$1" ;; esac; }
assert_same() { cmp -s "$2" "$3" && ok "$1" || bad "$1 (record changed)"; }
reason_of() { printf '%s\n' "$1" | sed -n 's/.*launch-next-session: refused reason=\([a-z_]*\).*/\1/p' | head -1; }
assert_refused() {  # $1=label $2=rc $3=out $4=code
  assert_eq "$1: exit 4" "$2" "4"
  assert_eq "$1: reason=$4" "$(reason_of "$3")" "$4"
}

# All runtime-identity env vars cleared per call unless a test sets one.
run_lns() { env -u CLAUDE_CODE_SESSION_ID -u CODEX_THREAD_ID -u OPENCODE_SESSION_ID \
  -u COPILOT_AGENT_SESSION_ID -u VSCODE_TARGET_SESSION_LOG -u TF_SESSION_LOOP \
  -u ROLLOVER_RELAUNCH -u ROLLOVER_RUNTIME -u CONTEXT_LOCK_STALE_SECS "$@"; }
as_me() { run_lns CLAUDE_CODE_SESSION_ID=sid-me "$LNS" testproj "$@"; }
rec() { jq -r "$1" "$REC" 2>/dev/null; }
mk_transcript() {  # $1=session-id
  jq -cn '{message:{usage:{input_tokens:1000,cache_read_input_tokens:0,cache_creation_input_tokens:0}},isSidechain:false}' \
    > "$PROJ_DIR/$1.jsonl"
}
ledger() { printf '# Session Handoff — %s (2026-09-18): the block\n' "$1" > "$HF"; }
# The fixture's owner: seq 8, launcher_hash from a previous launcher text (so the
# current file reads as rewritten), fresh transcript (live by age). $2 = owner
# sid ("" = no owner), $3/$4 = pid/pid_start ("" = none), $5 = launcher_hash.
seed() {  # $1=seq $2=owner-sid $3=pid $4=pid_start $5=launcher_hash
  [ -n "$2" ] && mk_transcript "$2"
  jq -n --argjson seq "$1" --arg sid "$2" --arg pid "${3:-}" --arg ps "${4:-}" \
    --arg lh "${5:-old-launcher-hash}" --arg af "$PROJ_DIR/$2.jsonl" \
    '{schema:1, seq:$seq, launch:{launched_at:"2026-01-01T00:00:00Z", by:"session", mode:"handsoff", predecessor:null, pending:null},
      session:(if $sid == "" then null else
        ({seq:$seq, runtime:"claude", session_id:$sid, artifact:$af, registered_at:"2026-09-18T00:00:00Z",
          launcher_hash:$lh, user:"t", ended:null}
         + (if $pid == "" then {} else {pid:($pid|tonumber), pid_start:$ps} end)) end)}' > "$REC"
}
reset() { rm -f "$REC" "$HF" "$EMITF" "$EMITF.json" "$LOOPF" "$MAIN/work/testproj/.session-seq"* \
            "$MAIN/work/testproj/.chain-closed" "$PROJ_DIR"/*.jsonl
          echo "# launcher" > "$NEXTF"; seed 8 sid-me; ledger 8; }
PROMPT='Work item testproj - rollover session #9. Read `work/testproj/next-session.md` and continue from **First actions**.'

# ---------------------------------------------------------------------------
echo "E: the end-to-end slice — register, write the two files, --check, --emit, successor registers"
reset; rm -f "$REC"; ledger 7; mk_transcript sid-a
out=$(run_lns CLAUDE_CODE_SESSION_ID=sid-a "$CB" register --project testproj --runtime claude 2>&1); rc=$?
assert_eq "E1a: register opened seq 8 from the ledger" "$(rec .seq)" "8"
assert_eq "E1b: register filled session" "$(rec .session.session_id)" "sid-a"
reg_at="$(rec .session.registered_at)"
# The agent writes the two files: a new launcher and this session's ledger block.
echo "# launcher for session 9" > "$NEXTF"; ledger 8
cp "$REC" "$TMP/rec.before"
out=$(run_lns CLAUDE_CODE_SESSION_ID=sid-a "$LNS" testproj --check 2>&1); rc=$?
assert_eq       "E2a: --check exit 0"           "$rc" "0"
assert_contains "E2b: check ok names the successor" "$out" "check ok"
assert_contains "E2c: successor number"         "$out" "successor=9"
assert_same     "E2d: --check wrote nothing"    "$TMP/rec.before" "$REC"
out=$(run_lns CLAUDE_CODE_SESSION_ID=sid-a "$LNS" testproj --emit "$EMITF" 2>&1); rc=$?
assert_eq "E3a: --emit exit 0"                       "$rc" "0"
assert_eq "E3b: seq advanced to 9"                   "$(rec .seq)" "9"
assert_eq "E3c: predecessor disposition rolled_over" "$(rec .launch.predecessor.disposition)" "rolled_over"
assert_eq "E3d: predecessor seq"                     "$(rec .launch.predecessor.seq)" "8"
assert_eq "E3e: predecessor session_id"              "$(rec .launch.predecessor.session_id)" "sid-a"
assert_eq "E3f: predecessor registered_at copied"    "$(rec .launch.predecessor.registered_at)" "$reg_at"
assert_eq "E3g: launch.by=session"                   "$(rec .launch.by)" "session"
assert_eq "E3h: session is null"                     "$(rec .session)" "null"
assert_eq "E3i: staged.by is the caller's session id" "$(rec .staged.by)" "sid-a"
assert_eq "E3j: staged.successor"                    "$(rec .staged.successor)" "9"
assert_contains "E3k: staged.command carries the prompt" "$(rec .staged.command)" 'rollover\ session\ #9'
assert_contains "E3l: staged.command carries the env pair" "$(rec .staged.command)" "TF_SESSION_PROJECT=testproj TF_SESSION_SEQ=9 "
assert_eq "E3m: launch.pending is null"              "$(rec .launch.pending)" "null"
assert_eq "E3n: the emitted file holds the same command" "$(cat "$EMITF")" "$(rec .staged.command)"
# The stub successor registers with the two environment variables.
mk_transcript sid-b
out=$(run_lns TF_SESSION_PROJECT=testproj TF_SESSION_SEQ=9 CLAUDE_CODE_SESSION_ID=sid-b \
  "$CB" register --runtime claude 2>&1); rc=$?
assert_contains "E4a: successor bound via env"   "$out" "bound work/testproj seq=9 via=env"
assert_eq "E4b: session filled by the successor" "$(rec .session.session_id)" "sid-b"
assert_eq "E4c: session.seq == seq"              "$(rec .session.seq)" "9"
assert_eq "E4d: seq unchanged by registration"   "$(rec .seq)" "9"
assert_eq "E4e: predecessor block survives"      "$(rec .launch.predecessor.session_id)" "sid-a"

echo "E5: the phase-5 supervisor's files are mirrored after the record"
assert_eq "E5a: .session-seq mirrors seq" "$(cat "$MAIN/work/testproj/.session-seq")" "9"
assert_eq "E5b: bump record seq/successor" \
  "$(jq -r '"\(.seq)/\(.successor)/\(.session_id)/\(.written_by)"' "$MAIN/work/testproj/.session-seq.bump.json")" \
  "8/9/sid-a/launch-next-session.sh"
assert_eq "E5c: identity sidecar beside the command" \
  "$(jq -r '"\(.successor)/\(.session_id)/\(.written_by)"' "$EMITF.json")" "9/sid-a/launch-next-session.sh"
assert_eq "E5d: sidecar checksum matches the command" "$(jq -r .command_cksum "$EMITF.json")" "$(cksum < "$EMITF")"

# ---------------------------------------------------------------------------
echo "P: prompt, runtime resolution, dry-run"
reset
out=$(as_me --dry-run 2>&1); rc=$?
assert_eq       "P1a: dry-run exit 0"          "$rc" "0"
assert_contains "P1b: verbatim prompt"         "$out" "$PROMPT"
assert_contains "P1c: claude argv with --name" "$out" "cmd: TF_SESSION_PROJECT=testproj TF_SESSION_SEQ=9 claude --name testproj"
assert_eq       "P1d: dry-run wrote nothing"   "$(rec .seq)" "8"
[ ! -f "$MAIN/work/testproj/.session-seq" ] && ok "P1e: no counter mirror on dry-run" || bad "P1e: dry-run wrote the counter"
out=$(as_me --runtime codex --dry-run 2>&1)
assert_contains "P2a: --runtime flag wins"   "$out" "runtime=codex"
assert_contains "P2b: codex argv"            "$out" "TF_SESSION_SEQ=9 codex "
assert_not_contains "P2c: no --name off claude" "$out" "--name"
jq '.session.runtime = "opencode"' "$REC" > "$REC.t" && mv "$REC.t" "$REC"
out=$(run_lns OPENCODE_SESSION_ID=sid-me "$LNS" testproj --dry-run 2>&1)
assert_contains "P3a: runtime from the owner's block" "$out" "runtime=opencode"
assert_contains "P3b: opencode argv"                 "$out" "opencode --prompt"
reset
out=$(as_me --runtime gemini --dry-run 2>&1)
assert_contains "P4: gemini -i argv" "$out" "gemini -i"
out=$(as_me --runtime copilot --dry-run 2>&1)
assert_contains "P5: copilot -i argv" "$out" "copilot -i"

# ---------------------------------------------------------------------------
echo "S: schema_mismatch"
reset; jq '.schema = 2' "$REC" > "$REC.t" && mv "$REC.t" "$REC"; cp "$REC" "$TMP/rec.before"
out=$(as_me --emit "$EMITF" 2>&1); rc=$?
assert_refused "S1" "$rc" "$out" schema_mismatch
assert_same "S1c: record untouched" "$TMP/rec.before" "$REC"
printf 'not json\n' > "$REC"
out=$(as_me --emit "$EMITF" 2>&1); rc=$?
assert_refused "S2 (unreadable)" "$rc" "$out" schema_mismatch

echo "C: chain_closed"
reset; jq '.chain = {supervisor:null, used:3, cap:10, closed:{at:"2026-09-18T00:00:00Z", by_seq:8, reason:"quit"}}' "$REC" > "$REC.t" && mv "$REC.t" "$REC"
out=$(as_me --emit "$EMITF" 2>&1); rc=$?
assert_refused "C1 (record)" "$rc" "$out" chain_closed
reset; printf '{"seq":8,"closed_at":"2026-09-13T00:00:00Z","written_by":"session-loop.sh"}\n' > "$MAIN/work/testproj/.chain-closed"
out=$(as_me --dry-run 2>&1); rc=$?
assert_refused "C2 (legacy marker)" "$rc" "$out" chain_closed
assert_eq "C2c: nothing written" "$(rec .seq)" "8"

echo "R: runtime_path_unsupported"
reset
out=$(as_me --runtime bogus --dry-run 2>&1); rc=$?
assert_refused "R1 (unknown runtime)" "$rc" "$out" runtime_path_unsupported
out=$(as_me --runtime copilot-vscode --emit "$EMITF" 2>&1); rc=$?
assert_refused "R2 (--emit x copilot-vscode)" "$rc" "$out" runtime_path_unsupported
out=$(as_me --runtime codex --clear 2>&1); rc=$?
assert_refused "R3 (--clear off claude)" "$rc" "$out" runtime_path_unsupported
out=$(as_me --clear 2>&1); rc=$?   # the owner's block records no pid
assert_refused "R4 (--clear with no pid recorded)" "$rc" "$out" runtime_path_unsupported
assert_eq "R5: none of them wrote" "$(rec .seq)" "8"
out=$(as_me --runtime copilot-vscode --dry-run 2>&1); rc=$?
assert_eq       "R6a: copilot-vscode dry-run is legal" "$rc" "0"
assert_contains "R6b: code chat argv"                  "$out" "code chat -r -m agent"

echo "V: supervised_stage_only"
mk_marker() { printf '{"pid":%s,"project":"testproj","started_at":"2026-09-10T00:00:00Z"}\n' "$1" > "$LOOPF"; }
reset; mk_marker "$LIVE_PID"
out=$(as_me 2>&1 </dev/null); rc=$?
assert_refused "V1 (bare launch)" "$rc" "$out" supervised_stage_only
out=$(as_me --clear 2>&1); rc=$?
assert_refused "V2 (--clear)" "$rc" "$out" supervised_stage_only
out=$(as_me --dry-run 2>&1); rc=$?
assert_refused "V3 (--dry-run runs the same gate)" "$rc" "$out" supervised_stage_only
assert_eq "V4: nothing written" "$(rec .seq)" "8"
out=$(as_me --emit "$EMITF" 2>&1); rc=$?
assert_eq "V5a: --emit under a live supervisor stages" "$rc" "0"
assert_eq "V5b: staged"                                "$(rec .staged.successor)" "9"
reset; mk_marker "$DEAD_PID"
out=$(as_me 2>&1 </dev/null); rc=$?
assert_eq       "V6a: dead-pid marker + bare launch proceeds" "$rc" "0"
assert_contains "V6b: with a warning"                         "$out" "warning"

echo "N: no_supervisor"
reset
out=$(run_lns TF_SESSION_LOOP=1 CLAUDE_CODE_SESSION_ID=sid-me "$LNS" testproj --emit "$EMITF" 2>&1); rc=$?
assert_refused "N1 (supervised session, no supervisor)" "$rc" "$out" no_supervisor
assert_eq "N1c: nothing written" "$(rec .seq)" "8"
mk_marker "$LIVE_PID"
out=$(run_lns TF_SESSION_LOOP=1 CLAUDE_CODE_SESSION_ID=sid-me "$LNS" testproj --emit "$EMITF" 2>&1); rc=$?
assert_eq "N2: with a live supervisor it stages" "$rc" "0"
reset
out=$(as_me --emit "$EMITF" 2>&1); rc=$?
assert_eq "N3: an unsupervised session may stage by hand (the slice)" "$rc" "0"

echo "O: not_owner / owner_live"
reset
out=$(run_lns "$LNS" testproj --emit "$EMITF" 2>&1); rc=$?
assert_refused "O1 (no identity, owner live)" "$rc" "$out" owner_live
out=$(run_lns CLAUDE_CODE_SESSION_ID=sid-other "$LNS" testproj --emit "$EMITF" 2>&1); rc=$?
assert_refused "O2 (other, owner live by transcript age)" "$rc" "$out" owner_live
assert_contains "O2c: names the owner" "$out" "owner=claude-sid-me"
reset; seed 8 sid-me "$LIVE_PID" "$LIVE_START"
out=$(run_lns CLAUDE_CODE_SESSION_ID=sid-other "$LNS" testproj --emit "$EMITF" 2>&1); rc=$?
assert_refused "O3 (other, owner live by pid)" "$rc" "$out" owner_live
reset; seed 8 sid-me "$DEAD_PID" "Tue Aug  5 00:00:00 2026"
out=$(run_lns CLAUDE_CODE_SESSION_ID=sid-other "$LNS" testproj --emit "$EMITF" 2>&1); rc=$?
assert_refused "O4 (other, owner dead by pid)" "$rc" "$out" not_owner
reset; touch -t 202001010000 "$PROJ_DIR/sid-me.jsonl"
out=$(run_lns CLAUDE_CODE_SESSION_ID=sid-other "$LNS" testproj --emit "$EMITF" 2>&1); rc=$?
assert_refused "O5 (other, owner dead by transcript age)" "$rc" "$out" not_owner
reset; seed 8 ""
out=$(as_me --emit "$EMITF" 2>&1); rc=$?
assert_refused "O6 (session null)" "$rc" "$out" not_owner
reset; touch -t 202001010000 "$PROJ_DIR/sid-me.jsonl"
out=$(run_lns "$LNS" testproj --emit "$EMITF" 2>&1); rc=$?
assert_refused "O6b (no identity, owner dead)" "$rc" "$out" not_owner
reset; rm -f "$REC"
out=$(as_me --emit "$EMITF" 2>&1); rc=$?
assert_refused "O7 (no record)" "$rc" "$out" not_owner
[ ! -f "$REC" ] && ok "O7c: a refusal creates no record" || bad "O7c: refusal wrote a record"
reset; seed 8 sid-me "$LIVE_PID" "$LIVE_START"
out=$(as_me --emit "$EMITF" 2>&1); rc=$?
assert_eq "O8: the owner itself (live pid) proceeds" "$rc" "0"
reset; jq '.session.runtime = "gemini" | .session.session_id = "workspace"' "$REC" > "$REC.t" && mv "$REC.t" "$REC"
out=$(run_lns "$LNS" testproj --runtime gemini --emit "$EMITF" 2>&1); rc=$?
assert_eq "O9a: gemini's constant identity counts when the runtime is gemini" "$rc" "0"
reset; jq '.session.runtime = "gemini" | .session.session_id = "workspace"' "$REC" > "$REC.t" && mv "$REC.t" "$REC"
out=$(run_lns "$LNS" testproj --runtime claude --emit "$EMITF" 2>&1); rc=$?
assert_refused "O9b (a claude caller is not gemini-workspace; the owner is live)" "$rc" "$out" owner_live

echo "A: artefact checks (launcher_unchanged, ledger_shape, ledger_seq_mismatch)"
reset; cur="$(shasum -a 256 "$NEXTF" | cut -d' ' -f1)"; seed 8 sid-me "" "" "$cur"
out=$(as_me --emit "$EMITF" 2>&1); rc=$?
assert_refused "A1 (launcher unchanged since registration)" "$rc" "$out" launcher_unchanged
reset; rm -f "$NEXTF"
out=$(as_me --emit "$EMITF" 2>&1); rc=$?
assert_refused "A2 (launcher absent)" "$rc" "$out" launcher_unchanged
assert_contains "A2c: names the file" "$out" "next-session.md"
reset; rm -f "$HF"
out=$(as_me --emit "$EMITF" 2>&1); rc=$?
assert_refused "A3 (no ledger)" "$rc" "$out" ledger_shape
reset; printf 'no heading here\n' > "$HF"
out=$(as_me --emit "$EMITF" 2>&1); rc=$?
assert_refused "A4 (no Session Handoff heading)" "$rc" "$out" ledger_shape
reset; printf '# Session Handoff — 2026-09-18 (date only)\n' > "$HF"
out=$(as_me --emit "$EMITF" 2>&1); rc=$?
assert_refused "A5 (unnumbered top heading)" "$rc" "$out" ledger_shape
reset; ledger 7
out=$(as_me --emit "$EMITF" 2>&1); rc=$?
assert_refused "A6 (ledger 7 vs seq 8)" "$rc" "$out" ledger_seq_mismatch
assert_contains "A6c: detail" "$out" "ledger=7 seq=8"
assert_eq "A7: none of them wrote" "$(rec .seq)" "8"
reset; rm -f "$HF"; printf '# Session Handoff — session #8: hash form\n' > "$MAIN/work/testproj/session_handoff.md"
out=$(as_me --check 2>&1); rc=$?
assert_eq "A8: session_handoff.md spelling and 'session #N' form pass" "$rc" "0"
rm -f "$MAIN/work/testproj/session_handoff.md"
reset; printf '# Session Handoff — s8 (sNNN form)\n' > "$HF"
out=$(as_me --check 2>&1); rc=$?
assert_eq "A9: sNNN form passes" "$rc" "0"

# ---------------------------------------------------------------------------
echo "B: the supervisor's own bootstrap (strict parent == .session-loop pid) is exempt from ownership"
# Direct calls, never $(...): a command substitution puts a subshell between the
# launcher and this shell, and the exemption keys on the strict parent.
reset; rm -f "$REC"; ledger 7; mk_marker "$$"
run_lns "$LNS" testproj --emit "$EMITF" >"$TMP/b1" 2>&1; rc=$?
assert_eq "B1a: exit 0"                     "$rc" "0"
assert_eq "B1b: seq opened from the ledger" "$(rec .seq)" "8"
assert_eq "B1c: launch.by=supervisor"       "$(rec .launch.by)" "supervisor"
assert_eq "B1d: staged.by=supervisor"       "$(rec .staged.by)" "supervisor"
assert_eq "B1e: no predecessor"             "$(rec .launch.predecessor)" "null"
assert_eq "B1f: session null"               "$(rec .session)" "null"
assert_contains "B1g: exemption is visible" "$(cat "$TMP/b1")" "not a session"
reset; rm -f "$REC" "$HF"; mk_marker "$$"
run_lns "$LNS" testproj --emit "$EMITF" >"$TMP/b2" 2>&1; rc=$?
assert_eq "B2a: no record, no ledger — exit 0" "$rc" "0"
assert_eq "B2b: seq opens at 1"                "$(rec .seq)" "1"
assert_contains "B2c: stages session #1"       "$(rec .staged.command)" 'session\ #1.'
reset; seed 8 sid-me "$DEAD_PID" "Tue Aug  5 00:00:00 2026"; mk_marker "$$"
run_lns "$LNS" testproj --emit "$EMITF" >"$TMP/b3" 2>&1; rc=$?
assert_eq "B3a: dead owner — exit 0"                 "$rc" "0"
assert_eq "B3b: predecessor abandoned"               "$(rec .launch.predecessor.disposition)" "abandoned"
assert_eq "B3c: predecessor names the dead owner"    "$(rec .launch.predecessor.session_id)" "sid-me"
assert_eq "B3d: seq 9"                               "$(rec .seq)" "9"
reset; seed 8 sid-me "$DEAD_PID" "Tue Aug  5 00:00:00 2026"; mk_marker "$$"
jq '.session.ended = {at:"2026-09-18T01:00:00Z", door:"stop"}' "$REC" > "$REC.t" && mv "$REC.t" "$REC"
run_lns "$LNS" testproj --emit "$EMITF" >"$TMP/b4" 2>&1; rc=$?
assert_eq "B4a: owner closed through the stop door — exit 0" "$rc" "0"
assert_eq "B4b: predecessor stopped" "$(rec .launch.predecessor.disposition)" "stopped"
reset; seed 8 sid-me "$LIVE_PID" "$LIVE_START"; mk_marker "$$"
run_lns "$LNS" testproj --emit "$EMITF" >"$TMP/b5" 2>&1; rc=$?
assert_eq "B5a: live owner — the bootstrap is refused too" "$rc" "4"
assert_eq "B5b: reason owner_live" "$(reason_of "$(cat "$TMP/b5")")" "owner_live"
# Artefact checks never fire on the bootstrap: a stale launcher hash and an
# unnumbered ledger are the rolling session's business, not the supervisor's.
reset; cur="$(shasum -a 256 "$NEXTF" | cut -d' ' -f1)"; seed 8 sid-me "$DEAD_PID" "Tue Aug  5 00:00:00 2026" "$cur"
printf '# Session Handoff — no number\n' > "$HF"; mk_marker "$$"
run_lns "$LNS" testproj --emit "$EMITF" >"$TMP/b6" 2>&1; rc=$?
assert_eq "B6: artefact checks skipped on the bootstrap" "$rc" "0"
# A marker naming another live pid is not this caller's parent: no exemption.
reset; rm -f "$REC"; mk_marker "$LIVE_PID"
run_lns "$LNS" testproj --emit "$EMITF" >"$TMP/b7" 2>&1; rc=$?
assert_eq "B7a: a session with no record under a supervisor is refused" "$rc" "4"
assert_eq "B7b: reason not_owner" "$(reason_of "$(cat "$TMP/b7")")" "not_owner"
[ ! -f "$REC" ] && ok "B7c: nothing written" || bad "B7c: refusal wrote a record"

# ---------------------------------------------------------------------------
echo "L: --clear writes launch.pending for the same process"
reset; seed 8 sid-me "$$" "$MY_START"
out=$(as_me --clear 2>&1); rc=$?
assert_eq "L1a: exit 0"                        "$rc" "0"
assert_eq "L1b: seq 9"                         "$(rec .seq)" "9"
assert_eq "L1c: pending.pid is the owner's pid" "$(rec .launch.pending.pid)" "$$"
assert_eq "L1d: pending.pid_start"             "$(rec .launch.pending.pid_start)" "$MY_START"
assert_eq "L1e: pending.prompt is the prompt"  "$(rec .launch.pending.prompt)" "$PROMPT"
assert_eq "L1f: session null"                  "$(rec .session)" "null"
assert_eq "L1g: staged null"                   "$(rec .staged)" "null"
assert_eq "L1h: predecessor rolled_over"       "$(rec .launch.predecessor.disposition)" "rolled_over"
assert_contains "L1i: tells the human to clear" "$out" "/clear"
[ ! -f "$MAIN/work/testproj/.pending-clear-seed" ] && ok "L1j: no seed file" || bad "L1j: seed file written"
out=$(run_lns ROLLOVER_RELAUNCH=off CLAUDE_CODE_SESSION_ID=sid-me "$LNS" testproj --clear 2>&1); rc=$?
assert_refused "L2 (a second --clear: the slot is open, I am not its owner)" "$rc" "$out" not_owner

echo "M: bare launch (attached, no tty) and mode=off"
reset
out=$(as_me 2>&1 </dev/null); rc=$?
assert_eq       "M1a: exit 0"                      "$rc" "0"
assert_contains "M1b: run: line with the env pair" "$out" "run: TF_SESSION_PROJECT=testproj TF_SESSION_SEQ=9 claude"
assert_eq       "M1c: seq 9"                       "$(rec .seq)" "9"
assert_eq       "M1d: staged null (nothing to consume)" "$(rec .staged)" "null"
assert_eq       "M1e: pending null"                "$(rec .launch.pending)" "null"
assert_eq       "M1f: mirror counter"              "$(cat "$MAIN/work/testproj/.session-seq")" "9"
reset
out=$(run_lns ROLLOVER_RELAUNCH=off CLAUDE_CODE_SESSION_ID=sid-me "$LNS" testproj 2>&1 </dev/null); rc=$?
assert_eq           "M2a: off exit 0"            "$rc" "0"
assert_contains     "M2b: prompt shown"          "$out" "$PROMPT"
assert_not_contains "M2c: no run: line"          "$out" "run: "
assert_eq           "M2d: the rollover is still recorded" "$(rec .launch.predecessor.session_id)" "sid-me"
reset; printf 'ROLLOVER_RELAUNCH=auto\n' > "$MAIN/work/testproj/context-budget.env"
out=$(as_me --dry-run 2>&1)
assert_contains "M3a: per-item env file sets the mode" "$out" "mode=auto"
assert_not_contains "M3b: auto no longer backgrounds" "$out" "--bg"
rm -f "$MAIN/work/testproj/context-budget.env"

echo "D: deleted flags and usage errors are exit 3 and write nothing"
reset
for f in "--bg" "--unstage" "--emit relative/path" "--loop-mode handsoff" "--clear --emit $EMITF" "--emit $EMITF --dry-run"; do
  # shellcheck disable=SC2086
  out=$(as_me $f 2>&1 </dev/null); rc=$?
  assert_eq "D1: [$f] exit 3" "$rc" "3"
done
assert_eq "D2: nothing written" "$(rec .seq)" "8"
out=$(as_me --loop-mode bogus --emit "$EMITF" 2>&1); rc=$?
assert_eq "D3: bad loop mode exit 3" "$rc" "3"

# ---------------------------------------------------------------------------
echo "W: worktree_unsynced and launcher_stale (git)"
git init -q --bare "$TMP/origin.git"
git -C "$MAIN" remote add origin "$TMP/origin.git"
git -C "$MAIN" push -q -u origin main
git -C "$MAIN" worktree add -q "$MAIN/wt" -b session-branch
WLNS="$MAIN/wt/scripts/launch-next-session.sh"
reset
echo "# launcher v2" > "$MAIN/wt/work/testproj/next-session.md"
out=$(run_lns CLAUDE_CODE_SESSION_ID=sid-me "$WLNS" testproj --check 2>&1 </dev/null); rc=$?
assert_refused "W1 (dirty worktree)" "$rc" "$out" worktree_unsynced
GITC -C "$MAIN/wt" commit -qam "rollover: new launcher"
out=$(run_lns CLAUDE_CODE_SESSION_ID=sid-me "$WLNS" testproj --check 2>&1 </dev/null); rc=$?
assert_refused "W2 (unpushed)" "$rc" "$out" worktree_unsynced
git -C "$MAIN/wt" push -q origin session-branch:main
out=$(run_lns CLAUDE_CODE_SESSION_ID=sid-me "$WLNS" testproj --check 2>&1 </dev/null); rc=$?
assert_eq "W3a: --check from a worktree passes without pulling" "$rc" "0"
assert_eq "W3b: main not pulled by --check" "$(cat "$NEXTF")" "# launcher"
out=$(run_lns CLAUDE_CODE_SESSION_ID=sid-me "$WLNS" testproj --emit "$EMITF" 2>&1 </dev/null); rc=$?
assert_eq "W4a: real launch from the worktree — exit 0"  "$rc" "0"
assert_eq "W4b: main checkout ff-pulled"                 "$(cat "$NEXTF")" "# launcher v2"
assert_eq "W4c: record written in the main checkout"     "$(rec .seq)" "9"
[ ! -f "$MAIN/wt/work/testproj/session-state.json" ] && ok "W4d: no record in the worktree" || bad "W4d: worktree record written"
reset
echo "local edit" >> "$NEXTF"
out=$(run_lns CLAUDE_CODE_SESSION_ID=sid-me "$WLNS" testproj --check 2>&1 </dev/null); rc=$?
assert_refused "W5 (dirty main checkout)" "$rc" "$out" worktree_unsynced
git -C "$MAIN" checkout -q -- work/testproj
echo "# main-local" > "$NEXTF"; GITC -C "$MAIN" commit -qam "main-local"
echo "# launcher v4" > "$MAIN/wt/work/testproj/next-session.md"; GITC -C "$MAIN/wt" commit -qam "rollover v4"
git -C "$MAIN/wt" push -q origin session-branch:main
out=$(run_lns CLAUDE_CODE_SESSION_ID=sid-me "$WLNS" testproj --emit "$EMITF" 2>&1 </dev/null); rc=$?
assert_refused "W6 (diverged main: ff-only pull fails)" "$rc" "$out" worktree_unsynced
assert_eq "W6c: nothing written" "$(rec .seq)" "8"
git -C "$MAIN" reset -q --hard origin/main

echo "F: launcher_stale"
reset
echo "# launcher v5" > "$MAIN/wt/work/testproj/next-session.md"; GITC -C "$MAIN/wt" commit -qam "rollover v5"
out=$(as_me --check 2>&1 </dev/null); rc=$?
assert_refused "F1 (newer launcher on an unmerged branch)" "$rc" "$out" launcher_stale
out=$(as_me --check --skip-freshness 2>&1 </dev/null); rc=$?
assert_eq "F2: --skip-freshness passes" "$rc" "0"
git -C "$MAIN" checkout -q -- work/testproj; GITC -C "$MAIN" merge -q session-branch
reset
out=$(as_me --check 2>&1 </dev/null); rc=$?
assert_eq "F3: merged — passes" "$rc" "0"
echo "# launcher v6" > "$MAIN/wt/work/testproj/next-session.md"; GITC -C "$MAIN/wt" commit -qam "rollover v6"
git -C "$MAIN/wt" push -q origin session-branch:main
out=$(as_me --check 2>&1 </dev/null); rc=$?
assert_refused "F4 (origin/main ahead)" "$rc" "$out" launcher_stale
git -C "$MAIN" checkout -q -- work/testproj; git -C "$MAIN" pull -q --ff-only
reset
out=$(as_me --check 2>&1 </dev/null); rc=$?
assert_eq "F5: after the pull — passes" "$rc" "0"

echo; echo "passed=$PASS failed=$FAIL"
[ "$FAIL" -eq 0 ]
