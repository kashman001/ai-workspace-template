# Implementation Spec — Context Budget & Session Rollover

**Audience:** an AI agent (any runtime) implementing this system in a similar
multi-agent workspace. This spec is self-contained: design rationale,
implementation (tested code embedded verbatim), documentation requirements,
and a verification protocol. Adapt the `ADAPT:` markers to the target
workspace; everything else should transfer as-is.

**Origin:** built and verified 2026-07-22 in the insight-dev-ai workspace.
The Claude Code hook fired its first live warning during its own build
session — the system is proven in production.

---

## 1. Purpose and acceptance criteria

LLM performance degrades past ~150K context tokens (the "dumb zone")
regardless of advertised window size. Build a system that:

1. **Measures** any agent session's live context usage exactly and
   reproducibly, from disk, for: Claude Code, Codex, GitHub Copilot in
   VS Code, GitHub Copilot CLI, Gemini CLI.
2. **Warns** the developer and (where possible) the agent itself before/at
   the threshold — including mid-task during long-running work.
3. **Rolls over** work to a fresh session via a deliberate, pruned handoff
   instead of uncontrolled automatic compaction.
4. Is **agent-runtime-neutral**: plain bash + jq + Markdown skills; no
   vendor-specific formats except thin per-runtime wiring.
5. Threshold is a **parameter** raised as models improve.

**Acceptance:** `context-budget.sh check --runtime <rt>` returns an exact
token count for every runtime with a live session on the machine; exit codes
0/1/2 map to OK/WARN/STOP; a Claude Code session that crosses WARN receives
an in-band hook message; the rollover skill produces `handoff.md`,
`next-session.md`, and a bootstrap prompt; all workspace validation scripts
pass.

## 2. Design decisions (implement these, not just the files)

- **D1 Measure from disk, never ask the model.** Token usage lives in the API
  response envelope the model never sees; agents guess their own usage badly.
  Every runtime persists usage (or raw transcripts) on disk — parse that.
  The agent's role is inverted: it *invokes* measurement at checkpoints; it
  is never the source of the number.
- **D2 Per-runtime adapters behind a fixed output contract.** Session formats
  are undocumented internals; drift is expected. One discover + one measure
  function per runtime; consumers see only the status line and ledger schema,
  so a format change breaks one function, never the skills/docs/hooks.
- **D3 Absolute threshold, not %-of-window** (a 936K Copilot window doesn't
  move the dumb zone). One checked-in env var pair, raised in one place.
  Must sit *below* the runtime's auto-compact trigger or compaction fires
  first and the deliberate handoff never happens.
- **D4 Estimate fallback (bytes÷4, `method=estimate`), never "unsupported".**
  A hard failure silently disables the safety net exactly where it's needed
  most. ±25% accuracy is fine given the WARN→STOP margin.
- **D5 Explicit session registration (`register`) over newest-mtime
  discovery** — concurrent sessions make heuristics ambiguous. Hooks that
  receive the exact transcript path bypass both.
- **D6 Hook speaks only on status escalation, throttled, and fails open.**
  Warnings consume the very budget they protect; repetition trains agents to
  ignore them. One WARN + one STOP per session. Any hook error → exit 0.
- **D7 Rollover is a Markdown skill** reusing the workspace's existing
  handoff skill; backward-looking `handoff.md` split from forward-looking,
  deliberately pruned `next-session.md` (with an explicit "Do NOT reload"
  section). Specialized workflow state files stay authoritative.
- **D8 Layered triggering:** in-band hook (Claude Code) + mandatory
  checkpoints in long-running skills (all runtimes) + polling watcher with
  OS notification (hook-less runtimes) + standing instruction in the shared
  agent context file. No single mechanism covers every runtime.
- **D9 Append-only JSON ledger** of labeled measurements — turns the safety
  net into research data (token growth per workflow phase).

## 3. Deliverables inventory

