# Phase 6 plan — one hook dispatcher over an adapter table

Ticket: `issues/07-phase-6-hook-dispatcher.md`. Plan of record: the `**Phase 6 —`
paragraph of `session-management-review-findings.md` (line 803); adapter-table
sentence and gate table in `evaluation/stage3-design-v2.md` (lines 17, 98–124,
151). Branch `s4-phase-6` from `stage4` at 0a117c6, worktree
`.claude/worktrees/s4-phase-6` (2026-09-18).

## Tasks

| # | Task | Check |
|---|---|---|
| 1 | Capture today's payloads as fixtures: run the 0a117c6 wrappers (`git show 0a117c6:scripts/hooks/<f>` into a temp dir) through the suite's own harness on a fixed input set (every runtime × every event × OK/WARN/STOP, plus the guard and edge inputs) and commit the captured `rc/stdout/stderr` under `scripts/tests/fixtures/vendor-hooks/` | fixtures exist; the suite's F cases compare against them and are red against a stub dispatcher |
| 2 | Add to `scripts/tests/test-vendor-budget-hooks.sh`: F (byte-equality per fixture, via the unchanged wrapper paths), J (`jq_missing` printed with `jq` off `PATH`, garbage stdin, no state file touched, gemini still prints `{}`) | red before the dispatcher exists |
| 3 | Write `scripts/hooks/context-budget-adapters.conf` (the table, one row per runtime) and `scripts/hooks/context-budget-hook.sh` (the dispatcher) | F and J green; T4–T13, X green unchanged |
| 4 | Replace the six wrappers and `context-budget-stop-hook.sh` with one-line `exec` shims at the same paths; keep `context-budget-hook-lib.sh` (sourced by the dispatcher and by `test-link-local-work.sh`) | `git diff --stat` shows each wrapper shrunk to a shim; vendor suite green |
| 5 | Every `scripts/tests/*.sh` green plus `test-check-ledger.py` | rc lines in Evidence |

## Interface

### The adapter table — `scripts/hooks/context-budget-adapters.conf`

`|`-separated, one row per runtime, whitespace around cells ignored, `#` comments. Read by the dispatcher with bash `read` (no `jq`), so it is loaded before the `jq_missing` check.

| runtime | session id | transcript (check) | transcript (end) | measure as | register | pin | check hook | turn-end hook | logged out |
|---|---|---|---|---|---|---|---|---|---|
| claude | `payload:.session_id` | `payload:.transcript_path+chain` | `-` | claude | config | `-` | `PostToolUse:stderr-exit2` | `Stop:sigterm` | last assistant turn `isApiErrorMessage` + `authentication_failed` + "Not logged in" (`session-loop.sh child_logged_out`) |
| codex | `payload:.session_id` | `payload:.transcript_path` | `-` | codex | agent | `-` | `UserPromptSubmit:hso-event` | `Stop:sigterm` | not captured |
| copilot | `payload:.sessionId` | `copilot-state` | `payload:.transcriptPath` | copilot-cli | agent | `-` | `sessionStart:ctx` | `agentStop:sigterm+block` | not captured |
| copilot-vscode | `payload:.session_id` | `chat-sessions` | `chat-sessions` | copilot-vscode | hook | `VSCODE_TARGET_SESSION_LOG=transcript` | `SessionStart:hso` | `Stop:block-stderr` | n/a (editor pane, no supervisor) |
| gemini | `payload:.session_id` | `-` | `-` | gemini | agent | `-` | `BeforeAgent:hso-json-only` | `-` | n/a (no exit hook; chains unsupported) |
| opencode | `arg` | `-` | `-` | opencode | agent | `OPENCODE_SESSION_ID=sid` | `chat.message:text` | `session.idle:decide` | not captured |

Column meanings:

