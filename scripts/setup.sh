#!/usr/bin/env bash
# File: scripts/setup.sh
# Purpose: Bootstrap the workspace — agent symlinks, per-user config copies, optional repo clones.
# Usage:   scripts/setup.sh [--clone-repos]
# See: docs/workspace-structure.md → "scripts/ — Bootstrap and Utility Scripts"
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

CLONE_REPOS=0
for arg in "$@"; do
  case "$arg" in
    --clone-repos) CLONE_REPOS=1 ;;
    -h|--help) echo "usage: scripts/setup.sh [--clone-repos]"; exit 0 ;;
    *) echo "unknown arg: $arg" >&2; exit 2 ;;
  esac
done

log(){ printf '  %s\n' "$*"; }
echo "Bootstrapping workspace at $ROOT"

# 0. Dependency preflight (informational; does not abort setup)
if [ -x scripts/check-dependencies.sh ]; then
  scripts/check-dependencies.sh || log "some dependencies missing — see docs/runbooks/dependencies.md"
fi

# 1. Agent entrypoint symlinks → CONTEXT.md
#    Idempotent; also repairs symlinks flattened to files by Windows/copy-based "Use this template" flows.
for f in CLAUDE.md AGENTS.md GEMINI.md; do
  if [ ! -L "$f" ]; then
    [ -e "$f" ] && mv "$f" "$f.bak" && log "backed up real $f → $f.bak"
    ln -s CONTEXT.md "$f" && log "linked $f → CONTEXT.md"
  fi
done

# 2. repos/README.md → ../docs/repos-registry.md
mkdir -p repos
if [ ! -L repos/README.md ]; then
  [ -e repos/README.md ] && rm -f repos/README.md
  ln -s ../docs/repos-registry.md repos/README.md && log "linked repos/README.md → ../docs/repos-registry.md"
fi

# 3. Per-user config copies (gitignored) from the *.example templates
copy_if_missing(){ if [ -f "$1" ] && [ ! -e "$2" ]; then cp "$1" "$2" && log "created $2 (from $1)"; fi; }
copy_if_missing .env.example .env
copy_if_missing .mcp.json.example .mcp.json
copy_if_missing .claude/settings.json.example .claude/settings.local.json

# 4. Optional: clone product repos listed in docs/repos-registry.md
if [ "$CLONE_REPOS" = 1 ]; then
  urls="$(grep -oE '(https?://|git@)[^ `<>]+\.git' docs/repos-registry.md 2>/dev/null | sort -u || true)"
  if [ -z "$urls" ]; then
    log "no clone URLs found in docs/repos-registry.md (still placeholders?)"
  else
    printf '%s\n' "$urls" | while read -r url; do
      name="$(basename "$url" .git)"
      if [ -d "repos/$name" ]; then log "repos/$name exists, skipping"
      else log "cloning $url → repos/$name"; git clone "$url" "repos/$name" || log "clone failed: $url"; fi
    done
  fi
else
  log "skipping repo clones (pass --clone-repos to enable)"
fi

echo "Done. Next:"
echo "  - authenticate / export the MCP token: scripts/check-service-access.sh (then docs/runbooks/authentication.md)"
echo "  - fill in CONTEXT.md, then run scripts/check-workspace-structure.sh"
echo "  - onboard a repo: /onboard-repo <repo-name>  (freshness later: scripts/check-repo-context.sh)"
