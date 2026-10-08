#!/usr/bin/env bash
# File: scripts/run-checks.sh
# Purpose: Run every scripts/tests/test-* suite and every scripts/check-* script,
#          one pass/fail line each plus a total. Exit 0 only when nothing failed.
#          The pre-commit hook (scripts/git-hooks/pre-commit) runs --fast; CI
#          (.github/workflows/checks.yml) runs the full set.
# Conventions a check can use:
#   - a line `# run-checks: slow` anywhere in it → left out of --fast
#     (mark anything that takes more than ~3s or needs the network)
#   - exit 77 → SKIP, not FAIL; its last output line is printed as the reason
#     (for a check that needs something a CI runner lacks: a CLI, a keychain)
# See: docs/workspace-structure.md → "scripts/ — Bootstrap and Utility Scripts"
set -uo pipefail

ROOT="${RUN_CHECKS_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
FAST=0; LIST=0
for a in "$@"; do
  case "$a" in
    --fast) FAST=1 ;;
    --list) LIST=1 ;;
    -h|--help) sed -n '2,11p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "run-checks: unknown argument: $a (use --fast, --list)" >&2; exit 2 ;;
  esac
done

checks=()
for f in "$ROOT"/scripts/tests/test-* "$ROOT"/scripts/check-*; do
  [ -f "$f" ] || continue
  [ "$FAST" -eq 1 ] && grep -q '^# run-checks: slow' "$f" && continue
  checks+=("$f")
done

if [ "$LIST" -eq 1 ]; then
  for f in "${checks[@]}"; do echo "${f#"$ROOT"/}"; done
  exit 0
fi

LOG="$(mktemp -d)"; trap 'rm -rf "$LOG"' EXIT
passed=0; failed=0; skipped=0
start_all=$SECONDS
for f in "${checks[@]}"; do
  n="$(basename "$f")"
  case "$f" in *.py) run=(python3 "$f") ;; *) run=(bash "$f") ;; esac
  t0=$SECONDS
  (cd "$ROOT" && "${run[@]}") </dev/null >"$LOG/$n" 2>&1; rc=$?
  dt=$((SECONDS - t0))
  if [ "$rc" -eq 0 ]; then
    passed=$((passed+1)); printf 'PASS  %s  (%ss)\n' "$n" "$dt"
  elif [ "$rc" -eq 77 ]; then
    skipped=$((skipped+1)); printf 'SKIP  %s  — %s\n' "$n" "$(tail -1 "$LOG/$n")"
  else
    failed=$((failed+1)); printf 'FAIL  %s  (rc=%s, %ss)\n' "$n" "$rc" "$dt"
    tail -15 "$LOG/$n" | sed 's/^/      | /'
  fi
done

printf '\nrun-checks%s: %d passed, %d failed, %d skipped (%ss)\n' \
  "$([ "$FAST" -eq 1 ] && echo ' --fast')" "$passed" "$failed" "$skipped" "$((SECONDS - start_all))"
[ "$failed" -eq 0 ]
