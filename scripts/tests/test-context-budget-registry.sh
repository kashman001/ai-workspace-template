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

echo "T4: release — a non-owner is refused loudly; --takeover releases (C5, D4)"
err=$(run_as aaa release --project testproj 2>&1 >/dev/null); rc=$?   # bbb holds it
assert_eq "T4a: foreign lock left in place" "$(jq -r .session_id "$LOCK")" "bbb"
assert_eq "T4a2: non-owner release exits non-zero" "$rc" "3"
assert_contains "T4a3: refusal names --takeover as the remedy" "$err" "--takeover"
run_as aaa release --project testproj --takeover --quiet >/dev/null
[ ! -f "$LOCK" ] && ok "T4a4: --takeover released a foreign lock" || bad "T4a4: --takeover no-op"

run_as bbb register --project testproj --quiet >/dev/null      # re-acquire for T4b
run_as bbb release --project testproj --quiet >/dev/null
[ ! -f "$LOCK" ] && ok "T4b: own lock released" || bad "T4b: lock still present"
run_as bbb register --project testproj --quiet >/dev/null      # project now in session file
run_as bbb release --quiet >/dev/null                          # no --project: self-derived
[ ! -f "$LOCK" ] && ok "T4c: release derives project from own session file" || bad "T4c"

echo "T4d: --takeover moves lock authority, but does NOT bypass the I4 release order"
# Lock authority moves; lock *ordering* does not (design.md 3, C5). Build the
# live child the way T8 does -- child liveness is the holder artifact's mtime
# (sweep_child_locks -> lock_holder_age), not the lock file's own timestamp.
mk_transcript agent-t4 8000
run_as bbb register --project testproj --quiet >/dev/null
run_as bbb register --transcript "$PROJ_DIR/agent-t4.jsonl" \
  --parent-session bbb --agent-id t4 --project testproj --quiet >/dev/null
T4CLOCK="$TMP/work/testproj/.agent-locks/claude-agent-t4.json"
[ -f "$T4CLOCK" ] && ok "T4d0: live child lock in place" || bad "T4d0: no child lock at $T4CLOCK"
err=$(run_as aaa release --project testproj --takeover 2>&1 >/dev/null); rc=$?
[ "$rc" -ne 0 ] && ok "T4d1: live child lock still blocks --takeover" \
  || bad "T4d1: --takeover bypassed the I4 guard (rc=$rc)"
assert_contains "T4d2: refusal names the live child" "$err" "claude-agent-t4"
[ -f "$LOCK" ] && ok "T4d3: project lock survived the refused takeover" || bad "T4d3: lock removed anyway"
run_as agent-t4 release --project testproj --quiet >/dev/null
run_as aaa release --project testproj --takeover --quiet >/dev/null
[ ! -f "$LOCK" ] && ok "T4d4: --takeover succeeds once the child is gone" || bad "T4d4: lock remains"
# Unconditional teardown -- T4d must hand T5/T6 the same empty-lock state the
# original T4 did, whether or not its own assertions passed.
rm -f "$LOCK"; rm -rf "$TMP/work/testproj/.agent-locks"
rm -f "$TMP/.context-budget/sessions/claude-agent-t4.json" "$PROJ_DIR/agent-t4.jsonl"

echo "T4e: takeover-release stamps the dispossessed holder superseded (A7)"
SESSD="$TMP/.context-budget/sessions"
mk_transcript aaa 50000; mk_transcript bbb 90000                # both live
run_as bbb register --project testproj --quiet >/dev/null       # bbb = live holder
run_as aaa release --project testproj --takeover --quiet >/dev/null
[ ! -f "$LOCK" ] && ok "T4e0: takeover-release removed the lock" || bad "T4e0: lock remains"
# Mutation red (T4e1-T4e3): drop the holder-record stamp from cmd_release's
# takeover branch — the registry keeps bbb as a primary with no lock behind it
# (the asymmetry vs the acquisition-side steal that A7 closes).
assert_eq "T4e1: dispossessed holder stamped role=superseded" \
  "$(jq -r '.role // "none"' "$SESSD/claude-bbb.json")" "superseded"
assert_eq "T4e2: superseded_by names the taking-over session" \
  "$(jq -r '.superseded_by // "none"' "$SESSD/claude-bbb.json")" "claude-aaa"
[ -n "$(jq -r '.superseded_at // empty' "$SESSD/claude-bbb.json")" ] \
  && ok "T4e3: superseded_at stamped" || bad "T4e3: no superseded_at"

