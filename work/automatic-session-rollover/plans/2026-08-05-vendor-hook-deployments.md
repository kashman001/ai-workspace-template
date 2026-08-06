# Vendor Hook Deployments + Option Inheritance Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Wire the context-budget WARN/STOP push into codex, gemini, opencode, and copilot CLI (mirroring the deployed Claude Code hook), and make `launch-next-session.sh` pass the predecessor session's launch options (approval mode, model) to the successor on every runtime.

**Architecture:** A shared bash lib (`scripts/hooks/context-budget-hook-lib.sh`) holds the throttle / escalation-only / fail-open core extracted from the working claude hook; four thin per-runtime wrappers own stdin parsing and the vendor output envelope. `context-budget.sh` gains an `opencode` runtime (sqlite measurement). Option inheritance is a persist-and-replay file (`work/<project>/.rollover-options`) mapped to per-runtime flags at launch.

**Tech Stack:** bash + jq (+ sqlite3 for opencode), vendored config files per runtime (`.codex/config.toml`, `.gemini/settings.json`, `.opencode/plugins/*.js`, `.github/hooks/*.json`).

## Global Constraints

- ADR-0003/0004 govern: hybrid trigger — WARN asks, STOP automatic; knobs workspace-level only; vendor specifics live only in `scripts/` + vendor config files; skills stay runtime-neutral.
- Every hook is **escalation-only** (speaks only when status rank increases vs the recorded previous status), **throttled** (one real check per `CHECK_EVERY`, default 60s), and **fail-open** (any error ⇒ silent success; a hook must never block real work).
- Exit codes 1/2 from `context-budget.sh check` mean WARN/STOP, **not failure** — never `|| exit` on that command substitution.
- gemini hooks: **JSON-only stdout** (print `{}` when silent, never plain text).
- opencode appended Parts MUST carry `id`, `sessionID`, `messageID` (bare `{type,text}` kills the whole turn — smoke-test-opencode.md §2a).
- copilot: block via `agentStop` **only at STOP** and never when `stop_hook_active` is true (8-block loop guard); `additionalContext` is discounted by the model — phrase as tooling status.
- Vendor flags must be verified against the live `--help` before wiring (a nonexistent flag already slipped into `launch-next-session.sh` once — its header comment says so).
- Standing push-to-main approval applies. Tests live in `scripts/tests/`, self-contained mktemp harness style (see `scripts/tests/test-launch-next-session.sh`).
- This template ships agent-agnostic and fully documented for downloaders (project memory): every deployment is a committed file + docs, not local-only state.
- macOS default bash is 3.2: `"${ARR[@]}"` on an empty array errors under `set -u` — use the `${ARR[@]+"${ARR[@]}"}` expansion form wherever an array may be empty.

## File Structure

| File | Action | Responsibility |
|---|---|---|
| `scripts/hooks/context-budget-hook-lib.sh` | create | shared core: throttle, escalation state, check invocation, canonical WARN/STOP text |
| `scripts/hooks/context-budget-claude-hook.sh` | modify | becomes a thin wrapper sourcing the lib (stderr + exit 2 envelope) |
| `scripts/hooks/context-budget-codex-hook.sh` | create | codex `UserPromptSubmit` wrapper → `hookSpecificOutput.additionalContext` JSON |
| `scripts/hooks/context-budget-gemini-hook.sh` | create | gemini `BeforeAgent` wrapper → JSON-only stdout |
| `scripts/hooks/context-budget-opencode-hook.sh` | create | opencode wrapper: argv sessionID → plain-text message (plugin wraps it) |
| `scripts/hooks/context-budget-copilot-hook.sh` | create | copilot `sessionStart`/`agentStop` wrapper (event as argv) |
| `scripts/context-budget.sh` | modify | add `opencode` runtime: discover/measure (sqlite) + identity |
| `.codex/config.toml` | create | codex hook wiring |
| `.gemini/settings.json` | modify | add `BeforeAgent` hook — preserve graphify `BeforeTool` + telemetry |
| `.opencode/plugins/context-budget.js` | create | `chat.message` part-append plugin calling the opencode wrapper |
| `.github/hooks/context-budget.json` | create | copilot CLI hook wiring |
| `scripts/launch-next-session.sh` | modify | read `.rollover-options`, map to per-runtime flags |
| `skills/session-rollover/SKILL.md` | modify | rollover step: write `.rollover-options` |
| `scripts/tests/test-vendor-budget-hooks.sh` | create | lib + all five wrappers + opencode measurement tests |
| `scripts/tests/test-launch-next-session.sh` | modify | option-inheritance tests |
| `docs/context-budget.md`, `CLAUDE.md`, `docs/template-workspace-backlog.html`, `work/automatic-session-rollover/decisions.md` | modify | docs, backlog rows, Tier-2 decision notes |

---

### Task 1: Shared hook lib extracted from the claude hook

**Files:**
- Create: `scripts/hooks/context-budget-hook-lib.sh`
- Modify: `scripts/hooks/context-budget-claude-hook.sh`
- Test: `scripts/tests/test-vendor-budget-hooks.sh`

**Interfaces:**
- Produces: `budget_hook_check <runtime> <session_id> [transcript]` — prints `"STATUS TOKENS THRESHOLD"` (single line, space-separated) on escalation, prints nothing otherwise, always returns 0. Honors env `CHECK_EVERY` (seconds, default 60) and `WORKSPACE_ROOT` (default: two dirs above the lib). State files: `$WORKSPACE_ROOT/.context-budget/hook-<runtime>-<session_id>.{stamp,status}`.
- Produces: `budget_hook_message <STATUS> <tokens> <threshold>` — prints the canonical WARN or STOP text (used verbatim by all wrappers).
- Consumes: `scripts/context-budget.sh check --runtime <rt> [--transcript <path>] --quiet` (exists; exit 0/1/2 = OK/WARN/STOP, line format `runtime=… tokens=… threshold=… status=…`).

- [ ] **Step 1: Write the failing test harness + lib tests**

Create `scripts/tests/test-vendor-budget-hooks.sh` (executable). Harness: mktemp workspace, real hooks copied in, **stub** `context-budget.sh` driven by `FAKE_STATUS`/`FAKE_TOKENS` env:

