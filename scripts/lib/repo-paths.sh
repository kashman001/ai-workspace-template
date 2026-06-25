#!/usr/bin/env bash
# File: scripts/lib/repo-paths.sh
# Purpose: Shared helper sourced by onboard-repo.sh and check-repo-context.sh so the
#          two stay in sync (they previously carried divergent copies). Resolve an
#          onboarded repo's working path from its registry "Location" first — so a repo
#          onboarded in place at an external/local path is found — then repos/<name>,
#          then the workspace root. Source from the workspace root (cwd == ROOT).
# See: docs/superpowers/specs/2026-06-24-repo-onboarding-design.md

# resolve_repo_path <repo-name>
#   Prints a path that exists, or "." as a last resort. Reads docs/repos-registry.md
#   relative to the current directory (callers cd to the workspace root first).
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
