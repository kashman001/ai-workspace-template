#!/usr/bin/env bash
# File: scripts/tests/test-context-budget-registry.sh
# Purpose: Regression tests for the session-keyed registry + per-project lock
#          in context-budget.sh (backlog M13 / ADR-0004). Self-contained:
#          builds a throwaway workspace + fake $HOME in mktemp -d.
set -u
SRC_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/scripts" "$TMP/work/testproj" "$TMP/home"
cp "$SRC_ROOT/scripts/context-budget.sh" "$TMP/scripts/"
printf 'CONTEXT_DUMB_ZONE_TOKENS=150000\nCONTEXT_DUMB_ZONE_WARN_TOKENS=120000\n' \
  > "$TMP/context-budget.env"
export HOME="$TMP/home"
cd "$TMP"
CB="$TMP/scripts/context-budget.sh"
SLUG="$(pwd | tr '/.' '--')"
PROJ_DIR="$HOME/.claude/projects/$SLUG"; mkdir -p "$PROJ_DIR"

PASS=0; FAIL=0
ok()   { PASS=$((PASS+1)); echo "  ok: $1"; }
bad()  { FAIL=$((FAIL+1)); echo "  FAIL: $1" >&2; }
assert_eq() { [ "$2" = "$3" ] && ok "$1" || bad "$1 (want [$3] got [$2])"; }
assert_contains() { case "$2" in *"$3"*) ok "$1" ;; *) bad "$1 (no [$3] in [$2])" ;; esac; }

mk_transcript() {  # $1=session-id $2=input-tokens
  jq -cn --argjson t "$2" \
    '{message:{usage:{input_tokens:$t,cache_read_input_tokens:0,cache_creation_input_tokens:0}},isSidechain:false}' \
    > "$PROJ_DIR/$1.jsonl"
}
run_as() {  # $1=claude-session-id, rest = context-budget.sh args
  local sid="$1"; shift
  CLAUDE_CODE_SESSION_ID="$sid" "$CB" "$@" --runtime claude
}

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

echo "T2: register --project acquires the lock; a live holder is not stolen"
LOCK="$TMP/work/testproj/.active-session"
mk_transcript aaa 50000; mk_transcript bbb 90000; touch "$PROJ_DIR/aaa.jsonl"
run_as aaa register --project testproj --quiet >/dev/null
assert_eq "T2a: lock holder is aaa" "$(jq -r .session_id "$LOCK" 2>/dev/null)" "aaa"
err=$(run_as bbb register --project testproj 2>&1 >/dev/null)
assert_eq "T2b: live lock not stolen" "$(jq -r .session_id "$LOCK")" "aaa"
assert_contains "T2c: holder warning emitted" "$err" "held by claude-aaa"

echo "T3: stale lock (holder artifact untouched for hours) is reclaimed"
touch -t 202601010000 "$PROJ_DIR/aaa.jsonl"
run_as bbb register --project testproj --quiet >/dev/null
assert_eq "T3a: stale lock reclaimed by bbb" "$(jq -r .session_id "$LOCK")" "bbb"

echo "T4: release removes own lock, never another session's"
err=$(run_as aaa release --project testproj 2>&1 >/dev/null)   # bbb holds it
assert_eq "T4a: foreign lock left in place" "$(jq -r .session_id "$LOCK")" "bbb"
run_as bbb release --project testproj --quiet >/dev/null
[ ! -f "$LOCK" ] && ok "T4b: own lock released" || bad "T4b: lock still present"
run_as bbb register --project testproj --quiet >/dev/null      # project now in session file
run_as bbb release --quiet >/dev/null                          # no --project: self-derived
[ ! -f "$LOCK" ] && ok "T4c: release derives project from own session file" || bad "T4c"

echo "T5: gemini register — fresh telemetry log means a concurrent session owns it"
mkdir -p "$TMP/.gemini" "$HOME/.gemini/tmp/h0"
printf '{"note":"chat log"}' > "$HOME/.gemini/tmp/h0/logs.json"
printf '{"gen_ai.usage.input_tokens": 42}\n' > "$TMP/.gemini/telemetry.log"   # fresh + non-empty
"$CB" register --runtime gemini --quiet >/dev/null 2>&1
[ -s "$TMP/.gemini/telemetry.log" ] && ok "T5a: fresh telemetry log NOT reset" || bad "T5a: log was reset"
assert_contains "T5b: registered estimate artifact instead" \
  "$(jq -r .artifact "$TMP/.context-budget/sessions/gemini-workspace.json")" "logs.json"
