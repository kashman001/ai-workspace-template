#!/usr/bin/env bash
# File: scripts/tests/test-probe-twins.sh
# Purpose: The stub-runtime twins of the phase-7 probes
#          (work/template-improvement-review/evaluation/probes/), the CI
#          contract for the probes that otherwise need a vendor login
#          (evaluation/stage3-design-v2.md, "Tests"). The probes run UNCHANGED
#          against a throwaway git workspace with a stub `claude` first on
#          PATH. The stub honours the hooks contract in .claude/settings.json
#          (SessionStart -> register, Stop -> the dispatcher's turn-end
#          self-kill, SessionEnd -> release) and its whole turn is the
#          First-actions script the launcher file names — so the measurer, the
#          launcher, the hook dispatcher and the supervisor under test are the
#          real ones. Plus the two suite-level cases of phase 7: the staged
#          command run by hand (H1: a supervisor restart refuses
#          staged_invalid leg=spent) and the refused hand stage (H2: not_owner
#          for the session that already staged, owner_live for a stranger).
#          Every case pins exit codes, reason/verdict codes and record fields.
set -u
unset TF_SESSION_LOOP TF_SESSION_LOOP_PROJECT TF_SESSION_PROJECT TF_SESSION_SEQ   # never inherit a live chain's env
SRC_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
PROBES="$SRC_ROOT/work/template-improvement-review/evaluation/probes"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
MAIN="$TMP/main"
mkdir -p "$MAIN/scripts/lib" "$MAIN/scripts/hooks" "$MAIN/work/testproj" "$MAIN/.claude" "$MAIN/.context-budget/sessions" "$TMP/home"
cp "$SRC_ROOT/scripts/session-loop.sh" "$SRC_ROOT/scripts/launch-next-session.sh" \
   "$SRC_ROOT/scripts/context-budget.sh" "$SRC_ROOT/scripts/fleet.sh" "$SRC_ROOT/scripts/check-ledger.py" "$MAIN/scripts/"
