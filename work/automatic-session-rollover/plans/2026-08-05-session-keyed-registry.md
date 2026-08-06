# Session-Keyed Registry Migration — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the scalar per-runtime registry in `scripts/context-budget.sh` with a session-keyed registry plus per-project advisory lock, so N concurrent sessions in one workspace each measure their own transcript (closes backlog M13, implements ADR-0004 item #1).

**Architecture:** Registry state moves from `.context-budget/session-<runtime>.json` (one file per runtime — whoever registers last wins) to `.context-budget/sessions/<runtime>-<session-id>.json` (each session writes only its own file). `check`/`record` resolve-self via runtime env-var identity first, then their own session file, then discovery — never another session's file. A per-project advisory lock `work/<proj>/.active-session` enforces one active session per work item, with stale-lock reclamation. Gemini keeps its documented single-session-per-workspace exception with a concurrent-session guard.

**Tech Stack:** bash + jq (existing script conventions: `set -u`, `note`/`die` helpers, per-runtime discover/measure adapters behind a fixed output contract). Tests: plain bash harness, no framework.

## Global Constraints

- Spec (verbatim, do not re-litigate): session file `{runtime, artifact, project, registered_at}` at `.context-budget/sessions/<runtime>-<session-id>.json`; lock `work/<proj>/.active-session` holding runtime + session-id + timestamp; env-var identity order `CLAUDE_CODE_SESSION_ID`, `CODEX_THREAD_ID`, `COPILOT_AGENT_SESSION_ID`; the Claude Code hook keeps passing `--transcript` explicitly (bypasses registry); stale locks = holder's artifact untouched for hours; gemini exact path stays single-session-per-workspace; successor confirmation (D8) = new session file, same project, different session-id.
- `register` must always re-discover (never trust a registry it exists to rewrite).
- Fallback on any parse/identity failure is degradation (estimate / `unknown` id), never a hard "unsupported".
- Output contract line `runtime= method= tokens= threshold= warn= pct= status= artifact=` must not change (the hook greps it).
- Exit codes: 0 OK / 1 WARN / 2 STOP / 3 error — unchanged.
- Surgical: adapters (discover/measure functions) and `emit_check`/`cmd_watch` are untouched.

## Implementation decisions made in this plan (Tier-2 notes to record)

- **Session-id derivation** per runtime, env-first with artifact-derived fallback so the same session maps to the same id either way: claude = `$CLAUDE_CODE_SESSION_ID` else transcript basename; codex = `$CODEX_THREAD_ID` else UUID suffix of rollout filename; copilot-cli = `$COPILOT_AGENT_SESSION_ID` else session-state dir name; copilot-vscode = `$VSCODE_TARGET_SESSION_LOG` basename else artifact basename; gemini = fixed literal `workspace` (no per-session identity exists — that *is* the documented exception).
- **Advisory lock does not block measurement**: a `register --project` that finds the lock held by a live session warns loudly and skips acquisition but still registers the session and emits the check. Rationale: failing register would kill budget tracking for the very session that most needs it; enforcement is the agent reading the warning before doing single-writer launcher/ledger writes.
- **Stale threshold is a knob**: `CONTEXT_LOCK_STALE_SECS` in `context-budget.env`, default 10800 (3h) — "hours" per ADR, one place to tune.
- **Gemini concurrent guard**: at gemini register, a non-empty telemetry log modified <600s ago means another live gemini session owns it → skip the reset, register against the newest chat log (estimate-only), warn. Register is a session-start action, so a fresh own-session log is not yet possible at that point.
- **Housekeeping in register**: delete the legacy scalar `session-<runtime>.json`, prune `sessions/*.json` older than 7 days.

---

### Task 1: Red test — reproduce the M13 clobber

**Files:**
- Create: `scripts/tests/context-budget-registry.test.sh` (mode 755)

**Interfaces:**
- Produces: test harness with `mk_transcript <sid> <tokens>`, `run_as <sid> <args…>`, `assert_eq`/`assert_contains` helpers, and numbered tests T1…; later tasks append tests to this file.

- [ ] **Step 1: Write the harness + T1 (clobber repro)**