touch -t 202601010000 "$TMP/.gemini/telemetry.log"                            # now stale
"$CB" register --runtime gemini --quiet >/dev/null 2>&1
[ ! -s "$TMP/.gemini/telemetry.log" ] && ok "T5c: stale telemetry log reset" || bad "T5c: not reset"

echo "T6: session roles — primary on acquire, auxiliary alongside a live primary"
touch "$PROJ_DIR/aaa.jsonl" "$PROJ_DIR/bbb.jsonl"
out=$(run_as aaa register --project testproj 2>&1)
assert_contains "T6a: register reports role=primary" "$out" "role=primary"
assert_eq "T6b: primary role recorded" \
  "$(jq -r .role "$TMP/.context-budget/sessions/claude-aaa.json")" "primary"
out=$(run_as bbb register --project testproj 2>&1)
assert_contains "T6c: register reports role=auxiliary" "$out" "role=auxiliary"
assert_eq "T6d: auxiliary role recorded" \
  "$(jq -r .role "$TMP/.context-budget/sessions/claude-bbb.json")" "auxiliary"
assert_eq "T6e: lock still held by primary" "$(jq -r .session_id "$LOCK")" "aaa"
run_as bbb register --quiet >/dev/null
assert_eq "T6f: no project -> no role" \
  "$(jq -r '.role // "none"' "$TMP/.context-budget/sessions/claude-bbb.json")" "none"

echo "T7: child registration — parent-side, artifact-keyed, parent/depth recorded"
rm -f "$TMP/work/testproj/.active-session"
mk_transcript aaa 50000
run_as aaa register --project testproj --quiet >/dev/null      # parent, primary
mk_transcript agent-c1 12000
out=$(run_as aaa register --transcript "$PROJ_DIR/agent-c1.jsonl" \
  --parent-session aaa --agent-id c1 --project testproj 2>&1)
REC_C1="$TMP/.context-budget/sessions/claude-agent-c1.json"
[ -f "$REC_C1" ] && ok "T7a: record keyed by artifact id, not env sid" \
  || bad "T7a: no record at claude-agent-c1.json"
assert_eq "T7b: parent_session_id recorded" \
  "$(jq -r '.parent_session_id // "none"' "$REC_C1" 2>/dev/null)" "aaa"
assert_eq "T7c: depth = parent depth + 1" \
  "$(jq -r '.depth // "none"' "$REC_C1" 2>/dev/null)" "1"
assert_eq "T7d: agent_id recorded" \
  "$(jq -r '.agent_id // "none"' "$REC_C1" 2>/dev/null)" "c1"
err=$(run_as aaa register --transcript "$PROJ_DIR/agent-c1.jsonl" \
  --parent-session ghost --project testproj 2>&1 >/dev/null); rc=$?
[ "$rc" -eq 3 ] && ok "T7e: unregistered parent session dies" \
  || bad "T7e: rc=$rc for unregistered parent (want 3)"

echo "T8: per-child lock under a lock-holding parent; project lock untouched"
CLOCK="$TMP/work/testproj/.agent-locks/claude-agent-c1.json"
out=$(run_as aaa register --transcript "$PROJ_DIR/agent-c1.jsonl" \
  --parent-session aaa --agent-id c1 --project testproj 2>&1)
assert_contains "T8a: register reports role=child" "$out" "role=child"
[ -f "$CLOCK" ] && ok "T8b: child lock file created" || bad "T8b: no child lock at $CLOCK"
assert_eq "T8c: child lock carries parent pointer" \
  "$(jq -r '.parent_session_id // "none"' "$CLOCK" 2>/dev/null)" "aaa"
assert_eq "T8d: project lock still held by parent" "$(jq -r .session_id "$LOCK")" "aaa"
assert_eq "T8e: role=child recorded" \
  "$(jq -r '.role // "none"' "$TMP/.context-budget/sessions/claude-agent-c1.json")" "child"

