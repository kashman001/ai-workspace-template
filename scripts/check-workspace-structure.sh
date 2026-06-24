#!/usr/bin/env bash
# File: scripts/check-workspace-structure.sh
# Purpose: Validate the workspace — required dirs exist, symlinks resolve, scripts executable,
#          and .gitignore keeps the registry README visible. Exits non-zero on any failure.
# See: docs/workspace-structure.md → "scripts/ — Bootstrap and Utility Scripts"
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

fail=0
ok(){  printf '  \033[32m✓\033[0m %s\n' "$*"; }
bad(){ printf '  \033[31m✗\033[0m %s\n' "$*" >&2; fail=1; }

echo "Checking workspace structure at $ROOT"

# Required directories
for d in docs skills work prompt-library references repos scripts; do
  [ -d "$d" ] && ok "dir $d" || bad "missing dir $d"
done

# Agent entrypoint + registry symlinks resolve
for l in CLAUDE.md AGENTS.md GEMINI.md repos/README.md; do
  if [ -L "$l" ] && [ -e "$l" ]; then ok "symlink $l → $(readlink "$l")"; else bad "broken/missing symlink $l"; fi
done

# Scripts executable
for s in scripts/*.sh; do
  [ -x "$s" ] && ok "executable $s" || bad "not executable $s (chmod +x)"
done

# .gitignore must keep repos/README.md visible to git
if git -C "$ROOT" rev-parse --git-dir >/dev/null 2>&1; then
  if git check-ignore -q repos/README.md; then bad "repos/README.md is gitignored (should be tracked)"
  else ok "repos/README.md not ignored"; fi
fi

if [ "$fail" = 0 ]; then echo "All checks passed."; exit 0
else echo "Some checks FAILED." >&2; exit 1; fi
