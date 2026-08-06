# launch-next-session.sh — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build `scripts/launch-next-session.sh` — the relaunch step of session-rollover (ADR-0003/0004, item #2): launch a fresh agent session seeded with the canonical bootstrap prompt, honoring `ROLLOVER_RELAUNCH`/`ROLLOVER_RUNTIME`, resolving the runtime from the dying session's own registry record.

**Architecture:** Single bash script owning all vendor launch specifics (skills stay runtime-neutral). Pipeline: validate project → resolve runtime (flag > own registry record via env-var identity, D6 > newest record for the project > `ROLLOVER_RUNTIME` > claude) → bake the verbatim bootstrap prompt → mode gate (`off` prints prompt only; `manual` launches attached or prints the ready-to-run command when not a tty; `auto` adds `--bg` for claude) → launch → for `--bg`, confirm the successor via D8 (new session file, same project, new session-id). Tests drive everything through `--dry-run` (assertable flag assembly) plus a stub `claude` binary on PATH for the real-launch path.

**Tech Stack:** bash + jq, house conventions from `context-budget.sh` (`set -u`, `note`/`die`, exit 3 on error). Tests: plain bash harness, `scripts/tests/test-launch-next-session.sh` (suite convention `test-*.sh`).

## Global Constraints

- Spec (settled — do not re-litigate): 5 runtimes seeded-interactive; **flags verified against live `--help` 2026-08-05**: `claude [prompt]` (+ `--bg, --background`), `codex [PROMPT]` (positional), `gemini -i <prompt>` (`--prompt-interactive`), `opencode --prompt <prompt>`, `copilot -i <prompt>` (`--interactive`). `--bg` is claude-only.
- Bootstrap prompt baked **verbatim**, single source of truth in this script (ADR-0003): `Read \`work/<project>/next-session.md\` and continue from **First actions**.`
- Knobs from `context-budget.env`: `ROLLOVER_RELAUNCH=off|manual|auto`, `ROLLOVER_RUNTIME` (fallback only). Workspace-level, no per-project override.
- Runtime comes from the dying session's own registry record `.context-budget/sessions/<runtime>-<session-id>.json`, field `runtime` (D6 = "read my own record"); env-var identity order `CLAUDE_CODE_SESSION_ID`, `CODEX_THREAD_ID`, `COPILOT_AGENT_SESSION_ID`, `VSCODE_TARGET_SESSION_LOG` — same as `context-budget.sh session_id_for()`.
- D8 successor confirmation = a new session file with the same project and a different session-id.
- No unsafe emulation of background launch on non-claude runtimes (`nohup`+`--yolo` rejected in ADR-0003).
- Degradation over hard failure where reasonable (house rule), but genuine misuse (`--bg codex`, missing launcher file) dies with exit 3.
- Surgical: `context-budget.sh` is NOT modified.

## Implementation decisions made in this plan (Tier-2 notes to record in Task 4)

- **TTY guard for attached launch:** in `manual` mode the script `exec`s the runtime only when stdin+stdout are a terminal; otherwise it prints the ready-to-run command (`run: …`) and exits 0. Rationale: the agent invokes this from a non-tty tool shell — exec'ing a TUI there hangs; relaunch-analysis already prescribed "print the ready-to-run command (others)" for exactly this case. Rejected: always exec (hangs agent shells).
- **`copilot-vscode` runtime degrades to prompt-only** (warn + print prompt, exit 0): VS Code agent mode has no CLI seeded launch; verification is spun out (`issues/01-vscode-agent-mode-hooks.md`). Rejected: hard error (the dying session still needs the prompt emitted to hand to the user).
- **D8 confirmation only after `--bg` launches**, polling `.context-budget/sessions/` for a file absent before launch with `project` match and different `session_id`; timeout `${ROLLOVER_CONFIRM_SECS:-120}`, non-fatal (`successor=unconfirmed` + advice). Rationale: attached launches occupy the terminal — nothing to poll from; timeout must not fail the rollover. Rejected: mandatory confirmation on all paths.
- **The script always prints the bootstrap prompt block first**, in every mode: the paste-me fallback must survive any launch failure.

---

### Task 1: Red tests — dry-run flag assembly + runtime resolution

**Files:**
- Create: `scripts/tests/test-launch-next-session.sh` (mode 755)

