#!/usr/bin/env bash
# File: scripts/tests/test-context-budget-registry.sh
# Purpose: Regression tests for context-budget.sh's session verbs on the
#          per-item record (work/<item>/session-state.json, Stage 4 phase 3):
#          register fills `session` and binds to an open launch; release and
#          close merge `ended` only for the owner; close runs the ledger checks.
#          Plus the kept registry behaviours (M13 self-measure, M16 re-pin, the
#          --session-id pin, the process walk, the supervised query, S1).
#          Self-contained: throwaway workspace + fake $HOME in mktemp -d.
set -u
SRC_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TMP="$(mktemp -d)"; TMP="$(cd "$TMP" && pwd -P)"
mkdir -p "$TMP/scripts/lib" "$TMP/work/testproj" "$TMP/home"
cp "$SRC_ROOT/scripts/context-budget.sh" "$TMP/scripts/"
cp "$SRC_ROOT/scripts/lib/session-lib.sh" "$TMP/scripts/lib/"
printf 'CONTEXT_DUMB_ZONE_TOKENS=150000\nCONTEXT_DUMB_ZONE_WARN_TOKENS=120000\n' \
  > "$TMP/context-budget.env"
printf '# launcher\n' > "$TMP/work/testproj/next-session.md"
export HOME="$TMP/home"
cd "$TMP"
CB="$TMP/scripts/context-budget.sh"
REC="$TMP/work/testproj/session-state.json"
SESS="$TMP/.context-budget/sessions"
HF="$TMP/work/testproj/handoff.md"
SLUG="$(pwd | tr '/.' '--')"
PROJ_DIR="$HOME/.claude/projects/$SLUG"; mkdir -p "$PROJ_DIR"
# A process that is live for the whole suite (a seeded owner's pid).
sleep 600 & LIVE_PID=$!
LIVE_START="$(ps -o lstart= -p "$LIVE_PID" | sed 's/^ *//;s/ *$//')"
trap 'kill "$LIVE_PID" 2>/dev/null; wait "$LIVE_PID" 2>/dev/null; rm -rf "$TMP"' EXIT
sleep 0 & DEAD_PID=$!; wait "$DEAD_PID" 2>/dev/null
# Hermetic: the suite may itself run under a supervised session.
unset TF_SESSION_PROJECT TF_SESSION_SEQ TF_SESSION_LOOP_PROJECT

PASS=0; FAIL=0
ok()   { PASS=$((PASS+1)); echo "  ok: $1"; }
bad()  { FAIL=$((FAIL+1)); echo "  FAIL: $1" >&2; }
assert_eq() { [ "$2" = "$3" ] && ok "$1" || bad "$1 (want [$3] got [$2])"; }
assert_contains() { case "$2" in *"$3"*) ok "$1" ;; *) bad "$1 (no [$3] in [$2])" ;; esac; }
assert_absent() { case "$2" in *"$3"*) bad "$1 (unwanted [$3] in [$2])" ;; *) ok "$1" ;; esac; }
assert_same() { cmp -s "$2" "$3" && ok "$1" || bad "$1 (record changed)"; }

mk_transcript() {  # $1=session-id $2=input-tokens
  jq -cn --argjson t "$2" \
    '{message:{usage:{input_tokens:$t,cache_read_input_tokens:0,cache_creation_input_tokens:0}},isSidechain:false}' \
    > "$PROJ_DIR/$1.jsonl"
}
run_as() {  # $1=claude-session-id, rest = context-budget.sh args
  local sid="$1"; shift
  CLAUDE_CODE_SESSION_ID="$sid" "$CB" "$@" --runtime claude
}
rec() { jq -r "$1" "$REC" 2>/dev/null; }
# The suite may run inside a real claude session, where the process walk finds
# a live claude ancestor and records its pid; outside one it records none.
# Owner-liveness cases must not depend on that, so they seed the owner.
seed_owner() {  # $1=sid $2=pid ("" = none) $3=pid_start $4=seq
  jq -n --arg sid "$1" --arg pid "$2" --arg ps "$3" --argjson seq "$4" \
    --arg af "$PROJ_DIR/$1.jsonl" \
    '{schema:1, seq:$seq, launch:{launched_at:"2026-01-01T00:00:00Z", pending:null},
      session:({seq:$seq, runtime:"claude", session_id:$sid, artifact:$af,
                registered_at:"2026-01-01T00:00:00Z", launcher_hash:"", user:"t", ended:null}
               + (if $pid == "" then {} else {pid:($pid|tonumber), pid_start:$ps} end))}' > "$REC"
}
strip_pid() { jq 'del(.session.pid, .session.pid_start)' "$REC" > "$REC.t" && mv "$REC.t" "$REC"; }

echo "T1: two concurrent sessions each measure their own transcript (M13)"
mk_transcript aaa 50000
mk_transcript bbb 90000
run_as aaa register --quiet >/dev/null
run_as bbb register --quiet >/dev/null          # must NOT clobber aaa's registration
out=$(run_as aaa check)
assert_contains "T1a: aaa check binds aaa's transcript" "$out" "artifact=$PROJ_DIR/aaa.jsonl"
assert_contains "T1b: aaa check measures aaa's tokens"  "$out" "tokens=50000"
out=$(run_as bbb check)
assert_contains "T1c: bbb check measures bbb's tokens"  "$out" "tokens=90000"
[ ! -f "$REC" ] && ok "T1d: a project-less register writes no item record" \
                || bad "T1d: record written without a work item"

