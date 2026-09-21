#!/usr/bin/env bash
# File: work/template-improvement-review/evaluation/probes/lib.sh
# Purpose: Shared by the phase-7 probes (v1-attended-rollover.sh, v3-chain.sh,
#          v10-fleet.sh): option parsing, the throwaway item's seed, the
#          session's turn script, and the assertions. A probe pins record
#          fields (jq on work/<p>/session-state.json), the supervisor's
#          `verdict=`/`refused`/`broken` codes from its log, exit codes and
#          check-ledger.py's rc — never prose (stage3-design-v2.md, "Tests").
#          Sourced, bash 3.2. Exit 0 iff every assertion held; 1 with one
#          `FAIL:` line per broken criterion; 3 usage.
# Twin:    scripts/tests/test-probe-twins.sh runs these same scripts unchanged
#          with a stub `claude` first on PATH — the CI contract for the probes
#          that otherwise need a vendor login.
# Options: --root <workspace-root> --project <item> [--runtime claude]
#          [--driver direct|expect] [--max-sessions N] [--stop-at N]
#          [--parent-session <sid>]
#          --stop-at N: the session numbered N (and any later one) writes its
#          ledger block and stops instead of rolling over.
#          --driver expect: the supervisor runs in a pty (a real TUI child
#          needs one); direct: stdin from /dev/null (the stub, or -p sessions).

PROBE_PASS=0; PROBE_FAIL=0
probe_ok()  { PROBE_PASS=$((PROBE_PASS+1)); echo "  ok: $1"; }
probe_bad() { PROBE_FAIL=$((PROBE_FAIL+1)); echo "  FAIL: $1" >&2; }
probe_assert_eq() { [ "$2" = "$3" ] && probe_ok "$1" || probe_bad "$1 (want [$3] got [$2])"; }
probe_assert_ne() { [ -n "$2" ] && [ "$2" != "$3" ] && probe_ok "$1" || probe_bad "$1 (got [$2], must be set and differ from [$3])"; }
probe_finish() { echo "$PROBE_NAME: $PROBE_PASS passed, $PROBE_FAIL failed"; [ "$PROBE_FAIL" -eq 0 ]; }
probe_usage() {
  echo "usage: $PROBE_NAME --root <workspace-root> --project <item> [--runtime claude] [--driver direct|expect] [--max-sessions N] [--stop-at N] [--parent-session <sid>]" >&2
  exit 3
}

ROOT=""; PROJECT=""; RUNTIME="claude"; DRIVER="direct"; MAX_SESSIONS=2; STOP_AT=""; PARENT_SESSION=""
probe_parse() {
  while [ $# -gt 0 ]; do
    case "$1" in
      --root) ROOT="${2:-}"; shift 2 ;;
      --project) PROJECT="${2:-}"; shift 2 ;;
      --runtime) RUNTIME="${2:-}"; shift 2 ;;
      --driver) DRIVER="${2:-}"; shift 2 ;;
      --max-sessions) MAX_SESSIONS="${2:-}"; shift 2 ;;
      --stop-at) STOP_AT="${2:-}"; shift 2 ;;
      --parent-session) PARENT_SESSION="${2:-}"; shift 2 ;;
      *) probe_usage ;;
    esac
  done
  [ -n "$ROOT" ] && [ -n "$PROJECT" ] || probe_usage
  ROOT="$(cd "$ROOT" 2>/dev/null && pwd -P)" || probe_usage
  [ -f "$ROOT/scripts/launch-next-session.sh" ] || { echo "$PROBE_NAME: $ROOT is not a workspace (no scripts/launch-next-session.sh)" >&2; exit 3; }
  command -v jq >/dev/null 2>&1 || { echo "$PROBE_NAME: jq is required" >&2; exit 3; }
  case "$DRIVER" in direct|expect) ;; *) probe_usage ;; esac
  W="$ROOT/work/$PROJECT"; REC="$W/session-state.json"; LOGF="$W/.session-loop.log"
  # A probe runs from outside any chain: the env a live supervisor exports
  # (a probe started from a supervised session inherits it) would make every
  # attended session here look supervised (no_supervisor at its hand stage).
  unset TF_SESSION_LOOP TF_SESSION_LOOP_PROJECT TF_SESSION_PROJECT TF_SESSION_SEQ
  CB="$ROOT/scripts/context-budget.sh"; LN="$ROOT/scripts/launch-next-session.sh"
  SL="$ROOT/scripts/session-loop.sh"; FLEET="$ROOT/scripts/fleet.sh"
}

