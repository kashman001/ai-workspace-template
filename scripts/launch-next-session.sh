#!/usr/bin/env bash
# File: scripts/launch-next-session.sh
# Purpose: Relaunch step of session-rollover (ADR-0003/0004): launch a fresh
#          agent session seeded with the canonical bootstrap prompt for a work
#          item. The prompt wording is load-bearing and lives ONLY here.
#          Runtime resolution: --runtime flag > the dying session's own
#          registry record (D6) > newest record for the project >
#          ROLLOVER_RUNTIME > claude.
# Usage:   launch-next-session.sh <project>
#            [--runtime claude|codex|gemini|opencode|copilot] [--bg] [--dry-run]
#            [--emit [<abs-path>]] [--skip-freshness] [--clear]
#          --clear: in-place relaunch (ADR-0009, claude-only) — seed
#          work/<project>/.pending-clear-seed and let the human press /clear
#          instead of spawning a successor process.
# Knobs:   ROLLOVER_RELAUNCH=off|manual|auto, ROLLOVER_RUNTIME (fallback
#          only). Precedence: explicit env > work/<project>/context-budget.env
#          (committed per-item policy, optional) > global context-budget.env >
#          built-in default. ROLLOVER_CONFIRM_SECS (env only, default 120)
#          bounds the --bg successor-confirmation poll.
#          work/<project>/.rollover-options (optional, written at rollover):
#          ROLLOVER_OPT_APPROVAL=default|edits|auto|full, ROLLOVER_OPT_MODEL=<id>,
#          ROLLOVER_OPT_EXTRA=<raw args> — replayed as per-runtime flags on
#          the successor launch. Use ROLLOVER_OPT_EXTRA to hand the successor
#          an opt-in MCP fragment, e.g.
#          ROLLOVER_OPT_EXTRA="--mcp-config mcp-fragments/<server>.json"
#          (claude-only flags; see mcp-fragments/README.md).
# Exit:    0 ok / 3 error. Requires jq.
# Vendor flags verified against live --help 2026-08-05: claude [prompt] + --bg;
# codex [PROMPT]; gemini -i; opencode --prompt; copilot -i. claude -n/--name
# (session display name: picker + terminal title) verified 2026-08-06
# (2.1.223); no equivalent verified for other runtimes — their session titles
# rely on the prompt's "Work item <proj> - rollover session #N" lead (ASCII
# only: the %q cmd-echo pipes through BSD sed, which rejects multibyte).
# Approval-mapping
# flags (OPT_ARGS below) re-verified against live --help 2026-08-06: claude
# --permission-mode acceptEdits (edits), --permission-mode auto (auto —
# classifier-vetted, claude 2.1.223), --dangerously-skip-permissions (full);
# codex --ask-for-approval never/--dangerously-bypass-approvals-and-sandbox
# (NOT --full-auto — that flag does not exist in codex-cli 0.142.4); gemini
# --approval-mode auto_edit/--yolo; opencode --auto (same flag for edits and
# full); copilot --allow-all-tools/--allow-all. Non-claude runtimes have no
# classifier equivalent: auto falls back to the edits mapping with a note.
# Re-verify before changing (ADR-0003: a nonexistent flag already slipped in
# once).

set -u

# Workspace identity = repository identity, not checkout path (issue 05):
# resolve through git's common dir so a launcher invoked from a worktree
# still reads/writes the main checkout's coordination state. Fallbacks: not
# a git repo, or the git root is not this workspace — script-relative root.
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

note() { echo "$@" >&2; }
die()  { echo "error: $*" >&2; exit 3; }

PROJECT=""; RUNTIME=""; BG=0; DRY=0; SKIP_FRESH=0; EMIT=""; CLEAR=0
while [ $# -gt 0 ]; do
  case "$1" in
    --runtime) RUNTIME="$2"; shift 2 ;;
    --bg) BG=1; shift ;;
    --dry-run) DRY=1; shift ;;
    --skip-freshness) SKIP_FRESH=1; shift ;;
    --clear) CLEAR=1; shift ;;
    # C2 — --emit takes an OPTIONAL argument. The bare form is resolved below
    # from this script's own WORKSPACE_ROOT (:64) — the identical expression
    # the supervisor uses at session-loop.sh:57 — so the agent never computes
    # the path. The explicit form is retained for the tests and for the
    # supervisor's own bootstrap call (session-loop.sh:139-141), which passes
    # $NEXTF.
    --emit)
      if [ $# -ge 2 ] && case "$2" in -*|"") false ;; *) true ;; esac; then
        EMIT="$2"; shift 2
      else
        EMIT="@auto"; shift
      fi ;;
    -*) die "unknown option: $1" ;;
    *) [ -z "$PROJECT" ] && PROJECT="$1" || die "unexpected argument: $1"; shift ;;
  esac
done
[ -n "$PROJECT" ] || die "usage: launch-next-session.sh <project> [--runtime <rt>] [--bg] [--dry-run] [--emit [<abs-path>]] [--skip-freshness] [--clear]"

# --emit: perform every real-run side effect, then write the command to a file
# instead of exec'ing (spec: "Architecture" -> 2). exec would replace the
# supervisor; --dry-run would skip the counter bump, the options adopt, the lock
# release, and the pending record the successor's register consumes.
if [ "$EMIT" = "@auto" ]; then
  EMIT="$WORKSPACE_ROOT/work/$PROJECT/.next-command"
fi