- **session id** — `payload:<jq path>` reads the hook payload on stdin (stdin is read only then); `arg` is the dispatcher's third argument (opencode's plugin passes the id on the command line and no stdin).
- **transcript (check / end)** — what the measurer's `check --transcript` receives at the check hook and at the turn-end hook. `payload:<path>` must name an existing file; `+chain` keys the hook state per chain (a transcript not named `<sid>.jsonl` is a sidechain: `<sid>-sidechain`, backlog L32); `copilot-state` = `$COPILOT_STATE_DIR/<sid>/events.jsonl`; `chat-sessions` = payload `transcript_path` → `../../../chatSessions/<sid>.jsonl`; `-` = none, the measurer discovers the artifact (gemini telemetry log, opencode sqlite).
- **measure as** — the measurer's `--runtime`; its per-runtime adapter is the token method (last usage record for claude/codex/copilot, telemetry log for gemini, sqlite for opencode). Also the hook-state key prefix (`hook-<measure as>-<sid>`), unchanged.
- **register** — who runs `register`: `config` (the vendor config calls the measurer — claude's `SessionStart`), `agent` (the agent runs it per the skill), `hook` (the dispatcher, on every firing until the registry record `.context-budget/sessions/<measure as>-<sid>.json` exists — today's copilot-vscode definite auto-registration).
- **pin** — an env var exported before the measurer runs, carrying the identity the measurer cannot read from the payload: `<VAR>=sid` or `<VAR>=transcript`.
- **check hook** — `<vendor event>:<envelope>`. Envelopes: `stderr-exit2` (message on stderr, exit 2), `hso-event` (`{hookSpecificOutput:{hookEventName:<event>,additionalContext}}`, `jq -n` pretty), `hso` (same without the event name), `hso-json-only` (compact, and `{}` on every silent exit — gemini demands JSON-only stdout), `ctx` (`{additionalContext}`), `text` (plain message on stdout).
- **turn-end hook** — `<vendor event>:<action>`. Actions: `sigterm` (`stop_hook_active` guard, then under `TF_SESSION_LOOP_PROJECT` `budget_hook_exit`), `sigterm+block` (sigterm, then measure and at STOP `{decision:"block",reason}`), `block-stderr` (guard, measure, at STOP message on stderr + exit 2), `decide` (print `exit` when `budget_hook_should_exit` says so; opencode's plugin self-kills).
- **logged out** — informational for the supervisor's logout discriminator; the dispatcher does not read it.

### The dispatcher — `scripts/hooks/context-budget-hook.sh <runtime> <event> [arg]`

Payload on stdin when the row's session id is `payload:`. Steps, in order: parse argv → load the row → **`jq_missing` check** (`context-budget-hook: refused reason=jq_missing runtime=<rt> event=<ev>` on stderr, the row's silent envelope on stdout, exit 0 — a hook never blocks a turn) → source the lib → read stdin → session id (empty → silent exit) → classify the event as the row's check hook or turn-end hook (anything else → one stderr line, silent exit) → turn-end guard/exit actions → transcript resolution (`payload:` empty → silent) → pin export → `hook` registration → transcript must exist → measure (`budget_hook_check <measure as> <key> <transcript>`) → envelope or STOP-only block.

Exit codes are today's: 0 everywhere except `stderr-exit2`/`block-stderr` on escalation (2). `budget_hook_exit` receives the row's runtime name (claude/codex/copilot), as the wrappers passed it.

### Shims (same paths, one `exec` line each)

| Path | Becomes |
|---|---|
| `context-budget-claude-hook.sh` | `exec context-budget-hook.sh claude PostToolUse` |
| `context-budget-codex-hook.sh` | `exec context-budget-hook.sh codex UserPromptSubmit` |
| `context-budget-copilot-hook.sh <event>` | `exec context-budget-hook.sh copilot "$1"` |
| `context-budget-copilot-vscode-hook.sh <event>` | `exec context-budget-hook.sh copilot-vscode "$1"` |
| `context-budget-gemini-hook.sh` | `exec context-budget-hook.sh gemini BeforeAgent` |
| `context-budget-opencode-hook.sh <sid>` / `--exit-check <sid>` | `exec context-budget-hook.sh opencode chat.message "$1"` / `… opencode session.idle "$2"` |
| `context-budget-stop-hook.sh <runtime>` | `exec context-budget-hook.sh "$1" Stop` |

`context-budget-hook-lib.sh` stays as is (throttle, escalation-only, messages, exit predicate); only its header comment changes to name the dispatcher.

### Tests

`test-vendor-budget-hooks.sh` keeps T1–T13, X1–X10 unchanged (they run through the shim paths). New: **F** — for each fixture under `scripts/tests/fixtures/vendor-hooks/`, run the same command line through the harness and `cmp` `rc + stdout + stderr` byte-for-byte; `HOOK_FIXTURE_WRITE=1` regenerates the fixtures (used once, against the 0a117c6 wrappers copied into the throwaway workspace). **J** — `PATH` holding only `bash` and `dirname`, garbage stdin: stderr carries `reason=jq_missing`, stdout is the silent envelope (`{}` for gemini, empty otherwise), rc 0, no `.context-budget/hook-*` file created.