```bash
#!/usr/bin/env bash
# File: scripts/tests/test-vendor-budget-hooks.sh
# Purpose: Regression tests for the context-budget vendor hook wrappers and
#          their shared lib (ADR-0003/0004 item #3). Self-contained: throwaway
#          workspace in mktemp -d, stub context-budget.sh driven by FAKE_* env.
set -u
SRC_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/scripts/hooks" "$TMP/.context-budget"
cp "$SRC_ROOT"/scripts/hooks/context-budget-*.sh "$TMP/scripts/hooks/" 2>/dev/null || true
cat > "$TMP/scripts/context-budget.sh" <<'STUB'
#!/usr/bin/env bash
[ "${1:-}" = "check" ] || exit 0
st="${FAKE_STATUS:-OK}"; tk="${FAKE_TOKENS:-1000}"
echo "runtime=stub method=exact tokens=$tk threshold=150000 warn=120000 pct=1 status=$st artifact=/dev/null"
case "$st" in OK) exit 0 ;; WARN) exit 1 ;; STOP) exit 2 ;; esac
STUB
chmod +x "$TMP/scripts/context-budget.sh"
touch "$TMP/fake-transcript"
cd "$TMP"
HOOKS="$TMP/scripts/hooks"

PASS=0; FAIL=0
ok()  { PASS=$((PASS+1)); echo "  ok: $1"; }
bad() { FAIL=$((FAIL+1)); echo "  FAIL: $1" >&2; }
assert_eq() { [ "$2" = "$3" ] && ok "$1" || bad "$1 (want [$3] got [$2])"; }
assert_contains() { case "$2" in *"$3"*) ok "$1" ;; *) bad "$1 (no [$3] in [$2])" ;; esac; }
assert_empty() { [ -z "$2" ] && ok "$1" || bad "$1 (expected empty, got [$2])"; }
reset_state() { rm -f "$TMP/.context-budget"/hook-*; }
# Each lib call in a fresh subshell so sourcing is isolated.
libcheck() { ( . "$HOOKS/context-budget-hook-lib.sh"; budget_hook_check "$@" ); }

echo "T1: lib escalation-only semantics"
reset_state
out=$(CHECK_EVERY=0 FAKE_STATUS=OK libcheck claude s1); assert_empty "T1a: OK silent" "$out"
out=$(CHECK_EVERY=0 FAKE_STATUS=WARN FAKE_TOKENS=125000 libcheck claude s1)
assert_eq "T1b: OK->WARN speaks" "$out" "WARN 125000 150000"
out=$(CHECK_EVERY=0 FAKE_STATUS=WARN FAKE_TOKENS=126000 libcheck claude s1)
assert_empty "T1c: WARN->WARN silent" "$out"
out=$(CHECK_EVERY=0 FAKE_STATUS=STOP FAKE_TOKENS=151000 libcheck claude s1)
assert_eq "T1d: WARN->STOP speaks" "$out" "STOP 151000 150000"
out=$(CHECK_EVERY=0 FAKE_STATUS=WARN FAKE_TOKENS=126000 libcheck claude s1)
assert_empty "T1e: STOP->WARN silent (never de-escalates loudly)" "$out"

echo "T2: lib throttle"
reset_state
out=$(CHECK_EVERY=9999 FAKE_STATUS=WARN FAKE_TOKENS=125000 libcheck claude s2)
assert_eq "T2a: first call runs" "$out" "WARN 125000 150000"
out=$(CHECK_EVERY=9999 FAKE_STATUS=STOP FAKE_TOKENS=151000 libcheck claude s2)
assert_empty "T2b: second call inside window is throttled" "$out"

echo "T3: lib fail-open"
reset_state
chmod -x "$TMP/scripts/context-budget.sh"
out=$(CHECK_EVERY=0 FAKE_STATUS=WARN libcheck claude s3); rc=$?
assert_eq "T3a: broken check script -> rc 0" "$rc" "0"
assert_empty "T3b: broken check script -> silent" "$out"
chmod +x "$TMP/scripts/context-budget.sh"

echo "T4: claude wrapper envelope preserved"
reset_state
payload="{\"session_id\":\"s4\",\"transcript_path\":\"$TMP/fake-transcript\"}"
err=$(echo "$payload" | CHECK_EVERY=0 FAKE_STATUS=WARN FAKE_TOKENS=125000 \
      "$HOOKS/context-budget-claude-hook.sh" 2>&1 >/dev/null); rc=$?
assert_eq "T4a: WARN exits 2" "$rc" "2"
assert_contains "T4b: WARN text on stderr" "$err" "CONTEXT BUDGET WARN: this session is at 125000 tokens"
reset_state
err=$(echo "$payload" | CHECK_EVERY=0 FAKE_STATUS=OK \
      "$HOOKS/context-budget-claude-hook.sh" 2>&1 >/dev/null); rc=$?
assert_eq "T4c: OK exits 0" "$rc" "0"
assert_empty "T4d: OK silent" "$err"

echo; echo "pass=$PASS fail=$FAIL"; [ "$FAIL" -eq 0 ]
```

Later tasks append their test blocks BEFORE the final `echo; echo "pass=…"` summary line.

- [ ] **Step 2: Run the test to verify it fails**

Run: `bash scripts/tests/test-vendor-budget-hooks.sh`
Expected: FAIL — `context-budget-hook-lib.sh` does not exist (source error), claude wrapper doesn't honor `CHECK_EVERY`/stub.

- [ ] **Step 3: Write the lib**

```bash
#!/usr/bin/env bash
# File: scripts/hooks/context-budget-hook-lib.sh
# Purpose: shared core for the per-runtime context-budget hook wrappers
#          (claude/codex/gemini/opencode/copilot). Sourced, not executed.
#          Escalation-only, throttled, fail-open — the wrapper owns stdin
#          parsing and the vendor output envelope, nothing else.
#   budget_hook_check <runtime> <session_id> [transcript]
#     prints "STATUS TOKENS THRESHOLD" on escalation, else nothing; rc 0 always.
#   budget_hook_message <STATUS> <tokens> <threshold>
#     prints the canonical WARN/STOP text.

BUDGET_HOOK_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_ROOT="${WORKSPACE_ROOT:-$(cd "$BUDGET_HOOK_LIB_DIR/../.." && pwd)}"
BUDGET_STATE_DIR="$WORKSPACE_ROOT/.context-budget"
CHECK_EVERY="${CHECK_EVERY:-60}"

budget_hook_rank() { case "$1" in STOP) echo 2 ;; WARN) echo 1 ;; *) echo 0 ;; esac; }

budget_hook_check() {
  local runtime="$1" session_id="${2:-unknown}" transcript="${3:-}"
  [ -n "$session_id" ] || session_id="unknown"
  mkdir -p "$BUDGET_STATE_DIR" 2>/dev/null || return 0
  local stamp="$BUDGET_STATE_DIR/hook-$runtime-$session_id.stamp"
  local state="$BUDGET_STATE_DIR/hook-$runtime-$session_id.status"
  if [ -f "$stamp" ]; then
    local now last
    now=$(date +%s)
    last=$(stat -f%m "$stamp" 2>/dev/null || stat -c%Y "$stamp" 2>/dev/null || echo 0)
    [ $(( now - last )) -lt "$CHECK_EVERY" ] && return 0
  fi
  touch "$stamp"
  # PITFALL: exit codes 1/2 mean WARN/STOP, not failure — no `|| return` here.
  local line
  if [ -n "$transcript" ]; then
    line=$("$WORKSPACE_ROOT/scripts/context-budget.sh" check \
            --runtime "$runtime" --transcript "$transcript" --quiet 2>/dev/null) || true
  else
    line=$("$WORKSPACE_ROOT/scripts/context-budget.sh" check \
            --runtime "$runtime" --quiet 2>/dev/null) || true
  fi
  [ -n "$line" ] || return 0
  local status tokens threshold prev
  status=$(echo "$line" | grep -o 'status=[A-Z]*' | cut -d= -f2)
  tokens=$(echo "$line" | grep -o 'tokens=[0-9]*' | cut -d= -f2)
  threshold=$(echo "$line" | grep -o 'threshold=[0-9]*' | cut -d= -f2)
  [ -n "$status" ] || return 0
  prev="OK"; [ -f "$state" ] && prev=$(cat "$state")
  echo "$status" > "$state"
  [ "$(budget_hook_rank "$status")" -le "$(budget_hook_rank "$prev")" ] && return 0
  echo "$status $tokens $threshold"
  return 0
}

budget_hook_message() {
  local status="$1" tokens="$2" threshold="$3"
  if [ "$status" = "STOP" ]; then
    echo "CONTEXT BUDGET STOP: this session is at $tokens tokens, past the $threshold-token dumb-zone threshold. Finish the current atomic step only, then tell the user and run the session-rollover workflow (skills/session-rollover/SKILL.md). Do not start new work in this session."
  else
    echo "CONTEXT BUDGET WARN: this session is at $tokens tokens, approaching the $threshold-token dumb-zone threshold. Wrap up the current work unit and avoid loading large files; prepare to run the session-rollover workflow (skills/session-rollover/SKILL.md) soon. Mention this warning to the user in your next reply."
  fi
}
```

