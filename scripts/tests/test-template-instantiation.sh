#!/usr/bin/env bash
# File: scripts/tests/test-template-instantiation.sh
# Purpose: Clean-room template instantiation test (usage-scenarios Gap 6).
#          Clones the workspace repo into mktemp -d, runs setup.sh and
#          check-workspace-structure.sh, and asserts exit codes + produced
#          structure. Also pins the two doc claims previously caught false
#          (work/usage-scenarios/gaps-and-coverage.md, Gap 6). Offline; only
#          committed state is tested — commit before running.
set -u
SRC_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
# setup.sh writes per-machine state under $HOME (~/.copilot trust seed) —
# sandbox HOME for every setup.sh run so the test never touches the real one.
SANDBOX_HOME="$TMP/home"; mkdir -p "$SANDBOX_HOME"

PASS=0; FAIL=0
ok()   { PASS=$((PASS+1)); echo "  ok: $1"; }
bad()  { FAIL=$((FAIL+1)); echo "  FAIL: $1" >&2; }
assert_eq() { [ "$2" = "$3" ] && ok "$1" || bad "$1 (want [$3] got [$2])"; }
assert_contains() { case "$2" in *"$3"*) ok "$1" ;; *) bad "$1 (no [$3] in [$2])" ;; esac; }

echo "T1: clean-room clone + setup.sh exits 0 and produces per-user copies"
git clone --quiet "$SRC_ROOT" "$TMP/ws" \
  || { bad "T1a: git clone of template"; echo "passed=$PASS failed=$FAIL"; exit 1; }
cd "$TMP/ws"
out=$(HOME="$SANDBOX_HOME" scripts/setup.sh 2>&1); rc=$?
assert_eq "T1a: setup.sh exit 0" "$rc" "0"
assert_contains "T1b: copilot trust seed skipped (no ~/.copilot)" "$out" "skipping trust seed"
for f in .env .mcp.json .claude/settings.local.json; do
  [ -f "$f" ] && ok "T1: created $f" || bad "T1: missing $f"
done
for l in CLAUDE.md AGENTS.md GEMINI.md repos/README.md; do
  { [ -L "$l" ] && [ -e "$l" ]; } && ok "T1: symlink $l resolves" || bad "T1: symlink $l broken"
done

echo "T2: check-workspace-structure.sh passes in the fresh instantiation"
out=$(scripts/check-workspace-structure.sh 2>&1); rc=$?
assert_eq "T2a: exit 0" "$rc" "0"
assert_contains "T2b: all checks passed" "$out" "All checks passed."

echo "T3: setup.sh is idempotent (second run changes nothing)"
out=$(HOME="$SANDBOX_HOME" scripts/setup.sh 2>&1); rc=$?
assert_eq "T3a: exit 0" "$rc" "0"
case "$out" in *"linked "*|*"created "*) bad "T3b: second run re-created something" ;; \
  *) ok "T3b: no re-links/re-copies" ;; esac
[ ! -e CLAUDE.md.bak ] && ok "T3c: no stray CLAUDE.md.bak" || bad "T3c: stray CLAUDE.md.bak"

echo "T4: setup.sh repairs a symlink flattened to a regular file"
rm CLAUDE.md
echo "flattened by a copy-based template flow" > CLAUDE.md
out=$(HOME="$SANDBOX_HOME" scripts/setup.sh 2>&1); rc=$?
assert_eq "T4a: exit 0" "$rc" "0"
{ [ -L CLAUDE.md ] && [ -e CLAUDE.md ]; } && ok "T4b: CLAUDE.md re-linked" || bad "T4b: CLAUDE.md not re-linked"
[ -f CLAUDE.md.bak ] && ok "T4c: flattened file backed up" || bad "T4c: no CLAUDE.md.bak"
rm -f CLAUDE.md.bak

echo "T5: --clone-repos with a placeholder registry is a no-op, exit 0"
printf '# Repos Registry\n\nNo repos onboarded yet.\n' > docs/repos-registry.md
out=$(HOME="$SANDBOX_HOME" scripts/setup.sh --clone-repos 2>&1); rc=$?
assert_eq "T5a: exit 0" "$rc" "0"
assert_contains "T5b: reports no URLs" "$out" "no clone URLs found"
git checkout --quiet docs/repos-registry.md

echo "T6: doc-accuracy pins for claims previously caught false"
if grep -q "the registry matches the on-disk repos" docs/workspace-structure.md; then
  bad "T6a: workspace-structure.md again claims registry<->disk reconciliation (check-workspace-structure.sh does no such check)"
else
  ok "T6a: no registry<->disk reconciliation claim"
fi
if grep -q "regardless of tier" docs/workspace-structure.md; then
  ok "T6b: --clone-repos tier behavior documented honestly"
else
  bad "T6b: missing note that --clone-repos ignores tiers (it clones every registry URL)"
fi

echo "T7: setup.sh seeds Copilot trustedFolders (JSONC-preserving, idempotent)"
if command -v jq >/dev/null 2>&1; then
  mkdir -p "$SANDBOX_HOME/.copilot"
  printf '// managed by copilot\n{"banner":"never"}\n' > "$SANDBOX_HOME/.copilot/config.json"
  out=$(HOME="$SANDBOX_HOME" scripts/setup.sh 2>&1); rc=$?
  assert_eq "T7a: exit 0" "$rc" "0"
  assert_contains "T7b: reports the seed" "$out" "added workspace to trustedFolders"
  cfg="$(cat "$SANDBOX_HOME/.copilot/config.json")"
  assert_contains "T7c: JSONC comment preserved" "$cfg" "// managed by copilot"
  assert_contains "T7d: existing keys preserved" "$cfg" '"banner"'
  if grep -vE '^[[:space:]]*//' "$SANDBOX_HOME/.copilot/config.json" \
       | jq -e --arg r "$(pwd)" '.trustedFolders | index($r)' >/dev/null 2>&1; then
    ok "T7e: workspace root present in trustedFolders"
  else
    bad "T7e: workspace root missing from trustedFolders"
  fi
  out=$(HOME="$SANDBOX_HOME" scripts/setup.sh 2>&1)
  assert_contains "T7f: second run takes the already-trusted path" "$out" "already in trustedFolders"
else
  echo "  skip: jq not installed"
fi

echo; echo "passed=$PASS failed=$FAIL"
[ "$FAIL" -eq 0 ]
