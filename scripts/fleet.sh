#!/usr/bin/env bash
# File: scripts/fleet.sh
# Purpose: The sub-agent fleet verbs, moved out of the measurer (Stage 4
#          phase 2, pure move): sweep a parent's child transcripts, and keep
#          the per-task dispatch records + the rollover contract a parent
#          hands a long-running child. Session identity and measurement stay
#          in scripts/context-budget.sh; `children` asks it for the caller's
#          own session instead of re-implementing discovery here.
# Usage:   fleet.sh children|dispatch-contract|dispatch-open|dispatch-close|dispatch-list
#            [--runtime claude|codex|copilot-vscode|copilot-cli|gemini|opencode|auto]
#            [--transcript <path>] [--project <work-item>] [--parent-session <sid>]
#            [--agent-id <id>] [--all] [--report <path>] [--brief <path>]
#            [--gen <n>] [--task <slug>] [--agent-type <t>] [--model <m>]
#            [--effort <e>] [--status <S>] [--quiet]
# Exit:    children: 0 OK / 1 WARN / 2 STOP (worst child) / 3 error.
#          dispatch-list: 0 all closed / 1 a generation is open / 3 error.
#          dispatch-contract, dispatch-open, dispatch-close: 0 / 3 error.
#          Requires jq.
# Docs:    docs/context-budget.md -> "Per-child sweep (children)" and
#          "Dispatching long-running children".

set -u