**Interfaces:**
- Produces: harness with a throwaway workspace (`mktemp -d`), `mk_record <runtime> <sid> <project>` (writes a registry session file), `assert_eq`/`assert_contains`/`assert_not_contains`, tests T1–T10. Task 3 appends T11–T13 to this file.
- Consumes (from Task 2, not yet existing): `scripts/launch-next-session.sh` with `--dry-run` printing a `project= runtime= mode= bg=` status line and a `cmd: <shell-quoted argv>` line; bootstrap prompt verbatim; error exit 3.

- [ ] **Step 1: Write the harness + T1–T10**

```bash
#!/usr/bin/env bash
# File: scripts/tests/test-launch-next-session.sh
# Purpose: Regression tests for launch-next-session.sh (ADR-0003/0004 item #2).
#          Self-contained: throwaway workspace in mktemp -d; --dry-run for flag
#          assembly, stub binaries on PATH for the real-launch path.
set -u
SRC_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/scripts" "$TMP/work/testproj" "$TMP/.context-budget/sessions" "$TMP/bin"
cp "$SRC_ROOT/scripts/launch-next-session.sh" "$TMP/scripts/" 2>/dev/null || true
printf 'ROLLOVER_RELAUNCH=manual\nROLLOVER_RUNTIME=claude\n' > "$TMP/context-budget.env"
echo "# launcher" > "$TMP/work/testproj/next-session.md"
cd "$TMP"
LNS="$TMP/scripts/launch-next-session.sh"
SESS="$TMP/.context-budget/sessions"

PASS=0; FAIL=0
ok()   { PASS=$((PASS+1)); echo "  ok: $1"; }
bad()  { FAIL=$((FAIL+1)); echo "  FAIL: $1" >&2; }
assert_eq() { [ "$2" = "$3" ] && ok "$1" || bad "$1 (want [$3] got [$2])"; }
assert_contains() { case "$2" in *"$3"*) ok "$1" ;; *) bad "$1 (no [$3] in [$2])" ;; esac; }
assert_not_contains() { case "$2" in *"$3"*) bad "$1 (unexpected [$3])" ;; *) ok "$1" ;; esac; }

mk_record() {  # $1=runtime $2=session-id $3=project
  jq -n --arg rt "$1" --arg sid "$2" --arg p "$3" \
    '{runtime:$rt, session_id:$sid, artifact:"/dev/null", project:$p, registered_at:"2026-08-05T00:00:00Z"}' \
    > "$SESS/$1-$2.json"
}
# All runtime-identity env vars cleared per call unless a test sets one.
run_lns() { env -u CLAUDE_CODE_SESSION_ID -u CODEX_THREAD_ID \
  -u COPILOT_AGENT_SESSION_ID -u VSCODE_TARGET_SESSION_LOG \
  -u ROLLOVER_RELAUNCH -u ROLLOVER_RUNTIME "$@"; }

PROMPT='Read `work/testproj/next-session.md` and continue from **First actions**.'

echo "T1: own registry record via CLAUDE_CODE_SESSION_ID resolves runtime=claude"
mk_record claude sid-aaa testproj
out=$(run_lns CLAUDE_CODE_SESSION_ID=sid-aaa "$LNS" testproj --dry-run 2>&1)
assert_contains "T1a: runtime resolved" "$out" "runtime=claude"
assert_contains "T1b: claude argv"      "$out" "cmd: claude"
assert_contains "T1c: verbatim prompt"  "$out" "continue from **First actions**"

echo "T2: codex identity resolves codex argv (positional prompt)"
mk_record codex th-bbb testproj
out=$(run_lns CODEX_THREAD_ID=th-bbb "$LNS" testproj --dry-run 2>&1)
assert_contains "T2a: runtime resolved" "$out" "runtime=codex"
assert_contains "T2b: codex argv"       "$out" "cmd: codex"

echo "T3: no env identity — newest record with matching project wins"
rm -f "$SESS"/*.json; mk_record gemini workspace testproj
out=$(run_lns "$LNS" testproj --dry-run 2>&1)
assert_contains "T3a: runtime from project record" "$out" "runtime=gemini"
assert_contains "T3b: gemini -i argv"              "$out" "cmd: gemini -i"

echo "T4: no records at all — ROLLOVER_RUNTIME fallback"
rm -f "$SESS"/*.json
out=$(env -u CLAUDE_CODE_SESSION_ID -u CODEX_THREAD_ID -u COPILOT_AGENT_SESSION_ID \
  -u VSCODE_TARGET_SESSION_LOG ROLLOVER_RELAUNCH=manual ROLLOVER_RUNTIME=opencode \
  "$LNS" testproj --dry-run 2>&1)
assert_contains "T4a: fallback runtime"    "$out" "runtime=opencode"
assert_contains "T4b: opencode argv"       "$out" "cmd: opencode --prompt"

echo "T5: --runtime flag overrides everything"
mk_record claude sid-ccc testproj
out=$(run_lns CLAUDE_CODE_SESSION_ID=sid-ccc "$LNS" testproj --runtime copilot --dry-run 2>&1)
assert_contains "T5a: flag wins"    "$out" "runtime=copilot"
assert_contains "T5b: copilot argv" "$out" "cmd: copilot -i"

echo "T6: bootstrap prompt is exact and verbatim"
out=$(run_lns "$LNS" testproj --runtime claude --dry-run 2>&1)
assert_contains "T6a: exact prompt text" "$out" "$PROMPT"

echo "T7: ROLLOVER_RELAUNCH=off prints prompt, launches nothing"
out=$(env ROLLOVER_RELAUNCH=off "$LNS" testproj --runtime claude --dry-run 2>&1)
assert_contains     "T7a: mode off"     "$out" "mode=off"
assert_contains     "T7b: prompt shown" "$out" "$PROMPT"
assert_not_contains "T7c: no cmd line"  "$out" "cmd: claude"

echo "T8: --bg on a non-claude runtime is an error (exit 3)"
out=$(run_lns "$LNS" testproj --runtime codex --bg --dry-run 2>&1); rc=$?
assert_eq       "T8a: exit 3"        "$rc" "3"
assert_contains "T8b: claude-only"   "$out" "claude-only"

echo "T9: missing next-session.md is an error (exit 3)"
out=$(run_lns "$LNS" nosuchproj --runtime claude --dry-run 2>&1); rc=$?
assert_eq       "T9a: exit 3"          "$rc" "3"
assert_contains "T9b: names the file"  "$out" "next-session.md"

echo "T10: ROLLOVER_RELAUNCH=auto + claude implies --bg"
out=$(env ROLLOVER_RELAUNCH=auto "$LNS" testproj --runtime claude --dry-run 2>&1)
assert_contains "T10a: bg=1"          "$out" "bg=1"
assert_contains "T10b: --bg in argv"  "$out" "cmd: claude --bg"

echo; echo "passed=$PASS failed=$FAIL"
[ "$FAIL" -eq 0 ]
```

