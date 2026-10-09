#!/usr/bin/env bash
# File: scripts/tests/test-run-checks.sh
# Purpose: run-checks.sh contract — finds every scripts/tests/test-* suite and
#          scripts/check-* script under RUN_CHECKS_ROOT, runs each with the
#          right interpreter (exec bit not needed), prints one line per check
#          plus a total, exits 0 only when nothing failed. Exit 77 is a skip
#          with a reason locally, but a FAIL under CI unless the check carries
#          `# run-checks: may-skip-in-ci`; `# run-checks: slow` drops a check
#          from --fast.
set -u
SRC_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
RC="$SRC_ROOT/scripts/run-checks.sh"

PASS=0; FAIL=0
ok()  { PASS=$((PASS+1)); echo "  ok: $1"; }
bad() { FAIL=$((FAIL+1)); echo "  FAIL: $1" >&2; }
assert_eq()       { [ "$2" = "$3" ] && ok "$1" || bad "$1 (want [$3] got [$2])"; }
assert_contains() { case "$2" in *"$3"*) ok "$1" ;; *) bad "$1 (no [$3] in [$2])" ;; esac; }
assert_absent()   { case "$2" in *"$3"*) bad "$1 (found [$3])" ;; *) ok "$1" ;; esac; }

# fixture <dir>: a workspace root with one check of each kind.
fixture() {
  mkdir -p "$1/scripts/tests"
  printf '#!/usr/bin/env bash\necho fine\n' > "$1/scripts/tests/test-pass.sh"
  printf '#!/usr/bin/env bash\necho fine\n' > "$1/scripts/tests/test-noexec.sh"
  printf 'import sys\nprint("py ok")\nsys.exit(0)\n' > "$1/scripts/tests/test-py.py"
  printf '#!/usr/bin/env bash\n# run-checks: slow\necho slow ok\n' > "$1/scripts/tests/test-slow.sh"
  printf '#!/usr/bin/env bash\necho fine\n' > "$1/scripts/check-ok.sh"
  chmod +x "$1/scripts/tests/test-pass.sh" "$1/scripts/tests/test-slow.sh" "$1/scripts/check-ok.sh"
  chmod -x "$1/scripts/tests/test-noexec.sh" "$1/scripts/tests/test-py.py"
}

echo "R1: all pass — one PASS line per check, a total, exit 0"
fixture "$TMP/a"
out="$(RUN_CHECKS_ROOT="$TMP/a" bash "$RC" 2>&1)"; rc=$?
assert_eq "R1 exit" "$rc" "0"
for n in test-pass.sh test-noexec.sh test-py.py test-slow.sh check-ok.sh; do
  assert_contains "R1 PASS $n" "$out" "PASS  $n"
done
assert_contains "R1 total" "$out" "5 passed, 0 failed, 0 skipped"

echo "R2: one failing check — FAIL line with its output tail, others still run, exit 1"
fixture "$TMP/b"
printf '#!/usr/bin/env bash\necho "boom: widget missing" >&2\nexit 3\n' > "$TMP/b/scripts/tests/test-fail.sh"
out="$(RUN_CHECKS_ROOT="$TMP/b" bash "$RC" 2>&1)"; rc=$?
assert_eq "R2 exit" "$rc" "1"
assert_contains "R2 FAIL line" "$out" "FAIL  test-fail.sh"
assert_contains "R2 exit code shown" "$out" "rc=3"
assert_contains "R2 output tail shown" "$out" "boom: widget missing"
assert_contains "R2 later checks still run" "$out" "PASS  test-slow.sh"
assert_contains "R2 total" "$out" "5 passed, 1 failed, 0 skipped"

echo "R3: exit 77 is a skip with the last output line as reason, and does not fail the run"
fixture "$TMP/c"
printf '#!/usr/bin/env bash\necho "probing"\necho "no claude CLI on PATH"\nexit 77\n' > "$TMP/c/scripts/tests/test-skip.sh"
out="$(env -u CI RUN_CHECKS_ROOT="$TMP/c" bash "$RC" 2>&1)"; rc=$?
assert_eq "R3 exit" "$rc" "0"
assert_contains "R3 SKIP line with reason" "$out" "SKIP  test-skip.sh"
assert_contains "R3 reason" "$out" "no claude CLI on PATH"
assert_contains "R3 total" "$out" "5 passed, 0 failed, 1 skipped"

