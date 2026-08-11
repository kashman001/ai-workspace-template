#!/usr/bin/env bash
# File: scripts/tests/test-rollover-prep.sh
# Purpose: Regression tests for rollover-prep.sh (rollover-cost analysis R1).
#          Self-contained: throwaway workspace in mktemp -d with stubbed
#          context-budget.sh / capture-rollover-options.sh; exercises the
#          archive rotation invariants (lossless split, PURPOSE comment
#          intact, newest-on-top archive) and the fail-open paths.
set -u
SRC_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/scripts" "$TMP/work/testproj"
cp "$SRC_ROOT/scripts/rollover-prep.sh" "$TMP/scripts/"

# Stubs: record the calls, produce recognizable output.
cat > "$TMP/scripts/context-budget.sh" <<'EOF'
#!/usr/bin/env bash
echo "stub-record label=[$3]"
exit 1
EOF
cat > "$TMP/scripts/capture-rollover-options.sh" <<'EOF'
#!/usr/bin/env bash
echo "ROLLOVER_OPT_APPROVAL=auto" > "$(dirname "$0")/../work/$1/.rollover-options"
echo "stub-capture project=[$1]"
EOF
chmod +x "$TMP/scripts/"*.sh
git -C "$TMP" init -q 2>/dev/null || true
RP="$TMP/scripts/rollover-prep.sh"
HF="$TMP/work/testproj/handoff.md"
AF="$TMP/work/testproj/handoff-archive.md"

PASS=0; FAIL=0
ok()   { PASS=$((PASS+1)); echo "  ok: $1"; }
bad()  { FAIL=$((FAIL+1)); echo "  FAIL: $1" >&2; }
assert_eq() { [ "$2" = "$3" ] && ok "$1" || bad "$1 (want [$3] got [$2])"; }
assert_contains() { case "$2" in *"$3"*) ok "$1" ;; *) bad "$1 (no [$3] in [$2])" ;; esac; }
assert_not_contains() { case "$2" in *"$3"*) bad "$1 (unexpected [$3])" ;; *) ok "$1" ;; esac; }

mk_handoff() {  # 3 blocks, newest-first, plus the hazardous PURPOSE comment
  cat > "$HF" <<'EOF'
<!--
PURPOSE: This is the LEDGER (provenance log). Append-only, newest block on TOP.
Each "# Session Handoff" block records what happened in one session.
Convention: docs/work-directory-conventions.md.
-->

# Session Handoff — 2026-08-10 (session 3)

newest block body.

# Session Handoff — 2026-08-09 (session 2)

middle block body.

# Session Handoff — 2026-08-08 (session 1)

oldest block body.
EOF
}

echo "T1: 3-block handoff rotates to 1 + archive gets 2, newest-on-top"
mk_handoff; rm -f "$AF"
before="$(cat "$HF")"
out="$("$RP" testproj --no-record 2>&1)"; rc=$?
assert_eq       "T1a: exit 0" "$rc" "0"
assert_contains "T1b: reports rotation" "$out" "rotated 2 block(s)"
assert_eq       "T1c: handoff keeps 1 block" "$(grep -c '^# Session Handoff' "$HF")" "1"
assert_contains "T1d: newest stayed" "$(cat "$HF")" "session 3"
assert_eq       "T1e: archive holds 2 blocks" "$(grep -c '^# Session Handoff' "$AF")" "2"
assert_eq       "T1f: archive newest-on-top" \
  "$(grep '^# Session Handoff' "$AF" | head -1)" "# Session Handoff — 2026-08-09 (session 2)"
assert_contains "T1g: PURPOSE comment intact" "$(cat "$HF")" 'Each "# Session Handoff" block records'
assert_eq       "T1h: split lossless (recompose)" \
  "$(cat "$HF"; sed -n '/^# Session Handoff — 2026-08-09/,$p' "$AF")" "$before"

echo "T2: rotation prepends to an EXISTING archive"
mk_handoff
printf '# Session Handoff — 2026-08-01 (session 0)\n\nancient block.\n' > "$AF"
out="$("$RP" testproj --no-record 2>&1)"
assert_eq       "T2a: archive holds 3 blocks" "$(grep -c '^# Session Handoff' "$AF")" "3"
assert_eq       "T2b: moved blocks above ancient one" \
  "$(grep '^# Session Handoff' "$AF" | tail -1)" "# Session Handoff — 2026-08-01 (session 0)"

echo "T3: single-block handoff — no rotation"
printf '# Session Handoff — solo\n\nbody.\n' > "$HF"; rm -f "$AF"
out="$("$RP" testproj --no-record 2>&1)"
assert_contains "T3a: reports no-op" "$out" "no rotation needed"
assert_eq       "T3b: no archive created" "$([ -f "$AF" ] && echo yes || echo no)" "no"

echo "T4: missing handoff.md — fail open"
rm -f "$HF" "$AF"
out="$("$RP" testproj --no-record 2>&1)"; rc=$?
assert_eq       "T4a: exit 0" "$rc" "0"
assert_contains "T4b: notes absence" "$out" "no handoff.md"

echo "T5: no trailing newline on handoff.md — archive still well-formed"
mk_handoff; rm -f "$AF"
printf '%s' "$(cat "$HF")" > "$HF"   # strip trailing newline
out="$("$RP" testproj --no-record 2>&1)"
assert_eq       "T5a: archive holds 2 blocks" "$(grep -c '^# Session Handoff' "$AF")" "2"
assert_eq       "T5b: handoff keeps 1 block" "$(grep -c '^# Session Handoff' "$HF")" "1"

echo "T6: top block, session-seq, options, and stub invocations in output"
mk_handoff
echo "7" > "$TMP/work/testproj/.session-seq"
out="$("$RP" testproj --no-record 2>&1)"
assert_contains "T6a: top block printed" "$out" "newest block body."
assert_contains "T6b: session-seq printed" "$out" "7"
assert_contains "T6c: capture stub invoked" "$out" "stub-capture project=[testproj]"
assert_contains "T6d: options echoed" "$out" "ROLLOVER_OPT_APPROVAL=auto"
assert_not_contains "T6e: record skipped under --no-record" "$out" "stub-record"

echo "T7: record runs by default with the reason label; WARN exit tolerated"
out="$("$RP" testproj --reason "hook WARN mid-unit" 2>&1)"; rc=$?
assert_eq       "T7a: exit 0 despite stub exit 1" "$rc" "0"
assert_contains "T7b: record invoked with label" "$out" "stub-record label=[rollover start: hook WARN mid-unit]"

echo "T8: git summary lists dirty paths of the workspace root"
touch "$TMP/dirty-file.txt"
out="$("$RP" testproj --no-record 2>&1)"
assert_contains "T8a: root section present" "$out" "(workspace root)"
assert_contains "T8b: dirty file listed" "$out" "dirty-file.txt"

echo "T9: usage errors"
"$RP" >/dev/null 2>&1; assert_eq "T9a: no project -> exit 1" "$?" "1"
"$RP" nosuchproj --no-record >/dev/null 2>&1; assert_eq "T9b: unknown project -> exit 1" "$?" "1"
"$RP" testproj --bogus >/dev/null 2>&1; assert_eq "T9c: unknown flag -> exit 1" "$?" "1"
"$RP" testproj --reason >/dev/null 2>&1; assert_eq "T9d: --reason without value -> exit 1 (no hang)" "$?" "1"

echo
echo "pass=$PASS fail=$FAIL"
[ "$FAIL" -eq 0 ]
