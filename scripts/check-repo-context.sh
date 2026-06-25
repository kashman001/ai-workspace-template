#!/usr/bin/env bash
# File: scripts/check-repo-context.sh
# Purpose: Warn-only freshness check for per-repo context docs. For each covered
#          repo, compare the provenance "Source commit" recorded in its
#          code-structure.md against the repo's current HEAD; flag drift. Never
#          blocks — always exits 0, signals via a Status: line (suite convention).
# See: docs/superpowers/specs/2026-06-24-repo-onboarding-design.md → Drift management
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

status="ok"
found=0
echo "Repo-context freshness:"

# Resolve a repo's working path: prefer its registry "Location" (so repos onboarded
# in place at an external/local path are tracked too), else the conventional
# repos/<name> or workspace root. Returns a path that exists, or "" if none does.
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
  [ -d . ] && printf '%s' "."
}

for d in docs/repo-context/*/; do
  [ -d "$d" ] || continue
  name="$(basename "$d")"
  [ "$name" = "_templates" ] && continue
  doc="${d}code-structure.md"
  [ -f "$doc" ] || continue
  found=1

  rec="$(grep -m1 -oE 'Source commit: [0-9a-f]+' "$doc" | awk '{print $3}')"
  path="$(resolve_repo_path "$name")"

  if [ -z "$rec" ]; then
    echo "  ? $name: no recorded source commit — run /onboard-repo $name --refresh"
    status="degraded"; continue
  fi
  if ! git -C "$path" rev-parse -q --verify "${rec}^{commit}" >/dev/null 2>&1; then
    echo "  ? $name: recorded commit $rec not found in $path — run /onboard-repo $name --refresh"
    status="degraded"; continue
  fi
  # Exclude the context docs themselves so doc commits don't self-report as drift.
  changes="$(git -C "$path" log "${rec}..HEAD" --oneline -- . ':(exclude)docs/repo-context' 2>/dev/null)"
  if [ -n "$changes" ]; then
    echo "  ✗ $name: code changed since $rec — context docs may be stale (/onboard-repo $name --refresh)"
    status="degraded"
  else
    echo "  ✓ $name: up to date ($rec)"
  fi
done

[ "$found" = 1 ] || echo "  (no covered repos with context docs yet)"
echo "Status: repo-context=$status"
exit 0