if [ -n "$EMIT" ]; then
  case "$EMIT" in
    /*) : ;;
    *)  die "--emit requires an absolute path (layer-1 invariant: a relative path lands in the caller's own worktree)" ;;
  esac
  [ "$DRY" -eq 0 ]  || die "--emit cannot be combined with --dry-run (--emit performs the side effects --dry-run refuses)"
  [ "$BG"  -eq 0 ]  || die "--emit cannot be combined with --bg (the supervisor runs the child in the foreground)"
fi

# --clear (ADR-0009): the successor is THIS process after /clear, not a new
# one. Both refusals are decided here, at parse time, so a bad invocation costs
# no side effects — the counter bump is still ahead of us. The claude-only
# check cannot live here: it needs the resolved runtime, so it sits in the
# pre-bump refusal zone after runtime resolution, alongside --bg's own
# claude-only check and the unknown-runtime check.
if [ "$CLEAR" -eq 1 ]; then
  [ -z "$EMIT" ]   || die "--clear cannot be combined with --emit (no new process is started to run the emitted command)"
  [ "$BG" -eq 0 ]  || die "--clear cannot be combined with --bg (the successor is this process, not a background one)"
fi

# Worktree-invoked (issue 05): tracked handoff artifacts (launcher/ledger)
# flow only through git, so before launching make the successor's launch root
# current — verify the worktree's state is committed+pushed, ff-only-pull the
# main checkout, then launch from the main root. Refusals are loud and die
# BEFORE the paste-me prompt: they are precondition failures (like the
# missing-launcher die below), and the human must resolve them.
if [ "$SCRIPT_ROOT" != "$WORKSPACE_ROOT" ]; then
  [ -z "$(git -C "$SCRIPT_ROOT" status --porcelain -uno -- "work/$PROJECT" 2>/dev/null)" ] \
    || die "worktree has uncommitted changes under work/$PROJECT — commit them before relaunch"
  [ -z "$(git -C "$SCRIPT_ROOT" rev-list -n1 HEAD --not --remotes 2>/dev/null)" ] \
    || die "worktree has commits not on any remote — push first (the successor launches from the main checkout)"
  [ -z "$(git -C "$WORKSPACE_ROOT" status --porcelain -uno -- "work/$PROJECT" 2>/dev/null)" ] \
    || die "main checkout has uncommitted changes under work/$PROJECT — resolve them before relaunch"
  # The note belongs INSIDE the guard: --dry-run performs no pull, and a
  # readout claiming a sync that did not happen is the one failure a dry-run
  # cannot afford — the mode exists so the operator can trust it without
  # verifying. Both branches keep the "worktree-invoked" marker the tests match on.
  if [ "$DRY" -eq 0 ]; then
    git -C "$WORKSPACE_ROOT" pull --ff-only -q 2>/dev/null \
      || die "main checkout 'git pull --ff-only' failed (diverged or offline) — sync it manually"
    note "worktree-invoked: main checkout synced; launching from $WORKSPACE_ROOT"
  else
    note "worktree-invoked: dry-run would sync the main checkout, then launch from $WORKSPACE_ROOT"
  fi
  cd "$WORKSPACE_ROOT"
fi

[ -f "$WORKSPACE_ROOT/work/$PROJECT/next-session.md" ] \
  || die "work/$PROJECT/next-session.md not found — run session-rollover first"

# Launcher freshness guard (backlog L33): a successor launched from a stale
# next-session.md resumes an outdated plan (three strikes logged). Refuse to
# launch when any local or remote ref carries a newer commit touching the
# launcher that is not in this checkout's history. Best-effort fetch first so
# lagging remote-tracking refs are visible; fails open when offline or when
# the launcher is untracked. Override: --skip-freshness.
if [ "$SKIP_FRESH" -eq 0 ]; then
  git -C "$WORKSPACE_ROOT" fetch -q --all 2>/dev/null || true
  # A launcher-touching commit reachable from some ref but NOT from HEAD =
  # someone has a launcher edit this checkout lacks (no date comparison —
  # rapid-fire commits share second-resolution timestamps).
  NEWER="$(git -C "$WORKSPACE_ROOT" rev-list -1 --all --not HEAD -- "work/$PROJECT/next-session.md" 2>/dev/null)"
  # Inline ff-only self-heal (rollover-automation-fix): a worktree-invoked
  # launch commits the fresh launcher on its work branch, but the successor
  # launches from the main checkout — background sessions cannot close that
  # gap themselves (classifier / keychain / isolation), so every bg rollover
  # used to die here waiting for a human merge. If the work branch is a CLEAN
  # fast-forward of origin/main, push it to main and re-check; on real
  # divergence fall through to the refusal below (a human must see it).
  # The push must also actually cure the staleness — NEWER reachable from the
  # work branch — else (newest launcher on a third ref) both dry-run and real
  # mode refuse identically instead of pushing and then refusing anyway.
  if [ -n "$NEWER" ] && [ "$SCRIPT_ROOT" != "$WORKSPACE_ROOT" ]; then
    WT_BRANCH="$(git -C "$SCRIPT_ROOT" rev-parse --abbrev-ref HEAD 2>/dev/null)"
    if [ -n "$WT_BRANCH" ] && [ "$WT_BRANCH" != "HEAD" ] \
       && git -C "$SCRIPT_ROOT" merge-base --is-ancestor origin/main "$WT_BRANCH" 2>/dev/null \
       && git -C "$SCRIPT_ROOT" merge-base --is-ancestor "$NEWER" "$WT_BRANCH" 2>/dev/null; then
      if [ "$DRY" -eq 1 ]; then
        note "dry-run: would ff-push origin $WT_BRANCH:main (stale launcher self-heal)"
        NEWER=""
      elif git -C "$SCRIPT_ROOT" push origin "$WT_BRANCH:main" >/dev/null 2>&1; then
        note "stale launcher self-heal: ff-pushed origin $WT_BRANCH:main"
        git -C "$WORKSPACE_ROOT" pull --ff-only -q 2>/dev/null \
          || die "main checkout 'git pull --ff-only' failed after ff-push — sync it manually"
        NEWER="$(git -C "$WORKSPACE_ROOT" rev-list -1 --all --not HEAD -- "work/$PROJECT/next-session.md" 2>/dev/null)"
      else
        note "ff-push origin $WT_BRANCH:main failed — leaving the stale-launcher refusal in place"
      fi
    fi
  fi
  if [ -n "$NEWER" ]; then
    refs="$(git -C "$WORKSPACE_ROOT" branch -a --contains "$NEWER" 2>/dev/null \
      | sed 's/^[* ] //' | head -3 | tr '\n' ' ')"
    die "stale launcher: a newer work/$PROJECT/next-session.md commit (${NEWER:0:12}) exists on: ${refs:-unknown ref} — merge/pull it into this checkout first, or pass --skip-freshness to launch anyway"
  fi
fi

# Relaunch knobs: explicit env > per-item work/$PROJECT/context-budget.env >
# global context-budget.env > built-in default. Sourced here (not at the top)
# because the per-item path needs $PROJECT from the args.
#
# EXCEPTION (TE6 R8): CONTEXT_LOCK_STALE_SECS is GLOBAL-ONLY. The pre-release
# guard below and context-budget.sh (register/release/sweep) must be the SAME
# liveness oracle for one lock, and context-budget.sh reads only the global
# env file — so LOCK_STALE is captured from exactly those sources (explicit
# env > global env file > built-in 10800) BEFORE the per-item file is
# sourced. The per-item file keeps its authority over the ROLLOVER_* knobs,
# which are genuinely launcher-owned per-item policy.
EXPLICIT_RELAUNCH="${ROLLOVER_RELAUNCH:-}"
EXPLICIT_RUNTIME="${ROLLOVER_RUNTIME:-}"
EXPLICIT_STALE="${CONTEXT_LOCK_STALE_SECS:-}"
if [ -f "$WORKSPACE_ROOT/context-budget.env" ]; then
  . "$WORKSPACE_ROOT/context-budget.env" >/dev/null 2>&1 || true
fi
if [ -n "$EXPLICIT_STALE" ]; then
  LOCK_STALE="$EXPLICIT_STALE"
else
  LOCK_STALE="${CONTEXT_LOCK_STALE_SECS:-10800}"
fi
_stale_pre_item="${CONTEXT_LOCK_STALE_SECS:-}"
if [ -f "$WORKSPACE_ROOT/work/$PROJECT/context-budget.env" ]; then
  . "$WORKSPACE_ROOT/work/$PROJECT/context-budget.env" >/dev/null 2>&1 || true
fi
# A knob that quietly does nothing is the defect class this work item is
# about: say so, loudly, when the per-item file tries to move the liveness
# rule to a different value than the one actually in force.
if [ "${CONTEXT_LOCK_STALE_SECS:-}" != "$_stale_pre_item" ] \
   && [ "${CONTEXT_LOCK_STALE_SECS:-}" != "$LOCK_STALE" ]; then
  note "CONTEXT_LOCK_STALE_SECS in work/$PROJECT/context-budget.env is global-only and IGNORED for lock liveness (effective: ${LOCK_STALE}s from env/global/default)"
fi
# TE6 R8 (one oracle), env-inheritance leg: if the operator's shell had
# EXPORTED CONTEXT_LOCK_STALE_SECS, the per-item sourcing above updated the
# exported copy, and an exec'd/--bg successor would inherit the per-item
# value as "explicit env" — which outranks the global file inside
# context-budget.sh. Re-set it to the launcher's own (global-resolution)
# value so any exported copy carries the one oracle's answer.
CONTEXT_LOCK_STALE_SECS="$LOCK_STALE"
[ -n "$EXPLICIT_RELAUNCH" ] && ROLLOVER_RELAUNCH="$EXPLICIT_RELAUNCH"
[ -n "$EXPLICIT_RUNTIME" ] && ROLLOVER_RUNTIME="$EXPLICIT_RUNTIME"
MODE="${ROLLOVER_RELAUNCH:-off}"
FALLBACK_RUNTIME="${ROLLOVER_RUNTIME:-claude}"
CONFIRM_SECS="${ROLLOVER_CONFIRM_SECS:-120}"

# Untracked coordination state can be stranded in a sibling checkout: the
# rolling agent writes work/<proj>/.session-seq (and hand-edits
# .rollover-options) relative to its OWN worktree, where this script never
# used to look (rollover-state-sync-issue). Reconcile at read time across
# every checkout of the repo instead of trusting the main copy. Fails open
# to the main checkout outside a git repo (main is listed first, so it also
# wins mtime ties below).
all_checkouts() {
  git -C "$WORKSPACE_ROOT" worktree list --porcelain 2>/dev/null \
    | sed -n 's/^worktree //p'
  echo "$WORKSPACE_ROOT"   # non-git fallback; the duplicate is harmless
}

# Lineage sequence: work/<proj>/.session-seq holds the last-launched session's
# number (machine-local runtime state, gitignored). Successor = last+1;
# persisted only on a real run (--dry-run never mutates). Absent file means
# the current session is #1.
#
# The main checkout's copy is authoritative (numbering rule 3). Cross-checkout
# max-wins was retired once seq-sync became the counter's only writer: it could
# only ever increase, so an over-count stranded in a worktree was ratified
# forever and no downward correction could land. Strays are now reported, not
# absorbed — a warning a human can act on beats a silent floor.
SEQF="$WORKSPACE_ROOT/work/$PROJECT/.session-seq"
LAST_SEQ=""
if [ -f "$SEQF" ]; then
  LAST_SEQ="$(tr -cd '0-9' < "$SEQF" 2>/dev/null)"
fi
while IFS= read -r co; do
  [ "$co" = "$WORKSPACE_ROOT" ] && continue
  f="$co/work/$PROJECT/.session-seq"
  [ -f "$f" ] || continue
  v="$(tr -cd '0-9' < "$f" 2>/dev/null)"
  [ -n "$v" ] || continue
  note "session-seq: ignoring stray copy $f (holds $v; authoritative is ${LAST_SEQ:-none})"
  note "session-seq: prune it — the agent no longer writes this file by hand (ADR-0008)"
done < <(all_checkouts)

# Lineage gate: at launch time the counter must equal the session number in the
# handoff's top block — the session that just rolled over. A mismatch means the
# counter was written wrong (e.g. an agent wrote the successor's number instead
# of its own — the s102/#104 off-by-one, 2026-08-14); refuse rather than mint a
# phantom lineage number. Skipped when either side is absent/unparseable, so
# projects without a numbered ledger pass trivially — prose is used only to
# VETO a number, never to DERIVE one. Complements ADR-0008: the assertion in
# seq-sync catches a counter that disagrees with the LIVE session; this catches
# one that disagrees with the ledger the successor is about to inherit.
if [ -n "$LAST_SEQ" ]; then
  for HF in "$WORKSPACE_ROOT/work/$PROJECT/handoff.md" \
            "$WORKSPACE_ROOT/work/$PROJECT/session_handoff.md"; do
    [ -f "$HF" ] || continue
    # Number extraction mirrors check-ledger.py's grammar: strip ISO dates
    # first (so "2026" is never read as a session number), then accept
    # "session N" / "session #N" anywhere, or "— N"/"— sN" right after the
    # heading dash (current + sNNN title forms). A heading with no session
    # number yields empty and the gate is skipped — noted below, not silent.
    TOP_LINE="$(grep -m1 -E '^#[[:space:]]*Session Handoff' "$HF" 2>/dev/null || true)"
    TOP_N="$(printf '%s\n' "$TOP_LINE" \
             | sed -E 's/[0-9]{4}-[0-9]{2}-[0-9]{2}//g' \
             | grep -oiE 'session[[:space:]]+#?[0-9]+|^#[[:space:]]*session handoff[[:space:]]*[—-][[:space:]]*s?[0-9]+' \
             | head -1 | grep -oE '[0-9]+' | head -1 || true)"
    if [ -n "$TOP_LINE" ] && [ -z "$TOP_N" ]; then
      note "lineage gate: top ledger heading carries no session number — gate skipped ($HF)"
    fi
    if [ -n "$TOP_N" ] && [ "$LAST_SEQ" != "$TOP_N" ]; then
      die "lineage gate: .session-seq=$LAST_SEQ but $HF top block is session $TOP_N.
The counter must hold the just-rolled-over session's number (launch does the +1).
Fix: scripts/context-budget.sh seq-sync --project $PROJECT --session $TOP_N   (or correct the ledger if IT is wrong), then relaunch."
    fi
    break
  done
fi
# D6 "read my own record" — split (TE6 R1/R2) into the two legs it always
# had, because only one of them may carry authority:
#   env leg  = POSITIVE identity: an exported session id AND a registry
#              record under that exact id (same order as context-budget.sh
#              session_id_for()). The only self-knowledge that cannot be a
#              guess; the authorization guard below keys on this alone.
#   fallback = newest record registered for this project: a HINT for runtime
#              resolution and logging only. It grants and denies nothing —
#              authorization hung on it once and misresolved attended
#              primaries and forked auxes both (registration order is not
#              identity).
env_session_record() {
  local rt sid b
  for rt in claude codex copilot-cli copilot-vscode; do
    case "$rt" in
      claude)      sid="${CLAUDE_CODE_SESSION_ID:-}" ;;
      codex)       sid="${CODEX_THREAD_ID:-}" ;;
      copilot-cli) sid="${COPILOT_AGENT_SESSION_ID:-}" ;;
      copilot-vscode)
        sid=""; if [ -n "${VSCODE_TARGET_SESSION_LOG:-}" ]; then
          b="$(basename "$VSCODE_TARGET_SESSION_LOG")"; sid="${b%.jsonl}"
        fi ;;
    esac
    if [ -n "$sid" ] && [ -f "$STATE_DIR/sessions/$rt-$sid.json" ]; then
      echo "$STATE_DIR/sessions/$rt-$sid.json"; return 0
    fi
  done
  return 1
}
own_record() {
  local f
  env_session_record && return 0
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    if [ "$(jq -r '.project // empty' "$f" 2>/dev/null)" = "$PROJECT" ]; then
      echo "$f"; return 0
    fi
  done < <(ls -t "$STATE_DIR/sessions/"*.json 2>/dev/null)
  return 1
}

OWN_ENV_REC="$(env_session_record)" || OWN_ENV_REC=""
DYING_SID=""
REC="$(own_record)" || REC=""
if [ -n "$REC" ]; then
  DYING_SID="$(jq -r '.session_id // empty' "$REC" 2>/dev/null)"
  recproj="$(jq -r '.project // empty' "$REC" 2>/dev/null)"
  [ -n "$recproj" ] && [ "$recproj" != "$PROJECT" ] \
    && note "warning: your session record is for project '$recproj', launching for '$PROJECT'"
  [ -n "$RUNTIME" ] || RUNTIME="$(jq -r '.runtime // empty' "$REC" 2>/dev/null)"
fi
if [ -z "$RUNTIME" ]; then
  RUNTIME="$FALLBACK_RUNTIME"
  note "no session record found; falling back to ROLLOVER_RUNTIME=$RUNTIME"
fi

# --emit x copilot-vscode (TE6 A5): `code chat` is detached BY NATURE — the
# launch paths force BG=1 for this runtime AFTER the parse-time --emit/--bg
# check, so that check cannot see it. The supervisor runs the emitted line in
# the FOREGROUND and waits on it; a command that returns at once reads as
# delta 0 / deliberate quit, the marker is deleted, and the real session runs
# unsupervised (the 2026-08-27 --bg bug in a second costume). Same shape as
# the --bg claude-only refusal below, but decided HERE, at the first point
# the runtime is resolved and before the authorization guard and the counter
# bump, so the refusal costs no side effects (TE6 R3).
if [ -n "$EMIT" ] && [ "$RUNTIME" = "copilot-vscode" ]; then
  die "--emit cannot be combined with runtime=copilot-vscode ('code chat' is detached by nature — the supervisor waits on the emitted command in the foreground and would read its instant return as a deliberate quit); run the chain with an attached runtime"
fi

# Runtime-conditioned refusals, decided HERE in the pre-bump refusal zone
# (s15 follow-on (a)): $RUNTIME is fully resolved above (flag -> record ->
# fallback), so every refusal that depends on it is taken before the counter
# bump — a refusal costs no side effects: no bump, no seed, no lock release,
# no superseded stamp. These used to sit at their enforcement points below the
# bump, from when RUNTIME resolved late; that rationale is gone (TE6 R3).
#
# --clear needs /clear and the SessionStart seed hook — Claude Code features.
if [ "$CLEAR" -eq 1 ] && [ "$RUNTIME" != "claude" ]; then
  die "--clear is claude-only (/clear and the SessionStart seed hook are Claude Code features); runtime=$RUNTIME"
fi
# Explicit --bg on a runtime with no background mode. Decided on the
# parse-time flag alone: the two mode-DERIVED BG=1 assignments below (auto +
# claude, and copilot-vscode's detached launch) only ever apply to the two
# exempt runtimes — any future derivation for another runtime must add it to
# this exemption list.
if [ "$BG" -eq 1 ] && [ "$RUNTIME" != "claude" ] && [ "$RUNTIME" != "copilot-vscode" ]; then
  die "--bg (background launch) is claude-only (ADR-0003); runtime=$RUNTIME"
fi
# Valid-runtime enumeration: MUST match the arms of the launch
# `case "$RUNTIME"` statement below (whose `*)` die is now an unreachable
# backstop) — keep the two lists in sync.
case "$RUNTIME" in
  claude|codex|gemini|opencode|copilot|copilot-cli|copilot-vscode) : ;;
  *) die "unknown runtime: $RUNTIME" ;;
esac

LOCK="$WORKSPACE_ROOT/work/$PROJECT/.active-session"

# Pre-release authorization guard (TE6 R1/R3/R4) — the DECISION, hoisted
# above the counter bump so that a refusal costs nothing: no bump, no seed,
# no lock touched, no record stamped, and the primary's next legitimate
# rollover needs no repair step. The release ACTION stays downstream (it must
# not run for --clear, and its place before the launch paths is
# load-bearing); the window between decision and action is straight-line code
# with no waits. Skipped on --dry-run, which releases nothing and so has
# nothing to protect.
#
# Both helpers are deliberate copies of context-budget.sh
# (lock_holder_age :436, sweep_child_locks :708) — same liveness rule
# (artifact mtime vs LOCK_STALE; unknowable = stale); keep them in sync.
lock_holder_age() {
  local rt="$1" sid="$2" af mt
  af=$(jq -r '.artifact // empty' "$STATE_DIR/sessions/$rt-$sid.json" 2>/dev/null)
  [ -n "$af" ] && [ -f "$af" ] || return 1
  mt=$(stat -f%m "$af" 2>/dev/null || stat -c%Y "$af" 2>/dev/null) || return 1
  echo $(( $(date +%s) - mt ))
}
sweep_child_locks() {
  local lockdir="$WORKSPACE_ROOT/work/$PROJECT/.agent-locks" f crt csid age
  LIVE_CHILD_LOCKS=""
  [ -d "$lockdir" ] || return 0
  for f in "$lockdir"/*.json; do
    [ -f "$f" ] || continue
    crt=$(jq -r '.runtime // empty' "$f" 2>/dev/null)
    csid=$(jq -r '.session_id // empty' "$f" 2>/dev/null)
    if age=$(lock_holder_age "$crt" "$csid") && [ "$age" -lt "$LOCK_STALE" ]; then
      LIVE_CHILD_LOCKS="$LIVE_CHILD_LOCKS$f
"
    else
      rm -f "$f"; note "lock: swept stale child lock ${f##*/}"
    fi
  done
}

