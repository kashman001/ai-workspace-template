#!/usr/bin/env bash
# File: scripts/tests/test-link-local-work.sh
# Purpose: Regression tests for scripts/link-local-work.sh (backlog L45):
#          local-only (ignored) work/<item>/ directories are symlinked from the
#          main checkout into a git worktree so a worktree-isolated session
#          reads and writes the real directory. Self-contained: throwaway git
#          repo + worktree in mktemp -d.
set -u
SRC_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TMP="$(mktemp -d)"; TMP="$(cd "$TMP" && pwd -P)"; trap 'rm -rf "$TMP"' EXIT
MAIN="$TMP/main"; WT="$TMP/wt"

PASS=0; FAIL=0
ok()  { PASS=$((PASS+1)); echo "  ok: $1"; }
bad() { FAIL=$((FAIL+1)); echo "  FAIL: $1" >&2; }
assert_eq() { [ "$2" = "$3" ] && ok "$1" || bad "$1 (want [$3] got [$2])"; }
assert_contains() { case "$2" in *"$3"*) ok "$1" ;; *) bad "$1 (no [$3] in [$2])" ;; esac; }
assert_link() { [ -L "$2" ] && [ "$(readlink "$2")" = "$3" ] && ok "$1" || bad "$1 ($2 is not a link to $3)"; }

# Main checkout: one tracked item, one item ignored via .gitignore, one via
# info/exclude, one untracked-but-not-ignored, plus an ignored file inside the
# tracked item (the .active-session shape) and an ignored subdir of it.
mkdir -p "$MAIN/scripts/hooks" "$MAIN/work/tracked/.agent-locks" \
         "$MAIN/work/ignored-gi" "$MAIN/work/ignored-ex"
cp "$SRC_ROOT/scripts/link-local-work.sh" "$MAIN/scripts/"
cp "$SRC_ROOT/scripts/hooks/context-budget-hook-lib.sh" "$MAIN/scripts/hooks/"
# Trailing-slash patterns, as the template's .gitignore and a typical
# info/exclude line use — they match directories only, not the symlink.
printf 'work/ignored-gi/\nwork/*/.active-session\nwork/*/.agent-locks/\n' > "$MAIN/.gitignore"
echo readme > "$MAIN/work/README.md"; echo t > "$MAIN/work/tracked/README.md"
echo gi > "$MAIN/work/ignored-gi/NOTES.md"; echo ex > "$MAIN/work/ignored-ex/NOTES.md"
echo lock > "$MAIN/work/tracked/.active-session"; echo l > "$MAIN/work/tracked/.agent-locks/x"
git -C "$MAIN" init -q -b main
echo 'work/ignored-ex/' >> "$MAIN/.git/info/exclude"
git -C "$MAIN" -c user.name=t -c user.email=t@t add -A
git -C "$MAIN" -c user.name=t -c user.email=t@t commit -qm init
mkdir -p "$MAIN/work/untracked-new"; echo new > "$MAIN/work/untracked-new/README.md"
git -C "$MAIN" worktree add -q "$WT" -b wt-branch >/dev/null 2>&1 || { echo "cannot create worktree" >&2; exit 1; }
SCRIPT="$MAIN/scripts/link-local-work.sh"

echo "L1: worktree lacks the ignored items; the script links exactly those"
[ ! -e "$WT/work/ignored-gi" ] && ok "L1a: precondition — ignored item absent from worktree" || bad "L1a: precondition"
out=$("$SCRIPT" "$WT" 2>&1); rc=$?
assert_eq       "L1b: exit 0"                          "$rc" "0"
assert_link     "L1c: .gitignore item linked"          "$WT/work/ignored-gi" "$MAIN/work/ignored-gi"
assert_link     "L1d: info/exclude item linked"        "$WT/work/ignored-ex" "$MAIN/work/ignored-ex"
[ ! -e "$WT/work/untracked-new" ] && ok "L1e: untracked-but-not-ignored item NOT linked" || bad "L1e: untracked item linked (would be committable)"
[ -d "$WT/work/tracked" ] && [ ! -L "$WT/work/tracked" ] && ok "L1f: tracked item is still a real dir" || bad "L1f: tracked item touched"
[ ! -e "$WT/work/tracked/.active-session" ] && ok "L1g: ignored file inside a tracked item not linked" || bad "L1g: ignored file linked"
[ ! -e "$WT/work/tracked/.agent-locks" ] && ok "L1h: ignored subdir of a tracked item not linked" || bad "L1h: ignored subdir linked"
assert_contains "L1i: reports the .gitignore link"     "$out" "linked work/ignored-gi"
assert_contains "L1j: reports the info/exclude link"   "$out" "linked work/ignored-ex"
assert_eq       "L1k: worktree git status stays clean (symlink registered in info/exclude)" "$(git -C "$WT" status --porcelain)" ""
assert_eq       "L1l: exact-path exclude line added once per item" "$(grep -c -x 'work/ignored-gi' "$MAIN/.git/info/exclude")" "1"
assert_eq       "L1m: main checkout status unchanged" "$(git -C "$MAIN" status --porcelain)" "?? work/untracked-new/"

