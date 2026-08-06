#!/usr/bin/env bash
# File: scripts/launch-next-session.sh
# Purpose: Relaunch step of session-rollover (ADR-0003/0004): launch a fresh
#          agent session seeded with the canonical bootstrap prompt for a work
#          item. The prompt wording is load-bearing and lives ONLY here.
#          Runtime resolution: --runtime flag > the dying session's own
#          registry record (D6) > newest record for the project >
#          ROLLOVER_RUNTIME > claude.
# Usage:   launch-next-session.sh <project>
#            [--runtime claude|codex|gemini|opencode|copilot] [--bg] [--dry-run]
# Knobs:   ROLLOVER_RELAUNCH=off|manual|auto, ROLLOVER_RUNTIME (fallback
#          only). Precedence: explicit env > work/<project>/context-budget.env
#          (committed per-item policy, optional) > global context-budget.env >
#          built-in default. ROLLOVER_CONFIRM_SECS (env only, default 120)
#          bounds the --bg successor-confirmation poll.
#          work/<project>/.rollover-options (optional, written at rollover):
#          ROLLOVER_OPT_APPROVAL=default|auto|full, ROLLOVER_OPT_MODEL=<id>,
#          ROLLOVER_OPT_EXTRA=<raw args> — replayed as per-runtime flags on
#          the successor launch.
# Exit:    0 ok / 3 error. Requires jq.
# Vendor flags verified against live --help 2026-08-05: claude [prompt] + --bg;
# codex [PROMPT]; gemini -i; opencode --prompt; copilot -i. Approval-mapping
# flags (OPT_ARGS below) re-verified against live --help 2026-08-06: claude
# --permission-mode acceptEdits/--dangerously-skip-permissions; codex
# --ask-for-approval never/--dangerously-bypass-approvals-and-sandbox (NOT
# --full-auto — that flag does not exist in codex-cli 0.142.4); gemini
# --approval-mode auto_edit/--yolo; opencode --auto (same flag for both
# levels); copilot --allow-all-tools/--allow-all. Re-verify before changing
# (ADR-0003: a nonexistent flag already slipped in once).

set -u

WORKSPACE_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
STATE_DIR="$WORKSPACE_ROOT/.context-budget"

note() { echo "$@" >&2; }
die()  { echo "error: $*" >&2; exit 3; }

PROJECT=""; RUNTIME=""; BG=0; DRY=0
while [ $# -gt 0 ]; do
  case "$1" in
    --runtime) RUNTIME="$2"; shift 2 ;;
    --bg) BG=1; shift ;;
    --dry-run) DRY=1; shift ;;
    -*) die "unknown option: $1" ;;
    *) [ -z "$PROJECT" ] && PROJECT="$1" || die "unexpected argument: $1"; shift ;;
  esac
done
[ -n "$PROJECT" ] || die "usage: launch-next-session.sh <project> [--runtime <rt>] [--bg] [--dry-run]"
[ -f "$WORKSPACE_ROOT/work/$PROJECT/next-session.md" ] \
  || die "work/$PROJECT/next-session.md not found — run session-rollover first"

# Relaunch knobs: explicit env > per-item work/$PROJECT/context-budget.env >
# global context-budget.env > built-in default. Sourced here (not at the top)
# because the per-item path needs $PROJECT from the args.
EXPLICIT_RELAUNCH="${ROLLOVER_RELAUNCH:-}"
EXPLICIT_RUNTIME="${ROLLOVER_RUNTIME:-}"
for envf in "$WORKSPACE_ROOT/context-budget.env" \
            "$WORKSPACE_ROOT/work/$PROJECT/context-budget.env"; do
  if [ -f "$envf" ]; then
    . "$envf" >/dev/null 2>&1 || true
  fi
done
[ -n "$EXPLICIT_RELAUNCH" ] && ROLLOVER_RELAUNCH="$EXPLICIT_RELAUNCH"
[ -n "$EXPLICIT_RUNTIME" ] && ROLLOVER_RUNTIME="$EXPLICIT_RUNTIME"
MODE="${ROLLOVER_RELAUNCH:-off}"
FALLBACK_RUNTIME="${ROLLOVER_RUNTIME:-claude}"
CONFIRM_SECS="${ROLLOVER_CONFIRM_SECS:-120}"

# The canonical bootstrap prompt (ADR-0003: wording is load-bearing, verbatim).
PROMPT="Read \`work/$PROJECT/next-session.md\` and continue from **First actions**."