if [ "$DRY" -eq 0 ] && [ -f "$LOCK" ]; then
  hrt=$(jq -r '.runtime // empty' "$LOCK" 2>/dev/null)
  hsid=$(jq -r '.session_id // empty' "$LOCK" 2>/dev/null)
  # Guard (a) — identity x liveness (TE6 R1): a POSITIVELY-identified session
  # that is not the recorded holder must not delete a live holder's lock.
  # Role is never consulted — auxiliary, superseded, an anomalous second
  # primary all refuse identically, because the predicate is the invariant
  # itself, not an allowlist of ways to violate it. Self, a stale/dead/
  # unknowable holder, or no positive identity (the D4 fork and the attended
  # human terminal): release proceeds — the rollover is the authority (C5).
  if [ -n "$OWN_ENV_REC" ]; then
    own_b="${OWN_ENV_REC##*/}"; own_key="${own_b%.json}"
    if [ "$own_key" != "$hrt-$hsid" ] \
       && age=$(lock_holder_age "$hrt" "$hsid") && [ "$age" -lt "$LOCK_STALE" ]; then
      die "lock: work/$PROJECT/.active-session is held by LIVE session $hrt-$hsid (artifact active ${age}s ago) and this session is positively $own_key — refusing to release another session's live lock (one primary per work item). Roll over from the holding session instead."
    fi
  fi
  # Guard (b) — I4 release order, same sweep as context-budget.sh cmd_release:
  # stale child locks are swept (idempotent hygiene, the guard's only side
  # effect), any LIVE child lock blocks the project-lock release (lock
  # authority moves at rollover; lock ordering does not).
  #
  # NOT applied on --clear (TE6 R4 verifier finding): I4 exists to protect
  # the project-lock RELEASE from outliving live child locks, and --clear
  # releases nothing — it exits before the release action, and the surviving
  # process keeps its lock and its children. Guard (a) above still applies.
  if [ "$CLEAR" -eq 0 ]; then
    sweep_child_locks
    [ -z "${LIVE_CHILD_LOCKS:-}" ] \
      || die "lock: refusing pre-launch release — live child locks in work/$PROJECT/.agent-locks: $(printf '%s' "$LIVE_CHILD_LOCKS" | while IFS= read -r f; do printf '%s ' "${f##*/}"; done). Close/release the children first (context-budget.sh release from each), then relaunch."
  fi
fi

# Counter bump — the FIRST write; everything that can say "no" already has
# (TE6 R3).
[ -n "$LAST_SEQ" ] || LAST_SEQ=1
SEQ=$((LAST_SEQ + 1))
[ "$DRY" -eq 0 ] && printf '%s\n' "$SEQ" > "$SEQF"

# The canonical bootstrap prompt (ADR-0003: wording is load-bearing, verbatim).
PROMPT="Work item $PROJECT - rollover session #$SEQ. Read \`work/$PROJECT/next-session.md\` and continue from **First actions**."

# Successor option inheritance: persist-and-replay from the work item
# (.rollover-options, written at rollover; see docs/context-budget.md).
OPT_ARGS=()
OPTF="$WORKSPACE_ROOT/work/$PROJECT/.rollover-options"
# Same stranding as .session-seq: the newest copy across checkouts wins,
# and an adopted copy is persisted to the main checkout so it survives
# worktree pruning. --dry-run reads the newest copy in place instead.
OPT_NEWEST=""
while IFS= read -r co; do
  f="$co/work/$PROJECT/.rollover-options"
  [ -f "$f" ] || continue
  if [ -z "$OPT_NEWEST" ] || [ "$f" -nt "$OPT_NEWEST" ]; then OPT_NEWEST="$f"; fi
done < <(all_checkouts)
if [ -n "$OPT_NEWEST" ] && [ "$OPT_NEWEST" != "$OPTF" ]; then
  if [ "$DRY" -eq 1 ]; then
    note "dry-run: would adopt .rollover-options from $OPT_NEWEST"
    OPTF="$OPT_NEWEST"
  elif cp "$OPT_NEWEST" "$OPTF" 2>/dev/null; then
    note "rollover-options: adopted newest copy from $OPT_NEWEST"
  fi
fi
if [ -f "$OPTF" ]; then
  ROLLOVER_OPT_APPROVAL=""; ROLLOVER_OPT_MODEL=""; ROLLOVER_OPT_EXTRA=""
  . "$OPTF" >/dev/null 2>&1 || true
  case "${ROLLOVER_OPT_APPROVAL:-}" in
    ""|default) : ;;
    edits)
      case "$RUNTIME" in
        claude) OPT_ARGS+=(--permission-mode acceptEdits) ;;
        codex) OPT_ARGS+=(--ask-for-approval never) ;;
        gemini) OPT_ARGS+=(--approval-mode auto_edit) ;;
        opencode) OPT_ARGS+=(--auto) ;;
        copilot|copilot-cli) OPT_ARGS+=(--allow-all-tools) ;;
      esac ;;
    auto)
      case "$RUNTIME" in
        claude) OPT_ARGS+=(--permission-mode auto) ;;
        codex)
          note "runtime=codex has no classifier mode — falling back to nearest level (edits)"
          OPT_ARGS+=(--ask-for-approval never) ;;
        gemini)
          note "runtime=gemini has no classifier mode — falling back to nearest level (edits)"
          OPT_ARGS+=(--approval-mode auto_edit) ;;
        opencode)
          note "runtime=opencode has no classifier mode — falling back to nearest level (edits)"
          OPT_ARGS+=(--auto) ;;
        copilot|copilot-cli)
          note "runtime=$RUNTIME has no classifier mode — falling back to nearest level (edits)"
          OPT_ARGS+=(--allow-all-tools) ;;
      esac ;;
    full)
      case "$RUNTIME" in
        claude) OPT_ARGS+=(--dangerously-skip-permissions) ;;
        codex) OPT_ARGS+=(--dangerously-bypass-approvals-and-sandbox) ;;
        gemini) OPT_ARGS+=(--yolo) ;;
        opencode) OPT_ARGS+=(--auto) ;;
        copilot|copilot-cli) OPT_ARGS+=(--allow-all) ;;
      esac ;;
    *) note "unknown ROLLOVER_OPT_APPROVAL='$ROLLOVER_OPT_APPROVAL' — ignoring" ;;
  esac
  [ -n "${ROLLOVER_OPT_MODEL:-}" ] && OPT_ARGS+=(--model "$ROLLOVER_OPT_MODEL")
  # shellcheck disable=SC2206 — deliberate word-split escape hatch
  [ -n "${ROLLOVER_OPT_EXTRA:-}" ] && OPT_ARGS+=($ROLLOVER_OPT_EXTRA)
