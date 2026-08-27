#!/usr/bin/env bash
# File: scripts/tests/test-seq-sync.sh
# Purpose: Unit tests for `context-budget.sh seq-sync` (spec: numbering rules
#          1-2). Self-contained: throwaway git workspace in mktemp -d, with a
#          real worktree so the common-dir resolution is exercised for real.
set -u
SRC_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
MAIN="$TMP/main"
mkdir -p "$MAIN/scripts" "$MAIN/work/testproj"
cp "$SRC_ROOT/scripts/context-budget.sh" "$MAIN/scripts/"
chmod +x "$MAIN/scripts/context-budget.sh"
git -C "$MAIN" init -q
git -C "$MAIN" config user.email t@t; git -C "$MAIN" config user.name t
echo "# launcher" > "$MAIN/work/testproj/next-session.md"
git -C "$MAIN" add -A; git -C "$MAIN" commit -qm init
CB="$MAIN/scripts/context-budget.sh"
SEQF="$MAIN/work/testproj/.session-seq"

PASS=0; FAIL=0
ok()  { PASS=$((PASS+1)); echo "  ok: $1"; }
bad() { FAIL=$((FAIL+1)); echo "  FAIL: $1" >&2; }
assert_eq() { [ "$2" = "$3" ] && ok "$1" || bad "$1 (want [$3] got [$2])"; }
assert_contains() { case "$2" in *"$3"*) ok "$1" ;; *) bad "$1 (no [$3] in [$2])" ;; esac; }

echo "S1: absent counter — session N creates it"
rm -f "$SEQF"
out=$("$CB" seq-sync --project testproj --session 7 2>&1); rc=$?
assert_eq       "S1a: exit 0"        "$rc" "0"
assert_contains "S1b: action=created" "$out" "seq-sync: created"
assert_eq       "S1c: file holds 7"  "$(cat "$SEQF")" "7"

echo "S2: counter already equals N — no write, no mtime change"
printf '7\n' > "$SEQF"
before=$(ls -l "$SEQF")
out=$("$CB" seq-sync --project testproj --session 7 2>&1); rc=$?
assert_eq       "S2a: exit 0"          "$rc" "0"
assert_contains "S2b: action=noop"     "$out" "seq-sync: noop"
assert_eq       "S2c: unchanged"       "$(ls -l "$SEQF")" "$before"

echo "S3: counter too low — upward correction lands"
printf '3\n' > "$SEQF"
out=$("$CB" seq-sync --project testproj --session 9 2>&1); rc=$?
assert_eq       "S3a: exit 0"        "$rc" "0"
assert_contains "S3b: action=raised" "$out" "seq-sync: raised"
assert_eq       "S3c: file holds 9"  "$(cat "$SEQF")" "9"

echo "S4: counter too high — downward correction lands (the 2026-08-25 case)"
printf '9\n' > "$SEQF"
out=$("$CB" seq-sync --project testproj --session 4 2>&1); rc=$?
assert_eq       "S4a: exit 0"         "$rc" "0"
assert_contains "S4b: action=lowered" "$out" "seq-sync: lowered"
assert_eq       "S4c: file holds 4"   "$(cat "$SEQF")" "4"

echo "S5: called from a worktree — writes the MAIN checkout, never its own"
git -C "$MAIN" worktree add -q -b wt "$TMP/wt"
printf '5\n' > "$SEQF"
out=$(cd "$TMP/wt" && "$TMP/wt/scripts/context-budget.sh" \
        seq-sync --project testproj --session 8 2>&1); rc=$?
assert_eq "S5a: exit 0"                 "$rc" "0"
assert_eq "S5b: main checkout updated"  "$(cat "$SEQF")" "8"
assert_eq "S5c: no stray in worktree"   "$([ -f "$TMP/wt/work/testproj/.session-seq" ] && echo stray || echo clean)" "clean"

echo "S6: bad input is refused with exit 3"
out=$("$CB" seq-sync --project testproj --session 0 2>&1); rc=$?
assert_eq "S6a: session 0 refused" "$rc" "3"
out=$("$CB" seq-sync --project testproj --session abc 2>&1); rc=$?
assert_eq "S6b: non-numeric refused" "$rc" "3"
out=$("$CB" seq-sync --project testproj 2>&1); rc=$?
assert_eq "S6c: missing --session refused" "$rc" "3"
out=$("$CB" seq-sync --session 3 2>&1); rc=$?
assert_eq "S6d: missing --project refused" "$rc" "3"
out=$("$CB" seq-sync --project nosuch --session 3 2>&1); rc=$?
assert_eq "S6e: unknown project refused" "$rc" "3"

