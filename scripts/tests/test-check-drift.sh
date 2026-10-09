#!/usr/bin/env bash
# File: scripts/tests/test-check-drift.sh
# Purpose: check-drift.sh contract — over a fixture workspace (DRIFT_ROOT) it
#          reports exactly: dead backticked docs/skills/scripts paths in tracked
#          .md files (allow-listed and placeholder paths skipped, ADR hits only
#          warned), gotchas past review age, an oversize CONTEXT.md, and docs/
#          entries missing from docs/README.md, and (as a warning, DRIFT_TODAY
#          fixing the date) vendored skills pinned over 60 days ago. One line
#          per finding, exit 1 if any failure; warnings alone exit 0.
set -u
SRC_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
CD="$SRC_ROOT/scripts/check-drift.sh"

PASS=0; FAIL=0
ok()  { PASS=$((PASS+1)); echo "  ok: $1"; }
bad() { FAIL=$((FAIL+1)); echo "  FAIL: $1" >&2; }
assert_eq()       { [ "$2" = "$3" ] && ok "$1" || bad "$1 (want [$3] got [$2])"; }
assert_contains() { case "$2" in *"$3"*) ok "$1" ;; *) bad "$1 (no [$3] in [$2])" ;; esac; }
assert_absent()   { case "$2" in *"$3"*) bad "$1 (found [$3])" ;; *) ok "$1" ;; esac; }

# clean <dir>: a tracked workspace with no drift.
clean() {
  mkdir -p "$1/docs/adr" "$1/docs/runbooks" "$1/scripts" "$1/skills/foo" "$1/work/x" "$1/docs/archive"
  printf '# ctx\nSee `docs/zoom-model.md` and `scripts/run.sh --fast`.\n' > "$1/CONTEXT.md"
  printf '# zoom\n' > "$1/docs/zoom-model.md"
  : > "$1/docs/.nojekyll"
  printf '# idx\n[z](zoom-model.md) [ok](operational-knowledge.md) [adr](adr/README.md) [rb](runbooks/)\n[ar](archive/)\n' > "$1/docs/README.md"
  printf '# adr\n' > "$1/docs/adr/README.md"
  printf '# rb\n' > "$1/docs/runbooks/x.md"
  printf '# old\n`docs/gone.md`\n' > "$1/docs/archive/old.md"
  printf '# ok\n\n## Fresh gotcha\n\n**Last confirmed:** %s\n' "$(date +%F)" > "$1/docs/operational-knowledge.md"
  printf '#!/usr/bin/env bash\n' > "$1/scripts/run.sh"
  printf '# foo\nUse `skills/foo/SKILL.md`, `docs/<name>.md`, `work/NN-x.md`, `skills/*/SKILL.md`.\nVendored from `skills/engineering/tdd/`.\n' > "$1/skills/foo/SKILL.md"
  printf '`docs/nowhere.md`\n' > "$1/work/x/notes.md"
  git -C "$1" init -q && git -C "$1" add -A
}

echo "D1: clean workspace — no findings, exit 0"
clean "$TMP/a"
out="$(DRIFT_ROOT="$TMP/a" bash "$CD" 2>&1)"; rc=$?
assert_eq "D1 exit" "$rc" "0"
assert_absent "D1 work/ and docs/archive/ not swept" "$out" "nowhere.md"
assert_absent "D1 archive not swept" "$out" "gone.md"
assert_absent "D1 allow-listed upstream path" "$out" "skills/engineering"
assert_absent "D1 placeholder/glob skipped" "$out" "<name>"
assert_absent "D1 dotfiles in docs/ need no index entry" "$out" ".nojekyll"