- [ ] **Step 2: `chmod +x scripts/tests/test-launch-next-session.sh`, run it to verify it fails for the right reason**

Run: `bash scripts/tests/test-launch-next-session.sh`
Expected: every T fails/errors because `scripts/launch-next-session.sh` doesn't exist (the `cp` is guarded with `|| true` so the harness itself runs). Exit non-zero.

*(No commit yet — red tests commit with the implementation in Task 2.)*

---

### Task 2: Implement the script core (make T1–T10 green)

**Files:**
- Create: `scripts/launch-next-session.sh` (mode 755)

**Interfaces:**
- Consumes: registry session files `{runtime, session_id, artifact, project, registered_at}` written by `context-budget.sh register`; `context-budget.env` knobs.
- Produces: status line `project=<p> runtime=<rt> mode=<off|manual|auto> bg=<0|1>`; `cmd: <shell-quoted argv>` on `--dry-run`; `run: <argv>` when manual+non-tty; `successor=confirmed session=<id>` / `successor=unconfirmed` after `--bg` (Task 3). Exit 0 ok / 3 error.

- [ ] **Step 1: Write `scripts/launch-next-session.sh`**

```bash
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
```

- [ ] **Step 2: `chmod +x scripts/launch-next-session.sh`, run the suite**

Run: `bash scripts/tests/test-launch-next-session.sh`
Expected: T1–T10 all pass (`failed=0`, exit 0). If a `cmd:` assertion fails on quoting, fix the test expectation to match `printf '%q'` output, not the script.

