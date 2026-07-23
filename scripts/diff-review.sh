#!/usr/bin/env bash
#
# diff-review.sh — open a commit (or commit range) for user review as a
# directory diff, with the load-bearing flags that keep symlinked files from
# showing up as "missing" in Beyond Compare.
#
# WHY THIS SCRIPT EXISTS
#   `git difftool --dir-diff` builds two temp trees. When one side equals the
#   working tree (e.g. reviewing HEAD), git populates that side with SYMLINKS
#   pointing back into the repo. Beyond Compare does not follow them, so files
#   render as missing / panes misalign. The fix is `--no-symlinks` (forces real
#   file copies) plus, on macOS, invoking the BLOCKING `bcomp` launcher rather
#   than `bcompare` (which returns immediately, letting git delete the temp
#   dirs before BC reads them → empty panes). This script always applies both.
#
# Agent-neutral: plain bash + git + a diff tool. Any runtime or human can call
# it. Codifies docs/operational-knowledge.md → "Diff Review Workflow".
#
# Usage:
#   scripts/diff-review.sh [options] <sha> [<base-sha>]
#
#   <sha>       Commit to review (its diff against <base-sha>).
#   <base-sha>  Optional base; defaults to <sha>~1 (the commit's parent).
#               Pass an explicit base to review a multi-commit range, e.g.
#               `scripts/diff-review.sh <tip-sha> <first-sha>~1` for a range.
#
# Options:
#   -r, --repo <path>   Run against this git repo (default: current directory).
#   -t, --tool <tool>   bc (Beyond Compare, default) | code (VS Code Compare
#                       Folders tree) | vscode (VS Code per-file diff).
#   -h, --help          Show this help.
#
# Examples:
#   scripts/diff-review.sh <sha>
#   scripts/diff-review.sh -r repos/<repo> <sha>
#   scripts/diff-review.sh -r repos/<repo> <tip-sha> <first-sha>~1   # range
#   scripts/diff-review.sh -t vscode <sha>                           # no BC license
#
# Full background + fallback levels: docs/operational-knowledge.md →
# "Diff Review Workflow". Install notes: docs/workspace-setup.md.
set -euo pipefail

usage() { sed -n '2,/^set -euo/p' "$0" | sed 's/^# \{0,1\}//; s/^#$//' | sed '$d'; }

REPO="."
TOOL="bc"

while [ $# -gt 0 ]; do
  case "$1" in
    -r|--repo) REPO="${2:?--repo needs a path}"; shift 2 ;;
    -t|--tool) TOOL="${2:?--tool needs a value}"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    --) shift; break ;;
    -*) echo "diff-review: unknown option '$1'" >&2; exit 2 ;;
    *) break ;;
  esac
done

SHA="${1:-}"
if [ -z "$SHA" ]; then
  echo "diff-review: missing <sha>. See --help." >&2
  exit 2
fi
BASE="${2:-${SHA}~1}"

# Resolve the repo and validate the revisions BEFORE launching any GUI, so a
# bad SHA fails fast with a clear message instead of an empty diff window.
if ! git -C "$REPO" rev-parse --git-dir >/dev/null 2>&1; then
  echo "diff-review: '$REPO' is not a git repository." >&2
  exit 1
fi
for rev in "$BASE" "$SHA"; do
  if ! git -C "$REPO" rev-parse --verify --quiet "${rev}^{commit}" >/dev/null; then
    echo "diff-review: revision '$rev' not found in '$REPO'." >&2
    exit 1
  fi
done

echo "diff-review: $REPO  ${BASE} .. ${SHA}  (tool=${TOOL})"
git -C "$REPO" --no-pager diff --stat "$BASE" "$SHA"

# --no-symlinks and --no-prompt are load-bearing for ALL tools here; see header.
case "$TOOL" in
  bc)
    # Prefer the BLOCKING launcher. On macOS `bcompare` is non-blocking (opens
    # empty panes under difftool); `bcomp` blocks. On Linux the blocking binary
    # is usually `bcompare`. Pick whichever blocking launcher exists.
    LAUNCHER=""
    for cand in /usr/local/bin/bcomp /opt/homebrew/bin/bcomp bcomp /usr/bin/bcompare bcompare; do
      if command -v "$cand" >/dev/null 2>&1; then LAUNCHER="$cand"; break; fi
    done
    if [ -z "$LAUNCHER" ]; then
      echo "diff-review: Beyond Compare not found (bcomp/bcompare). Try -t code or -t vscode." >&2
      exit 1
    fi
    echo "diff-review: launching Beyond Compare via '$LAUNCHER' (blocks until you close it)…"
    git -C "$REPO" -c "difftool.bc.path=${LAUNCHER}" \
      difftool --dir-diff --no-symlinks --no-prompt -t bc "$BASE" "$SHA"
    ;;
  vscode)
    if ! command -v code >/dev/null 2>&1; then
      echo "diff-review: 'code' CLI not on PATH (VS Code → 'Shell Command: Install code command')." >&2
      exit 1
    fi
    echo "diff-review: walking changed files through VS Code diff (close each tab to advance)…"
    git -C "$REPO" difftool --no-symlinks --no-prompt -x 'code --wait --diff' "$BASE" "$SHA"
    ;;
  code)
    # VS Code + Compare Folders extension (moshfeu.compare-folders): extract
    # both trees to real files (no symlinks) and open the folder in VS Code.
    if ! command -v code >/dev/null 2>&1; then
      echo "diff-review: 'code' CLI not on PATH." >&2
      exit 1
    fi
    TMP="$(mktemp -d -t diff-review-XXXXXX)"
    mkdir -p "$TMP/old" "$TMP/new"
    git -C "$REPO" archive "$BASE" | tar -x -C "$TMP/old"
    git -C "$REPO" archive "$SHA"  | tar -x -C "$TMP/new"
    echo "diff-review: extracted trees to $TMP (old/ vs new/)."
    echo "  In VS Code: Cmd/Ctrl+Shift+P → 'Compare Folders: Choose Folders' →"
    echo "  source=old/  target=new/ .  Delete when done:  rm -rf '$TMP'"
    code -n "$TMP"
    ;;
  *)
    echo "diff-review: unknown --tool '$TOOL' (expected bc | code | vscode)." >&2
    exit 2
    ;;
esac