rec() { jq -r "$1" "$REC" 2>/dev/null; }
ledger_blocks() { grep -c '^# Session Handoff' "$W/handoff.md" 2>/dev/null | tr -d ' '; }
check_ledger_rc() { (cd "$ROOT" && python3 scripts/check-ledger.py "work/$PROJECT" >/dev/null 2>&1); echo $?; }
# The supervisor's codes, from its log: "verdict=<code> seq=<n>" in order, and
# the first refused/broken code (with its leg) if any.
log_verdicts() { grep -o 'verdict=[a-z_]* seq=[0-9]*' "$LOGF" 2>/dev/null | sed 's/verdict=//' | tr '\n' ' ' | sed 's/ $//'; }
log_broken()   { grep -o 'broken reason=[a-z_]*\( leg=[a-z_]*\)\?' "$LOGF" 2>/dev/null | head -1 | sed 's/broken reason=//'; }
log_refused()  { grep -o 'refused reason=[a-z_]*\( leg=[a-z_]*\)\?' "$LOGF" 2>/dev/null | head -1 | sed 's/refused reason=//'; }
# Files the record replaced (phases 3–5); none may reappear under work/<p>/.
# (.next-command, .session-seq.bump.json and .session-loop are the phase-5
# mirrors, still written until phase 8; .agent-dispatch/ is the fleet's.)
RETIRED_FILES=".active-session .agent-locks .rollover-options .session-seq .session-seq.provenance.json .rollover-complete .next-command.json .next-command.stale .session-loop.budget .session-loop.alarm-stop .chain-closed .pending-clear-seed"
retired_present() { local f out=""; for f in $RETIRED_FILES; do [ -e "$W/$f" ] && out="$out $f"; done; printf '%s' "${out# }"; }

# The canonical bootstrap prompt (launch-next-session.sh, verbatim shape).
probe_prompt() { printf 'Work item %s - rollover session #%s. Read `work/%s/next-session.md` and continue from **First actions**.' "$PROJECT" "$1" "$PROJECT"; }

# A fresh item: no record, no supervisor files, an empty ledger (purpose
# comment only), the launcher for session 1 naming the turn script.
probe_seed_item() {
  mkdir -p "$W"
  rm -f "$REC" "$REC.lock" "$W/.session-loop" "$LOGF" "$W/.next-command" "$W/.session-seq.bump.json" \
        "$W/.probe-stop-at" "$W"/launcher-*.log "$W"/session-*.out "$W/turns.log" "$W/supervisor.out" \
        "$W/.hands-off" "$W/.interactive"
  rm -rf "$W/.agent-dispatch"
  [ -f "$W/README.md" ] || printf '# %s\n\nThrowaway item for the phase-7 probes.\n' "$PROJECT" > "$W/README.md"
  cat > "$W/handoff.md" <<'EOF'
<!--
PURPOSE: This is the LEDGER (provenance log). Append-only, newest block on
TOP. Each "# Session Handoff" block records what happened in one session.
-->
EOF
  probe_write_turn_script
  bash "$W/session-turn.sh" --write-launcher 1
  [ -n "$STOP_AT" ] && printf '%s\n' "$STOP_AT" > "$W/.probe-stop-at"
  return 0
}