cp "$SRC_ROOT/scripts/lib/session-lib.sh" "$MAIN/scripts/lib/"
cp "$SRC_ROOT"/scripts/hooks/* "$MAIN/scripts/hooks/"
cp "$SRC_ROOT/.claude/settings.json" "$MAIN/.claude/"
chmod +x "$MAIN/scripts/"*.sh "$MAIN/scripts/hooks/"*.sh
printf 'ROLLOVER_RELAUNCH=manual\nROLLOVER_RUNTIME=claude\nCONTEXT_DUMB_ZONE_TOKENS=150000\nCONTEXT_DUMB_ZONE_WARN_TOKENS=120000\n' > "$MAIN/context-budget.env"
printf '%s\n' 'work/*/session-state.json*' 'work/*/.session-loop*' 'work/*/.next-command*' \
  'work/*/.session-seq*' 'work/*/.agent-dispatch/' 'work/*/.probe-stop-at' 'work/*/turns.log' \
  'work/*/launcher-*.log' 'work/*/session-*.out' 'work/*/supervisor.out' '.context-budget/' > "$MAIN/.gitignore"
export HOME="$TMP/home"      # the stub's transcripts live under $HOME/.claude/projects/<slug>/
git -C "$MAIN" init -q
git -C "$MAIN" config user.email t@t; git -C "$MAIN" config user.name t
git -C "$MAIN" add -A; git -C "$MAIN" commit -qm init
NOTED="$TMP/notify.log"
printf '#!/usr/bin/env bash\nprintf "%%s\\n" "$1" >> "%s"\n' "$NOTED" > "$TMP/notify.sh"; chmod +x "$TMP/notify.sh"
export SESSION_LOOP_NOTIFY="$TMP/notify.sh"
export STUB_LOG="$TMP/stub.log"

# The stub, reached as `claude`: exec -a gives it argv0 "claude" so the
# measurer's process walk finds it (pid, pid_start, supervisor parent) the way
# it finds the real runtime.
cat > "$TMP/stub.sh" <<'EOF'
#!/bin/bash
set -u
ROOT="$(pwd -P)"                       # claude's project dir is its cwd
prompt=""; for a in "$@"; do case "$a" in "Work item "*) prompt="$a" ;; esac; done
sid="stub-$(date +%s)-$$"
export CLAUDE_CODE_SESSION_ID="$sid" CLAUDE_PROJECT_DIR="$ROOT"
slug="$(printf '%s' "$ROOT" | tr '/.' '--')"; tdir="$HOME/.claude/projects/$slug"; mkdir -p "$tdir"; tx="$tdir/$sid.jsonl"
usage() { printf '{"type":"assistant","sessionId":"%s","message":{"role":"assistant","usage":{"input_tokens":%s,"cache_read_input_tokens":0,"cache_creation_input_tokens":0},"content":[{"type":"text","text":"%s"}]},"isSidechain":false}\n' "$sid" "$1" "$2" >> "$tx"; }
printf '{"type":"user","sessionId":"%s","message":{"role":"user","content":%s}}\n' "$sid" "$(printf '%s' "$prompt" | jq -R .)" > "$tx"
usage 1000 ok
payload="$(jq -cn --arg s "$sid" --arg t "$tx" --arg c "$ROOT" '{session_id:$s, transcript_path:$t, cwd:$c}')"
hooks() {   # $1 = event: every command .claude/settings.json wires for it, as claude would run it
  local cmds cmd
  cmds="$(jq -r --arg ev "$1" '.hooks[$ev][]?.hooks[]?.command' "$ROOT/.claude/settings.json")"
  [ -n "$cmds" ] || return 0
  while IFS= read -r cmd; do printf '%s' "$payload" | bash -c "$cmd" >> "$STUB_LOG" 2>&1 || true; done <<< "$cmds"
}
echo "start sid=$sid seq=${TF_SESSION_SEQ:-} loop=${TF_SESSION_LOOP:-}" >> "$STUB_LOG"
hooks SessionStart
f="$(printf '%s' "$prompt" | grep -o 'work/[^`/ ]*/next-session.md' | head -1)"
turn=""; [ -n "$f" ] && turn="$(grep -o 'bash work/[^` ]*\.sh' "$ROOT/$f" | head -1)"
[ -n "$turn" ] && { (cd "$ROOT" && $turn) >> "$STUB_LOG" 2>&1; echo "turn rc=$? sid=$sid" >> "$STUB_LOG"; }
usage 1200 done
hooks Stop            # under a supervisor, after a staging: the dispatcher TERMs this process
hooks SessionEnd
echo "end sid=$sid" >> "$STUB_LOG"
exit 0
EOF
mkdir -p "$TMP/bin"
printf '#!/bin/bash\nexec -a claude /bin/bash "%s" "$@"\n' "$TMP/stub.sh" > "$TMP/bin/claude"; chmod +x "$TMP/bin/claude"
export PATH="$TMP/bin:$PATH"

PROBE_NAME="test-probe-twins"
. "$PROBES/lib.sh"
probe_parse --root "$MAIN" --project testproj
run_probe() {   # $1 = probe, rest = its extra options; sets RC and OUT
  "$PROBES/$1" --root "$MAIN" --project testproj "${@:2}" > "$TMP/probe.out" 2>&1; RC=$?
  OUT="$(cat "$TMP/probe.out")"
}
probe_failures() { printf '%s\n' "$OUT" | grep -c '^  FAIL:' | tr -d ' '; }
probe_passes()   { printf '%s\n' "$OUT" | grep -c '^  ok:' | tr -d ' '; }
stub_starts()    { grep -c '^start sid=' "$STUB_LOG" 2>/dev/null | tr -d ' '; }
: > "$STUB_LOG"

