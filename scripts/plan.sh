#!/usr/bin/env bash
# File: scripts/plan.sh
# Purpose: Read and write a work item's plan (work/<item>/plans/NN-<slug>/):
#          node files under nodes/ are the truth, plan.md is prose plus a
#          rendered board. This script derives, never decides: everything it
#          prints comes from the node files; it never calls a model.
#          Format, resolution order and exit codes: docs/plans.md. Bash 3.2 + jq.
# Usage:   scripts/plan.sh <verb> [args] [--project <item>] [--plan <name>] [--json]
#          new <slug>      create the next-numbered plan (refuses while one is open)
#          status          plan, open/closed, wave n of m, counts by status, sessions used
#          show <id>       print one node (text: the file; --json: its frontmatter + path)
# Resolution: project = --project → session registry binding (a registry
#          record whose pid is an ancestor of this process) → TF_SESSION_PROJECT
#          → the work item the cwd is inside → refuse. Plan = --plan →
#          chain.plan in the item's session record → the single open plan →
#          refuse; read verbs fall back to the latest plan by number.
# Exit:    0 ok / 1 lint or state refusal (malformed node, unknown value,
#          unknown id, a plan already open) / 2 usage or resolution failure.
#          Refusals print `plan: <detail>` on stderr; a node problem names the file.

set -u
WORKSPACE_ROOT="$(cd "$(dirname "$0")/.." && pwd -P)"
STATE_DIR="$WORKSPACE_ROOT/.context-budget"

die() { echo "plan: $2" >&2; exit "$1"; }   # <code> <message>
usage() { sed -n '/^# Usage:/,/^# Resolution:/p' "$0" | sed '$d; s/^# \{0,9\}//' >&2; exit 2; }
command -v jq >/dev/null 2>&1 || die 2 "jq is required"

VERB=""; ARG=""; PROJECT=""; PLAN=""; JSON=0
while [ $# -gt 0 ]; do
  case "$1" in
    --project) [ $# -ge 2 ] || usage; PROJECT="$2"; shift 2 ;;
    --plan)    [ $# -ge 2 ] || usage; PLAN="$2"; shift 2 ;;
    --json)    JSON=1; shift ;;
    -h|--help) usage ;;
    -*)        die 2 "unknown option $1" ;;
    *) if [ -z "$VERB" ]; then VERB="$1"; elif [ -z "$ARG" ]; then ARG="$1"; else usage; fi; shift ;;
  esac
done
case "$VERB" in new|status|show) ;; "") usage ;; *) die 2 "unknown verb $VERB" ;; esac

# ---- project -----------------------------------------------------------------
registry_project() {  # the item bound to the session this process runs under
  local p="$$" hops=0 pids="" f pid ps
  while [ "${p:-0}" -gt 1 ] && [ "$hops" -lt 12 ]; do
    pids="$pids $p"; hops=$((hops + 1)); p=$(ps -o ppid= -p "$p" 2>/dev/null | tr -d ' ')
  done
  for f in "$STATE_DIR/sessions/"*.json; do
    [ -f "$f" ] || continue
    pid=$(jq -r 'select(.project != null and .project != "") | .pid // empty' "$f" 2>/dev/null)
    [ -n "$pid" ] || continue
    case " $pids " in *" $pid "*) ;; *) continue ;; esac
    ps=$(ps -o lstart= -p "$pid" 2>/dev/null | sed 's/^ *//;s/ *$//')
    [ "$ps" = "$(jq -r '.pid_start // empty' "$f")" ] || continue   # recycled pid
    jq -r '.project' "$f"; return 0
  done
  return 1
}
cwd_project() {
  local here; here="$(pwd -P)/"
  case "$here" in "$WORKSPACE_ROOT/work/"*) here="${here#"$WORKSPACE_ROOT/work/"}"; printf '%s' "${here%%/*}" ;; *) return 1 ;; esac
}
if [ -z "$PROJECT" ]; then
  PROJECT="$(registry_project)" || PROJECT="${TF_SESSION_PROJECT:-}"
  [ -n "$PROJECT" ] || PROJECT="$(cwd_project)" \
    || die 2 "no work item: pass --project, or run from a registered session, TF_SESSION_PROJECT, or inside work/<item>/"
fi
ITEM="$WORKSPACE_ROOT/work/$PROJECT"
[ -d "$ITEM" ] || die 2 "work/$PROJECT is not a work item"
PLANS="$ITEM/plans"