echo "D2: one of each finding — exactly those, exit 1"
clean "$TMP/b"
printf 'Run `scripts/missing.sh` now.\n' >> "$TMP/b/skills/foo/SKILL.md"
printf 'Hook was `scripts/hooks/old-hook.sh`.\n' > "$TMP/b/docs/adr/0001-x.md"
printf '\n## Stale gotcha\n\n**Last confirmed:** 2000-01-01\n' >> "$TMP/b/docs/operational-knowledge.md"
head -c 17000 /dev/zero | tr '\0' 'x' >> "$TMP/b/CONTEXT.md"
printf '# new\n' > "$TMP/b/docs/unindexed.md"
printf '[adr](adr/0001-x.md)\n' >> "$TMP/b/docs/README.md"
git -C "$TMP/b" add -A
out="$(DRIFT_ROOT="$TMP/b" bash "$CD" 2>&1)"; rc=$?
assert_eq "D2 exit" "$rc" "1"
assert_contains "D2 dead path, with its file" "$out" "skills/foo/SKILL.md: scripts/missing.sh"
assert_contains "D2 ADR dead path is a warning" "$out" "WARN"
assert_contains "D2 ADR path named" "$out" "scripts/hooks/old-hook.sh"
assert_contains "D2 stale gotcha" "$out" "2000-01-01 ## Stale gotcha"
assert_absent "D2 fresh gotcha not reported" "$out" "Fresh gotcha"
assert_contains "D2 CONTEXT.md over budget" "$out" "CONTEXT.md is"
assert_contains "D2 over budget names the repair order" "$out" "move content to its proper home first, then condense"
assert_contains "D2 unindexed doc" "$out" "docs/unindexed.md"
assert_absent "D2 indexed folder not reported" "$out" "docs/runbooks"
assert_eq "D2 one line per finding (4 failures + 1 warning)" \
  "$(printf '%s\n' "$out" | grep -c -E '^(DRIFT|WARN) ')" "5"

echo "D3: ADR warnings alone — exit 0"
clean "$TMP/c"
printf 'Hook was `scripts/hooks/old-hook.sh`.\n' > "$TMP/c/docs/adr/0001-x.md"
printf '[adr](adr/0001-x.md)\n' >> "$TMP/c/docs/README.md"
git -C "$TMP/c" add -A
out="$(DRIFT_ROOT="$TMP/c" bash "$CD" 2>&1)"; rc=$?
assert_eq "D3 exit" "$rc" "0"
assert_contains "D3 warning shown" "$out" "WARN"

echo "D4: untracked .md files are not swept"
clean "$TMP/d"
printf '`scripts/untracked-ref.sh`\n' > "$TMP/d/skills/foo/draft.md"
out="$(DRIFT_ROOT="$TMP/d" bash "$CD" 2>&1)"; rc=$?
assert_absent "D4 untracked file ignored" "$out" "untracked-ref"

echo "D5: vendored skills pinned more than 60 days ago — warning, exit 0"
clean "$TMP/e"
mkdir -p "$TMP/e/skills/tdd" "$TMP/e/skills/grill-me"
prov() { printf -- '---\nname: x\n---\n\n<!--\nVendored from github.com/mattpocock/skills — skills/engineering/x/\nat commit abc1234 (%s). Upstream content.\n-->\n' "$1"; }
prov 2026-01-01 > "$TMP/e/skills/tdd/SKILL.md"
prov 2026-02-20 > "$TMP/e/skills/grill-me/SKILL.md"
git -C "$TMP/e" add -A
out="$(DRIFT_ROOT="$TMP/e" DRIFT_TODAY=2026-03-15 bash "$CD" 2>&1)"; rc=$?
assert_eq "D5 exit" "$rc" "0"
assert_contains "D5 warning" "$out" "WARN vendored"
assert_contains "D5 names the oldest pin" "$out" "2026-01-01"
assert_contains "D5 says how to refresh" "$out" "scripts/sync-vendored-skills.sh"
assert_eq "D5 one line" "$(printf '%s\n' "$out" | grep -c 'scripts/sync-vendored-skills.sh')" "1"

echo "D6: pinned within 60 days — no warning"
out="$(DRIFT_ROOT="$TMP/e" DRIFT_TODAY=2026-03-01 bash "$CD" 2>&1)"; rc=$?
assert_eq "D6 exit" "$rc" "0"
assert_absent "D6 no warning" "$out" "vendored"

echo
echo "check-drift: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
