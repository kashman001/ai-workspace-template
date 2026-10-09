#!/usr/bin/env bash
# File: scripts/tests/test-sync-vendored-skills.sh
# Purpose: sync-vendored-skills.sh contract — over a fake upstream clone and a
#          fixture workspace (the script runs from a copy inside it): pristine skills are re-copied with a
#          provenance comment, adapted skills keep their frontmatter + comment,
#          and a patched skill (a pristine skill carrying workspace.patch) gets
#          its patch re-applied after the re-copy; a patch that no longer
#          applies fails the sync, naming the skill. A patch's `Upstream:`
#          issue, checked via a stubbed gh, yields a delete-the-patch hint when
#          closed and nothing when open, unlinked, gh-less, or gh fails.
set -u
SRC_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
SYNC="$SRC_ROOT/scripts/sync-vendored-skills.sh"

PASS=0; FAIL=0
ok()  { PASS=$((PASS+1)); echo "  ok: $1"; }
bad() { FAIL=$((FAIL+1)); echo "  FAIL: $1" >&2; }
assert_eq()       { [ "$2" = "$3" ] && ok "$1" || bad "$1 (want [$3] got [$2])"; }
assert_contains() { case "$2" in *"$3"*) ok "$1" ;; *) bad "$1 (no [$3] in [$2])" ;; esac; }
assert_absent()   { case "$2" in *"$3"*) bad "$1 (found [$3])" ;; *) ok "$1" ;; esac; }

# The skill paths the script syncs, read from its PRISTINE/ADAPTED arrays.
list() { sed -n "/^$1=(/,/^)/p" "$SYNC" | grep -E '^  [a-z]' | tr -d ' '; }

# upstream <dir>: a git clone holding every listed skill.
upstream() {
  for p in $(list PRISTINE) $(list ADAPTED); do
    mkdir -p "$1/skills/$p"
    printf -- '---\nname: %s\ndescription: up\n---\n\nUpstream body line 1.\nUpstream body line 2.\n' \
      "$(basename "$p")" > "$1/skills/$p/SKILL.md"
    printf 'extra\n' > "$1/skills/$p/extra.md"
  done
  git -C "$1" init -q && git -C "$1" add -A \
    && git -C "$1" -c user.name=t -c user.email=t@t commit -qm up
}

# workspace <dir>: adapted skills carry local frontmatter + provenance comment.
workspace() {
  for p in $(list ADAPTED); do
    mkdir -p "$1/skills/$(basename "$p")"
    printf -- '---\nname: local\n---\n\n<!--\nAdapted; at commit 0000000 (2000-01-01).\n-->\nold body\n' \
      > "$1/skills/$(basename "$p")/SKILL.md"
  done
}

upstream "$TMP/up"
workspace "$TMP/ws"
mkdir -p "$TMP/ws/scripts" && cp "$SYNC" "$TMP/ws/scripts/"
mkdir -p "$TMP/ws/skills/tdd"
printf 'stale\n' > "$TMP/ws/skills/tdd/stale.md"

# A patch that applies: replace body line 2 in tdd.
mkdir -p "$TMP/patch/a" "$TMP/patch/b"
printf 'Upstream body line 1.\nUpstream body line 2.\n' > "$TMP/patch/a/SKILL.md"
printf 'Upstream body line 1.\nWorkspace line 2.\n' > "$TMP/patch/b/SKILL.md"
(cd "$TMP/patch" && diff -u a/SKILL.md b/SKILL.md) > "$TMP/ws/skills/tdd/workspace.patch"

echo "S1: pristine, adapted, and patched skills sync"
out="$(bash "$TMP/ws/scripts/sync-vendored-skills.sh" "$TMP/up" 2>&1)"; rc=$?
assert_eq "exit 0" "$rc" "0"
md="$(cat "$TMP/ws/skills/grill-me/SKILL.md")"
assert_contains "pristine gets provenance comment" "$md" "Vendored from github.com/mattpocock/skills — skills/productivity/grill-me/"
assert_contains "pristine keeps upstream body" "$md" "Upstream body line 2."
md="$(cat "$TMP/ws/skills/to-spec/SKILL.md")"
assert_contains "adapted keeps local frontmatter" "$md" "name: local"
assert_absent  "adapted provenance SHA refreshed" "$md" "0000000"
assert_contains "adapted gets upstream body" "$md" "Upstream body line 1."
assert_absent  "adapted drops old body" "$md" "old body"
md="$(cat "$TMP/ws/skills/tdd/SKILL.md")"
assert_contains "patched skill has the patch applied" "$md" "Workspace line 2."
assert_absent  "patched skill lost the upstream line" "$md" "Upstream body line 2."
assert_contains "patched provenance names the patch" "$md" "skills/tdd/workspace.patch"
[ -f "$TMP/ws/skills/tdd/workspace.patch" ] && ok "rsync --delete keeps workspace.patch" || bad "workspace.patch deleted"
[ -f "$TMP/ws/skills/tdd/stale.md" ] && bad "stale file survived re-copy" || ok "stale file removed"
assert_contains "reports patched class" "$out" "synced (patched):"
ls "$TMP/ws/skills/tdd" | grep -qE '\.(orig|rej)$' && bad "patch left .orig/.rej files" || ok "no .orig/.rej files"

