#!/usr/bin/env bash
# File: scripts/check-dependencies.sh
# Purpose: Verify the tools this workspace's workflow expects are installed.
#          Required tools missing → exit 1. Recommended tools missing → warn only.
#          For install steps, an agent or human follows docs/runbooks/dependencies.md.
# See: docs/workspace-structure.md → "scripts/ — Bootstrap and Utility Scripts"
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

case "$(uname -s)" in
  Darwin)               OS=macOS ;;
  Linux)                OS=Linux ;;
  MINGW*|MSYS*|CYGWIN*) OS=Windows ;;
  *)                    OS=unknown ;;
esac
echo "Dependency check (OS: $OS)"

have(){ command -v "$1" >/dev/null 2>&1; }
ver(){ "$1" --version 2>/dev/null | head -1; }

missing_required=0

# name | one-line reason it's required
req(){
  if have "$1"; then printf '  \033[32m✓\033[0m %-8s %s\n' "$1" "$(ver "$1")"
  else printf '  \033[31m✗\033[0m %-8s MISSING (required) — %s\n' "$1" "$2" >&2; missing_required=1; fi
}
# name | what needs it
rec(){
  if have "$1"; then printf '  \033[32m✓\033[0m %-8s %s\n' "$1" "$(ver "$1")"
  else printf '  \033[33m•\033[0m %-8s not found — needed for: %s\n' "$1" "$2"; fi
}

echo "Required:"
req git "core — clone/symlinks/registry"
req gh  "GitHub CLI — the workspace's GitHub path (auth, PRs, API)"
req jq  "context-budget accounting (scripts/context-budget.sh) — every session runs it"

# Wiring, not a binary: the context-budget hooks must be wired into Claude Code's
# project-level gitignored settings (scripts/setup.sh copies .claude/settings.json.example there).
if grep -qs 'context-budget-claude-hook' .claude/settings.json .claude/settings.local.json 2>/dev/null; then
  printf '  \033[32m✓\033[0m %-8s context-budget hooks wired (.claude/settings*.json)\n' "hooks"
else
  printf '  \033[31m✗\033[0m %-8s MISSING (required) — context-budget hooks not wired; run scripts/setup.sh (copies .claude/settings.json.example → .claude/settings.local.json)\n' "hooks" >&2
  missing_required=1
fi

echo "Recommended (install the ones whose features you use):"
rec node    "Claude Code status line (npx ccstatusline)"
rec uv      "graphify install (uv tool install graphifyy)"
rec python3 "graphify runtime / general tooling"
rec yt-dlp  "workspace-local YouTube transcript MCP server"
rec graphify "per-repo knowledge graph (optional)"

echo
if [ "$missing_required" = 0 ]; then
  echo "Required dependencies present. Install any missing recommended tools per docs/runbooks/dependencies.md"
  exit 0
else
  echo "Missing required dependencies — see docs/runbooks/dependencies.md (OS: $OS)" >&2
  exit 1
fi