- [ ] **Step 4: Refactor the claude hook to a thin wrapper**

Replace `scripts/hooks/context-budget-claude-hook.sh` with:

```bash
#!/usr/bin/env bash
# File: scripts/hooks/context-budget-claude-hook.sh
# Purpose: Claude Code PostToolUse hook — in-band WARN/STOP message to the agent
#          when the session crosses the context-budget threshold. Core logic
#          (throttle, escalation-only, fail-open) lives in
#          context-budget-hook-lib.sh, shared with the other runtimes' wrappers.
# Wiring:  .claude/settings.json "hooks" (see .claude/settings.json.example).
set -u
command -v jq >/dev/null 2>&1 || exit 0
. "$(cd "$(dirname "$0")" && pwd)/context-budget-hook-lib.sh"
input=$(cat)
session_id=$(echo "$input" | jq -r '.session_id // empty')
transcript=$(echo "$input" | jq -r '.transcript_path // empty')
[ -n "$transcript" ] && [ -f "$transcript" ] || exit 0
out=$(budget_hook_check claude "$session_id" "$transcript")
[ -n "$out" ] || exit 0
read -r status tokens threshold <<<"$out"
budget_hook_message "$status" "$tokens" "$threshold" >&2
exit 2
```

Behavior parity note: the state-file names change from `hook-<sid>.*` to `hook-claude-<sid>.*`; stale old files in `.context-budget/` are harmless (dir is gitignored). Message strings are byte-identical to the pre-refactor hook.

- [ ] **Step 5: Run the tests, verify T1–T4 pass**

Run: `bash scripts/tests/test-vendor-budget-hooks.sh`
Expected: `pass=… fail=0`.

- [ ] **Step 6: Commit**

```bash
git add scripts/hooks/context-budget-hook-lib.sh scripts/hooks/context-budget-claude-hook.sh scripts/tests/test-vendor-budget-hooks.sh
git commit -m "refactor(rollover): extract shared context-budget hook lib from claude hook

Decision: one copy of throttle/escalation/fail-open logic for five runtime
wrappers beats four near-duplicates; claude wrapper keeps stderr+exit-2
envelope and byte-identical messages."
```

---

### Task 2: `opencode` runtime in context-budget.sh

**Files:**
- Modify: `scripts/context-budget.sh` (usage comment line 8; `discover_for`/`measure_for`/`session_id_for`/`detect_runtime` cases; new `opencode_discover`/`opencode_measure` beside the other measure fns)
- Test: `scripts/tests/test-vendor-budget-hooks.sh` (append T9)

**Interfaces:**
- Consumes: env `OPENCODE_SESSION_ID` (exported by the opencode wrapper in Task 5); sqlite db `~/.local/share/opencode/opencode.db` — schema live-verified 2026-08-05: `session(id text pk, directory text, time_updated integer, tokens_input/tokens_output/tokens_reasoning/tokens_cache_read integer)`, `message(id text pk, session_id text, data text)` with `data` JSON carrying `tokens.total` on assistant rows.
- Produces: `context-budget.sh check --runtime opencode [--transcript <db-path>]` works end-to-end (method `exact`).