# Workspace identity = repository identity, not checkout path (issue 05):
# resolve through git's common dir so every worktree converges on the main
# checkout's coordination state. Same rule as context-budget.sh; the marker
# is this script.
resolve_workspace_root() {  # $1 = script-relative candidate root
  local root common repo
  root="$(cd "$1" && pwd -P)"
  if common="$(git -C "$root" rev-parse --git-common-dir 2>/dev/null)"; then
    case "$common" in /*) : ;; *) common="$root/$common" ;; esac
    repo="$(cd "$common/.." 2>/dev/null && pwd -P)"
    if [ -n "$repo" ] && [ -f "$repo/scripts/fleet.sh" ]; then
      printf '%s' "$repo"; return
    fi
  fi
  printf '%s' "$root"
}
WORKSPACE_ROOT="$(resolve_workspace_root "$(dirname "$0")/..")"
STATE_DIR="$WORKSPACE_ROOT/.context-budget"
MEASURER="$WORKSPACE_ROOT/scripts/context-budget.sh"

# Thresholds: explicit env > context-budget.env > built-in default, the
# measurer's precedence, so a child is graded on the same scale as its parent.
EXPLICIT_TOTAL="${CONTEXT_DUMB_ZONE_TOKENS:-}"
EXPLICIT_WARN="${CONTEXT_DUMB_ZONE_WARN_TOKENS:-}"
if [ -f "$WORKSPACE_ROOT/context-budget.env" ]; then
  . "$WORKSPACE_ROOT/context-budget.env" >/dev/null 2>&1 || true
fi
[ -n "$EXPLICIT_TOTAL" ] && CONTEXT_DUMB_ZONE_TOKENS="$EXPLICIT_TOTAL"
[ -n "$EXPLICIT_WARN" ] && CONTEXT_DUMB_ZONE_WARN_TOKENS="$EXPLICIT_WARN"
THRESHOLD="${CONTEXT_DUMB_ZONE_TOKENS:-150000}"
WARN="${CONTEXT_DUMB_ZONE_WARN_TOKENS:-$(( THRESHOLD * 80 / 100 ))}"

COMMAND=""; RUNTIME="auto"; ARTIFACT=""; PROJECT=""; QUIET=0
PARENT_SESSION=""; AGENT_ID=""; ALL=0
REPORT_FILE=""; BRIEF_FILE=""; GEN=1; GEN_SET=0
TASK=""; AGENT_TYPE=""; MODEL=""; EFFORT=""; CLOSE_STATUS=""
case "${1:-}" in children|dispatch-contract|dispatch-open|dispatch-close|dispatch-list) COMMAND="$1"; shift ;; esac
while [ $# -gt 0 ]; do
  case "$1" in
    --runtime) RUNTIME="$2"; shift 2 ;;
    --transcript) ARTIFACT="$2"; shift 2 ;;
    --project) PROJECT="$2"; shift 2 ;;
    --parent-session) PARENT_SESSION="$2"; shift 2 ;;
    --agent-id) AGENT_ID="$2"; shift 2 ;;
    --all) ALL=1; shift ;;
    --report) REPORT_FILE="$2"; shift 2 ;;
    --brief) BRIEF_FILE="$2"; shift 2 ;;
    --gen) GEN="$2"; GEN_SET=1; shift 2 ;;
    --task) TASK="$2"; shift 2 ;;
    --agent-type) AGENT_TYPE="$2"; shift 2 ;;
    --model) MODEL="$2"; shift 2 ;;
    --effort) EFFORT="$2"; shift 2 ;;
    --status) CLOSE_STATUS="$2"; shift 2 ;;
    --quiet) QUIET=1; shift ;;
    *) echo "unknown option: $1" >&2; exit 3 ;;
  esac
done

note() { [ "$QUIET" -eq 1 ] || echo "$@" >&2; }
die()  { echo "error: $*" >&2; exit 3; }

[ -n "$COMMAND" ] \
  || die "usage: fleet.sh children|dispatch-contract|dispatch-open|dispatch-close|dispatch-list [options]"

estimate_from_size() {
  local bytes
  bytes=$(stat -f%z "$1" 2>/dev/null || stat -c%s "$1" 2>/dev/null) || return 1
  echo "$(( bytes / 4 )) estimate"
}

parent_record_path() {
  # $1 = parent session id -> its registry record path (any runtime; mixed
  # fleets register children under a parent from another runtime).
  local f
  for f in "$STATE_DIR/sessions/"*.json; do
    [ -f "$f" ] || continue
    [ "$(jq -r '.session_id // empty' "$f" 2>/dev/null)" = "$1" ] && { echo "$f"; return 0; }
  done
  return 1
}

resolve_own_session() {
  # The measurer owns session identity (runtime detection, the registry, the
  # M16 re-pin). Ask it rather than carry a copy of that code here: `check`
  # prints one `runtime= ... artifact=` line and exits 0/1/2 on the caller's
  # own budget (irrelevant here) or 3 when no session resolves, with its
  # error already on stderr.
  local line rc=0
  set --
  [ "$RUNTIME" = "auto" ] || set -- "$@" --runtime "$RUNTIME"
  [ -z "$ARTIFACT" ] || set -- "$@" --transcript "$ARTIFACT"
  [ "$QUIET" -eq 0 ] || set -- "$@" --quiet
  line=$("$MEASURER" check "$@") || rc=$?
  { [ "$rc" -ne 3 ] && [ -n "$line" ]; } || exit 3
  RUNTIME="${line#runtime=}"; RUNTIME="${RUNTIME%% *}"
  ARTIFACT="${line##* artifact=}"
}

claude_child_measure() {
  # Sidechain-INCLUSIVE variant of claude_measure: a subagent transcript's
  # entries are all isSidechain:true, so the self-measure filter would
  # silently degrade every child to size-estimate.
  local f="$1" jq_prog tokens
  jq_prog='[.[] | select(.message.usage.input_tokens != null)]
    | last | if . == null then empty else
      (.message.usage.input_tokens + (.message.usage.cache_read_input_tokens // 0)
       + (.message.usage.cache_creation_input_tokens // 0)) end'
  tokens=$(tail -n 2000 "$f" | jq -s -r "$jq_prog" 2>/dev/null)
  [ -z "$tokens" ] && tokens=$(jq -s -r "$jq_prog" "$f" 2>/dev/null)
  [ -n "$tokens" ] && echo "$tokens exact" || estimate_from_size "$f"
}

cmd_children() {
  # R1 sweep (research §10): no runtime reports per-child usage to the parent;
  # measure the child transcript artifacts directly. Escalation-only output —
  # WARN/STOP children print, OK children don't (unless --all). Exit code is
  # the worst child status, check-style. Direct children only (R8).
  if [ "$RUNTIME" != "auto" ] && [ "$RUNTIME" != "claude" ]; then
    die "children: only implemented for runtime=claude (got $RUNTIME)"
  fi
  if [ -n "$PARENT_SESSION" ]; then
    local prec
    prec=$(parent_record_path "$PARENT_SESSION") \
      || die "children: parent session $PARENT_SESSION is not registered"
    RUNTIME=$(jq -r '.runtime // empty' "$prec")
    ARTIFACT=$(jq -r '.artifact // empty' "$prec")
    [ -n "$ARTIFACT" ] && [ -f "$ARTIFACT" ] \
      || die "children: no artifact on record for parent $PARENT_SESSION"
  else
    resolve_own_session
  fi
  [ "$RUNTIME" = "claude" ] || die "children: only implemented for runtime=claude (got $RUNTIME)"
  local subdir="${ARTIFACT%.jsonl}/subagents"
  local worst=0 measured=0 escalated=0
  local f b tokens method status pct mt age atype
  if [ -d "$subdir" ]; then
    for f in "$subdir"/agent-*.jsonl; do
      [ -f "$f" ] || continue
      read -r tokens method < <(claude_child_measure "$f") || continue
      [ -n "$tokens" ] || continue
      measured=$((measured+1))
      if [ "$tokens" -ge "$THRESHOLD" ]; then status="STOP"; worst=2
      elif [ "$tokens" -ge "$WARN" ]; then status="WARN"; [ "$worst" -lt 1 ] && worst=1
      else status="OK"; fi
      [ "$status" = "OK" ] || escalated=$((escalated+1))
      if [ "$status" != "OK" ] || [ "$ALL" -eq 1 ]; then
        pct=$(( tokens * 100 / THRESHOLD ))
        mt=$(stat -f%m "$f" 2>/dev/null || stat -c%Y "$f" 2>/dev/null) || mt=$(date +%s)
        age=$(( $(date +%s) - mt ))
        atype=$(jq -r '.agentType // empty' "${f%.jsonl}.meta.json" 2>/dev/null)
        [ -n "$atype" ] || atype="?"
        b="${f##*/}"; b="${b%.jsonl}"
        echo "agent=$b tokens=$tokens threshold=$THRESHOLD warn=$WARN pct=$pct status=$status age=$age type=$atype artifact=$f"
      fi
    done
  fi
  note "children: $measured measured, $escalated escalated"
  return "$worst"
}