```bash
#!/usr/bin/env bash
# File: scripts/tests/context-budget-registry.test.sh
# Purpose: Regression tests for the session-keyed registry + per-project lock
#          in context-budget.sh (backlog M13 / ADR-0004). Self-contained:
#          builds a throwaway workspace + fake $HOME in mktemp -d.
set -u
SRC_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/scripts" "$TMP/work/testproj" "$TMP/home"
cp "$SRC_ROOT/scripts/context-budget.sh" "$TMP/scripts/"
printf 'CONTEXT_DUMB_ZONE_TOKENS=150000\nCONTEXT_DUMB_ZONE_WARN_TOKENS=120000\n' \
  > "$TMP/context-budget.env"
export HOME="$TMP/home"
cd "$TMP"
CB="$TMP/scripts/context-budget.sh"
SLUG="$(pwd | tr '/.' '--')"
PROJ_DIR="$HOME/.claude/projects/$SLUG"; mkdir -p "$PROJ_DIR"

PASS=0; FAIL=0
ok()   { PASS=$((PASS+1)); echo "  ok: $1"; }
bad()  { FAIL=$((FAIL+1)); echo "  FAIL: $1" >&2; }
assert_eq() { [ "$2" = "$3" ] && ok "$1" || bad "$1 (want [$3] got [$2])"; }
assert_contains() { case "$2" in *"$3"*) ok "$1" ;; *) bad "$1 (no [$3] in [$2])" ;; esac; }

mk_transcript() {  # $1=session-id $2=input-tokens
  jq -cn --argjson t "$2" \
    '{message:{usage:{input_tokens:$t,cache_read_input_tokens:0,cache_creation_input_tokens:0}},isSidechain:false}' \
    > "$PROJ_DIR/$1.jsonl"
}
run_as() {  # $1=claude-session-id, rest = context-budget.sh args
  local sid="$1"; shift
  CLAUDE_CODE_SESSION_ID="$sid" "$CB" "$@" --runtime claude
}

echo "T1: two concurrent sessions each measure their own transcript (M13)"
mk_transcript aaa 50000
mk_transcript bbb 90000
run_as aaa register --quiet >/dev/null
run_as bbb register --quiet >/dev/null          # must NOT clobber aaa's registration
out=$(run_as aaa check)
assert_contains "T1a: aaa check binds aaa's transcript" "$out" "artifact=$PROJ_DIR/aaa.jsonl"
assert_contains "T1b: aaa check measures aaa's tokens"  "$out" "tokens=50000"
out=$(run_as bbb check)
assert_contains "T1c: bbb check measures bbb's tokens"  "$out" "tokens=90000"

echo; echo "passed=$PASS failed=$FAIL"
[ "$FAIL" -eq 0 ]
```

- [ ] **Step 2: Run it to verify it fails for the right reason**

Run: `bash scripts/tests/context-budget-registry.test.sh`
Expected: T1a/T1b FAIL — `aaa check` reads the scalar `session-claude.json` that bbb's register overwrote, so it reports `artifact=…/bbb.jsonl tokens=90000`. T1c passes. Exit non-zero.

*(No commit yet — red test commits with the fix in Task 2.)*

---

### Task 2: Session-keyed registry + resolve-self (make T1 green)

**Files:**
- Modify: `scripts/context-budget.sh` — header usage comment, `resolve_session()` (~line 218), `cmd_register()` (~line 251); add `session_id_for()` near the adapters.

**Interfaces:**
- Consumes: harness from Task 1.
- Produces: global `SESSION_ID` set by `resolve_session`; `session_id_for <runtime> <artifact-or-empty>` (echoes id, rc 1 if underivable); session files `$STATE_DIR/sessions/<runtime>-<session-id>.json` with keys `runtime, session_id, artifact, project, registered_at`. Task 3 relies on `SESSION_ID` and the `--project` plumbing point in `cmd_register`.

- [ ] **Step 1: Add `session_id_for()` after `measure_for()`**