echo "T9: child lock refused when the named parent does not hold the project lock"
mk_transcript agent-c2 9000
err=$(run_as bbb register --transcript "$PROJ_DIR/agent-c2.jsonl" \
  --parent-session bbb --project testproj 2>&1 >/dev/null)   # bbb is not the holder
[ ! -f "$TMP/work/testproj/.agent-locks/claude-agent-c2.json" ] \
  && ok "T9a: no child lock created" || bad "T9a: child lock created under non-holder"
assert_contains "T9b: loud refusal names the reason" "$err" "does not hold"
assert_eq "T9c: child degraded to auxiliary" \
  "$(jq -r '.role // "none"' "$TMP/.context-budget/sessions/claude-agent-c2.json")" "auxiliary"

echo "T10: release order — parent refused while a child lock is live (I4)"
err=$(run_as aaa release --project testproj 2>&1 >/dev/null); rc=$?
[ "$rc" -eq 3 ] && ok "T10a: parent release refused (exit 3)" || bad "T10a: rc=$rc (want 3)"
assert_eq "T10b: project lock still held" "$(jq -r .session_id "$LOCK")" "aaa"
assert_contains "T10c: refusal names the live child" "$err" "claude-agent-c1"
run_as agent-c1 release --project testproj --quiet >/dev/null
[ ! -f "$CLOCK" ] && ok "T10d: child released its own lock" || bad "T10d: child lock remains"
assert_eq "T10e: child release left project lock alone" "$(jq -r .session_id "$LOCK")" "aaa"
run_as aaa release --project testproj --quiet >/dev/null
[ ! -f "$LOCK" ] && ok "T10f: parent release succeeds at zero child locks" || bad "T10f"

echo "T11: stale child locks are swept at release, not counted as blockers"
run_as aaa register --project testproj --quiet >/dev/null
run_as aaa register --transcript "$PROJ_DIR/agent-c1.jsonl" \
  --parent-session aaa --project testproj --quiet >/dev/null
touch -t 202601010000 "$PROJ_DIR/agent-c1.jsonl"               # child artifact stale
err=$(run_as aaa release --project testproj 2>&1 >/dev/null); rc=$?
[ "$rc" -eq 0 ] && ok "T11a: release proceeds past stale child" || bad "T11a: rc=$rc"
[ ! -f "$CLOCK" ] && ok "T11b: stale child lock swept" || bad "T11b: stale child lock remains"
[ ! -f "$LOCK" ] && ok "T11c: project lock released" || bad "T11c: project lock remains"

echo "T12: depth 2 — grandchild chains through the child; release order enforced"
mk_transcript agent-c1 12000                                    # fresh again
run_as aaa register --project testproj --quiet >/dev/null
run_as aaa register --transcript "$PROJ_DIR/agent-c1.jsonl" \
  --parent-session aaa --project testproj --quiet >/dev/null
mk_transcript agent-g1 5000
out=$(run_as aaa register --transcript "$PROJ_DIR/agent-g1.jsonl" \
  --parent-session agent-c1 --project testproj 2>&1)
assert_contains "T12a: grandchild granted role=child" "$out" "role=child"
assert_eq "T12b: grandchild depth=2" \
  "$(jq -r '.depth // "none"' "$TMP/.context-budget/sessions/claude-agent-g1.json")" "2"
err=$(run_as agent-c1 release --project testproj 2>&1 >/dev/null); rc=$?
[ "$rc" -eq 3 ] && ok "T12c: child refused release while grandchild live" \
  || bad "T12c: rc=$rc (want 3)"
run_as agent-g1 release --project testproj --quiet >/dev/null
run_as agent-c1 release --project testproj --quiet >/dev/null
run_as aaa release --project testproj --quiet >/dev/null
[ ! -f "$LOCK" ] && [ -z "$(ls "$TMP/work/testproj/.agent-locks" 2>/dev/null)" ] \
  && ok "T12d: full tree released bottom-up" || bad "T12d: locks remain"