# R2 dispatch contract (subagent-rollover research §8/§10): the block a parent
# injects into a long-running child's dispatch prompt. Stateless, ASCII-only
# (dispatch prompts traverse %q and BSD sed in launch paths), runtime-agnostic
# — the portable-core tier, load-bearing on disk protocol not hooks.
cmd_dispatch_contract() {
  [ -n "$REPORT_FILE" ] || die "dispatch-contract requires --report <path>"
  case "$GEN" in ''|*[!0-9]*|0) die "--gen must be a positive integer" ;; esac
  echo "=== Dispatch contract (context-budget R2/R3) ==="
  echo "You are generation $GEN on this task."
  [ -n "$BRIEF_FILE" ] && echo "Brief: $BRIEF_FILE"
  echo "Report file: $REPORT_FILE"
  if [ "$GEN" -ge 2 ]; then
    cat <<'EOF'
- Read the report file before starting: earlier generations' progress and
  open items are recorded there. Finish the open items first.
EOF
  fi
  echo "- At every work-unit boundary, append a progress block to the report file"
  echo "  (what finished, what is next, open items), labeled [gen $GEN]. This"
  echo "  doubles as your heartbeat."
  cat <<'EOF'
- Keep your final return message to at most 15 lines; detail belongs in the
  report file, not the return.
- The first line of your return must be one of:
  DONE | DONE_WITH_CONCERNS | BLOCKED | NEEDS_CONTEXT | ROLLOVER_NEEDED
- ROLLOVER_NEEDED means: context spent, task incomplete, report current as
  of your last checkpoint, open items listed there. Emit it only when asked
  to checkpoint or when a WARN/STOP line is pushed into your session -
  never from self-assessment of your own context usage.
- If asked to checkpoint: flush state to the report file, then return your
  status and open items. Do not push on.
EOF
}

# R4 dispatch records (subagent-rollover research §5/§8): the parent persists
# each child dispatch spec so a successor parent can reconstruct the
# orchestration and re-dispatch unfinished subtrees fresh — resume is keyed to
# the (dead) predecessor's session id. Generation fencing lives in
# dispatch-open: gen N+1 exists only after gen N was closed (clean yield or a
# parent KILLED ruling), so each report file has at most one live writer.
# Records are workspace-root-anchored runtime state (ADR-0006), one JSON per
# task under work/<proj>/.agent-dispatch/, same class as .agent-locks/.
dispatch_record_path() {
  local dir="$WORKSPACE_ROOT/work/$PROJECT"
  [ -n "$PROJECT" ] || die "$COMMAND requires --project <work-item>"
  [ -d "$dir" ] || die "no such work directory: work/$PROJECT"
  echo "$dir/.agent-dispatch/$TASK.json"
}

