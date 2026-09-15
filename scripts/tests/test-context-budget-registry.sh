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

echo "M16: relocated transcript (EnterWorktree) — re-pin + liveness survive"
# EnterWorktree moves a claude transcript to the worktree's project slug dir
# mid-session; the session id (basename) is stable across the move.
WTPROJ="$HOME/.claude/projects/wt-slug--claude-worktrees-m16"
mkdir -p "$WTPROJ"
rm -f "$LOCK"

# Self-side: record after the move binds the moved transcript and re-pins.
# Mutation red (M16a-b): drop the id-keyed glob — record falls back to a
# newest-mtime sibling in the old slug dir and the record keeps the dead path.
mk_transcript aaa 50000
run_as aaa register --quiet >/dev/null
mv "$PROJ_DIR/aaa.jsonl" "$WTPROJ/aaa.jsonl"
out=$(run_as aaa record --label m16-a 2>/dev/null)
assert_contains "M16a: record binds the moved transcript" "$out" "artifact=$WTPROJ/aaa.jsonl"
assert_eq "M16b: registry record re-pinned to the new path" \
  "$(jq -r .artifact "$SESS/claude-aaa.json")" "$WTPROJ/aaa.jsonl"

# Self-side: a stale copy left behind at the old pinned path must not win —
# the freshest id-keyed match does.
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

# Other-side liveness: the two live wrongful-takeover incidents — a holder
# whose pinned path went stale after relocation must still read as live.
rm -f "$LOCK" "$WTPROJ/aaa.jsonl"
mk_transcript aaa 50000; mk_transcript bbb 90000
run_as aaa register --project testproj --quiet >/dev/null   # aaa primary, pinned old path
mv "$PROJ_DIR/aaa.jsonl" "$WTPROJ/aaa.jsonl"                # relocated; still fresh
err=$(run_as bbb register --project testproj 2>&1 >/dev/null)
assert_eq "M16e: relocated live holder keeps the lock" "$(jq -r .session_id "$LOCK")" "aaa"
assert_contains "M16f: challenger degrades to auxiliary" "$err" "role=auxiliary"

# Sweep: a relocated live primary must not be stamped superseded.
rm -f "$LOCK"                                               # lock lost out-of-band
mk_transcript ccc 20000
run_as ccc register --project testproj --quiet >/dev/null
assert_eq "M16g: relocated live primary not swept" \
  "$(jq -r '.role // "none"' "$SESS/claude-aaa.json")" "primary"

# Register-side discovery also resolves by id across slugs (no sibling bind).
rm -f "$LOCK"
run_as aaa register --project testproj --quiet >/dev/null
assert_eq "M16h: register re-discovers the relocated transcript" \
  "$(jq -r .artifact "$SESS/claude-aaa.json")" "$WTPROJ/aaa.jsonl"

# Staleness detection must survive the fix: relocated AND idle is still stale.
touch -t 202601010000 "$WTPROJ/aaa.jsonl"
run_as bbb register --project testproj --quiet >/dev/null
assert_eq "M16i: genuinely stale relocated holder still reclaimed" \
  "$(jq -r .session_id "$LOCK")" "bbb"
run_as bbb release --project testproj --quiet >/dev/null
rm -rf "$WTPROJ"

echo "P: D8/R2.10 — the lock and the session record name a PROCESS, not only a transcript"
# What these pin: register must resolve the runtime pid by walking its ANCESTRY
# (its own parent is a throwaway hook shell, so $PPID is wrong), must record the
# process start time alongside the pid (pids are recycled; the record outlives
# the process), and must pick up the supervisor for free from the runtime's
# parent. Mutations that make these red: P1 — replace the walk with $PPID (P1a
# names the wrapper shell, not claude); P2 — record the pid without pid_start;
# P3 — match the runtime name anywhere in the command line instead of at argv0;
# P4 — drop the "no resolvable ancestor" degradation and record a wrong pid.
#
# The fixture needs a process whose argv[0] basename really is the runtime name.
# A #! script cannot do it (the kernel puts the interpreter in argv[0]), so the
# fake runtime is a symlink to bash: exec'ing it sets argv[0] to the link path.
mkdir -p "$TMP/bin" "$TMP/fake"
ln -sf "$(command -v bash)" "$TMP/bin/claude"
ln -sf "$(command -v bash)" "$TMP/bin/copilot-vscode"
export TMP CB
# The `; :` is load-bearing: bash -c 'single simple command' execs in place,
# which would replace the fake runtime process with the one being measured.
cat > "$TMP/fake/session-loop.sh" <<'EOS'
#!/usr/bin/env bash
echo $$ > "$TMP/sup.pid"
"$TMP/bin/$FAKE_RT" -c 'echo $$ > "$TMP/rt.pid"; "$CB" register --project testproj --runtime "$FAKE_RT" --quiet >/dev/null 2>&1; :'
EOS
chmod +x "$TMP/fake/session-loop.sh"