| # | File (ADAPT paths to target conventions) | What |
| --- | --- | --- |
| 1 | `scripts/context-budget.sh` | measurement core (§5, verbatim) |
| 2 | env file (checked-in, non-secret) | `CONTEXT_DUMB_ZONE_TOKENS=150000`, `CONTEXT_DUMB_ZONE_WARN_TOKENS=120000` |
| 3 | `scripts/hooks/context-budget-claude-hook.sh` | Claude Code PostToolUse hook (§6, verbatim) |
| 4 | `.claude/settings.json` (+ checked-in template if gitignored) | hook wiring (§6) |
| 5 | `skills/session-rollover/SKILL.md` | rollover workflow (§7, outline) |
| 6 | `docs/context-budget.md` | usage + reference doc (§8, outline) |
| 7 | `work/context-decay/design.html` | self-contained HTML design doc (§8) |
| 8 | long-running/orchestrator skills | mandatory checkpoint clause (§9) |
| 9 | shared agent context file (CONTEXT.md/AGENTS.md) | standing instruction (§9) |
| 10 | `.gitignore` | add `.context-budget/` |
| 11 | `work/context-decay/context-ledger.jsonl` | created by first `record` |

## 4. Measurement sources (the hard-won knowledge)

| Runtime | Artifact | Signal | Fidelity |
| --- | --- | --- | --- |
| Claude Code | `~/.claude/projects/<cwd-slug>/<session>.jsonl` (slug = cwd with `/` and `.` → `-`) | last main-chain `message.usage`: `input_tokens + cache_read_input_tokens + cache_creation_input_tokens`; **exclude `isSidechain:true`** (sub-agent turns have their own windows) | exact |
| Codex | `~/.codex/sessions/YYYY/MM/DD/rollout-*.jsonl` | last `"last_token_usage"` object → `total_tokens`; prefer rollouts whose head (`session_meta`) contains the workspace cwd | exact |
| Copilot VS Code | `~/Library/Application Support/<app>/User/workspaceStorage/<hash>/chatSessions/*.jsonl`; `<app>` ∈ Code, Code - Insiders, VSCodium; find `<hash>` by grepping the workspace path in each `workspace.json` | last `"promptTokens":N` — use flat `grep -o`, NOT jq: files reach 4–5MB with multi-MB single-line records (jq with wide context times out; flat scan survives schema nesting changes) | exact |
| Copilot CLI | probe `~/.copilot/history-session-state/`, `~/.copilot/sessions/` | try `promptTokens`/`input_tokens`/`inputTokens`, else estimate. **Unverified** — refine against real files on first CLI session; also check whether `~/.copilot/hooks/` supports an in-band hook | expected exact |
| Gemini CLI | `~/.gemini/tmp/<hash>/logs.json` | no token counts in logs → bytes÷4 estimate; exact requires enabling Gemini local telemetry (follow-up) | estimate |

Non-macOS targets: Copilot VS Code storage root differs (Linux:
`~/.config/Code/...`, Windows: `%APPDATA%/Code/...`); `stat -f%z/-f%m` are
BSD — the code already falls back to GNU `stat -c%s/-c%Y`; replace
`osascript` notifications with `notify-send` or equivalent.

## 5. `scripts/context-budget.sh` (verbatim, tested)

CLI: `check|register|record|watch`, options `--runtime
claude|codex|copilot-vscode|copilot-cli|gemini|auto`, `--transcript <path>`,
`--label "<text>"`, `--interval <secs>`, `--quiet`. Output one line:
`runtime= method= tokens= threshold= warn= pct= status= artifact=`.
Exit 0 OK / 1 WARN / 2 STOP / 3 error. Requires `jq`.

ADAPT: the env-file name it sources for thresholds, and the ledger path.

