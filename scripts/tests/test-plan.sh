#!/usr/bin/env bash
# File: scripts/tests/test-plan.sh
# Purpose: Contract of scripts/plan.sh at its one seam, the command line:
#          given the fixture plan (scripts/tests/fixtures/plan-01-concept,
#          the worked example in work/plans/concept.md), `status` and `show`
#          print the documented text and --json with the documented exit
#          codes; malformed node files are refused naming the file; `new`
#          numbers the next plan and refuses while one is open; project and
#          plan resolution follow the settled order (docs/plans.md).
#          Self-contained: throwaway workspace in mktemp -d.
set -u
SRC_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TMP="$(mktemp -d)"; TMP="$(cd "$TMP" && pwd -P)"; trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/scripts" "$TMP/work/demo/plans" "$TMP/.context-budget/sessions" "$TMP/elsewhere"
cp "$SRC_ROOT/scripts/plan.sh" "$TMP/scripts/"
cp -R "$SRC_ROOT/scripts/tests/fixtures/plan-01-concept" "$TMP/work/demo/plans/01-concept"
PLAN="$TMP/scripts/plan.sh"
cd "$TMP/elsewhere"
unset TF_SESSION_PROJECT

PASS=0; FAIL=0
ok()  { PASS=$((PASS+1)); echo "  ok: $1"; }
bad() { FAIL=$((FAIL+1)); echo "  FAIL: $1" >&2; }
assert_eq()       { [ "$2" = "$3" ] && ok "$1" || bad "$1 (want [$3] got [$2])"; }
assert_contains() { case "$2" in *"$3"*) ok "$1" ;; *) bad "$1 (no [$3] in [$2])" ;; esac; }

echo "T1: usage — no verb or an unknown verb exits 2"
"$PLAN" >/dev/null 2>&1; assert_eq "T1a: no verb" "$?" "2"
"$PLAN" bogus --project demo >/dev/null 2>&1; assert_eq "T1b: unknown verb" "$?" "2"
"$PLAN" show --project demo >/dev/null 2>&1; assert_eq "T1c: show without id" "$?" "2"

echo "T2: status — one line, derived from the node files"
out="$("$PLAN" status --project demo)"; rc=$?
assert_eq "T2a: exit 0" "$rc" "0"
assert_eq "T2b: line" "$out" "plan 01-concept  open  wave 3 of 3  done 6/9  doing 1  todo 2  blocked 0  dropped 0  sessions 2"
out="$("$PLAN" status --project demo --json)"; rc=$?
assert_eq "T2c: json exit 0" "$rc" "0"
assert_eq "T2d: json fields" "$(printf '%s' "$out" | jq -c '[.plan,.status,.wave.current,.wave.total,.counts.done,.counts.total,.sessions_used]')" \
  '["01-concept","open",3,3,6,9,2]'

echo "T3: show — the node file in text, its frontmatter in --json"
out="$("$PLAN" show 01-seam-inventory --project demo)"; rc=$?
assert_eq "T3a: exit 0" "$rc" "0"
assert_contains "T3b: prints the file" "$out" "## Acceptance"
out="$("$PLAN" show 01-seam-inventory --project demo --json)"
assert_eq "T3c: parsed fields" "$(printf '%s' "$out" | jq -c '[.id,.status,.kind,.wave,.tier,.parallel,.loop,.sessions,.isolated]')" \
  '["01-seam-inventory","done","work",1,"standard",2,1,[1],false]'
assert_eq "T3d: check kept verbatim" "$(printf '%s' "$out" | jq -r '.check')" \
  "test -s seams.md && grep -q '^## What is genuinely missing' seams.md"
out="$("$PLAN" show 09-reconcile-verdict --project demo --json)"
assert_eq "T3e: list fields and defaults" "$(printf '%s' "$out" | jq -c '[.blocked_by,.sessions,.parallel,.check!=null,.isolated]')" \
  '[["07-spec","08-tickets"],[],1,true,false]'
out="$("$PLAN" show 08-tickets --project demo --json)"
assert_eq "T3f: absent optional fields default" "$(printf '%s' "$out" | jq -c '[.kind,.loop,.check,(.path|type)]')" '["work",1,null,"string"]'
"$PLAN" show no-such-node --project demo >/dev/null 2>&1; assert_eq "T3g: unknown id exits 1" "$?" "1"

echo "T4: malformed frontmatter or an unknown value is refused naming the file"
N="$TMP/work/demo/plans/01-concept/nodes"
cp "$N/08-tickets.md" "$TMP/08.bak"
sed 's/^status: todo$/status: pending/' "$TMP/08.bak" > "$N/08-tickets.md"
err="$("$PLAN" status --project demo 2>&1 >/dev/null)"; rc=$?
assert_eq "T4a: unknown status exits 1" "$rc" "1"
assert_contains "T4b: names the file" "$err" "08-tickets.md"
sed 's/^kind: work$/kind: task/' "$TMP/08.bak" > "$N/08-tickets.md"
"$PLAN" status --project demo >/dev/null 2>&1; assert_eq "T4c: unknown kind exits 1" "$?" "1"
sed 's/^tier: standard$/tier: gold/' "$TMP/08.bak" > "$N/08-tickets.md"
"$PLAN" status --project demo >/dev/null 2>&1; assert_eq "T4d: unknown tier exits 1" "$?" "1"
sed '1d' "$TMP/08.bak" > "$N/08-tickets.md"
err="$("$PLAN" show 08-tickets --project demo 2>&1 >/dev/null)"; rc=$?
assert_eq "T4e: missing frontmatter exits 1" "$rc" "1"
assert_contains "T4f: names the file" "$err" "08-tickets.md"
cp "$TMP/08.bak" "$N/08-tickets.md"
"$PLAN" status --project demo >/dev/null 2>&1; assert_eq "T4g: restored fixture passes again" "$?" "0"

