#!/usr/bin/env bash
# File: scripts/launch-next-session.sh
# Purpose: Relaunch step of session-rollover (ADR-0003/0004) on the work item's
#          session record (work/<project>/session-state.json, Stage 4). The
#          launcher checks the two handoff files itself, then in ONE atomic
#          write advances `seq`, copies the outgoing owner into
#          `launch.predecessor`, empties `session`, and writes `staged` (--emit)
#          or `launch.pending` (--clear). The successor finds its number through
#          TF_SESSION_PROJECT + TF_SESSION_SEQ on the command line (attached
#          launches, the supervisor) or through `launch.pending` (--clear, same
#          process). The prompt wording is load-bearing and lives ONLY here.
# Usage:   launch-next-session.sh <project>
#            [--runtime claude|codex|gemini|opencode|copilot|copilot-cli|copilot-vscode]
#            [--emit [<abs-path>] [--loop-mode interactive|handsoff] [--loop-reason <text>]]
#            [--clear] [--check] [--dry-run] [--skip-freshness]
#          --emit:  stage the successor's command for a supervisor (write the
#                   record's `staged`, spawn nothing).
#          --clear: in-place relaunch (ADR-0009, claude-only) — the successor is
#                   THIS process after /clear; the prompt travels in
#                   launch.pending.prompt.
#          --check: run every gate, write nothing, exit 0 or 4.
#          --dry-run: --check plus the command that would run.
# Knobs:   ROLLOVER_RELAUNCH=off|manual|auto, ROLLOVER_RUNTIME (fallback only).
#          Precedence: explicit env > work/<project>/context-budget.env >
#          global context-budget.env > built-in default.
# Exit:    0 ok / 3 usage / 4 refused, with
#          `launch-next-session: refused reason=<code> [k=v …] — <remedy>` on
#          stderr. Codes (evaluation/stage3-design-v2.md, gate table), in the
#          order they are checked: schema_mismatch, chain_closed,
#          runtime_path_unsupported, supervised_stage_only, no_supervisor,
#          owner_live, not_owner, worktree_unsynced, launcher_stale,
#          launcher_unchanged, ledger_shape, ledger_seq_mismatch.
# The record is the only thing written. --emit leaves the successor's command
# in `staged` (and prints it as `cmd: …`); the supervisor consumes it, the
# turn-end self-kill (scripts/hooks/context-budget-hook-lib.sh) and the
# measurer's successor_advisory read `staged.by` / `staged` from the record.
# Vendor flags verified against live --help 2026-08-05/06: claude [prompt]
# --name; codex [PROMPT]; gemini -i; opencode --prompt; copilot -i; code chat.

set -u

