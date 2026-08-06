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
# Knobs:   context-budget.env — ROLLOVER_RELAUNCH=off|manual|auto,
#          ROLLOVER_RUNTIME (fallback only). ROLLOVER_CONFIRM_SECS (env only,
#          default 120) bounds the --bg successor-confirmation poll.
# Exit:    0 ok / 3 error. Requires jq.
# Vendor flags verified against live --help 2026-08-05: claude [prompt] + --bg;
# codex [PROMPT]; gemini -i; opencode --prompt; copilot -i. Re-verify before
# changing (ADR-0003: a nonexistent flag already slipped in once).

set -u

WORKSPACE_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
STATE_DIR="$WORKSPACE_ROOT/.context-budget"

if [ -z "${ROLLOVER_RELAUNCH:-}" ] && [ -f "$WORKSPACE_ROOT/context-budget.env" ]; then
  . "$WORKSPACE_ROOT/context-budget.env" >/dev/null 2>&1 || true
fi
MODE="${ROLLOVER_RELAUNCH:-off}"
FALLBACK_RUNTIME="${ROLLOVER_RUNTIME:-claude}"
CONFIRM_SECS="${ROLLOVER_CONFIRM_SECS:-120}"

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

# Every mode prints the paste-me prompt first — it must survive launch failure.
printf 'Bootstrap prompt (paste into the successor if needed):\n----\n%s\n----\n' "$PROMPT"

[ "$MODE" = "auto" ] && [ "$RUNTIME" = "claude" ] && BG=1
if [ "$BG" -eq 1 ] && [ "$RUNTIME" != "claude" ]; then
  die "--bg (background launch) is claude-only (ADR-0003); runtime=$RUNTIME"
fi

echo "project=$PROJECT runtime=$RUNTIME mode=$MODE bg=$BG"

if [ "$MODE" = "off" ]; then
  note "ROLLOVER_RELAUNCH=off — not launching; paste the prompt above manually"
  exit 0
fi

case "$RUNTIME" in
  claude)   CMD=(claude); [ "$BG" -eq 1 ] && CMD+=(--bg); CMD+=("$PROMPT") ;;
  codex)    CMD=(codex "$PROMPT") ;;
  gemini)   CMD=(gemini -i "$PROMPT") ;;
  opencode) CMD=(opencode --prompt "$PROMPT") ;;
  copilot|copilot-cli) CMD=(copilot -i "$PROMPT") ;;
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