echo "P1: ancestry walk — the lock names the runtime process and its supervisor"
rm -f "$LOCK" "$TMP/sup.pid" "$TMP/rt.pid"
mk_transcript ppp 40000
FAKE_RT=claude CLAUDE_CODE_SESSION_ID=ppp \
  env FAKE_RT=claude bash "$TMP/fake/session-loop.sh"
assert_eq "P1a: lock pid is the runtime process, not the hook shell" \
  "$(jq -r '.pid // "none"' "$LOCK" 2>/dev/null)" "$(cat "$TMP/rt.pid" 2>/dev/null || echo none)"
assert_eq "P1b: lock supervisor_pid is the runtime's parent" \
  "$(jq -r '.supervisor_pid // "none"' "$LOCK" 2>/dev/null)" "$(cat "$TMP/sup.pid" 2>/dev/null || echo none)"
[ -n "$(jq -r '.pid_start // empty' "$LOCK" 2>/dev/null)" ] \
  && ok "P1c: pid_start recorded beside the pid" \
  || bad "P1c: pid without pid_start — a recycled pid would be named with confidence"
assert_eq "P1d: the session record carries the same pid" \
  "$(jq -r '.pid // "none"' "$TMP/.context-budget/sessions/claude-ppp.json" 2>/dev/null)" \
  "$(cat "$TMP/rt.pid" 2>/dev/null || echo none)"

echo "P2: no runtime ancestor — degrade to no pid, never to a wrong one"
# Uses gemini deliberately. This suite is itself normally run from inside a
# claude session, so a claude ancestor is genuinely present in the test's own
# process tree and a runtime=claude fixture could never show the degradation.
# Picking a runtime that is NOT in the ancestry is the only hermetic way to
# reach the "walk found nothing" branch.
rm -f "$LOCK"
: > "$TMP/gemini-telemetry.log"
"$CB" register --runtime gemini --project testproj --quiet >/dev/null 2>&1
assert_eq "P2a: lock written" "$(jq -r '.runtime' "$LOCK" 2>/dev/null)" "gemini"
assert_eq "P2b: no pid invented from the nearest ancestor" \
  "$(jq -r 'has("pid")' "$LOCK")" "false"
assert_eq "P2c: no supervisor invented either" \
  "$(jq -r 'has("supervisor_pid")' "$LOCK")" "false"

echo "P3: the walk matches argv[0], so a runtime named only in an argument is not adopted"
rm -f "$LOCK"
# The wrapper shell's command line contains the word gemini; its argv[0] is bash.
bash -c '"$CB" register --runtime gemini --project testproj --quiet >/dev/null 2>&1 # gemini
:'
assert_eq "P3a: a mention in the argv tail resolves no pid" \
  "$(jq -r 'has("pid")' "$LOCK")" "false"

echo "P4: copilot-vscode has no process an operator may be told to end"
rm -f "$LOCK" "$TMP/sup.pid" "$TMP/rt.pid"
# Deliberately give it the ancestor the walk WOULD find, then require it absent:
# the "session" for this runtime is VS Code itself, which must never be named.
VSCODE_TARGET_SESSION_LOG="$TMP/copilot.log"; : > "$VSCODE_TARGET_SESSION_LOG"
export VSCODE_TARGET_SESSION_LOG
env FAKE_RT=copilot-vscode bash "$TMP/fake/session-loop.sh"
if [ -f "$LOCK" ] && [ "$(jq -r '.runtime' "$LOCK" 2>/dev/null)" = "copilot-vscode" ]; then
  assert_eq "P4a: no pid recorded for copilot-vscode" "$(jq -r 'has("pid")' "$LOCK")" "false"
else
  ok "P4a: copilot-vscode did not register in this fixture — no pid to record either way"
fi
unset VSCODE_TARGET_SESSION_LOG
rm -f "$LOCK"

