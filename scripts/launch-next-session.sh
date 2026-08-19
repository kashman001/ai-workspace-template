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
#          ROLLOVER_OPT_APPROVAL=default|edits|auto|full, ROLLOVER_OPT_MODEL=<id>,
#          ROLLOVER_OPT_EXTRA=<raw args> — replayed as per-runtime flags on
#          the successor launch. Use ROLLOVER_OPT_EXTRA to hand the successor
#          an opt-in MCP fragment, e.g.
#          ROLLOVER_OPT_EXTRA="--mcp-config mcp-fragments/<server>.json"
#          (claude-only flags; see mcp-fragments/README.md).
# Exit:    0 ok / 3 error. Requires jq.
# Vendor flags verified against live --help 2026-08-05: claude [prompt] + --bg;
# codex [PROMPT]; gemini -i; opencode --prompt; copilot -i. claude -n/--name
# (session display name: picker + terminal title) verified 2026-08-06
# (2.1.223); no equivalent verified for other runtimes — their session titles
# rely on the prompt's "Work item <proj> - rollover session #N" lead (ASCII
# only: the %q cmd-echo pipes through BSD sed, which rejects multibyte).
# Approval-mapping
# flags (OPT_ARGS below) re-verified against live --help 2026-08-06: claude
# --permission-mode acceptEdits (edits), --permission-mode auto (auto —
# classifier-vetted, claude 2.1.223), --dangerously-skip-permissions (full);
# codex --ask-for-approval never/--dangerously-bypass-approvals-and-sandbox
# (NOT --full-auto — that flag does not exist in codex-cli 0.142.4); gemini
# --approval-mode auto_edit/--yolo; opencode --auto (same flag for edits and
# full); copilot --allow-all-tools/--allow-all. Non-claude runtimes have no
# classifier equivalent: auto falls back to the edits mapping with a note.
# Re-verify before changing (ADR-0003: a nonexistent flag already slipped in
# once).

set -u