# Workspace identity = repository identity, not checkout path (issue 05):
# resolve through git's common dir so a launcher invoked from a worktree still
# reads/writes the main checkout's record. Fallback: script-relative root.
SCRIPT_ROOT="$(cd "$(dirname "$0")/.." && pwd -P)"
resolve_workspace_root() {
  local common repo
  if common="$(git -C "$SCRIPT_ROOT" rev-parse --git-common-dir 2>/dev/null)"; then
    case "$common" in /*) : ;; *) common="$SCRIPT_ROOT/$common" ;; esac
    repo="$(cd "$common/.." 2>/dev/null && pwd -P)"
    if [ -n "$repo" ] && [ -f "$repo/scripts/launch-next-session.sh" ]; then
      printf '%s' "$repo"; return
    fi
  fi
  printf '%s' "$SCRIPT_ROOT"
}
WORKSPACE_ROOT="$(resolve_workspace_root)"
STATE_DIR="$WORKSPACE_ROOT/.context-budget"
# shellcheck source=lib/session-lib.sh
. "$WORKSPACE_ROOT/scripts/lib/session-lib.sh"

note() { echo "$@" >&2; }
die()  { echo "error: $*" >&2; exit 3; }
refuse() { echo "launch-next-session: refused reason=$1${2:+ $2}" >&2; exit 4; }
command -v jq >/dev/null 2>&1 || refuse jq_missing "jq is required"

PROJECT=""; RUNTIME=""; DRY=0; CHECK=0; SKIP_FRESH=0; EMIT=""; CLEAR=0
LOOP_MODE=""; LOOP_REASON=""
while [ $# -gt 0 ]; do
  case "$1" in
    --runtime) RUNTIME="$2"; shift 2 ;;
    --dry-run) DRY=1; shift ;;
    --check) CHECK=1; shift ;;
    --skip-freshness) SKIP_FRESH=1; shift ;;
    --clear) CLEAR=1; shift ;;
    # Deliberately NOT --mode: $MODE is ROLLOVER_RELAUNCH (auto|off|manual),
    # a different axis.
    --loop-mode)   LOOP_MODE="$2"; shift 2 ;;
    --loop-reason) LOOP_REASON="$2"; shift 2 ;;
    --emit) EMIT=1; shift ;;
    -*) die "unknown option: $1" ;;
    *) [ -z "$PROJECT" ] && PROJECT="$1" || die "unexpected argument: $1"; shift ;;
  esac
done
[ -n "$PROJECT" ] || die "usage: launch-next-session.sh <project> [--runtime <rt>] [--emit [--loop-mode interactive|handsoff] [--loop-reason <text>]] [--clear] [--check] [--dry-run] [--skip-freshness]"

if [ -n "$EMIT" ]; then
  [ "$DRY" -eq 0 ]   || die "--emit cannot be combined with --dry-run (--dry-run writes nothing)"
  [ "$CLEAR" -eq 0 ] || die "--clear cannot be combined with --emit (no new process is started to run the emitted command)"
else
  [ -z "$LOOP_MODE" ]   || die "--loop-mode requires --emit (it records how the ROLLOVER was performed; a direct launch is not one)"
  [ -z "$LOOP_REASON" ] || die "--loop-reason requires --emit (it records why the ROLLOVER happened; a direct launch is not one)"
fi
NOWRITE=0; { [ "$DRY" -eq 1 ] || [ "$CHECK" -eq 1 ]; } && NOWRITE=1

# The human override: a marker file in the work item beats the flag.
_hands=0; _inter=0
[ -f "$WORKSPACE_ROOT/work/$PROJECT/.hands-off" ]   && _hands=1
[ -f "$WORKSPACE_ROOT/work/$PROJECT/.interactive" ] && _inter=1
if [ "$_hands" -eq 1 ] && [ "$_inter" -eq 1 ]; then
  die "both .hands-off and .interactive exist in work/$PROJECT — remove one"
fi
[ "$_hands" -eq 1 ] && LOOP_MODE="handsoff"
[ "$_inter" -eq 1 ] && LOOP_MODE="interactive"
[ -n "$LOOP_MODE" ] || LOOP_MODE="handsoff"
case "$LOOP_MODE" in
  interactive|handsoff) : ;;
  *) die "--loop-mode must be interactive|handsoff, got: $LOOP_MODE" ;;
esac

# ---- the record, read once ---------------------------------------------------
REC="$WORKSPACE_ROOT/work/$PROJECT/session-state.json"
REC_JSON=""            # "" = no record yet (the launcher opens seq)
if [ -e "$REC" ]; then
  REC_JSON=$(cat "$REC" 2>/dev/null) || refuse schema_mismatch "record=$REC — unreadable"
  printf '%s' "$REC_JSON" | jq -e 'type=="object"' >/dev/null 2>&1 \
    || refuse schema_mismatch "record=$REC — not a JSON object"
  printf '%s' "$REC_JSON" | jq -e '.schema == 1' >/dev/null 2>&1 \
    || refuse schema_mismatch "record=$REC schema=$(printf '%s' "$REC_JSON" | jq -r '.schema // "none"') want=1"
fi
rec_q() { printf '%s' "$REC_JSON" | jq -r "$@" 2>/dev/null; }
SEEN_SEQ=null; OWNER_JSON=null
if [ -n "$REC_JSON" ]; then
  SEEN_SEQ="$(rec_q '.seq // null')"
  OWNER_JSON="$(printf '%s' "$REC_JSON" | jq -c '.session // null' 2>/dev/null)"
fi
owner_q() { printf '%s' "$OWNER_JSON" | jq -r "$@" 2>/dev/null; }

# chain_closed: the record's chain block (the supervisor writes it at a quit).
# An UNSUPERVISED rollover never runs session-loop.sh, so this read cannot
# live only there.
if [ -n "$REC_JSON" ] && [ "$(rec_q '.chain.closed // null')" != null ]; then
  refuse chain_closed "seq=$(rec_q '.chain.closed.by_seq // "?"') at=$(rec_q '.chain.closed.at // "?"') — the chain for work/$PROJECT was deliberately ended; reopen it explicitly: scripts/session-loop.sh $PROJECT --reopen"
fi

# Relaunch knobs: explicit env > per-item work/$PROJECT/context-budget.env >
# global context-budget.env > built-in default.
#
# EXCEPTION: CONTEXT_LOCK_STALE_SECS is GLOBAL-ONLY. The owner-liveness
# fallback here and context-budget.sh must be the SAME oracle, and the
# measurer reads only the global env file — so LOCK_STALE is captured from
# exactly those sources BEFORE the per-item file is sourced, and the exported
# copy is re-set afterwards so a successor inherits the one oracle's answer.
EXPLICIT_RELAUNCH="${ROLLOVER_RELAUNCH:-}"
EXPLICIT_RUNTIME="${ROLLOVER_RUNTIME:-}"
EXPLICIT_STALE="${CONTEXT_LOCK_STALE_SECS:-}"
if [ -f "$WORKSPACE_ROOT/context-budget.env" ]; then
  . "$WORKSPACE_ROOT/context-budget.env" >/dev/null 2>&1 || true
fi
if [ -n "$EXPLICIT_STALE" ]; then LOCK_STALE="$EXPLICIT_STALE"
else LOCK_STALE="${CONTEXT_LOCK_STALE_SECS:-10800}"; fi
_stale_pre_item="${CONTEXT_LOCK_STALE_SECS:-}"
if [ -f "$WORKSPACE_ROOT/work/$PROJECT/context-budget.env" ]; then
  . "$WORKSPACE_ROOT/work/$PROJECT/context-budget.env" >/dev/null 2>&1 || true
fi
if [ "${CONTEXT_LOCK_STALE_SECS:-}" != "$_stale_pre_item" ] \
   && [ "${CONTEXT_LOCK_STALE_SECS:-}" != "$LOCK_STALE" ]; then
  note "CONTEXT_LOCK_STALE_SECS in work/$PROJECT/context-budget.env is global-only and IGNORED for owner liveness (effective: ${LOCK_STALE}s from env/global/default)"
fi
CONTEXT_LOCK_STALE_SECS="$LOCK_STALE"
[ -n "$EXPLICIT_RELAUNCH" ] && ROLLOVER_RELAUNCH="$EXPLICIT_RELAUNCH"
[ -n "$EXPLICIT_RUNTIME" ] && ROLLOVER_RUNTIME="$EXPLICIT_RUNTIME"
MODE="${ROLLOVER_RELAUNCH:-off}"
FALLBACK_RUNTIME="${ROLLOVER_RUNTIME:-claude}"

# ---- runtime: --runtime > the outgoing owner's runtime > ROLLOVER_RUNTIME ----
if [ -z "$RUNTIME" ] && [ "$OWNER_JSON" != null ]; then
  RUNTIME="$(owner_q '.runtime // empty')"
fi
if [ -z "$RUNTIME" ]; then
  RUNTIME="$FALLBACK_RUNTIME"
  note "no session on the record; falling back to ROLLOVER_RUNTIME=$RUNTIME"
fi
# Keep in sync with the launch `case "$RUNTIME"` below.
case "$RUNTIME" in
  claude|codex|gemini|opencode|copilot|copilot-cli|copilot-vscode) : ;;
  *) refuse runtime_path_unsupported "runtime=$RUNTIME — unknown runtime" ;;
esac
# `code chat` is detached BY NATURE: a supervisor waiting on the emitted line in
# the foreground would read its instant return as a deliberate quit.
if [ -n "$EMIT" ] && [ "$RUNTIME" = "copilot-vscode" ]; then
  refuse runtime_path_unsupported "runtime=copilot-vscode path=emit — 'code chat' is detached by nature; run the chain with an attached runtime"
fi
if [ "$CLEAR" -eq 1 ] && [ "$RUNTIME" != "claude" ]; then
  refuse runtime_path_unsupported "runtime=$RUNTIME path=clear — /clear is a Claude Code feature"
fi

# ---- supervision -------------------------------------------------------------
# `supervised` exit 0 = positively live, 1 = positively not, 2 = ambiguous (a
# marker whose pid is dead, or TF_SESSION_LOOP_PROJECT with no marker). Only
# positive evidence refuses; ambiguity warns and proceeds (a spurious staged
# command is harmless, a refused repair strands the chain).
_sup_out="$("$WORKSPACE_ROOT/scripts/context-budget.sh" supervised --project "$PROJECT" 2>&1)"
SUP_RC=$?
if [ "$SUP_RC" -eq 0 ] && [ -z "$EMIT" ]; then
  refuse supervised_stage_only "pid=$(printf '%s' "$_sup_out" | sed -n 's/.*pid=\([0-9]*\).*/\1/p') — a supervised chain is STAGED, never launched: scripts/launch-next-session.sh $PROJECT --emit  then exit; the supervisor starts your successor itself"
fi
# A session the supervisor started (TF_SESSION_LOOP=1) is ended by its turn-end
# hook once it stages; with no live supervisor nothing would consume the command.
if [ -n "$EMIT" ] && [ "${TF_SESSION_LOOP:-}" = "1" ] && [ "$SUP_RC" -eq 1 ]; then
  refuse no_supervisor "project=$PROJECT — this session was started by a supervisor but none is live; start one (scripts/session-loop.sh $PROJECT) or roll over attached"
fi
case "$SUP_RC" in
  0|1) : ;;
  *) note "warning: could not positively rule out a live supervisor for $PROJECT ($_sup_out) — proceeding" ;;