echo "T21: D14 — a supervised successor takes its project from the environment, not file mtime"
# The swap this guards against: two chains staging inside the 600s handshake TTL.
# register runs with no --project from a SessionStart hook, so before D14 it
# consumed the *freshest* pending file — which can belong to the other chain.
mkdir -p "$TMP/work/otherproj"
PEND_T="$TMP/.context-budget/successor-pending-testproj.json"
PEND_O="$TMP/.context-budget/successor-pending-otherproj.json"
mk_pending() {   # $1=project -> a fresh handshake file for that chain
  mkdir -p "$TMP/.context-budget"
  jq -n --arg p "$1" '{project:$p, seq:9, launched_at:"2026-01-01T00:00:00Z"}' \
    > "$TMP/.context-budget/successor-pending-$1.json"
}
reset_pend() {   # otherproj's file is always the FRESHER of the two
  rm -f "$TMP/work/testproj/.active-session" "$TMP/work/otherproj/.active-session" \
        "$TMP/.context-budget/successor-pending-"*.json
  mk_pending testproj; sleep 1; mk_pending otherproj
}

# T21a-c: TF_SESSION_LOOP_PROJECT set => adopt it, retire only our own file.
reset_pend; mk_transcript sup1 40000
TF_SESSION_LOOP_PROJECT=testproj run_as sup1 register --quiet >/dev/null
assert_eq "T21a: adopted the supervised project, not the freshest file" \
  "$(jq -r .project "$TMP/.context-budget/sessions/claude-sup1.json" 2>/dev/null)" "testproj"
assert_eq "T21b: it locked its OWN work item" \
  "$(jq -r .session_id "$TMP/work/testproj/.active-session" 2>/dev/null)" "sup1"
[ ! -f "$TMP/work/otherproj/.active-session" ] \
  && ok "T21c: the other chain's lock was not taken" \
  || bad "T21c: it locked otherproj — D14 swap reproduced"
[ ! -f "$PEND_T" ] && ok "T21d: its own handshake file was retired" \
                   || bad "T21d: own handshake file survived"
[ -f "$PEND_O" ] && ok "T21e: the other chain's fresher handshake survived unread" \
                 || bad "T21e: the other chain's handshake was consumed"

# T21f: the mtime heuristic is the UNSUPERVISED fallback and must still work.
reset_pend; mk_transcript unsup1 40000
unset TF_SESSION_LOOP_PROJECT
run_as unsup1 register --quiet >/dev/null
assert_eq "T21f: with no supervisor, the freshest handshake still wins" \
  "$(jq -r .project "$TMP/.context-budget/sessions/claude-unsup1.json" 2>/dev/null)" "otherproj"

# T21g: an env var naming no work directory must not invent a project.
reset_pend; mk_transcript sup2 40000
TF_SESSION_LOOP_PROJECT=nosuchproj run_as sup2 register --quiet >/dev/null
assert_eq "T21g: a bogus env project falls back to the handshake" \
  "$(jq -r .project "$TMP/.context-budget/sessions/claude-sup2.json" 2>/dev/null)" "otherproj"

# T21h: children are excluded by construction — a sub-agent inheriting the same
# variable must neither adopt a project nor eat the successor's handshake.
reset_pend; mk_transcript sup3 40000
run_as sup3 register --project testproj --quiet >/dev/null      # a parent to chain from
mk_pending testproj
mk_transcript agent-d14 1000
TF_SESSION_LOOP_PROJECT=testproj run_as sup3 register \
  --transcript "$PROJ_DIR/agent-d14.jsonl" --parent-session sup3 --quiet >/dev/null 2>&1
[ -f "$PEND_T" ] && ok "T21h: a child left the handshake file for the real successor" \
                 || bad "T21h: a child consumed the successor's handshake"
rm -f "$TMP/work/testproj/.active-session" "$TMP/.context-budget/successor-pending-"*.json