echo "L2: a write through the link lands in the main checkout"
echo "from worktree" > "$WT/work/ignored-gi/session.md"
assert_eq "L2a: file visible in main" "$(cat "$MAIN/work/ignored-gi/session.md" 2>/dev/null)" "from worktree"
git -C "$WT" worktree remove --force "$WT" 2>/dev/null || rm -rf "$WT"
[ -f "$MAIN/work/ignored-gi/session.md" ] && ok "L2b: survives worktree removal" || bad "L2b: lost with the worktree"
git -C "$MAIN" worktree prune
git -C "$MAIN" worktree add -q "$WT" wt-branch >/dev/null 2>&1

echo "L3: idempotent — second run is silent and leaves links intact"
"$SCRIPT" "$WT" >/dev/null 2>&1
out=$("$SCRIPT" "$WT" 2>&1); rc=$?
assert_eq   "L3a: exit 0"          "$rc" "0"
assert_eq   "L3b: no output"       "$out" ""
assert_link "L3c: link intact"     "$WT/work/ignored-gi" "$MAIN/work/ignored-gi"
assert_eq   "L3d: exclude line not duplicated" "$(grep -c -x 'work/ignored-gi' "$MAIN/.git/info/exclude")" "1"

echo "L4: a pre-existing real directory in the worktree (manual copy) is left alone"
mkdir -p "$MAIN/work/ignored-pre"; echo p > "$MAIN/work/ignored-pre/NOTES.md"
echo 'work/ignored-pre/' >> "$MAIN/.git/info/exclude"
mkdir -p "$WT/work/ignored-pre"; echo mine > "$WT/work/ignored-pre/NOTES.md"
"$SCRIPT" "$WT" >/dev/null 2>&1
[ -d "$WT/work/ignored-pre" ] && [ ! -L "$WT/work/ignored-pre" ] && ok "L4a: real dir kept" || bad "L4a: real dir replaced"
assert_eq "L4b: its content untouched" "$(cat "$WT/work/ignored-pre/NOTES.md")" "mine"

echo "L5: no-ops — main checkout, non-git dir, missing dir, default arg"
out=$("$SCRIPT" "$MAIN" 2>&1); rc=$?
assert_eq "L5a: main checkout exits 0"  "$rc" "0"
assert_eq "L5b: main checkout is silent" "$out" ""
[ ! -L "$MAIN/work/ignored-gi" ] && ok "L5c: main checkout dirs untouched" || bad "L5c: main checkout dir became a link"
mkdir -p "$TMP/plain"
out=$("$SCRIPT" "$TMP/plain" 2>&1); rc=$?
assert_eq "L5d: non-git dir exits 0"    "$rc" "0"
out=$("$SCRIPT" "$TMP/nope" 2>&1); rc=$?
assert_eq "L5e: missing dir is a usage error (1)" "$rc" "1"
rm -f "$WT/work/ignored-gi"
out=$(cd "$WT/work" && "$SCRIPT" 2>&1)
assert_link "L5f: default arg = \$PWD, any dir inside the worktree" "$WT/work/ignored-gi" "$MAIN/work/ignored-gi"

echo "L6: the shared hook lib links on a per-tool firing from a worktree (all runtimes)"
cat > "$MAIN/scripts/context-budget.sh" <<'STUB'
#!/usr/bin/env bash
echo "runtime=stub method=exact tokens=1 threshold=150000 warn=120000 pct=0 status=OK artifact=/dev/null"
STUB
chmod +x "$MAIN/scripts/context-budget.sh"
rm -f "$WT/work/ignored-gi" "$WT/work/ignored-ex"
( cd "$WT" && . "$WT/scripts/hooks/context-budget-hook-lib.sh" && budget_hook_check claude sid-1 "" ) >/dev/null 2>&1
assert_link "L6a: lib call from worktree cwd links the item" "$WT/work/ignored-gi" "$MAIN/work/ignored-gi"
rm -f "$WT/work/ignored-gi"
( cd "$WT" && . "$WT/scripts/hooks/context-budget-hook-lib.sh" && budget_hook_check claude sid-1 "" ) >/dev/null 2>&1
assert_link "L6b: second firing inside the throttle window still links (unthrottled)" "$WT/work/ignored-gi" "$MAIN/work/ignored-gi"
( cd "$MAIN" && . "$MAIN/scripts/hooks/context-budget-hook-lib.sh" && budget_hook_check claude sid-2 "" ) >/dev/null 2>&1
[ ! -L "$MAIN/work/ignored-gi" ] && ok "L6c: lib call from the main checkout changes nothing" || bad "L6c: main checkout dir became a link"
rm -rf "$MAIN/.context-budget"

echo
echo "link-local-work: $PASS passed, $FAIL failed"
[ "$FAIL" = 0 ]
