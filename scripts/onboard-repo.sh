#!/usr/bin/env bash
# File: scripts/onboard-repo.sh
# Purpose: Thin, idempotent mechanical half of repo onboarding — scaffold the
#          registry entry, wire the graphify MCP server, stamp the repo-context
#          doc templates with provenance, and (on --refresh) update the graph.
#          Judgement-heavy derivation of the docs is done by the agent following
#          skills/onboard-repo/SKILL.md. Never fails onboarding just because
#          graphify is absent; signals availability via a Status: line.
# Usage:   scripts/onboard-repo.sh <repo-name> [repo-path]
#          scripts/onboard-repo.sh <repo-name> --refresh
# See: docs/superpowers/specs/2026-06-24-repo-onboarding-design.md
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

REPO="${1:-}"
if [ -z "$REPO" ]; then
  echo "usage: scripts/onboard-repo.sh <repo-name> [repo-path|--refresh]" >&2
  exit 2
fi

REFRESH=0
REPO_PATH=""
case "${2:-}" in
  --refresh) REFRESH=1 ;;
  "")        REPO_PATH="" ;;
  *)         REPO_PATH="$2" ;;
esac

# Resolve a repo's working path when none was passed explicitly: prefer its registry
# "Location" (so a repo onboarded in place at an external/local path is found — e.g. on
# --refresh, whose hint is pathless), else the conventional repos/<repo> or workspace
# root. Mirrors resolve_repo_path() in check-repo-context.sh — keep them in sync.
resolve_repo_path() {
  local name="$1" loc=""
  if [ -f docs/repos-registry.md ]; then
    loc="$(awk -v repo="$name" '
      $0 ~ "^##[[:space:]]+" repo "([[:space:]]|\\(|$)" {inSec=1; next}
      inSec && /^##[[:space:]]/ {inSec=0}
      inSec && /^- \*\*Location\*\*:/ {print; exit}
    ' docs/repos-registry.md | grep -oE '`[^`]+`' | head -1 | tr -d '`')"
  fi
  if [ -n "$loc" ] && [ -d "$loc" ]; then printf '%s' "$loc"; return; fi
  if [ -d "repos/$name" ]; then printf '%s' "repos/$name"; return; fi
  printf '%s' "."
}

# Default repo path: registry Location, else repos/<repo> (multi-repo), else workspace root.
if [ -z "$REPO_PATH" ]; then
  REPO_PATH="$(resolve_repo_path "$REPO")"
fi

TODAY="$(date +%Y-%m-%d)"
SHA="$(git -C "$REPO_PATH" rev-parse --short HEAD 2>/dev/null || echo unknown)"
CTX_DIR="docs/repo-context/$REPO"
graphify_status="fallback"

# Rewrite the "> Generated: ..." provenance line in a doc (fresh copy or --refresh).
set_provenance() {
  local prov="> Generated: $TODAY | Source commit: $SHA | Refresh: \`/onboard-repo $REPO --refresh\`"
  local esc=${prov//&/\\&}
  sed -i.bak -E "s@^> Generated:.*@$esc@" "$1" && rm -f "$1.bak"
}

add_registry_entry() {
  # Idempotency keyed on the heading PREFIX so it also matches "## <repo> (primary)".
  if grep -qiE "^##[[:space:]]+${REPO}([[:space:]]|\$)" docs/repos-registry.md; then
    echo "  registry: entry for $REPO already present — skipping"
    return
  fi
  cat >> docs/repos-registry.md <<EOF

## $REPO

- **Host**: <GitHub / GitLab / Bitbucket / local>
- **Clone URL**: \`<ssh-or-https-clone-url>\` (n/a for local)
- **Default branch**: \`main\`
- **Visibility**: <public / private>
- **Purpose**: <one line>
- **Auth method**: <gh CLI / SSH key X / PAT in keychain> — see \`docs/runbooks/authentication.md\`
- **Language / stack**: <languages + frameworks>
- **Build / test / run**: \`<build>\` / \`<test>\` / \`<run>\`
- **Network**: <none special / VPN required / SSH key X>
- **Location**: \`$REPO_PATH\`
- **Covered by context docs**: yes — \`docs/repo-context/$REPO/\` (code-structure.md, design.md, api.md)
- **Tier**: <primary | optional>
EOF
  echo "  registry: appended entry for $REPO"
}

wire_graphify_mcp() {
  # Ensure a local .mcp.json exists (carries the graphify server entry from the example).
  if [ ! -f .mcp.json ] && [ -f .mcp.json.example ]; then
    cp .mcp.json.example .mcp.json
    echo "  mcp: created .mcp.json from example (graphify server included)"
  fi
}

refresh_graph() {
  # AST-only, no API cost. Only meaningful if a graph already exists.
  if command -v graphify >/dev/null 2>&1 && [ -f "$REPO_PATH/graphify-out/graph.json" ]; then
    ( cd "$REPO_PATH" && graphify update . >/dev/null 2>&1 || true )
  fi
}

detect_graph() {
  [ -f "$REPO_PATH/graphify-out/graph.json" ] && graphify_status="live"
}

echo "Onboarding repo: $REPO  (path: $REPO_PATH, head: $SHA)"
wire_graphify_mcp

if [ "$REFRESH" = 1 ]; then
  if [ ! -d "$CTX_DIR" ]; then
    echo "  ✗ $CTX_DIR does not exist — run without --refresh first" >&2
    exit 2
  fi
  refresh_graph
  for f in code-structure.md design.md api.md; do
    [ -f "$CTX_DIR/$f" ] && set_provenance "$CTX_DIR/$f"
  done
  echo "  refreshed provenance (date=$TODAY sha=$SHA) and graph (if present)"
else
  add_registry_entry
  mkdir -p "$CTX_DIR"
  for f in code-structure.md design.md api.md; do
    if [ -f "$CTX_DIR/$f" ]; then
      echo "  docs: $CTX_DIR/$f exists — skipping (not clobbered)"
    else
      if ! cp "docs/repo-context/_templates/$f" "$CTX_DIR/$f"; then
        echo "  ✗ missing template docs/repo-context/_templates/$f" >&2
        exit 1
      fi
      repo_esc=${REPO//&/\\&}
      sed -i.bak "s@<repo>@$repo_esc@g" "$CTX_DIR/$f" && rm -f "$CTX_DIR/$f.bak"
      set_provenance "$CTX_DIR/$f"
      echo "  docs: created $CTX_DIR/$f"
    fi
  done
fi

detect_graph
echo "Status: graphify=$graphify_status"
if [ "$graphify_status" != live ]; then
  echo "graphify graph not built — agents fall back to the committed docs; run /graphify in $REPO_PATH for live queries" >&2
fi
exit 0