echo "S1: P1' — record/register name an unstaged successor under a supervisor (B1)"
# The predicate is "a supervised session is past its budget and the handshake
# has not completed", read from the session's own end. Neither leg is
# agent-authored: .next-command is written only by --emit, the budget is
# measured from the transcript. Hermetic like T20 — a supervised test runner
# would otherwise leak in through TF_SESSION_LOOP_PROJECT.
unset TF_SESSION_LOOP_PROJECT
S1LOOP="$TMP/work/testproj/.session-loop"
S1NEXT="$TMP/work/testproj/.next-command"
rm -f "$S1LOOP" "$S1NEXT" "$TMP/work/testproj/.active-session"
assert_absent() { case "$2" in *"$3"*) bad "$1 (unwanted [$3] in [$2])" ;; *) ok "$1" ;; esac; }
s1_supervisor() {   # a live supervisor marker for testproj
  jq -n --argjson pid "$$" --arg p testproj --arg s "2026-01-01T00:00:00Z" \
    '{pid:$pid, project:$p, started_at:$s}' > "$S1LOOP"
}
mk_transcript s1ok   50000
mk_transcript s1warn 125000
mk_transcript s1stop 155000

# S1a: H1 — below WARN, silent. Mutation red: drop the budget leg and every
# healthy session is told to stage, its whole life, because the supervisor
# consumes .next-command BEFORE the run. That is exactly how P1 died.
s1_supervisor
err=$(run_as s1ok record --project testproj --label s1a 2>&1 >/dev/null)
assert_eq "S1a: below WARN, silent" "$err" ""

# S1b: H2 — WARN, nothing staged, live supervisor. It speaks, and it names BOTH
# legitimate endings, because H3 (a session deliberately ending the chain) sits
# inside the same predicate and is correct.
err=$(run_as s1warn record --project testproj --label s1b 2>&1 >/dev/null)
assert_contains "S1b: WARN names the unstaged successor" "$err" "successor: NOT STAGED"
assert_contains "S1b2: it gives the staging command" "$err" "launch-next-session.sh testproj --emit"
assert_contains "S1b3: it names quitting as a correct ending" "$err" "to end it:"

# S1c: exit codes untouched — 0/1/2 keep meaning OK/WARN/STOP only. This is the
# difference between P1' and the rejected P5: it never tells a compliant
# rollover it did something wrong.
run_as s1warn record --project testproj --label s1c >/dev/null 2>&1; rc=$?
assert_eq "S1c: WARN still exits 1" "$rc" "1"
run_as s1stop record --project testproj --label s1c2 >/dev/null 2>&1; rc=$?
assert_eq "S1c2: STOP still exits 2" "$rc" "2"

# S1d: stdout untouched — one status line, so no consumer parsing it breaks.
out=$(run_as s1stop record --project testproj --label s1d 2>/dev/null)
assert_eq "S1d: stdout is still a single line" "$(printf '%s' "$out" | wc -l | tr -d ' ')" "0"
assert_contains "S1d2: stdout is the status line" "$out" "status=STOP"

# S1e: leg 2 — once --emit has staged, the advisory goes quiet.
printf 'claude -p "next"\n' > "$S1NEXT"
err=$(run_as s1stop record --project testproj --label s1e 2>&1 >/dev/null)
assert_eq "S1e: a staged successor silences it" "$err" ""
rm -f "$S1NEXT"

# S1f: H4 — unsupervised. No supervisor, no chain to strand.
rm -f "$S1LOOP"
err=$(run_as s1stop record --project testproj --label s1f 2>&1 >/dev/null)
assert_eq "S1f: unsupervised, silent" "$err" ""

# S1g: strictly exit 0 — an ambiguous supervision answer stays silent. A
# spurious advisory is cheap; a wrong one trains the reader to ignore it.
sleep 0 & s1dead=$!; wait "$s1dead" 2>/dev/null
jq -n --argjson pid "$s1dead" --arg p testproj --arg s "2026-01-01T00:00:00Z" \
  '{pid:$pid, project:$p, started_at:$s}' > "$S1LOOP"
err=$(run_as s1stop record --project testproj --label s1g 2>&1 >/dev/null)
assert_eq "S1g: ambiguous supervision, silent" "$err" ""
s1_supervisor

# S1h: no project named and none recorded — nothing to ask about. (s1stop is
# still unregistered at this point; S1i registers it.)
err=$(run_as s1stop record --label s1h 2>&1 >/dev/null)
assert_eq "S1h: no project, silent" "$err" ""

# S1i: the invocation the workspace discipline actually prescribes is
# `record --label "<checkpoint>"` with NO --project. It resolves the project
# from this session's own record — cmd_release's idiom, never a newest-mtime
# guess.
rm -f "$TMP/work/testproj/.active-session"
run_as s1stop register --project testproj --quiet >/dev/null 2>&1
err=$(run_as s1stop record --label s1i 2>&1 >/dev/null)
assert_contains "S1i: bare record resolves its own project" "$err" "successor: NOT STAGED"

