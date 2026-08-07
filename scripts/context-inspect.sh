#!/usr/bin/env bash
# File: scripts/context-inspect.sh
# Purpose: Break down what is actually in a Claude Code session's context
#          window, from the session transcript: exact per-turn totals from
#          message.usage, plus the harness attachment records (skill listing,
#          MCP instructions, agent/deferred-tool listings, hook context) split
#          into "materialized with turn 1" vs "arrived later". CLAUDE.md and
#          auto-memory are harness-injected and never recorded in the
#          transcript, so those are measured from disk. The unexplained
#          remainder is the harness-fixed floor (system prompt, tool schemas).
#          Context: /context under-reports ~10K before the first real message
#          (docs/operational-knowledge.md); usage numbers are exact.
# Usage:   context-inspect.sh [--phases] [transcript.jsonl]
#          No argument: $CLAUDE_CODE_SESSION_ID's transcript for this
#          workspace, else the newest one in the project slug dir.
#          --phases adds a per-turn diff table: exact delta per assistant
#          turn vs the attributed estimate of what arrived between turns
#          (attachments, user/tool messages, prior assistant output); the
#          residual flags content the transcript doesn't attribute (or
#          transcribed records that never enter model context). Snapshot
#          frame: S1 = pre-turn-1 disk/attachment estimate (a prediction —
#          no API call exists yet), S2 = turn-1 exact, S3 = last-turn exact.
# Notes:   figures marked "est" are chars/4 estimates; "exact" comes from the
#          API usage envelope. Requires jq. Needs >=1 assistant turn.

set -u

