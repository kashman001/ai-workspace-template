#!/usr/bin/env bash
# Sync the vendored Matt Pocock skills under skills/ from an upstream clone of
# github.com/mattpocock/skills (MIT — see skills/vendored-skills.md).
#
# Three classes of vendored skill:
#   - Pristine: the whole directory is upstream content. Re-copied wholesale;
#     a provenance comment is stamped into SKILL.md below the frontmatter.
#   - Patched: a PRISTINE entry whose directory holds a workspace.patch. It is
#     re-copied like a pristine skill (the patch file is kept), then the patch
#     is re-applied; the sync fails, naming the skill, if it no longer applies.
#     A patch may open with an `Upstream: <owner>/<repo>#<N>` line (before the
#     diff, where patch ignores it). When gh reports that issue or PR closed,
#     the sync prints a hint to delete the patch; it says nothing when gh is
#     missing or the call fails, or when there is no such line.
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
  engineering/implement-spec
  engineering/improve-codebase-architecture
  engineering/pr
  engineering/prototype
  engineering/research
  engineering/retro
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

# upstream_hint <name> <patch>: print a hint when the patch's Upstream issue/PR
# is closed. Quiet without gh, on any gh failure, or with no valid link
# (e.g. `Upstream: none filed`). gh api's issues endpoint covers PRs too.
upstream_hint() {
  local ref state
  ref="$(awk '/^(--- |diff )/{exit} /^Upstream: /{print $2; exit}' "$2")"
  [[ "$ref" =~ ^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+#[0-9]+$ ]] || return 0
  command -v gh >/dev/null 2>&1 || return 0
  state="$(gh api "repos/${ref%#*}/issues/${ref##*#}" -q .state 2>/dev/null)" || return 0
  case "$state" in
    closed|CLOSED|merged|MERGED)
      echo "note: skills/$1/workspace.patch — $ref is closed; upstream may have landed this; delete the patch (and re-run the sync) if so" ;;
  esac
}

# Line number of the closing '---' of the YAML frontmatter.
frontmatter_end() {
  awk '/^---$/{c++; if (c==2) {print NR; exit}}' "$1"
}

for path in "${PRISTINE[@]}"; do
  name="$(basename "$path")"
  src="$CLONE/skills/$path"
  dst="$ROOT/skills/$name"
  [ -d "$src" ] || { echo "error: $src missing upstream — update this script" >&2; exit 1; }
  patch_file="$dst/workspace.patch"
  rsync -a --delete --exclude workspace.patch "$src/" "$dst/"
  fm="$(frontmatter_end "$dst/SKILL.md")"
  [ -n "$fm" ] || { echo "error: no frontmatter in $dst/SKILL.md" >&2; exit 1; }
  tmp="$(mktemp)"
  {
    head -n "$fm" "$dst/SKILL.md"
    if [ -f "$patch_file" ]; then
      cat <<EOF

<!--
Vendored from github.com/mattpocock/skills — skills/$path/
at commit $SHA ($DATE). Upstream content (MIT — see
skills/vendored-skills.md) plus skills/$name/workspace.patch, which
scripts/sync-vendored-skills.sh re-applies at every refresh. Change the
patch, not this file.
-->
EOF
    else
      cat <<EOF

<!--
Vendored from github.com/mattpocock/skills — skills/$path/
at commit $SHA ($DATE). Upstream content (MIT — see
skills/vendored-skills.md); keep this directory unmodified so refreshes
stay a clean re-copy: scripts/sync-vendored-skills.sh.
-->
EOF
    fi
    tail -n "+$((fm + 1))" "$dst/SKILL.md"
  } > "$tmp"
  mv "$tmp" "$dst/SKILL.md"
  if [ -f "$patch_file" ]; then
    # Before applying: an upstream fix is the likely reason a patch stops applying.
    upstream_hint "$name" "$patch_file"
    # Dry-run first so a patch that fails leaves no .orig/.rej files behind.
    patch -p1 -d "$dst" -F0 -N -s --dry-run -i "$patch_file" >/dev/null 2>&1 \
      || { echo "error: skills/$name/workspace.patch no longer applies to upstream $SHA — rewrite it against the re-copied skills/$name/SKILL.md" >&2; exit 1; }
    patch -p1 -d "$dst" -F0 -N -s --no-backup-if-mismatch -i "$patch_file"
    echo "synced (patched):  $name @ $SHA (workspace.patch applied)"
  else
    echo "synced (pristine): $name @ $SHA"
  fi
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