```bash
#!/usr/bin/env bash
# context-budget.sh — measure the current agent session's context-window usage
# and compare it against the workspace "dumb zone" threshold.
# Design notes: D1–D6 in the implementation spec / design.html.

set -u

WORKSPACE_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
STATE_DIR="$WORKSPACE_ROOT/.context-budget"
LEDGER="$WORKSPACE_ROOT/work/context-decay/context-ledger.jsonl"

if [ -z "${CONTEXT_DUMB_ZONE_TOKENS:-}" ] && [ -f "$WORKSPACE_ROOT/insight-environments.env" ]; then
  . "$WORKSPACE_ROOT/insight-environments.env" >/dev/null 2>&1 || true
fi
THRESHOLD="${CONTEXT_DUMB_ZONE_TOKENS:-150000}"
WARN="${CONTEXT_DUMB_ZONE_WARN_TOKENS:-$(( THRESHOLD * 80 / 100 ))}"

COMMAND="check"; RUNTIME="auto"; ARTIFACT=""; LABEL=""; INTERVAL=30; QUIET=0
case "${1:-}" in check|register|record|watch) COMMAND="$1"; shift ;; esac
while [ $# -gt 0 ]; do
  case "$1" in
    --runtime) RUNTIME="$2"; shift 2 ;;
    --transcript) ARTIFACT="$2"; shift 2 ;;
    --label) LABEL="$2"; shift 2 ;;
    --interval) INTERVAL="$2"; shift 2 ;;
    --quiet) QUIET=1; shift ;;
    *) echo "unknown option: $1" >&2; exit 3 ;;
  esac
done

note() { [ "$QUIET" -eq 1 ] || echo "$@" >&2; }
die()  { echo "error: $*" >&2; exit 3; }

newest_of() { ls -t "$@" 2>/dev/null | head -1; }

claude_discover() {
  local slug proj
  slug="$(pwd | tr '/.' '--')"
  proj="$HOME/.claude/projects/$slug"
  [ -d "$proj" ] || return 1
  newest_of "$proj"/*.jsonl
}

codex_discover() {
  local base f
  base="$HOME/.codex/sessions"
  [ -d "$base" ] || return 1
  while IFS= read -r f; do
    if head -c 8192 "$f" 2>/dev/null | grep -qF "$(pwd)"; then echo "$f"; return 0; fi
  done < <(find "$base" -name 'rollout-*.jsonl' -mtime -7 2>/dev/null | xargs ls -t 2>/dev/null)
  find "$base" -name 'rollout-*.jsonl' 2>/dev/null | xargs ls -t 2>/dev/null | head -1
}

copilot_vscode_discover() {
  local root ws d
  for root in "Code" "Code - Insiders" "VSCodium"; do
    ws="$HOME/Library/Application Support/$root/User/workspaceStorage"
    [ -d "$ws" ] || continue
    for d in "$ws"/*/; do
      [ -f "$d/workspace.json" ] || continue
      if grep -qF "$(pwd)" "$d/workspace.json" 2>/dev/null; then
        newest_of "$d"chatSessions/*.jsonl "$d"chatSessions/*.json && return 0
      fi
    done
  done
  return 1
}

copilot_cli_discover() {
  local d
  for d in "$HOME/.copilot/history-session-state" "$HOME/.copilot/sessions"; do
    [ -d "$d" ] || continue
    find "$d" -type f \( -name '*.json' -o -name '*.jsonl' \) 2>/dev/null | xargs ls -t 2>/dev/null | head -1 && return 0
  done
  return 1
}

gemini_discover() {
  local base="$HOME/.gemini/tmp"
  [ -d "$base" ] || return 1
  find "$base" -name 'logs.json' 2>/dev/null | xargs ls -t 2>/dev/null | head -1
}

estimate_from_size() {
  local bytes
  bytes=$(stat -f%z "$1" 2>/dev/null || stat -c%s "$1" 2>/dev/null) || return 1
  echo "$(( bytes / 4 )) estimate"
}

claude_measure() {
  local f="$1" jq_prog tokens
  # Sidechain (sub-agent) entries excluded — separate windows. tail-then-full
  # keeps multi-MB transcripts fast.
  jq_prog='[.[] | select(.message.usage.input_tokens != null) | select(.isSidechain != true)]
    | last | if . == null then empty else
      (.message.usage.input_tokens + (.message.usage.cache_read_input_tokens // 0)
       + (.message.usage.cache_creation_input_tokens // 0)) end'
  tokens=$(tail -n 2000 "$f" | jq -s -r "$jq_prog" 2>/dev/null)
  [ -z "$tokens" ] && tokens=$(jq -s -r "$jq_prog" "$f" 2>/dev/null)
  [ -n "$tokens" ] && echo "$tokens exact" || estimate_from_size "$f"
}

codex_measure() {
  local f="$1" tokens
  tokens=$(grep -o '"last_token_usage":{[^}]*}' "$f" 2>/dev/null | tail -1 \
    | grep -o '"total_tokens":[0-9]*' | grep -o '[0-9]*$')
  [ -n "$tokens" ] && echo "$tokens exact" || estimate_from_size "$f"
}

copilot_vscode_measure() {
  local f="$1" tokens
  # grep -o, not jq: multi-MB single-line records; survives nesting changes.
  tokens=$(grep -o '"promptTokens":[0-9]*' "$f" 2>/dev/null | tail -1 | grep -o '[0-9]*$')
  [ -n "$tokens" ] && echo "$tokens exact" || estimate_from_size "$f"
}

copilot_cli_measure() {
  local f="$1" tokens
  tokens=$(grep -o '"\(promptTokens\|input_tokens\|inputTokens\)":[0-9]*' "$f" 2>/dev/null \
    | tail -1 | grep -o '[0-9]*$')
  [ -n "$tokens" ] && echo "$tokens exact" || estimate_from_size "$f"
}

gemini_measure() { estimate_from_size "$1"; }

detect_runtime() {
  if [ -n "${CLAUDECODE:-}" ] || [ -n "${CLAUDE_CODE_ENTRYPOINT:-}" ]; then echo "claude"; return; fi
  if [ -n "${CODEX_SANDBOX:-}" ] || [ -n "${CODEX_HOME:-}" ]; then echo "codex"; return; fi
  local best_rt="" best_file="" f
  for rt in claude codex copilot-vscode copilot-cli gemini; do
    f=$(discover_for "$rt") || continue
    [ -n "$f" ] || continue
    if [ -z "$best_file" ] || [ "$f" -nt "$best_file" ]; then best_rt="$rt"; best_file="$f"; fi
  done
  [ -n "$best_rt" ] && echo "$best_rt"
}

discover_for() {
  case "$1" in
    claude) claude_discover ;; codex) codex_discover ;;
    copilot-vscode) copilot_vscode_discover ;; copilot-cli) copilot_cli_discover ;;
    gemini) gemini_discover ;; *) return 1 ;;
  esac
}

measure_for() {
  case "$1" in
    claude) claude_measure "$2" ;; codex) codex_measure "$2" ;;
    copilot-vscode) copilot_vscode_measure "$2" ;; copilot-cli) copilot_cli_measure "$2" ;;
    gemini) gemini_measure "$2" ;; *) return 1 ;;
  esac
}

resolve_session() {
  if [ "$RUNTIME" = "auto" ]; then
    RUNTIME=$(detect_runtime)
    [ -n "$RUNTIME" ] || die "could not detect runtime; pass --runtime"
  fi
  if [ -z "$ARTIFACT" ]; then
    local reg="$STATE_DIR/session-$RUNTIME.json"
    if [ -f "$reg" ]; then
      ARTIFACT=$(jq -r '.artifact // empty' "$reg" 2>/dev/null)
      [ -f "$ARTIFACT" ] || ARTIFACT=""
    fi
  fi
  if [ -z "$ARTIFACT" ]; then
    ARTIFACT=$(discover_for "$RUNTIME") || true
    [ -n "$ARTIFACT" ] && [ -f "$ARTIFACT" ] \
      || die "no session artifact found for runtime=$RUNTIME"
  fi
}

emit_check() {
  local tokens method status pct
  read -r tokens method < <(measure_for "$RUNTIME" "$ARTIFACT") || die "measurement failed"
  [ -n "$tokens" ] || die "measurement failed for $ARTIFACT"
  if [ "$tokens" -ge "$THRESHOLD" ]; then status="STOP"
  elif [ "$tokens" -ge "$WARN" ]; then status="WARN"
  else status="OK"; fi
  pct=$(( tokens * 100 / THRESHOLD ))
  echo "runtime=$RUNTIME method=$method tokens=$tokens threshold=$THRESHOLD warn=$WARN pct=$pct status=$status artifact=$ARTIFACT"
  LAST_TOKENS="$tokens"; LAST_METHOD="$method"; LAST_STATUS="$status"
  case "$status" in OK) return 0 ;; WARN) return 1 ;; STOP) return 2 ;; esac
}

cmd_register() {
  resolve_session
  mkdir -p "$STATE_DIR"
  jq -n --arg rt "$RUNTIME" --arg af "$ARTIFACT" --arg ts "$(date -u +%FT%TZ)" \
    '{runtime:$rt, artifact:$af, registered_at:$ts}' > "$STATE_DIR/session-$RUNTIME.json"
  note "registered $RUNTIME session artifact: $ARTIFACT"
  emit_check
}

cmd_record() {
  resolve_session
  local rc=0
  emit_check || rc=$?
  mkdir -p "$(dirname "$LEDGER")"
  jq -cn --arg ts "$(date -u +%FT%TZ)" --arg rt "$RUNTIME" \
    --arg session "$(basename "$ARTIFACT")" --arg method "$LAST_METHOD" \
    --arg status "$LAST_STATUS" --arg label "$LABEL" \
    --argjson tokens "$LAST_TOKENS" --argjson threshold "$THRESHOLD" \
    '{ts:$ts, runtime:$rt, session:$session, tokens:$tokens, method:$method,
      threshold:$threshold, status:$status, label:$label}' >> "$LEDGER"
  return $rc
}

cmd_watch() {
  resolve_session
  note "watching $RUNTIME session every ${INTERVAL}s; threshold=$THRESHOLD warn=$WARN"
  local prev="OK" rc
  while true; do
    rc=0; emit_check || rc=$?
    if { [ "$LAST_STATUS" = "WARN" ] && [ "$prev" = "OK" ]; } \
       || { [ "$LAST_STATUS" = "STOP" ] && [ "$prev" != "STOP" ]; }; then
      if command -v osascript >/dev/null 2>&1; then
        osascript -e "display notification \"$RUNTIME session at $LAST_TOKENS tokens (threshold $THRESHOLD)\" with title \"Context budget: $LAST_STATUS\" sound name \"Basso\"" || true
      fi
    fi
    prev="$LAST_STATUS"
    sleep "$INTERVAL"
  done
}

command -v jq >/dev/null 2>&1 || die "jq is required"

case "$COMMAND" in
  check) resolve_session; emit_check ;;
  register) cmd_register ;;
  record) cmd_record ;;
  watch) cmd_watch ;;
esac
```