## Decisions (Tier 2 candidates; `decisions.md` is off-limits to this agent)

1. **The table is a data file, not bash.** `context-budget-adapters.conf` is read with `read`, so the design's "one row per runtime" is literally one line a human or the supervisor can read without executing anything, and the `logged out` column has a home. Rejected: a `case` block or per-runtime functions inside the dispatcher (the six wrappers in one file, not a table).
2. **`copilot-vscode` and `opencode` keep a row and a shim.** Both ship today with committed wiring (`.github/hooks/context-budget-vscode.json`, `.opencode/plugins/context-budget.js`) that names the wrapper paths, and "non-goal" in the design means no new work, not removal of working support (memory: integrations must be agent-agnostic). A row costs one line. Rejected: deleting them (breaks two shipped integrations for zero simplification; the config files cannot be edited in this phase anyway).
3. **`context-budget-stop-hook.sh` folds into the dispatcher; the lib stays.** The Stop hook is the `Stop:sigterm` cell of the claude and codex rows, so it is one more shim. The lib is sourced by `scripts/tests/test-link-local-work.sh` (not this phase's file) and by the X tests, and its functions are the measurer-facing core, not payload handling. Rejected: inlining the lib into the dispatcher (breaks a suite this phase may not edit, and makes the dispatcher own the throttle it only calls).
4. **`jq_missing` goes to stderr with exit 0 and the silent envelope on stdout.** stdout is the vendor payload channel (gemini rejects non-JSON stdout, opencode's plugin injects any stdout as a message), and a hook must never block a turn. The line is printed on every firing (the hook has no per-session state before `jq`). Rejected: exit 4 like the measurer (a PostToolUse hook exiting non-zero is a visible failure for an outcome the agent cannot fix mid-turn); stdout (corrupts the envelope).
5. **An empty session id is a silent exit for every runtime.** Today claude, codex and gemini fell through to the lib's `unknown` key (or, for claude, a `-sidechain` key), sharing one throttle slot across sessions; copilot, copilot-vscode and opencode already exited. No vendor payload omits the id, so the fixtures never exercise this input. Rejected: a per-row "id optional" flag to reproduce the `unknown` key (data to preserve a defect).
6. **The `stop_hook_active` guard runs before `hook` registration.** Generic order: guard → exit → transcript → register → measure. Today's copilot-vscode wrapper registered before its guard; on a hook-continued turn registration is now skipped, and the next firing retries it (`[ -f record ]` is the only gate). Payloads are identical. Rejected: a per-row ordering flag.
7. **Fixtures are committed outputs, not the old wrappers.** Byte-equality against captured `rc/stdout/stderr` survives shallow clones and does not depend on `git show 0a117c6`; regeneration is explicit (`HOOK_FIXTURE_WRITE=1`) so drift cannot be papered over silently. Rejected: extracting the 0a117c6 wrappers at test time (needs history; a template download has none).
8. **Vendor config files keep naming the shim paths.** No edit is needed for the dispatcher to work. Optional later cleanup for the parent: point `.claude/settings.json` (`PostToolUse`, `Stop`), `.codex/config.toml`, `.gemini/settings.json`, `.github/hooks/*.json` and `.opencode/plugins/context-budget.js` at `context-budget-hook.sh <runtime> <event>` and delete the shims; the opencode plugin would then call `chat.message`/`session.idle` directly. Rejected: doing it now (forbidden files; and the codex trust hash re-prompts on any hook command change).
9. **Docs prose is phase 8's.** `docs/context-budget.md` "Vendor hook deployments" and the spec still describe per-vendor wrappers; the shims' header comments point at the dispatcher. Rejected: editing docs here (phase 4 runs in parallel and the doc is shared).

## Evidence

Run 2026-09-18 in the worktree, every suite with `bash`, no `timeout` wrapper.

**Byte equality (F, 47 fixtures).** Captured from the 0a117c6 wrappers (`git show 0a117c6:scripts/hooks/<f>` into a scratch tree, run through the suite's own `fcase` harness with `HOOK_FIXTURE_WRITE`), committed under `scripts/tests/fixtures/vendor-hooks/`, no temp path in any fixture. Against the dispatcher behind the shim paths, `cmp` on `rc + stdout + stderr` passes for every case:

| runtime | cases (all identical) |
|---|---|
| claude | PostToolUse OK / WARN / WARN again (silent) / WARN→STOP / STOP / sidechain WARN / missing transcript; Stop unsupervised / `stop_hook_active` / no sentinel |
| codex | UserPromptSubmit OK / WARN / STOP / missing transcript; Stop unsupervised / no sentinel |
| copilot | sessionStart OK / WARN / STOP / fresh (no events file); agentStop OK / WARN / STOP / active / no sentinel; no sid; unknown event |
| copilot-vscode | SessionStart OK / WARN / STOP; Stop OK / WARN / STOP / active; camelCase (Copilot CLI) payload; fresh (no chatSessions file); no transcript_path |
| gemini | BeforeAgent OK (`{}`) / WARN / STOP (compact JSON) |
| opencode | chat.message OK / WARN / STOP; no sid; session.idle unsupervised / mine (`exit` + stderr line) / foreign |

The one divergence found while building (an unknown event printed a stderr note) was removed: the dispatcher is silent there, as the wrappers were.

**`jq_missing` (J).** With `PATH` holding only `bash` and `dirname` and `not json` on stdin: claude → rc 0, empty stdout, exactly one stderr line `context-budget-hook: refused reason=jq_missing runtime=claude event=PostToolUse`, no `.context-budget/hook-*` file created; gemini → stdout `{}`, same stderr line; opencode → empty stdout, same line. The check sits after the table row is loaded (bash `read` only) and before the lib is sourced or stdin is read.

**Suites** (`for t in scripts/tests/*.sh; do bash "$t"; done`, plus `python3 scripts/tests/test-check-ledger.py`):

```
test-agent-entrypoints.sh rc=0        test-link-local-work.sh rc=0
test-attach-session.sh rc=0           test-parameterization.sh rc=0
test-check-dependencies.sh rc=0       test-rollover-clear-seed.sh rc=0
test-context-budget-registry.sh rc=0  test-session-lib.sh rc=1 → rerun rc=0 (see below)
test-emit-mode.sh rc=0                test-session-loop-notify.sh rc=0
test-fleet-children.sh rc=0           test-session-loop.sh rc=0
test-fleet-dispatch-contract.sh rc=0  test-session-numbering.sh rc=0
test-fleet-dispatch-records.sh rc=0   test-statusline-context-budget.sh rc=0
test-import-session-seq.sh rc=0       test-template-instantiation.sh rc=0
test-launch-next-session.sh rc=0      test-turn-end-exit.sh rc=0
test-vendor-budget-hooks.sh rc=0 (pass=150 fail=0; was 108 asserts)
test-check-ledger.py rc=0
```

`test-session-lib.sh` S8a/S8c (three concurrent writers: `writer 3: rc=4 at 0`, seq 59 vs 60) failed once during the full run and reproduced identically on a clean `git archive 0a117c6` extract, so it is a pre-existing load-sensitive lock timeout in `session-lib.sh` (not this phase's file); the rerun passed. Nothing this phase touches is on its path.

**Files.** Added: `scripts/hooks/context-budget-hook.sh` (dispatcher), `scripts/hooks/context-budget-adapters.conf` (table), `scripts/tests/fixtures/vendor-hooks/*.txt` (47). Shimmed to one `exec` line each (same paths): `context-budget-claude-hook.sh`, `-codex-hook.sh`, `-copilot-hook.sh`, `-copilot-vscode-hook.sh`, `-gemini-hook.sh`, `-opencode-hook.sh`, `-stop-hook.sh`. Kept: `context-budget-hook-lib.sh` (header comment only). Edited: `scripts/tests/test-vendor-budget-hooks.sh` (copies the table too; F and J added). Deleted: none. `rollover-clear-seed.sh` untouched (phase 4's).

**Config edits for the parent.** None required; every vendor config still resolves to a working shim. Optional cleanup later (decision 8): point the configs at `context-budget-hook.sh <runtime> <event>` and delete the shims. Docs prose (`docs/context-budget.md` "Vendor hook deployments", the session-loop spec) still describes per-vendor wrappers — phase 8.