# S1j: register speaks too — a supervised successor's first boundary.
rm -f "$TMP/work/testproj/.active-session"
err=$(run_as s1stop register --project testproj 2>&1 >/dev/null)
assert_contains "S1j: register speaks" "$err" "successor: NOT STAGED"

# S1k: --quiet suppresses it, like note().
err=$(run_as s1stop record --project testproj --label s1k --quiet 2>&1 >/dev/null)
assert_eq "S1k: --quiet suppresses it" "$err" ""

# S1l: NOT in emit_check(). children/watch call it for OTHER sessions, where
# .next-command says nothing about the caller; `check` is the reachable proxy.
err=$(run_as s1stop check --project testproj 2>&1 >/dev/null)
assert_eq "S1l: check does not speak" "$err" ""

# S1m: a sub-agent is not the chain, and must never be told to stage the
# parent's successor.
run_as s1stop register --project testproj --quiet >/dev/null 2>&1   # parent holds the lock
mk_transcript s1child 155000
err=$(run_as s1stop register --transcript "$PROJ_DIR/s1child.jsonl" \
        --parent-session s1stop --project testproj 2>&1 >/dev/null)
assert_absent "S1m: a child says nothing about the chain" "$err" "successor: NOT STAGED"

rm -f "$S1LOOP" "$S1NEXT" "$TMP/work/testproj/.active-session"

echo "N1: --session-id — a read-only pin so check measures a NAMED session (Q3)"
# P4a plumbing (session-chain-observability, spec.md 4.1). The supervisor has to
# ask the budget question about its CHILD. Run in the supervisor's own env, check
# answers about whatever session discovery lands on -- newest-mtime when no env
# identity matches, which is the false-STOP bug this registry exists to stop. The
# pin names the session instead of guessing at it, and it is read-only: a
# supervisor asking a question must never re-pin, re-register, or touch a record
# that belongs to the session it is asking about.
CB_STATE="$TMP/.context-budget"
snap_state() {  # every state file, with mtime and content — the read-only oracle
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

# The runtime of the session being ASKED about must not come from the asker's
# env: a claude supervisor can run a codex child. The registry already knows it.
printf '{"last_token_usage":{"total_tokens":4242}}\n' > "$TMP/home/codex-pin.jsonl"
jq -n --arg af "$TMP/home/codex-pin.jsonl" \
  '{runtime:"codex", session_id:"pin-codex", artifact:$af}' \
  > "$CB_STATE/sessions/codex-pin-codex.json"
out=$(CLAUDE_CODE_SESSION_ID=pin-asker "$CB" check --session-id pin-codex)
assert_contains "N1d: runtime comes from the registry, not the caller's env" "$out" "runtime=codex"
assert_contains "N1e: and the pinned codex session is measured" "$out" "tokens=4242"

before="$(snap_state)"
run_as pin-asker check --session-id pin-live >/dev/null 2>&1
assert_eq "N1f: the pin writes nothing — no re-pin, no record, no ledger" \
  "$(snap_state)" "$before"

err=$(run_as pin-asker check --session-id no-such-session 2>&1 >/dev/null); rc=$?
assert_eq "N1g: an unregistered id is refused, not guessed around" "$rc" "3"
assert_contains "N1h: the refusal names the id it could not find" "$err" "no-such-session"

# Writing commands must never take the pin: register/record would stamp the
# caller's measurement onto a foreign identity, which is M13 with extra steps.
err=$(run_as pin-asker record --session-id pin-live 2>&1 >/dev/null); rc=$?
assert_eq "N1i: record refuses the pin (it writes)" "$rc" "3"
assert_contains "N1j: and says the pin is check-only" "$err" "check"
err=$(run_as pin-asker register --session-id pin-live --quiet 2>&1 >/dev/null); rc=$?
assert_eq "N1k: register refuses the pin" "$rc" "3"

# Two identities in one invocation is ambiguous; silently preferring either one
# is how a read ends up measuring a session nobody asked about.
err=$(run_as pin-asker check --session-id pin-live \
        --transcript "$PROJ_DIR/pin-asker.jsonl" 2>&1 >/dev/null); rc=$?
assert_eq "N1l: --session-id with --transcript is refused" "$rc" "3"

rm -f "$CB_STATE/sessions/codex-pin-codex.json"

echo; echo "passed=$PASS failed=$FAIL"
[ "$FAIL" -eq 0 ]
