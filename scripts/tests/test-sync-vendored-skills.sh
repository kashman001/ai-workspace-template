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
#          Three upstreams (mattpocock, addyosmani, pstack): each stamps its own
#          repo in the comment; addyosmani's shared references/ files are
#          copied and stamped; pstack pins the last commit touching pstack/;
#          adapted skills get their patch re-applied and keep a local
#          agents/openai.yaml upstream lacks; a no-arg run syncs every clone
#          present and exits 1 naming the missing ones.
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

# The entries the script syncs, read from its <key>_PRISTINE/_ADAPTED/_REFERENCES arrays.
list() { sed -n "/^$1=(/,/^)/p" "$SYNC" | grep -E '^  [a-z]' | tr -d ' '; }

# skills <dir> <skill-dir-in-clone> <array>...: fake upstream skills.
skills() {
  local d="$1" sub="$2"; shift 2
  for p in $(for a in "$@"; do list "$a"; done); do
    mkdir -p "$d/$sub/$p"
    printf -- '---\nname: %s\ndescription: up\n---\n\nUpstream body line 1.\nUpstream body line 2.\n' \
      "$(basename "$p")" > "$d/$sub/$p/SKILL.md"
    printf 'extra\n' > "$d/$sub/$p/extra.md"
  done
}
commit() { git -C "$1" add -A && git -C "$1" -c user.name=t -c user.email=t@t commit -qm "$2"; }

# upstream <dir>: a git clone holding every listed mattpocock skill.
upstream() {
  skills "$1" skills mattpocock_PRISTINE mattpocock_ADAPTED
  git -C "$1" init -q && commit "$1" up
}