## 6. Claude Code hook (verbatim, tested) + wiring

`scripts/hooks/context-budget-claude-hook.sh` — PostToolUse is the only
mechanism that interrupts an agent mid-turn. Escalation-only + 60s throttle
(D6); fail-open.

```bash
#!/usr/bin/env bash
# Claude Code PostToolUse hook: in-band WARN/STOP on threshold escalation.
set -u
CHECK_EVERY=60
WORKSPACE_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
STATE_DIR="$WORKSPACE_ROOT/.context-budget"
command -v jq >/dev/null 2>&1 || exit 0
input=$(cat)
session_id=$(echo "$input" | jq -r '.session_id // empty')
transcript=$(echo "$input" | jq -r '.transcript_path // empty')
[ -n "$transcript" ] && [ -f "$transcript" ] || exit 0
[ -n "$session_id" ] || session_id="unknown"
mkdir -p "$STATE_DIR"
stamp="$STATE_DIR/hook-$session_id.stamp"
state="$STATE_DIR/hook-$session_id.status"
if [ -f "$stamp" ]; then
  now=$(date +%s)
  last=$(stat -f%m "$stamp" 2>/dev/null || stat -c%Y "$stamp" 2>/dev/null || echo 0)
  [ $(( now - last )) -lt "$CHECK_EVERY" ] && exit 0
fi
touch "$stamp"
# PITFALL: exit codes 1/2 from the script mean WARN/STOP, not failure —
# do NOT `|| exit 0` on the command substitution (original build bug).
line=$("$WORKSPACE_ROOT/scripts/context-budget.sh" check \
        --runtime claude --transcript "$transcript" --quiet 2>/dev/null) || true
[ -n "$line" ] || exit 0
status=$(echo "$line" | grep -o 'status=[A-Z]*' | cut -d= -f2)
tokens=$(echo "$line" | grep -o 'tokens=[0-9]*' | cut -d= -f2)
threshold=$(echo "$line" | grep -o 'threshold=[0-9]*' | cut -d= -f2)
prev="OK"; [ -f "$state" ] && prev=$(cat "$state")
echo "$status" > "$state"
rank() { case "$1" in STOP) echo 2 ;; WARN) echo 1 ;; *) echo 0 ;; esac; }
[ "$(rank "$status")" -le "$(rank "$prev")" ] && exit 0
if [ "$status" = "STOP" ]; then
  echo "CONTEXT BUDGET STOP: this session is at $tokens tokens, past the $threshold-token dumb-zone threshold. Finish the current atomic step only, then tell the user and run the session-rollover workflow (skills/session-rollover/SKILL.md). Do not start new work in this session." >&2
else
  echo "CONTEXT BUDGET WARN: this session is at $tokens tokens, approaching the $threshold-token dumb-zone threshold. Wrap up the current work unit and avoid loading large files; prepare to run the session-rollover workflow (skills/session-rollover/SKILL.md) soon. Mention this warning to the user in your next reply." >&2
fi
exit 2
```

