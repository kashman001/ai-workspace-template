#!/usr/bin/env bash
# File: scripts/plan.sh
# Purpose: Read and write a work item's plan (work/<item>/plans/NN-<slug>/):
#          node files under nodes/ are the truth, plan.md is prose plus a
#          rendered board. This script derives, never decides: everything it
#          prints comes from the node files; it never calls a model.
#          Format, resolution order and exit codes: docs/plans.md. Bash 3.2 + jq.
# Usage:   scripts/plan.sh <verb> [args] [--project <item>] [--plan <name>] [--json]
#          (--project=<item> and --plan=<name> work too)
#          new <slug>      create the next-numbered plan (refuses while one is open)
#          status          plan, open/closed, wave n of m, counts by status, sessions used
#          show <id>       print one node (text: the file; --json: its frontmatter + path)
#          frontier        todo nodes whose blockers are all done/dropped, in the lowest
#                          unfinished wave: id kind tier (exit 1 + why when empty but unfinished)
#          remaining       every node not done/dropped, by wave then id: id status wave
#          graph           the plan as text, one block per wave, `<- blockers` per node
#          check           lint: one line per violation on stdout, exit 1 when any; silent
#                          and exit 0 on a clean plan (rules: docs/plans.md → "Check rules")
#          start <id>      todo (on the frontier, or --force) or blocked → doing; stamps the session
#          done <id>       doing → done once the node's check passes; the Nth failure (loop: N)
#                          writes blocked; hitl nodes need --by <actor>; --force allows todo → done;
#                          the check's output shows only on failure (its last 20 lines)
#          verify <id>     run the node's check, exit 0/1, change nothing
#          block <id> <reason>   doing → blocked, the reason as the latest Log line
#          drop <id> [reason]    any → dropped
#          add <slug> --wave <n> [--title t] [--kind k] [--tier t] [--leaf label] [--blocked-by a,b]
#                          [--parallel n] [--loop n] [--check cmd] [--isolated]   new node file;
#                          --leaf without --tier writes tier: auto
#          note <text>     append to plan.md → "Not yet specified"; touches no node
#          sync            re-render the board into plan.md and the position block into
#                          next-session.md, each between `<!-- plan:begin <name> -->` /
#                          `<!-- plan:end <name> -->` markers; missing markers: exit 1, nothing written
#          Write verbs: --session <n> sets the session number (default: seq in the item's
#          session-state.json), --by <actor> the Log stamp; they refuse a closed plan.
#          --runtime <r> names the runtime whose model knob applies (default: PLAN_RUNTIME,
#          then the runtime of the session's registry record); `start` stamps the tier.
# Resolution: project = --project → session registry binding (a registry
#          record whose pid is an ancestor of this process) → TF_SESSION_PROJECT
#          → the work item the cwd is inside → refuse. Plan = --plan →
#          chain.plan in the item's session record (a closed one yields to the
#          single open plan) → the single open plan → refuse; read verbs fall
#          back to the latest plan by number.
# Exit:    0 ok / 1 lint or state refusal (malformed node, unknown value,
#          unknown id, a plan already open, an illegal transition, a failing check)
#          / 2 usage or resolution failure.
#          Refusals print `plan: <detail>` on stderr; a node problem names the file.
# Env:     PLAN_WAVE_MAX — nodes per wave before `check` complains; explicit env >
#          context-budget.env > 6. A plan's `wave_max:` frontmatter overrides it.
#          PLAN_RUNTIME — the runtime for the model knob when --runtime is not given.
#          PLAN_TIER_<LABEL> / PLAN_MODEL_<RUNTIME>_<TIER> — plan-tiers.env (see "tiers").

set -u
WORKSPACE_ROOT="$(cd "$(dirname "$0")/.." && pwd -P)"
STATE_DIR="$WORKSPACE_ROOT/.context-budget"

die() { echo "plan: $2" >&2; exit "$1"; }   # <code> <message>
usage() { sed -n '/^# Usage:/,/^# Resolution:/p' "$0" | sed '$d; s/^# \{0,9\}//' >&2; exit 2; }
command -v jq >/dev/null 2>&1 || die 2 "jq is required"

