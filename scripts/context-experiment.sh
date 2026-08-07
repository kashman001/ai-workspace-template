#!/usr/bin/env bash
# File: scripts/context-experiment.sh
# Purpose: Reproducible three-snapshot context experiment. Launches two
#          headless claude sessions in this workspace — (A) baseline: the
#          prompt "hi"; (B) workload: a prompt you supply — then analyzes
#          both transcripts with context-inspect.sh --phases and prints the
#          snapshot summary: S1 = pre-turn-1 prediction (disk + attachment
#          estimates, printed by the analyzer), S2 = run A's turn-1 exact
#          (what a session costs before any work), S3 = run B's last-turn
#          exact (after the workload). Re-run after template changes to see
#          what a change costs at session start.
# Usage:   context-experiment.sh [--workload <prompt-file>]
#          Default workload: a one-file read task (see WORKLOAD below).
# Notes:   claude-only; both runs BILL REAL TOKENS. Requires claude with
#          --session-id (verified live 2026-08-07) and uuidgen. Transcripts
#          stay in the project slug dir for later comparison.

set -u

resolve_workspace_root() {  # same convention as context-inspect.sh
  local root common repo
  root="$(cd "$1" && pwd -P)"
  if common="$(git -C "$root" rev-parse --git-common-dir 2>/dev/null)"; then
    case "$common" in /*) : ;; *) common="$root/$common" ;; esac
    repo="$(cd "$common/.." 2>/dev/null && pwd -P)"
    if [ -n "$repo" ] && [ -f "$repo/scripts/context-experiment.sh" ]; then
      printf '%s' "$repo"; return
    fi
  fi
  printf '%s' "$root"
}
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd -P)"
WORKSPACE_ROOT="$(resolve_workspace_root "$SCRIPT_DIR/..")"

die() { echo "error: $*" >&2; exit 1; }
command -v claude >/dev/null 2>&1 || die "claude CLI not on PATH"
command -v uuidgen >/dev/null 2>&1 || die "uuidgen is required"

WORKLOAD="Read README.md and state its first heading in one sentence."
while [ $# -gt 0 ]; do
  case "$1" in
    --workload) [ -f "${2:-}" ] || die "--workload: file not found: ${2:-}"
                WORKLOAD="$(cat "$2")"; shift 2 ;;
    *) die "usage: context-experiment.sh [--workload <prompt-file>]" ;;
  esac
done

SLUG="$(printf '%s' "$WORKSPACE_ROOT" | tr '/.' '--')"
PROJ_DIR="$HOME/.claude/projects/$SLUG"

run_one() {  # $1=label $2=session-uuid $3=prompt
  echo "=== run $1: claude -p --session-id $2 ..." >&2
  ( cd "$WORKSPACE_ROOT" && claude -p --session-id "$2" "$3" >/dev/null ) \
    || die "run $1 failed"
  [ -f "$PROJ_DIR/$2.jsonl" ] || die "run $1 left no transcript at $PROJ_DIR/$2.jsonl"
}

turn_totals() {  # $1=transcript — exact context total per assistant line
  jq -r 'select(.type=="assistant") | .message.usage
    | (.input_tokens + .cache_read_input_tokens + .cache_creation_input_tokens)' \
    "$1" 2>/dev/null
}

A_SID="$(uuidgen | tr '[:upper:]' '[:lower:]')"
B_SID="$(uuidgen | tr '[:upper:]' '[:lower:]')"
run_one baseline "$A_SID" "hi"
run_one workload "$B_SID" "$WORKLOAD"

echo
echo "################ run A (baseline: \"hi\") ################"
"$SCRIPT_DIR/context-inspect.sh" --phases "$PROJ_DIR/$A_SID.jsonl"
echo
echo "################ run B (workload) ################"
"$SCRIPT_DIR/context-inspect.sh" --phases "$PROJ_DIR/$B_SID.jsonl"

S2="$(turn_totals "$PROJ_DIR/$A_SID.jsonl" | head -1)"
B1="$(turn_totals "$PROJ_DIR/$B_SID.jsonl" | head -1)"
S3="$(turn_totals "$PROJ_DIR/$B_SID.jsonl" | tail -1)"
echo
echo "################ snapshot summary ################"
echo "S1 (pre-turn-1 prediction):   see run A's disk + attachment estimates above"
printf 'S2 (baseline turn-1 exact):  %8d tokens   [%s]\n' "$S2" "$A_SID"
printf 'S3 (post-workload exact):    %8d tokens   [%s, turn-1 %d, workload growth %d]\n' \
  "$S3" "$B_SID" "$B1" "$((S3 - B1))"
