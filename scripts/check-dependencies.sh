#!/usr/bin/env bash
# File: scripts/check-dependencies.sh
# Purpose: Verify the tools this workspace's workflow expects are installed.
#          Required tools missing → exit 1. Recommended tools missing → warn only.
#          For install steps, an agent or human follows docs/runbooks/dependencies.md.
# See: docs/workspace-structure.md → "scripts/ — Bootstrap and Utility Scripts"
set -uo pipefail

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

echo "Recommended (install the ones whose features you use):"
rec gh      "GitHub auth + MCP token source (gh auth token)"
rec node    "Claude Code status line (npx ccstatusline)"
rec uv      "graphify install (uv tool install graphifyy)"
rec python3 "graphify runtime / general tooling"
rec docker  "local GitHub MCP server option (vs. hosted)"
rec graphify "per-repo knowledge graph (optional)"

echo
if [ "$missing_required" = 0 ]; then
  echo "Required dependencies present. Install any missing recommended tools per docs/runbooks/dependencies.md"
  exit 0
else
  echo "Missing required dependencies — see docs/runbooks/dependencies.md (OS: $OS)" >&2
  exit 1
fi