# ---------------------------------------------------------------------------
echo "T1: v1-attended-rollover under the stub"
run_probe v1-attended-rollover.sh
probe_assert_eq "T1a: probe rc 0"                     "$RC" "0"
probe_assert_eq "T1b: no failed criterion"            "$(probe_failures)" "0"
[ "$(probe_passes)" -ge 18 ] && probe_ok "T1c: every V1 criterion ran ($(probe_passes))" || probe_bad "T1c: only $(probe_passes) criteria ran"
probe_assert_eq "T1d: two stub sessions ran"          "$(stub_starts)" "2"
grep -q 'register: bound work/testproj seq=1 via=project (opened)' "$STUB_LOG" \
  && probe_ok "T1e: session #1 opened the record by an explicit register" || probe_bad "T1e: the explicit register did not open seq 1"
grep -q 'register: bound work/testproj seq=2 via=env (filled)' "$STUB_LOG" \
  && probe_ok "T1f: session #2 bound by the env pair through the SessionStart hook" || probe_bad "T1f: the successor was not bound by the hook"
probe_assert_ne "T1g: the SessionEnd hook (release --quiet) ended #2" "$(rec '.session.ended.at')" "null"

echo "T3: v3-chain under the stub — to the cap, and to a quit"
: > "$STUB_LOG"
run_probe v3-chain.sh --max-sessions 2
probe_assert_eq "T3a: probe rc 0 (staged, staged, cap)"   "$RC" "0"
probe_assert_eq "T3b: no failed criterion"                "$(probe_failures)" "0"
probe_assert_eq "T3c: two children ran"                   "$(stub_starts)" "2"
probe_assert_eq "T3d: both were ended by the turn-end hook (rc 143)" "$(grep -c 'ended rc=143' "$MAIN/work/testproj/.session-loop.log" | tr -d ' ')" "2"
grep -q 'terminating claude session' "$STUB_LOG" \
  && probe_ok "T3e: the dispatcher's self-kill fired" || probe_bad "T3e: the dispatcher never fired the self-kill"
: > "$STUB_LOG"
run_probe v3-chain.sh --max-sessions 3 --stop-at 2
probe_assert_eq "T3f: probe rc 0 (staged, quit_plain)"    "$RC" "0"
probe_assert_eq "T3g: no failed criterion"                "$(probe_failures)" "0"
probe_assert_eq "T3h: two children ran, the second quit"  "$(stub_starts)" "2"
grep -q 'end sid=' "$STUB_LOG" && probe_ok "T3i: the quitting child ran to its own end" || probe_bad "T3i: the quitting child did not exit on its own"

echo "T10: v10-fleet under fabricated child transcripts"
SLUG="$(printf '%s' "$MAIN" | tr '/.' '--')"; PROJ_DIR="$HOME/.claude/projects/$SLUG"; mkdir -p "$PROJ_DIR/parent-1/subagents"
jq -cn '{message:{usage:{input_tokens:50000,cache_read_input_tokens:0,cache_creation_input_tokens:0}},isSidechain:false}' > "$PROJ_DIR/parent-1.jsonl"
for c in a b; do
  jq -cn '{message:{usage:{input_tokens:2,cache_read_input_tokens:30000,cache_creation_input_tokens:0}},isSidechain:true}' > "$PROJ_DIR/parent-1/subagents/agent-$c.jsonl"
done
(cd "$MAIN" && CLAUDE_CODE_SESSION_ID=parent-1 "$CB" register --runtime claude --transcript "$PROJ_DIR/parent-1.jsonl" >/dev/null 2>&1)
run_probe v10-fleet.sh --parent-session parent-1
probe_assert_eq "T10a: probe rc 0"                        "$RC" "0"
probe_assert_eq "T10b: no failed criterion"               "$(probe_failures)" "0"
[ "$(probe_passes)" -ge 19 ] && probe_ok "T10c: every V10 criterion ran ($(probe_passes))" || probe_bad "T10c: only $(probe_passes) criteria ran"

