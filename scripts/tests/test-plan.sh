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


# Write verbs (ticket 04). Each case edits the fixture copy, then reset. The
# session number comes from work/demo/session-state.json (seq 3 here).
SS="$TMP/work/demo/session-state.json"
printf '{"schema":1,"seq":3}\n' > "$SS"
fm()  { sed -n "s/^$2:[[:space:]]*//p" "$NODES/$1.md" | head -1 | sed 's/[[:space:]]*#.*$//; s/[[:space:]]*$//'; }   # <id> <key>: the raw value
logs() { sed -n '/^## Log/,$p' "$NODES/$1.md" | sed '1d' | grep -c .; }   # <id>: Log lines
lastlog() { sed -n '/^## Log/,$p' "$NODES/$1.md" | grep '^- ' | tail -1; }

echo "T12: start — a frontier node goes todo -> doing, stamped with the session"
reset; setf 07-spec status done
out="$("$PLAN" start 08-tickets --project demo)"; rc=$?
assert_eq "T12a: exit 0, one line" "$rc:$out" "0:08-tickets doing"
assert_eq "T12b: status written in place" "$(fm 08-tickets status)" "doing"
assert_eq "T12c: session appended to sessions" "$(fm 08-tickets sessions)" "[3]"
assert_eq "T12d: one Log line, stamped s3" "$(logs 08-tickets):$(lastlog 08-tickets)" "1:- s3 · started"
assert_eq "T12e: the rest of the file is byte-identical" "$(diff <(sed '/^status:/d;/^sessions:/d;/^- s3/d' "$TMP/orig/08-tickets.md") <(sed '/^status:/d;/^sessions:/d;/^- s3/d' "$NODES/08-tickets.md") | wc -l | tr -d ' ')" "0"
"$PLAN" check --project demo >/dev/null 2>&1; assert_eq "T12g: the plan still passes check" "$?" "0"
assert_eq "T12h: --json gives {id,status}" "$(reset; setf 07-spec status done; "$PLAN" start 08-tickets --project demo --json | jq -c '[.id,.status]')" '["08-tickets","doing"]'
reset
err="$("$PLAN" start 08-tickets --project demo 2>&1 >/dev/null)"; rc=$?
assert_eq "T12i: a todo node off the frontier (blocker unfinished) is refused" "$rc" "1"
assert_contains "T12j: says why" "$err" "not on the frontier"
assert_eq "T12k: ... and the file is untouched" "$(fm 08-tickets status)" "todo"
out="$("$PLAN" start 08-tickets --project demo --force)"; rc=$?
assert_eq "T12l: --force starts it anyway" "$rc:$(fm 08-tickets status)" "0:doing"
assert_contains "T12m: the Log says it was forced" "$(lastlog 08-tickets)" "forced"
reset
"$PLAN" start 07-spec --project demo >/dev/null 2>&1; assert_eq "T12n: start on a doing node is refused" "$?" "1"
"$PLAN" start 01-seam-inventory --project demo >/dev/null 2>&1; assert_eq "T12o: start on a done node is refused" "$?" "1"
setf 07-spec status blocked
out="$("$PLAN" start 07-spec --project demo --session 4)"; rc=$?
assert_eq "T12p: blocked -> doing is legal (resume), --session overrides the number" "$rc:$(fm 07-spec status):$(fm 07-spec sessions)" "0:doing:[2, 4]"
reset; setf 07-spec status done
"$PLAN" start 08-tickets --project demo --plan 02-none >/dev/null 2>&1; assert_eq "T12q: an unknown --plan exits 2" "$?" "2"
"$PLAN" start no-such --project demo >/dev/null 2>&1; assert_eq "T12r: an unknown id exits 1" "$?" "1"
"$PLAN" start --project demo >/dev/null 2>&1; assert_eq "T12s: no id is usage" "$?" "2"
rm "$SS"
err="$("$PLAN" start 08-tickets --project demo 2>&1 >/dev/null)"; rc=$?
assert_eq "T12t: no session number anywhere is refused" "$rc:$(fm 08-tickets status)" "2:todo"
assert_contains "T12u: ... naming the fix" "$err" "--session"
printf '{"schema":1,"seq":3}\n' > "$SS"
sed -i '' 's/^status: open$/status: closed/' "$PM"
"$PLAN" start 08-tickets --project demo --plan 01-concept >/dev/null 2>&1; assert_eq "T12v: a write into a closed plan is refused" "$?" "1"
cp "$TMP/plan.bak" "$PM"
reset

