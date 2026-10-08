#!/usr/bin/env bash
# File: scripts/tests/test-check-service-access.sh
# Purpose: check-service-access.sh fails when its required service is missing:
#          a stub `gh` whose `auth status` fails → exit 1 with the reason and the
#          fix line; an authenticated stub → exit 0. Runs a copy in a throwaway
#          workspace with a fake HOME, so no real credential is consulted.
set -u
SRC_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT

PASS=0; FAIL=0
ok()  { PASS=$((PASS+1)); echo "  ok: $1"; }
bad() { FAIL=$((FAIL+1)); echo "  FAIL: $1" >&2; }
assert_eq()       { [ "$2" = "$3" ] && ok "$1" || bad "$1 (want [$3] got [$2])"; }
assert_contains() { case "$2" in *"$3"*) ok "$1" ;; *) bad "$1 (no [$3] in [$2])" ;; esac; }

mkdir -p "$TMP/ws/scripts" "$TMP/bin" "$TMP/home"
cp "$SRC_ROOT/scripts/check-service-access.sh" "$TMP/ws/scripts/"
printf '#!/usr/bin/env bash\nexit 3\n' > "$TMP/ws/scripts/jev.sh"   # no key: optional
chmod +x "$TMP/ws/scripts/jev.sh"
# stub gh: `auth status` exits $GH_AUTH_RC
printf '#!/usr/bin/env bash\n[ "$1 $2" = "auth status" ] && exit "${GH_AUTH_RC:-0}"\nexit 0\n' > "$TMP/bin/gh"
chmod +x "$TMP/bin/gh"
run() { HOME="$TMP/home" PATH="$TMP/bin:/usr/bin:/bin" GH_AUTH_RC="$1" bash "$TMP/ws/scripts/check-service-access.sh" 2>&1; }

echo "S1: gh present but not authenticated — required service missing, exit 1"
out="$(run 1)"; rc=$?
assert_eq "S1 exit 1" "$rc" "1"
assert_contains "S1 reason" "$out" "gh not authenticated"
assert_contains "S1 fix line" "$out" "fix: gh auth login"
assert_contains "S1 status" "$out" "Status: degraded"

echo "S2: gh authenticated — exit 0"
out="$(run 0)"; rc=$?
assert_eq "S2 exit 0" "$rc" "0"
assert_contains "S2 ok line" "$out" "gh authenticated"

echo
echo "check-service-access: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