# What a session does, as one script it runs from its own tool shell (so the
# launcher sees the session's identity, and the hooks see the launcher's
# writes). The model's part is to run it and reply.
probe_write_turn_script() {
  cat > "$W/session-turn.sh" <<'EOF'
#!/usr/bin/env bash
# The probe session's turn (work/<p>/session-turn.sh), run INSIDE the session
# from the workspace root: bind the item if the record does not already name
# this session, put this session's block on top of the ledger, then either
# stop (the number in .probe-stop-at) or write the successor's launcher and
# roll over — `--emit` under a supervisor (TF_SESSION_LOOP=1), attached
# otherwise (from a tool shell the launcher prints the `run:` line).
#   --write-launcher <n>   only write the launcher for session n
#   --no-launch            everything but the launcher call
set -u
W="$(cd "$(dirname "$0")" && pwd -P)"; P="${W##*/}"; ROOT="$(cd "$W/../.." && pwd -P)"
CB="$ROOT/scripts/context-budget.sh"; LN="$ROOT/scripts/launch-next-session.sh"; REC="$W/session-state.json"
log() { printf '%s %s\n' "$(date -u +%FT%TZ)" "$*" >> "$W/turns.log"; }
write_launcher() {
  cat > "$W/next-session.md" <<MD
# Next session — $P #$1

Phase-7 probe item: the session's whole turn is one script.

## First actions

1. Run \`bash work/$P/session-turn.sh\` and wait for it to finish.
2. Reply with the single word \`done\`. Do nothing else: no other commands, no other files.
MD
}
[ "${1:-}" = "--write-launcher" ] && { write_launcher "$2"; exit 0; }
me="${CLAUDE_CODE_SESSION_ID:-}"
[ "$(jq -r '.session.session_id // empty' "$REC" 2>/dev/null)" = "$me" ] \
  || "$CB" register --project "$P" --runtime claude
seq="$(jq -r '.seq // empty' "$REC" 2>/dev/null)"
[ -n "$seq" ] || { log "turn: no number for ${me:-?}"; exit 9; }
under=""; [ "${TF_SESSION_LOOP:-}" = 1 ] && under=" under the supervisor"
blk="# Session Handoff — $seq ($(date -u +%F)): probe turn\n\n**Summary.** Session #$seq ($me) ran its turn$under.\n"
if grep -q '^-->' "$W/handoff.md"; then
  awk -v blk="$blk" '{print} /^-->/ && !d {print ""; print blk; d=1}' "$W/handoff.md" > "$W/handoff.md.new"
else
  { printf '%b\n' "$blk"; cat "$W/handoff.md"; } > "$W/handoff.md.new"
fi
mv "$W/handoff.md.new" "$W/handoff.md"
stop_at="$(cat "$W/.probe-stop-at" 2>/dev/null)"
if [ -n "$stop_at" ] && [ "$seq" -ge "$stop_at" ]; then log "session #$seq ($me): stopping here"; exit 0; fi
write_launcher "$((seq + 1))"
[ "${1:-}" = "--no-launch" ] && { log "session #$seq ($me): launcher written, not launched"; exit 0; }
if [ "${TF_SESSION_LOOP:-}" = 1 ]; then
  "$LN" "$P" --emit > "$W/launcher-$seq.log" 2>&1; rc=$?
else
  "$LN" "$P" > "$W/launcher-$seq.log" 2>&1 </dev/null; rc=$?
fi
log "session #$seq ($me): launcher rc=$rc"
exit "$rc"
EOF
  chmod +x "$W/session-turn.sh"
}

# The `run:` line the attached launcher printed for session <n>'s successor.
probe_run_line() { sed -n 's/^run: //p' "$W/launcher-$1.log" 2>/dev/null | head -1; }

# Run a headless attended session: `claude -p <prompt>`, the tools the turn
# needs allowed, transcripts forced on (a nested launch inherits
# CLAUDE_CODE_CHILD_SESSION, which turns transcript saving off — stage2-probes.md).
# $1 = label (output at work/<p>/session-<label>.out), $2 = the prompt,
# $3 = an optional env-prefixed command line to run instead of a plain `claude`
#      (the launcher's `run:` line; -p and the tool list are appended).
probe_session() {
  local label="$1" prompt="$2" line="${3:-}" tools
  tools="--allowedTools 'Bash(bash work/$PROJECT/session-turn.sh:*)' Read"
  if [ -n "$line" ]; then
    (cd "$ROOT" && eval "env -u CLAUDE_CODE_CHILD_SESSION CLAUDE_CODE_FORCE_SESSION_PERSISTENCE=1 $line -p $tools") \
      > "$W/session-$label.out" 2>&1 </dev/null
  else
    (cd "$ROOT" && eval "env -u CLAUDE_CODE_CHILD_SESSION CLAUDE_CODE_FORCE_SESSION_PERSISTENCE=1 $RUNTIME -p \"\$prompt\" --name \"$PROJECT #$label\" $tools") \
      > "$W/session-$label.out" 2>&1 </dev/null
  fi
}

# Run the supervisor; DRIVER=expect gives it a pty (a TUI child needs one) and
# answers Claude Code's folder-trust dialog if it appears. Output at
# work/<p>/supervisor.out; the exit code is the supervisor's.
probe_supervise() {
  if [ "$DRIVER" = expect ]; then
    command -v expect >/dev/null 2>&1 || { echo "$PROBE_NAME: --driver expect needs expect(1)" >&2; return 3; }
    (cd "$ROOT" && env -u CLAUDE_CODE_CHILD_SESSION CLAUDE_CODE_FORCE_SESSION_PERSISTENCE=1 \
      expect -f - "$SL" "$PROJECT" "$@" <<'EOF'
set timeout 2400
set cmd [lrange $argv 0 end]
eval spawn -noecho $cmd
stty rows 40 columns 140 < $spawn_out(slave,name)
expect {
  -re {trust this folder} { sleep 1; send "\033\[B"; sleep 1; send "\r"; exp_continue }
  timeout { puts stderr "probe: expect timed out"; exec kill -TERM [exp_pid]; exit 124 }
  eof
}
catch wait result
exit [lindex $result 3]
EOF
    ) > "$W/supervisor.out" 2>&1
  else
    (cd "$ROOT" && "$SL" "$PROJECT" "$@") > "$W/supervisor.out" 2>&1 </dev/null
  fi
}
