#!/usr/bin/env bash
# File: scripts/migrate-glossary.sh
# Purpose: Move an older project's domain glossary out of CONTEXT.md (backlog
#          M49). Projects made from older versions of this template, or the
#          old init-project-ai-infra, keep it as a `## Language` section inside
#          the root CONTEXT.md; the template and its vendored skills now keep
#          it in a root GLOSSARY.md. This script, run against such a repo:
#            1. creates and switches to branch migrate/glossary;
#            2. moves the `## Language` body (up to the next `## ` heading)
#               into a new GLOSSARY.md, verbatim, under a title and intro;
#            3. replaces that body in CONTEXT.md with a pointer (the heading
#               stays), editing CONTEXT.md itself so the CLAUDE.md/AGENTS.md/
#               GEMINI.md symlinks keep resolving to it;
#            4. rewrites clear references in tracked .md files (outside work/
#               and repos/) — "`CONTEXT.md` → `## Language`", "the `## Language`
#               section of CONTEXT.md", "CONTEXT.md's glossary", "glossary in
#               CONTEXT.md" — to `GLOSSARY.md`;
#            5. commits on the branch and lists any other `## Language` or
#               CONTEXT.md-glossary mentions for a person to check by hand.
#          It leaves you on migrate/glossary to review, merge, or delete.
# Refuses (exit 1, no changes): not a git repo; no CONTEXT.md, or CONTEXT.md
#          is a symlink or not committed; no commits yet; tracked files with
#          uncommitted changes (untracked files are fine); a GLOSSARY.md that
#          already exists while CONTEXT.md still holds real terms (merge those
#          by hand); an existing migrate/glossary branch.
# No-op (exit 0, no branch): no `## Language` section, or it already points
#          at GLOSSARY.md, or it is empty.
# Usage:   migrate-glossary.sh [<target-repo>]   (default: current directory)
# See:     docs/runbooks/glossary-migration.md
set -u
export LC_ALL=C
BRANCH=migrate/glossary
die() { echo "migrate-glossary: $*" >&2; exit 1; }

case "${1:-}" in -h|--help) sed -n '2,32p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;; esac
[ $# -le 1 ] || die "usage: $0 [<target-repo>]"
dir="${1:-$PWD}"
[ -d "$dir" ] || die "not a directory: $dir"
top="$(git -C "$dir" rev-parse --show-toplevel 2>/dev/null)" || die "not a git repo: $dir"
cd "$top" || die "cannot enter $top"

[ -e CONTEXT.md ] || die "no CONTEXT.md at the repo root ($top)"
[ -L CONTEXT.md ] && die "CONTEXT.md is a symlink; run this where the real file lives"

# Split CONTEXT.md around the first `## Language` heading.
section_body() {
  awk 'f && /^## /{exit} f{print} /^## Language[ \t]*$/{f=1}' CONTEXT.md
}
if ! grep -q '^## Language[[:space:]]*$' CONTEXT.md; then
  if [ -e GLOSSARY.md ]; then echo "already migrated: no ## Language section in CONTEXT.md, GLOSSARY.md exists"
  else echo "nothing to do: no ## Language section in CONTEXT.md"; fi
  exit 0
fi
body="$(section_body)"
case "$body" in
  *GLOSSARY.md*) echo "already migrated: CONTEXT.md's ## Language already points at GLOSSARY.md"; exit 0 ;;
esac
if [ -z "$(printf '%s' "$body" | tr -d '[:space:]')" ]; then
  echo "nothing to do: CONTEXT.md's ## Language section is empty"; exit 0
fi
[ -e GLOSSARY.md ] && die "GLOSSARY.md already exists, but CONTEXT.md's ## Language section still holds terms. Merge them into GLOSSARY.md by hand, then replace the section body with a pointer to GLOSSARY.md. Nothing was changed."

# Preconditions for writing.
git rev-parse --verify -q HEAD >/dev/null || die "the repo has no commits yet; commit CONTEXT.md first, then re-run"
git ls-files --error-unmatch CONTEXT.md >/dev/null 2>&1 || die "CONTEXT.md is not committed; commit it first, then re-run"
[ -z "$(git status --porcelain --untracked-files=no)" ] || die "tracked files have uncommitted changes; commit or stash them first (untracked files are fine)"
git show-ref --verify --quiet "refs/heads/$BRANCH" && die "branch $BRANCH already exists; review or delete it (git branch -D $BRANCH), then re-run"
orig="$(git symbolic-ref --short -q HEAD || git rev-parse --short HEAD)"