esac
unset _sup_out

# ---- identity and ownership --------------------------------------------------
# Identity is the exported session id, the same table context-budget.sh
# registers under. gemini's constant id is workspace-scoped, not session-scoped:
# it counts only when the runtime in play is gemini.
ME=""; ME_SID=""
me_identity() {  # sets ME (<rt>-<sid>) and ME_SID
  local b
  if [ -n "${CLAUDE_CODE_SESSION_ID:-}" ]; then ME_SID="$CLAUDE_CODE_SESSION_ID"; ME="claude-$ME_SID"
  elif [ -n "${CODEX_THREAD_ID:-}" ]; then ME_SID="$CODEX_THREAD_ID"; ME="codex-$ME_SID"
  elif [ -n "${COPILOT_AGENT_SESSION_ID:-}" ]; then ME_SID="$COPILOT_AGENT_SESSION_ID"; ME="copilot-cli-$ME_SID"
  elif [ -n "${VSCODE_TARGET_SESSION_LOG:-}" ]; then
    b="$(basename "$VSCODE_TARGET_SESSION_LOG")"; ME_SID="${b%.jsonl}"; ME="copilot-vscode-$ME_SID"
  elif [ -n "${OPENCODE_SESSION_ID:-}" ]; then ME_SID="$OPENCODE_SESSION_ID"; ME="opencode-$ME_SID"
  elif [ "$RUNTIME" = "gemini" ]; then ME_SID="workspace"; ME="gemini-workspace"
  fi
}
me_identity
# Liveness of the recorded owner: pid running AND started when the record says;
# a block without a pid falls back to its transcript's age (copilot-vscode,
# gemini, a hook whose walk found nothing) — the measurer's rule.
owner_live() {
  local pid pstart cur af mt
  pid="$(owner_q '.pid // empty')"; pstart="$(owner_q '.pid_start // empty')"
  if [ -n "$pid" ]; then
    kill -0 "$pid" 2>/dev/null || return 1
    cur=$(ps -o lstart= -p "$pid" 2>/dev/null | sed 's/^ *//;s/ *$//')
    [ -n "$cur" ] && [ "$cur" = "$pstart" ]
    return
  fi
  af="$(owner_q '.artifact // empty')"
  [ -n "$af" ] && [ -f "$af" ] || return 1
  mt=$(stat -f%m "$af" 2>/dev/null || stat -c%Y "$af" 2>/dev/null) || return 1
  [ $(( $(date +%s) - mt )) -lt "$LOCK_STALE" ]
}
# The ONE caller that is not a session: the supervisor's own bootstrap
# (iteration 1 has no dying session to stage its command). The test is the
# STRICT parent, never an ancestor — session-loop.sh runs its child in the
# foreground, so the supervisor is an ancestor of every tool shell inside the
# session too. Consequence: session-loop.sh's bootstrap call must stay a DIRECT
# call (no $(...) or pipeline); test-session-loop.sh F1 is the tripwire.
invoked_by_supervisor() {
  local pid
  pid="$(rec_q '.chain.supervisor.pid // empty')"
  [ -n "$pid" ] && [ "$pid" = "$PPID" ] && kill -0 "$pid" 2>/dev/null
}
OWNER_KEY=""
[ "$OWNER_JSON" != null ] && OWNER_KEY="$(owner_q '"\(.runtime // "")-\(.session_id // "")"')"
BY="session"; DISPOSITION=""; PRED_JSON=null
if [ "$OWNER_JSON" = null ]; then
  if invoked_by_supervisor; then
    BY="supervisor"
    note "bootstrap: this --emit came from the session-loop supervisor itself (pid $PPID), which is not a session and so has no record — the ownership check does not apply"
  else
    refuse not_owner "project=$PROJECT owner=none me=${ME:-none} — no session owns work/$PROJECT; register first: scripts/context-budget.sh register --project $PROJECT"
  fi
elif [ -n "$ME" ] && [ "$OWNER_KEY" = "$ME" ]; then
  DISPOSITION="rolled_over"
elif owner_live; then
  refuse owner_live "project=$PROJECT owner=$OWNER_KEY me=${ME:-none} — a live session owns work/$PROJECT; roll over from it, or take it over: scripts/context-budget.sh register --project $PROJECT --takeover"
elif invoked_by_supervisor; then
  BY="supervisor"
  if [ "$(owner_q '.ended.door // empty')" = "stop" ]; then DISPOSITION="stopped"; else DISPOSITION="abandoned"; fi
  note "bootstrap: this --emit came from the session-loop supervisor itself (pid $PPID), which is not a session — the dead owner $OWNER_KEY is recorded as $DISPOSITION"
else
  refuse not_owner "project=$PROJECT owner=$OWNER_KEY me=${ME:-none} — the recorded owner is dead; adopt the item first: scripts/context-budget.sh register --project $PROJECT"
fi
if [ "$OWNER_JSON" != null ]; then
  PRED_JSON="$(printf '%s' "$OWNER_JSON" | jq -c --arg d "$DISPOSITION" \
    '{seq: .seq, session_id: .session_id, registered_at: .registered_at, disposition: $d}')"
fi
# --clear: the successor is THIS process, and the measurer binds it by the pid
# and start time the owner's block recorded at registration.
PENDING_JSON=null
if [ "$CLEAR" -eq 1 ]; then
  _pid="$(owner_q '.pid // empty')"; _pstart="$(owner_q '.pid_start // empty')"
  [ -n "$_pid" ] || refuse runtime_path_unsupported "runtime=$RUNTIME path=clear — the owner's block records no pid, so the successor could not be bound after /clear"
fi

# ---- worktree-invoked (issue 05) ---------------------------------------------
# Tracked handoff files flow only through git: the worktree must be committed
# and pushed, the main checkout clean, then ff-pulled (never on --check/--dry-run).
if [ "$SCRIPT_ROOT" != "$WORKSPACE_ROOT" ]; then
  [ -z "$(git -C "$SCRIPT_ROOT" status --porcelain -uno -- "work/$PROJECT" 2>/dev/null)" ] \
    || refuse worktree_unsynced "checkout=worktree state=uncommitted — commit work/$PROJECT in the worktree before relaunch"
  [ -z "$(git -C "$SCRIPT_ROOT" rev-list -n1 HEAD --not --remotes 2>/dev/null)" ] \
    || refuse worktree_unsynced "checkout=worktree state=unpushed — push first (the successor launches from the main checkout)"
  [ -z "$(git -C "$WORKSPACE_ROOT" status --porcelain -uno -- "work/$PROJECT" 2>/dev/null)" ] \
    || refuse worktree_unsynced "checkout=main state=uncommitted — resolve work/$PROJECT in the main checkout before relaunch"
  if [ "$NOWRITE" -eq 0 ]; then
    git -C "$WORKSPACE_ROOT" pull --ff-only -q 2>/dev/null \
      || refuse worktree_unsynced "checkout=main state=ff_pull_failed — diverged or offline; sync the main checkout manually"
    note "worktree-invoked: main checkout synced; launching from $WORKSPACE_ROOT"
  else
    note "worktree-invoked: a real launch would sync the main checkout, then launch from $WORKSPACE_ROOT"
  fi
  cd "$WORKSPACE_ROOT"
fi

# ---- launcher_stale (backlog L33) --------------------------------------------
# A launcher-touching commit reachable from some ref but NOT from HEAD = an edit
# this checkout lacks. Best-effort fetch first; fails open offline. From a
# worktree whose branch is a clean fast-forward of origin/main, push it to main
# and re-check (background sessions cannot close that gap themselves).
if [ "$SKIP_FRESH" -eq 0 ]; then
  git -C "$WORKSPACE_ROOT" fetch -q --all 2>/dev/null || true
  NEWER="$(git -C "$WORKSPACE_ROOT" rev-list -1 --all --not HEAD -- "work/$PROJECT/next-session.md" 2>/dev/null)"
  if [ -n "$NEWER" ] && [ "$SCRIPT_ROOT" != "$WORKSPACE_ROOT" ]; then
    WT_BRANCH="$(git -C "$SCRIPT_ROOT" rev-parse --abbrev-ref HEAD 2>/dev/null)"
    if [ -n "$WT_BRANCH" ] && [ "$WT_BRANCH" != "HEAD" ] \
       && git -C "$SCRIPT_ROOT" merge-base --is-ancestor origin/main "$WT_BRANCH" 2>/dev/null \
       && git -C "$SCRIPT_ROOT" merge-base --is-ancestor "$NEWER" "$WT_BRANCH" 2>/dev/null; then
      if [ "$NOWRITE" -eq 1 ]; then
        note "would ff-push origin $WT_BRANCH:main (stale launcher self-heal)"
        NEWER=""
      elif git -C "$SCRIPT_ROOT" push origin "$WT_BRANCH:main" >/dev/null 2>&1; then
        note "stale launcher self-heal: ff-pushed origin $WT_BRANCH:main"
        git -C "$WORKSPACE_ROOT" pull --ff-only -q 2>/dev/null \
          || refuse worktree_unsynced "checkout=main state=ff_pull_failed — after the ff-push; sync the main checkout manually"
        NEWER="$(git -C "$WORKSPACE_ROOT" rev-list -1 --all --not HEAD -- "work/$PROJECT/next-session.md" 2>/dev/null)"
      else
        note "ff-push origin $WT_BRANCH:main failed — leaving the stale-launcher refusal in place"
      fi
    fi
  fi
  if [ -n "$NEWER" ]; then
    refs="$(git -C "$WORKSPACE_ROOT" branch -a --contains "$NEWER" 2>/dev/null \
      | sed 's/^[* ] //' | head -3 | tr '\n' ' ' | sed 's/ $//')"
    refuse launcher_stale "commit=${NEWER:0:12} refs=${refs:-unknown} — a newer work/$PROJECT/next-session.md exists there; merge/pull it into this checkout first, or pass --skip-freshness"
  fi
fi

# ---- the two files (owner only; never on the supervisor's bootstrap) ---------
ledger_file() {
  local hf
  for hf in "$WORKSPACE_ROOT/work/$PROJECT/handoff.md" \
            "$WORKSPACE_ROOT/work/$PROJECT/session_handoff.md"; do
    [ -f "$hf" ] && { printf '%s' "$hf"; return 0; }
  done
  return 1
}
# Grammar mirrors check-ledger.py: strip ISO dates first (so "2026" is never a
# session number), then "session N" / "session #N" anywhere, or "— N"/"— sN"
# right after the heading dash.
top_ledger_session() {
  grep -m1 -E '^#[[:space:]]*Session Handoff' "$1" 2>/dev/null \
    | sed -E 's/[0-9]{4}-[0-9]{2}-[0-9]{2}//g' \
    | grep -oiE 'session[[:space:]]+#?[0-9]+|^#[[:space:]]*session handoff[[:space:]]*[—-][[:space:]]*s?[0-9]+' \
    | head -1 | grep -oE '[0-9]+' | head -1 || true
}
launcher_hash() {
  if command -v shasum >/dev/null 2>&1; then shasum -a 256 "$1" | cut -d' ' -f1
  elif command -v sha256sum >/dev/null 2>&1; then sha256sum "$1" | cut -d' ' -f1
  else cksum "$1" | cut -d' ' -f1; fi
}
LAUNCHER="$WORKSPACE_ROOT/work/$PROJECT/next-session.md"
[ -f "$LAUNCHER" ] || refuse launcher_unchanged "file=$LAUNCHER — absent; write the successor's work/$PROJECT/next-session.md first"
if [ "$BY" = "session" ]; then
  _reg_hash="$(owner_q '.launcher_hash // empty')"
  _cur_hash="$(launcher_hash "$LAUNCHER")"
  if [ -n "$_reg_hash" ] && [ "$_reg_hash" = "$_cur_hash" ]; then
    refuse launcher_unchanged "file=$LAUNCHER hash=${_cur_hash:0:12} — unchanged since this session registered; write the successor's launcher first"
  fi
  HF="$(ledger_file)" || refuse ledger_shape "project=$PROJECT — no handoff.md (nor session_handoff.md)"
  grep -q -E '^#[[:space:]]*Session Handoff' "$HF" 2>/dev/null \
    || refuse ledger_shape "file=$HF — no '# Session Handoff' heading"
  TOP_N="$(top_ledger_session "$HF")"
  [ -n "$TOP_N" ] || refuse ledger_shape "file=$HF — the top heading carries no session number"
  [ "$TOP_N" = "$SEEN_SEQ" ] || refuse ledger_seq_mismatch "ledger=$TOP_N seq=$SEEN_SEQ file=$HF — the top block must be this session's (#$SEEN_SEQ)"
fi

# ---- the successor's number and command ------------------------------------
if [ "$SEEN_SEQ" = null ]; then
  # No record: the launcher opens seq — ledger top block + 1, else 1.
  SEQ=1
  if HF0="$(ledger_file)"; then t="$(top_ledger_session "$HF0")"; [ -n "$t" ] && SEQ=$((t + 1)); fi
  LAST_SEQ=$((SEQ - 1))
else
  LAST_SEQ="$SEEN_SEQ"; SEQ=$((SEEN_SEQ + 1))
fi
# The canonical bootstrap prompt (ADR-0003: wording is load-bearing, verbatim).
PROMPT="Work item $PROJECT - rollover session #$SEQ. Read \`work/$PROJECT/next-session.md\` and continue from **First actions**."
# The env pair leads the command: how an attached successor finds its number.
CMD=("TF_SESSION_PROJECT=$PROJECT" "TF_SESSION_SEQ=$SEQ")
case "$RUNTIME" in
  claude)   CMD+=(claude --name "$PROJECT #$SEQ" "$PROMPT") ;;
  codex)    CMD+=(codex "$PROMPT") ;;
  gemini)   CMD+=(gemini -i "$PROMPT") ;;
  opencode) CMD+=(opencode --prompt "$PROMPT") ;;
  copilot|copilot-cli) CMD+=(copilot -i "$PROMPT") ;;
  copilot-vscode) CMD+=(code chat -r -m agent "$PROMPT") ;;
