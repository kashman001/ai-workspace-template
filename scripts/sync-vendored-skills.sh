#!/usr/bin/env bash
# Sync the vendored Matt Pocock skills under skills/ from an upstream clone of
# github.com/mattpocock/skills (MIT — see skills/vendored-skills.md).
#
# Two classes of vendored skill:
#   - Pristine: the whole directory is upstream content. Re-copied wholesale;
#     a provenance comment is stamped into SKILL.md below the frontmatter.
#   - Adapted: the SKILL.md frontmatter + provenance comment are workspace-
#     specific and preserved; only the body below the comment (and the
#     supporting files) are re-copied from upstream.
#
# Usage: scripts/sync-vendored-skills.sh [path-to-upstream-clone]
#   (default: $MATTPOCOCK_SKILLS_CLONE, else ~/Developer/references/mattpocock-skills)
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CLONE="${1:-${MATTPOCOCK_SKILLS_CLONE:-$HOME/Developer/references/mattpocock-skills}}"

if [ ! -d "$CLONE/.git" ]; then
  echo "error: upstream clone not found at $CLONE" >&2
  echo "  git clone https://github.com/mattpocock/skills.git \"$CLONE\"" >&2
  exit 1
fi

SHA="$(git -C "$CLONE" rev-parse --short HEAD)"
DATE="$(git -C "$CLONE" log -1 --format=%cd --date=short HEAD)"

PRISTINE=(
  engineering/ask-matt
  engineering/code-review
  engineering/codebase-design
  engineering/diagnosing-bugs
  engineering/domain-modeling
  engineering/grill-with-docs
  engineering/implement
  engineering/improve-codebase-architecture
  engineering/prototype
  engineering/research
  engineering/resolving-merge-conflicts
  engineering/setup-matt-pocock-skills
  engineering/tdd
  engineering/wizard
  productivity/grill-me
  productivity/grilling
  productivity/handoff
  productivity/teach
  productivity/to-questionnaire
  productivity/wait-what
  misc/git-guardrails-claude-code
  misc/setup-pre-commit
)

ADAPTED=(
  engineering/to-spec
  engineering/to-tickets
  engineering/triage
  engineering/wayfinder
  productivity/writing-for-agents
)

# Line number of the closing '---' of the YAML frontmatter.
frontmatter_end() {
  awk '/^---$/{c++; if (c==2) {print NR; exit}}' "$1"
}

for path in "${PRISTINE[@]}"; do
  name="$(basename "$path")"
  src="$CLONE/skills/$path"
  dst="$ROOT/skills/$name"
  [ -d "$src" ] || { echo "error: $src missing upstream — update this script" >&2; exit 1; }
  rsync -a --delete "$src/" "$dst/"
  fm="$(frontmatter_end "$dst/SKILL.md")"
  [ -n "$fm" ] || { echo "error: no frontmatter in $dst/SKILL.md" >&2; exit 1; }
  tmp="$(mktemp)"
  {
    head -n "$fm" "$dst/SKILL.md"
    cat <<EOF

<!--
Vendored from github.com/mattpocock/skills — skills/$path/
at commit $SHA ($DATE). Upstream content (MIT — see
skills/vendored-skills.md); keep this directory unmodified so refreshes
stay a clean re-copy: scripts/sync-vendored-skills.sh.
-->
EOF
    tail -n "+$((fm + 1))" "$dst/SKILL.md"
  } > "$tmp"
  mv "$tmp" "$dst/SKILL.md"
  echo "synced (pristine): $name @ $SHA"
done

for path in "${ADAPTED[@]}"; do
  name="$(basename "$path")"
  src="$CLONE/skills/$path"
  dst="$ROOT/skills/$name"
  head_end="$(grep -n '^-->' "$dst/SKILL.md" | head -1 | cut -d: -f1)"
  [ -n "$head_end" ] || { echo "error: no provenance comment in $dst/SKILL.md — adapted skills need one" >&2; exit 1; }
  fm="$(frontmatter_end "$src/SKILL.md")"
  tmp="$(mktemp)"
  {
    head -n "$head_end" "$dst/SKILL.md" \
      | sed -E "s/at commit [0-9a-f]+ \([0-9-]+\)/at commit $SHA ($DATE)/"
    tail -n "+$((fm + 1))" "$src/SKILL.md"
  } > "$tmp"
  mv "$tmp" "$dst/SKILL.md"
  rsync -a --delete --exclude SKILL.md "$src/" "$dst/"
  echo "synced (adapted):  $name @ $SHA (frontmatter + comment preserved)"
done

echo
echo "Done. Review with: git status skills/ && git diff skills/"
echo "Workspace-authored skills (checkpoint, session-rollover, rlm, ...) are not touched."