fi

# Every mode prints the paste-me prompt first — it must survive launch failure.
printf 'Bootstrap prompt (paste into the successor if needed):\n----\n%s\n----\n' "$PROMPT"

# --clear: in-place relaunch (ADR-0009, closing issue 04). Everything above
# still applies — the freshness guard, the counter bump, the canonical prompt
# wording. What changes is the handover: instead of spawning a process we drop
# a seed marker that the SessionStart hook (scripts/hooks/rollover-clear-seed.sh)
# drains into the cleared context, so the human presses /clear and types
# nothing.
#
# The claude-only refusal is no longer here: it is decided in the pre-bump
# refusal zone (with --bg's claude-only check and the unknown-runtime check),
# so a refused --clear costs no counter bump and no seed. This block's own
# placement is still load-bearing: it is AFTER the counter bump and the
# paste-me prompt, BEFORE the lock release and the superseded stamp, and it exits:
# neither may run on this path. The process survives /clear, so its registry
# record is still live and its lock is still correctly held; `register` re-fires
# from the SessionStart hook and reconciles the new session id itself. Stamping
# the record superseded here would mark a session dead that is still running.
# No successor-pending handshake file is written either: no second process
# starts, so there is no second register call to consume one.
#
# It also exits before the MODE=off branch, deliberately: --clear is an
# explicit human invocation, and ROLLOVER_RELAUNCH=off means "do not spawn a
# successor behind my back", which is not what this does.
if [ "$CLEAR" -eq 1 ]; then
  SEED="$WORKSPACE_ROOT/work/$PROJECT/.pending-clear-seed"
  if [ "$DRY" -eq 1 ]; then
    echo "project=$PROJECT runtime=$RUNTIME mode=clear seq=$SEQ (dry-run: counter NOT bumped, no seed written)"
    exit 0
  fi
  printf '%s\n' "$PROMPT" > "$SEED" || die "could not write seed marker: $SEED"
  echo "project=$PROJECT runtime=$RUNTIME mode=clear seq=$SEQ seed=$SEED"
  note "the prompt above is seeded automatically — NOW PRESS /clear and type nothing."
  note "if you do NOT clear, the counter is already at $SEQ; rewind with:"
  note "  scripts/context-budget.sh seq-sync --project $PROJECT --session $LAST_SEQ"
  exit 0