esac
CMD_LINE="$(printf '%q ' "${CMD[@]}" | sed 's/ $//')"
PATH_KIND="exec"; [ -n "$EMIT" ] && PATH_KIND="emit"; [ "$CLEAR" -eq 1 ] && PATH_KIND="clear"

if [ "$CHECK" -eq 1 ] && [ "$DRY" -eq 0 ]; then
  echo "launch-next-session: check ok project=$PROJECT seq=${SEEN_SEQ} successor=$SEQ path=$PATH_KIND by=$BY"
  exit 0
fi
printf 'Bootstrap prompt (paste into the successor if needed):\n----\n%s\n----\n' "$PROMPT"
echo "project=$PROJECT runtime=$RUNTIME mode=$MODE path=$PATH_KIND seq=$SEQ"
if [ "$DRY" -eq 1 ]; then
  echo "cmd: $CMD_LINE"
  exit 0
fi

# ---- the write ---------------------------------------------------------------
STAGED_JSON=null
[ -n "$EMIT" ] && STAGED_JSON="$(jq -cn --argjson s "$SEQ" --arg c "$CMD_LINE" --arg by "$ME_SID" --arg sup "$BY" \
  '{successor:$s, command:$c, by:(if $sup == "supervisor" then "supervisor" else $by end)}')"
