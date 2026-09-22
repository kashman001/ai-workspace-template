#!/usr/bin/env bash
# File: scripts/attach-session.sh
# Purpose: Re-attach step of session-rollover (ADR-0003) for chained claude
#          successors: find the latest session for a work item and, when it
#          is alive and holds the work-item lock, connect this terminal to
#          it. Resolution: the owner named by work/<project>/session-state.json
#          (its `session` block, alive while its pid is — ADR-0010; read via
#          scripts/lib/session-lib.sh; corrected for a fork that re-keyed the
#          owning session — see fork_of() below) >
#          newest .context-budget/sessions/*.json record for the project
#          (fallback, same convention as own_record() in
#          launch-next-session.sh) > newest live `claude agents --json` entry
#          whose `name` matches the launcher's "<project> #<N>" convention
#          (last resort for a session that registered project-less — see the
#          note at the fallback) > none.
# Usage:   attach-session.sh <project> [--dry-run]
# Exit:    0 handled (attached, printed command, or informative no-op) /
#          3 error (bad args, no session known). Requires jq.
# Vendor flags re-verified against live claude 2.1.226 on 2026-08-20:
# `claude attach <id>` DOES now exist ("Open the background session in this
# terminal") and supersedes the 2026-08-06 note that it did not. It is valid
# ONLY for a background session — the kind the launcher's --bg creates.
# `claude agents --json` keys sessions by `sessionId` and distinguishes them
# with `kind` ("background" | "interactive"); this script reads that field and
# picks: attach for background, `-r/--resume` otherwise (resume replays a
# transcript into a NEW process, so it is the wrong verb for a live background
# session and the right one for anything else). Re-verify before changing
# (ADR-0003: a nonexistent flag already slipped in once).

set -u