fi

# --emit hands the command to a supervisor that runs it in the FOREGROUND and
# waits on it, so no mode-derived backgrounding may reach the emitted line. The
# explicit --bg is refused above, but that guard runs before this assignment:
# without the [ -z "$EMIT" ] clause, ROLLOVER_RELAUNCH=auto + runtime=claude
# slips --bg into the emitted command, session-loop.sh evals something that
# returns at once, and it reads the missing sentinel as a deliberate quit
# (found 2026-08-27, starting a supervised chain on a fresh work item).
[ -z "$EMIT" ] && [ "$MODE" = "auto" ] && [ "$RUNTIME" = "claude" ] && BG=1
# copilot-vscode's `code chat` is detached by nature (exits before the seeded
# session responds — issue 01) — always confirm the successor via the BG loop.
# An explicit --bg on any other runtime was refused in the pre-bump refusal
# zone; these two derivations only ever set BG=1 for the runtimes that zone
# exempts — a derivation for a new runtime must extend its exemption list.
[ "$RUNTIME" = "copilot-vscode" ] && BG=1

echo "project=$PROJECT runtime=$RUNTIME mode=$MODE bg=$BG"

# Release the dying session's own work-item lock BEFORE any launch path: with
# auto-relaunch the successor's register races an unreleased lock (and the
# attached-manual path execs below, so nothing can release afterwards).
#
# C5 — at rollover, the rollover is the authority (design.md §3). The lock is
# released regardless of the recorded holder's session id, logging the
# previous holder by name — including when a fork gave the caller a new
# session id (D4), in which case an id-equality rule could never be satisfied
# and the successor would race an unreleased lock. The DECISION that this
# release is authorized was taken by the identity x liveness guard above,
# BEFORE the counter bump; from here on the release is the unconditional
# action that decision permitted.
if [ "$DRY" -eq 0 ] && [ -f "$LOCK" ]; then
  hrt=$(jq -r '.runtime // empty' "$LOCK" 2>/dev/null)
  hsid=$(jq -r '.session_id // empty' "$LOCK" 2>/dev/null)
  drt=""; [ -n "$REC" ] && drt=$(jq -r '.runtime // empty' "$REC" 2>/dev/null)
  rm -f "$LOCK"
  if [ -n "$DYING_SID" ] && [ "$hrt-$hsid" = "$drt-$DYING_SID" ]; then
    note "lock: released work/$PROJECT/.active-session (pre-launch; successor's register re-acquires)"
  else
    note "lock: released work/$PROJECT/.active-session (pre-launch; recorded holder $hrt-$hsid — rollover authority)"
  fi
  # The dying session's primary role ends here: stamp its registry record
  # superseded so listings and attach-session.sh never mistake it for a
  # usable session (the successor's own register becomes the new primary).
  # Stamp ONLY the record that is provably the dying session's (TE6 R2):
  # env-resolved (it is the caller's own), or the fallback record whose
  # session_id matches the released holder's (the D4 fork — the fallback
  # found the actual dying primary). A fallback record matching neither is
  # somebody else's live session — leave it alone; the registry's own hygiene
  # (backstamp_superseded, sweep_stale_primaries) covers stragglers at the
  # successor's register.
  if [ -n "$REC" ] && [ -f "$REC" ] \
     && { [ -n "$OWN_ENV_REC" ] || { [ -n "$DYING_SID" ] && [ "$DYING_SID" = "$hsid" ]; }; }; then
    jq --arg ts "$(date -u +%FT%TZ)" '.role="superseded" | .superseded_at=$ts' \
      "$REC" > "$REC.tmp" && mv "$REC.tmp" "$REC"
    note "role: $drt-$DYING_SID stamped superseded"
  fi