- [ ] **Step 1: Append failing test T9** (before the summary line; uses the REAL script — first read `scripts/tests/test-context-budget-registry.sh`'s setup block and mirror exactly how it copies `context-budget.sh` + `context-budget.env` into a temp workspace and what exit code `die` produces, then adapt the literals below to match):

```bash
echo "T9: opencode runtime measurement (real script, fake sqlite db)"
if command -v sqlite3 >/dev/null 2>&1; then
  OTMP="$(mktemp -d)"
  mkdir -p "$OTMP/scripts" "$OTMP/.context-budget/sessions"
  cp "$SRC_ROOT/scripts/context-budget.sh" "$OTMP/scripts/"
  cp "$SRC_ROOT/context-budget.env" "$OTMP/" 2>/dev/null || true
  DB="$OTMP/opencode.db"
  sqlite3 "$DB" <<'SQL'
CREATE TABLE session (id text PRIMARY KEY, directory text, time_updated integer,
  tokens_input integer DEFAULT 0, tokens_output integer DEFAULT 0,
  tokens_reasoning integer DEFAULT 0, tokens_cache_read integer DEFAULT 0);
CREATE TABLE message (id text PRIMARY KEY, session_id text, data text);
INSERT INTO session VALUES ('ses_test','/tmp',0,128,9,31,12416);
INSERT INTO message VALUES ('msg_1','ses_test',
  '{"role":"assistant","tokens":{"total":12584,"input":128,"output":9,"reasoning":31,"cache":{"write":0,"read":12416}}}');
INSERT INTO message VALUES ('msg_2','ses_other',
  '{"role":"assistant","tokens":{"total":999999}}');
SQL
  out=$(cd "$OTMP" && OPENCODE_SESSION_ID=ses_test \
        ./scripts/context-budget.sh check --runtime opencode --transcript "$DB" 2>&1); rc=$?
  assert_contains "T9a: exact token count from message.data" "$out" "tokens=12584"
  assert_contains "T9b: method exact" "$out" "method=exact"
  assert_eq "T9c: OK exit code" "$rc" "0"
  out=$(cd "$OTMP" && OPENCODE_SESSION_ID=ses_missing \
        ./scripts/context-budget.sh check --runtime opencode --transcript "$DB" 2>&1); rc=$?
  [ "$rc" -ne 0 ] && [ "$rc" -ne 1 ] && [ "$rc" -ne 2 ] \
    && ok "T9d: unknown session -> error exit" || bad "T9d: unknown session -> error exit (rc=$rc)"
  rm -rf "$OTMP"
else
  echo "  skip: sqlite3 not available"
fi
```

- [ ] **Step 2: Run — verify T9 fails** (`--runtime opencode` currently dies: unknown runtime / measurement failed).

- [ ] **Step 3: Implement the opencode branch**

Add beside the other measure functions in `scripts/context-budget.sh`:

```bash
opencode_discover() {
  local db="$HOME/.local/share/opencode/opencode.db"
  [ -f "$db" ] && echo "$db"
}

opencode_measure() {
  # $1 = opencode.db (sqlite, verified v1.18.14). Context size = last assistant
  # message's tokens.total (= input+output+reasoning+cache.read) for the
  # session in OPENCODE_SESSION_ID (exported by the chat.message plugin);
  # fallback: newest session for this cwd. No size-estimate fallback — the
  # shared db spans all sessions, its size says nothing about one context.
  local db="$1" sid="${OPENCODE_SESSION_ID:-}" tokens
  command -v sqlite3 >/dev/null 2>&1 || return 1
  [ -n "$sid" ] || sid=$(sqlite3 "$db" \
    "select id from session where directory='$PWD' order by time_updated desc limit 1" 2>/dev/null)
  [ -n "$sid" ] || return 1
  tokens=$(sqlite3 "$db" "select json_extract(data,'\$.tokens.total') from message
    where session_id='$sid' and json_extract(data,'\$.tokens.total') is not null
    order by rowid desc limit 1" 2>/dev/null)
  if [ -z "$tokens" ]; then
    tokens=$(sqlite3 "$db" "select tokens_input+tokens_output+tokens_reasoning+tokens_cache_read
      from session where id='$sid'" 2>/dev/null)
  fi
  [ -n "$tokens" ] && echo "$tokens exact" || return 1
}
```

Wire the cases:
- `discover_for`: add `opencode) opencode_discover ;;`
- `measure_for`: add `opencode) opencode_measure "$2" ;;`
- `session_id_for`: in the env-first case block add `opencode) [ -n "${OPENCODE_SESSION_ID:-}" ] && { echo "$OPENCODE_SESSION_ID"; return 0; } ;;` (artifact-derived: falls through to the existing `*) return 1` — a db path encodes no session).
- `detect_runtime`: after the codex env check add `if [ -n "${OPENCODE_SESSION_ID:-}" ]; then echo "opencode"; return; fi`. Do NOT add opencode to the freshest-artifact fallback loop — the db's mtime changes on any opencode activity and would shadow other runtimes' discovery.
- Usage comment (line 8): add `opencode` to the runtime list.

- [ ] **Step 4: Run tests — T9 green; also run `bash scripts/tests/test-context-budget-registry.sh` to confirm no regression.**

- [ ] **Step 5: Commit**

```bash
git add scripts/context-budget.sh scripts/tests/test-vendor-budget-hooks.sh
git commit -m "feat(rollover): opencode runtime for context-budget.sh (sqlite measurement)

Decision: measure from message.data tokens.total (verified per-turn context
reading) with session-column sum fallback; no size-estimate fallback — the
shared db spans all sessions. opencode joins detect_runtime via env only,
not the freshest-artifact loop, to avoid shadowing other runtimes."
```

---

### Task 3: codex deployment (`UserPromptSubmit`)

**Files:**
- Create: `scripts/hooks/context-budget-codex-hook.sh`, `.codex/config.toml`
- Test: `scripts/tests/test-vendor-budget-hooks.sh` (append T5)

**Interfaces:**
- Consumes: stdin JSON with `session_id`, `transcript_path` (Claude-compatible payload, vendor-hooks-research §1); `budget_hook_check`/`budget_hook_message` from Task 1.
- Produces: on escalation, stdout JSON `{"hookSpecificOutput":{"hookEventName":"UserPromptSubmit","additionalContext":"<msg>"}}`, exit 0; silent otherwise (empty stdout, exit 0).

- [ ] **Step 1: Append failing test T5**

```bash
echo "T5: codex wrapper JSON envelope"
reset_state
payload="{\"session_id\":\"s5\",\"transcript_path\":\"$TMP/fake-transcript\"}"
out=$(echo "$payload" | CHECK_EVERY=0 FAKE_STATUS=WARN FAKE_TOKENS=125000 \
      "$HOOKS/context-budget-codex-hook.sh"); rc=$?
assert_eq "T5a: exit 0" "$rc" "0"
ctx=$(echo "$out" | jq -r '.hookSpecificOutput.additionalContext')
assert_contains "T5b: additionalContext carries WARN text" "$ctx" "CONTEXT BUDGET WARN"
assert_eq "T5c: hookEventName" "$(echo "$out" | jq -r '.hookSpecificOutput.hookEventName')" "UserPromptSubmit"
reset_state
out=$(echo "$payload" | CHECK_EVERY=0 FAKE_STATUS=OK "$HOOKS/context-budget-codex-hook.sh")
assert_empty "T5d: OK silent" "$out"
```

- [ ] **Step 2: Run — T5 fails (wrapper missing).**

- [ ] **Step 3: Write the wrapper** (`chmod +x`)

```bash
#!/usr/bin/env bash
# File: scripts/hooks/context-budget-codex-hook.sh
# Purpose: Codex CLI UserPromptSubmit hook — same WARN/STOP push as the claude
#          hook, emitted as Claude-compatible hookSpecificOutput JSON.
# Wiring:  .codex/config.toml [[hooks.UserPromptSubmit]]. Codex trust gate:
#          first run in this repo prompts to trust the hook (hash-recorded;
#          editing this file re-prompts). CI: --dangerously-bypass-hook-trust.
set -u
command -v jq >/dev/null 2>&1 || exit 0
. "$(cd "$(dirname "$0")" && pwd)/context-budget-hook-lib.sh"
input=$(cat)
session_id=$(echo "$input" | jq -r '.session_id // empty')
transcript=$(echo "$input" | jq -r '.transcript_path // empty')
[ -n "$transcript" ] && [ -f "$transcript" ] || exit 0
out=$(budget_hook_check codex "$session_id" "$transcript")
[ -n "$out" ] || exit 0
read -r status tokens threshold <<<"$out"
jq -n --arg ctx "$(budget_hook_message "$status" "$tokens" "$threshold")" \
  '{hookSpecificOutput:{hookEventName:"UserPromptSubmit",additionalContext:$ctx}}'
exit 0
```

- [ ] **Step 4: Write `.codex/config.toml`**

```toml
# Codex CLI repo config — context-budget WARN/STOP push (ADR-0003/0004).
# Trust: codex prompts once to trust this hook (hash-based; re-prompts on edit).
[[hooks.UserPromptSubmit]]
[[hooks.UserPromptSubmit.hooks]]
type = "command"
command = "scripts/hooks/context-budget-codex-hook.sh"
timeout = 30
```

Assumption (record in decisions.md if it survives the smoke check): hook commands run with cwd = session cwd, and sessions start at the workspace root — the same assumption the gemini graphify hook already relies on with its relative paths.

- [ ] **Step 5: Run tests — T5 green.**

- [ ] **Step 6: Live smoke check (codex installed):** from the workspace root run `codex exec --dangerously-bypass-hook-trust "Reply with exactly OK"`; confirm the turn completes with no hook error (budget is OK so the hook must be invisible). If codex rejects the config shape, fix per the error text before committing.

- [ ] **Step 7: Commit**

```bash
git add scripts/hooks/context-budget-codex-hook.sh .codex/config.toml scripts/tests/test-vendor-budget-hooks.sh
git commit -m "feat(rollover): codex UserPromptSubmit context-budget hook"
```

---

### Task 4: gemini deployment (`BeforeAgent`)

**Files:**
- Create: `scripts/hooks/context-budget-gemini-hook.sh`
- Modify: `.gemini/settings.json` (add `BeforeAgent` — MUST preserve the existing graphify `BeforeTool` hook and `telemetry` block)
- Test: `scripts/tests/test-vendor-budget-hooks.sh` (append T6 + T10)

**Interfaces:**
- Consumes: stdin JSON with `session_id` (bundled v0.46.0 reference.md base fields: `session_id`, `transcript_path`, `cwd`); lib from Task 1.
- Produces: JSON-only stdout — `{}` when silent; `{"hookSpecificOutput":{"additionalContext":"<msg>"}}` on escalation (BeforeAgent: additionalContext is appended to the turn's prompt). Always exit 0.
- Measurement: does NOT pass `--transcript` — gemini's exact reading comes from the telemetry log discovery already wired in `.gemini/settings.json` (the payload transcript is a chat JSON with no token counts; passing it would degrade `exact` → size estimate).

- [ ] **Step 1: Append failing tests T6 + T10**

```bash
echo "T6: gemini wrapper JSON-only stdout"
reset_state
out=$(echo '{"session_id":"s6"}' | CHECK_EVERY=0 FAKE_STATUS=OK "$HOOKS/context-budget-gemini-hook.sh"); rc=$?
assert_eq "T6a: silent case prints {}" "$out" "{}"
assert_eq "T6b: exit 0" "$rc" "0"
reset_state
out=$(echo '{"session_id":"s6"}' | CHECK_EVERY=0 FAKE_STATUS=STOP FAKE_TOKENS=151000 \
      "$HOOKS/context-budget-gemini-hook.sh")
echo "$out" | jq -e . >/dev/null 2>&1 && ok "T6c: stdout is valid JSON" || bad "T6c: stdout is valid JSON"
assert_contains "T6d: STOP text present" "$(echo "$out" | jq -r '.hookSpecificOutput.additionalContext')" "CONTEXT BUDGET STOP"

echo "T10: repo .gemini/settings.json carries both hooks"
S="$SRC_ROOT/.gemini/settings.json"
assert_contains "T10a: graphify BeforeTool preserved" "$(jq -r '.hooks.BeforeTool[0].hooks[0].command' "$S")" "graphify"
assert_contains "T10b: BeforeAgent budget hook wired" "$(jq -r '.hooks.BeforeAgent[0].hooks[0].command' "$S")" "context-budget-gemini-hook.sh"
assert_eq "T10c: telemetry block intact" "$(jq -r '.telemetry.enabled' "$S")" "true"
```

- [ ] **Step 2: Run — T6/T10 fail.**

- [ ] **Step 3: Write the wrapper** (`chmod +x`)

```bash
#!/usr/bin/env bash
# File: scripts/hooks/context-budget-gemini-hook.sh
# Purpose: Gemini CLI BeforeAgent hook — WARN/STOP push appended to the turn's
#          prompt. Gemini hooks demand JSON-only stdout: {} when silent.
# Wiring:  .gemini/settings.json hooks.BeforeAgent. Measurement uses the
#          workspace telemetry log (exact), NOT the payload transcript_path —
#          the chat transcript carries no token counts.
set -u
emit_silent() { printf '%s' '{}'; exit 0; }
command -v jq >/dev/null 2>&1 || emit_silent
. "$(cd "$(dirname "$0")" && pwd)/context-budget-hook-lib.sh"
input=$(cat)
session_id=$(echo "$input" | jq -r '.session_id // empty')
out=$(budget_hook_check gemini "$session_id" "")
[ -n "$out" ] || emit_silent
read -r status tokens threshold <<<"$out"
jq -nc --arg ctx "$(budget_hook_message "$status" "$tokens" "$threshold")" \
  '{hookSpecificOutput:{additionalContext:$ctx}}'
exit 0
```

- [ ] **Step 4: Edit `.gemini/settings.json`** — add a `BeforeAgent` key to the existing `hooks` object (do not touch `BeforeTool` or `telemetry`):

```json
"BeforeAgent": [
  {
    "hooks": [
      {
        "type": "command",
        "command": "scripts/hooks/context-budget-gemini-hook.sh"
      }
    ]
  }
]
```

- [ ] **Step 5: Run tests — T6 + T10 green.**

- [ ] **Step 6: Live smoke check (gemini installed):** from the workspace root run `gemini -p "Reply with exactly OK"`; confirm the turn completes and no hook JSON error appears (budget OK ⇒ hook invisible).

- [ ] **Step 7: Commit**

```bash
git add scripts/hooks/context-budget-gemini-hook.sh .gemini/settings.json scripts/tests/test-vendor-budget-hooks.sh
git commit -m "feat(rollover): gemini BeforeAgent context-budget hook

Decision: measurement stays on the telemetry log (exact) instead of the
payload transcript_path (no token counts, would degrade to size estimate);
gemini's workspace-scoped telemetry limitation is accepted for the hook path."
```

---

### Task 5: opencode deployment (`chat.message` plugin)

**Files:**
- Create: `scripts/hooks/context-budget-opencode-hook.sh`, `.opencode/plugins/context-budget.js`
- Test: `scripts/tests/test-vendor-budget-hooks.sh` (append T7)

**Interfaces:**
- Consumes: argv `$1` = opencode sessionID (from plugin `input.sessionID`); Task 2's `--runtime opencode` (wrapper exports `OPENCODE_SESSION_ID`); lib from Task 1.
- Produces: wrapper prints the plain WARN/STOP message text on escalation, nothing otherwise, exit 0 always. Plugin appends a schema-complete text Part (`id`/`sessionID`/`messageID` mandatory — smoke-test-opencode.md §2a).

- [ ] **Step 1: Append failing test T7**

```bash
echo "T7: opencode wrapper plain-text output"
reset_state
out=$(CHECK_EVERY=0 FAKE_STATUS=WARN FAKE_TOKENS=125000 \
      "$HOOKS/context-budget-opencode-hook.sh" ses_x); rc=$?
assert_eq "T7a: exit 0" "$rc" "0"
assert_contains "T7b: WARN text" "$out" "CONTEXT BUDGET WARN: this session is at 125000 tokens"
reset_state
out=$(CHECK_EVERY=0 FAKE_STATUS=OK "$HOOKS/context-budget-opencode-hook.sh" ses_x)
assert_empty "T7c: OK silent" "$out"
out=$(CHECK_EVERY=0 FAKE_STATUS=WARN "$HOOKS/context-budget-opencode-hook.sh")
assert_empty "T7d: missing sessionID -> silent fail-open" "$out"
```

- [ ] **Step 2: Run — T7 fails.**

- [ ] **Step 3: Write the wrapper** (`chmod +x`)

```bash
#!/usr/bin/env bash
# File: scripts/hooks/context-budget-opencode-hook.sh
# Purpose: called by .opencode/plugins/context-budget.js on each user message
#          with the sessionID; prints the WARN/STOP text on escalation (plugin
#          appends it as an in-band message Part), nothing otherwise.
set -u
sid="${1:-}"
[ -n "$sid" ] || exit 0
. "$(cd "$(dirname "$0")" && pwd)/context-budget-hook-lib.sh"
export OPENCODE_SESSION_ID="$sid"
out=$(budget_hook_check opencode "$sid" "")
[ -n "$out" ] || exit 0
read -r status tokens threshold <<<"$out"
budget_hook_message "$status" "$tokens" "$threshold"
exit 0
```

- [ ] **Step 4: Write the plugin** — first read `.opencode/plugins/graphify.js` and match its export /`$` idiom; shape below is the smoke-tested one (smoke-test-opencode.md §2a):

```js
// .opencode/plugins/context-budget.js
// Context-budget WARN/STOP push (ADR-0003/0004): on each user message, ask
// scripts/hooks/context-budget-opencode-hook.sh for an escalation message and
// inject it as an in-band text Part. Part MUST carry id/sessionID/messageID —
// a bare {type,text} part fails schema validation and kills the turn.
export const ContextBudget = async ({ $, directory }) => {
  const hook = `${directory}/scripts/hooks/context-budget-opencode-hook.sh`;
  return {
    "chat.message": async (input, output) => {
      try {
        const r = await $`${hook} ${input.sessionID}`.quiet().nothrow();
        const text = r.stdout.toString().trim();
        if (!text) return;
        output.parts.push({
          id: "prt_budget" + Date.now().toString(36),
          sessionID: input.sessionID,
          messageID: output.message.id,
          type: "text",
          text,
        });
      } catch {
        // fail-open: budget push must never break a turn
      }
    },
  };
};
```

- [ ] **Step 5: Run tests — T7 green.**

- [ ] **Step 6: Live smoke check (opencode installed, zero-auth free model):** from the workspace root: `opencode run -m opencode/big-pickle "Reply with exactly OK"`. Confirm the turn completes (plugin loads, budget OK ⇒ silent). Plugin/schema errors land in `~/.local/share/opencode/log/opencode.log`, not the client.

- [ ] **Step 7: Commit**

```bash
git add scripts/hooks/context-budget-opencode-hook.sh .opencode/plugins/context-budget.js scripts/tests/test-vendor-budget-hooks.sh
git commit -m "feat(rollover): opencode chat.message context-budget plugin"
```

---

### Task 6: copilot CLI deployment (`sessionStart` + `agentStop`)

**Files:**
- Create: `scripts/hooks/context-budget-copilot-hook.sh`, `.github/hooks/context-budget.json`
- Test: `scripts/tests/test-vendor-budget-hooks.sh` (append T8)

**Interfaces:**
- Consumes: argv `$1` = event (`sessionStart`|`agentStop`); stdin JSON — `sessionStart`: `{sessionId, cwd, source, initialPrompt}` (NO transcriptPath — derive `~/.copilot/session-state/<sessionId>/events.jsonl`); `agentStop`: `{sessionId, transcriptPath, stopReason, stop_hook_active}` (smoke-test-copilot.md §4d). Lib from Task 1; runtime `copilot-cli` already exists in context-budget.sh.
- Produces: `sessionStart` escalation → `{"additionalContext":"<msg>"}`; `agentStop` → `{"decision":"block","reason":"<STOP msg>"}` ONLY at STOP escalation and only when `stop_hook_active` ≠ true. Exit 0 always.

- [ ] **Step 1: Append failing test T8**

```bash
echo "T8: copilot wrapper — additionalContext at start, block only at STOP"
reset_state
mkdir -p "$TMP/copilot-state/s8"; touch "$TMP/copilot-state/s8/events.jsonl"
start_payload='{"sessionId":"s8","cwd":"/x","source":"resume"}'
out=$(echo "$start_payload" | CHECK_EVERY=0 FAKE_STATUS=WARN FAKE_TOKENS=125000 \
      COPILOT_STATE_DIR="$TMP/copilot-state" "$HOOKS/context-budget-copilot-hook.sh" sessionStart)
assert_contains "T8a: sessionStart WARN -> additionalContext" \
  "$(echo "$out" | jq -r '.additionalContext')" "CONTEXT BUDGET WARN"
reset_state
stop_payload="{\"sessionId\":\"s8\",\"transcriptPath\":\"$TMP/fake-transcript\",\"stopReason\":\"end_turn\",\"stop_hook_active\":false}"
out=$(echo "$stop_payload" | CHECK_EVERY=0 FAKE_STATUS=WARN FAKE_TOKENS=125000 \
      "$HOOKS/context-budget-copilot-hook.sh" agentStop)
assert_empty "T8b: agentStop WARN -> silent (block only at STOP)" "$out"
out=$(echo "$stop_payload" | CHECK_EVERY=0 FAKE_STATUS=STOP FAKE_TOKENS=151000 \
      "$HOOKS/context-budget-copilot-hook.sh" agentStop)
assert_eq "T8c: agentStop STOP -> block" "$(echo "$out" | jq -r '.decision')" "block"
assert_contains "T8d: reason carries STOP text" "$(echo "$out" | jq -r '.reason')" "CONTEXT BUDGET STOP"
active_payload="{\"sessionId\":\"s8\",\"transcriptPath\":\"$TMP/fake-transcript\",\"stopReason\":\"end_turn\",\"stop_hook_active\":true}"
reset_state
out=$(echo "$active_payload" | CHECK_EVERY=0 FAKE_STATUS=STOP FAKE_TOKENS=151000 \
      "$HOOKS/context-budget-copilot-hook.sh" agentStop)
assert_empty "T8e: stop_hook_active -> never re-block" "$out"
```

Note T8b's sequencing matters: the WARN escalation is consumed silently (state records WARN), so the later STOP in T8c is still an escalation. Keep the payload order as written.

- [ ] **Step 2: Run — T8 fails.**

- [ ] **Step 3: Write the wrapper** (`chmod +x`; `COPILOT_STATE_DIR` env exists only for testability)

```bash
#!/usr/bin/env bash
# File: scripts/hooks/context-budget-copilot-hook.sh
# Purpose: Copilot CLI hooks — sessionStart pushes WARN/STOP as
#          additionalContext (model may discount it: phrased as tooling
#          status); agentStop blocks with the rollover instruction ONLY at
#          STOP (the strong lever; avoids the 8-block continuation guard).
# Wiring:  .github/hooks/context-budget.json. Repo hooks silently no-op unless
#          the folder is in ~/.copilot/config.json trustedFolders.
set -u
event="${1:-}"
command -v jq >/dev/null 2>&1 || exit 0
. "$(cd "$(dirname "$0")" && pwd)/context-budget-hook-lib.sh"
input=$(cat)
sid=$(echo "$input" | jq -r '.sessionId // empty')
[ -n "$sid" ] || exit 0
case "$event" in
  sessionStart)
    transcript="${COPILOT_STATE_DIR:-$HOME/.copilot/session-state}/$sid/events.jsonl"
    [ -f "$transcript" ] || exit 0   # fresh session: nothing to measure yet
    out=$(budget_hook_check copilot-cli "$sid" "$transcript")
    [ -n "$out" ] || exit 0
    read -r status tokens threshold <<<"$out"
    jq -n --arg ctx "$(budget_hook_message "$status" "$tokens" "$threshold")" \
      '{additionalContext:$ctx}'
    ;;
  agentStop)
    active=$(echo "$input" | jq -r '.stop_hook_active // false')
    [ "$active" = "true" ] && exit 0
    transcript=$(echo "$input" | jq -r '.transcriptPath // empty')
    [ -n "$transcript" ] && [ -f "$transcript" ] || exit 0
    out=$(budget_hook_check copilot-cli "$sid" "$transcript")
    [ -n "$out" ] || exit 0
    read -r status tokens threshold <<<"$out"
    [ "$status" = "STOP" ] || exit 0
    jq -n --arg r "$(budget_hook_message STOP "$tokens" "$threshold")" \
      '{decision:"block",reason:$r}'
    ;;
esac
exit 0
```

- [ ] **Step 4: Write `.github/hooks/context-budget.json`** (format live-verified, smoke-test-copilot.md §4b; hook cwd = session cwd):

```json
{
  "version": 1,
  "hooks": {
    "sessionStart": [
      {
        "type": "command",
        "bash": "scripts/hooks/context-budget-copilot-hook.sh sessionStart",
        "timeoutSec": 30
      }
    ],
    "agentStop": [
      {
        "type": "command",
        "bash": "scripts/hooks/context-budget-copilot-hook.sh agentStop",
        "timeoutSec": 30
      }
    ]
  }
}
```

- [ ] **Step 5: Run tests — T8 green.**

- [ ] **Step 6: Live smoke check (copilot installed, gh auth works):** ensure this workspace is in `~/.copilot/config.json` `trustedFolders` (add it if absent — report that in the session summary); then from the workspace root: `GH_TOKEN=$(gh auth token) copilot -p "Reply with exactly OK" --allow-all-tools`; confirm the turn completes (budget OK ⇒ hooks silent).

- [ ] **Step 7: Commit**

```bash
git add scripts/hooks/context-budget-copilot-hook.sh .github/hooks/context-budget.json scripts/tests/test-vendor-budget-hooks.sh
git commit -m "feat(rollover): copilot CLI sessionStart/agentStop context-budget hooks

Decision: block only at STOP escalation via agentStop (strong lever; WARN has
no reliable in-band mid-session channel — additionalContext is
model-discounted), guarded by stop_hook_active to never fight the 8-block
continuation limit."
```

---

### Task 7: successor option inheritance (all runtimes)

**Files:**
- Modify: `scripts/launch-next-session.sh` (options file read + per-runtime flag mapping, spliced into the existing `case "$RUNTIME"` argv build at lines 107–117)
- Modify: `skills/session-rollover/SKILL.md` (rollover writes the options file)
- Test: `scripts/tests/test-launch-next-session.sh` (append option-inheritance tests)

**Interfaces:**
- Produces: file convention `work/<project>/.rollover-options` (committed, env format), written at rollover, read at launch:
  - `ROLLOVER_OPT_APPROVAL=default|auto|full` — normalized approval mode of the predecessor.
  - `ROLLOVER_OPT_MODEL=<model-id>` — optional; empty/absent = runtime default.
  - `ROLLOVER_OPT_EXTRA=<raw args>` — optional runtime-specific escape hatch, appended verbatim (word-split).
- Flag mapping (VERIFY each against live `--help` in Step 3 before wiring; correct table + tests to the shipped reality — do not guess):

| approval | claude | codex | gemini | opencode | copilot |
|---|---|---|---|---|---|
| `auto` | `--permission-mode acceptEdits` | `--full-auto` | `--approval-mode auto_edit` | `--auto` (if the TUI command lacks it, drop approval mapping for opencode) | `--allow-all-tools` |
| `full` | `--dangerously-skip-permissions` | `--dangerously-bypass-approvals-and-sandbox` | `--yolo` | `--auto` | `--allow-all` |
| model | `--model <m>` | `--model <m>` | `--model <m>` | `--model <m>` | `--model <m>` |

- [ ] **Step 1: Append failing tests to `scripts/tests/test-launch-next-session.sh`** (reuse its `run_lns`/`mk_record`/assert helpers; continue the existing test numbering — rename `T20…` below to follow the file's last test):

```bash
echo "T20: option inheritance from .rollover-options"
cat > "$TMP/work/testproj/.rollover-options" <<'EOF'
ROLLOVER_OPT_APPROVAL=auto
ROLLOVER_OPT_MODEL=claude-sonnet-5
EOF
mk_record claude sid-opt testproj
out=$(run_lns CLAUDE_CODE_SESSION_ID=sid-opt "$LNS" testproj --dry-run 2>&1)
assert_contains "T20a: claude approval flag" "$out" "--permission-mode acceptEdits"
assert_contains "T20b: claude model flag" "$out" "--model claude-sonnet-5"
out=$(run_lns "$LNS" testproj --runtime codex --dry-run 2>&1)
assert_contains "T20c: codex auto maps to --full-auto" "$out" "--full-auto"
out=$(run_lns "$LNS" testproj --runtime gemini --dry-run 2>&1)
assert_contains "T20d: gemini auto maps to --approval-mode auto_edit" "$out" "--approval-mode auto_edit"
out=$(run_lns "$LNS" testproj --runtime copilot --dry-run 2>&1)
assert_contains "T20e: copilot auto maps to --allow-all-tools" "$out" "--allow-all-tools"
printf 'ROLLOVER_OPT_APPROVAL=full\n' > "$TMP/work/testproj/.rollover-options"
out=$(run_lns "$LNS" testproj --runtime codex --dry-run 2>&1)
assert_contains "T20f: codex full maps to bypass flag" "$out" "--dangerously-bypass-approvals-and-sandbox"
printf 'ROLLOVER_OPT_APPROVAL=bogus\n' > "$TMP/work/testproj/.rollover-options"
out=$(run_lns "$LNS" testproj --runtime codex --dry-run 2>&1)
assert_contains "T20g: unknown approval warned" "$out" "unknown ROLLOVER_OPT_APPROVAL"
assert_not_contains "T20h: unknown approval adds no flags" "$out" "--full-auto"
rm -f "$TMP/work/testproj/.rollover-options"
out=$(run_lns "$LNS" testproj --runtime codex --dry-run 2>&1)
assert_not_contains "T20i: absent file -> unchanged argv" "$out" "--full-auto"
printf 'ROLLOVER_OPT_EXTRA=--add-dir /somewhere\n' > "$TMP/work/testproj/.rollover-options"
out=$(run_lns "$LNS" testproj --runtime claude --dry-run 2>&1)
assert_contains "T20j: raw extra args pass through" "$out" "--add-dir /somewhere"
rm -f "$TMP/work/testproj/.rollover-options"
```

- [ ] **Step 2: Run — new tests fail (no option handling yet).**

- [ ] **Step 3: Verify the mapped flags against live `--help`** (all five CLIs installed on this machine):

```bash
claude --help | grep -E 'permission-mode|dangerously-skip|--model'
codex --help | grep -E 'full-auto|dangerously-bypass|--model|ask-for-approval'
gemini --help | grep -E 'approval-mode|yolo|--model'
opencode --help | grep -E 'auto|--model|prompt'
copilot --help | grep -iE 'allow-all|--model|mode'
```

Correct the mapping table, the implementation below, and the T20 assertions to the shipped flags. If opencode's default (TUI) command has no auto-approval flag, drop opencode from the approval mapping (model only) and record it in decisions.md.

- [ ] **Step 4: Implement in `launch-next-session.sh`** — after RUNTIME resolution (after line 90), before the argv `case`:

```bash
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
        codex) OPT_ARGS+=(--full-auto) ;;
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
```

(Flags per Step 3 findings.) Splice into each argv branch — flags before the prompt, using the bash-3.2-safe empty-array form:

```bash
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
```

Also update the header Usage/Knobs comment: mention `.rollover-options` and that vendor flags were re-verified against live `--help` today.

- [ ] **Step 5: Update `skills/session-rollover/SKILL.md`** — in the flush/handoff phase, add one step (runtime-neutral wording; NO vendor flags in the skill):

> Write `work/<project>/.rollover-options` recording how THIS session was launched, so the successor inherits it: `ROLLOVER_OPT_APPROVAL=default|auto|full` (normalized approval/permission mode), optional `ROLLOVER_OPT_MODEL=<model-id>`, optional `ROLLOVER_OPT_EXTRA=<raw flags for this runtime>`. If you don't know your own launch options, leave any existing file untouched (it carries the last known values); create or update it only from knowledge. `scripts/launch-next-session.sh` maps these to each runtime's flags.

- [ ] **Step 6: Run the full launch suite** — `bash scripts/tests/test-launch-next-session.sh` — all green (old + new).

- [ ] **Step 7: Commit**

```bash
git add scripts/launch-next-session.sh skills/session-rollover/SKILL.md scripts/tests/test-launch-next-session.sh
git commit -m "feat(rollover): successor inherits predecessor launch options across runtimes

Decision: persist-and-replay via work/<proj>/.rollover-options (normalized
approval level + model + raw-extra escape hatch) mapped to per-runtime flags
in the launcher; rejected auto-detecting options from session artifacts —
unverified per runtime, and the rolling session already knows how it was
launched. Vendor flags stay in the script; the skill stays runtime-neutral."
```

---

### Task 8: docs, backlog, decisions, full verification

**Files:**
- Modify: `docs/context-budget.md`, `CLAUDE.md`, `docs/template-workspace-backlog.html`, `work/automatic-session-rollover/decisions.md`

- [ ] **Step 1: `docs/context-budget.md`** — add a "Vendor hook deployments" section covering, per runtime: wiring file, event, in-band channel, and the friction gates — codex hash-based hook trust (first-run approval; `--dangerously-bypass-hook-trust` for automation), gemini JSON-only stdout + telemetry-based measurement (workspace-scoped), opencode Part schema requirement + sqlite measurement + plugin→wrapper flow, copilot folder-trust gate (`~/.copilot/config.json` `trustedFolders`; repo hooks silently no-op untrusted) + block-only-at-STOP rationale. State the shared-lib architecture in two sentences. Under "Relaunch knobs", document `.rollover-options` (keys, normalized approval values, who writes it, behavior when absent).

- [ ] **Step 2: `CLAUDE.md`** — in the Context Budget section, update "Claude Code sessions also get an in-band hook message at these thresholds" to say all five runtimes (claude/codex/gemini/opencode/copilot CLI) get the in-band push via their committed hook wiring (pointer: `docs/context-budget.md`). In the relaunch sentence, append that the successor inherits the predecessor's launch options via `work/<proj>/.rollover-options`.

- [ ] **Step 3: `docs/template-workspace-backlog.html`** — read its "Maintaining this backlog" section first, then add/resolve rows for vendor hook deployments (item #3) and option inheritance, with `Fixed:` notes naming the delivering commits.

- [ ] **Step 4: `work/automatic-session-rollover/decisions.md`** — append Tier-2 notes (what + why + rejected alternative) matching the commit trailers from Tasks 1–7: lib extraction; opencode sqlite measure & env-only detect; gemini telemetry-over-transcript; copilot STOP-only block; options persist-and-replay vs artifact auto-detection; plus any Step-3/Task-7 flag-verification findings.

- [ ] **Step 5: Full verification gate**

```bash
bash scripts/tests/test-vendor-budget-hooks.sh
bash scripts/tests/test-launch-next-session.sh
bash scripts/tests/test-context-budget-registry.sh
```
All three green.

- [ ] **Step 6: Commit**

```bash
git add docs/context-budget.md CLAUDE.md docs/template-workspace-backlog.html work/automatic-session-rollover/decisions.md
git commit -m "docs(rollover): vendor hook deployments + option inheritance documented"
```

---

## Out of scope (do not do)

- VS Code agent-mode hook verification → `issues/01-vscode-agent-mode-hooks.md`.
- Auto-detecting predecessor options from session artifacts (rejected in Task 7's decision).
- codex `Stop`-block channel, gemini `AfterAgent` deny-retry, opencode event-bus SDK push — the chosen per-runtime channel suffices; add only if a live gap shows up.
- Re-litigating items #1/#2 design questions (settled; see `decisions.md` tail).