# ---- frontmatter --------------------------------------------------------------
fm_block() {  # <file>: the lines between the opening and closing ---, comments stripped; 1 when malformed
  local block
  block="$(awk 'NR==1 && $0!="---"{exit} NR>1 && $0=="---"{found=1; exit} NR>1{print} END{if(!found) exit 2}' "$1")" || return 1
  printf '%s\n' "$block" | sed -E 's/[[:space:]]+#[[:space:]].*$//; /^[[:space:]]*$/d'
  ! printf '%s\n' "$block" | sed -E '/^[[:space:]]*$/d; /^[[:space:]]*#/d' | grep -qvE '^[a-z_]+:'
}
fm_get() { fm_block "$1" | sed -n "s/^$2:[[:space:]]*//p" | head -1 | sed 's/[[:space:]]*$//'; }

plan_status() {  # <plan dir>: open|closed, or exit 1 naming plan.md
  local s; s="$(fm_get "$1/plan.md" status)" || die 1 "$1/plan.md: malformed frontmatter"
  case "$s" in open|closed) printf '%s' "$s" ;; *) die 1 "$1/plan.md: unknown status '$s' (open|closed)" ;; esac
}
open_plans() { local d; for d in "$PLANS"/[0-9]*/; do [ -f "$d/plan.md" ] || continue; [ "$(plan_status "${d%/}")" = open ] && basename "$d"; done; return 0; }

