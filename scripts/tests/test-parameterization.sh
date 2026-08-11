#!/usr/bin/env bash
# File: scripts/tests/test-parameterization.sh
# Purpose: Parameterization guards for tracked files (the suite recommended by
#          docs/workspace-structure.md → "Environment Parameterization"):
#          P1 — no version-pinned Homebrew Cellar paths in docs/scripts
#               (reference keg-only tools via a .env variable or the stable
#               /opt/homebrew/opt/<formula> symlink instead);
#          P2 — a PII ratchet: no NEW tracked files containing the personal
#               identifiers listed in PII_PATTERNS. Baseline-tolerant so a
#               pre-existing scrub backlog doesn't block work, but any new
#               introduction fails. Lower the baseline toward 0 as scrubs
#               land to harden it into a zero-tolerance guard.
set -u
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"

# ── Adopter configuration ────────────────────────────────────────────────────
# P2: extended regexes matching identifiers that must not be committed (e.g.
# personal email addresses: 'jane\.doe@corp\.example'). Empty = P2 skips.
# Shared test-fixture identities that runbooks legitimately need should NOT be
# listed here. When you add patterns, set PII_BASELINE to the current count
# reported by this test, then ratchet it down as you scrub.
PII_PATTERNS=""
PII_BASELINE=0

PASS=0; FAIL=0; SKIP=0
ok()   { PASS=$((PASS+1)); echo "  ok: $1"; }
bad()  { FAIL=$((FAIL+1)); echo "  FAIL: $1" >&2; }
skip() { SKIP=$((SKIP+1)); echo "  skip: $1"; }

echo "P1: no version-pinned Homebrew Cellar paths in tracked files"
# work/ holds session/state records where historical paths are fine.
P1_HITS=$(git grep -Il '/opt/homebrew/Cellar/' -- . \
  ':(exclude)work/' ':(exclude)scripts/tests/' 2>/dev/null || true)
if [ -z "$P1_HITS" ]; then
  ok "P1: no hardcoded Cellar paths"
else
  bad "P1: version-pinned Cellar paths in: $(echo "$P1_HITS" | tr '\n' ' ')"
fi

echo "P2: PII ratchet — no new tracked files with personal identifiers"
if [ -z "$PII_PATTERNS" ]; then
  skip "P2: no PII_PATTERNS configured (set them when instantiating the template)"
else
  P2_COUNT=$(git grep -Il -E "$PII_PATTERNS" -- . \
    ':(exclude)scripts/tests/' 2>/dev/null | wc -l | tr -d ' ')
  if [ "${P2_COUNT:-0}" -le "$PII_BASELINE" ]; then
    ok "P2: $P2_COUNT files <= baseline $PII_BASELINE"
  else
    bad "P2: new personal identifier(s) introduced ($P2_COUNT > baseline $PII_BASELINE) — scrub before commit"
  fi
fi

echo
echo "pass=$PASS fail=$FAIL skip=$SKIP"
[ "$FAIL" -eq 0 ]