echo "S2: a patch that no longer applies fails, naming the skill"
printf -- '--- a/SKILL.md\n+++ b/SKILL.md\n@@ -1,2 +1,2 @@\n Nonexistent context.\n-Gone line.\n+New line.\n' \
  > "$TMP/ws/skills/tdd/workspace.patch"
out="$(bash "$TMP/ws/scripts/sync-vendored-skills.sh" "$TMP/up" 2>&1)"; rc=$?
assert_eq "exit non-zero" "$([ "$rc" -ne 0 ] && echo nz || echo 0)" "nz"
assert_contains "error names the skill" "$out" "tdd"
assert_contains "error says the patch failed" "$out" "workspace.patch"

# Upstream-link check. Tools the sync needs, linked into one dir so PATH can
# hold exactly them (plus an optional gh stub) on macOS and Linux alike.
TOOLS="$TMP/tools"; mkdir -p "$TOOLS"
for t in bash env git rsync patch awk sed grep head tail cut tr mktemp mv cat basename dirname; do
  ln -s "$(command -v "$t")" "$TOOLS/$t"
done
STUB="$TMP/stub"; mkdir -p "$STUB"
# gh stub: logs its args, prints $GH_STATE, exits $GH_RC.
printf '#!/bin/sh\necho "$*" >> "%s/gh.log"\n[ -n "$GH_STATE" ] && echo "$GH_STATE"\nexit "${GH_RC:-0}"\n' "$TMP" > "$STUB/gh"
chmod +x "$STUB/gh"
HINT="upstream may have landed this; delete the patch"
# upstream_patch <Upstream value>: the applying tdd patch with that header line.
upstream_patch() {
  { printf 'Upstream: %s\n\n' "$1"
    (cd "$TMP/patch" && diff -u a/SKILL.md b/SKILL.md); } > "$TMP/ws/skills/tdd/workspace.patch"
}
sync_with() { env PATH="$1" GH_STATE="${2:-}" GH_RC="${3:-0}" bash "$TMP/ws/scripts/sync-vendored-skills.sh" "$TMP/up" 2>&1; }

echo "S3: a patch whose upstream issue is closed — hint names skill and issue"
upstream_patch "owner/repo#42"; rm -f "$TMP/gh.log"
out="$(sync_with "$STUB:$TOOLS" closed)"; rc=$?
assert_eq "exit 0" "$rc" "0"
assert_contains "patch with header still applies" "$(cat "$TMP/ws/skills/tdd/SKILL.md")" "Workspace line 2."
assert_contains "hint shown" "$out" "$HINT"
assert_contains "hint names the skill" "$out" "skills/tdd/workspace.patch"
assert_contains "hint names the issue" "$out" "owner/repo#42"
assert_contains "gh asked about that issue" "$(cat "$TMP/gh.log" 2>/dev/null)" "repos/owner/repo/issues/42"

echo "S4: open issue — no hint"
upstream_patch "owner/repo#42"
out="$(sync_with "$STUB:$TOOLS" open)"; rc=$?
assert_eq "exit 0" "$rc" "0"
assert_absent "no hint" "$out" "$HINT"

echo "S5: gh fails (offline/unauthenticated) — quiet"
upstream_patch "owner/repo#42"
out="$(sync_with "$STUB:$TOOLS" "" 1)"; rc=$?
assert_eq "exit 0" "$rc" "0"
assert_absent "no hint" "$out" "$HINT"
assert_absent "no gh noise" "$out" "gh"

echo "S6: gh not installed — quiet"
upstream_patch "owner/repo#42"
out="$(sync_with "$TOOLS")"; rc=$?
assert_eq "exit 0" "$rc" "0"
assert_absent "no hint" "$out" "$HINT"
assert_absent "no command-not-found noise" "$out" "not found"

echo "S7: no issue filed — gh not called, quiet"
upstream_patch "none filed"; rm -f "$TMP/gh.log"
out="$(sync_with "$STUB:$TOOLS" closed)"; rc=$?
assert_eq "exit 0" "$rc" "0"
assert_absent "no hint" "$out" "$HINT"
[ -f "$TMP/gh.log" ] && bad "gh called without a link" || ok "gh not called"

echo "S8: closed issue and a patch that no longer applies — hint precedes the failure"
printf -- 'Upstream: owner/repo#42\n\n--- a/SKILL.md\n+++ b/SKILL.md\n@@ -1,2 +1,2 @@\n Nonexistent context.\n-Gone line.\n+New line.\n' \
  > "$TMP/ws/skills/tdd/workspace.patch"
out="$(sync_with "$STUB:$TOOLS" closed)"; rc=$?
assert_eq "exit non-zero" "$([ "$rc" -ne 0 ] && echo nz || echo 0)" "nz"
assert_contains "hint shown" "$out" "$HINT"

echo
echo "sync-vendored-skills: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
