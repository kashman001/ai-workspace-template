#!/usr/bin/env bash
# File: scripts/rollover-prep.sh
# Purpose: One-shot mechanical prep for a session rollover (session-rollover
#          skill, step 1). A single call: records the "rollover start" ledger
#          entry, prints a compact git summary (workspace root + repos/*),
#          rotates older handoff.md blocks to handoff-archive.md, prints the
#          remaining top block and .session-seq, and captures
#          .rollover-options. The agent then only writes: the new handoff
#          block (inserted directly below the PURPOSE comment), a replaced
#          next-session.md, and the bootstrap prompt.
# Usage:   rollover-prep.sh <project> [--reason "<text>"] [--no-record]
# Exit:    0 (each step fails open with a note) / 1 usage error.
#
# Rotation invariant: handoff.md is left holding exactly ONE block (the
# newest), so after the agent prepends the new block it holds two — the
# ledger read-path contract (docs/work-directory-conventions.md). Moved
# blocks go on TOP of handoff-archive.md (newest-on-top ordering).
# Block markers are matched anchored to start-of-line ('^# Session Handoff');
# the PURPOSE comment mentions the marker mid-line only, so an anchored match
# cannot split inside it. Text lacking its own marker rides with the block
# above it. The split is verified lossless (head + tail recompose to the
# original) before anything is moved; on any anomaly both files are left
# untouched.

set -u