echo "T5: new — refuses while a plan is open, then numbers the next one"
err="$("$PLAN" new second --project demo 2>&1 >/dev/null)"; rc=$?
assert_eq "T5a: exit 1 while 01-concept is open" "$rc" "1"
assert_contains "T5b: names the open plan" "$err" "01-concept"
sed -i '' 's/^status: open$/status: closed/' "$TMP/work/demo/plans/01-concept/plan.md"
out="$("$PLAN" new second --project demo)"; rc=$?
assert_eq "T5c: exit 0" "$rc" "0"
P2="$TMP/work/demo/plans/02-second"
[ -f "$P2/plan.md" ] && ok "T5d: plans/02-second/plan.md created" || bad "T5d: plan.md missing"
[ -d "$P2/nodes" ] && ok "T5e: nodes/ created" || bad "T5e: nodes/ missing"
assert_contains "T5f: prints the path" "$out" "plans/02-second"
assert_eq "T5g: frontmatter" "$(sed -n '1,5p' "$P2/plan.md" | tr '\n' '|')" "---|plan: 02-second|status: open|replan: local|default_tier: standard|"
for h in '## Goal' '## Not yet specified' '## Out of scope' '## Replans' '<!-- plan:begin board -->' '<!-- plan:end board -->'; do
  grep -qF "$h" "$P2/plan.md" && ok "T5h: skeleton has $h" || bad "T5h: skeleton lacks $h"
done
assert_eq "T5i: status of the empty plan" "$("$PLAN" status --project demo)" "plan 02-second  open  wave 0 of 0  done 0/0  doing 0  todo 0  blocked 0  dropped 0  sessions 0"
"$PLAN" new bad_slug --project demo >/dev/null 2>&1; assert_eq "T5j: a slug outside [a-z0-9-] exits 2" "$?" "2"

echo "T6: plan resolution — flag, chain.plan, single open, latest for reads, refuse"
assert_eq "T6a: --plan picks the closed plan" "$("$PLAN" status --project demo --plan 01-concept | cut -d' ' -f2,4)" "01-concept closed"
"$PLAN" status --project demo --plan 03-none >/dev/null 2>&1; assert_eq "T6b: unknown --plan exits 2" "$?" "2"
printf '{"schema":1,"chain":{"plan":"01-concept"}}\n' > "$TMP/work/demo/session-state.json"
assert_eq "T6c: chain.plan wins over the single open plan" "$("$PLAN" status --project demo | cut -d' ' -f2)" "01-concept"
rm "$TMP/work/demo/session-state.json"
sed -i '' 's/^status: closed$/status: open/' "$TMP/work/demo/plans/01-concept/plan.md"
assert_eq "T6d: two open — a read verb falls back to the latest" "$("$PLAN" status --project demo | cut -d' ' -f2)" "02-second"
rm -rf "$P2"
assert_eq "T6e: single open plan resolves" "$("$PLAN" status --project demo | cut -d' ' -f2)" "01-concept"
mkdir -p "$TMP/work/empty/plans"
"$PLAN" status --project empty >/dev/null 2>&1; assert_eq "T6f: no plan at all exits 2" "$?" "2"

echo "T7: project resolution — flag, registry binding, TF_SESSION_PROJECT, cwd, refuse"
"$PLAN" status >/dev/null 2>&1; assert_eq "T7a: nothing to resolve from exits 2" "$?" "2"
"$PLAN" status --project nosuch >/dev/null 2>&1; assert_eq "T7b: --project naming no work item exits 2" "$?" "2"
assert_eq "T7c: TF_SESSION_PROJECT" "$(TF_SESSION_PROJECT=demo "$PLAN" status | cut -d' ' -f2)" "01-concept"
assert_eq "T7d: cwd inside the item" "$(cd "$TMP/work/demo/plans" && "$PLAN" status | cut -d' ' -f2)" "01-concept"
start="$(ps -o lstart= -p $$ | sed 's/^ *//;s/ *$//')"
jq -n --argjson pid $$ --arg ps "$start" '{runtime:"test",session_id:"t",project:"demo",pid:$pid,pid_start:$ps}' \
  > "$TMP/.context-budget/sessions/test-t.json"
assert_eq "T7e: registry binding (this shell is an ancestor)" "$("$PLAN" status | cut -d' ' -f2)" "01-concept"
assert_eq "T7f: registry binding beats TF_SESSION_PROJECT" "$(TF_SESSION_PROJECT=empty "$PLAN" status 2>/dev/null | cut -d' ' -f2)" "01-concept"
jq '.pid_start = "Mon Jan  1 00:00:00 2001"' "$TMP/.context-budget/sessions/test-t.json" > "$TMP/r.json" && mv "$TMP/r.json" "$TMP/.context-budget/sessions/test-t.json"
"$PLAN" status >/dev/null 2>&1; assert_eq "T7g: a recycled pid (pid_start differs) does not bind" "$?" "2"

echo "passed=$PASS failed=$FAIL"
[ "$FAIL" -eq 0 ]
