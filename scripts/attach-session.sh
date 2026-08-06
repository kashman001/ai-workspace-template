#!/usr/bin/env bash
# File: scripts/attach-session.sh
# Purpose: Re-attach step of session-rollover (ADR-0003) for chained claude
#          successors: find the latest session for a work item and, when it
#          is alive and holds the work-item lock, connect this terminal to
#          it. Resolution: work/<project>/.active-session lock >
#          newest .context-budget/sessions/*.json record for the project
#          (fallback, same convention as own_record() in
#          launch-next-session.sh) > none.
# Usage:   attach-session.sh <project> [--dry-run]
# Exit:    0 handled (attached, printed command, or informative no-op) /
#          3 error (bad args, no session known). Requires jq.
# Vendor flags verified against live claude --help 2026-08-06: no `claude
# attach` subcommand exists. `claude agents --json` lists both interactive
# and background sessions keyed by `sessionId`; `-r/--resume [value]`
# ("Resume a conversation by session ID, or open interactive picker") is the
# closest supported attach-by-id form and is what this script wires. Re-verify
# before changing (ADR-0003: a nonexistent flag already slipped in once).

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

# Resolution: the work-item lock first, else the newest registry record for
# the project (fallback — same convention as own_record() in
# launch-next-session.sh, minus its env-var self-identification, which does
# not apply here: we want the project's latest session, not "my own").
RUNTIME=""; SID=""; LOCKED=0
LOCK="$WORKSPACE_ROOT/work/$PROJECT/.active-session"
if [ -f "$LOCK" ]; then
  RUNTIME="$(jq -r '.runtime // empty' "$LOCK" 2>/dev/null)"
  SID="$(jq -r '.session_id // empty' "$LOCK" 2>/dev/null)"
  [ -n "$RUNTIME" ] && [ -n "$SID" ] && LOCKED=1
fi
if [ "$LOCKED" -eq 0 ]; then
  RUNTIME=""; SID=""
  for f in $(ls -t "$STATE_DIR/sessions/"*.json 2>/dev/null); do
    if [ "$(jq -r '.project // empty' "$f" 2>/dev/null)" = "$PROJECT" ]; then
      RUNTIME="$(jq -r '.runtime // empty' "$f" 2>/dev/null)"
      SID="$(jq -r '.session_id // empty' "$f" 2>/dev/null)"
      break
    fi
  done
fi
[ -n "$RUNTIME" ] && [ -n "$SID" ] || die "no session known for work/$PROJECT"

# Liveness: mirror lock_holder_age() in scripts/context-budget.sh (read it
# first — canonical logic; NOT sourced here, it dispatches a command on
# execution) — age of the session's registered artifact vs LOCK_STALE.
AGE=""; LIVE="no"
REC="$STATE_DIR/sessions/$RUNTIME-$SID.json"
if [ -f "$REC" ]; then
  AF="$(jq -r '.artifact // empty' "$REC" 2>/dev/null)"
  if [ -n "$AF" ] && [ -f "$AF" ]; then
    MT="$(stat -f%m "$AF" 2>/dev/null || stat -c%Y "$AF" 2>/dev/null)" || MT=""
    if [ -n "$MT" ]; then
      AGE=$(( $(date +%s) - MT ))
      [ "$AGE" -lt "$LOCK_STALE" ] && LIVE="yes"
    fi
  fi
fi

# Role: the lock is authoritative (holder = primary); otherwise the session
# record's cached role claim (auxiliary/superseded), else none.
ROLE="none"
if [ "$LOCKED" -eq 1 ]; then
  ROLE="primary"
elif [ -f "$REC" ]; then
  ROLE="$(jq -r '.role // "none"' "$REC" 2>/dev/null)"
fi

echo "project=$PROJECT runtime=$RUNTIME session=$SID role=$ROLE age=${AGE:-unknown}${AGE:+s} live=$LIVE locked=$([ "$LOCKED" -eq 1 ] && echo yes || echo no)"

if [ "$LIVE" != "yes" ] || [ "$LOCKED" -ne 1 ]; then
  note "no live session — run: scripts/launch-next-session.sh $PROJECT"
  exit 0
fi

if [ "$RUNTIME" != "claude" ]; then
  note "cannot attach — $RUNTIME has no background sessions (launcher --bg is claude-only); the session is already interactive in someone's terminal"
  exit 0
fi

CMD=(claude --resume "$SID")

if [ "$DRY" -eq 1 ] || { [ ! -t 0 ] || [ ! -t 1 ]; }; then
  echo "run: $(printf '%q ' "${CMD[@]}" | sed 's/ $//')"
  exit 0
fi

exec "${CMD[@]}"