echo "R1: register --project on a record-less item opens seq and fills session"
rm -f "$REC" "$HF"
err=$(run_as aaa register --project testproj 2>&1 >/dev/null); rc=$?
assert_eq "R1a: measurement exit code" "$rc" "0"
assert_eq "R1b: schema 1"              "$(rec .schema)" "1"
assert_eq "R1c: seq opened at 1 (no ledger)" "$(rec .seq)" "1"
assert_eq "R1d: session.seq"           "$(rec .session.seq)" "1"
assert_eq "R1e: session.runtime"       "$(rec .session.runtime)" "claude"
assert_eq "R1f: session.session_id"    "$(rec .session.session_id)" "aaa"
assert_eq "R1g: session.artifact"      "$(rec .session.artifact)" "$PROJ_DIR/aaa.jsonl"
[ -n "$(rec '.session.registered_at // empty')" ] && ok "R1h: registered_at" || bad "R1h: no registered_at"
[ -n "$(rec '.session.launcher_hash // empty')" ] && ok "R1i: launcher_hash taken from next-session.md" || bad "R1i: no launcher_hash"
[ -n "$(rec '.session.user // empty')" ] && ok "R1j: user" || bad "R1j: no user"
assert_eq "R1k: ended is null"         "$(rec '.session.ended')" "null"
assert_contains "R1l: register says it bound the item" "$err" "bound work/testproj seq=1"
assert_eq "R1m: registry record carries the project" "$(jq -r .project "$SESS/claude-aaa.json")" "testproj"
[ ! -f "$TMP/work/testproj/.active-session" ] && ok "R1n: no .active-session lock written" \
                                              || bad "R1n: .active-session written"
mkdir -p "$TMP/work/proj2"
printf '# Session Handoff — 6 (2026-09-10): block six\n\nbody\n' > "$TMP/work/proj2/handoff.md"
run_as aaa register --project proj2 --quiet >/dev/null
assert_eq "R1o: a ledger with top block 6 opens seq at 7" \
  "$(jq -r .seq "$TMP/work/proj2/session-state.json")" "7"
assert_eq "R1p: and session.seq follows" \
  "$(jq -r .session.seq "$TMP/work/proj2/session-state.json")" "7"

echo "R2: re-registering the same session keeps seq and refreshes the block"
run_as aaa register --project testproj --quiet >/dev/null
assert_eq "R2a: seq unchanged" "$(rec .seq)" "1"
assert_eq "R2b: still the owner" "$(rec .session.session_id)" "aaa"

echo "R3: a stub successor binds to an open launch through TF_SESSION_PROJECT + TF_SESSION_SEQ"
jq -n '{schema:1, seq:5, launch:{launched_at:"2026-01-01T00:00:00Z", by:"session", pending:null}, session:null}' > "$REC"
mk_transcript succ 1000
err=$(TF_SESSION_PROJECT=testproj TF_SESSION_SEQ=5 run_as succ register 2>&1 >/dev/null)
assert_eq "R3a: session filled by the successor" "$(rec .session.session_id)" "succ"
assert_eq "R3b: session.seq is the advanced number" "$(rec .session.seq)" "5"
assert_eq "R3c: seq not advanced by registration" "$(rec .seq)" "5"
assert_contains "R3d: bound via env" "$err" "bound work/testproj seq=5 via=env"
assert_eq "R3e: registry record carries the project" "$(jq -r .project "$SESS/claude-succ.json")" "testproj"
# R3f: the number must match — a stale variable never claims a launch.
jq -n '{schema:1, seq:5, launch:{pending:null}, session:null}' > "$REC"; cp "$REC" "$TMP/before"
mk_transcript stale 1000
err=$(TF_SESSION_PROJECT=testproj TF_SESSION_SEQ=4 run_as stale register 2>&1 >/dev/null)
assert_same "R3f: seq mismatch leaves the record untouched" "$REC" "$TMP/before"
assert_contains "R3g: and says why" "$err" "not bound"
assert_eq "R3h: registered project-less" "$(jq -r '.project // ""' "$SESS/claude-stale.json")" ""
# R3i: both variables are required.
err=$(TF_SESSION_PROJECT=testproj run_as stale register 2>&1 >/dev/null)
assert_same "R3i: project without a number does not bind" "$REC" "$TMP/before"
# R3j: a variable naming no work directory invents nothing.
TF_SESSION_PROJECT=nosuchproj TF_SESSION_SEQ=1 run_as stale register --quiet >/dev/null
[ ! -e "$TMP/work/nosuchproj" ] && ok "R3j: no work item invented" || bad "R3j: work/nosuchproj created"
# R3k: the record must exist — an env launch always has one (the launcher wrote it).
rm -f "$REC"
err=$(TF_SESSION_PROJECT=testproj TF_SESSION_SEQ=1 run_as stale register 2>&1 >/dev/null)
[ ! -f "$REC" ] && ok "R3k: env binding never creates a record" || bad "R3k: record created from env"
assert_contains "R3l: says not bound" "$err" "not bound"
# R3m: an env-bound successor nulls launch.pending (binding consumes the launch).
jq -n '{schema:1, seq:6, launch:{pending:{pid:1, pid_start:"x", prompt:"p"}}, session:null}' > "$REC"
TF_SESSION_PROJECT=testproj TF_SESSION_SEQ=6 run_as succ register --quiet >/dev/null
assert_eq "R3m: launch.pending emptied on bind" "$(rec .launch.pending)" "null"
assert_eq "R3n: the rest of launch survives" "$(rec '.launch | type')" "object"
# R3o: children are excluded by construction — a sub-agent inheriting the pair
# must not take the item.
jq -n '{schema:1, seq:6, launch:{pending:null}, session:null}' > "$REC"; cp "$REC" "$TMP/before"
mk_transcript agent-env 1000
TF_SESSION_PROJECT=testproj TF_SESSION_SEQ=6 run_as succ register \
  --transcript "$PROJ_DIR/agent-env.jsonl" --parent-session succ --quiet >/dev/null 2>&1
assert_same "R3o: a child leaves the open launch alone" "$REC" "$TMP/before"

echo "R5: a live different owner keeps the slot (owner_live); --takeover overwrites it"
mk_transcript aaa 50000; mk_transcript bbb 90000
seed_owner bbb "$LIVE_PID" "$LIVE_START" 5; cp "$REC" "$TMP/before"
err=$(run_as aaa register --project testproj 2>&1 >/dev/null); rc=$?
assert_eq       "R5a: register still exits with the measurement" "$rc" "0"
assert_contains "R5b: reason=owner_live"    "$err" "reason=owner_live"
assert_contains "R5c: names the owner"      "$err" "owner=claude-bbb"
assert_same     "R5d: record byte-identical" "$REC" "$TMP/before"
assert_eq       "R5e: non-owner registered without the project" \
  "$(jq -r '.project // ""' "$SESS/claude-aaa.json")" ""
