#!/usr/bin/env bash
# File: scripts/tests/test-template-version.sh
# Purpose: The workspace-level template version marker (TEMPLATE_VERSION at
#          the root) exists, parses, is named by the docs, and survives the
#          instantiation/prune path in docs/template-usage.md §5. Runs against
#          the working tree (tracked + untracked-not-ignored files), so it is
#          green before the commit. Ticket 03 of
#          work/session-management-followups (M42). Offline.
set -u
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"; cd "$ROOT"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
PASS=0; FAIL=0
ok()   { PASS=$((PASS+1)); echo "  ok: $1"; }
bad()  { FAIL=$((FAIL+1)); echo "  FAIL: $1" >&2; }
assert_eq() { [ "$2" = "$3" ] && ok "$1" || bad "$1 (want [$3] got [$2])"; }

MARKER=TEMPLATE_VERSION
# The value is what remains after '#' comment lines and blank lines.
value_of() { grep -v '^#' "$1" 2>/dev/null | grep -v '^[[:space:]]*$'; }

echo "V1: $MARKER exists at the root and parses"
[ -f "$MARKER" ] && ok "V1a: $MARKER present" || bad "V1a: $MARKER missing"
value="$(value_of "$MARKER")"
assert_eq "V1b: exactly one value line" "$(printf '%s\n' "$value" | grep -c .)" "1"
case "$value" in
  [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9])
    m=$((10#${value:5:2})); d=$((10#${value:8:2}))
    if [ "$m" -ge 1 ] && [ "$m" -le 12 ] && [ "$d" -ge 1 ] && [ "$d" -le 31 ]; then
      ok "V1c: value is an ISO date ($value)"
    else bad "V1c: month/day out of range ($value)"; fi ;;
  *) bad "V1c: value is not YYYY-MM-DD ([$value])" ;;
esac

echo "V2: the docs name the marker"
grep -q "$MARKER" docs/template-usage.md && ok "V2a: docs/template-usage.md names $MARKER" \
  || bad "V2a: docs/template-usage.md does not name $MARKER"
grep -q "$MARKER" docs/workspace-structure.md && ok "V2b: docs/workspace-structure.md tree names $MARKER" \
  || bad "V2b: docs/workspace-structure.md does not name $MARKER"

echo "V3: the marker survives the §5 prune (no-git form, on a copy of the working tree)"
mkdir "$TMP/ws"
git ls-files -co --exclude-standard -z | tar -c --null -T - -f - | tar -x -C "$TMP/ws" -f -
# The wholesale command is taken from the doc itself, so the test follows the
# doc when the prune list changes; the template-only files are the ones §5
# lists individually.
wholesale="$(grep -m1 '^git rm -r ' docs/template-usage.md | sed 's/^git rm -r //')"
[ -n "$wholesale" ] && ok "V3a: §5 wholesale prune command found ($wholesale)" \
  || bad "V3a: no 'git rm -r …' line in docs/template-usage.md §5"
( cd "$TMP/ws" && eval "rm -r $wholesale" && rm -f docs/template-usage.md LICENSE ) \
  && ok "V3b: prune ran on the copy" || bad "V3b: prune failed on the copy"
[ -f "$TMP/ws/$MARKER" ] && ok "V3c: $MARKER survives the prune" || bad "V3c: $MARKER gone after the prune"
assert_eq "V3d: value unchanged after the prune" "$(value_of "$TMP/ws/$MARKER")" "$value"

echo; echo "passed=$PASS failed=$FAIL"
[ "$FAIL" -eq 0 ]