own_record() {
  # D6 "read my own record": env-first identity, same order as
  # context-budget.sh session_id_for(). Falls back to the newest record
  # registered for this project (lock invariant: one active session per item).
  local rt sid b f
  for rt in claude codex copilot-cli copilot-vscode; do
    case "$rt" in
      claude)      sid="${CLAUDE_CODE_SESSION_ID:-}" ;;
      codex)       sid="${CODEX_THREAD_ID:-}" ;;
      copilot-cli) sid="${COPILOT_AGENT_SESSION_ID:-}" ;;
      copilot-vscode)
        sid=""; if [ -n "${VSCODE_TARGET_SESSION_LOG:-}" ]; then
          b="$(basename "$VSCODE_TARGET_SESSION_LOG")"; sid="${b%.jsonl}"
        fi ;;
    esac
    if [ -n "$sid" ] && [ -f "$STATE_DIR/sessions/$rt-$sid.json" ]; then
      echo "$STATE_DIR/sessions/$rt-$sid.json"; return 0
    fi
  done
  for f in $(ls -t "$STATE_DIR/sessions/"*.json 2>/dev/null); do
    if [ "$(jq -r '.project // empty' "$f" 2>/dev/null)" = "$PROJECT" ]; then
      echo "$f"; return 0
    fi
  done
  return 1
}

DYING_SID=""
REC="$(own_record)" || REC=""
if [ -n "$REC" ]; then
  DYING_SID="$(jq -r '.session_id // empty' "$REC" 2>/dev/null)"
  recproj="$(jq -r '.project // empty' "$REC" 2>/dev/null)"
  [ -n "$recproj" ] && [ "$recproj" != "$PROJECT" ] \
    && note "warning: your session record is for project '$recproj', launching for '$PROJECT'"
  [ -n "$RUNTIME" ] || RUNTIME="$(jq -r '.runtime // empty' "$REC" 2>/dev/null)"
fi
if [ -z "$RUNTIME" ]; then
  RUNTIME="$FALLBACK_RUNTIME"
  note "no session record found; falling back to ROLLOVER_RUNTIME=$RUNTIME"
fi

# Successor option inheritance: persist-and-replay from the work item
# (.rollover-options, written at rollover; see docs/context-budget.md).
OPT_ARGS=()
OPTF="$WORKSPACE_ROOT/work/$PROJECT/.rollover-options"
if [ -f "$OPTF" ]; then
  ROLLOVER_OPT_APPROVAL=""; ROLLOVER_OPT_MODEL=""; ROLLOVER_OPT_EXTRA=""
  . "$OPTF" >/dev/null 2>&1 || true
  case "${ROLLOVER_OPT_APPROVAL:-}" in
    ""|default) : ;;
    auto)
      case "$RUNTIME" in
        claude) OPT_ARGS+=(--permission-mode acceptEdits) ;;
        codex) OPT_ARGS+=(--ask-for-approval never) ;;
        gemini) OPT_ARGS+=(--approval-mode auto_edit) ;;
        opencode) OPT_ARGS+=(--auto) ;;
        copilot|copilot-cli) OPT_ARGS+=(--allow-all-tools) ;;
      esac ;;
    full)
      case "$RUNTIME" in
        claude) OPT_ARGS+=(--dangerously-skip-permissions) ;;
        codex) OPT_ARGS+=(--dangerously-bypass-approvals-and-sandbox) ;;
        gemini) OPT_ARGS+=(--yolo) ;;
        opencode) OPT_ARGS+=(--auto) ;;
        copilot|copilot-cli) OPT_ARGS+=(--allow-all) ;;
      esac ;;
    *) note "unknown ROLLOVER_OPT_APPROVAL='$ROLLOVER_OPT_APPROVAL' — ignoring" ;;
  esac
  [ -n "${ROLLOVER_OPT_MODEL:-}" ] && OPT_ARGS+=(--model "$ROLLOVER_OPT_MODEL")
  # shellcheck disable=SC2206 — deliberate word-split escape hatch
  [ -n "${ROLLOVER_OPT_EXTRA:-}" ] && OPT_ARGS+=($ROLLOVER_OPT_EXTRA)
fi

# Every mode prints the paste-me prompt first — it must survive launch failure.
printf 'Bootstrap prompt (paste into the successor if needed):\n----\n%s\n----\n' "$PROMPT"