# workspace <dir> [<adapted array>]: adapted skills carry local frontmatter + provenance comment.
workspace() {
  for p in $(list "${2:-mattpocock_ADAPTED}"); do
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

# Second workspace for the three-upstream cases, synced with no args.
ADDY="$TMP/addy"; CP="$TMP/cp"; WS="$TMP/ws2"
skills "$ADDY" skills addyosmani_PRISTINE addyosmani_ADAPTED
mkdir -p "$ADDY/references"
for f in $(list addyosmani_REFERENCES); do printf '# %s\n\nRef body.\n' "$f" > "$ADDY/references/$f"; done
printf -- '---\ntitle: sec\n---\n\n# Security\n' > "$ADDY/references/security-checklist.md"
git -C "$ADDY" init -q && commit "$ADDY" up
skills "$CP" pstack/skills pstack_PRISTINE pstack_ADAPTED
git -C "$CP" init -q && commit "$CP" pstack
PSHA="$(git -C "$CP" rev-parse --short HEAD)"
mkdir -p "$CP/other" && printf 'x\n' > "$CP/other/f" && commit "$CP" other
workspace "$WS" mattpocock_ADAPTED; workspace "$WS" pstack_ADAPTED
mkdir -p "$WS/scripts" "$WS/skills/unslop/agents" && cp "$SYNC" "$WS/scripts/"
printf 'local: yes\n' > "$WS/skills/unslop/agents/openai.yaml"
(cd "$TMP/patch" && diff -u a/SKILL.md b/SKILL.md) > "$WS/skills/blast-radius/workspace.patch"
sync3() {
  env MATTPOCOCK_SKILLS_CLONE="$TMP/up" ADDYOSMANI_AGENT_SKILLS_CLONE="${ADDY_CLONE:-$ADDY}" \
    CURSOR_PLUGINS_CLONE="$CP" bash "$WS/scripts/sync-vendored-skills.sh" "$@" 2>&1
}

echo "S9: no-arg run syncs all three upstreams"
out="$(sync3)"; rc=$?
assert_eq "exit 0" "$rc" "0"
md="$(cat "$WS/skills/security-and-hardening/SKILL.md" 2>/dev/null)"
assert_contains "addyosmani pristine names its repo" "$md" "Vendored from github.com/addyosmani/agent-skills — skills/security-and-hardening/"
assert_contains "addyosmani pristine keeps body" "$md" "Upstream body line 2."
md="$(cat "$WS/skills/unslop/SKILL.md")"
assert_contains "pstack adapted keeps local frontmatter" "$md" "name: local"
assert_contains "pstack pin is the last commit touching pstack/" "$md" "at commit $PSHA ("
assert_contains "pstack adapted gets upstream body" "$md" "Upstream body line 1."
assert_eq "adapted keeps a local agents/openai.yaml upstream lacks" "$(cat "$WS/skills/unslop/agents/openai.yaml" 2>/dev/null)" "local: yes"
md="$(cat "$WS/skills/blast-radius/SKILL.md")"
assert_contains "adapted skill has its patch applied" "$md" "Workspace line 2."
assert_absent  "adapted patched skill lost the upstream line" "$md" "Upstream body line 2."
[ -f "$WS/skills/blast-radius/workspace.patch" ] && ok "adapted rsync keeps workspace.patch" || bad "adapted workspace.patch deleted"
r="$WS/references/performance-checklist.md"
assert_eq "reference without frontmatter: comment first" "$(head -1 "$r" 2>/dev/null)" "<!--"
assert_eq "reference stamp names its path" "$(sed -n 2p "$r" 2>/dev/null)" "Vendored from github.com/addyosmani/agent-skills — references/performance-checklist.md"
assert_eq "reference: blank line, then upstream content" "$(awk '/^-->/{getline a; getline b; print "[" a "]" b; exit}' "$r" 2>/dev/null)" "[]# performance-checklist.md"
r="$WS/references/security-checklist.md"
assert_eq "reference with frontmatter: frontmatter kept first" "$(head -3 "$r" 2>/dev/null | tr '\n' '|')" "---|title: sec|---|"
assert_eq "reference with frontmatter: comment after it" "$(sed -n 5,6p "$r" 2>/dev/null | tr '\n' '|')" "<!--|Vendored from github.com/addyosmani/agent-skills — references/security-checklist.md|"
assert_contains "reference keeps body" "$(cat "$r" 2>/dev/null)" "# Security"
assert_contains "reference stamp says keep unmodified" "$(cat "$r" 2>/dev/null)" "keep unmodified: scripts/sync-vendored-skills.sh."

echo "S10: an adapted skill's patch that no longer applies fails, naming the skill"
printf -- '--- a/SKILL.md\n+++ b/SKILL.md\n@@ -1,2 +1,2 @@\n Nonexistent context.\n-Gone line.\n+New line.\n' \
  > "$WS/skills/blast-radius/workspace.patch"
out="$(sync3 pstack)"; rc=$?
assert_eq "exit non-zero" "$([ "$rc" -ne 0 ] && echo nz || echo 0)" "nz"
assert_contains "error names the skill" "$out" "skills/blast-radius/workspace.patch no longer applies"
(cd "$TMP/patch" && diff -u a/SKILL.md b/SKILL.md) > "$WS/skills/blast-radius/workspace.patch"

echo "S11: no-arg run with one clone missing — others sync, exit 1"
mkdir -p "$WS/skills/grill-me"; printf 'stale\n' > "$WS/skills/grill-me/stale.md"; printf 'stale\n' > "$WS/skills/unslop/stale.md"
out="$(ADDY_CLONE="$TMP/none" sync3)"; rc=$?
assert_eq "exit 1" "$rc" "1"
assert_contains "prints the clone instruction" "$out" "git clone https://github.com/addyosmani/agent-skills.git \"$TMP/none\""
[ -f "$WS/skills/grill-me/stale.md" ] && bad "mattpocock not synced" || ok "mattpocock still synced"
[ -f "$WS/skills/unslop/stale.md" ] && bad "pstack not synced" || ok "pstack still synced"

echo "S12: a named upstream with its clone missing — exit 1"
out="$(ADDY_CLONE="$TMP/none" sync3 addyosmani)"; rc=$?
assert_eq "exit 1" "$rc" "1"
assert_contains "names the missing clone" "$out" "upstream clone not found at $TMP/none"

echo
echo "sync-vendored-skills: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
