#!/usr/bin/env bash
# File: scripts/capture-rollover-options.sh
# Purpose: Mechanically capture the CURRENT session's launch properties into
#          work/<project>/.rollover-options so launch-next-session.sh replays
#          them on the successor (e.g. a session running in auto permission
#          mode relaunches in auto mode). The claude transcript records
#          permissionMode per line; the LAST value wins. Model is
#          deliberately NOT captured: the transcript can't distinguish an
#          explicit --model from the runtime default, and pinning would opt
#          successors out of default-model upgrades (see decisions.md).
# Usage:   capture-rollover-options.sh <project> [transcript.jsonl]
#          No transcript: $CLAUDE_CODE_SESSION_ID's, else the newest in the
#          project slug dir. Claude-only; on any other runtime or missing
#          transcript it exits 0 leaving the file untouched (fail open —
#          the file's last known values still apply, per session-rollover
#          step 6). Existing ROLLOVER_OPT_MODEL/EXTRA lines are preserved.
# Exit:    0 (captured, or fail-open no-op) / 1 usage error. Requires jq.

set -u

resolve_workspace_root() {  # same convention as context-inspect.sh
  local root common repo
  root="$(cd "$1" && pwd -P)"
  if common="$(git -C "$root" rev-parse --git-common-dir 2>/dev/null)"; then
    case "$common" in /*) : ;; *) common="$root/$common" ;; esac
    repo="$(cd "$common/.." 2>/dev/null && pwd -P)"
    if [ -n "$repo" ] && [ -f "$repo/scripts/capture-rollover-options.sh" ]; then
      printf '%s' "$repo"; return
    fi
  fi
  printf '%s' "$root"
}
WORKSPACE_ROOT="$(resolve_workspace_root "$(dirname "$0")/..")"

note() { echo "$@" >&2; }
die()  { echo "error: $*" >&2; exit 1; }
command -v jq >/dev/null 2>&1 || die "jq is required"

PROJECT="${1:-}"; F="${2:-}"
[ -n "$PROJECT" ] || die "usage: capture-rollover-options.sh <project> [transcript.jsonl]"
[ -d "$WORKSPACE_ROOT/work/$PROJECT" ] || die "work/$PROJECT not found"

# Transcript slug follows the session's CWD, not the repo root — a worktree
# session's transcript lives under the worktree-path slug. Try cwd first.
if [ -z "$F" ]; then
  for base in "$PWD" "$WORKSPACE_ROOT"; do
    SLUG="$(printf '%s' "$base" | tr '/.' '--')"
    PROJ_DIR="$HOME/.claude/projects/$SLUG"
    if [ -n "${CLAUDE_CODE_SESSION_ID:-}" ] && [ -f "$PROJ_DIR/$CLAUDE_CODE_SESSION_ID.jsonl" ]; then
      F="$PROJ_DIR/$CLAUDE_CODE_SESSION_ID.jsonl"; break
    fi
  done
fi
if [ -z "$F" ]; then
  SLUG="$(printf '%s' "$PWD" | tr '/.' '--')"
  F="$(ls -t "$HOME/.claude/projects/$SLUG"/*.jsonl \
             "$HOME/.claude/projects/$(printf '%s' "$WORKSPACE_ROOT" | tr '/.' '--')"/*.jsonl \
       2>/dev/null | head -1)"
fi
if [ -z "$F" ] || [ ! -f "$F" ]; then
  note "no claude transcript found — leaving .rollover-options untouched (fail open)"
  exit 0
fi

PMODE="$(jq -r 'select(.permissionMode != null) | .permissionMode' "$F" 2>/dev/null | tail -1)"
case "$PMODE" in
  default)           APPROVAL=default ;;
  acceptEdits)       APPROVAL=edits ;;
  auto)              APPROVAL=auto ;;
  bypassPermissions) APPROVAL=full ;;
  plan)              APPROVAL=default
                     note "session is in plan mode — capturing 'default' (plan is transient)" ;;
  "")                note "transcript records no permissionMode — leaving .rollover-options untouched"
                     exit 0 ;;
  *)                 note "unknown permissionMode '$PMODE' — leaving .rollover-options untouched"
                     exit 0 ;;
esac

OPTF="$WORKSPACE_ROOT/work/$PROJECT/.rollover-options"
KEPT=""
[ -f "$OPTF" ] && KEPT="$(grep -v '^ROLLOVER_OPT_APPROVAL=' "$OPTF")"
{
  echo "ROLLOVER_OPT_APPROVAL=$APPROVAL"
  [ -n "$KEPT" ] && printf '%s\n' "$KEPT"
} > "$OPTF"
echo "captured ROLLOVER_OPT_APPROVAL=$APPROVAL (permissionMode=$PMODE) -> ${OPTF/#$WORKSPACE_ROOT\//}"