[ "$MODE" = "auto" ] && [ "$RUNTIME" = "claude" ] && BG=1
if [ "$BG" -eq 1 ] && [ "$RUNTIME" != "claude" ]; then
  die "--bg (background launch) is claude-only (ADR-0003); runtime=$RUNTIME"
fi

echo "project=$PROJECT runtime=$RUNTIME mode=$MODE bg=$BG"

# Release the dying session's own work-item lock BEFORE any launch path: with
# auto-relaunch the successor's register races an unreleased lock (and the
# attached-manual path execs below, so nothing can release afterwards). Only a
# lock held by this session's own registry identity is removed — a foreign
# holder's lock is never stolen, just warned about.
LOCK="$WORKSPACE_ROOT/work/$PROJECT/.active-session"
if [ "$DRY" -eq 0 ] && [ -f "$LOCK" ]; then
  hrt=$(jq -r '.runtime // empty' "$LOCK" 2>/dev/null)
  hsid=$(jq -r '.session_id // empty' "$LOCK" 2>/dev/null)
  drt=""; [ -n "$REC" ] && drt=$(jq -r '.runtime // empty' "$REC" 2>/dev/null)
  if [ -n "$DYING_SID" ] && [ "$hrt-$hsid" = "$drt-$DYING_SID" ]; then
    rm -f "$LOCK"
    note "lock: released work/$PROJECT/.active-session (pre-launch; successor's register re-acquires)"
  else
    note "lock: held by $hrt-$hsid, not this session — left in place; successor will contend"
  fi
fi

if [ "$MODE" = "off" ]; then
  note "ROLLOVER_RELAUNCH=off — not launching; paste the prompt above manually"
  exit 0
fi

case "$RUNTIME" in
  claude)   CMD=(claude); [ "$BG" -eq 1 ] && CMD+=(--bg)
            CMD+=(${OPT_ARGS[@]+"${OPT_ARGS[@]}"} "$PROMPT") ;;
  codex)    CMD=(codex ${OPT_ARGS[@]+"${OPT_ARGS[@]}"} "$PROMPT") ;;
  gemini)   CMD=(gemini ${OPT_ARGS[@]+"${OPT_ARGS[@]}"} -i "$PROMPT") ;;
  opencode) CMD=(opencode ${OPT_ARGS[@]+"${OPT_ARGS[@]}"} --prompt "$PROMPT") ;;
  copilot|copilot-cli) CMD=(copilot ${OPT_ARGS[@]+"${OPT_ARGS[@]}"} -i "$PROMPT") ;;
  copilot-vscode)
    note "copilot-vscode has no CLI seeded launch (see issues/01-vscode-agent-mode-hooks.md) — paste the prompt into VS Code agent mode"
    exit 0 ;;
  *) die "unknown runtime: $RUNTIME" ;;
esac

if [ "$DRY" -eq 1 ]; then
  echo "cmd: $(printf '%q ' "${CMD[@]}" | sed 's/ $//')"
  exit 0
fi

if [ "$BG" -eq 1 ]; then
  PRE_EXISTING=" $(ls "$STATE_DIR/sessions/" 2>/dev/null | tr '\n' ' ') "
  "${CMD[@]}" || die "launch failed: ${CMD[*]}"
  deadline=$(( $(date +%s) + CONFIRM_SECS ))
  while [ "$(date +%s)" -lt "$deadline" ]; do
    for f in "$STATE_DIR/sessions/"*.json; do
      [ -f "$f" ] || continue
      case "$PRE_EXISTING" in *" $(basename "$f") "*) continue ;; esac
      proj="$(jq -r '.project // empty' "$f" 2>/dev/null)"
      sid="$(jq -r '.session_id // empty' "$f" 2>/dev/null)"
      if [ "$proj" = "$PROJECT" ] && [ -n "$sid" ] && [ "$sid" != "$DYING_SID" ]; then
        echo "successor=confirmed session=$sid"
        exit 0
      fi
    done
    sleep 2
  done
  note "successor did not register within ${CONFIRM_SECS}s — check 'claude attach' / the sessions dir"
  echo "successor=unconfirmed"
  exit 0
fi

# manual / attached: exec only on a real terminal; from an agent tool-shell,
# print the ready-to-run command instead (relaunch-analysis: "print the
# ready-to-run command (others)").
if [ -t 0 ] && [ -t 1 ]; then
  exec "${CMD[@]}"
else
  note "not an interactive terminal — run this in one:"
  echo "run: $(printf '%q ' "${CMD[@]}" | sed 's/ $//')"
  exit 0
fi