echo "T4f: non-owner refusal names the holder's liveness (A7)"
mk_transcript aaa 50000; mk_transcript bbb 90000
run_as bbb register --project testproj --quiet >/dev/null       # bbb = live holder
err=$(run_as aaa release --project testproj 2>&1 >/dev/null); rc=$?
assert_eq "T4f0: non-owner refusal still exits 3" "$rc" "3"
# Mutation red (T4f1, T4f3): revert the die message to the single pre-A7
# wording — neither the live nor the stale marker text appears.
assert_contains "T4f1: live holder called out as live" "$err" "holder is live"
assert_contains "T4f2: live refusal still names --takeover" "$err" "--takeover"
touch -t 202601010000 "$PROJ_DIR/bbb.jsonl"                     # holder now stale
err=$(run_as aaa release --project testproj 2>&1 >/dev/null); rc=$?
assert_eq "T4f3a: stale-holder refusal still exits 3" "$rc" "3"
assert_contains "T4f3: stale holder called out as stale" "$err" "stale"
assert_contains "T4f4: stale refusal still names --takeover" "$err" "--takeover"
run_as aaa release --project testproj --takeover --quiet >/dev/null   # teardown

echo "T4g: takeover-release when the holder's record was already purged (A7 follow-on b)"
mk_transcript aaa 50000; mk_transcript bbb 90000
run_as bbb register --project testproj --quiet >/dev/null       # bbb = live holder
rm -f "$SESSD/claude-bbb.json"                                  # record purged out-of-band
out=$(run_as aaa release --project testproj --takeover 2>&1)
# Mutation red (T4g0): abort the takeover when the stamp cannot land — the
# stamp is bookkeeping; the release must proceed either way.
[ ! -f "$LOCK" ] && ok "T4g0: takeover-release still removed the lock" \
  || bad "T4g0: lock remains"
# Mutation red (T4g1, T4g2): revert the note to the unconditional
# "holder stamped superseded" wording.
assert_contains "T4g1: note says the holder record was absent" "$out" "holder record absent"
case "$out" in *"stamped superseded"*) bad "T4g2: note claims a stamp that never landed" ;;
               *) ok "T4g2: no stamped-superseded claim without a stamp" ;; esac
# Mutation red (T4g3): stamp unconditionally (drop the [ -f ] guard) AND drop
# the rm -f cleanup — jq on the missing record strands the .tmp.
[ ! -e "$SESSD/claude-bbb.json.tmp" ] && ok "T4g3: no stranded .tmp" \
  || bad "T4g3: stranded $SESSD/claude-bbb.json.tmp"

echo "T4h: takeover-release when the holder's record cannot be stamped (A7 follow-on b)"
mk_transcript aaa 50000; mk_transcript bbb 90000
run_as bbb register --project testproj --quiet >/dev/null       # bbb = live holder
printf 'not-json{' > "$SESSD/claude-bbb.json"                   # jq-unparseable record
out=$(run_as aaa release --project testproj --takeover 2>&1)
# Mutation red (T4h0): abort the takeover when the stamp fails.
[ ! -f "$LOCK" ] && ok "T4h0: takeover-release still removed the lock" \
  || bad "T4h0: lock remains"
# Mutation red (T4h1): drop the rm -f of the stranded tmp.
[ ! -e "$SESSD/claude-bbb.json.tmp" ] && ok "T4h1: stranded .tmp removed" \
  || bad "T4h1: stranded $SESSD/claude-bbb.json.tmp"
# Mutation red (T4h2, T4h3): revert the note to the unconditional wording.
assert_contains "T4h2: note says the stamp failed" "$out" "failed to stamp"
case "$out" in *"stamped superseded"*) bad "T4h3: note claims a stamp that never landed" ;;
               *) ok "T4h3: no stamped-superseded claim without a stamp" ;; esac

echo "T4i: acquisition takeover when the stamp cannot be written (A7 follow-on b)"
# The acquisition takeover branch is gated on lock_holder_age, which reads the
# same record file — an absent/corrupt record routes to the stale-reclaim
# branch instead, so only the write-failure defect is directly drivable here:
# block the .tmp redirect target to fail the stamp without touching the record.
mk_transcript aaa 50000; mk_transcript bbb 90000
run_as aaa register --project testproj --quiet >/dev/null       # aaa = live holder
mkdir -p "$SESSD/claude-aaa.json.tmp"                           # stamp write must fail
out=$(run_as bbb register --project testproj --takeover 2>&1)
# Mutation red (T4i0): abort the takeover when the stamp fails.
assert_eq "T4i0: takeover still moved the lock" "$(jq -r .session_id "$LOCK")" "bbb"
# Mutation red (T4i1, T4i2): revert the note to the unconditional
# "old holder stamped superseded" wording.
assert_contains "T4i1: note says the stamp failed" "$out" "failed to stamp"
case "$out" in *"stamped superseded"*) bad "T4i2: note claims a stamp that never landed" ;;
               *) ok "T4i2: no stamped-superseded claim without a stamp" ;; esac