- [ ] **Step 3: Commit**

```bash
git add scripts/launch-next-session.sh scripts/tests/test-launch-next-session.sh
git commit -m "feat(rollover): launch-next-session.sh — seeded successor relaunch (ADR-0003 item #2)

Decision: runtime resolves from the dying session's own registry record
(D6), env-first identity mirroring context-budget.sh; ROLLOVER_RUNTIME is
fallback-only. Vendor flags re-verified against live --help 2026-08-05."
```

---

### Task 3: Launch-path tests — stub-binary --bg confirmation + non-tty manual

**Files:**
- Modify: `scripts/tests/test-launch-next-session.sh` (append T11–T13 before the summary block)

**Interfaces:**
- Consumes: `$TMP/bin` (already created by the harness), `mk_record`, `run_lns`, `$SESS`, `$PROMPT`.
- Produces: end-to-end coverage of `--bg` D8 confirmation, unconfirmed timeout, and the non-tty manual path.

- [ ] **Step 1: Append T11–T13 (insert before the `echo; echo "passed=…"` summary lines)**

```bash
echo "T11: --bg launch with stub claude; successor registers -> confirmed"
rm -f "$SESS"/*.json; mk_record claude sid-old testproj
cat > "$TMP/bin/claude" <<STUB
#!/usr/bin/env bash
# Stub: pretend the successor session booted and registered (D8 heartbeat).
jq -n '{runtime:"claude", session_id:"sid-new", artifact:"/dev/null",
        project:"testproj", registered_at:"2026-08-05T00:00:01Z"}' \
  > "$SESS/claude-sid-new.json"
STUB
chmod +x "$TMP/bin/claude"
out=$(PATH="$TMP/bin:$PATH" ROLLOVER_CONFIRM_SECS=10 \
  run_lns CLAUDE_CODE_SESSION_ID=sid-old "$LNS" testproj --bg 2>&1); rc=$?
assert_eq       "T11a: exit 0"      "$rc" "0"
assert_contains "T11b: confirmed"   "$out" "successor=confirmed session=sid-new"

echo "T12: --bg launch, successor never registers -> unconfirmed (non-fatal)"
rm -f "$SESS"/*.json; mk_record claude sid-old testproj
cat > "$TMP/bin/claude" <<'STUB'
#!/usr/bin/env bash
exit 0
STUB
chmod +x "$TMP/bin/claude"
out=$(PATH="$TMP/bin:$PATH" ROLLOVER_CONFIRM_SECS=3 \
  run_lns CLAUDE_CODE_SESSION_ID=sid-old "$LNS" testproj --bg 2>&1); rc=$?
assert_eq       "T12a: exit 0 still" "$rc" "0"
assert_contains "T12b: unconfirmed"  "$out" "successor=unconfirmed"

echo "T13: manual mode without a tty prints the ready-to-run command, execs nothing"
rm -f "$SESS"/*.json
cat > "$TMP/bin/gemini" <<'STUB'
#!/usr/bin/env bash
echo "GEMINI_EXECUTED"; exit 0
STUB
chmod +x "$TMP/bin/gemini"
out=$(PATH="$TMP/bin:$PATH" run_lns "$LNS" testproj --runtime gemini </dev/null 2>&1); rc=$?
assert_eq           "T13a: exit 0"          "$rc" "0"
assert_contains     "T13b: run: line"       "$out" "run: gemini -i"
assert_not_contains "T13c: not executed"    "$out" "GEMINI_EXECUTED"
```

Note for the implementer: `run_lns` passes leading `VAR=value` pairs to `env`, so `PATH=… ROLLOVER_CONFIRM_SECS=… run_lns CLAUDE_CODE_SESSION_ID=… "$LNS" …` works because `run_lns` is `env -u … "$@"` — the `VAR=value` words become `env` arguments. The `PATH=`/`ROLLOVER_CONFIRM_SECS=` prefixes before `run_lns` itself apply to the whole `env` invocation; both routes reach the script.

- [ ] **Step 2: Run the suite**

Run: `bash scripts/tests/test-launch-next-session.sh`
Expected: T1–T13 all pass, `failed=0`, exit 0. T11/T12 exercise the real launch path — if T11 hangs ~10s then fails, the stub's registry write path (`$SESS` expansion inside the heredoc) is wrong; the T11 heredoc is intentionally unquoted so `$SESS` expands at write time.

