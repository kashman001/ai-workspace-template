#!/usr/bin/env bash
# File: scripts/tests/test-migrate-glossary.sh
# Purpose: Regression tests for scripts/migrate-glossary.sh (backlog M49): an
#          older project's `## Language` glossary inside CONTEXT.md moves to a
#          root GLOSSARY.md on a migrate/glossary branch, CONTEXT.md keeps a
#          pointer, and clear references are rewritten. Self-contained:
#          throwaway git repos in mktemp -d.
set -u
SRC_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SCRIPT="$SRC_ROOT/scripts/migrate-glossary.sh"
TMP="$(mktemp -d)"; TMP="$(cd "$TMP" && pwd -P)"; trap 'rm -rf "$TMP"' EXIT
export GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@t GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@t
export GIT_CONFIG_NOSYSTEM=1 HOME="$TMP"

PASS=0; FAIL=0
ok()  { PASS=$((PASS+1)); echo "  ok: $1"; }
bad() { FAIL=$((FAIL+1)); echo "  FAIL: $1" >&2; }
assert_eq() { [ "$2" = "$3" ] && ok "$1" || bad "$1 (want [$3] got [$2])"; }
assert_contains() { case "$2" in *"$3"*) ok "$1" ;; *) bad "$1 (no [$3] in [$2])" ;; esac; }
assert_not_contains() { case "$2" in *"$3"*) bad "$1 (found [$3])" ;; *) ok "$1" ;; esac; }
branch_of() { git -C "$1" symbolic-ref --short -q HEAD; }
has_branch() { git -C "$1" show-ref --verify --quiet refs/heads/migrate/glossary; }

# make_repo <dir> [last]  — a committed project whose CONTEXT.md carries a real
# `## Language` glossary; with "last", Language is the final section.
make_repo() {
  d="$1"; mkdir -p "$d/docs" "$d/work/old"
  {
    echo "# Demo — Workspace Context"; echo
    echo "## Workspace Purpose"; echo; echo "A demo."; echo
    echo "## Language"; echo
    echo "- **Widget** — a thing we sell."
    echo "- **Gadget** — *not \"widget\"*."
    echo "  ### Sub-heading kept"
    if [ "${2:-}" != last ]; then
      echo; echo "## Repository Layout"; echo; echo "Code lives at the root."
    fi
  } > "$d/CONTEXT.md"
  ln -s CONTEXT.md "$d/CLAUDE.md"; ln -s CONTEXT.md "$d/AGENTS.md"
  {
    echo "Terms: see \`CONTEXT.md\` → \`## Language\`."
    echo "Also the \`## Language\` section of \`CONTEXT.md\` is canonical."
    echo "Update CONTEXT.md's glossary when a term settles."
    echo "Keep the glossary in \`CONTEXT.md\` tight."
    echo "Unrelated: CONTEXT.md is the front door."
  } > "$d/docs/guide.md"
  echo "Write a ## Language heading in each module doc." > "$d/docs/other.md"
  echo "Old note: \`CONTEXT.md\` → \`## Language\`." > "$d/work/old/notes.md"
  git -C "$d" init -q -b main
  git -C "$d" add -A && git -C "$d" commit -qm init
}