```bash
session_id_for() {
  # $1 = runtime, $2 = artifact path or empty. Env-var identity first (exact,
  # exported by the runtime itself), else derived from the artifact path so the
  # same session resolves to the same id either way. rc 1 when underivable.
  local rt="$1" af="${2:-}" b
  case "$rt" in
    claude)  [ -n "${CLAUDE_CODE_SESSION_ID:-}" ] && { echo "$CLAUDE_CODE_SESSION_ID"; return 0; } ;;
    codex)   [ -n "${CODEX_THREAD_ID:-}" ] && { echo "$CODEX_THREAD_ID"; return 0; } ;;
    copilot-cli) [ -n "${COPILOT_AGENT_SESSION_ID:-}" ] && { echo "$COPILOT_AGENT_SESSION_ID"; return 0; } ;;
    copilot-vscode)
      if [ -n "${VSCODE_TARGET_SESSION_LOG:-}" ]; then
        b="$(basename "$VSCODE_TARGET_SESSION_LOG")"; echo "${b%.jsonl}"; return 0
      fi ;;
    gemini)  echo "workspace"; return 0 ;;  # no per-session identity exists (see docs)
  esac
  [ -n "$af" ] || return 1
  b="$(basename "$af")"
  case "$rt" in
    claude)         echo "${b%.jsonl}" ;;
    codex)          b="${b%.jsonl}"; echo "${b#rollout-????-??-??T??-??-??-}" ;;
    copilot-cli)    basename "$(dirname "$af")" ;;
    copilot-vscode) b="${b%.jsonl}"; echo "${b%.json}" ;;
    *) return 1 ;;
  esac
}
```

- [ ] **Step 2: Rewrite `resolve_session()` to resolve-self**

Replace the registry-read block (the `session-$RUNTIME.json` lines) with:

```bash
resolve_session() {
  if [ "$RUNTIME" = "auto" ]; then
    RUNTIME=$(detect_runtime)
    [ -n "$RUNTIME" ] || die "could not detect runtime; pass --runtime"
  fi
  SESSION_ID="$(session_id_for "$RUNTIME" "")" || SESSION_ID=""
  # Resolve-self: only this session's own file is ever trusted — the scalar
  # per-runtime registry let session A measure session B's artifact (M13).
  # register must always re-discover; the registry is what it's there to (re)write.
  if [ -z "$ARTIFACT" ] && [ "$COMMAND" != "register" ] && [ -n "$SESSION_ID" ]; then
    local reg="$STATE_DIR/sessions/$RUNTIME-$SESSION_ID.json"
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
  [ -n "$SESSION_ID" ] || SESSION_ID="$(session_id_for "$RUNTIME" "$ARTIFACT")" || SESSION_ID="unknown"
}
```

- [ ] **Step 3: Rewrite `cmd_register()` to write the session-keyed file**

```bash
cmd_register() {
  resolve_session
  # Session boundary: the workspace telemetry log is shared append-only across
  # gemini sessions — reset it so a new session never reads the previous
  # session's counts (gemini stays single-session-per-workspace, see docs).
  if [ "$RUNTIME" = "gemini" ] && [ "$ARTIFACT" = "$WORKSPACE_ROOT/.gemini/telemetry.log" ]; then
    : > "$ARTIFACT"
  fi
  mkdir -p "$STATE_DIR/sessions"
  rm -f "$STATE_DIR/session-$RUNTIME.json"                      # legacy scalar registry
  find "$STATE_DIR/sessions" -name '*.json' -mtime +7 -delete 2>/dev/null  # dead sessions
  jq -n --arg rt "$RUNTIME" --arg sid "$SESSION_ID" --arg af "$ARTIFACT" \
    --arg proj "$PROJECT" --arg ts "$(date -u +%FT%TZ)" \
    '{runtime:$rt, session_id:$sid, artifact:$af, project:$proj, registered_at:$ts}' \
    > "$STATE_DIR/sessions/$RUNTIME-$SESSION_ID.json"
  note "registered $RUNTIME session $SESSION_ID artifact: $ARTIFACT"
  emit_check
}
```

Also: add `PROJECT=""` to the initializer line (~26) and `--project) PROJECT="$2"; shift 2 ;;` to the option loop; update the header `Usage:` comment to `check|register|record|watch|release … [--project <work-item>]`.

- [ ] **Step 4: Run the tests — T1 green**

Run: `bash scripts/tests/context-budget-registry.test.sh`
Expected: all T1 asserts pass, exit 0. Also sanity-check the live workspace: `scripts/context-budget.sh register` from the repo root still emits an OK line and creates `.context-budget/sessions/claude-<this-session-id>.json`.

- [ ] **Step 5: Commit**