err=$(run_as aaa register --project testproj --takeover 2>&1 >/dev/null)
assert_eq       "R5f: --takeover moves the slot" "$(rec .session.session_id)" "aaa"
assert_eq       "R5g: seq kept"                  "$(rec .seq)" "5"
assert_contains "R5h: takeover logged with the loser" "$err" "reason=takeover loser=claude-bbb"

echo "R6: a dead owner is adopted; a pid-less owner falls back to its transcript age"
seed_owner ccc "$DEAD_PID" "Thu Jan  1 00:00:00 2026" 5
err=$(run_as aaa register --project testproj 2>&1 >/dev/null)
assert_eq       "R6a: dead owner adopted"        "$(rec .session.session_id)" "aaa"
assert_eq       "R6b: seq kept"                  "$(rec .seq)" "5"
assert_contains "R6c: reason=adopted with the loser" "$err" "reason=adopted loser=claude-ccc"
# pid-less owner (registered from outside the process tree): transcript age decides.
mk_transcript ddd 1000
run_as ddd register --project testproj --quiet >/dev/null; strip_pid   # ddd owns, no pid
cp "$REC" "$TMP/before"
err=$(run_as aaa register --project testproj 2>&1 >/dev/null)
assert_contains "R6d: fresh transcript, no pid -> owner_live" "$err" "reason=owner_live"
assert_same     "R6e: record untouched" "$REC" "$TMP/before"
touch -t 202601010000 "$PROJ_DIR/ddd.jsonl"
err=$(run_as aaa register --project testproj 2>&1 >/dev/null)
assert_contains "R6f: stale transcript, no pid -> adopted" "$err" "reason=adopted"
assert_eq       "R6g: slot moved" "$(rec .session.session_id)" "aaa"
# no pid and no registry record either: unknowable is dead.
seed_owner ghost "" "" 5; rm -f "$SESS/claude-ghost.json"
err=$(run_as aaa register --project testproj 2>&1 >/dev/null)
assert_contains "R6h: unknowable owner is adopted" "$err" "reason=adopted loser=claude-ghost"

echo "R7: release merges ended.at for the owner only"
mk_transcript aaa 50000
run_as aaa register --project testproj --quiet >/dev/null
run_as aaa release --project testproj --quiet; rc=$?
assert_eq "R7a: owner release exits 0" "$rc" "0"
[ -n "$(rec '.session.ended.at // empty')" ] && ok "R7b: ended.at set" || bad "R7b: no ended.at"
assert_eq "R7c: no door from release" "$(rec '.session.ended.door // "none"')" "none"
assert_eq "R7d: owner unchanged" "$(rec .session.session_id)" "aaa"
cp "$REC" "$TMP/before"
mk_transcript zzz 1000
err=$(run_as zzz release --project testproj 2>&1 >/dev/null); rc=$?
assert_eq       "R7e: non-owner release exits 1" "$rc" "1"
assert_same     "R7f: non-owner release changes nothing (cmp)" "$REC" "$TMP/before"
assert_contains "R7g: says not_owner" "$err" "reason=not_owner"
err=$(run_as zzz release 2>&1 >/dev/null); rc=$?
assert_eq       "R7h: no project bound anywhere -> exit 0" "$rc" "0"
assert_contains "R7i: says nothing to release" "$err" "no work item bound"
assert_same     "R7j: still untouched" "$REC" "$TMP/before"
jq '.session.ended = {door:"stop", at:"2026-01-01T00:00:00Z"}' "$REC" > "$REC.t" && mv "$REC.t" "$REC"
run_as aaa release --quiet >/dev/null                     # no --project: from own registry record
assert_eq "R7k: bare release derives the project; door survives the merge" "$(rec .session.ended.door)" "stop"
[ "$(rec .session.ended.at)" != "2026-01-01T00:00:00Z" ] && ok "R7l: ended.at refreshed" || bad "R7l: ended.at not refreshed"
err=$(run_as aaa release --project testproj --takeover 2>&1 >/dev/null); rc=$?
assert_eq "R7m: --takeover is not a release option" "$rc" "3"

echo "R8: close — the stop door runs the ledger checks inline; --check is the dry run"
mk_transcript aaa 50000
rm -f "$HF"
run_as aaa register --project testproj --quiet >/dev/null
assert_eq "R8-setup: seq is 5" "$(rec .seq)" "5"
cp "$REC" "$TMP/before"
err=$(run_as aaa close --project testproj 2>&1 >/dev/null); rc=$?
assert_eq       "R8a: no ledger -> exit 4"           "$rc" "4"
assert_contains "R8b: reason=ledger_shape"           "$err" "reason=ledger_shape"
assert_same     "R8c: record untouched"              "$REC" "$TMP/before"
printf '# Session Handoff — 2026-09-17 (no number here)\n' > "$HF"
err=$(run_as aaa close --project testproj 2>&1 >/dev/null); rc=$?
assert_eq       "R8d: unnumbered top heading -> exit 4" "$rc" "4"
assert_contains "R8e: reason=ledger_shape"           "$err" "reason=ledger_shape"
printf 'prose first\n# Session Handoff — 4 (2026-09-17): wrong block\n' > "$HF"
err=$(run_as aaa close --project testproj 2>&1 >/dev/null); rc=$?
assert_eq       "R8f: wrong block number -> exit 4"  "$rc" "4"
assert_contains "R8g: reason=ledger_seq_mismatch"    "$err" "reason=ledger_seq_mismatch"
assert_contains "R8h: detail carries both numbers"   "$err" "ledger=4 seq=5"
assert_same     "R8i: record untouched"              "$REC" "$TMP/before"
printf '# Session Handoff — 5 (2026-09-17): the right block\n\nbody\n' > "$HF"
mk_transcript zzz 1000
err=$(run_as zzz close --project testproj 2>&1 >/dev/null); rc=$?
assert_eq       "R8j: non-owner close -> exit 4"     "$rc" "4"
assert_contains "R8k: reason=not_owner"              "$err" "reason=not_owner"
assert_same     "R8l: record untouched"              "$REC" "$TMP/before"
out=$(run_as aaa close --project testproj --check 2>/dev/null); rc=$?
assert_eq       "R8m: --check passes"                "$rc" "0"
assert_contains "R8n: says check ok"                 "$out" "close: check ok seq=5"
assert_same     "R8o: --check writes nothing"        "$REC" "$TMP/before"
out=$(run_as aaa close --project testproj 2>/dev/null); rc=$?
assert_eq       "R8p: close passes"                  "$rc" "0"
assert_contains "R8q: says ok"                       "$out" "close: ok seq=5"
assert_eq       "R8r: door=stop"                     "$(rec .session.ended.door)" "stop"
[ -n "$(rec '.session.ended.at // empty')" ] && ok "R8s: ended.at set" || bad "R8s: no ended.at"
assert_eq       "R8t: owner still named"             "$(rec .session.session_id)" "aaa"
printf '# Session Handoff — 2026-09-17 (session #5: hash form)\n' > "$HF"
out=$(run_as aaa close --project testproj --check 2>/dev/null); rc=$?
assert_eq       "R8u: the 'session #N' heading form parses" "$rc" "0"
run_as aaa record --project testproj --check --quiet >/dev/null 2>&1; rc=$?
assert_eq       "R8v: --check with another verb is a usage error" "$rc" "3"
rm -f "$HF"