echo "T13: superseded_by back-stamped on successor primary registration"
SESS="$TMP/.context-budget/sessions"
mk_transcript aaa 50000; mk_transcript bbb 90000; mk_transcript ccc 20000
run_as aaa register --project testproj --quiet >/dev/null
run_as aaa release --project testproj --quiet >/dev/null
jq '.role="superseded" | .superseded_at="2026-08-06T01:00:00Z"' \
  "$SESS/claude-aaa.json" > "$SESS/tmp.json" && mv "$SESS/tmp.json" "$SESS/claude-aaa.json"
run_as bbb register --project testproj --quiet >/dev/null
assert_eq "T13a: successor stamps predecessor superseded_by" \
  "$(jq -r '.superseded_by // "none"' "$SESS/claude-aaa.json")" "claude-bbb"
jq '.role="superseded" | .superseded_at="2026-08-06T02:00:00Z"' \
  "$SESS/claude-bbb.json" > "$SESS/tmp.json" && mv "$SESS/tmp.json" "$SESS/claude-bbb.json"
rm -f "$TMP/work/testproj/.active-session"
run_as ccc register --project testproj --quiet >/dev/null
assert_eq "T13b: only the unstamped predecessor gets the new stamp" \
  "$(jq -r '.superseded_by // "none"' "$SESS/claude-bbb.json")" "claude-ccc"
assert_eq "T13c: an already-stamped record is not overwritten" \
  "$(jq -r '.superseded_by // "none"' "$SESS/claude-aaa.json")" "claude-bbb"
run_as ccc release --project testproj --quiet >/dev/null

echo "T14: --takeover — explicit recorded steal from a live holder"
mk_transcript aaa 50000; mk_transcript bbb 90000                # both live again
run_as aaa register --project testproj --quiet >/dev/null
out=$(run_as bbb register --project testproj --takeover 2>&1)
assert_eq "T14a: lock moved to bbb" "$(jq -r .session_id "$LOCK")" "bbb"
assert_contains "T14b: register reports role=primary" "$out" "role=primary"
assert_contains "T14c: loud takeover note" "$out" "takeover"
assert_eq "T14d: old holder stamped superseded" \
  "$(jq -r '.role // "none"' "$SESS/claude-aaa.json")" "superseded"
assert_eq "T14e: old holder stamped superseded_by" \
  "$(jq -r '.superseded_by // "none"' "$SESS/claude-aaa.json")" "claude-bbb"
[ -n "$(jq -r '.superseded_at // empty' "$SESS/claude-aaa.json")" ] \
  && ok "T14f: superseded_at stamped" || bad "T14f: no superseded_at"
run_as bbb release --project testproj --quiet >/dev/null

echo "T15: register-time sweep of stale primary records (registry hygiene)"
mk_transcript prim1 10000; mk_transcript aux1 9000; mk_transcript live1 12000
mk_transcript prim2 11000; mk_transcript new1 20000; mk_transcript aux2 8000
run_as prim1 register --project testproj --quiet >/dev/null   # primary; will go stale
run_as aux1 register --project testproj --quiet >/dev/null    # auxiliary alongside prim1
rm -f "$LOCK"                                                 # lock lost out-of-band
run_as live1 register --project testproj --quiet >/dev/null   # primary; stays live
rm -f "$LOCK"                                                 # lock lost out-of-band again
mkdir -p "$TMP/work/otherproj"
run_as prim2 register --project otherproj --quiet >/dev/null  # other project's primary
rm -f "$TMP/work/otherproj/.active-session"
touch -t 202601010000 "$PROJ_DIR/prim1.jsonl" "$PROJ_DIR/aux1.jsonl" "$PROJ_DIR/prim2.jsonl"
out=$(run_as new1 register --project testproj 2>&1)
assert_contains "T15a: sweep noted loudly" "$out" "swept stale primary"
assert_eq "T15b: stale primary stamped superseded" \
  "$(jq -r '.role // "none"' "$SESS/claude-prim1.json")" "superseded"
assert_eq "T15c: stale primary stamped superseded_by=new primary" \
  "$(jq -r '.superseded_by // "none"' "$SESS/claude-prim1.json")" "claude-new1"