# Workspace identity = repository identity, not checkout path (issue 05):
# resolve through git's common dir so worktree invocations converge on the
# main checkout's state. Fallback: script-relative root (non-git workspace).
resolve_workspace_root() {  # $1 = script-relative candidate root
  local root common repo
  root="$(cd "$1" && pwd -P)"
  if common="$(git -C "$root" rev-parse --git-common-dir 2>/dev/null)"; then
    case "$common" in /*) : ;; *) common="$root/$common" ;; esac
    repo="$(cd "$common/.." 2>/dev/null && pwd -P)"
    if [ -n "$repo" ] && [ -f "$repo/scripts/attach-session.sh" ]; then
      printf '%s' "$repo"; return
    fi
  fi
  printf '%s' "$root"
}
WORKSPACE_ROOT="$(resolve_workspace_root "$(dirname "$0")/..")"
STATE_DIR="$WORKSPACE_ROOT/.context-budget"
. "$WORKSPACE_ROOT/scripts/lib/session-lib.sh" || { echo "error: scripts/lib/session-lib.sh missing" >&2; exit 3; }

if [ -z "${CONTEXT_LOCK_STALE_SECS:-}" ] && [ -f "$WORKSPACE_ROOT/context-budget.env" ]; then
  . "$WORKSPACE_ROOT/context-budget.env" >/dev/null 2>&1 || true
fi
LOCK_STALE="${CONTEXT_LOCK_STALE_SECS:-10800}"

note() { echo "$@" >&2; }
die()  { echo "error: $*" >&2; exit 3; }

PROJECT=""; DRY=0
while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run) DRY=1; shift ;;
    -*) die "unknown option: $1" ;;
    *) [ -z "$PROJECT" ] && PROJECT="$1" || die "unexpected argument: $1"; shift ;;
  esac
done
[ -n "$PROJECT" ] || die "usage: attach-session.sh <project> [--dry-run]"

command -v jq >/dev/null 2>&1 || die "jq is required"

# Resolution: the item's record first (its open `session` block is the owner;
# LOCKED=1 keeps the old name for the output shape), else the newest registry
# record for the project (fallback — same convention as own_record() in
# launch-next-session.sh, minus its env-var self-identification, which does
# not apply here: we want the project's latest session, not "my own").
RUNTIME=""; SID=""; LOCKED=0; OWNER=""
if OWNER="$(session_record_owner "$WORKSPACE_ROOT/work/$PROJECT/session-state.json")"; then
  RUNTIME="$(printf '%s' "$OWNER" | jq -r '.runtime // empty' 2>/dev/null)"
  SID="$(printf '%s' "$OWNER" | jq -r '.session_id // empty' 2>/dev/null)"
  [ -n "$RUNTIME" ] && [ -n "$SID" ] && LOCKED=1
fi
# A fork (Claude's SessionStart:fork) RE-KEYS a live session: the transcript
# moves to a new session id and `record` self-heals onto it, but the record may
# still name the pre-fork id. Because the record resolves first, the naming step below
# — which would have found the live session — never got a chance to run, so the
# script printed a `--resume` for a dead id. The fork inherits the launcher's
# `-n "<project> #<N>"` name, so an entry sharing that exact name with a strictly
# later start IS the fork of the owning session, not a different one. Adopt it:
# the item is still validly owned (a fork is the same logical session), only its
# id moved. Positive evidence only — no oracle, no name, no timestamps, or any
# jq/CLI failure all leave the owner's id exactly as it was.
fork_of() {  # $1 = session id -> id of the fork that superseded it, or empty
  claude agents --json 2>/dev/null | jq -r --arg s "$1" '
      (map(select(.sessionId == $s)) | .[0]) as $h
      | if ($h | type) != "object" then ""
        elif (($h.name // "") == "") or (($h.startedAt | type) != "number") then ""
        else ( map(select((.name // "") == $h.name
                          and (.startedAt | type) == "number"
                          and .startedAt > $h.startedAt))
               | sort_by(.startedAt) | .[-1].sessionId // "" )
        end' 2>/dev/null
}
if [ "$LOCKED" -eq 1 ] && [ "$RUNTIME" = "claude" ]; then
  FORK="$(fork_of "$SID")" || FORK=""
  if [ -n "$FORK" ] && [ "$FORK" != "$SID" ]; then
    note "record names $SID, which a fork superseded; following it to $FORK (same session, re-keyed)"
    SID="$FORK"
  fi
fi

if [ "$LOCKED" -eq 0 ]; then
  RUNTIME=""; SID=""
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    if [ "$(jq -r '.project // empty' "$f" 2>/dev/null)" = "$PROJECT" ]; then
      RUNTIME="$(jq -r '.runtime // empty' "$f" 2>/dev/null)"
      SID="$(jq -r '.session_id // empty' "$f" 2>/dev/null)"
      break
    fi
  done < <(ls -t "$STATE_DIR/sessions/"*.json 2>/dev/null)
fi
# Third resolution step. The two above depend on state the session must write
# about itself: the item's record, and `project` in its budget record. The registration
# handshake normally supplies it, but it cannot in every case — the launcher's
# own note records that a successor started from the printed command (the
# non-tty branch, which launches nothing) still registers project-less, and so
# does any session predating the handshake. Such a session owns no item and
# matches no record. Fall back to the launcher's OWN naming: it starts every
# successor with `-n "<project> #<N>"`, which `claude agents --json` reports as
# `name`, so a live session stays discoverable. Newest start wins. Claude-only,
# like --bg itself.
if [ -z "$RUNTIME" ] || [ -z "$SID" ]; then
  SID="$(claude agents --json 2>/dev/null \
         | jq -r --arg p "$PROJECT" \
             'map(select(.name // "" | startswith($p + " #")))
              | sort_by(.startedAt) | reverse | .[0].sessionId // ""' 2>/dev/null)"
  [ -n "$SID" ] && RUNTIME="claude"
fi

[ -n "$RUNTIME" ] && [ -n "$SID" ] || die "no session known for work/$PROJECT"

# Liveness: the owner is alive while its pid is (session_owner_live, ADR-0010;
# a pid-less owner falls back to its artifact's age vs LOCK_STALE). A session
# found through the fallbacks has no pid on record, so it keeps the artifact-
# age rule — mirror of lock_holder_age() in scripts/context-budget.sh (NOT
# sourced here, it dispatches a command on execution). `age` is reported
# either way, for the human reading the line.
AGE=""; LIVE="no"
REC="$STATE_DIR/sessions/$RUNTIME-$SID.json"
if [ "$LOCKED" -eq 1 ]; then
  session_owner_live "$OWNER" "$LOCK_STALE" && LIVE="yes"
  AF="$(printf '%s' "$OWNER" | jq -r '.artifact // empty' 2>/dev/null)"
else
  AF="$(jq -r '.artifact // empty' "$REC" 2>/dev/null)"
fi
if [ -n "$AF" ] && [ -f "$AF" ]; then
  MT="$(stat -f%m "$AF" 2>/dev/null || stat -c%Y "$AF" 2>/dev/null)" || MT=""
  if [ -n "$MT" ]; then
    AGE=$(( $(date +%s) - MT ))
    [ "$LOCKED" -eq 0 ] && [ "$AGE" -lt "$LOCK_STALE" ] && LIVE="yes"
  fi
fi

# Role: the record's owner is primary; otherwise the session record's cached
# role claim (auxiliary/superseded), else none.
ROLE="none"
if [ "$LOCKED" -eq 1 ]; then
  ROLE="primary"
elif [ -f "$REC" ]; then
  ROLE="$(jq -r '.role // "none"' "$REC" 2>/dev/null)"
fi

echo "project=$PROJECT runtime=$RUNTIME session=$SID role=$ROLE age=${AGE:-unknown}${AGE:+s} live=$LIVE locked=$([ "$LOCKED" -eq 1 ] && echo yes || echo no)"

if [ "$LIVE" != "yes" ] || [ "$LOCKED" -ne 1 ]; then
  if [ "$LIVE" = "yes" ]; then
    note "session is live but does not hold the work-item lock — not attaching; run: scripts/launch-next-session.sh $PROJECT"
  else
    note "no live session — run: scripts/launch-next-session.sh $PROJECT"
  fi
  exit 0
fi

if [ "$RUNTIME" != "claude" ]; then
  note "cannot attach — $RUNTIME has no background sessions (launcher --bg is claude-only); the session is already interactive in someone's terminal"
  exit 0
fi

# `claude attach` connects this terminal to the RUNNING background session;
# `--resume` would instead replay the transcript into a new process. Pick by
# the session's own `kind`, and fall back to resume on any older CLI that has
# no attach subcommand.
KIND="$(claude agents --json 2>/dev/null \
        | jq -r --arg s "$SID" 'map(select(.sessionId == $s)) | .[0].kind // ""' 2>/dev/null)"
if [ "$KIND" = "background" ] && claude attach --help >/dev/null 2>&1; then
  CMD=(claude attach "$SID")
else
  CMD=(claude --resume "$SID")
fi

if [ "$DRY" -eq 1 ] || { [ ! -t 0 ] || [ ! -t 1 ]; }; then
  echo "run: $(printf '%q ' "${CMD[@]}" | sed 's/ $//')"
  exit 0
fi

exec "${CMD[@]}"