VERB=""; ARG=""; ARG2=""; PROJECT=""; PLAN=""; JSON=0; FORCE=0; BY=""; SEQ=""; RUNTIME_FLAG=""
TITLE=""; WAVE=""; KIND=""; TIER=""; LEAF=""; BLOCKED_BY=""; PARALLEL=""; LOOP=""; CHECK=""; ISOLATED=""
while [ $# -gt 0 ]; do
  case "$1" in
    --project) [ $# -ge 2 ] || usage; PROJECT="$2"; shift 2 ;;
    --project=*) PROJECT="${1#--project=}"; shift ;;
    --plan)    [ $# -ge 2 ] || usage; PLAN="$2"; shift 2 ;;
    --plan=*)  PLAN="${1#--plan=}"; shift ;;
    --by)      [ $# -ge 2 ] || usage; BY="$2"; shift 2 ;;
    --session) [ $# -ge 2 ] || usage; SEQ="$2"; shift 2 ;;
    --runtime) [ $# -ge 2 ] || usage; RUNTIME_FLAG="$2"; shift 2 ;;
    --title)   [ $# -ge 2 ] || usage; TITLE="$2"; shift 2 ;;
    --wave)    [ $# -ge 2 ] || usage; WAVE="$2"; shift 2 ;;
    --kind)    [ $# -ge 2 ] || usage; KIND="$2"; shift 2 ;;
    --tier)    [ $# -ge 2 ] || usage; TIER="$2"; shift 2 ;;
    --leaf)    [ $# -ge 2 ] || usage; LEAF="$2"; shift 2 ;;
    --blocked-by) [ $# -ge 2 ] || usage; BLOCKED_BY="$2"; shift 2 ;;
    --parallel) [ $# -ge 2 ] || usage; PARALLEL="$2"; shift 2 ;;
    --loop)    [ $# -ge 2 ] || usage; LOOP="$2"; shift 2 ;;
    --check)   [ $# -ge 2 ] || usage; CHECK="$2"; shift 2 ;;
    --isolated) ISOLATED=yes; shift ;;
    --json)    JSON=1; shift ;;
    --force)   FORCE=1; shift ;;
    -h|--help) usage ;;
    --*" "*)   die 2 "unknown option '$1': a flag and its value arrived as one word — pass two words, or ${1%% *}=${1#* }" ;;
    -*)        die 2 "unknown option $1" ;;
    *) if [ -z "$VERB" ]; then VERB="$1"; elif [ -z "$ARG" ]; then ARG="$1"; elif [ -z "$ARG2" ]; then ARG2="$1"; else usage; fi; shift ;;
  esac
done
case "$VERB" in new|status|show|frontier|remaining|graph|check|start|done|verify|block|drop|add|note|sync) ;; "") usage ;; *) die 2 "unknown verb $VERB" ;; esac