Wiring (add to `.claude/settings.json`; if that file is gitignored in the
target workspace, also add to its checked-in `.example` template):

```json
"hooks": {
  "PostToolUse": [
    { "matcher": "*",
      "hooks": [ { "type": "command",
        "command": "\"$CLAUDE_PROJECT_DIR\"/scripts/hooks/context-budget-claude-hook.sh" } ] }
  ]
}
```

## 7. `skills/session-rollover/SKILL.md` — required content

Write in the target workspace's skill format. Must contain:

1. **Frontmatter/description**: use on WARN/STOP, hook message, or user
   request. Rollover = reflect + flush + handoff + bootstrap.
2. **When to invoke**: STOP → finish only the current atomic step; WARN →
   finish the current work unit first.
3. **Workflow (7 steps)**:
   1. `context-budget.sh record --label "rollover start: <reason>"`
   2. *Reflect*: route conversation-only learnings into workspace files via
      the target workspace's learning-routing convention (ADAPT; ours is a
      3-tier rule: setup-time → setup scripts/docs, stable operational →
      operational-knowledge doc, code-derived → doc with `repo/path:line`
      pointer). Do this now — unwritten learnings are unrecoverable.
   3. *Flush*: make disk fully current — state files, trackers; `git status`
      per touched repo; commit or explicitly note uncommitted work; verify
      sub-agent-claimed outputs exist on disk.
   4. Update `work/<project>/handoff.md` (backward-looking; reuse the
      workspace's existing handoff skill/structure if present).
   5. Update `work/<project>/next-session.md` (forward-looking, pruned):
      Mission / Read-these-in-order (smallest sufficient set) /
      **Do NOT reload** (settled side quests, and why) / State snapshot /
      First actions (step 1: `context-budget.sh register`).
   6. Emit a paste-ready bootstrap prompt: "Read
      `work/<project>/next-session.md` and continue from First actions.
      Governing skill: `skills/<skill>/SKILL.md`."
   7. `context-budget.sh record --label "rollover complete: <project>"`
4. **Guardrails**: specialized workflow handoff/state files win (thin
   pointers, don't fork state); no secrets; prefer file pointers over
   content summaries; never roll over mid-atomic-step; ask where to persist
   if no work directory fits.

## 8. Documentation deliverables

**`docs/context-budget.md`** must contain: a Quickstart split by audience
(developer: `check`, `watch` for hook-less runtimes, what to say when warned;
agent: `register` at start, `record` at boundaries, exit-code actions);
threshold config; the D1 explanation (agents cannot introspect usage);
the adapter table from §4 with fidelity + verification dates; the layered
triggering model from D8; the compaction-interaction warning from D3;
known limitations; ledger schema.

**`work/context-decay/design.html`** — a self-contained HTML design doc
(no external assets; light+dark via `prefers-color-scheme`): problem/goals,
3-layer architecture diagram (CSS boxes suffice), decisions D1–D9 as
choice→why→consequence cards, a design→code map table (decision → file →
functions), the §4 source table, a runtime-flow walkthrough, limitations,
provenance.

**Shared agent context file** (CONTEXT.md/AGENTS.md — whatever all runtimes
read): add a short "Context budget — measure, don't guess" section: the
threshold, agents cannot introspect own usage, `register` at session start,
`record --label` at boundaries, exit-code actions, pointer to the doc and
skill. Also register the new skill in the workspace's skills list, structure
doc, and work-directory index per local convention.

## 9. Checkpoint clause for long-running skills

Add to every orchestrator/long-running skill (ADAPT label text):

> **Measured checkpoint (mandatory, every iteration/phase boundary)**: run
> `scripts/context-budget.sh record --label "<skill>: <unit> done"` and act
> on the exit code: `1` (WARN) — finish the current unit's bookkeeping, then
> run `skills/session-rollover/SKILL.md`; `2` (STOP) — flush shared state
> and hand off immediately. Never start a new parallel phase in WARN/STOP
> state.

## 10. Verification protocol (run all)

1. `bash -n` both scripts; `jq -e .hooks .claude/settings.json`.
2. Adapter truth test per runtime with a live/local session:
   `check --runtime <rt>` returns `method=exact` and a plausible token count
   (compare against the runtime's own context display if available).
3. Exit codes: run with `CONTEXT_DUMB_ZONE_TOKENS=<below current>` → expect
   `status=STOP`, exit 2; with a value putting current usage in the 80–100%
   band → `status=WARN`, exit 1.
4. `register` → state file in `.context-budget/`; `record` → valid JSON line
   appended to the ledger.
5. Hook, by piping fake stdin
   `{"session_id":"t","transcript_path":"<real transcript>"}`:
   normal → silent exit 0; forced-low threshold → STOP message + exit 2;
   repeat with same state → silent exit 0 (suppression); OK run resets state;
   then WARN-band threshold → message + exit 2.
6. Run the target workspace's structure/validation checks and fix findings.
7. Live: open a fresh Claude Code session, confirm the hook fires at WARN
   (or force with a low threshold in the env file, then revert).

## 11. Known pitfalls (bugs already hit — don't rediscover)

- **Hook swallowing WARN/STOP**: `$( ... ) || exit 0` around the check call
  treats exit 1/2 as failure. Capture output, `|| true`, test non-empty.
- **Secret scanners**: a checked-in env var named `*_TOKENS=` can trip
  password/token heuristics. Exempt purely numeric values in the scanner
  (a count is never a credential) rather than renaming the variable.
- **Copilot chatSessions parsing**: never jq or wide-context grep these
  files (multi-MB single lines → timeouts). Flat `grep -o` + `tail -1`.
- **Claude sidechain usage rows** would report a sub-agent's window, not the
  session's — filter `isSidechain != true`.
- **macOS vs GNU**: `stat -f%z/-f%m` vs `-c%s/-c%Y` (code handles both);
  no `grep -P`; zsh users: never name a shell variable `path`.
- **Escaped pipes in Markdown tables** when documenting paths like
  `<Code|Insiders>` — breaks the table; write "(`<app>` = Code, …)".
- Keep the STOP threshold **below** the runtime's auto-compact trigger
  (150K < Claude Code's ~200K works) or rollover never gets its chance.

## 12. Follow-ups to carry into the target workspace

- Verify/fix the Copilot CLI adapter on its first real session; check its
  hooks directory for in-band warning support.
- Enable Gemini CLI local telemetry for exact counts.
- Periodically analyze the ledger: token growth per phase, hot workflows,
  estimate-mode accuracy.