# Workspace identity = repository identity, not checkout path (issue 05):
# resolve through git's common dir so a launcher invoked from a worktree
# still reads/writes the main checkout's coordination state. Fallbacks: not
# a git repo, or the git root is not this workspace — script-relative root.
SCRIPT_ROOT="$(cd "$(dirname "$0")/.." && pwd -P)"
resolve_workspace_root() {
  local common repo
  if common="$(git -C "$SCRIPT_ROOT" rev-parse --git-common-dir 2>/dev/null)"; then
    case "$common" in /*) : ;; *) common="$SCRIPT_ROOT/$common" ;; esac
    repo="$(cd "$common/.." 2>/dev/null && pwd -P)"
    if [ -n "$repo" ] && [ -f "$repo/scripts/launch-next-session.sh" ]; then
      printf '%s' "$repo"; return
    fi
  fi
  printf '%s' "$SCRIPT_ROOT"
}
WORKSPACE_ROOT="$(resolve_workspace_root)"
STATE_DIR="$WORKSPACE_ROOT/.context-budget"

note() { echo "$@" >&2; }
die()  { echo "error: $*" >&2; exit 3; }

PROJECT=""; RUNTIME=""; BG=0; DRY=0; SKIP_FRESH=0
while [ $# -gt 0 ]; do
  case "$1" in
    --runtime) RUNTIME="$2"; shift 2 ;;
    --bg) BG=1; shift ;;
    --dry-run) DRY=1; shift ;;
    --skip-freshness) SKIP_FRESH=1; shift ;;
    -*) die "unknown option: $1" ;;
    *) [ -z "$PROJECT" ] && PROJECT="$1" || die "unexpected argument: $1"; shift ;;
  esac
done
[ -n "$PROJECT" ] || die "usage: launch-next-session.sh <project> [--runtime <rt>] [--bg] [--dry-run] [--skip-freshness]"

# Worktree-invoked (issue 05): tracked handoff artifacts (launcher/ledger)
# flow only through git, so before launching make the successor's launch root
# current — verify the worktree's state is committed+pushed, ff-only-pull the
# main checkout, then launch from the main root. Refusals are loud and die
# BEFORE the paste-me prompt: they are precondition failures (like the
# missing-launcher die below), and the human must resolve them.
if [ "$SCRIPT_ROOT" != "$WORKSPACE_ROOT" ]; then
  [ -z "$(git -C "$SCRIPT_ROOT" status --porcelain -uno -- "work/$PROJECT" 2>/dev/null)" ] \
    || die "worktree has uncommitted changes under work/$PROJECT — commit them before relaunch"
  [ -z "$(git -C "$SCRIPT_ROOT" rev-list -n1 HEAD --not --remotes 2>/dev/null)" ] \
    || die "worktree has commits not on any remote — push first (the successor launches from the main checkout)"
  [ -z "$(git -C "$WORKSPACE_ROOT" status --porcelain -uno -- "work/$PROJECT" 2>/dev/null)" ] \
    || die "main checkout has uncommitted changes under work/$PROJECT — resolve them before relaunch"
  if [ "$DRY" -eq 0 ]; then
    git -C "$WORKSPACE_ROOT" pull --ff-only -q 2>/dev/null \
      || die "main checkout 'git pull --ff-only' failed (diverged or offline) — sync it manually"
  fi
  note "worktree-invoked: main checkout synced; launching from $WORKSPACE_ROOT"
  cd "$WORKSPACE_ROOT"
fi

[ -f "$WORKSPACE_ROOT/work/$PROJECT/next-session.md" ] \
  || die "work/$PROJECT/next-session.md not found — run session-rollover first"

# Launcher freshness guard (backlog L33): a successor launched from a stale
# next-session.md resumes an outdated plan (three strikes logged). Refuse to
# launch when any local or remote ref carries a newer commit touching the
# launcher that is not in this checkout's history. Best-effort fetch first so
# lagging remote-tracking refs are visible; fails open when offline or when
# the launcher is untracked. Override: --skip-freshness.
if [ "$SKIP_FRESH" -eq 0 ]; then
  git -C "$WORKSPACE_ROOT" fetch -q --all 2>/dev/null || true
  # A launcher-touching commit reachable from some ref but NOT from HEAD =
  # someone has a launcher edit this checkout lacks (no date comparison —
  # rapid-fire commits share second-resolution timestamps).
  NEWER="$(git -C "$WORKSPACE_ROOT" rev-list -1 --all --not HEAD -- "work/$PROJECT/next-session.md" 2>/dev/null)"
  # Inline ff-only self-heal (rollover-automation-fix): a worktree-invoked
  # launch commits the fresh launcher on its work branch, but the successor
  # launches from the main checkout — background sessions cannot close that
  # gap themselves (classifier / keychain / isolation), so every bg rollover
  # used to die here waiting for a human merge. If the work branch is a CLEAN
  # fast-forward of origin/main, push it to main and re-check; on real
  # divergence fall through to the refusal below (a human must see it).
  # The push must also actually cure the staleness — NEWER reachable from the
  # work branch — else (newest launcher on a third ref) both dry-run and real
  # mode refuse identically instead of pushing and then refusing anyway.
  if [ -n "$NEWER" ] && [ "$SCRIPT_ROOT" != "$WORKSPACE_ROOT" ]; then
    WT_BRANCH="$(git -C "$SCRIPT_ROOT" rev-parse --abbrev-ref HEAD 2>/dev/null)"
    if [ -n "$WT_BRANCH" ] && [ "$WT_BRANCH" != "HEAD" ] \
       && git -C "$SCRIPT_ROOT" merge-base --is-ancestor origin/main "$WT_BRANCH" 2>/dev/null \
       && git -C "$SCRIPT_ROOT" merge-base --is-ancestor "$NEWER" "$WT_BRANCH" 2>/dev/null; then
      if [ "$DRY" -eq 1 ]; then
        note "dry-run: would ff-push origin $WT_BRANCH:main (stale launcher self-heal)"
        NEWER=""
      elif git -C "$SCRIPT_ROOT" push origin "$WT_BRANCH:main" >/dev/null 2>&1; then
        note "stale launcher self-heal: ff-pushed origin $WT_BRANCH:main"
        git -C "$WORKSPACE_ROOT" pull --ff-only -q 2>/dev/null \
          || die "main checkout 'git pull --ff-only' failed after ff-push — sync it manually"
        NEWER="$(git -C "$WORKSPACE_ROOT" rev-list -1 --all --not HEAD -- "work/$PROJECT/next-session.md" 2>/dev/null)"
      else
        note "ff-push origin $WT_BRANCH:main failed — leaving the stale-launcher refusal in place"
      fi
    fi
  fi
  if [ -n "$NEWER" ]; then
    refs="$(git -C "$WORKSPACE_ROOT" branch -a --contains "$NEWER" 2>/dev/null \
      | sed 's/^[* ] //' | head -3 | tr '\n' ' ')"
    die "stale launcher: a newer work/$PROJECT/next-session.md commit (${NEWER:0:12}) exists on: ${refs:-unknown ref} — merge/pull it into this checkout first, or pass --skip-freshness to launch anyway"
  fi
fi

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

# Untracked coordination state can be stranded in a sibling checkout: the
# rolling agent writes work/<proj>/.session-seq (and hand-edits
# .rollover-options) relative to its OWN worktree, where this script never
# used to look (rollover-state-sync-issue). Reconcile at read time across
# every checkout of the repo instead of trusting the main copy. Fails open
# to the main checkout outside a git repo (main is listed first, so it also
# wins mtime ties below).
all_checkouts() {
  git -C "$WORKSPACE_ROOT" worktree list --porcelain 2>/dev/null \
    | sed -n 's/^worktree //p'
  echo "$WORKSPACE_ROOT"   # non-git fallback; the duplicate is harmless
}

# Lineage sequence: work/<proj>/.session-seq holds the last-launched session's
# number (machine-local runtime state, gitignored). Successor = last+1;
# persisted only on a real run (--dry-run never mutates). Absent file means
# the current session is #1. Feeds the prompt lead + claude --name so session
# titles read "work item + number" instead of a guess from early content.
# The counter only grows, so across checkouts the numeric max wins; the
# result is persisted to the main checkout, which every launch reads.
SEQF="$WORKSPACE_ROOT/work/$PROJECT/.session-seq"
LAST_SEQ=""; SEQ_SRC=""
while IFS= read -r co; do
  f="$co/work/$PROJECT/.session-seq"
  [ -f "$f" ] || continue
  v="$(tr -cd '0-9' < "$f" 2>/dev/null)"
  [ -n "$v" ] || continue
  if [ -z "$LAST_SEQ" ] || [ "$v" -gt "$LAST_SEQ" ]; then LAST_SEQ="$v"; SEQ_SRC="$f"; fi
done < <(all_checkouts)
[ -n "$LAST_SEQ" ] || LAST_SEQ=1
[ -n "$SEQ_SRC" ] && [ "$SEQ_SRC" != "$SEQF" ] \
  && note "session-seq: adopting $LAST_SEQ from $SEQ_SRC (main copy stale or absent)"
SEQ=$((LAST_SEQ + 1))
[ "$DRY" -eq 0 ] && printf '%s\n' "$SEQ" > "$SEQF"

# The canonical bootstrap prompt (ADR-0003: wording is load-bearing, verbatim).
PROMPT="Work item $PROJECT - rollover session #$SEQ. Read \`work/$PROJECT/next-session.md\` and continue from **First actions**."

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
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    if [ "$(jq -r '.project // empty' "$f" 2>/dev/null)" = "$PROJECT" ]; then
      echo "$f"; return 0
    fi
  done < <(ls -t "$STATE_DIR/sessions/"*.json 2>/dev/null)
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
# Same stranding as .session-seq: the newest copy across checkouts wins,
# and an adopted copy is persisted to the main checkout so it survives
# worktree pruning. --dry-run reads the newest copy in place instead.
OPT_NEWEST=""
while IFS= read -r co; do
  f="$co/work/$PROJECT/.rollover-options"
  [ -f "$f" ] || continue
  if [ -z "$OPT_NEWEST" ] || [ "$f" -nt "$OPT_NEWEST" ]; then OPT_NEWEST="$f"; fi
done < <(all_checkouts)
if [ -n "$OPT_NEWEST" ] && [ "$OPT_NEWEST" != "$OPTF" ]; then
  if [ "$DRY" -eq 1 ]; then
    note "dry-run: would adopt .rollover-options from $OPT_NEWEST"
    OPTF="$OPT_NEWEST"
  elif cp "$OPT_NEWEST" "$OPTF" 2>/dev/null; then
    note "rollover-options: adopted newest copy from $OPT_NEWEST"
  fi
fi
if [ -f "$OPTF" ]; then
  ROLLOVER_OPT_APPROVAL=""; ROLLOVER_OPT_MODEL=""; ROLLOVER_OPT_EXTRA=""
  . "$OPTF" >/dev/null 2>&1 || true
  case "${ROLLOVER_OPT_APPROVAL:-}" in
    ""|default) : ;;
    edits)
      case "$RUNTIME" in
        claude) OPT_ARGS+=(--permission-mode acceptEdits) ;;
        codex) OPT_ARGS+=(--ask-for-approval never) ;;
        gemini) OPT_ARGS+=(--approval-mode auto_edit) ;;
        opencode) OPT_ARGS+=(--auto) ;;
        copilot|copilot-cli) OPT_ARGS+=(--allow-all-tools) ;;
      esac ;;
    auto)
      case "$RUNTIME" in
        claude) OPT_ARGS+=(--permission-mode auto) ;;
        codex)
          note "runtime=codex has no classifier mode — falling back to nearest level (edits)"
          OPT_ARGS+=(--ask-for-approval never) ;;
        gemini)
          note "runtime=gemini has no classifier mode — falling back to nearest level (edits)"
          OPT_ARGS+=(--approval-mode auto_edit) ;;
        opencode)
          note "runtime=opencode has no classifier mode — falling back to nearest level (edits)"
          OPT_ARGS+=(--auto) ;;
        copilot|copilot-cli)
          note "runtime=$RUNTIME has no classifier mode — falling back to nearest level (edits)"
          OPT_ARGS+=(--allow-all-tools) ;;
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
# copilot-vscode's `code chat` is detached by nature (exits before the seeded
# session responds — issue 01) — always confirm the successor via the BG loop.
[ "$RUNTIME" = "copilot-vscode" ] && BG=1
if [ "$BG" -eq 1 ] && [ "$RUNTIME" != "claude" ] && [ "$RUNTIME" != "copilot-vscode" ]; then
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
    # The dying session's primary role ends here: stamp its registry record
    # superseded so listings and attach-session.sh never mistake it for a
    # usable session (the successor's own register becomes the new primary).
    if [ -n "$REC" ] && [ -f "$REC" ]; then
      jq --arg ts "$(date -u +%FT%TZ)" '.role="superseded" | .superseded_at=$ts' \
        "$REC" > "$REC.tmp" && mv "$REC.tmp" "$REC"
      note "role: $drt-$DYING_SID stamped superseded"
    fi
  else
    note "lock: held by $hrt-$hsid, not this session — left in place; successor will contend"
  fi
fi

if [ "$MODE" = "off" ]; then
  note "ROLLOVER_RELAUNCH=off — not launching; paste the prompt above manually"
  exit 0
fi

case "$RUNTIME" in
  claude)   CMD=(claude --name "$PROJECT #$SEQ"); [ "$BG" -eq 1 ] && CMD+=(--bg)
            CMD+=(${OPT_ARGS[@]+"${OPT_ARGS[@]}"} "$PROMPT") ;;
  codex)    CMD=(codex ${OPT_ARGS[@]+"${OPT_ARGS[@]}"} "$PROMPT") ;;
  gemini)   CMD=(gemini ${OPT_ARGS[@]+"${OPT_ARGS[@]}"} -i "$PROMPT") ;;
  opencode) CMD=(opencode ${OPT_ARGS[@]+"${OPT_ARGS[@]}"} --prompt "$PROMPT") ;;
  copilot|copilot-cli) CMD=(copilot ${OPT_ARGS[@]+"${OPT_ARGS[@]}"} -i "$PROMPT") ;;
  copilot-vscode)
    # Verified (issue 01, session 28): opens a NEW agent session in the
    # last-active VS Code window and returns immediately.
    CMD=(code chat ${OPT_ARGS[@]+"${OPT_ARGS[@]}"} -r -m agent "$PROMPT") ;;
  *) die "unknown runtime: $RUNTIME" ;;
esac

if [ "$DRY" -eq 1 ]; then
  echo "cmd: $(printf '%q ' "${CMD[@]}" | sed 's/ $//')"
  exit 0
fi

# Registration handshake (rollover-automation-fix): the successor's
# SessionStart hook runs `context-budget.sh register` with no --project (it
# cannot know the work item at session start), so its record used to carry
# project:"" — making the --bg confirm poll below undecidable and degrading
# lock attribution/release. Drop a pending file the successor's register
# consumes (freshest non-expired wins; TTL enforced there). A file, not an
# env var: it must survive `claude --bg` daemonization, and works identically
# for attached launches on every runtime. Written ONLY at the two points that
# actually start a successor (bg launch, attached exec) and removed if the bg
# launch dies — no pending file may exist unless a successor was actually
# started (a consumer of a launch-less file would take the project's primary
# lock; the non-tty branch below prints the command and exits, launching
# nothing, so a successor started from that printout registers project-less).
PENDING="$STATE_DIR/successor-pending-$PROJECT.json"
write_pending() {
  mkdir -p "$STATE_DIR"
  jq -n --arg proj "$PROJECT" --argjson seq "$SEQ" --arg ts "$(date -u +%FT%TZ)" \
    '{project:$proj, seq:$seq, launched_at:$ts}' > "$PENDING"
  note "handshake: wrote ${PENDING#"$WORKSPACE_ROOT/"} for the successor's register"
}

if [ "$BG" -eq 1 ]; then
  PRE_EXISTING=" $(ls "$STATE_DIR/sessions/" 2>/dev/null | tr '\n' ' ') "
  write_pending
  "${CMD[@]}" || { rm -f "$PENDING"; die "launch failed: ${CMD[*]}"; }
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
  # Fallback (rollover-automation-fix): hooks disabled or handshake missed —
  # a NEW but project-less record inside the window is almost certainly the
  # successor (the .project match above stays primary; this only softens the
  # verdict from unconfirmed to probable).
  PROBABLE=""
  for f in "$STATE_DIR/sessions/"*.json; do
    [ -f "$f" ] || continue
    case "$PRE_EXISTING" in *" $(basename "$f") "*) continue ;; esac
    proj="$(jq -r '.project // empty' "$f" 2>/dev/null)"
    sid="$(jq -r '.session_id // empty' "$f" 2>/dev/null)"
    if [ -z "$proj" ] && [ -n "$sid" ] && [ "$sid" != "$DYING_SID" ]; then
      PROBABLE="$sid"
    fi
  done
  if [ -n "$PROBABLE" ]; then
    note "a new project-less session registered in the window — handshake missed, treating as the successor"
    echo "successor=probable session=$PROBABLE"
    exit 0
  fi
  note "successor did not register within ${CONFIRM_SECS}s — check 'claude attach' / the sessions dir"
  echo "successor=unconfirmed"
  exit 0
fi

# manual / attached: exec only on a real terminal; from an agent tool-shell,
# print the ready-to-run command instead (relaunch-analysis: "print the
# ready-to-run command (others)").
if [ -t 0 ] && [ -t 1 ]; then
  write_pending
  exec "${CMD[@]}"
else
  note "not an interactive terminal — run this in one:"
  echo "run: $(printf '%q ' "${CMD[@]}" | sed 's/ $//')"
  exit 0
fi