echo "R9: jq missing — refused with reason=jq_missing before anything is read"
mkdir -p "$TMP/nojq"
for t in bash dirname basename git ps stat date cat ls head tail tr sed grep mkdir rm find mv cmp hostname sleep xargs cut sort uniq wc touch; do
  p="$(command -v "$t" 2>/dev/null)" && ln -sf "$p" "$TMP/nojq/$t"
done
cp "$REC" "$TMP/before"
err=$(PATH="$TMP/nojq" CLAUDE_CODE_SESSION_ID=aaa "$CB" close --project testproj --runtime claude 2>&1 >/dev/null); rc=$?
assert_eq       "R9a: exit 4"            "$rc" "4"
assert_contains "R9b: reason=jq_missing" "$err" "reason=jq_missing"
assert_same     "R9c: record untouched"  "$REC" "$TMP/before"
err=$(PATH="$TMP/nojq" CLAUDE_CODE_SESSION_ID=aaa "$CB" check --runtime claude 2>&1 >/dev/null); rc=$?
assert_eq       "R9d: check refuses too" "$rc" "4"

echo "R10: the retired verbs refuse with a pointer, exit 3"
for v in seq-sync opts-sync rollover-complete; do
  err=$(run_as aaa "$v" --project testproj 2>&1 >/dev/null); rc=$?
  assert_eq       "R10 $v: exit 3" "$rc" "3"
  assert_contains "R10 $v: names the record" "$err" "session-state.json"
done

echo "T5: gemini register — fresh telemetry log means a concurrent session owns it"
mkdir -p "$TMP/.gemini" "$HOME/.gemini/tmp/h0"
printf '{"note":"chat log"}' > "$HOME/.gemini/tmp/h0/logs.json"
printf '{"gen_ai.usage.input_tokens": 42}\n' > "$TMP/.gemini/telemetry.log"   # fresh + non-empty
"$CB" register --runtime gemini --quiet >/dev/null 2>&1
[ -s "$TMP/.gemini/telemetry.log" ] && ok "T5a: fresh telemetry log NOT reset" || bad "T5a: log was reset"
assert_contains "T5b: registered estimate artifact instead" \
  "$(jq -r .artifact "$SESS/gemini-workspace.json")" "logs.json"
touch -t 202601010000 "$TMP/.gemini/telemetry.log"                            # now stale
"$CB" register --runtime gemini --quiet >/dev/null 2>&1
[ ! -s "$TMP/.gemini/telemetry.log" ] && ok "T5c: stale telemetry log reset" || bad "T5c: not reset"

echo "T7: child registration — parent-side, artifact-keyed, parent/depth recorded, no item state"
rm -f "$REC"
mk_transcript aaa 50000
run_as aaa register --project testproj --quiet >/dev/null      # parent, owner
cp "$REC" "$TMP/before"
mk_transcript agent-c1 12000
run_as aaa register --transcript "$PROJ_DIR/agent-c1.jsonl" \
  --parent-session aaa --agent-id c1 --project testproj --quiet >/dev/null 2>&1
REC_C1="$SESS/claude-agent-c1.json"
[ -f "$REC_C1" ] && ok "T7a: record keyed by artifact id, not env sid" \
  || bad "T7a: no record at claude-agent-c1.json"
assert_eq "T7b: parent_session_id recorded" "$(jq -r '.parent_session_id // "none"' "$REC_C1" 2>/dev/null)" "aaa"
assert_eq "T7c: depth = parent depth + 1"   "$(jq -r '.depth // "none"' "$REC_C1" 2>/dev/null)" "1"
assert_eq "T7d: agent_id recorded"          "$(jq -r '.agent_id // "none"' "$REC_C1" 2>/dev/null)" "c1"
assert_eq "T7e: no role field any more"     "$(jq -r 'has("role")' "$REC_C1")" "false"
assert_same "T7f: the item record is the parent's, untouched" "$REC" "$TMP/before"
[ ! -d "$TMP/work/testproj/.agent-locks" ] && ok "T7g: no child lock written" || bad "T7g: .agent-locks written"
err=$(run_as aaa register --transcript "$PROJ_DIR/agent-c1.jsonl" \
  --parent-session ghost --project testproj 2>&1 >/dev/null); rc=$?
[ "$rc" -eq 3 ] && ok "T7h: unregistered parent session dies" || bad "T7h: rc=$rc (want 3)"
assert_eq "T7i: registry record has no role" "$(jq -r 'has("role")' "$SESS/claude-aaa.json")" "false"