```bash
git add scripts/context-budget.sh scripts/tests/context-budget-registry.test.sh
git commit -m "work(automatic-session-rollover): session-keyed registry — resolve-self in context-budget.sh

Decision: registry moves to .context-budget/sessions/<runtime>-<session-id>.json;
check/record trust only their own session file (env-var identity first), so a
concurrent session can no longer clobber the binding (M13 live repro now a
regression test). Rejected: keeping the scalar file with a mtime heuristic —
still races, identity is the only reliable key."
```

---

### Task 3: Per-project advisory lock in `register`

**Files:**
- Modify: `scripts/context-budget.sh` — add `acquire_lock()` helper; call it from `cmd_register` when `--project` is set.
- Modify: `context-budget.env` — add the stale knob.
- Test: append T2/T3 to `scripts/tests/context-budget-registry.test.sh`.

**Interfaces:**
- Consumes: `SESSION_ID`, `PROJECT` from Task 2.
- Produces: lock file `work/<proj>/.active-session` = `{runtime, session_id, project, acquired_at}`; `LOCK_STALE="${CONTEXT_LOCK_STALE_SECS:-10800}"`. Task 4's release reads the same lock shape.

- [ ] **Step 1: Append the failing tests**

```bash
echo "T2: register --project acquires the lock; a live holder is not stolen"
LOCK="$TMP/work/testproj/.active-session"
mk_transcript aaa 50000; mk_transcript bbb 90000; touch "$PROJ_DIR/aaa.jsonl"
run_as aaa register --project testproj --quiet >/dev/null
assert_eq "T2a: lock holder is aaa" "$(jq -r .session_id "$LOCK" 2>/dev/null)" "aaa"
err=$(run_as bbb register --project testproj 2>&1 >/dev/null)
assert_eq "T2b: live lock not stolen" "$(jq -r .session_id "$LOCK")" "aaa"
assert_contains "T2c: holder warning emitted" "$err" "held by claude-aaa"

echo "T3: stale lock (holder artifact untouched for hours) is reclaimed"
touch -t 202601010000 "$PROJ_DIR/aaa.jsonl"
run_as bbb register --project testproj --quiet >/dev/null
assert_eq "T3a: stale lock reclaimed by bbb" "$(jq -r .session_id "$LOCK")" "bbb"
```

- [ ] **Step 2: Run to verify they fail**

