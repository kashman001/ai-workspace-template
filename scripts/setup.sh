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

# 3b. Seed Copilot folder trust (per-machine state; idempotent).
#     Repo-committed Copilot hooks (.github/hooks/*.json → context-budget
#     wrappers) silently no-op unless this workspace is listed in
#     ~/.copilot/config.json trustedFolders — no error, no visible signal.
#     Verify-only counterpart: scripts/check-dependencies.sh. The config is
#     JSONC (Copilot writes // comment lines) — strip them before jq,
#     preserve them on rewrite.
COPILOT_CFG="$HOME/.copilot/config.json"
if [ ! -d "$HOME/.copilot" ]; then
  log "Copilot not initialized (~/.copilot missing) — skipping trust seed; re-run scripts/setup.sh after Copilot's first run"
elif ! command -v jq >/dev/null 2>&1; then
  log "WARNING: jq not found — cannot seed Copilot trustedFolders; add \"trustedFolders\": [\"$ROOT\"] to $COPILOT_CFG manually"
else
  cfg_comments=""; cfg_json="{}"
  if [ -f "$COPILOT_CFG" ]; then
    cfg_comments="$(grep -E '^[[:space:]]*//' "$COPILOT_CFG" || true)"
    cfg_json="$(grep -vE '^[[:space:]]*//' "$COPILOT_CFG" || true)"
    [ -n "$cfg_json" ] || cfg_json="{}"
  fi
  if printf '%s' "$cfg_json" | jq -e --arg r "$ROOT" '.trustedFolders // [] | index($r)' >/dev/null 2>&1; then
    log "Copilot: workspace already in trustedFolders (skipping)"
  elif cfg_updated="$(printf '%s' "$cfg_json" | jq --arg r "$ROOT" '.trustedFolders = (((.trustedFolders // []) + [$r]) | unique)')"; then
    { [ -n "$cfg_comments" ] && printf '%s\n' "$cfg_comments"; printf '%s\n' "$cfg_updated"; } > "$COPILOT_CFG"
    log "Copilot: added workspace to trustedFolders in $COPILOT_CFG"
  else
    log "WARNING: could not parse $COPILOT_CFG — add trustedFolders manually"
  fi
fi

# 3c. Dependency check (informational; does not abort setup). Runs after the
#     per-user copies and the trust seed so its wiring checks reflect
#     post-setup state.
if [ -x scripts/check-dependencies.sh ]; then
  scripts/check-dependencies.sh || log "some dependencies missing — see docs/runbooks/dependencies.md"
fi

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