echo "T13: done — doing -> done once the check passes; a failing check is refused, the Nth writes blocked"
reset
out="$("$PLAN" done 07-spec --project demo)"; rc=$?
assert_eq "T13a: no check — exit 0, one line" "$rc:$out" "0:07-spec done"
assert_eq "T13b: status, session, Log" "$(fm 07-spec status):$(fm 07-spec sessions):$(lastlog 07-spec)" "done:[2, 3]:- s3 · done"
assert_eq "T13c: the frontier moves on" "$("$PLAN" frontier --project demo | squeeze)" "08-tickets work standard"
reset; addf 07-spec check 'test -f marker.txt && test -d "$WORKSPACE_ROOT/scripts" && echo checked'
touch "$TMP/work/demo/marker.txt"
out="$("$PLAN" done 07-spec --project demo 2>/dev/null)"; rc=$?
assert_eq "T13d: the check runs from the work item dir with WORKSPACE_ROOT set; its output stays off stdout" "$rc:$out" "0:07-spec done"
assert_eq "T13e: Log records the passing check" "$(lastlog 07-spec)" "- s3 · check passed → done"
rm "$TMP/work/demo/marker.txt"
reset; addf 07-spec check false
err="$("$PLAN" done 07-spec --project demo 2>&1 >/dev/null)"; rc=$?
assert_eq "T13f: a failing check is refused" "$rc" "1"
assert_contains "T13g: says the check failed" "$err" "check failed"
assert_eq "T13h: loop 1 (default): the first failure writes blocked, reason as the latest Log line" "$(fm 07-spec status):$(lastlog 07-spec)" "blocked:- s3 · check failed (exit 1), attempt 1 of 1 → blocked"
reset; addf 07-spec check 'exit 3'; addf 07-spec loop 2
"$PLAN" done 07-spec --project demo >/dev/null 2>&1; rc=$?
assert_eq "T13i: loop 2: the first failure leaves doing" "$rc:$(fm 07-spec status):$(lastlog 07-spec)" "1:doing:- s3 · check failed (exit 3), attempt 1 of 2"
"$PLAN" done 07-spec --project demo >/dev/null 2>&1; rc=$?
assert_eq "T13j: ... the second writes blocked" "$rc:$(fm 07-spec status):$(lastlog 07-spec)" "1:blocked:- s3 · check failed (exit 3), attempt 2 of 2 → blocked"
assert_eq "T13k: two Log lines, nothing else changed" "$(logs 07-spec):$(fm 07-spec sessions)" "2:[2]"
"$PLAN" check --project demo >/dev/null 2>&1; assert_eq "T13l: the plan still passes check" "$?" "0"
reset
"$PLAN" done 08-tickets --project demo >/dev/null 2>&1; assert_eq "T13m: done on a todo node is refused" "$?:$(fm 08-tickets status)" "1:todo"
"$PLAN" done 08-tickets --project demo --force >/dev/null 2>&1; assert_eq "T13n: --force allows todo -> done" "$?:$(fm 08-tickets status)" "0:done"
assert_contains "T13o: ... and says so in the Log" "$(lastlog 08-tickets)" "forced from todo"
"$PLAN" done 01-seam-inventory --project demo >/dev/null 2>&1; assert_eq "T13p: done on a done node is refused" "$?" "1"
reset; setf 07-spec status blocked
"$PLAN" done 07-spec --project demo >/dev/null 2>&1; assert_eq "T13q: done on a blocked node is refused (start it first)" "$?" "1"
reset; setf 04-grill-open-items status doing
err="$("$PLAN" done 04-grill-open-items --project demo 2>&1 >/dev/null)"; rc=$?
assert_eq "T13r: a hitl node without --by is refused" "$rc:$(fm 04-grill-open-items status)" "1:doing"
assert_contains "T13s: ... naming the flag" "$err" "--by human"
out="$("$PLAN" done 04-grill-open-items --project demo --by human --json)"; rc=$?
assert_eq "T13t: --by human marks it done, --json gives {id,status}" "$rc:$(printf '%s' "$out" | jq -c '[.id,.status]')" '0:["04-grill-open-items","done"]'
assert_eq "T13u: the Log names the actor" "$(lastlog 04-grill-open-items)" "- human · done"
reset