echo "G1: register from a git worktree lands the item record in the shared root"
GW="$(mktemp -d)"; GW="$(cd "$GW" && pwd -P)"
trap 'kill "$LIVE_PID" 2>/dev/null; wait "$LIVE_PID" 2>/dev/null; rm -rf "$TMP" "$GW"' EXIT
mkdir -p "$GW/scripts/lib" "$GW/work/testproj"
cp "$SRC_ROOT/scripts/context-budget.sh" "$GW/scripts/"
cp "$SRC_ROOT/scripts/lib/session-lib.sh" "$GW/scripts/lib/"
printf 'CONTEXT_DUMB_ZONE_TOKENS=150000\nCONTEXT_DUMB_ZONE_WARN_TOKENS=120000\n' \
  > "$GW/context-budget.env"
touch "$GW/work/testproj/.gitkeep"
git -C "$GW" init -q -b main
git -C "$GW" -c user.email=t@t -c user.name=t add -A >/dev/null
git -C "$GW" -c user.email=t@t -c user.name=t commit -qm init
git -C "$GW" worktree add -q "$GW/wt" -b wt-branch
cd "$GW/wt"
WSLUG="$(pwd | tr '/.' '--')"
WPROJ_DIR="$HOME/.claude/projects/$WSLUG"; mkdir -p "$WPROJ_DIR"
jq -cn '{message:{usage:{input_tokens:40000,cache_read_input_tokens:0,cache_creation_input_tokens:0}},isSidechain:false}' \
  > "$WPROJ_DIR/ggg.jsonl"
CLAUDE_CODE_SESSION_ID=ggg "$GW/wt/scripts/context-budget.sh" \
  register --project testproj --runtime claude --quiet >/dev/null 2>&1
assert_eq "G1a: item record lands in main-root work/testproj" \
  "$(jq -r '.session.session_id // "none"' "$GW/work/testproj/session-state.json" 2>/dev/null)" "ggg"
[ ! -e "$GW/wt/work/testproj/session-state.json" ] \
  && ok "G1b: no record in the worktree's own checkout" \
  || bad "G1b: record written under the worktree"
[ -f "$GW/.context-budget/sessions/claude-ggg.json" ] \
  && ok "G1c: session record in main-root state dir" \
  || bad "G1c: no record in main-root .context-budget"
[ ! -d "$GW/wt/.context-budget" ] \
  && ok "G1d: no state dir created in the worktree" \
  || bad "G1d: worktree grew its own .context-budget"

echo "G2: record from the worktree appends to the main-root ledger"
CLAUDE_CODE_SESSION_ID=ggg "$GW/wt/scripts/context-budget.sh" \
  record --label "wt-unit" --runtime claude --quiet >/dev/null 2>&1
grep -q "wt-unit" "$GW/.context-budget/context-ledger.jsonl" 2>/dev/null \
  && ok "G2a: ledger line in main root" || bad "G2a: no main-root ledger line"
[ ! -e "$GW/wt/.context-budget/context-ledger.jsonl" ] \
  && ok "G2b: no ledger in the worktree" || bad "G2b: worktree ledger written"

echo "G3: legacy work/context-decay ledger is folded into .context-budget (M19)"
mkdir -p "$GW/work/context-decay"
printf '%s\n' '{"ts":"old","session":"legacy.jsonl","tokens":1,"threshold":150000,"label":"legacy-line"}' \
  > "$GW/work/context-decay/context-ledger.jsonl"
CLAUDE_CODE_SESSION_ID=ggg "$GW/wt/scripts/context-budget.sh" \
  record --label "post-migrate" --runtime claude --quiet >/dev/null 2>&1
grep -q "legacy-line" "$GW/.context-budget/context-ledger.jsonl" 2>/dev/null \
  && ok "G3a: legacy lines folded into the new ledger" \
  || bad "G3a: legacy ledger lines lost"
[ ! -e "$GW/work/context-decay/context-ledger.jsonl" ] \
  && ok "G3b: legacy ledger file removed" || bad "G3b: legacy ledger file remains"
grep -q "post-migrate" "$GW/.context-budget/context-ledger.jsonl" 2>/dev/null \
  && ok "G3c: new records append after migration" || bad "G3c: post-migration record missing"
CLAUDE_CODE_SESSION_ID=ggg "$GW/wt/scripts/context-budget.sh" \
  release --project testproj --runtime claude --quiet >/dev/null 2>&1
[ -n "$(jq -r '.session.ended.at // empty' "$GW/work/testproj/session-state.json")" ] \
  && ok "G3d: release from the worktree ended the main-root record" || bad "G3d: no ended.at"
cd "$TMP"

echo "T16: explicit env override beats context-budget.env (L18)"
printf 'CONTEXT_LOCK_STALE_SECS=10800\n' >> "$TMP/context-budget.env"
rm -f "$REC"
mk_transcript aaa 50000; mk_transcript bbb 90000
run_as aaa register --project testproj --quiet >/dev/null; strip_pid   # transcript-age fallback
touch -t 202601010000 "$PROJ_DIR/aaa.jsonl"   # hours-stale under the env file's 10800
CONTEXT_LOCK_STALE_SECS=999999999 CLAUDE_CODE_SESSION_ID=bbb \
  "$CB" register --project testproj --runtime claude --quiet >/dev/null 2>&1
assert_eq "T16a: huge explicit stale-secs keeps the owner live — slot not taken" \
  "$(rec .session.session_id)" "aaa"