fi

# The [ -z "$EMIT" ] clause (TE6 A4): --emit stages a command for a
# supervisor and launches nothing itself, so mode=off has nothing to refuse —
# "off" means "do not LAUNCH a successor", and the staging path never does.
# Without the clause, --emit under a committed off exits 0 here having staged
# nothing: the supervisor bootstrap's `--emit "$NEXTF" || halt` in
# session-loop.sh never fires its halt, and the chain dissolves later with a
# fabricated story.
# (Refusing off + --emit at parse time was considered and rejected: the
# supervisor's own bootstrap call must keep working under a committed off.)
if [ "$MODE" = "off" ] && [ -z "$EMIT" ]; then
  note "ROLLOVER_RELAUNCH=off — not launching; paste the prompt above manually"
  exit 0
fi

case "$RUNTIME" in
  claude)   CMD=(claude --name "$PROJECT #$SEQ"); [ "$BG" -eq 1 ] && CMD+=(--bg)
            CMD+=(${OPT_ARGS[@]+"${OPT_ARGS[@]}"} "$PROMPT") ;;
  codex)    CMD=(codex ${OPT_ARGS[@]+"${OPT_ARGS[@]}"} "$PROMPT") ;;
  gemini)   CMD=(gemini ${OPT_ARGS[@]+"${OPT_ARGS[@]}"} -i "$PROMPT") ;;
  opencode) CMD=(opencode ${OPT_ARGS[@]+"${OPT_ARGS[@]}"} --prompt "$PROMPT") ;;
  copilot|copilot-cli) CMD=(copilot ${OPT_ARGS[@]+"${OPT_ARGS[@]}"} -i "$PROMPT") ;;
  copilot-vscode)
    # Verified (issue 01, session 28): opens a NEW agent session in the
    # last-active VS Code window and returns immediately.
    CMD=(code chat ${OPT_ARGS[@]+"${OPT_ARGS[@]}"} -r -m agent "$PROMPT") ;;
  # Backstop: the pre-bump valid-runtime enumeration already refused any
  # runtime not in these arms — keep the two lists in sync. Not strictly
  # unreachable: sourcing .rollover-options (above) runs after that zone and
  # an out-of-contract RUNTIME= line there lands here, post-bump.
  *) die "unknown runtime: $RUNTIME" ;;
