# Context Budget — Measurement, Warning, and Rollover

LLM performance degrades past ~150K context tokens (the "dumb zone") regardless
of advertised window size. This workspace measures every agent session's live
context usage **exactly, from disk**, warns before the threshold, and rolls work
over to a fresh session via a deliberate handoff instead of uncontrolled
automatic compaction.

Pieces: `scripts/context-budget.sh` (measurement core) ·
`scripts/hooks/context-budget-claude-hook.sh` (in-band Claude Code warning) ·
`skills/session-rollover/SKILL.md` (rollover workflow) · `context-budget.env`
(thresholds) · `work/context-decay/context-ledger.jsonl` (measurement ledger).

## Quickstart — developer

```sh
scripts/context-budget.sh check                  # auto-detect runtime, one status line
scripts/context-budget.sh check --runtime codex  # or claude|copilot-vscode|copilot-cli|gemini
scripts/context-budget.sh watch --interval 30    # hook-less runtimes: poll + macOS notification
```

Output is one line: `runtime= method= tokens= threshold= warn= pct= status= artifact=`.
Exit code: `0` OK · `1` WARN · `2` STOP · `3` error. Requires `jq`.

When an agent tells you it got a WARN/STOP: let it finish the current unit, have
it run the `session-rollover` skill, then start a fresh session with the
bootstrap prompt it emits. Don't push new work into a STOP'd session.

## Quickstart — agent

- **Session start:** `scripts/context-budget.sh register` — pins your session
  artifact so later checks aren't confused by concurrent sessions.
- **Every work-unit boundary:** `scripts/context-budget.sh record --label
  "<skill>: <unit> done"` — measures, appends to the ledger, and returns the
  status via exit code.
- **Exit 1 (WARN):** finish the current unit's bookkeeping, then run
  `skills/session-rollover/SKILL.md`. **Exit 2 (STOP):** flush shared state and
  hand off immediately. Never start a new work unit in WARN/STOP state.

## Why you can't ask the model (D1)

Token usage lives in the API response envelope, which the model never sees;
agents guess their own usage badly (and optimistically). So the number always
comes from the runtime's on-disk session artifact, and the agent's role is
inverted: it *invokes* measurement at checkpoints; it is never the source of
the number.

## Thresholds

`context-budget.env` (checked in, non-secret):

```sh
CONTEXT_DUMB_ZONE_TOKENS=150000        # STOP
CONTEXT_DUMB_ZONE_WARN_TOKENS=120000   # WARN (defaults to 80% of STOP if unset)
```