rm -rf "$SESSD/claude-aaa.json.tmp"                             # fixture teardown
run_as bbb release --project testproj --quiet >/dev/null        # bbb owns it now

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
mkdir -p "$GW/scripts" "$GW/work/testproj"
cp "$SRC_ROOT/scripts/context-budget.sh" "$GW/scripts/"
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

echo "T20: supervised — on-disk supervision query (C1)"
# Hermetic: the query consults TF_SESSION_LOOP_PROJECT, so a supervised
# *test runner* would otherwise leak into T20a/T20e.
unset TF_SESSION_LOOP_PROJECT
LOOPF="$TMP/work/testproj/.session-loop"
rm -f "$LOOPF"

# T20a: no marker, no env => unsupervised, exit 1
out=$(run_as aaa supervised --project testproj 2>/dev/null); rc=$?
assert_eq "T20a: unsupervised line" "$out" "unsupervised"
assert_eq "T20a: unsupervised rc"   "$rc"  "1"

# T20b: marker with a live pid => supervised, exit 0
jq -n --argjson pid "$$" --arg project testproj --arg started_at "2026-01-01T00:00:00Z" \
  '{pid:$pid, project:$project, started_at:$started_at}' > "$LOOPF"
out=$(run_as aaa supervised --project testproj 2>/dev/null); rc=$?
assert_eq "T20b: supervised rc" "$rc" "0"
case "$out" in "supervised pid=$$ project=testproj started_at="*) ok "T20b: supervised line" ;;
               *) bad "T20b: supervised line was: $out" ;; esac

# T20c: marker with a dead pid => ambiguous, exit 2 (never deleted)
sleep 0 & deadpid=$!; wait "$deadpid" 2>/dev/null
jq -n --argjson pid "$deadpid" --arg project testproj --arg started_at "2026-01-01T00:00:00Z" \
  '{pid:$pid, project:$project, started_at:$started_at}' > "$LOOPF"
out=$(run_as aaa supervised --project testproj 2>/dev/null); rc=$?
assert_eq "T20c: ambiguous rc" "$rc" "2"
case "$out" in ambiguous*) ok "T20c: ambiguous line" ;; *) bad "T20c: line was: $out" ;; esac
[ -f "$LOOPF" ] && ok "T20c: stale marker NOT deleted" || bad "T20c: marker was deleted"
rm -f "$LOOPF"

# T20d: no marker but TF_SESSION_LOOP_PROJECT names us => ambiguous, exit 2
out=$(TF_SESSION_LOOP_PROJECT=testproj run_as aaa supervised --project testproj 2>/dev/null); rc=$?
assert_eq "T20d: env-only ambiguous rc" "$rc" "2"

# T20e: --quiet prints nothing, exit code unchanged
out=$(run_as aaa supervised --project testproj --quiet 2>/dev/null); rc=$?
assert_eq "T20e: quiet is silent" "$out" ""
assert_eq "T20e: quiet rc"        "$rc"  "1"

# T20f: --project is required
run_as aaa supervised >/dev/null 2>&1; rc=$?
assert_eq "T20f: missing --project errors" "$rc" "3"

echo "R9: record refreshes the session record's mtime (7-day purge liveness)"
mk_transcript aaa 50000
run_as aaa register --quiet >/dev/null
touch -t 202001010000 "$SESS/claude-aaa.json"      # back-date: looks >7 days dead
run_as aaa record --label "r9-liveness" --quiet >/dev/null 2>&1
# Mutation red: drop the session-record `touch` from cmd_record — the record
# keeps its 2020 mtime, so register's `-mtime +7` purge would collect a live,
# record-ing session's record.
mt=$(stat -f%m "$SESS/claude-aaa.json" 2>/dev/null || stat -c%Y "$SESS/claude-aaa.json" 2>/dev/null)
age=$(( $(date +%s) - mt ))
[ "$age" -lt 600 ] && ok "R9a: record refreshed session record mtime (age=${age}s)" \
  || bad "R9a: session record mtime not refreshed by record (age=${age}s)"

echo; echo "passed=$PASS failed=$FAIL"
[ "$FAIL" -eq 0 ]