esac

if [ "$DRY" -eq 1 ]; then
  echo "cmd: $(printf '%q ' "${CMD[@]}" | sed 's/ $//')"
  exit 0
fi

# Registration handshake (rollover-automation-fix): the successor's
# SessionStart hook runs `context-budget.sh register` with no --project (it
# cannot know the work item at session start), so its record used to carry
# project:"" — making the --bg confirm poll below undecidable and degrading
# lock attribution/release. Drop a pending file the successor's register
# consumes (freshest non-expired wins; TTL enforced there). A file, not an
# env var: it must survive `claude --bg` daemonization, and works identically
# for attached launches on every runtime. Written ONLY at the two points that
# actually start a successor (bg launch, attached exec) and removed if the bg
# launch dies — no pending file may exist unless a successor was actually
# started (a consumer of a launch-less file would take the project's primary
# lock; the non-tty branch below prints the command and exits, launching
# nothing, so a successor started from that printout registers project-less).
PENDING="$STATE_DIR/successor-pending-$PROJECT.json"
write_pending() {
  mkdir -p "$STATE_DIR"
  jq -n --arg proj "$PROJECT" --argjson seq "$SEQ" --arg ts "$(date -u +%FT%TZ)" \
    '{project:$proj, seq:$seq, launched_at:$ts}' > "$PENDING"
  note "handshake: wrote ${PENDING#"$WORKSPACE_ROOT/"} for the successor's register"
}