resolve_workspace_root() {  # same convention as capture-rollover-options.sh
  local root common repo
  root="$(cd "$1" && pwd -P)"
  if common="$(git -C "$root" rev-parse --git-common-dir 2>/dev/null)"; then
    case "$common" in /*) : ;; *) common="$root/$common" ;; esac
    repo="$(cd "$common/.." 2>/dev/null && pwd -P)"
    if [ -n "$repo" ] && [ -f "$repo/scripts/rollover-prep.sh" ]; then
      printf '%s' "$repo"; return
    fi
  fi
  printf '%s' "$root"
}
WORKSPACE_ROOT="$(resolve_workspace_root "$(dirname "$0")/..")"

# Tracked work files (handoff.md rotation, git summary) must target the
# checkout the session is actually working in — from a worktree, that is the
# worktree, whose copies get committed and merged (backlog M25). Adopt $PWD's
# toplevel only when it is a checkout of THIS repository (same git common
# dir); otherwise fall back to the main checkout. Untracked coordination
# state (.session-seq, .rollover-options) stays on WORKSPACE_ROOT, where
# launch-next-session.sh reads it.
canon_common_dir() {  # $1 = dir to query; prints resolved common dir or nothing
  local common
  common="$(git -C "$1" rev-parse --git-common-dir 2>/dev/null)" || return 0
  case "$common" in /*) : ;; *) common="$1/$common" ;; esac  # relative to the queried dir
  (cd "$common" 2>/dev/null && pwd -P)
}
resolve_invoke_root() {
  local top pcommon scommon
  top="$(git -C "$PWD" rev-parse --show-toplevel 2>/dev/null)" \
    || { printf '%s' "$WORKSPACE_ROOT"; return; }
  pcommon="$(canon_common_dir "$PWD")"
  scommon="$(canon_common_dir "$WORKSPACE_ROOT")"
  if [ -n "$pcommon" ] && [ "$pcommon" = "$scommon" ]; then
    printf '%s' "$top"
  else
    printf '%s' "$WORKSPACE_ROOT"
  fi
}
INVOKE_ROOT="$(resolve_invoke_root)"

die() { echo "error: $*" >&2; exit 1; }

PROJECT="${1:-}"; shift 2>/dev/null || true
[ -n "$PROJECT" ] || die "usage: rollover-prep.sh <project> [--reason \"<text>\"] [--no-record]"
REASON=""; DO_RECORD=1
while [ $# -gt 0 ]; do
  case "$1" in
    --reason)    [ $# -ge 2 ] || die "--reason needs a value"; REASON="$2"; shift 2 ;;
    --no-record) DO_RECORD=0; shift ;;
    *) die "unknown argument: $1" ;;
  esac
done
DIR="$INVOKE_ROOT/work/$PROJECT"           # tracked files: invoking checkout
COORD_DIR="$WORKSPACE_ROOT/work/$PROJECT"  # untracked coordination state
[ -d "$DIR" ] || die "work/$PROJECT not found"
[ "$INVOKE_ROOT" != "$WORKSPACE_ROOT" ] \
  && echo "note: operating on checkout $INVOKE_ROOT (coordination state stays at $WORKSPACE_ROOT)"

MARKER='^# Session Handoff'

rotate_handoff() {
  local hf="$DIR/handoff.md" af="$DIR/handoff-archive.md" n second
  [ -f "$hf" ] || { echo "no handoff.md — nothing to rotate"; return; }
  n="$(grep -c "$MARKER" "$hf" || true)"
  if [ "${n:-0}" -le 1 ]; then echo "$n block(s) — no rotation needed"; return; fi
  second="$(grep -n "$MARKER" "$hf" | sed -n 2p | cut -d: -f1)"
  head -n "$((second - 1))" "$hf" > "$hf.tmp"
  tail -n "+$second" "$hf" > "$hf.moved"
  if ! cat "$hf.tmp" "$hf.moved" | cmp -s - "$hf" \
     || [ "$(grep -c "$MARKER" "$hf.tmp")" -ne 1 ]; then
    rm -f "$hf.tmp" "$hf.moved"
    echo "rotation verification failed — handoff.md and archive left untouched"
    return
  fi
  [ -n "$(tail -c1 "$hf.moved")" ] && echo >> "$hf.moved"   # newline guard
  if [ -f "$af" ]; then cat "$hf.moved" "$af" > "$af.tmp"; else cp "$hf.moved" "$af.tmp"; fi
  mv "$af.tmp" "$af"; mv "$hf.tmp" "$hf"; rm -f "$hf.moved"
  echo "rotated $((n - 1)) block(s) to handoff-archive.md; handoff.md holds the newest"
}

git_summary() {
  local r name total
  for r in "$INVOKE_ROOT" "$INVOKE_ROOT"/repos/*/; do
    [ -e "$r/.git" ] || continue
    case "$r" in
      "$INVOKE_ROOT") name="(workspace root)" ;;
      *) name="${r#"$INVOKE_ROOT"/}" ;;
    esac
    echo "-- $name"
    git -C "$r" status --porcelain=v1 -b 2>/dev/null | sed -n '1,15p'
    total="$(git -C "$r" status --porcelain=v1 2>/dev/null | wc -l | tr -d ' ')"
    [ "$total" -gt 14 ] && echo "   (... $total dirty paths total)"
  done
}

echo "== record =="
if [ "$DO_RECORD" -eq 1 ]; then
  "$WORKSPACE_ROOT/scripts/context-budget.sh" record \
    --label "rollover start: ${REASON:-$PROJECT}" || true   # exit 1/2 = WARN/STOP, expected here
else
  echo "skipped (--no-record)"
fi

echo "== git =="
git_summary

echo "== handoff rotation =="
rotate_handoff

echo "== top handoff block =="
if [ -f "$DIR/handoff.md" ]; then
  sed -n "/$MARKER/,\$p" "$DIR/handoff.md" | sed -n '1,80p'
else
  echo "(no handoff.md)"
fi

echo "== session-seq =="
if [ -f "$COORD_DIR/.session-seq" ]; then cat "$COORD_DIR/.session-seq"; else echo "absent"; fi

echo "== rollover-options =="
"$WORKSPACE_ROOT/scripts/capture-rollover-options.sh" "$PROJECT" || true
[ -f "$COORD_DIR/.rollover-options" ] && cat "$COORD_DIR/.rollover-options"
exit 0