echo "T14: verify — run the check, report, change nothing"
out="$("$PLAN" verify 07-spec --project demo)"; rc=$?
assert_eq "T14a: no check — exit 0" "$rc:$out" "0:07-spec: no check"
addf 07-spec check true
out="$("$PLAN" verify 07-spec --project demo)"; rc=$?
assert_eq "T14b: a passing check" "$rc:$out" "0:07-spec: check passed"
setf 07-spec check 'exit 4'
out="$("$PLAN" verify 07-spec --project demo)"; rc=$?
assert_eq "T14c: a failing check exits 1 with the code" "$rc:$out" "1:07-spec: check failed (exit 4)"
assert_eq "T14d: the file is untouched" "$(fm 07-spec status):$(logs 07-spec)" "doing:0"
assert_eq "T14e: any status will do" "$("$PLAN" verify 01-seam-inventory --project demo >/dev/null 2>&1; echo "rc=$?")" "rc=1"
reset

echo "T15: block and drop — doing -> blocked with a reason; any -> dropped"
out="$("$PLAN" block 07-spec "spec needs the user's call on tiers" --project demo)"; rc=$?
assert_eq "T15a: exit 0, one line" "$rc:$out" "0:07-spec blocked"
assert_eq "T15b: status and the reason as the latest Log line" "$(fm 07-spec status):$(lastlog 07-spec)" "blocked:- s3 · blocked: spec needs the user's call on tiers"
assert_eq "T15c: frontier reports it" "$("$PLAN" frontier --project demo 2>&1 >/dev/null | squeeze)" "plan: frontier empty: wave 3 has nothing ready — 07-spec blocked; 08-tickets waits on 07-spec; 09-reconcile-verdict waits on 07-spec, 08-tickets"
"$PLAN" block 07-spec "again" --project demo >/dev/null 2>&1; assert_eq "T15d: block on a blocked node is refused" "$?" "1"
"$PLAN" block 08-tickets "why" --project demo >/dev/null 2>&1; assert_eq "T15e: block on a todo node is refused" "$?" "1"
"$PLAN" block 07-spec --project demo >/dev/null 2>&1; assert_eq "T15f: no reason is usage" "$?" "2"
reset
out="$("$PLAN" drop 08-tickets --project demo)"; rc=$?
assert_eq "T15g: drop a todo node" "$rc:$out:$(fm 08-tickets status):$(lastlog 08-tickets)" "0:08-tickets dropped:dropped:- s3 · dropped"
out="$("$PLAN" drop 07-spec "superseded by 08" --project demo --json)"; rc=$?
assert_eq "T15h: drop a doing node with a reason, --json" "$rc:$(printf '%s' "$out" | jq -c '[.id,.status]'):$(lastlog 07-spec)" '0:["07-spec","dropped"]:- s3 · dropped: superseded by 08'
assert_eq "T15i: the frontier treats dropped blockers as finished" "$("$PLAN" frontier --project demo | squeeze)" "09-reconcile-verdict reconcile frontier"
"$PLAN" drop 07-spec --project demo >/dev/null 2>&1; assert_eq "T15j: drop on a dropped node is refused" "$?" "1"
"$PLAN" drop 01-seam-inventory --project demo >/dev/null 2>&1; assert_eq "T15k: done -> dropped is allowed (any -> dropped)" "$?:$(fm 01-seam-inventory status)" "0:dropped"
reset