# --emit: the supervisor treats the appearance of $EMIT as the signal that a
# successor is fully staged, so write_pending must already have run when it
# appears. Sits after write_pending's definition (it calls it) and before the
# --bg block (which --emit refuses).
if [ -n "$EMIT" ]; then
  write_pending
  # C3 — temp file + mv, both status-checked, then assert the target is
  # non-empty. write_pending IS rolled back on failure: the --bg path below
  # already does exactly this, and leaving a pending record for a successor
  # that was never staged is the same defect that rollback was written to
  # prevent. The counter is NOT auto-rewound — seq-sync is max-wins and
  # ADR-0008 governed, so the remedy is named rather than performed.
  emit_tmp="$EMIT.tmp.$$"
  emit_fail() {
    rm -f "$emit_tmp" "$PENDING"
    die "emit: could not stage the successor at $EMIT ($1); the counter advanced to $SEQ; if you retry, rewind first with scripts/context-budget.sh seq-sync --project $PROJECT --session $((SEQ - 1))"
  }
  printf '%s\n' "$(printf '%q ' "${CMD[@]}" | sed 's/ $//')" > "$emit_tmp" \
    || emit_fail "write failed"
  mv "$emit_tmp" "$EMIT" || emit_fail "mv failed"
  [ -s "$EMIT" ] || emit_fail "target missing or empty after write"
  note "emit: wrote the successor command to $EMIT"
  exit 0
fi

if [ "$BG" -eq 1 ]; then
  PRE_EXISTING=" $(ls "$STATE_DIR/sessions/" 2>/dev/null | tr '\n' ' ') "
  write_pending
  "${CMD[@]}" || { rm -f "$PENDING"; die "launch failed: ${CMD[*]}"; }
  deadline=$(( $(date +%s) + CONFIRM_SECS ))
  while [ "$(date +%s)" -lt "$deadline" ]; do
    for f in "$STATE_DIR/sessions/"*.json; do
      [ -f "$f" ] || continue
      case "$PRE_EXISTING" in *" $(basename "$f") "*) continue ;; esac
      proj="$(jq -r '.project // empty' "$f" 2>/dev/null)"
      sid="$(jq -r '.session_id // empty' "$f" 2>/dev/null)"
      if [ "$proj" = "$PROJECT" ] && [ -n "$sid" ] && [ "$sid" != "$DYING_SID" ]; then
        echo "successor=confirmed session=$sid"
        exit 0
      fi
    done
    sleep 2
  done
  # Fallback (rollover-automation-fix): hooks disabled or handshake missed —
  # a NEW but project-less record inside the window is almost certainly the
  # successor (the .project match above stays primary; this only softens the
  # verdict from unconfirmed to probable).
  PROBABLE=""
  for f in "$STATE_DIR/sessions/"*.json; do
    [ -f "$f" ] || continue
    case "$PRE_EXISTING" in *" $(basename "$f") "*) continue ;; esac
    proj="$(jq -r '.project // empty' "$f" 2>/dev/null)"
    sid="$(jq -r '.session_id // empty' "$f" 2>/dev/null)"
    if [ -z "$proj" ] && [ -n "$sid" ] && [ "$sid" != "$DYING_SID" ]; then
      PROBABLE="$sid"
    fi
  done
  if [ -n "$PROBABLE" ]; then
    note "a new project-less session registered in the window — handshake missed, treating as the successor"
    echo "successor=probable session=$PROBABLE"
    exit 0
  fi
  note "successor did not register within ${CONFIRM_SECS}s — check 'claude attach' / the sessions dir"
  echo "successor=unconfirmed"
  exit 0
fi

# manual / attached: exec only on a real terminal; from an agent tool-shell,
# print the ready-to-run command instead (relaunch-analysis: "print the
# ready-to-run command (others)").
if [ -t 0 ] && [ -t 1 ]; then
  write_pending
  exec "${CMD[@]}"
else
  note "not an interactive terminal — run this in one:"
  echo "run: $(printf '%q ' "${CMD[@]}" | sed 's/ $//')"
  exit 0
fi