Absolute counts, not %-of-window — a 936K Copilot window doesn't move the dumb
zone. Raise here as models improve. **Keep STOP below the runtime's auto-compact
trigger** (150K < Claude Code's ~200K): if compaction fires first, the
deliberate rollover never gets its chance.

## Per-runtime adapters

Session formats are undocumented internals; each runtime gets one discover + one
measure function behind a fixed output contract, so format drift breaks one
function, never the skills/docs/hooks. Where parsing fails, the fallback is
always a bytes÷4 estimate (`method=estimate`), never "unsupported" — ±25% is
fine given the WARN→STOP margin.

| Runtime | Artifact | Signal | Fidelity |
| --- | --- | --- | --- |
| Claude Code | `~/.claude/projects/<cwd-slug>/$CLAUDE_CODE_SESSION_ID.jsonl` when that var is set (transcript basename = session id), else newest `.jsonl` in the slug dir (slug = cwd with `/` and `.` → `-`) | last main-chain `message.usage` sum of input + cache-read + cache-creation tokens; sidechain (sub-agent) rows excluded — they have their own windows | exact (verified 2026-07-22, this workspace) |
| Codex | `~/.codex/sessions/YYYY/MM/DD/rollout-*.jsonl` | last `last_token_usage.total_tokens`; prefers rollouts whose head mentions this cwd | exact (verified 2026-07-22, origin workspace) |
| Copilot VS Code | `$VSCODE_TARGET_SESSION_LOG` when set (Copilot terminal sessions export the live log's path), else newest of `~/Library/Application Support/<app>/User/workspaceStorage/<hash>/chatSessions/` (`<app>` = Code, Code - Insiders, VSCodium; `<hash>` found by grepping the workspace path in `workspace.json`) — mtime alone can pin a stale sibling session whose log flushed later | last `"promptTokens":N` via flat `grep -o` — these files reach 4–5MB with multi-MB single-line records; jq times out | exact (verified 2026-07-22, origin workspace) |
| Copilot CLI | `~/.copilot/history-session-state/` or `~/.copilot/sessions/` | tries `promptTokens`/`input_tokens`/`inputTokens`, else estimate | **unverified** — refine on first real CLI session |
| Gemini CLI | workspace `.gemini/telemetry.log` (local OTLP export, wired in tracked `.gemini/settings.json`), else `~/.gemini/tmp/<hash>/logs.json` | last response's input tokens from the telemetry log (`input_token_count` or OTel `gen_ai.usage.input_tokens`); chat logs carry no token counts → bytes÷4 | exact when the telemetry log has data (**unverified** against a live session); estimate otherwise |

Non-macOS: the Copilot VS Code storage root differs (Linux `~/.config/Code/…`,
Windows `%APPDATA%/Code/…`); BSD `stat -f` already falls back to GNU `stat -c`;
replace the `osascript` notification in `watch` with `notify-send` or equivalent.

## How warnings reach the agent (layered, D8)

No single mechanism covers every runtime, so four layers overlap:

1. **In-band hook (Claude Code):** a `PostToolUse` hook interrupts the agent
   mid-turn with a WARN/STOP message. Escalation-only (one WARN + one STOP per
   session), throttled to one check/minute, fails open — any hook error exits 0
   so it can never block real work. Wiring lives in `.claude/settings.json`
   (gitignored — copy the `hooks` block from `.claude/settings.json.example`).
2. **Mandatory checkpoints in long-running skills (all runtimes):** `onboard-repo`
   and `rlm` carry a measured-checkpoint clause — `record` at every phase
   boundary and act on the exit code.
3. **Polling watcher (hook-less runtimes):** `watch` posts an OS notification on
   status escalation.
4. **Standing instruction:** the "Context Budget" section in `CONTEXT.md`
   (read by every runtime via the symlinked entrypoints).

## Session registration

`register` writes `.context-budget/session-<runtime>.json` pinning the exact
artifact, because newest-mtime discovery is ambiguous under concurrent sessions.
Precedence in every command: explicit `--transcript` > registration > discovery.
The Claude Code hook receives the exact transcript path on stdin, bypassing both.

## Ledger

`record` appends one JSON line per measurement to
`work/context-decay/context-ledger.jsonl` — the safety net doubles as research
data (token growth per workflow phase, hot workflows, estimate-mode accuracy):

```json
{"ts":"2026-07-22T12:00:00Z","runtime":"claude","session":"<file>","tokens":91000,
 "method":"exact","threshold":150000,"status":"OK","label":"onboard-repo: step 4 done"}
```

## Known limitations

- Copilot CLI adapter is a best-effort probe until verified against real files
  (Copilot CLI isn't installed on the origin machine).
- Gemini CLI: the tracked `.gemini/settings.json` enables local-file telemetry
  (`target: local`, no data leaves the machine, `logPrompts: false`), and the
  adapter reads the last response's input-token attribute from
  `.gemini/telemetry.log` (`input_token_count` legacy / `gen_ai.usage.input_tokens`
  semconv) as an exact count. Wiring verified live (a run in this workspace
  produced the log); the parser is fixture-verified for both spellings but not
  yet against a real *successful* Gemini response — blocked on auth on the
  origin machine (personal-OAuth tier discontinued for gemini-cli; needs a
  `GEMINI_API_KEY`, see `docs/operational-knowledge.md`); sessions outside this
  workspace still fall back to the bytes÷4 estimate. The log accumulates across sessions in the workspace,
  so under concurrent Gemini sessions the last entry may belong to the other one.
- Auto-detection (`--runtime auto`) prefers env-var evidence (Claude/Codex) then
  newest artifact — with several runtimes active, `register` or pass `--runtime`.
- The hook checks at most once per minute — a single huge tool result can
  overshoot the threshold between checks.
- Estimates (bytes÷4) drift on binary-heavy or highly-compressed transcripts.