echo "T20: supervised — the record's chain.supervisor block (C1)"
sup_block() {  # $1 = pid; merges a chain.supervisor block naming it into the record
  local ps; ps="$(ps -o lstart= -p "$1" 2>/dev/null | sed 's/^ *//;s/ *$//')"
  [ -f "$REC" ] || echo '{"schema":1}' > "$REC"
  jq --argjson pid "$1" --arg ps "$ps" \
    '.chain.supervisor = {pid:$pid, pid_start:$ps, started_at:"2026-01-01T00:00:00Z"}' "$REC" > "$REC.t" && mv "$REC.t" "$REC"
}
rm -f "$REC"
out=$(run_as aaa supervised --project testproj 2>/dev/null); rc=$?
assert_eq "T20a: unsupervised line" "$out" "unsupervised"
assert_eq "T20a: unsupervised rc"   "$rc"  "1"
sup_block "$$"
out=$(run_as aaa supervised --project testproj 2>/dev/null); rc=$?
assert_eq "T20b: supervised rc" "$rc" "0"
case "$out" in "supervised pid=$$ project=testproj started_at="*) ok "T20b: supervised line" ;;
               *) bad "T20b: supervised line was: $out" ;; esac
sup_block "$DEAD_PID"
out=$(run_as aaa supervised --project testproj 2>/dev/null); rc=$?
assert_eq "T20c: ambiguous rc" "$rc" "2"
case "$out" in ambiguous*) ok "T20c: ambiguous line" ;; *) bad "T20c: line was: $out" ;; esac
assert_eq "T20c: stale block NOT cleared" "$(rec .chain.supervisor.pid)" "$DEAD_PID"
rm -f "$REC"
out=$(TF_SESSION_LOOP_PROJECT=testproj run_as aaa supervised --project testproj 2>/dev/null); rc=$?
assert_eq "T20d: env-only ambiguous rc" "$rc" "2"
out=$(run_as aaa supervised --project testproj --quiet 2>/dev/null); rc=$?
assert_eq "T20e: quiet is silent" "$out" ""
assert_eq "T20e: quiet rc"        "$rc"  "1"
run_as aaa supervised >/dev/null 2>&1; rc=$?
assert_eq "T20f: missing --project errors" "$rc" "3"

echo "T22: record refreshes the session record's mtime (7-day purge liveness, R9)"
mk_transcript aaa 50000
run_as aaa register --quiet >/dev/null
touch -t 202001010000 "$SESS/claude-aaa.json"      # back-date: looks >7 days dead
run_as aaa record --label "r9-liveness" --quiet >/dev/null 2>&1
mt=$(stat -f%m "$SESS/claude-aaa.json" 2>/dev/null || stat -c%Y "$SESS/claude-aaa.json" 2>/dev/null)
age=$(( $(date +%s) - mt ))
[ "$age" -lt 600 ] && ok "T22a: record refreshed session record mtime (age=${age}s)" \
  || bad "T22a: session record mtime not refreshed by record (age=${age}s)"

echo "M16: relocated transcript (EnterWorktree) — re-pin + liveness survive"
WTPROJ="$HOME/.claude/projects/wt-slug--claude-worktrees-m16"
mkdir -p "$WTPROJ"
rm -f "$REC"
mk_transcript aaa 50000
run_as aaa register --quiet >/dev/null
mv "$PROJ_DIR/aaa.jsonl" "$WTPROJ/aaa.jsonl"
out=$(run_as aaa record --label m16-a 2>/dev/null)
assert_contains "M16a: record binds the moved transcript" "$out" "artifact=$WTPROJ/aaa.jsonl"
assert_eq "M16b: registry record re-pinned to the new path" \
  "$(jq -r .artifact "$SESS/claude-aaa.json")" "$WTPROJ/aaa.jsonl"
mk_transcript aaa 50000                              # stale copy at the old path
touch -t 202601010000 "$PROJ_DIR/aaa.jsonl"
jq -cn '{message:{usage:{input_tokens:60000,cache_read_input_tokens:0,cache_creation_input_tokens:0}},isSidechain:false}' \
  > "$WTPROJ/aaa.jsonl"                              # live relocated transcript, fresher
jq --arg af "$PROJ_DIR/aaa.jsonl" '.artifact = $af' "$SESS/claude-aaa.json" \
  > "$SESS/tmp.json" && mv "$SESS/tmp.json" "$SESS/claude-aaa.json"   # pinned at old path
out=$(run_as aaa record --label m16-c 2>/dev/null)
assert_contains "M16c: freshest match beats the stale pinned copy" "$out" "tokens=60000"
assert_eq "M16d: record re-pinned off the stale copy" \
  "$(jq -r .artifact "$SESS/claude-aaa.json")" "$WTPROJ/aaa.jsonl"
rm -f "$PROJ_DIR/aaa.jsonl"
# Other-side liveness (pid-less owner): a relocated, fresh transcript still reads live.
rm -f "$REC" "$WTPROJ/aaa.jsonl"
mk_transcript aaa 50000; mk_transcript bbb 90000
run_as aaa register --project testproj --quiet >/dev/null; strip_pid
mv "$PROJ_DIR/aaa.jsonl" "$WTPROJ/aaa.jsonl"                # relocated; still fresh
err=$(run_as bbb register --project testproj 2>&1 >/dev/null)
assert_eq "M16e: relocated live owner keeps the slot" "$(rec .session.session_id)" "aaa"
assert_contains "M16f: challenger sees owner_live" "$err" "reason=owner_live"
run_as aaa register --project testproj --quiet >/dev/null
assert_eq "M16h: register re-discovers the relocated transcript" \
  "$(jq -r .session.artifact "$REC")" "$WTPROJ/aaa.jsonl"
strip_pid
touch -t 202601010000 "$WTPROJ/aaa.jsonl"
run_as bbb register --project testproj --quiet >/dev/null
assert_eq "M16i: genuinely stale relocated owner is adopted" "$(rec .session.session_id)" "bbb"
rm -rf "$WTPROJ"

echo "P: D8/R2.10 — the session block names a PROCESS, not only a transcript"
mkdir -p "$TMP/bin" "$TMP/fake"
ln -sf "$(command -v bash)" "$TMP/bin/claude"
ln -sf "$(command -v bash)" "$TMP/bin/copilot-vscode"
export TMP CB REC
cat > "$TMP/fake/session-loop.sh" <<'EOS'
#!/usr/bin/env bash
echo $$ > "$TMP/sup.pid"
"$TMP/bin/$FAKE_RT" -c 'echo $$ > "$TMP/rt.pid"; ps -o lstart= -p $$ | sed "s/^ *//;s/ *$//" > "$TMP/rt.start"; "$CB" register --project testproj --runtime "$FAKE_RT" --quiet >/dev/null 2>&1; :'
EOS
chmod +x "$TMP/fake/session-loop.sh"