cmd_dispatch_open() {
  [ -n "$TASK" ] || die "dispatch-open requires --task <slug>"
  [ -n "$REPORT_FILE" ] || die "dispatch-open requires --report <path>"
  [ "$GEN_SET" -eq 0 ] || die "dispatch-open: --gen is computed from the record, never passed"
  local rec gen
  rec=$(dispatch_record_path) || exit 3
  mkdir -p "${rec%/*}"
  if [ -f "$rec" ]; then
    gen=$(jq -r '.generations | length' "$rec")
    [ "$(jq -r '.generations[-1].status // empty' "$rec")" != "open" ] \
      || die "dispatch-open: generation $gen of $TASK is still open — dispatch-close it first (yield or KILLED ruling)"
    gen=$((gen + 1))
  else
    gen=1
    jq -n --arg t "$TASK" --arg proj "$PROJECT" \
      '{task:$t, project:$proj, generations:[]}' > "$rec"
  fi
  jq --arg ts "$(date -u +%FT%TZ)" --arg rp "$REPORT_FILE" --arg bf "$BRIEF_FILE" \
     --arg at "$AGENT_TYPE" --arg md "$MODEL" --arg ef "$EFFORT" \
     --arg aid "$AGENT_ID" --argjson gen "$gen" --arg user "$USER@$(hostname -s)" \
    '.report = $rp
     | (if $bf == "" then . else .brief = $bf end)
     | (if $at == "" then . else .agent_type = $at end)
     | (if $md == "" then . else .model = $md end)
     | (if $ef == "" then . else .effort = $ef end)
     | .generations += [{gen:$gen, dispatched_at:$ts, status:"open", user:$user}
                        + (if $aid == "" then {} else {agent_id:$aid} end)]' \
    "$rec" > "$rec.tmp" && mv "$rec.tmp" "$rec"
  GEN="$gen"
  cmd_dispatch_contract
  note "dispatch: opened generation $gen of $TASK (work/$PROJECT/.agent-dispatch/$TASK.json)"
}

cmd_dispatch_close() {
  [ -n "$TASK" ] || die "dispatch-close requires --task <slug>"
  case "$CLOSE_STATUS" in
    DONE|DONE_WITH_CONCERNS|BLOCKED|NEEDS_CONTEXT|ROLLOVER_NEEDED|KILLED) : ;;
    "") die "dispatch-close requires --status <S>" ;;
    *) die "dispatch-close: invalid --status $CLOSE_STATUS (DONE|DONE_WITH_CONCERNS|BLOCKED|NEEDS_CONTEXT|ROLLOVER_NEEDED|KILLED)" ;;
  esac
  local rec
  rec=$(dispatch_record_path) || exit 3
  [ -f "$rec" ] || die "dispatch-close: no dispatch record for task $TASK"
  [ "$(jq -r '.generations[-1].status // empty' "$rec")" = "open" ] \
    || die "dispatch-close: no open generation for $TASK"
  jq --arg ts "$(date -u +%FT%TZ)" --arg st "$CLOSE_STATUS" --arg aid "$AGENT_ID" \
    '.generations[-1] |= (.status = $st | .closed_at = $ts
                          | (if $aid == "" then . else .agent_id = $aid end))' \
    "$rec" > "$rec.tmp" && mv "$rec.tmp" "$rec"
  note "dispatch: closed generation $(jq -r '.generations | length' "$rec") of $TASK status=$CLOSE_STATUS"
}

cmd_dispatch_list() {
  # One line per task record; exit 1 iff any generation is still open — the
  # drain-check a rolling parent consults before its own rollover.
  local dir="$WORKSPACE_ROOT/work/$PROJECT" f any_open=0
  [ -n "$PROJECT" ] || die "dispatch-list requires --project <work-item>"
  [ -d "$dir" ] || die "no such work directory: work/$PROJECT"
  for f in "$dir/.agent-dispatch/"*.json; do
    [ -f "$f" ] || continue
    jq -r '"task=\(.task) gen=\(.generations | length) status=\(.generations[-1].status // "none") report=\(.report // "?")"
           + (if .brief then " brief=\(.brief)" else "" end)' "$f"
    [ "$(jq -r '.generations[-1].status // empty' "$f")" = "open" ] && any_open=1
  done
  return "$any_open"
}

command -v jq >/dev/null 2>&1 || die "jq is required"

case "$COMMAND" in
  children) cmd_children ;;
  dispatch-contract) cmd_dispatch_contract ;;
  dispatch-open) cmd_dispatch_open ;;
  dispatch-close) cmd_dispatch_close ;;
  dispatch-list) cmd_dispatch_list ;;
esac
