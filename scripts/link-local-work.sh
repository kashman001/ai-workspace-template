#!/usr/bin/env bash
# File: scripts/link-local-work.sh
# Purpose: Share local-only work items into a git worktree (backlog L45). A
#          worktree carries tracked files only, so a work/<item>/ that is
#          ignored (.gitignore or .git/info/exclude) is absent there, and what
#          a worktree-isolated session writes under it dies with the worktree.
#          This symlinks each such item from the main checkout into the
#          worktree, so the session reads and writes the real directory.
#          Idempotent; silent when there is nothing to do; never replaces an
#          existing path (a manual copy stays a real dir); never links an
#          untracked-but-not-ignored item (a symlink there would be
#          committable); registers each linked path in the shared
#          .git/info/exclude so the symlink never shows as untracked in the
#          worktree. Fails open (rc 0) except on a usage error.
# Callers: every per-tool hook firing (scripts/hooks/context-budget-hook-lib.sh,
#          all runtimes, unthrottled) and `context-budget.sh register`; safe
#          to run by hand from inside a worktree.
# Usage:   link-local-work.sh [<dir>]   (any dir inside the worktree; default $PWD)
# Prints:  "linked work/<item> -> <main>/work/<item>" per new link (stdout).
set -u
dir="${1:-$PWD}"
[ -d "$dir" ] || { echo "usage: $0 [<dir-inside-worktree>]" >&2; exit 1; }
top="$(git -C "$dir" rev-parse --show-toplevel 2>/dev/null)" || exit 0
# A linked worktree's toplevel holds a .git FILE (gitdir pointer); the main
# checkout's .git is a directory. Nothing to share in the main checkout.
[ -f "$top/.git" ] || exit 0
common="$(git -C "$top" rev-parse --git-common-dir 2>/dev/null)" || exit 0
case "$common" in /*) : ;; *) common="$top/$common" ;; esac
main="$(cd "$common/.." 2>/dev/null && pwd -P)" || exit 0
[ -d "$main/work" ] && [ -d "$top/work" ] || exit 0
# Ignored top-level work/<item>/ directories only. --directory collapses a
# fully-ignored dir to one "work/<item>/" line; ignored files or subdirs
# inside a tracked item come out deeper (work/<item>/.active-session,
# work/<item>/.agent-locks/) and are skipped by the depth filter.
git -C "$main" ls-files --others --ignored --exclude-standard --directory -- work/ 2>/dev/null \
| while IFS= read -r p; do
    case "$p" in work/*/) ;; *) continue ;; esac
    name="${p#work/}"; name="${name%/}"
    case "$name" in */*|"") continue ;; esac
    [ -d "$main/work/$name" ] || continue
    if [ -e "$top/work/$name" ] || [ -L "$top/work/$name" ]; then continue; fi
    ln -s "$main/work/$name" "$top/work/$name" 2>/dev/null || continue
    echo "linked work/$name -> $main/work/$name"
    # A "work/<item>/" pattern (trailing slash) matches directories only, so
    # the symlink would show as untracked in the worktree and a blanket
    # `git add -A` there would commit it. Register the exact path in the
    # shared info/exclude (machine-local, never tracked) when needed.
    git -C "$top" check-ignore -q -- "work/$name" 2>/dev/null \
      || printf '%s\n' "work/$name" >> "$common/info/exclude" 2>/dev/null
  done
exit 0