echo "P1: ancestry walk — the block names the runtime process and its supervisor"
rm -f "$REC" "$TMP/sup.pid" "$TMP/rt.pid"
mk_transcript ppp 40000
FAKE_RT=claude CLAUDE_CODE_SESSION_ID=ppp env FAKE_RT=claude bash "$TMP/fake/session-loop.sh"
assert_eq "P1a: session.pid is the runtime process, not the hook shell" \
  "$(rec '.session.pid // "none"')" "$(cat "$TMP/rt.pid" 2>/dev/null || echo none)"
assert_eq "P1b: registry record supervisor_pid is the runtime's parent" \
  "$(jq -r '.supervisor_pid // "none"' "$SESS/claude-ppp.json" 2>/dev/null)" "$(cat "$TMP/sup.pid" 2>/dev/null || echo none)"
assert_eq "P1c: pid_start recorded beside the pid" \
  "$(rec '.session.pid_start // "none"')" "$(cat "$TMP/rt.start" 2>/dev/null || echo none)"
assert_eq "P1d: the registry record carries the same pid" \
  "$(jq -r '.pid // "none"' "$SESS/claude-ppp.json" 2>/dev/null)" "$(cat "$TMP/rt.pid" 2>/dev/null || echo none)"

echo "P5: the same process under a new session id adopts the slot (/clear)"
mk_transcript qqq 1000
cat > "$TMP/fake/clear.sh" <<'EOS'
#!/usr/bin/env bash
"$TMP/bin/claude" -c 'CLAUDE_CODE_SESSION_ID=ppp "$CB" register --project testproj --runtime claude --quiet >/dev/null 2>&1; CLAUDE_CODE_SESSION_ID=qqq "$CB" register --project testproj --runtime claude 2>"$TMP/p5.err" >/dev/null; :'
EOS
chmod +x "$TMP/fake/clear.sh"; rm -f "$REC"
bash "$TMP/fake/clear.sh"
assert_eq       "P5a: qqq adopted the slot" "$(rec .session.session_id)" "qqq"
assert_contains "P5b: reason=adopted names ppp" "$(cat "$TMP/p5.err")" "reason=adopted loser=claude-ppp"

echo "P6: an in-place restart binds through a matching launch.pending pid"
cat > "$TMP/fake/pending.sh" <<'EOS'
#!/usr/bin/env bash
"$TMP/bin/claude" -c 'st="$(ps -o lstart= -p $$ | sed "s/^ *//;s/ *$//")"
jq -n --argjson pid $$ --arg st "$st" "{schema:1, seq:8, launch:{launched_at:\"x\", pending:{pid:\$pid, pid_start:\$st, prompt:\"seed\"}}, session:null}" > "$REC"
CLAUDE_CODE_SESSION_ID=rrr "$CB" register --runtime claude 2>"$TMP/p6.err" >/dev/null; :'
EOS
chmod +x "$TMP/fake/pending.sh"
mk_transcript rrr 1000
bash "$TMP/fake/pending.sh"
assert_eq       "P6a: bound to the pending launch" "$(rec .session.session_id)" "rrr"
assert_eq       "P6b: session.seq is the record's seq" "$(rec .session.seq)" "8"
assert_eq       "P6c: launch.pending emptied" "$(rec .launch.pending)" "null"
assert_contains "P6d: bound via pending" "$(cat "$TMP/p6.err")" "via=pending"
assert_eq       "P6e: registry record carries the project" "$(jq -r .project "$SESS/claude-rrr.json")" "testproj"

echo "P2: no runtime ancestor — degrade to no pid, never to a wrong one"
rm -f "$REC"
: > "$TMP/gemini-telemetry.log"
"$CB" register --runtime gemini --project testproj --quiet >/dev/null 2>&1
assert_eq "P2a: record written" "$(rec .session.runtime)" "gemini"
assert_eq "P2b: no pid invented from the nearest ancestor" "$(rec '.session | has("pid")')" "false"
assert_eq "P2c: no supervisor invented either" "$(jq -r 'has("supervisor_pid")' "$SESS/gemini-workspace.json")" "false"

echo "P3: the walk matches argv[0], so a runtime named only in an argument is not adopted"
rm -f "$REC"
bash -c '"$CB" register --runtime gemini --project testproj --quiet >/dev/null 2>&1 # gemini
:'
assert_eq "P3a: a mention in the argv tail resolves no pid" "$(rec '.session | has("pid")')" "false"

echo "P4: copilot-vscode has no process an operator may be told to end"
rm -f "$REC" "$TMP/sup.pid" "$TMP/rt.pid"
VSCODE_TARGET_SESSION_LOG="$TMP/copilot.log"; : > "$VSCODE_TARGET_SESSION_LOG"
export VSCODE_TARGET_SESSION_LOG
env FAKE_RT=copilot-vscode bash "$TMP/fake/session-loop.sh"
if [ -f "$REC" ] && [ "$(rec .session.runtime)" = "copilot-vscode" ]; then
  assert_eq "P4a: no pid recorded for copilot-vscode" "$(rec '.session | has("pid")')" "false"
else
  ok "P4a: copilot-vscode did not register in this fixture — no pid to record either way"
fi
unset VSCODE_TARGET_SESSION_LOG
rm -f "$REC"