[ -n "$(jq -r '.superseded_at // empty' "$SESS/claude-prim1.json")" ] \
  && ok "T15d: superseded_at stamped" || bad "T15d: no superseded_at"
assert_eq "T15e: live primary record left alone" \
  "$(jq -r '.role // "none"' "$SESS/claude-live1.json")" "primary"
assert_eq "T15f: other project's stale primary left alone" \
  "$(jq -r '.role // "none"' "$SESS/claude-prim2.json")" "primary"
assert_eq "T15g: stale auxiliary record left alone" \
  "$(jq -r '.role // "none"' "$SESS/claude-aux1.json")" "auxiliary"
touch -t 202601010000 "$PROJ_DIR/live1.jsonl"                 # now a stale primary too
run_as aux2 register --project testproj --quiet >/dev/null    # auxiliary: must NOT sweep
assert_eq "T15h: auxiliary registration does not sweep" \
  "$(jq -r '.role // "none"' "$SESS/claude-live1.json")" "primary"
run_as new1 release --project testproj --quiet >/dev/null

echo "G1: register from a git worktree lands lock/record in the shared root"
GW="$(mktemp -d)"; GW="$(cd "$GW" && pwd -P)"
trap 'rm -rf "$TMP" "$GW"' EXIT
mkdir -p "$GW/scripts" "$GW/work/testproj" "$GW/work/context-decay"
cp "$SRC_ROOT/scripts/context-budget.sh" "$GW/scripts/"
printf 'CONTEXT_DUMB_ZONE_TOKENS=150000\nCONTEXT_DUMB_ZONE_WARN_TOKENS=120000\n' \
  > "$GW/context-budget.env"
touch "$GW/work/testproj/.gitkeep" "$GW/work/context-decay/.gitkeep"
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
assert_eq "G1a: lock lands in main-root work/testproj" \
  "$(jq -r '.session_id // "none"' "$GW/work/testproj/.active-session" 2>/dev/null)" "ggg"
[ ! -e "$GW/wt/work/testproj/.active-session" ] \
  && ok "G1b: no lock in the worktree's own checkout" \
  || bad "G1b: lock written under the worktree"
[ -f "$GW/.context-budget/sessions/claude-ggg.json" ] \
  && ok "G1c: session record in main-root state dir" \
  || bad "G1c: no record in main-root .context-budget"
[ ! -d "$GW/wt/.context-budget" ] \
  && ok "G1d: no state dir created in the worktree" \
  || bad "G1d: worktree grew its own .context-budget"

echo "G2: record from the worktree appends to the main-root ledger"
CLAUDE_CODE_SESSION_ID=ggg "$GW/wt/scripts/context-budget.sh" \
  record --label "wt-unit" --runtime claude --quiet >/dev/null 2>&1
grep -q "wt-unit" "$GW/work/context-decay/context-ledger.jsonl" 2>/dev/null \
  && ok "G2a: ledger line in main root" || bad "G2a: no main-root ledger line"
[ ! -e "$GW/wt/work/context-decay/context-ledger.jsonl" ] \
  && ok "G2b: no ledger in the worktree" || bad "G2b: worktree ledger written"
CLAUDE_CODE_SESSION_ID=ggg "$GW/wt/scripts/context-budget.sh" \
  release --project testproj --runtime claude --quiet >/dev/null 2>&1
cd "$TMP"

echo "T16: explicit env override beats context-budget.env (L18)"
printf 'CONTEXT_LOCK_STALE_SECS=10800\n' >> "$TMP/context-budget.env"
rm -f "$LOCK"
mk_transcript aaa 50000; mk_transcript bbb 90000
run_as aaa register --project testproj --quiet >/dev/null
touch -t 202601010000 "$PROJ_DIR/aaa.jsonl"   # hours-stale under the env file's 10800
CONTEXT_LOCK_STALE_SECS=999999999 CLAUDE_CODE_SESSION_ID=bbb \
  "$CB" register --project testproj --runtime claude --quiet >/dev/null 2>&1
assert_eq "T16a: huge explicit stale-secs keeps holder live — lock not stolen" \
  "$(jq -r .session_id "$LOCK")" "aaa"

echo; echo "passed=$PASS failed=$FAIL"
[ "$FAIL" -eq 0 ]