# ---------------------------------------------------------------------------
echo "H2: the refused hand stage — --emit that the record contradicts"
STOP_AT=2; probe_seed_item; : > "$STUB_LOG"
as() { local s="$1"; shift; (cd "$MAIN" && CLAUDE_CODE_SESSION_ID="$s" "$@"); }
as hand-1 "$CB" register --project testproj --runtime claude >/dev/null 2>&1
as hand-1 bash work/testproj/session-turn.sh --no-launch
as hand-1 "$LN" testproj --emit >"$TMP/emit1.out" 2>&1; rc=$?
probe_assert_eq "H2a: the owner's hand stage is accepted"  "$rc" "0"
probe_assert_eq "H2b: staged #2 by hand-1"                 "$(rec '.staged.successor')/$(rec '.staged.by')" "2/hand-1"
cp "$REC" "$TMP/before"; cp "$W/.next-command" "$TMP/next-before"
out="$(as hand-1 "$LN" testproj --emit 2>&1)"; rc=$?
probe_assert_eq "H2c: --emit again by the session that staged → 4" "$rc" "4"
case "$out" in *"refused reason=not_owner"*) probe_ok "H2d: reason not_owner (it is no longer the owner)" ;; *) probe_bad "H2d: no not_owner in [$out]" ;; esac
cmp -s "$REC" "$TMP/before" && probe_ok "H2e: record byte-identical" || probe_bad "H2e: the refused stage wrote the record"
cmp -s "$W/.next-command" "$TMP/next-before" && probe_ok "H2f: the staged command untouched" || probe_bad "H2f: the staged command changed"

echo "H1: the staged command run by hand; a supervisor restart refuses staged_invalid leg=spent"
staged_cmd="$(rec '.staged.command')"
(cd "$MAIN" && eval "$staged_cmd") >/dev/null 2>&1; rc=$?
probe_assert_eq "H1a: the hand-run session exited 0"       "$rc" "0"
probe_assert_eq "H1b: it registered as #2 by the env pair"  "$(rec '.session.seq')" "2"
probe_assert_eq "H1c: the staged block is still there"      "$(rec '.staged.successor')" "2"
cp "$REC" "$TMP/before"; n0="$(stub_starts)"
(cd "$MAIN" && "$SL" testproj --max-sessions 3 --min-lifetime 0 --stall-limit 0) >"$TMP/sl.out" 2>&1 </dev/null; rc=$?
probe_assert_eq "H1d: supervisor exit 4"                    "$rc" "4"
probe_assert_eq "H1e: refused staged_invalid leg=spent"     "$(log_refused)" "staged_invalid leg=spent"
probe_assert_eq "H1f: the spent command was not run again"  "$(stub_starts)" "$n0"
probe_assert_eq "H1g: staged left in place as evidence"     "$(rec '.staged.successor')" "2"
probe_assert_eq "H1h: chain.supervisor cleared"             "$(rec '.chain.supervisor')" "null"

echo "H2 (cont.): a stranger's --emit while the owner is live"
tx="$TMP/hand-3.jsonl"; printf '{"type":"user"}\n' > "$tx"
as hand-3 "$CB" register --project testproj --runtime claude --transcript "$tx" >/dev/null 2>&1
probe_assert_eq "H2g: a fresh session adopted the dead owner's number" "$(rec '.session.session_id')/$(rec '.session.seq')" "hand-3/2"
cp "$REC" "$TMP/before"
out="$(as stranger "$LN" testproj --emit 2>&1)"; rc=$?
probe_assert_eq "H2h: --emit by another session → 4"         "$rc" "4"
case "$out" in *"refused reason=owner_live"*) probe_ok "H2i: reason owner_live" ;; *) probe_bad "H2i: no owner_live in [$out]" ;; esac
cmp -s "$REC" "$TMP/before" && probe_ok "H2j: record byte-identical" || probe_bad "H2j: the refused stage wrote the record"

echo
probe_finish