Run: `bash scripts/tests/context-budget-registry.test.sh`
Expected: T2a fails (`--project` accepted but no lock written — or, before Task 2's flag plumbing, an unknown-option error). T1 stays green.

- [ ] **Step 3: Implement `acquire_lock()`**

Add near `cmd_register` (knob read goes next to `THRESHOLD`/`WARN` at the top: `LOCK_STALE="${CONTEXT_LOCK_STALE_SECS:-10800}"`):

```bash
lock_holder_age() {
  # Age in seconds of the lock holder's artifact (its liveness signal), via the
  # holder's own session file; empty when unknowable (treated as stale — a
  # holder with no session record cannot be confirmed live).
  local rt="$1" sid="$2" af mt
  af=$(jq -r '.artifact // empty' "$STATE_DIR/sessions/$rt-$sid.json" 2>/dev/null)
  [ -n "$af" ] && [ -f "$af" ] || return 1
  mt=$(stat -f%m "$af" 2>/dev/null || stat -c%Y "$af" 2>/dev/null) || return 1
  echo $(( $(date +%s) - mt ))
}

acquire_lock() {
  local dir="$WORKSPACE_ROOT/work/$PROJECT" lock hrt hsid age
  [ -d "$dir" ] || die "no such work directory: work/$PROJECT"
  lock="$dir/.active-session"
  if [ -f "$lock" ]; then
    hrt=$(jq -r '.runtime // empty' "$lock" 2>/dev/null)
    hsid=$(jq -r '.session_id // empty' "$lock" 2>/dev/null)
    if [ "$hrt-$hsid" != "$RUNTIME-$SESSION_ID" ]; then
      if age=$(lock_holder_age "$hrt" "$hsid") && [ "$age" -lt "$LOCK_STALE" ]; then
        note "lock: work/$PROJECT/.active-session held by $hrt-$hsid (artifact active ${age}s ago); NOT acquired — one active session per work item"
        return 0
      fi
      note "lock: reclaiming stale lock from $hrt-$hsid"
    fi
  fi
  jq -n --arg rt "$RUNTIME" --arg sid "$SESSION_ID" --arg proj "$PROJECT" \
    --arg ts "$(date -u +%FT%TZ)" \
    '{runtime:$rt, session_id:$sid, project:$proj, acquired_at:$ts}' > "$lock"
  note "lock: acquired work/$PROJECT/.active-session as $RUNTIME-$SESSION_ID"
}
```

In `cmd_register`, after writing the session file: `[ -n "$PROJECT" ] && acquire_lock`. Append to `context-budget.env` (with a comment matching the file's style):

```sh
# Advisory work-item lock: a holder whose session artifact is untouched for
# this many seconds is considered dead and its lock reclaimable.
CONTEXT_LOCK_STALE_SECS=10800
```

- [ ] **Step 4: Run the tests — T2/T3 green, T1 still green**

Run: `bash scripts/tests/context-budget-registry.test.sh`
Expected: exit 0, all asserts pass.

- [ ] **Step 5: Commit**

```bash
git add scripts/context-budget.sh scripts/tests/context-budget-registry.test.sh context-budget.env
git commit -m "work(automatic-session-rollover): per-project advisory lock on register --project

Decision: a held-by-live-session lock warns and skips acquisition but never
fails register — failing would kill budget tracking for the session that most
needs it; enforcement is the agent honoring the warning before single-writer
launcher/ledger writes. Staleness = holder artifact untouched
>CONTEXT_LOCK_STALE_SECS (default 3h). Rejected: hard-fail register on held
lock."
```

---

### Task 4: `release` subcommand + rollover-skill integration

**Files:**
- Modify: `scripts/context-budget.sh` — new `cmd_release`, dispatch entry, usage comment.
- Modify: `skills/session-rollover/SKILL.md` — one line in the post-verification closing step.
- Test: append T4 to the test file.

**Interfaces:**
- Consumes: lock shape + `PROJECT`/`SESSION_ID` from Task 3.
- Produces: `context-budget.sh release [--project <proj>]` — project defaults to the caller's own session-file `project`; removes the lock only when held by self.

- [ ] **Step 1: Append the failing tests**

```bash
echo "T4: release removes own lock, never another session's"
err=$(run_as aaa release --project testproj 2>&1 >/dev/null)   # bbb holds it
assert_eq "T4a: foreign lock left in place" "$(jq -r .session_id "$LOCK")" "bbb"
run_as bbb release --project testproj --quiet >/dev/null
[ ! -f "$LOCK" ] && ok "T4b: own lock released" || bad "T4b: lock still present"
run_as bbb register --project testproj --quiet >/dev/null      # project now in session file
run_as bbb release --quiet >/dev/null                          # no --project: self-derived
[ ! -f "$LOCK" ] && ok "T4c: release derives project from own session file" || bad "T4c"
```

- [ ] **Step 2: Run to verify they fail**

Run: `bash scripts/tests/context-budget-registry.test.sh`
Expected: `release` is an unknown command → the `case "${1:-}"` falls through to `check` semantics / unknown option error; T4 asserts fail. T1–T3 green.

- [ ] **Step 3: Implement `cmd_release`**

```bash
cmd_release() {
  resolve_session
  if [ -z "$PROJECT" ]; then
    PROJECT=$(jq -r '.project // empty' "$STATE_DIR/sessions/$RUNTIME-$SESSION_ID.json" 2>/dev/null)
    [ -n "$PROJECT" ] || die "release: no --project given and none recorded for this session"
  fi
  local lock="$WORKSPACE_ROOT/work/$PROJECT/.active-session" hrt hsid
  [ -f "$lock" ] || { note "release: no lock at work/$PROJECT/.active-session"; return 0; }
  hrt=$(jq -r '.runtime // empty' "$lock" 2>/dev/null)
  hsid=$(jq -r '.session_id // empty' "$lock" 2>/dev/null)
  if [ "$hrt-$hsid" = "$RUNTIME-$SESSION_ID" ]; then
    rm -f "$lock"; note "release: released work/$PROJECT/.active-session"
  else
    note "release: lock held by $hrt-$hsid, not by this session ($RUNTIME-$SESSION_ID); left in place"
  fi
}
```

Add `release` to the command `case` on line 27 (`check|register|record|watch|release`) and the dispatch `case` at the bottom (`release) cmd_release ;;`), and to the header `Usage:` line.

- [ ] **Step 4: Wire into the rollover skill**

In `skills/session-rollover/SKILL.md`, find the closing/verification step (the gate after the successor bootstrap prompt is written) and add one runtime-neutral line, e.g.:

```
After the verification gate passes, release the work-item lock:
`scripts/context-budget.sh release --project <project>` (the successor's
`register --project <project>` re-acquires it).
```

Match the skill's surrounding step formatting exactly; do not restructure the skill.

- [ ] **Step 5: Run the tests — all green**

Run: `bash scripts/tests/context-budget-registry.test.sh`
Expected: exit 0.

- [ ] **Step 6: Commit**

```bash
git add scripts/context-budget.sh scripts/tests/context-budget-registry.test.sh skills/session-rollover/SKILL.md
git commit -m "work(automatic-session-rollover): release subcommand — dying session frees the work-item lock

Decision: release defaults its project to the caller's own session record and
only ever removes a lock held by self; a foreign lock is reported and left —
the advisory model never lets one session destroy another's claim."
```

---

### Task 5: Gemini concurrent-session guard

**Files:**
- Modify: `scripts/context-budget.sh` — replace the bare telemetry reset in `cmd_register` with the guard.
- Test: append T5 to the test file.

**Interfaces:**
- Consumes: `cmd_register` shape from Task 2.
- Produces: no new interface — behavioral guard only.

- [ ] **Step 1: Append the failing tests**

```bash
echo "T5: gemini register — fresh telemetry log means a concurrent session owns it"
mkdir -p "$TMP/.gemini" "$HOME/.gemini/tmp/h0"
printf '{"note":"chat log"}' > "$HOME/.gemini/tmp/h0/logs.json"
printf '{"gen_ai.usage.input_tokens": 42}\n' > "$TMP/.gemini/telemetry.log"   # fresh + non-empty
err=$("$CB" register --runtime gemini 2>&1 >/dev/null)
[ -s "$TMP/.gemini/telemetry.log" ] && ok "T5a: fresh telemetry log NOT reset" || bad "T5a: log was reset"
assert_contains "T5b: registered estimate artifact instead" \
  "$(jq -r .artifact "$TMP/.context-budget/sessions/gemini-workspace.json")" "logs.json"
touch -t 202601010000 "$TMP/.gemini/telemetry.log"                            # now stale
"$CB" register --runtime gemini --quiet >/dev/null
[ ! -s "$TMP/.gemini/telemetry.log" ] && ok "T5c: stale telemetry log reset" || bad "T5c: not reset"
```

- [ ] **Step 2: Run to verify T5a/T5b fail**

Run: `bash scripts/tests/context-budget-registry.test.sh`
Expected: T5a fails (current code always resets). T5c passes either way. T1–T4 green.

- [ ] **Step 3: Implement the guard**

Replace the gemini reset block in `cmd_register` with:

```bash
  if [ "$RUNTIME" = "gemini" ] && [ "$ARTIFACT" = "$WORKSPACE_ROOT/.gemini/telemetry.log" ]; then
    # The workspace telemetry log is shared append-only and single-session:
    # normally a session boundary resets it. But a non-empty log written in the
    # last 10 min means another live gemini session owns it — don't corrupt its
    # counts; this session degrades to estimate-only from the chat log (docs:
    # "a second concurrent gemini session falls back to estimate-only").
    local mt age
    mt=$(stat -f%m "$ARTIFACT" 2>/dev/null || stat -c%Y "$ARTIFACT" 2>/dev/null || echo 0)
    age=$(( $(date +%s) - mt ))
    if [ -s "$ARTIFACT" ] && [ "$age" -lt 600 ]; then
      note "gemini: telemetry log active ${age}s ago — concurrent session suspected; falling back to estimate-only"
      ARTIFACT=$(find "$HOME/.gemini/tmp" -name 'logs.json' 2>/dev/null | xargs ls -t 2>/dev/null | head -1)
      [ -n "$ARTIFACT" ] || die "no gemini chat log to fall back to"
    else
      : > "$ARTIFACT"
    fi
  fi
```

- [ ] **Step 4: Run the tests — all green**

Run: `bash scripts/tests/context-budget-registry.test.sh`
Expected: exit 0, T1–T5 pass.

- [ ] **Step 5: Commit**

```bash
git add scripts/context-budget.sh scripts/tests/context-budget-registry.test.sh
git commit -m "work(automatic-session-rollover): gemini concurrent-session guard on telemetry reset

Decision: a non-empty telemetry log modified <10min before register is treated
as another live gemini session's — skip the reset and degrade this session to
chat-log estimate. Rejected: always-reset (corrupts the live session's exact
counts) and per-session telemetry filtering (gemini exports no session id)."
```

---

### Task 6: Documentation + backlog close-out

**Files:**
- Modify: `docs/context-budget.md` — status notes + limitation section + session-registration section.
- Modify: `docs/template-workspace-backlog.html` — M13 card → Resolved; summary count line.
- Modify: `docs/workspace-structure.md` — only if it enumerates `.context-budget/` contents (check first with `grep -n "context-budget" docs/workspace-structure.md`).

**Interfaces:** none — prose only.

- [ ] **Step 1: Update `docs/context-budget.md`**

Three edits:
1. §"Multi-session model" status note (line ~135): replace "implementation item #1. The shipped script still uses the scalar per-runtime registry … a live wrong-measurement bug under concurrency" with "implemented 2026-08-05 (session-keyed registry + `--project` lock + `release`; regression-tested in `scripts/tests/context-budget-registry.test.sh`)".
2. §"Per-runtime adapters" → the "**Limitation — one session per runtime per workspace**" paragraph (line ~189): rewrite to past tense — the session-keyed registry shipped; the remaining limitation is gemini-only (shared telemetry log; a second concurrent gemini session degrades to estimate-only automatically). Keep the `--transcript` escape hatch sentence.
3. The earlier "Session registration" section (find with `grep -n "Session registration" docs/context-budget.md`): update the registry path to `.context-budget/sessions/<runtime>-<session-id>.json` and document `register --project <work-item>` (acquires `work/<proj>/.active-session`), `release`, and `CONTEXT_LOCK_STALE_SECS`.

- [ ] **Step 2: Update the backlog M13 card**

In `docs/template-workspace-backlog.html`: on the M13 `<div class="find med">` flip the class to `find med resolved` and the `<span class="status open">Open</span>` to `<span class="status resolved">Resolved</span>`; append a `<p><span class="fix">Fixed:</span> …</p>` naming the session-keyed registry commit and the regression test. Update the summary line (~line 87) "29 of 30 findings are resolved; M13 …" to reflect all findings resolved (adjust the sentence, don't just swap numbers blindly — read the sentence first).

- [ ] **Step 3: Verify docs consistency + run the full test file once more**

Run: `bash scripts/tests/context-budget-registry.test.sh && grep -rn "session-<runtime>" docs/ skills/ | grep -v archive`
Expected: tests exit 0; no remaining references to the scalar registry path outside archived/ledger material.

- [ ] **Step 4: Commit + push**

```bash
git add docs/context-budget.md docs/template-workspace-backlog.html docs/workspace-structure.md
git commit -m "work(automatic-session-rollover): docs + backlog — M13 resolved, multi-session model implemented"
git push
```

---

### Task 7: Tier-2 decision notes + budget record

**Files:**
- Modify: `work/automatic-session-rollover/decisions.md` — append the four implementation decisions from the "Implementation decisions" section above (gemini guard, advisory-not-blocking lock, stale knob, session-id derivation) in the file's existing note format.

- [ ] **Step 1: Append the decision notes** (match the file's existing heading/date format — read it first).
- [ ] **Step 2: Record the work-unit boundary**

Run: `scripts/context-budget.sh record --label "item #1 session-keyed registry landed"`

- [ ] **Step 3: Commit + push**

```bash
git add work/automatic-session-rollover/decisions.md work/context-decay/context-ledger.jsonl
git commit -m "work(automatic-session-rollover): decision notes for registry migration"
git push
```

---

## Self-review notes

- Spec coverage: session-keyed files (T2/Task 2), resolve-self env-first (Task 2), lock acquire/stale-reclaim (Task 3), release-after-gate (Task 4), gemini exception (Task 5), D8 successor-confirmation needs no code here — it's a read pattern for item #2's launcher script, enabled by the session files Task 2 produces. M13 closure (Task 6).
- The hook path (`--transcript` explicit) is untouched by design; verified `resolve_session` keeps the `-z "$ARTIFACT"` guard.
- `record`'s ledger row shape unchanged (session = artifact basename) — deliberate, surgical.