# ---- project -----------------------------------------------------------------
registry_record() {  # the project-bound session record whose pid is an ancestor of this process (its path), or 1
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
    printf '%s' "$f"; return 0
  done
  return 1
}
registry_project() { local f; f="$(registry_record)" && jq -r '.project' "$f"; }  # the item bound to this session
RUNTIME=""; RUNTIME_KNOWN=0
resolve_runtime() {  # sets RUNTIME: --runtime -> PLAN_RUNTIME -> the bound registry record's runtime -> "" (unknown); once
  local f
  [ "$RUNTIME_KNOWN" -eq 0 ] || return 0
  RUNTIME="${RUNTIME_FLAG:-${PLAN_RUNTIME:-}}"
  [ -n "$RUNTIME" ] || { f="$(registry_record)" && RUNTIME="$(jq -r '.runtime // empty' "$f")"; }
  RUNTIME_KNOWN=1
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
  | .tier //= (if .kind == "reconcile" or .kind == "hitl" then "frontier" else $default_tier end)
  | if (.tier | IN("frontier","standard","cheap","auto") | not) then .problem //= "unknown tier \(.tier) (frontier|standard|cheap|auto)" else . end
  | .leaf //= null
  | if .leaf != null and (.leaf | test("^[a-z][a-z0-9_]*$") | not) then .problem //= "leaf label \(.leaf) is not [a-z][a-z0-9_]*" else . end
  | if .wave == null then .problem //= "missing wave" else int("wave") end
  | .parallel //= "1" | int("parallel") | .loop //= "1" | int("loop")
  | .blocked_by = ((.blocked_by // "[]") | list)
  | .sessions = ((.sessions // "[]") | list | map(tonumber? // .))
  | .isolated = ((.isolated // "no") | IN("yes", "true"))
  | .check //= null | .title //= "" | .path = $path'
node_parse() {  # <file> <default tier>: one JSON object, .problem set (never exits) when the frontmatter is bad
  local block
  block="$(fm_block "$1")" && printf '%s\n' "$block" | jq -R -s --arg path "$1" --arg default_tier "$2" "$NODE_JQ" 2>/dev/null \
    || jq -n --arg path "$1" '{path: $path, id: ($path | sub(".*/"; "") | rtrimstr(".md")), problem: "malformed frontmatter"}'
}
node_json() {  # <file> <default tier>: one JSON object, or exit 1 naming the file
  local out; out="$(node_parse "$1" "$2")"
  [ "$(printf '%s' "$out" | jq -r '.problem // empty')" = "" ] || die 1 "$1: $(printf '%s' "$out" | jq -r '.problem')"
  printf '%s' "$out" | jq 'del(.problem)'
}
# On an array of nodes, with $ids bound to the plan's ids: one violation object per blocked_by entry naming no node.
DANGLING_JQ='.[] | .blocked_by[] as $b | select(($ids | index($b)) == null)
  | {rule: "blocked-by", id, wave, path, message: "blocked_by names no node \($b)"}'
# ---- tiers ----------------------------------------------------------------------
# `auto` resolves node tier -> plan.md `tier_<label>:` -> PLAN_TIER_<LABEL> in plan-tiers.env
# -> the plan's default_tier -> standard; the label is the node's `leaf:`. Reconcile and hitl
# fan in to frontier. PLAN_MODEL_<RUNTIME>_<TIER> maps a tier to a model knob for the resolved
# runtime; no knob = null = the session model (docs/plans.md -> "Tiers").
tier_env_json() {  # {policy: {label: tier}, models: {runtime: {tier: model}}} from plan-tiers.env
  local f="$WORKSPACE_ROOT/plan-tiers.env" v
  { [ ! -f "$f" ] || ( . "$f" >/dev/null 2>&1
      for v in $(compgen -A variable PLAN_TIER_; compgen -A variable PLAN_MODEL_); do printf '%s\t%s\n' "$v" "${!v}"; done ); } \
  | jq -R -s '[split("\n")[] | select(. != "") | split("\t") | {k: .[0], v: .[1]} | select(.v != "")]
      | { policy: (map(select(.k | startswith("PLAN_TIER_")) | {key: (.k | ltrimstr("PLAN_TIER_") | ascii_downcase), value: .v}) | from_entries),
          models: (reduce (map(select(.k | startswith("PLAN_MODEL_")) | (.k | ltrimstr("PLAN_MODEL_") | ascii_downcase | capture("^(?<r>.+)_(?<t>[a-z]+)$")) + {m: .v})[]) as $e
                     ({}; .[$e.r][$e.t] = $e.m)) }'
}
tier_env_check() {  # the first PLAN_TIER_* outside frontier|standard|cheap, as "PLAN_TIER_<LABEL>=<v>: unknown tier (…)", or nothing
  printf '%s' "$1" | jq -r '.policy | to_entries[] | select(.value | IN("frontier","standard","cheap") | not)
    | "PLAN_TIER_\(.key | ascii_upcase)=\(.value): unknown tier (frontier|standard|cheap)"' | head -1
}
plan_tiers_check() {  # <plan dir>: the first `tier_<label>:` outside frontier|standard|cheap, as "tier_<label>: unknown tier <v> (…)", or nothing
  { fm_block "$1/plan.md" 2>/dev/null || true; } | sed -n 's/^tier_\([a-z][a-z0-9_]*\):[[:space:]]*\(.*\)$/\1 \2/p' \
  | awk '$2 !~ /^(frontier|standard|cheap)$/ { print "tier_" $1 ": unknown tier " $2 " (frontier|standard|cheap)"; exit }'
}
plan_tiers_json() {  # <plan dir>: {label: tier} from plan.md's `tier_<label>:` lines
  { fm_block "$1/plan.md" 2>/dev/null || true; } | sed -n 's/^tier_\([a-z][a-z0-9_]*\):[[:space:]]*\(.*\)$/\1\t\2/p' \
  | jq -R -s '[split("\n")[] | select(. != "") | split("\t") | {key: .[0], value: (.[1] | sub("[[:space:]]+$"; ""))}] | from_entries'
}
RESOLVE_JQ='map(.tier_resolved = (
    if .tier != "auto" then .tier
    elif .kind == "reconcile" or .kind == "hitl" then "frontier"
    else ($plan[.leaf // ""] // $env.policy[.leaf // ""] // (if $dt == "auto" then "standard" else $dt end)) end))
  | map(.model = (($env.models[$rt] // {})[.tier_resolved] // null))'

load_nodes() {  # <plan dir>: a JSON array of every node, sorted by file name, each with its resolved tier and model
  local tier f one out="" env
  tier="$(fm_get "$1/plan.md" default_tier)"; [ -n "$tier" ] || tier=standard
  env="$(tier_env_json)"
  one="$(tier_env_check "$env")"; [ -z "$one" ] || die 1 "plan-tiers.env: $one"
  one="$(plan_tiers_check "$1")"; [ -z "$one" ] || die 1 "$1/plan.md: $one"
  [ "$(printf '%s' "$env" | jq '.models | length')" -eq 0 ] || resolve_runtime   # the registry walk only when a knob exists
  for f in "$1"/nodes/*.md; do
    [ -f "$f" ] || continue
    one="$(node_json "$f" "$tier")" || exit 1     # node_json already named the file
    out="$out$one"
  done
  out="$(printf '%s' "$out" | jq -s --argjson env "$env" --argjson plan "$(plan_tiers_json "$1")" --arg dt "$tier" --arg rt "$RUNTIME" "$RESOLVE_JQ")"
  one="$(printf '%s' "$out" | jq -r '[.[].id] as $ids | '"$DANGLING_JQ"' | "\(.path): \(.message)"' | head -1)"
  [ -z "$one" ] || die 1 "$one"
  printf '%s' "$out"
}

# Shared jq for the derived read verbs: column padding, the current wave, what is finished.
DERIVE_JQ='
  def pad($n): . + (" " * ($n - length));
  def idw: ([.[].id | length] | max // 0) + 2;
  def finished: map(select(.status == "done" or .status == "dropped") | .id);
  def current_wave: [.[] | select(.status != "done" and .status != "dropped") | .wave] | min;
  def ready: finished as $ok | map(select(.status == "todo" and (.blocked_by - $ok) == []));
  def frontier: current_wave as $cur | ready | map(select(.wave == $cur));'


# ---- verbs --------------------------------------------------------------------
cmd_new() {
  [ -n "$ARG" ] || usage
  printf '%s' "$ARG" | grep -qE '^[a-z0-9][a-z0-9-]*$' || die 2 "slug '$ARG' must be lowercase [a-z0-9-]"
  local open n dir name
  open="$(open_plans | head -1)"
  [ -z "$open" ] || die 1 "$open is still open in work/$PROJECT — close it (status: closed) before opening another"
  n=0; for dir in "$PLANS"/[0-9]*/; do [ -d "$dir" ] || continue; dir="$(basename "$dir")"; dir="${dir%%-*}"; [ "$dir" -gt "$n" ] 2>/dev/null && n="$dir"; done
  name="$(printf '%02d-%s' $((10#$n + 1)) "$ARG")"; dir="$PLANS/$name"
  mkdir -p "$dir/nodes" || die 1 "cannot create $dir"
  cat > "$dir/plan.md" <<PLAN
---
plan: $name
status: open
replan: local
default_tier: standard
---

# Plan $(printf '%02d' $((10#$n + 1))) — <title>

## Goal

## Not yet specified

## Out of scope

## Replans

<!-- plan:begin board -->
<!-- plan:end board -->
PLAN
  if [ "$JSON" -eq 1 ]; then jq -n --arg plan "$name" --arg path "work/$PROJECT/plans/$name" '{plan: $plan, path: $path}'
  else echo "created work/$PROJECT/plans/$name — name it in later verbs: --plan $name"; fi
}

resolve_plan() {  # [write]: sets PLAN_DIR; a write verb never falls back to the latest plan and refuses a closed one
  local rec open count
  if [ -z "$PLAN" ]; then
    rec="$ITEM/session-state.json"
    [ -f "$rec" ] && PLAN="$(jq -r '.chain.plan // empty' "$rec" 2>/dev/null)"
    # A chain.plan left closed by an earlier chain yields to the open plan: one open → it; several → --plan.
    if [ -n "$PLAN" ] && [ -f "$PLANS/$PLAN/plan.md" ] && [ "$(plan_status "$PLANS/$PLAN")" = closed ]; then
      open="$(open_plans)"; count="$(printf '%s' "$open" | grep -c .)"
      if [ "$count" -eq 1 ]; then PLAN="$open"
      elif [ "$count" -gt 1 ]; then die 2 "chain.plan $PLAN is closed and work/$PROJECT has $count open plans; pass --plan"
      fi
    fi
  fi
  if [ -z "$PLAN" ]; then
    open="$(open_plans)"; count="$(printf '%s' "$open" | grep -c .)"
    if [ "$count" -eq 1 ]; then PLAN="$open"
    elif [ "${1:-}" = write ]; then die 2 "work/$PROJECT has $count open plans; pass --plan"
    else  # read verbs: the latest plan by number
      PLAN="$(for d in "$PLANS"/[0-9]*/; do [ -f "$d/plan.md" ] && basename "$d"; done | sort | tail -1)"
      [ -n "$PLAN" ] || die 2 "work/$PROJECT has no plan; scripts/plan.sh new <slug> creates one"
    fi
  fi
  PLAN_DIR="$PLANS/$PLAN"
  [ -f "$PLAN_DIR/plan.md" ] || die 2 "work/$PROJECT/plans/$PLAN is not a plan"
  [ "${1:-}" = write ] && [ "$(plan_status "$PLAN_DIR")" = closed ] && die 1 "work/$PROJECT/plans/$PLAN is closed; writes need an open plan"
  return 0
}

# ---- write plumbing ----------------------------------------------------------------
# The session number: --session, else seq in the item's session-state.json. The Log
# stamp (WHO): --by, else s<seq>. Node files are rewritten whole via a temp file;
# frontmatter line order and trailing `  # comments` are kept.
[ -n "$SEQ" ] || SEQ="$(jq -r '.seq // empty' "$ITEM/session-state.json" 2>/dev/null)"
[ -z "$SEQ" ] || printf '%s' "$SEQ" | grep -qE '^[0-9]+$' || die 2 "session number '$SEQ' is not an integer"
WHO="${BY:-${SEQ:+s$SEQ}}"
need_who() { [ -n "$WHO" ] || die 2 "no session number (work/$PROJECT/session-state.json has no seq): pass --session <n> or --by <actor>"; }
need_seq() { [ -n "$SEQ" ] || die 2 "no session number (work/$PROJECT/session-state.json has no seq): pass --session <n>"; }
fm_set() {  # <file> <key> <value>: replace the value in place (comment kept), or add the line before the closing ---
  local tmp="$1.tmp.$$"
  awk -v k="$2" -v v="$3" '
    BEGIN { infm = 0; done = 0 }
    NR == 1 && $0 == "---" { infm = 1; print; next }
    infm && $0 == "---" { if (!done) print k ": " v; infm = 0; print; next }
    infm && index($0, k ":") == 1 && !done {
      c = ""; if (match($0, /[[:space:]][[:space:]]+#[[:space:]].*$/)) c = substr($0, RSTART)
      print k ": " v c; done = 1; next }
    { print }' "$1" > "$tmp" && mv "$tmp" "$1"
}
section_append() {  # <file> <heading> <line> [create]: append `- <line>` after the section's last content line; 1 when absent
  local tmp="$1.tmp.$$"
  awk -v h="$2" -v l="- $3" -v create="${4:-}" '
    BEGIN { insec = 0; seen = 0; pending = 0 }
    index($0, h) == 1 && !seen { insec = 1; seen = 1; print; next }
    insec && /^## / { print l; while (pending > 0) { print ""; pending-- }; insec = 0 }
    insec && /^[[:space:]]*$/ { pending++; next }
    insec { while (pending > 0) { print ""; pending-- } }
    { print }
    END { if (insec) print l; else if (!seen) { if (create == "") exit 1; print ""; print h; print l } }' "$1" > "$tmp" && mv "$tmp" "$1" || { rm -f "$tmp"; return 1; }
}
log_append() { section_append "$1" "## Log" "$2" create; }
node_file() {  # <id>: NODE (the node JSON) and NODE_FILE, or exit 1
  local nodes
  nodes="$(load_nodes "$PLAN_DIR")" || exit 1
  NODE="$(printf '%s' "$nodes" | jq -c --arg id "$1" '.[] | select(.id == $id)' | head -1)"
  [ -n "$NODE" ] || die 1 "no node '$1' in work/$PROJECT/plans/$PLAN"
  NODE_FILE="$(printf '%s' "$NODE" | jq -r '.path')"
  NODES_JSON="$nodes"
}
node_field() { printf '%s' "$NODE" | jq -r "$1"; }
stamp_session() {  # add SEQ to the node's sessions (unique, sorted)
  [ -n "$SEQ" ] || return 0
  fm_set "$NODE_FILE" sessions "$(printf '%s' "$NODE" | jq -r --argjson s "$SEQ" '.sessions + [$s] | unique | "[\(map(tostring) | join(", "))]"')"
}
run_check() {  # the node's check, run from the work item dir with its output on stderr; its exit code (0 when none)
  local cmd; cmd="$(node_field '.check // empty')"
  [ -n "$cmd" ] || return 0
  ( cd "$ITEM" && WORKSPACE_ROOT="$WORKSPACE_ROOT" sh -c "$cmd" 1>&2 )
}
run_check_quiet() {  # run_check, its output kept back unless it fails — then the last 20 lines on stderr
  local out rc
  out="$(run_check 2>&1)"; rc=$?
  [ "$rc" -eq 0 ] || printf '%s\n' "$out" | tail -n 20 >&2
  return "$rc"
}
failed_attempts() {  # check failures logged since the node was last started
  awk '/^## Log/ { inlog = 1; next } inlog && /· started/ { n = 0 } inlog && /· check failed/ { n++ } END { print n + 0 }' "$NODE_FILE"
}
report() {  # <id> <status>: the one-line result
  if [ "$JSON" -eq 1 ]; then jq -n --arg id "$1" --arg status "$2" '{id: $id, status: $status}'; else echo "$1 $2"; fi
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

cmd_frontier() {
  local nodes out reason
  nodes="$(load_nodes "$PLAN_DIR")" || exit 1
  out="$(printf '%s' "$nodes" | jq "$DERIVE_JQ"'
    . as $all | idw as $w | finished as $ok | current_wave as $cur
    | ready as $ready | frontier as $front
    | { nodes: $front,
        text: ($front | map("\(.id | pad($w))\(.kind | pad(11))\(.tier_resolved)" + (if .tier == "auto" then " (auto)" else "" end)) | join("\n")),
        reason: (if $cur == null or ($front | length) > 0 then "" else
          "frontier empty: wave \($cur) has nothing ready — "
          + ($all | map(select(.wave == $cur and .status != "done" and .status != "dropped")
              | if .status == "todo" then "\(.id) waits on \(.blocked_by - $ok | join(", "))" else "\(.id) \(.status)" end) | join("; "))
          + (if ($ready | length) > 0 then "; ready only in a later wave: \($ready | map(.id) | join(", "))" else "" end) end) }')"
  reason="$(printf '%s' "$out" | jq -r '.reason')"
  if [ "$JSON" -eq 1 ]; then printf '%s' "$out" | jq '.nodes'; else printf '%s' "$out" | jq -r '.text | select(. != "")'; fi
  [ -z "$reason" ] || die 1 "$reason"
}

cmd_remaining() {
  local nodes
  nodes="$(load_nodes "$PLAN_DIR")" || exit 1
  printf '%s' "$nodes" | jq -r --argjson json "$JSON" "$DERIVE_JQ"'
    idw as $w | map(select(.status != "done" and .status != "dropped")) | sort_by(.wave, .id)
    | if $json == 1 then . else .[] | "\(.id | pad($w))\(.status | pad(9))wave \(.wave)" end'
}

cmd_graph() {
  local nodes
  nodes="$(load_nodes "$PLAN_DIR")" || exit 1
  printf '%s' "$nodes" | jq -r --arg plan "$PLAN" --argjson json "$JSON" "$DERIVE_JQ"'
    idw as $w
    | if $json == 1 then
        { plan: $plan,
          nodes: map({id, title, status, kind, tier, wave, blocked_by}),
          edges: [.[] | .id as $to | .blocked_by[] | {from: ., to: $to}] }
      else
        group_by(.wave)[] | "wave \(.[0].wave)",
          (.[] | ("  \(.id | pad($w))\(.status | pad(9))\(.kind | pad(11))"
                  + (if .blocked_by == [] then "" else "<- \(.blocked_by | join(", "))" end)
                  | sub("[[:space:]]+$"; "")))
      end'
}

cmd_check() {
  local pm="$PLAN_DIR/plan.md" tier wmax env_max="${PLAN_WAVE_MAX:-}" f nodes="" plan_problem=""
  [ -f "$WORKSPACE_ROOT/context-budget.env" ] && . "$WORKSPACE_ROOT/context-budget.env" >/dev/null 2>&1
  wmax="${env_max:-${PLAN_WAVE_MAX:-6}}"
  if fm_block "$pm" >/dev/null; then
    tier="$(fm_get "$pm" default_tier)"; [ -n "$tier" ] || tier=standard
    f="$(fm_get "$pm" wave_max)"
    if [ -n "$f" ]; then
      if printf '%s' "$f" | grep -qE '^[0-9]+$'; then wmax="$f"; else plan_problem="wave_max is not an integer"; fi
    fi
    [ -n "$plan_problem" ] || plan_problem="$(plan_tiers_check "$PLAN_DIR")"
  else tier=standard; plan_problem="malformed frontmatter"; fi
  for f in "$PLAN_DIR"/nodes/*.md; do [ -f "$f" ] && nodes="$nodes$(node_parse "$f" "$tier")"; done
  nodes="$(printf '%s' "$nodes" | jq -s --argjson max "$wmax" --arg pm "$pm" --arg pmp "$plan_problem" '
    def v($rule; $node; $msg): {rule: $rule, id: ($node.id // null), wave: ($node.wave // null), path: ($node.path // null), message: $msg};
    def w($rule; $wave; $msg): {rule: $rule, id: null, wave: $wave, path: null, message: $msg};
    map(select(.problem == null)) as $nodes | map(.id) as $ids
    | (if $pmp == "" then [] else [v("malformed"; {path: $pm}; $pmp)] end)
    + map(select(.problem != null) | v("malformed"; .; .problem))
    + [$nodes | '"$DANGLING_JQ"']
    + ($nodes | group_by(.wave) | map(.[0].wave as $wave | map(select(.kind == "reconcile")) as $r
        | (if ($r | length) != 1 then [w("reconcile-count"; $wave; "\($r | length) reconcile nodes (want exactly one)")]
           else (map(select(.id > $r[0].id)) | map(.id)) as $after
             | if $after == [] then [] else [v("reconcile-last"; $r[0]; "reconcile node is not last in wave \($wave) (\($after | join(", ")) follow)")] end end)
        + (if length > $max then [w("wave-size"; $wave; "\(length) nodes, limit \($max)")] else [] end)) | add // [])
    + ($nodes | map(select(.kind == "hitl" and .check != null) | v("hitl-check"; .; "hitl node has a check")))
    + ($nodes | map(select(.check != null and (.check | test("^[^ /$\"'"'"'~=-][^ =]*/")))
        | (.check | capture("^(?<p>[^ ]+)").p) as $p
        | v("relative-check"; .; "check starts with relative path \($p); checks run from the work item dir — use \"$WORKSPACE_ROOT/\($p | ltrimstr("./"))\"")))
    + ($nodes | map(select(.status == "doing" and .sessions == []) | v("doing-sessions"; .; "doing with no session listed")))')"
  if [ "$JSON" -eq 1 ]; then printf '%s\n' "$nodes"; else printf '%s' "$nodes" | jq -r '.[] | "\(.path // "wave \(.wave)"): \(.message)"'; fi
  [ "$(printf '%s' "$nodes" | jq 'length')" -eq 0 ] || exit 1
}

cmd_start() {
  [ -n "$ARG" ] || usage
  need_seq; node_file "$ARG"
  local status forced=""
  status="$(node_field .status)"
  case "$status" in
    todo)
      if ! printf '%s' "$NODES_JSON" | jq -e --arg id "$ARG" "$DERIVE_JQ"' frontier | any(.id == $id)' >/dev/null; then
        [ "$FORCE" -eq 1 ] || die 1 "$ARG is not on the frontier (blockers unfinished or a later wave); --force to start it anyway"
        forced=" (forced: not on the frontier)"
      fi ;;
    blocked) ;;
    *) die 1 "$ARG is $status; start needs todo or blocked" ;;
  esac
  local tier; tier="$(node_field .tier_resolved)"; resolve_runtime
  if [ "$(node_field '.model // empty')" != "" ]; then tier=", tier $tier"
  elif [ -n "$RUNTIME" ]; then tier=", tier $tier unavailable on $RUNTIME (session model)"
  else tier=", tier $tier unavailable (no runtime; session model)"; fi
  fm_set "$NODE_FILE" status doing; stamp_session
  log_append "$NODE_FILE" "$WHO · started$forced$tier"
  report "$ARG" doing
}

cmd_done() {
  [ -n "$ARG" ] || usage
  need_who; node_file "$ARG"
  local status forced="" line rc attempt loop
  status="$(node_field .status)"
  [ "$(node_field .kind)" != hitl ] || [ -n "$BY" ] || die 1 "$ARG is a hitl node: a person ticks it — done $ARG --by human"
  case "$status" in
    doing) ;;
    todo)  [ "$FORCE" -eq 1 ] || die 1 "$ARG is todo; start it first (--force to mark it done anyway)"; forced=" (forced from todo)" ;;
    *)     die 1 "$ARG is $status; done needs doing" ;;
  esac
  if [ "$(node_field '.check // empty')" = "" ]; then line="done$forced"
  else
    run_check_quiet; rc=$?
    if [ "$rc" -ne 0 ]; then
      loop="$(node_field .loop)"; attempt=$(( $(failed_attempts) + 1 ))
      line="$WHO · check failed (exit $rc), attempt $attempt of $loop"
      if [ "$attempt" -ge "$loop" ]; then fm_set "$NODE_FILE" status blocked; line="$line → blocked"; fi
      log_append "$NODE_FILE" "$line"
      die 1 "$ARG ${line#"$WHO · "}"
    fi
    line="check passed → done$forced"
  fi
  fm_set "$NODE_FILE" status done; stamp_session
  log_append "$NODE_FILE" "$WHO · $line"
  report "$ARG" done
}

cmd_verify() {
  [ -n "$ARG" ] || usage
  node_file "$ARG"
  local result rc=0
  if [ "$(node_field '.check // empty')" = "" ]; then result="no check"
  else run_check; rc=$?; if [ "$rc" -eq 0 ]; then result="check passed"; else result="check failed (exit $rc)"; fi; fi
  if [ "$JSON" -eq 1 ]; then jq -n --arg id "$ARG" --arg result "$result" --argjson exit "$rc" '{id: $id, result: $result, exit: $exit}'
  else echo "$ARG: $result"; fi
  [ "$rc" -eq 0 ]
}

cmd_block() {
  [ -n "$ARG" ] && [ -n "$ARG2" ] || usage
  need_who; node_file "$ARG"
  [ "$(node_field .status)" = doing ] || die 1 "$ARG is $(node_field .status); block needs doing"
  fm_set "$NODE_FILE" status blocked
  log_append "$NODE_FILE" "$WHO · blocked: $ARG2"
  report "$ARG" blocked
}

cmd_drop() {
  [ -n "$ARG" ] || usage
  need_who; node_file "$ARG"
  [ "$(node_field .status)" != dropped ] || die 1 "$ARG is already dropped"
  fm_set "$NODE_FILE" status dropped
  log_append "$NODE_FILE" "$WHO · dropped${ARG2:+: $ARG2}"
  report "$ARG" dropped
}

cmd_add() {
  [ -n "$ARG" ] && [ -n "$WAVE" ] || usage
  printf '%s' "$ARG" | grep -qE '^[a-z0-9][a-z0-9-]*$' || die 2 "slug '$ARG' must be lowercase [a-z0-9-]"
  local k v nodes n f id ids b
  for k in WAVE PARALLEL LOOP; do eval "v=\$$k"; [ -z "$v" ] || printf '%s' "$v" | grep -qE '^[0-9]+$' || die 2 "--$(printf '%s' "$k" | tr A-Z a-z) '$v' is not an integer"; done
  case "$KIND" in ""|work|reconcile|hitl) ;; *) die 2 "unknown kind $KIND (work|reconcile|hitl)" ;; esac
  case "$TIER" in ""|frontier|standard|cheap|auto) ;; *) die 2 "unknown tier $TIER (frontier|standard|cheap|auto)" ;; esac
  [ -z "$LEAF" ] || printf '%s' "$LEAF" | grep -qE '^[a-z][a-z0-9_]*$' || die 2 "--leaf '$LEAF' is not [a-z][a-z0-9_]*"
  [ -z "$LEAF" ] || [ -n "$TIER" ] || TIER=auto   # a leaf label only matters under auto
  nodes="$(load_nodes "$PLAN_DIR")" || exit 1
  ids="$(printf '%s' "$nodes" | jq -r '.[].id')"
  for f in "$PLAN_DIR"/nodes/*-"$ARG".md; do [ -f "$f" ] && die 1 "slug $ARG is taken by $(basename "$f")"; done
  b="$(printf '%s' "$BLOCKED_BY" | tr ',' '\n' | sed 's/^ *//;s/ *$//' | grep . || true)"
  for v in $b; do printf '%s\n' "$ids" | grep -qx "$v" || die 1 "--blocked-by names no node $v"; done
  n=0; for f in "$PLAN_DIR"/nodes/[0-9]*.md; do [ -f "$f" ] || continue; f="$(basename "$f")"; f="${f%%-*}"; [ "$f" -gt "$n" ] 2>/dev/null && n="$f"; done
  id="$(printf '%02d-%s' $((10#$n + 1)) "$ARG")"
  {
    echo "---"; echo "id: $id"; echo "title: $TITLE"; echo "status: todo"; echo "kind: ${KIND:-work}"; echo "wave: $WAVE"
    echo "blocked_by: [$(printf '%s' "$b" | tr '\n' ',' | sed 's/,$//; s/,/, /g')]"
    [ -z "$TIER" ] || echo "tier: $TIER"
    [ -z "$LEAF" ] || echo "leaf: $LEAF"
    [ -z "$PARALLEL" ] || echo "parallel: $PARALLEL"
    [ -z "$LOOP" ] || echo "loop: $LOOP"
    [ -z "$CHECK" ] || echo "check: $CHECK"
    echo "sessions: []"
    [ -z "$ISOLATED" ] || echo "isolated: yes"
    echo "---"; echo; echo "## Goal"; echo; echo "## Acceptance"; echo; echo "## Log"
  } > "$PLAN_DIR/nodes/$id.md"
  report "$id" todo
}

cmd_note() {
  [ -n "$ARG" ] || usage
  section_append "$PLAN_DIR/plan.md" "## Not yet specified" "${WHO:+$WHO · }$ARG" \
    || die 1 "$PLAN_DIR/plan.md has no '## Not yet specified' section"
}

# ---- generated blocks ------------------------------------------------------------
# sync renders only between `<!-- plan:begin <name> -->` and `<!-- plan:end <name> -->`
# (convention: docs/work-directory-conventions.md); a missing marker is reported, never added.
marker_check() {  # <file> <name>: exit 1 naming the file and the marker it lacks
  local b="<!-- plan:begin $2 -->" e="<!-- plan:end $2 -->"
  [ -f "$1" ] || die 1 "$1: no such file — the $2 block goes between $b and $e in it"
  grep -qxF "$b" "$1" || die 1 "$1: no $b marker — add it, with $e, where the $2 block goes"
  grep -qxF "$e" "$1" || die 1 "$1: no $e marker — add it after $b"
}
marker_splice() {  # <file> <name> <content>: replace what lies between the markers; every other line verbatim
  local tmp="$1.tmp.$$"
  BLOCK="$3" awk -v b="<!-- plan:begin $2 -->" -v e="<!-- plan:end $2 -->" '
    $0 == e && skip { print ENVIRON["BLOCK"]; skip = 0 }
    !skip { print }
    $0 == b { skip = 1 }' "$1" > "$tmp" && mv "$tmp" "$1"
}
cmd_sync() {
  local pm="$PLAN_DIR/plan.md" launch="$ITEM/next-session.md" pstatus nodes out
  marker_check "$pm" board; marker_check "$launch" position
  pstatus="$(plan_status "$PLAN_DIR")"
  nodes="$(load_nodes "$PLAN_DIR")" || exit 1
  out="$(printf '%s' "$nodes" | jq --arg plan "$PLAN" --arg status "$pstatus" "$DERIVE_JQ"'
    def n($s): map(select(.status == $s)) | length;
    def unfinished: map(select(.status != "done" and .status != "dropped"));
    . as $all | current_wave as $cur | frontier as $front | (unfinished | length) as $rem
    | (if ($front | length) > 0 then ($front | map(.id) | join(", "))
       else "none" + ($all | unfinished | map(select(.wave == $cur and .status != "todo") | "\(.id) \(.status)")
                      | if length > 0 then " (\(join(", ")))" else "" end) end) as $ft
    | { board: ("| Wave | Node | Kind | Tier | Status |\n|---|---|---|---|---|"
          + (sort_by(.wave, .id) | map("\n| \(.wave) | \(.id) | \(.kind) | \(.tier) | \(.status) |") | join(""))
          + "\nFrontier: \($ft). Remaining: \($rem) of \(length). Sessions used: \([.[].sessions[]] | unique | length)."),
        position: ("Position: plan \($plan), \($status), wave \($cur // (([.[].wave] | max) // 0)) of \(([.[].wave] | max) // 0), "
          + "done \(n("done"))/\(length), doing \(n("doing")), todo \(n("todo")), blocked \(n("blocked")), dropped \(n("dropped")), "
          + "sessions \([.[].sessions[]] | unique | length).\nFrontier: \($ft). Remaining: \($rem) of \(length)"
          + (if $rem > 0 then " — wave \($cur): " + (unfinished | map(select(.wave == $cur)) | sort_by(.id) | map("\(.id) \(.status)") | join(", ")) else "" end) + ".") }')"
  marker_splice "$pm" board "$(printf '%s' "$out" | jq -r '.board')"
  marker_splice "$launch" position "$(printf '%s' "$out" | jq -r '.position')"
  pm="${pm#"$WORKSPACE_ROOT/"}"; launch="${launch#"$WORKSPACE_ROOT/"}"
  if [ "$JSON" -eq 1 ]; then jq -n --arg plan "$PLAN" --arg a "$pm" --arg b "$launch" '{plan: $plan, files: [$a, $b]}'
  else echo "synced $pm, $launch"; fi
}

case "$VERB" in
  new)       cmd_new ;;
  status)    resolve_plan; cmd_status ;;
  show)      resolve_plan; cmd_show ;;
  frontier)  resolve_plan; cmd_frontier ;;
  remaining) resolve_plan; cmd_remaining ;;
  graph)     resolve_plan; cmd_graph ;;
  check)     resolve_plan; cmd_check ;;
  start)     resolve_plan write; cmd_start ;;
  done)      resolve_plan write; cmd_done ;;
  verify)    resolve_plan; cmd_verify ;;
  block)     resolve_plan write; cmd_block ;;
  drop)      resolve_plan write; cmd_drop ;;
  add)       resolve_plan write; cmd_add ;;
  note)      resolve_plan write; cmd_note ;;
  sync)      resolve_plan; cmd_sync ;;
esac