resolve_workspace_root() {  # same convention as attach-session.sh
  local root common repo
  root="$(cd "$1" && pwd -P)"
  if common="$(git -C "$root" rev-parse --git-common-dir 2>/dev/null)"; then
    case "$common" in /*) : ;; *) common="$root/$common" ;; esac
    repo="$(cd "$common/.." 2>/dev/null && pwd -P)"
    if [ -n "$repo" ] && [ -f "$repo/scripts/context-inspect.sh" ]; then
      printf '%s' "$repo"; return
    fi
  fi
  printf '%s' "$root"
}
WORKSPACE_ROOT="$(resolve_workspace_root "$(dirname "$0")/..")"

die() { echo "error: $*" >&2; exit 1; }
command -v jq >/dev/null 2>&1 || die "jq is required"

# --- resolve transcript ------------------------------------------------------
PHASES=0
if [ "${1:-}" = "--phases" ]; then PHASES=1; shift; fi
F="${1:-}"
# Transcript slug follows the session's CWD, not the repo root — a worktree
# session's transcript lives under the worktree-path slug. Try cwd first.
if [ -z "$F" ]; then
  for base in "$PWD" "$WORKSPACE_ROOT"; do
    SLUG="$(printf '%s' "$base" | tr '/.' '--')"
    PROJ_DIR="$HOME/.claude/projects/$SLUG"
    if [ -n "${CLAUDE_CODE_SESSION_ID:-}" ] && [ -f "$PROJ_DIR/$CLAUDE_CODE_SESSION_ID.jsonl" ]; then
      F="$PROJ_DIR/$CLAUDE_CODE_SESSION_ID.jsonl"; break
    fi
  done
fi
if [ -z "$F" ]; then
  SLUG="$(printf '%s' "$PWD" | tr '/.' '--')"
  F="$(ls -t "$HOME/.claude/projects/$SLUG"/*.jsonl \
             "$HOME/.claude/projects/$(printf '%s' "$WORKSPACE_ROOT" | tr '/.' '--')"/*.jsonl \
       2>/dev/null | head -1)"
fi
[ -n "$F" ] && [ -f "$F" ] || die "no transcript found (pass one explicitly)"

# --- exact totals from usage -------------------------------------------------
# Context size at a turn = input + cache_read + cache_creation of its usage.
totals="$(jq -r 'select(.type=="assistant") | .message.usage
  | (.input_tokens + .cache_read_input_tokens + .cache_creation_input_tokens)' "$F" 2>/dev/null)"
[ -n "$totals" ] || die "no assistant turn in $F yet — say something first"
FIRST_TOTAL="$(printf '%s\n' "$totals" | head -1)"
LAST_TOTAL="$(printf '%s\n' "$totals" | tail -1)"
TURNS="$(printf '%s\n' "$totals" | wc -l | tr -d ' ')"

echo "transcript: $F"
echo "assistant turns: $TURNS"
printf 'context at turn 1:   %8d tokens (exact)\n' "$FIRST_TOTAL"
printf 'context at last turn:%8d tokens (exact)\n' "$LAST_TOTAL"
echo

# --- per-turn phase table (--phases) -----------------------------------------
# A "turn" here = one API request (grouped by requestId; a turn with several
# content blocks spans several assistant jsonl lines sharing one usage
# envelope). Records between turn N-1's last line and turn N's first line are
# attributed to turn N; turn N's own output is attributed to turn N+1.
if [ "$PHASES" -eq 1 ]; then
  echo "per-turn phase table (est cols = chars/4; resid = exact delta - attributed):"
  echo "  S1 = the disk/attachment estimates below (pre-turn-1 prediction);"
  echo "  S2 = turn-1 exact; S3 = last-turn exact."
  jq -r '
    if .type=="assistant" then
      "A\t\(.requestId // "-")\t\(.message.usage
        | (.input_tokens + .cache_read_input_tokens + .cache_creation_input_tokens) // 0
        )\t\(.message.content|tojson|length)"
    elif .type=="attachment" then "att\t-\t0\t\(if .attachment.type=="hook_success" then ((.attachment.content // "")|length) else (.attachment|tojson|length) end)"
    elif .type=="user" then "msg\t-\t0\t\((.message.content // "")|tojson|length)"
    else empty end' "$F" | awk '
    BEGIN { FS="\t"; turn=1; prevreq="" }
    $1=="A" {
      if ($2=="-" || $2!=prevreq) { exact[turn]=$3; turn++ }
      asst[turn]+=$4; prevreq=$2; next
    }
    $1=="att" { att[turn]+=$4 }
    $1=="msg" { msg[turn]+=$4 }
    END {
      N=turn-1
      printf "  %4s %9s %8s %7s %7s %7s %7s\n", \
        "turn","exact","delta","att~","msg~","asst~","resid~"
      for (t=1; t<=N; t++) {
        a=int(att[t]/4); m=int(msg[t]/4); s=int(asst[t]/4)
        if (t==1)
          printf "  %4d %9d %8s %7d %7d %7d %7s  (resid = harness+CLAUDE.md floor)\n", \
            t, exact[t], "-", a, m, s, "-"
        else {
          d=exact[t]-exact[t-1]
          printf "  %4d %9d %8d %7d %7d %7d %7d\n", t, exact[t], d, a, m, s, d-a-m-s
        }
      }
    }'
  echo
fi

# --- attachment breakdown, turn-1 vs later -----------------------------------
# Stream "A" for assistant lines and "type chars" for attachments; awk phases
# them by whether the first assistant line has been seen yet.
echo "harness attachments recorded in the transcript (est tokens = chars/4):"
# hook_success records are attributed at .content length only: stdout/stderr/
# command are transcript-only and never enter model context (residual analysis
# 2026-08-07, work/context-decay — whole-JSON attribution went ~190 tok/turn
# negative on Warp-plugin sessions).
att_stream() {
  jq -r 'if .type=="assistant" then "A"
         elif .type=="attachment" then "\(.attachment.type) \(if .attachment.type=="hook_success" then ((.attachment.content // "")|length) else (.attachment|tojson|length) end)"
         else empty end' "$F"
}
# Rows carry tab-separated sort keys: phase (0=turn1, 1=later), then
# -tokens so bigger rows come first and the TOTAL row (key 1) lands last.
att_stream | awk '
  $1=="A" { seen=1; next }
  { phase = seen ? 1 : 0
    key = phase " " $1
    cnt[key]++; chars[key]+=$2; sum[phase]+=$2 }
  END {
    lab[0]="turn1"; lab[1]="later"
    for (k in cnt) { split(k,p," ")
      printf "%d\t%d\t  %-6s %-28s x%-4d %8d chars  ~%6d tok\n", \
        p[1], -int(chars[k]/4), lab[p[1]], p[2], cnt[k], chars[k], int(chars[k]/4) }
    for (ph = 0; ph <= 1; ph++)
      printf "%d\t%d\t  %-6s %-28s %14d chars  ~%6d tok\n", \
        ph, 1, lab[ph], "TOTAL", sum[ph], int(sum[ph]/4)
  }' | sort -t "$(printf '\t')" -k1,1n -k2,2n | cut -f3
ATT1_EST="$(att_stream | awk '$1=="A"{exit} {s+=$2} END{print int(s/4)}')"
echo

# --- disk-side stack (harness-injected, absent from the transcript) ----------
echo "CLAUDE.md / memory stack measured from disk (injected, not transcribed):"
DISK_CHARS=0
for f in "$HOME/.claude/CLAUDE.md" "$WORKSPACE_ROOT/CLAUDE.md" \
         "$HOME/.claude/projects/$(printf '%s' "$WORKSPACE_ROOT" | tr '/.' '--')/memory/MEMORY.md"; do
  [ -f "$f" ] || continue
  c="$(wc -c < "$f" | tr -d ' ')"   # follows the CONTEXT.md symlink
  DISK_CHARS=$((DISK_CHARS + c))
  printf '  %-62s %8d chars  ~%6d tok\n' "${f/#$HOME/~}" "$c" "$((c / 4))"
done
DISK_EST=$((DISK_CHARS / 4))
printf '  %-62s %8d chars  ~%6d tok\n' "TOTAL" "$DISK_CHARS" "$DISK_EST"
echo

# --- remainder ---------------------------------------------------------------
REMAINDER=$((FIRST_TOTAL - ATT1_EST - DISK_EST))
printf 'harness-fixed remainder at turn 1 (system prompt, tool schemas, env,\n'
printf 'plus est error): %d exact - %d att-est - %d disk-est = ~%d tokens\n' \
  "$FIRST_TOTAL" "$ATT1_EST" "$DISK_EST" "$REMAINDER"
