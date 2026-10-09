#!/usr/bin/env bash
# File: scripts/check-plans.sh
# Purpose: Lint every committed plan — run `plan.sh check` on each
#          work/<item>/plans/NN-<slug>/ (the node-directory format; older flat
#          plans/*.md files are skipped). One line per plan, plan.sh's
#          violation lines under a failing one. Exits 1 when any plan fails.
# See: docs/plans.md → "Check rules"; tested by scripts/tests/test-check-plans.sh
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

fail=0; n=0
for pm in work/*/plans/[0-9]*/plan.md; do
  [ -f "$pm" ] || continue
  dir="${pm%/plan.md}"; item="${dir#work/}"; item="${item%%/*}"
  n=$((n+1))
  if out="$(bash scripts/plan.sh check --project "$item" --plan "$(basename "$dir")" 2>&1)"; then
    printf '  \033[32m✓\033[0m %s\n' "$dir"
  else
    printf '  \033[31m✗\033[0m %s\n' "$dir" >&2
    printf '%s\n' "$out" | sed 's/^/      /' >&2
    fail=1
  fi
done

if [ "$fail" = 0 ]; then echo "All $n plans pass plan.sh check."; exit 0
else echo "Some plans FAILED plan.sh check." >&2; exit 1; fi