echo "S1: P1' — record/register name an unstaged successor under a supervisor (B1)"
rm -f "$REC"
s1_supervisor() { sup_block "$$"; }
s1_edit() { jq "$1" "$REC" > "$REC.t" && mv "$REC.t" "$REC"; }
mk_transcript s1ok   50000
mk_transcript s1warn 125000
mk_transcript s1stop 155000
s1_supervisor
err=$(run_as s1ok record --project testproj --label s1a 2>&1 >/dev/null)
assert_eq "S1a: below WARN, silent" "$err" ""
err=$(run_as s1warn record --project testproj --label s1b 2>&1 >/dev/null)
assert_contains "S1b: WARN names the unstaged successor" "$err" "successor: NOT STAGED"
assert_contains "S1b2: it gives the staging command" "$err" "launch-next-session.sh testproj --emit"
assert_contains "S1b3: it names quitting as a correct ending" "$err" "to end it:"
run_as s1warn record --project testproj --label s1c >/dev/null 2>&1; rc=$?
assert_eq "S1c: WARN still exits 1" "$rc" "1"
run_as s1stop record --project testproj --label s1c2 >/dev/null 2>&1; rc=$?
assert_eq "S1c2: STOP still exits 2" "$rc" "2"
out=$(run_as s1stop record --project testproj --label s1d 2>/dev/null)
assert_eq "S1d: stdout is still a single line" "$(printf '%s' "$out" | wc -l | tr -d ' ')" "0"
assert_contains "S1d2: stdout is the status line" "$out" "status=STOP"
s1_edit '.staged = {successor: 9, command: "claude -p next", by: "s1stop"}'
err=$(run_as s1stop record --project testproj --label s1e 2>&1 >/dev/null)
assert_eq "S1e: a staged successor (the record's staged block) silences it" "$err" ""
s1_edit '.staged = null | .chain.supervisor = null'
err=$(run_as s1stop record --project testproj --label s1f 2>&1 >/dev/null)
assert_eq "S1f: unsupervised, silent" "$err" ""
sup_block "$DEAD_PID"
err=$(run_as s1stop record --project testproj --label s1g 2>&1 >/dev/null)
assert_eq "S1g: ambiguous supervision, silent" "$err" ""
s1_supervisor
err=$(run_as s1stop record --label s1h 2>&1 >/dev/null)
assert_eq "S1h: no project, silent" "$err" ""
rm -f "$REC"
run_as s1stop register --project testproj --quiet >/dev/null 2>&1
s1_supervisor
err=$(run_as s1stop record --label s1i 2>&1 >/dev/null)
assert_contains "S1i: bare record resolves its own project" "$err" "successor: NOT STAGED"
s1_edit '.session = null'
err=$(run_as s1stop register --project testproj 2>&1 >/dev/null)
assert_contains "S1j: register speaks" "$err" "successor: NOT STAGED"
err=$(run_as s1stop record --project testproj --label s1k --quiet 2>&1 >/dev/null)
assert_eq "S1k: --quiet suppresses it" "$err" ""
err=$(run_as s1stop check --project testproj 2>&1 >/dev/null)
assert_eq "S1l: check does not speak" "$err" ""
mk_transcript s1child 155000
err=$(run_as s1stop register --transcript "$PROJ_DIR/s1child.jsonl" \
        --parent-session s1stop --project testproj 2>&1 >/dev/null)
assert_absent "S1m: a child says nothing about the chain" "$err" "successor: NOT STAGED"
rm -f "$REC"

echo "N1: --session-id — a read-only pin so check measures a NAMED session (Q3)"
CB_STATE="$TMP/.context-budget"
snap_state() {
  find "$CB_STATE" -type f 2>/dev/null | sort | while read -r f; do
    printf '%s %s %s\n' "$f" \
      "$(stat -f %m "$f" 2>/dev/null || stat -c %Y "$f" 2>/dev/null)" "$(cksum < "$f")"
  done
}
mk_transcript pin-live 155000
run_as pin-live register --quiet >/dev/null 2>&1
mk_transcript pin-asker 1000
run_as pin-asker register --quiet >/dev/null 2>&1
out=$(run_as pin-asker check --session-id pin-live); rc=$?
assert_contains "N1a: the pin measures the named session, not the caller" "$out" "tokens=155000"
assert_contains "N1b: and names the pinned session's artifact" "$out" "artifact=$PROJ_DIR/pin-live.jsonl"
assert_eq "N1c: the exit code is the pinned session's status (STOP)" "$rc" "2"
printf '{"last_token_usage":{"total_tokens":4242}}\n' > "$TMP/home/codex-pin.jsonl"
jq -n --arg af "$TMP/home/codex-pin.jsonl" \
  '{runtime:"codex", session_id:"pin-codex", artifact:$af}' \
  > "$CB_STATE/sessions/codex-pin-codex.json"
out=$(CLAUDE_CODE_SESSION_ID=pin-asker "$CB" check --session-id pin-codex)
assert_contains "N1d: runtime comes from the registry, not the caller's env" "$out" "runtime=codex"
assert_contains "N1e: and the pinned codex session is measured" "$out" "tokens=4242"
before="$(snap_state)"
run_as pin-asker check --session-id pin-live >/dev/null 2>&1
assert_eq "N1f: the pin writes nothing — no re-pin, no record, no ledger" "$(snap_state)" "$before"
err=$(run_as pin-asker check --session-id no-such-session 2>&1 >/dev/null); rc=$?
assert_eq "N1g: an unregistered id is refused, not guessed around" "$rc" "3"
assert_contains "N1h: the refusal names the id it could not find" "$err" "no-such-session"
err=$(run_as pin-asker record --session-id pin-live 2>&1 >/dev/null); rc=$?
assert_eq "N1i: record refuses the pin (it writes)" "$rc" "3"
assert_contains "N1j: and says the pin is check-only" "$err" "check"
err=$(run_as pin-asker register --session-id pin-live --quiet 2>&1 >/dev/null); rc=$?
assert_eq "N1k: register refuses the pin" "$rc" "3"
err=$(run_as pin-asker check --session-id pin-live \
        --transcript "$PROJ_DIR/pin-asker.jsonl" 2>&1 >/dev/null); rc=$?
assert_eq "N1l: --session-id with --transcript is refused" "$rc" "3"
rm -f "$CB_STATE/sessions/codex-pin-codex.json"

echo; echo "passed=$PASS failed=$FAIL"
[ "$FAIL" -eq 0 ]