- [ ] **Step 3: Also re-run the registry suite (no regressions — shared state dir conventions)**

Run: `bash scripts/tests/test-context-budget-registry.sh`
Expected: all pass, exit 0.

- [ ] **Step 4: Commit**

```bash
git add scripts/tests/test-launch-next-session.sh
git commit -m "test(rollover): launch-path coverage — --bg D8 confirmation, timeout, non-tty manual"
```

---

### Task 4: Docs flip + backlog + decision notes

**Files:**
- Modify: `docs/context-budget.md:80-83` (status note in §"Rollover trigger policy")
- Modify: `docs/template-workspace-backlog.html` (append changelog `<tr>` in the dated table, after the 2026-08-05 skill-hardening row)
- Modify: `work/automatic-session-rollover/decisions.md` (append Tier-2 notes)
- Check only: `docs/workspace-structure.md:659` (line already reads "Relaunch a rollover successor seeded with the bootstrap prompt" — accurate, leave untouched)

**Interfaces:**
- Consumes: shipped script + green suites from Tasks 2–3.
- Produces: docs consistent with reality; Tier-2 provenance for this plan's decisions.

- [ ] **Step 1: Flip the status note in `docs/context-budget.md`**

Replace (lines 80–83):

```markdown
> **Status:** design accepted 2026-08-05 (ADR-0003/ADR-0004); the
> `session-rollover` skill carries the policy now, `launch-next-session.sh` and
> the session-keyed registry are the implementation items. Until the script
> lands, relaunch behaves as `ROLLOVER_RELAUNCH=off` regardless of the knob.
```

with:

```markdown
> **Status:** implemented 2026-08-05 (ADR-0003/ADR-0004): the
> `session-rollover` skill carries the policy, the session-keyed registry and
> `scripts/launch-next-session.sh` implement it (tests:
> `scripts/tests/test-launch-next-session.sh`).
```

- [ ] **Step 2: Append Tier-2 decision notes to `work/automatic-session-rollover/decisions.md`**

Append the four decisions from "Implementation decisions made in this plan" above (tty guard, copilot-vscode degradation, --bg-only D8 confirmation, always-print prompt), each in the file's existing entry format (date-stamped heading + why + rejected alternative), dated 2026-08-05.

- [ ] **Step 3: Append the backlog changelog row**

In `docs/template-workspace-backlog.html`, in the dated changelog table (the one whose last data row is the 2026-08-05 skill-hardening batch), append:

```html
<tr><td>2026-08-05</td><td>Feature: <strong>rollover relaunch script</strong> — <code>scripts/launch-next-session.sh</code> (ADR-0003/0004 item #2): launches a successor session seeded with the canonical bootstrap prompt (verbatim, single source of truth in the script); runtime from the dying session's own registry record (D6), <code>ROLLOVER_RUNTIME</code> fallback-only; 5 runtimes seeded-interactive (<code>claude</code>, <code>codex</code>, <code>gemini -i</code>, <code>opencode --prompt</code>, <code>copilot -i</code>; flags re-verified against live <code>--help</code>), <code>--bg</code> claude-only with D8 successor confirmation; <code>ROLLOVER_RELAUNCH=off|manual|auto</code> honored; non-tty manual prints the ready-to-run command. Tests: <code>scripts/tests/test-launch-next-session.sh</code> (13 cases, dry-run + stub-binary launch paths). Status note flipped in <code>docs/context-budget.md</code>. No scorecard change.</td></tr>
```

- [ ] **Step 4: Run the workspace structure check**

Run: `bash scripts/check-workspace-structure.sh`
Expected: exit 0 (no missing-file complaints about the newly referenced script).

- [ ] **Step 5: Commit**

```bash
git add docs/context-budget.md docs/template-workspace-backlog.html work/automatic-session-rollover/decisions.md
git commit -m "docs(rollover): mark relaunch implemented; backlog row + Tier-2 notes for launch-next-session.sh"
```

- [ ] **Step 6: Budget checkpoint**

Run: `scripts/context-budget.sh record --label "launch-next-session.sh shipped (item #2)"`
Act on the exit code per the Context Budget policy (0 → continue to item #3; 1 → wrap up and ask; 2 → roll over).