[ "$CLEAR" -eq 1 ] && PENDING_JSON="$(jq -cn --argjson pid "$_pid" --arg ps "$_pstart" --arg p "$PROMPT" \
  '{pid:$pid, pid_start:$ps, prompt:$p}')"
SEEN_SID="$(printf '%s' "$OWNER_JSON" | jq -c '.session_id // null' 2>/dev/null)"
NOW="$(date -u +%FT%TZ)"
rc=0
session_record_update "$REC" \
  '(.seq // null) == $seen_seq and ((.session.session_id) // null) == $seen_sid' \
  '.seq = $seq
   | .launch = {launched_at: $ts, by: $by, mode: $mode, reason: $reason, predecessor: $pred, pending: $pending}
   | .session = null
   | .staged = $staged' \
  --argjson seen_seq "$SEEN_SEQ" --argjson seen_sid "$SEEN_SID" \
  --argjson seq "$SEQ" --arg ts "$NOW" --arg by "$BY" --arg mode "$LOOP_MODE" --arg reason "$LOOP_REASON" \
  --argjson pred "$PRED_JSON" --argjson pending "$PENDING_JSON" --argjson staged "$STAGED_JSON" || rc=$?
case "$rc" in
  0) ;;
  1) refuse not_owner "project=$PROJECT — the record changed underneath; re-run" ;;
  *) exit 4 ;;
