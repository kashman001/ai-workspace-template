#!/usr/bin/env bash
# File: scripts/tests/test-agent-entrypoints.sh
# Purpose: Static agent-entrypoint plumbing check — every runtime's discovery
#          file is a symlink that resolves to the single master CONTEXT.md,
#          and the onboarding canary token is present. This is the automated
#          prerequisite for the live per-runtime checks in
#          docs/agent-onboarding-check.md. Complements
#          check-workspace-structure.sh (which asserts symlinks resolve but
#          not what they point at). Also: every skills/*/SKILL.md opens with
#          the name/description frontmatter runtimes use to find a skill.
set -u
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"

# Keep in sync with the canary line in CONTEXT.md (see
# docs/agent-onboarding-check.md → "Customizing the token").
CANARY_TOKEN="WORKSPACE-CONTEXT-OK"

# Entrypoint symlinks and their expected targets, as "<path>:<target>" pairs.
# A nested entrypoint resolves via a relative target, which a flat name list
# cannot express. Adding a runtime? Register it here, in setup.sh, and in
# check-workspace-structure.sh.
ENTRYPOINTS="CLAUDE.md:CONTEXT.md AGENTS.md:CONTEXT.md GEMINI.md:CONTEXT.md
             .github/copilot-instructions.md:../CONTEXT.md"

PASS=0; FAIL=0
ok()  { PASS=$((PASS+1)); echo "  ok: $1"; }
bad() { FAIL=$((FAIL+1)); echo "  FAIL: $1" >&2; }

echo "E1: each entrypoint is a symlink whose target is CONTEXT.md"
for e in $ENTRYPOINTS; do
  f="${e%%:*}"; t="${e#*:}"
  if [ -L "$f" ] && [ "$(readlink "$f")" = "$t" ]; then
    ok "E1: $f -> $t"
  else
    bad "E1: $f is not a symlink to $t (got: $(readlink "$f" 2>/dev/null || echo 'not a symlink'))"
  fi
done

echo "E2: each entrypoint resolves and reads back CONTEXT.md's content"
for e in $ENTRYPOINTS; do
  f="${e%%:*}"
  if [ -r "$f" ] && head -1 "$f" 2>/dev/null | grep -q '^# .*Workspace Context'; then
    ok "E2: $f reads CONTEXT.md"
  else
    bad "E2: $f does not resolve to CONTEXT.md content (broken symlink?)"
  fi
done

echo "E3: the onboarding canary token is present in CONTEXT.md"
if grep -q "$CANARY_TOKEN" CONTEXT.md; then
  ok "E3: CONTEXT.md carries $CANARY_TOKEN"
else
  bad "E3: CONTEXT.md is missing the canary token $CANARY_TOKEN (see docs/agent-onboarding-check.md)"
fi

echo "E4: the live-check guide exists"
if [ -f docs/agent-onboarding-check.md ]; then
  ok "E4: docs/agent-onboarding-check.md exists"
else
  bad "E4: docs/agent-onboarding-check.md missing"
fi

# skill_fm_problems <skills-dir>: one line per SKILL.md that does not open with
# a --- frontmatter block carrying non-empty name: and description: lines.
skill_fm_problems() {
  local f
  for f in "$1"/*/SKILL.md; do
    [ -f "$f" ] || continue
    awk 'NR==1 { if ($0 != "---") exit 1; next }
         $0 == "---" { closed=1; exit }
         /^name:[ \t]*[^ \t]/ { n=1 } /^description:[ \t]*[^ \t]/ { d=1 }
         END { exit !(closed && n && d) }' "$f" || echo "$f"
  done
}

FM_TMP="$(mktemp -d)"; trap 'rm -rf "$FM_TMP"' EXIT
mkdir -p "$FM_TMP"/{good,bare,nodesc}
printf -- '---\nname: good\ndescription: Does a thing\n---\n# good\n' > "$FM_TMP/good/SKILL.md"
printf -- '# bare — no frontmatter\nname: bare\n' > "$FM_TMP/bare/SKILL.md"
printf -- '---\nname: nodesc\n---\ndescription: too late\n' > "$FM_TMP/nodesc/SKILL.md"
got="$(skill_fm_problems "$FM_TMP" | sed "s|$FM_TMP/||" | tr '\n' ' ')"
if [ "$got" = "bare/SKILL.md nodesc/SKILL.md " ]; then
  ok "E5a: skill frontmatter check flags a fixture with none and one without description"
else
  bad "E5a: skill frontmatter check flagged [$got], want [bare/SKILL.md nodesc/SKILL.md ]"
fi
got="$(skill_fm_problems skills)"
if [ -z "$got" ]; then
  ok "E5b: every skills/*/SKILL.md has name and description frontmatter"
else
  bad "E5b: skills missing name/description frontmatter: $(echo $got)"
fi

echo
echo "pass=$PASS fail=$FAIL"
[ "$FAIL" -eq 0 ]
