#!/usr/bin/env bash
# File: scripts/tests/test-plan.sh
# Purpose: Contract of scripts/plan.sh at its one seam, the command line:
#          given the fixture plan (scripts/tests/fixtures/plan-01-concept,
#          the worked example in work/plans/concept.md), `status` and `show`
#          print the documented text and --json with the documented exit
#          codes; malformed node files are refused naming the file; `new`
#          numbers the next plan and refuses while one is open; project and
#          plan resolution follow the settled order (docs/plans.md);
#          `frontier`, `remaining` and `graph` derive from the same node
#          files (empty-frontier reasons, wave order, mixed done/dropped
#          blockers, a blocker naming no node); `check` lists every rule
#          violation at once (one fixture variant per rule) and is silent
#          on the clean fixture.
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

# Derived read verbs (ticket 02). Each case edits a copy of the fixture, then reset.
NODES="$TMP/work/demo/plans/01-concept/nodes"; mkdir -p "$TMP/orig"; cp "$NODES"/*.md "$TMP/orig/"
reset() { rm -f "$NODES"/*.md; cp "$TMP/orig"/*.md "$NODES/"; }
setf()  { sed -i '' "s/^$2: .*$/$2: $3/" "$NODES/$1.md"; }   # <id> <key> <value>
squeeze() { tr -s ' ' | sed 's/^ //;s/ $//'; }

echo "T8: frontier — todo nodes whose blockers are done or dropped, in the lowest unfinished wave"
err="$("$PLAN" frontier --project demo 2>&1 >/dev/null)"; rc=$?
assert_eq "T8a: fixture (07-spec doing, 08/09 wait on it) exits 1" "$rc" "1"
assert_contains "T8b: says why, naming the blocker" "$err" "07-spec"
out="$("$PLAN" frontier --project demo --json 2>/dev/null)"; rc=$?
assert_eq "T8c: --json on an empty frontier prints [] and still exits 1" "$rc:$out" "1:[]"
setf 07-spec status done
out="$("$PLAN" frontier --project demo)"; rc=$?
assert_eq "T8d: exit 0 once 07-spec is done" "$rc" "0"
assert_eq "T8e: id kind tier" "$(printf '%s' "$out" | squeeze)" "08-tickets work standard"
setf 06-reconcile-write status todo
out="$("$PLAN" frontier --project demo)"
assert_eq "T8f: a todo node in a lower wave is the whole frontier (the concept's sample line)" "$out" "06-reconcile-write     reconcile  frontier"
reset; setf 07-spec status dropped; setf 08-tickets status done
out="$("$PLAN" frontier --project demo)"
assert_eq "T8g: mixed dropped/done blockers satisfy" "$(printf '%s' "$out" | squeeze)" "09-reconcile-verdict reconcile frontier"
out="$("$PLAN" frontier --project demo --json)"
assert_eq "T8h: --json is the full node objects" "$(printf '%s' "$out" | jq -c '[.[] | [.id, .wave, .blocked_by, (.check != null)]]')" \
  '[["09-reconcile-verdict",3,["07-spec","08-tickets"],true]]'
setf 09-reconcile-verdict status done
out="$("$PLAN" frontier --project demo)"; rc=$?
assert_eq "T8i: nothing unfinished — empty, exit 0" "$rc:$out" "0:"
reset
printf -- '---\nid: 10-later\nstatus: todo\nwave: 4\n---\n## Goal\n' > "$NODES/10-later.md"
err="$("$PLAN" frontier --project demo 2>&1 >/dev/null)"; rc=$?
assert_eq "T8j: an unblocked node in a later wave is not the frontier" "$rc" "1"
assert_contains "T8k: the reason names it as later" "$err" "later wave"
assert_contains "T8l: ... and names it" "$err" "10-later"
setf 07-spec status done
assert_eq "T8m: with wave 3 ready, wave 4 stays off the frontier" "$("$PLAN" frontier --project demo | squeeze)" "08-tickets work standard"
reset; setf 08-tickets blocked_by '[07-spce]'
err="$("$PLAN" frontier --project demo 2>&1 >/dev/null)"; rc=$?
assert_eq "T8n: a blocker naming no node is refused" "$rc" "1"
assert_contains "T8o: names the file and the id" "$err" "08-tickets.md"
assert_contains "T8p: ..." "$err" "07-spce"
reset

echo "T9: remaining — everything not done or dropped, by wave then id"
out="$("$PLAN" remaining --project demo)"; rc=$?
assert_eq "T9a: exit 0" "$rc" "0"
assert_eq "T9b: id status wave" "$(printf '%s' "$out" | squeeze | tr '\n' '|')" "07-spec doing wave 3|08-tickets todo wave 3|09-reconcile-verdict todo wave 3"
assert_eq "T9c: --json ids" "$("$PLAN" remaining --project demo --json | jq -c '[.[].id]')" '["07-spec","08-tickets","09-reconcile-verdict"]'
setf 09-reconcile-verdict wave 2
assert_eq "T9d: wave before id" "$("$PLAN" remaining --project demo --json | jq -c '[.[].id]')" '["09-reconcile-verdict","07-spec","08-tickets"]'
reset; setf 07-spec status done; setf 08-tickets status dropped; setf 09-reconcile-verdict status done
out="$("$PLAN" remaining --project demo)"; rc=$?
assert_eq "T9e: nothing left — empty, exit 0" "$rc:$out" "0:"
assert_eq "T9f: --json empty" "$("$PLAN" remaining --project demo --json | jq -c .)" "[]"
reset

echo "T10: graph — the whole plan as text, nodes and edges in --json"
out="$("$PLAN" graph --project demo)"; rc=$?
assert_eq "T10a: exit 0" "$rc" "0"
assert_eq "T10b: one heading per wave" "$(printf '%s' "$out" | grep -c '^wave ')" "3"
assert_contains "T10c: a node line with its blockers" "$(printf '%s' "$out" | squeeze)" "03-reconcile-ground done reconcile <- 01-seam-inventory, 02-concept-discussion"
assert_eq "T10d: a root node has no arrow" "$(printf '%s' "$out" | grep '^ *01-seam-inventory' | squeeze)" "01-seam-inventory done work"
out="$("$PLAN" graph --project demo --json)"
assert_eq "T10e: nodes and edges" "$(printf '%s' "$out" | jq -c '[.plan, (.nodes|length), (.edges|length)]')" '["01-concept",9,10]'
assert_eq "T10f: an edge runs blocker -> node" "$(printf '%s' "$out" | jq -c '.edges | map(select(.to == "08-tickets"))')" '[{"from":"07-spec","to":"08-tickets"}]'

echo "T11: check — one line per violation, exit 1; silence and exit 0 on a clean plan"
addf() { sed -i '' "1a\\
$2: $3
" "$NODES/$1.md"; }   # <id> <key> <value>: a new frontmatter line
PM="$TMP/work/demo/plans/01-concept/plan.md"; cp "$PM" "$TMP/plan.bak"
out="$("$PLAN" check --project demo 2>&1)"; rc=$?
assert_eq "T11a: the fixture is clean — exit 0, no output" "$rc:$out" "0:"
assert_eq "T11b: --json on a clean plan is []" "$("$PLAN" check --project demo --json | jq -c .)" "[]"
setf 09-reconcile-verdict kind work
out="$("$PLAN" check --project demo)"; rc=$?
assert_eq "T11c: a wave with no reconcile node exits 1" "$rc" "1"
assert_eq "T11d: exactly one line, naming the wave" "$(printf '%s' "$out" | squeeze)" "wave 3: 0 reconcile nodes (want exactly one)"
reset; setf 08-tickets kind reconcile
assert_eq "T11e: two reconcile nodes in a wave" "$("$PLAN" check --project demo | squeeze)" "wave 3: 2 reconcile nodes (want exactly one)"
reset; setf 07-spec kind reconcile; setf 09-reconcile-verdict kind work
out="$("$PLAN" check --project demo)"; rc=$?
assert_eq "T11f: a reconcile node not last in its wave exits 1" "$rc" "1"
assert_eq "T11g: one line" "$(printf '%s' "$out" | grep -c .)" "1"
assert_contains "T11h: names the file" "$out" "07-spec.md: reconcile node is not last in wave 3"
assert_contains "T11i: ... and what follows it" "$out" "08-tickets, 09-reconcile-verdict follow"
reset; addf 04-grill-open-items check true
out="$("$PLAN" check --project demo)"; rc=$?
assert_eq "T11j: a check on a hitl node exits 1" "$rc" "1"
assert_contains "T11k: names the file" "$out" "04-grill-open-items.md: hitl node has a check"
assert_eq "T11l: one line" "$(printf '%s' "$out" | grep -c .)" "1"
reset; setf 08-tickets blocked_by '[07-spce]'
out="$("$PLAN" check --project demo 2>/dev/null)"; rc=$?
assert_eq "T11m: a dangling blocked_by is a listed violation, not a load refusal" "$rc" "1"
assert_contains "T11n: names file and id" "$out" "08-tickets.md: blocked_by names no node 07-spce"
assert_eq "T11o: one line" "$(printf '%s' "$out" | grep -c .)" "1"
out="$("$PLAN" check --project demo --json 2>/dev/null)"
assert_eq "T11p: --json lists violations as objects" "$(printf '%s' "$out" | jq -c '[.[] | [.rule, .id, .wave, (.path | endswith("08-tickets.md")), .message]]')" \
  '[["blocked-by","08-tickets",3,true,"blocked_by names no node 07-spce"]]'
addf 04-grill-open-items check true
assert_eq "T11q: every violation is reported at once" "$("$PLAN" check --project demo --json | jq -c '[.[].rule] | sort')" '["blocked-by","hitl-check"]'
reset; setf 07-spec sessions '[]'
out="$("$PLAN" check --project demo)"; rc=$?
assert_eq "T11r: a doing node with no session exits 1" "$rc" "1"
assert_eq "T11s: one line naming the file" "$(printf '%s' "$out" | grep -c '07-spec.md: doing with no session listed'):$(printf '%s' "$out" | grep -c .)" "1:1"
reset; sed '1d' "$TMP/orig/08-tickets.md" > "$NODES/08-tickets.md"
out="$("$PLAN" check --project demo 2>/dev/null)"; rc=$?
assert_eq "T11t: malformed frontmatter is a listed violation" "$rc" "1"
assert_eq "T11u: one line naming the file" "$(printf '%s' "$out" | squeeze | sed 's|.*/||')" "08-tickets.md: malformed frontmatter"
reset; setf 08-tickets status pending
assert_eq "T11v: an unknown value is a listed violation" "$("$PLAN" check --project demo --json | jq -c '[.[] | [.rule, .id]]')" '[["malformed","08-tickets"]]'
reset; setf 08-tickets status doing
assert_eq "T11w: an unknown-value node trips only the malformed rule" "$("$PLAN" check --project demo --json | jq -c '[.[].rule]')" '["doing-sessions"]'
reset
echo "T11x-z: wave size — plan frontmatter wave_max, then PLAN_WAVE_MAX (env or context-budget.env), then the built-in 6"
out="$(PLAN_WAVE_MAX=2 "$PLAN" check --project demo)"; rc=$?
assert_eq "T11x: three waves of three over a limit of 2 — three lines, exit 1" "$rc:$(printf '%s' "$out" | grep -c .)" "1:3"
assert_contains "T11y: the line" "$(printf '%s' "$out" | squeeze)" "wave 1: 3 nodes, limit 2"
printf 'PLAN_WAVE_MAX=2\n' > "$TMP/context-budget.env"
assert_eq "T11z1: context-budget.env sets the default" "$("$PLAN" check --project demo | grep -c .)" "3"
assert_eq "T11z2: explicit env beats the file" "$(PLAN_WAVE_MAX=3 "$PLAN" check --project demo | grep -c .)" "0"
sed -i '' 's/^status: open$/status: open\
wave_max: 3/' "$PM"
assert_eq "T11z3: plan frontmatter wave_max beats both" "$(PLAN_WAVE_MAX=2 "$PLAN" check --project demo; echo "rc=$?")" "rc=0"
rm "$TMP/context-budget.env"
sed -i '' 's/^wave_max: 3$/wave_max: 2/' "$PM"
assert_eq "T11z4: wave_max: 2 in the plan trips all three waves" "$("$PLAN" check --project demo | grep -c .)" "3"
sed -i '' 's/^wave_max: 2$/wave_max: many/' "$PM"
assert_eq "T11z5: a non-integer wave_max is a malformed violation on plan.md" "$("$PLAN" check --project demo --json | jq -c '[.[] | [.rule, (.path | endswith("plan.md"))]]')" '[["malformed",true]]'
sed '1d' "$TMP/plan.bak" > "$PM"
assert_eq "T11z6: malformed plan.md frontmatter (with --plan) is a violation" "$("$PLAN" check --project demo --plan 01-concept --json 2>/dev/null | jq -c '[.[] | [.rule, .message]]')" '[["malformed","malformed frontmatter"]]'
cp "$TMP/plan.bak" "$PM"
assert_eq "T11z7: restored fixture is clean again" "$("$PLAN" check --project demo; echo "rc=$?")" "rc=0"

echo "passed=$PASS failed=$FAIL"
[ "$FAIL" -eq 0 ]