echo "R3b: under CI a skip fails the run, unless the check is marked may-skip-in-ci"
out="$(CI=true RUN_CHECKS_ROOT="$TMP/c" bash "$RC" 2>&1)"; rc=$?
assert_eq "R3b unmarked skip in CI: exit" "$rc" "1"
assert_contains "R3b FAIL line names the skip" "$out" "FAIL  test-skip.sh  (skipped in CI"
assert_contains "R3b reason still shown" "$out" "no claude CLI on PATH"
assert_contains "R3b total" "$out" "5 passed, 1 failed, 0 skipped"
printf '#!/usr/bin/env bash\n# run-checks: may-skip-in-ci\necho "no keychain"\nexit 77\n' > "$TMP/c/scripts/tests/test-skip.sh"
out="$(CI=true RUN_CHECKS_ROOT="$TMP/c" bash "$RC" 2>&1)"; rc=$?
assert_eq "R3b marked skip in CI: exit" "$rc" "0"
assert_contains "R3b marked skip is a SKIP" "$out" "SKIP  test-skip.sh  — no keychain"

echo "R4: --fast leaves out checks marked slow"
out="$(RUN_CHECKS_ROOT="$TMP/a" bash "$RC" --fast 2>&1)"; rc=$?
assert_eq "R4 exit" "$rc" "0"
assert_absent "R4 slow check not run" "$out" "test-slow.sh"
assert_contains "R4 total" "$out" "4 passed, 0 failed, 0 skipped"

echo "R5: --list names the checks without running them; unknown flag exits 2"
out="$(RUN_CHECKS_ROOT="$TMP/a" bash "$RC" --fast --list 2>&1)"; rc=$?
assert_eq "R5 list exit" "$rc" "0"
assert_contains "R5 lists a fast check" "$out" "scripts/tests/test-py.py"
assert_absent "R5 nothing ran" "$out" "PASS"
assert_absent "R5 slow not listed under --fast" "$out" "test-slow.sh"
RUN_CHECKS_ROOT="$TMP/a" bash "$RC" --bogus >/dev/null 2>&1; assert_eq "R5 unknown flag" "$?" "2"

echo "R6: every real check here is listed, and --fast is a strict subset"
full="$(bash "$RC" --list)"; fast="$(bash "$RC" --fast --list)"
for f in "$SRC_ROOT"/scripts/tests/test-* "$SRC_ROOT"/scripts/check-*; do
  assert_contains "R6 lists ${f#"$SRC_ROOT"/}" "$full" "${f#"$SRC_ROOT"/}"
done
[ "$(printf '%s\n' "$fast" | wc -l)" -lt "$(printf '%s\n' "$full" | wc -l)" ] \
  && ok "R6 --fast is smaller" || bad "R6 --fast is not smaller than the full run"

echo "R7: the pre-commit hook blocks a failing commit only after opting in"
HOOK="$SRC_ROOT/scripts/git-hooks/pre-commit"
[ -x "$HOOK" ] && ok "R7 hook is executable" || bad "R7 hook missing or not executable"
G="$TMP/repo"; fixture "$G"; cp "$RC" "$G/scripts/run-checks.sh"; mkdir -p "$G/scripts/git-hooks"; cp "$HOOK" "$G/scripts/git-hooks/"
printf '#!/usr/bin/env bash\necho "boom: widget missing"\nexit 1\n' > "$G/scripts/tests/test-fail.sh"
gc() { git -C "$G" -c user.name=t -c user.email=t@t "$@"; }
gc init -q; gc add -A
gc commit -qm "not opted in" >/dev/null 2>&1; assert_eq "R7 no opt-in: commit goes through" "$?" "0"
gc config core.hooksPath scripts/git-hooks
echo x > "$G/f"; gc add f
err="$(gc commit -qm "opted in" 2>&1)"; rc=$?
assert_eq "R7 opted in: failing check refuses the commit" "$rc" "1"
assert_contains "R7 names the failing check" "$err" "FAIL  test-fail.sh"
rm "$G/scripts/tests/test-fail.sh"; gc add -A
gc commit -qm "fixed" >/dev/null 2>&1; assert_eq "R7 opted in, all green: commit goes through" "$?" "0"

echo
echo "pass=$PASS fail=$FAIL"
[ "$FAIL" -eq 0 ]