esac
note "record: seq $LAST_SEQ -> $SEQ, predecessor=${DISPOSITION:-none}, by=$BY (work/$PROJECT/session-state.json)"

if [ -n "$EMIT" ]; then
  # The staged command, for the eye: the supervisor reads it from the record.
  echo "cmd: $CMD_LINE"
  note "emit: staged successor #$SEQ in work/$PROJECT/session-state.json (staged.command)"
  [ "${TF_SESSION_LOOP:-}" = "1" ] \
    && note "staged — this session ends at the end of this turn; there is no sentinel step."
  exit 0
fi

if [ "$CLEAR" -eq 1 ]; then
  note "the prompt above travels in launch.pending — NOW PRESS /clear and type nothing; the successor registers itself against this process."
  exit 0
fi

# "off" means "do not LAUNCH a successor"; the rollover itself is recorded above.
if [ "$MODE" = "off" ]; then
  note "ROLLOVER_RELAUNCH=off — not launching; paste the prompt above manually (prefix: TF_SESSION_PROJECT=$PROJECT TF_SESSION_SEQ=$SEQ)"
  exit 0
fi

# Attached: exec only on a real terminal; from an agent tool-shell, print the
# ready-to-run command instead.
if [ -t 0 ] && [ -t 1 ]; then
  exec env "${CMD[@]}"
else
  note "not an interactive terminal — run this in one:"
  echo "run: $CMD_LINE"
  exit 0
fi