# Project name: CONTEXT.md's H1 up to " — ", else the directory name.
name="$(awk '/^# /{sub(/^# /,""); print; exit}' CONTEXT.md)"
name="${name%% — *}"
[ -n "$name" ] || name="$(basename "$top")"

git checkout -q -b "$BRANCH" || die "could not create branch $BRANCH"

# Body without leading/trailing blank lines.
trimmed="$(printf '%s\n' "$body" | awk 'NF{f=1} f' | awk '{a[NR]=$0} NF{n=NR} END{for(i=1;i<=n;i++) print a[i]}')"
{
  echo "# $name — Glossary"
  echo
  echo "The project's domain language: resolved terms and the aliases to avoid. The"
  echo "\`domain-modeling\`, \`grill-with-docs\` and \`improve-codebase-architecture\`"
  echo "skills read and write this file."
  echo
  echo "## Language"
  echo
  printf '%s\n' "$trimmed"
} > GLOSSARY.md

tmp="$(mktemp)"; trap 'rm -f "$tmp"' EXIT
awk '
  f && /^## / { f=0; print ""; }
  f { next }
  { print }
  /^## Language[ \t]*$/ && !done {
    print ""
    print "The domain glossary — project terms and aliases to avoid — lives in"
    print "`GLOSSARY.md`. Read it before naming a domain concept; skills that resolve a"
    print "term update it."
    f=1; done=1
  }
' CONTEXT.md > "$tmp"
cat "$tmp" > CONTEXT.md   # write in place: keeps the file (and its symlinks) intact

# Rewrite clear references to the old location.
B='`?'
rewritten=""
while IFS= read -r f; do
  case "$f" in work/*|repos/*|GLOSSARY.md) continue ;; esac
  [ -f "$f" ] && [ ! -L "$f" ] || continue
  sed -E \
    -e "s/${B}CONTEXT\.md${B} (→|->) ${B}(## )?\"?Language\"?${B}/\`GLOSSARY.md\`/g" \
    -e "s/the ${B}(## )?\"?Language\"?${B} section (of|in) ${B}CONTEXT\.md${B}/\`GLOSSARY.md\`/g" \
    -e "s/${B}CONTEXT\.md${B}'s (domain )?glossary/\`GLOSSARY.md\`/g" \
    -e "s/(glossary|domain language) (in|of) ${B}CONTEXT\.md${B}/\1 \2 \`GLOSSARY.md\`/g" \
    "$f" > "$tmp"
  if ! cmp -s "$f" "$tmp"; then cat "$tmp" > "$f"; rewritten="$rewritten $f"; fi
done <<EOF
$(git ls-files -- '*.md')
EOF

# shellcheck disable=SC2086
git add GLOSSARY.md CONTEXT.md $rewritten
git commit -q -m "Move the domain glossary from CONTEXT.md to GLOSSARY.md" \
  -m "The vendored skills (domain-modeling, grill-with-docs, improve-codebase-architecture) read and write a root GLOSSARY.md. CONTEXT.md's ## Language section now points there. Made by scripts/migrate-glossary.sh." \
  || die "commit failed; the changes are on branch $BRANCH, uncommitted"

echo "Moved CONTEXT.md's ## Language into GLOSSARY.md and committed on branch $BRANCH."
if [ -n "$rewritten" ]; then
  echo "Rewrote references in:"; for f in $rewritten; do echo "  $f"; done
fi
left="$(git grep -n -E '## Language|CONTEXT\.md.{0,40}(glossary|Language)|(glossary|Language).{0,40}CONTEXT\.md' \
  -- '*.md' ':!GLOSSARY.md' ':!work/' ':!repos/' 2>/dev/null | grep -v '^CONTEXT\.md:[0-9]*:## Language[[:space:]]*$')"
if [ -n "$left" ]; then
  echo "Check these by hand (they may still point at the old location):"
  printf '%s\n' "$left" | sed 's/^/  /'
fi
cat <<EOF
Next steps:
  review:   git diff $orig..$BRANCH
  merge:    git checkout $orig && git merge $BRANCH && git branch -d $BRANCH
  back out: git checkout $orig && git branch -D $BRANCH
EOF