echo "T16: add — a new node file from flags, next number, todo"
out="$("$PLAN" add board-renderer --wave 3 --title "Render the board" --blocked-by 07-spec,08-tickets --project demo)"; rc=$?
assert_eq "T16a: exit 0, one line" "$rc:$out" "0:10-board-renderer todo"
assert_eq "T16b: the file exists and parses" "$("$PLAN" show 10-board-renderer --project demo --json | jq -c '[.id,.title,.status,.kind,.wave,.blocked_by,.tier,.parallel,.loop,.check,.sessions,.isolated]')" \
  '["10-board-renderer","Render the board","todo","work",3,["07-spec","08-tickets"],"standard",1,1,null,[],false]'
assert_eq "T16c: sections present, frontmatter in the fixture's order" "$(grep -E '^(id|title|status|kind|wave|blocked_by|sessions|## )' "$NODES/10-board-renderer.md" | cut -d: -f1 | tr '\n' ' ')" "id title status kind wave blocked_by sessions ## Goal ## Acceptance ## Log "
"$PLAN" check --project demo >/dev/null 2>&1; assert_eq "T16d: check now trips reconcile-last (10 follows 09 in wave 3) — add does not lint" "$?" "1"
rm "$NODES/10-board-renderer.md"
out="$("$PLAN" add reconcile-two --wave 4 --kind reconcile --tier frontier --parallel 2 --loop 3 --check 'true' --isolated --project demo --json)"; rc=$?
assert_eq "T16e: every flag lands, --json" "$rc:$(printf '%s' "$out" | jq -c '[.id,.status]')" '0:["10-reconcile-two","todo"]'
assert_eq "T16f: ... parsed back" "$("$PLAN" show 10-reconcile-two --project demo --json | jq -c '[.kind,.tier,.parallel,.loop,.check,.isolated,.wave,.blocked_by]')" '["reconcile","frontier",2,3,"true",true,4,[]]'
"$PLAN" check --project demo >/dev/null 2>&1; assert_eq "T16g: a wave-4 reconcile node keeps the plan clean" "$?" "0"
"$PLAN" add reconcile-two --wave 4 --project demo >/dev/null 2>&1; assert_eq "T16h: a slug already in use is refused" "$?" "1"
"$PLAN" add other --wave 4 --blocked-by no-such --project demo >/dev/null 2>&1; assert_eq "T16i: a blocker naming no node is refused" "$?:$(ls "$NODES" | grep -c other)" "1:0"
"$PLAN" add other --project demo >/dev/null 2>&1; assert_eq "T16j: no --wave is usage" "$?" "2"
"$PLAN" add Bad_Slug --wave 4 --project demo >/dev/null 2>&1; assert_eq "T16k: a bad slug exits 2" "$?" "2"
"$PLAN" add other --wave 4 --kind task --project demo >/dev/null 2>&1; assert_eq "T16l: an unknown kind exits 2" "$?" "2"
rm "$NODES/10-reconcile-two.md"
reset

echo "T17: note — appends to plan.md -> Not yet specified; touches no node file"
before="$(cat "$NODES"/*.md | cksum)"
out="$("$PLAN" note "tier policy needs a per-runtime override" --project demo)"; rc=$?
assert_eq "T17a: exit 0, silent" "$rc:$out" "0:"
assert_eq "T17b: the line lands at the end of the section, stamped" "$(sed -n '/^## Not yet specified/,/^## Out of scope/p' "$PM" | grep '^- ' | tail -1)" "- s3 · tier policy needs a per-runtime override"
assert_eq "T17c: section order intact, board untouched" "$(diff <(sed '/^- s3 · tier/d' "$PM") "$TMP/plan.bak" | wc -l | tr -d ' ')" "0"
assert_eq "T17d: node files untouched" "$(cat "$NODES"/*.md | cksum)" "$before"
"$PLAN" note "second" --project demo >/dev/null
assert_eq "T17e: a second note follows the first" "$(sed -n '/^## Not yet specified/,/^## Out of scope/p' "$PM" | grep -c '^- ')" "3"
"$PLAN" note --project demo >/dev/null 2>&1; assert_eq "T17f: no text is usage" "$?" "2"
cp "$TMP/plan.bak" "$PM"
"$PLAN" check --project demo >/dev/null 2>&1; assert_eq "T17g: fixture clean at the end" "$?" "0"
rm -f "$SS"

echo "passed=$PASS failed=$FAIL"
[ "$FAIL" -eq 0 ]