echo "S7: provenance sidecar records the writer's identity"
PROV="$MAIN/work/testproj/.session-seq.provenance.json"
rm -f "$PROV"; printf '5\n' > "$SEQF"
out=$(CLAUDE_CODE_SESSION_ID=sid-prov "$CB" seq-sync \
        --project testproj --session 6 --runtime claude 2>&1)
assert_eq "S7a: sidecar exists"  "$([ -f "$PROV" ] && echo yes || echo no)" "yes"
assert_eq "S7b: session recorded" "$(jq -r .session "$PROV")" "6"
assert_eq "S7c: action recorded"  "$(jq -r .action  "$PROV")" "raised"
assert_eq "S7d: cwd recorded"     "$(jq -r .cwd     "$PROV")" "$(pwd -P)"
assert_eq "S7e: valid json"       "$(jq -e . "$PROV" >/dev/null 2>&1 && echo ok)" "ok"

echo "S8: a noop still records provenance (proves the session ran)"
printf '6\n' > "$SEQF"; rm -f "$PROV"
out=$("$CB" seq-sync --project testproj --session 6 2>&1)
assert_eq "S8a: sidecar written on noop" "$(jq -r .action "$PROV")" "noop"

echo "S9: the counter itself stays a bare integer"
assert_eq "S9a: no JSON leaked into .session-seq" "$(cat "$SEQF")" "6"

echo "S10: opts-sync writes the main checkout from a worktree"
OPTF="$MAIN/work/testproj/.rollover-options"
rm -f "$OPTF"
out=$(cd "$TMP/wt" && "$TMP/wt/scripts/context-budget.sh" \
        opts-sync --project testproj --model opus 2>&1); rc=$?
assert_eq       "S10a: exit 0"            "$rc" "0"
assert_eq       "S10b: main copy written" "$([ -f "$OPTF" ] && echo yes || echo no)" "yes"
assert_contains "S10c: model recorded"    "$(cat "$OPTF")" "opus"
assert_eq       "S10d: no stray"          "$([ -f "$TMP/wt/work/testproj/.rollover-options" ] && echo stray || echo clean)" "clean"

echo "S11: the launcher can still source what opts-sync wrote"
out=$(sh -c ". '$OPTF' && echo \"\$ROLLOVER_OPT_MODEL\"" 2>&1)
assert_eq "S11a: sources cleanly" "$out" "opus"

echo "S12: approval is written and validated"
out=$("$CB" opts-sync --project testproj --approval edits 2>&1); rc=$?
assert_eq       "S12a: exit 0"           "$rc" "0"
assert_contains "S12b: approval written" "$(cat "$OPTF")" "ROLLOVER_OPT_APPROVAL=edits"
out=$("$CB" opts-sync --project testproj --approval bogus 2>&1); rc=$?
assert_eq "S12c: bad approval refused" "$rc" "3"
# The launcher maps four levels (launch-next-session.sh:277-311). A level the
# writer cannot set is a level that needs the hand-edit this subcommand removes.
out=$("$CB" opts-sync --project testproj --approval full 2>&1); rc=$?
assert_eq       "S12d: full accepted"    "$rc" "0"
assert_contains "S12e: full written"     "$(cat "$OPTF")" "ROLLOVER_OPT_APPROVAL=full"
out=$("$CB" opts-sync --project testproj --approval default 2>&1); rc=$?
assert_eq       "S12f: default accepted" "$rc" "0"

echo "S13: a rewrite clears a key that is no longer passed"
"$CB" opts-sync --project testproj --model opus --extra "--verbose" >/dev/null 2>&1
"$CB" opts-sync --project testproj --model opus >/dev/null 2>&1
case "$(cat "$OPTF")" in *ROLLOVER_OPT_EXTRA*) bad "S13a: stale extra survived" ;;
                         *) ok "S13a: omitted key cleared" ;; esac

echo; echo "passed=$PASS failed=$FAIL"
[ "$FAIL" -eq 0 ]