NODE_JQ='
  def trim: sub("^[[:space:]]+"; "") | sub("[[:space:]]+$"; "");
  def list: trim | ltrimstr("[") | rtrimstr("]") | split(",") | map(trim) | map(select(. != ""));
  def int($k): if (.[$k] | tostring | test("^[0-9]+$")) then .[$k] |= tonumber else .problem //= "\($k) is not an integer" end;
  [ split("\n")[] | select(. != "") | capture("^(?<key>[a-z_]+):(?<value>.*)$") ] | from_entries
  | with_entries(.value |= trim) | .problem = null
  | if (.id // "") == "" then .problem //= "missing id" else . end
  | if .status == null then .problem //= "missing status"
    elif (.status | IN("todo","doing","done","blocked","dropped") | not) then .problem //= "unknown status \(.status) (todo|doing|done|blocked|dropped)" else . end
  | .kind //= "work"
  | if (.kind | IN("work","reconcile","hitl") | not) then .problem //= "unknown kind \(.kind) (work|reconcile|hitl)" else . end
  | .tier //= (if .kind == "reconcile" then "frontier" else $default_tier end)
  | if (.tier | IN("frontier","standard","cheap","auto") | not) then .problem //= "unknown tier \(.tier) (frontier|standard|cheap|auto)" else . end
  | if .wave == null then .problem //= "missing wave" else int("wave") end
  | .parallel //= "1" | int("parallel") | .loop //= "1" | int("loop")
  | .blocked_by = ((.blocked_by // "[]") | list)
  | .sessions = ((.sessions // "[]") | list | map(tonumber? // .))
  | .isolated = ((.isolated // "no") | IN("yes", "true"))
  | .check //= null | .title //= "" | .path = $path'
node_json() {  # <file> <default tier>: one JSON object, or exit 1 naming the file
  local block out
  block="$(fm_block "$1")" || die 1 "$1: malformed frontmatter"
  out="$(printf '%s\n' "$block" | jq -R -s --arg path "$1" --arg default_tier "$2" "$NODE_JQ")" || die 1 "$1: malformed frontmatter"
  [ "$(printf '%s' "$out" | jq -r '.problem // empty')" = "" ] || die 1 "$1: $(printf '%s' "$out" | jq -r '.problem')"
  printf '%s' "$out" | jq 'del(.problem)'
}
load_nodes() {  # <plan dir>: a JSON array of every node, sorted by file name
  local tier f one out=""
  tier="$(fm_get "$1/plan.md" default_tier)"; [ -n "$tier" ] || tier=standard
  for f in "$1"/nodes/*.md; do
    [ -f "$f" ] || continue
    one="$(node_json "$f" "$tier")" || exit 1     # node_json already named the file
    out="$out$one"
  done
  printf '%s' "$out" | jq -s '.'
}

# ---- verbs --------------------------------------------------------------------
cmd_new() {
  [ -n "$ARG" ] || usage
  printf '%s' "$ARG" | grep -qE '^[a-z0-9][a-z0-9-]*$' || die 2 "slug '$ARG' must be lowercase [a-z0-9-]"
  local open n dir name
  open="$(open_plans | head -1)"
  [ -z "$open" ] || die 1 "$open is still open in work/$PROJECT — close it (status: closed) before opening another"
  n=0; for dir in "$PLANS"/[0-9]*/; do [ -d "$dir" ] || continue; dir="$(basename "$dir")"; dir="${dir%%-*}"; [ "$dir" -gt "$n" ] 2>/dev/null && n="$dir"; done
  name="$(printf '%02d-%s' $((n + 1)) "$ARG")"; dir="$PLANS/$name"
  mkdir -p "$dir/nodes" || die 1 "cannot create $dir"
  cat > "$dir/plan.md" <<PLAN
---
plan: $name
status: open
replan: local
default_tier: standard
---

# Plan $(printf '%02d' $((n + 1))) — <title>

## Goal

## Not yet specified

## Out of scope

## Replans

<!-- plan:begin board -->
<!-- plan:end board -->
PLAN
  if [ "$JSON" -eq 1 ]; then jq -n --arg plan "$name" --arg path "work/$PROJECT/plans/$name" '{plan: $plan, path: $path}'
  else echo "created work/$PROJECT/plans/$name"; fi
}

resolve_plan() {  # sets PLAN_DIR
  local rec open count
  if [ -z "$PLAN" ]; then
    rec="$ITEM/session-state.json"
    [ -f "$rec" ] && PLAN="$(jq -r '.chain.plan // empty' "$rec" 2>/dev/null)"
  fi
  if [ -z "$PLAN" ]; then
    open="$(open_plans)"; count="$(printf '%s' "$open" | grep -c .)"
    if [ "$count" -eq 1 ]; then PLAN="$open"
    else  # read verbs: the latest plan by number
      PLAN="$(for d in "$PLANS"/[0-9]*/; do [ -f "$d/plan.md" ] && basename "$d"; done | sort | tail -1)"
      [ -n "$PLAN" ] || die 2 "work/$PROJECT has no plan; scripts/plan.sh new <slug> creates one"
    fi
  fi
  PLAN_DIR="$PLANS/$PLAN"
  [ -f "$PLAN_DIR/plan.md" ] || die 2 "work/$PROJECT/plans/$PLAN is not a plan"
}

cmd_status() {
  local pstatus nodes
  pstatus="$(plan_status "$PLAN_DIR")"
  nodes="$(load_nodes "$PLAN_DIR")" || exit 1
  printf '%s' "$nodes" | jq --arg plan "$PLAN" --arg status "$pstatus" --argjson json "$JSON" '
    def n($s): map(select(.status == $s)) | length;
    { plan: $plan, status: $status,
      wave: { total: (([.[].wave] | max) // 0),
              current: (([.[] | select(.status != "done" and .status != "dropped") | .wave] | min) // (([.[].wave] | max) // 0)) },
      counts: { todo: n("todo"), doing: n("doing"), done: n("done"), blocked: n("blocked"), dropped: n("dropped"), total: length },
      sessions_used: ([.[].sessions[]] | unique | length) }
    | if $json == 1 then . else
      "plan \(.plan)  \(.status)  wave \(.wave.current) of \(.wave.total)  done \(.counts.done)/\(.counts.total)  doing \(.counts.doing)  todo \(.counts.todo)  blocked \(.counts.blocked)  dropped \(.counts.dropped)  sessions \(.sessions_used)" end' -r
}

cmd_show() {
  [ -n "$ARG" ] || usage
  local nodes node
  nodes="$(load_nodes "$PLAN_DIR")" || exit 1
  node="$(printf '%s' "$nodes" | jq -c --arg id "$ARG" '.[] | select(.id == $id)' | head -1)"
  [ -n "$node" ] || die 1 "no node '$ARG' in work/$PROJECT/plans/$PLAN"
  if [ "$JSON" -eq 1 ]; then printf '%s\n' "$node" | jq '.'; else cat "$(printf '%s' "$node" | jq -r '.path')"; fi
}

case "$VERB" in
  new)    cmd_new ;;
  status) resolve_plan; cmd_status ;;
  show)   resolve_plan; cmd_show ;;
esac