echo "G1: happy path — glossary moves to GLOSSARY.md on migrate/glossary"
R="$TMP/g1"; make_repo "$R"
orig_ctx="$(cat "$R/CONTEXT.md")"; orig_head="$(git -C "$R" rev-parse main)"
out=$("$SCRIPT" "$R" 2>&1); rc=$?
assert_eq       "G1a: exit 0" "$rc" "0"
assert_eq       "G1b: left on migrate/glossary" "$(branch_of "$R")" "migrate/glossary"
g="$(cat "$R/GLOSSARY.md" 2>/dev/null)"
assert_contains "G1c: GLOSSARY.md titled from CONTEXT.md H1" "$g" "# Demo — Glossary"
assert_contains "G1d: GLOSSARY.md has ## Language" "$g" "## Language"
assert_contains "G1e: term moved verbatim" "$g" "- **Widget** — a thing we sell."
assert_contains "G1f: nested heading moved too" "$g" "  ### Sub-heading kept"
assert_not_contains "G1g: next section not moved" "$g" "Repository Layout"
c="$(cat "$R/CONTEXT.md")"
assert_contains "G1h: CONTEXT.md keeps the heading" "$c" "## Language"
assert_contains "G1i: CONTEXT.md points at GLOSSARY.md" "$c" "lives in
\`GLOSSARY.md\`"
assert_not_contains "G1j: terms gone from CONTEXT.md" "$c" "Widget"
assert_contains "G1k: later section intact" "$c" "## Repository Layout

Code lives at the root."
assert_contains "G1l: earlier section intact" "$c" "## Workspace Purpose

A demo."
[ -L "$R/CLAUDE.md" ] && ok "G1m: CLAUDE.md is still a symlink" || bad "G1m: CLAUDE.md replaced"
assert_eq       "G1n: CLAUDE.md resolves to the edited CONTEXT.md" "$(cat "$R/CLAUDE.md")" "$c"
assert_eq       "G1o: main branch untouched" "$(git -C "$R" rev-parse main)" "$orig_head"
assert_eq       "G1p: main's CONTEXT.md unchanged" "$(git -C "$R" show main:CONTEXT.md)" "$orig_ctx"
assert_eq       "G1q: one commit on the branch" "$(git -C "$R" rev-list --count main..HEAD)" "1"
assert_eq       "G1r: tree clean after commit" "$(git -C "$R" status --porcelain)" ""
assert_contains "G1s: commit message names the move" "$(git -C "$R" log -1 --format=%s)" "GLOSSARY.md"
assert_contains "G1t: prints how to back out" "$out" "git checkout main && git branch -D migrate/glossary"

echo "G2: references rewritten conservatively"
gd="$(cat "$R/docs/guide.md")"
assert_contains "G2a: arrow form rewritten" "$gd" "Terms: see \`GLOSSARY.md\`."
assert_contains "G2b: section-of form rewritten" "$gd" "Also \`GLOSSARY.md\` is canonical."
assert_contains "G2c: possessive form rewritten" "$gd" "Update \`GLOSSARY.md\` when a term settles."
assert_contains "G2d: glossary-in form rewritten" "$gd" "Keep the glossary in \`GLOSSARY.md\` tight."
assert_contains "G2e: unrelated CONTEXT.md mention kept" "$gd" "Unrelated: CONTEXT.md is the front door."
assert_eq       "G2f: unclear mention not rewritten" "$(cat "$R/docs/other.md")" "Write a ## Language heading in each module doc."
assert_contains "G2g: unclear mention listed for review" "$out" "docs/other.md:1"
assert_eq       "G2h: work/ history untouched" "$(cat "$R/work/old/notes.md")" "Old note: \`CONTEXT.md\` → \`## Language\`."
assert_contains "G2i: rewritten file reported" "$out" "docs/guide.md"

echo "G3: second run is a no-op"
head1="$(git -C "$R" rev-parse HEAD)"
out=$("$SCRIPT" "$R" 2>&1); rc=$?
assert_eq       "G3a: exit 0" "$rc" "0"
assert_contains "G3b: says already migrated" "$out" "already migrated"
assert_eq       "G3c: no new commit" "$(git -C "$R" rev-parse HEAD)" "$head1"

echo "G4: dirty tracked tree refused"
R="$TMP/g4"; make_repo "$R"; echo more >> "$R/docs/guide.md"
out=$("$SCRIPT" "$R" 2>&1); rc=$?
[ "$rc" -ne 0 ] && ok "G4a: non-zero exit" || bad "G4a: exit 0 on dirty tree"
assert_contains "G4b: says uncommitted" "$out" "uncommitted"
has_branch "$R" && bad "G4c: branch created" || ok "G4c: no branch created"
[ ! -e "$R/GLOSSARY.md" ] && ok "G4d: no GLOSSARY.md" || bad "G4d: GLOSSARY.md written"

echo "G5: untracked files do not block"
R="$TMP/g5"; make_repo "$R"; echo x > "$R/.env.example"; mkdir "$R/.claude"; echo y > "$R/.claude/s.json"
out=$("$SCRIPT" "$R" 2>&1); rc=$?
assert_eq       "G5a: exit 0" "$rc" "0"
assert_eq       "G5b: on migrate/glossary" "$(branch_of "$R")" "migrate/glossary"
assert_eq       "G5c: untracked files left untracked" "$(git -C "$R" status --porcelain)" "?? .claude/
?? .env.example"

echo "G6: no ## Language section — nothing to do"
R="$TMP/g6"; mkdir -p "$R"; printf '# P\n\n## Other\n\nx\n' > "$R/CONTEXT.md"
git -C "$R" init -q -b main; git -C "$R" add -A; git -C "$R" commit -qm init
out=$("$SCRIPT" "$R" 2>&1); rc=$?
assert_eq       "G6a: exit 0" "$rc" "0"
assert_contains "G6b: says nothing to do" "$out" "nothing to do"
has_branch "$R" && bad "G6c: branch created" || ok "G6c: no branch created"
[ ! -e "$R/GLOSSARY.md" ] && ok "G6d: no GLOSSARY.md" || bad "G6d: GLOSSARY.md written"

echo "G7: GLOSSARY.md plus a real ## Language body — refused, no changes"
R="$TMP/g7"; make_repo "$R"; echo "# Existing" > "$R/GLOSSARY.md"
git -C "$R" add GLOSSARY.md; git -C "$R" commit -qm glossary
before="$(cat "$R/CONTEXT.md")"
out=$("$SCRIPT" "$R" 2>&1); rc=$?
[ "$rc" -ne 0 ] && ok "G7a: non-zero exit" || bad "G7a: exit 0"
assert_contains "G7b: explains the conflict" "$out" "GLOSSARY.md already exists"
has_branch "$R" && bad "G7c: branch created" || ok "G7c: no branch created"
assert_eq       "G7d: CONTEXT.md unchanged" "$(cat "$R/CONTEXT.md")" "$before"
assert_eq       "G7e: GLOSSARY.md unchanged" "$(cat "$R/GLOSSARY.md")" "# Existing"

echo "G8: existing migrate/glossary branch — refused"
R="$TMP/g8"; make_repo "$R"; git -C "$R" branch migrate/glossary
out=$("$SCRIPT" "$R" 2>&1); rc=$?
[ "$rc" -ne 0 ] && ok "G8a: non-zero exit" || bad "G8a: exit 0"
assert_contains "G8b: names the branch" "$out" "migrate/glossary already exists"
assert_eq       "G8c: still on main" "$(branch_of "$R")" "main"
[ ! -e "$R/GLOSSARY.md" ] && ok "G8d: no GLOSSARY.md" || bad "G8d: GLOSSARY.md written"

echo "G9: ## Language as the last section"
R="$TMP/g9"; make_repo "$R" last
out=$("$SCRIPT" "$R" 2>&1); rc=$?
assert_eq       "G9a: exit 0" "$rc" "0"
assert_contains "G9b: last term moved" "$(cat "$R/GLOSSARY.md")" "  ### Sub-heading kept"
assert_not_contains "G9c: terms gone from CONTEXT.md" "$(cat "$R/CONTEXT.md")" "Gadget"
assert_contains "G9d: pointer at end of CONTEXT.md" "$(tail -3 "$R/CONTEXT.md")" "GLOSSARY.md"

echo "G10: refusals before any change"
R="$TMP/g10a"; mkdir -p "$R"; git -C "$R" init -q -b main
printf '# P\n\n## Language\n\n- **X** — y\n' > "$R/CONTEXT.md"
out=$("$SCRIPT" "$R" 2>&1); rc=$?
[ "$rc" -ne 0 ] && ok "G10a: no commits yet → non-zero" || bad "G10a: exit 0 with no commits"
assert_contains "G10b: says commit first" "$out" "commit"
[ ! -e "$R/GLOSSARY.md" ] && ok "G10c: no GLOSSARY.md" || bad "G10c: GLOSSARY.md written"
R="$TMP/g10d"; mkdir -p "$R"
out=$("$SCRIPT" "$R" 2>&1); rc=$?
[ "$rc" -ne 0 ] && ok "G10d: not a git repo → non-zero" || bad "G10d: exit 0 outside git"
R="$TMP/g10e"; mkdir -p "$R"; git -C "$R" init -q -b main
out=$("$SCRIPT" "$R" 2>&1); rc=$?
[ "$rc" -ne 0 ] && ok "G10e: no CONTEXT.md → non-zero" || bad "G10e: exit 0 without CONTEXT.md"
assert_contains "G10f: names CONTEXT.md" "$out" "CONTEXT.md"

echo "G11: project name falls back to the directory name"
R="$TMP/my-proj"; mkdir -p "$R"; printf 'No heading.\n\n## Language\n\n- **X** — y\n' > "$R/CONTEXT.md"
git -C "$R" init -q -b main; git -C "$R" add -A; git -C "$R" commit -qm init
out=$("$SCRIPT" "$R" 2>&1); rc=$?
assert_eq       "G11a: exit 0" "$rc" "0"
assert_eq       "G11b: title from dir name" "$(head -1 "$R/GLOSSARY.md")" "# my-proj — Glossary"

echo
echo "migrate-glossary: $PASS passed, $FAIL failed"
[ "$FAIL" = 0 ]
