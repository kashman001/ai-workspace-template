# Context Budget — Measurement, Warning, and Rollover

LLM performance degrades past ~150K context tokens (the "dumb zone") regardless
of advertised window size. This workspace measures every agent session's live
context usage **exactly, from disk**, warns before the threshold, and rolls work
over to a fresh session via a deliberate handoff instead of uncontrolled
automatic compaction.

Pieces: `scripts/context-budget.sh` (measurement core) ·
`scripts/hooks/context-budget-claude-hook.sh` (in-band Claude Code warning) ·
`skills/session-rollover/SKILL.md` (rollover workflow) · `context-budget.env`
(thresholds + relaunch knobs) · `scripts/launch-next-session.sh` (successor
relaunch) · `work/context-decay/context-ledger.jsonl` (measurement ledger).

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
bootstrap prompt it emits — or let the agent relaunch the successor itself per
`ROLLOVER_RELAUNCH` (see "Relaunch knobs"). Don't push new work into a STOP'd
session.

**Session lifecycle:** registering a session (`register`, below) is the
*agent's* job, not yours. It's automatic-by-instruction, not by mechanism — the
standing "Context Budget" section in `CONTEXT.md` tells every agent to register
at session start, which only works for sessions started inside the workspace
tree (where the agent loads that file) by an agent that follows it. Claude Code
is the exception: the `SessionStart` hook shipped in
`.claude/settings.json.example` runs `register` mechanically at every session
start/resume. Unregistered sessions still measure — `check` falls back to
newest-mtime discovery — but only registration pins the exact artifact, which
is what keeps concurrent sessions from reading each other's counts.

## Quickstart — agent

- **Session start:** `scripts/context-budget.sh register` — pins your session
  artifact so later checks aren't confused by concurrent sessions.
- **Every work-unit boundary:** `scripts/context-budget.sh record --label
  "<skill>: <unit> done"` — measures, appends to the ledger, and returns the
  status via exit code.
- **Exit 1 (WARN):** finish the current unit's bookkeeping, then ask the user
  whether to roll over; if declined, write ahead incrementally (see "Rollover
  trigger policy"). **Exit 2 (STOP):** finish only the current atomic step,
  then run `skills/session-rollover/SKILL.md` — no ask. Never start a new work
  unit in WARN/STOP state.

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

## Rollover trigger policy (hybrid: WARN asks, STOP goes)

> **Status:** implemented 2026-08-05 (ADR-0003/ADR-0004): the
> `session-rollover` skill carries the policy, the session-keyed registry and
> `scripts/launch-next-session.sh` implement it (tests:
> `scripts/tests/test-launch-next-session.sh`).

Who decides that a rollover happens, and when:

- **WARN (≥120K) asks.** The agent finishes the current work unit, then asks
  the user "roll over now?". On yes, the **dying agent conducts the rollover
  itself** — mandatory, because the reflect step routes conversation-only
  state to disk and only the dying context has it.
- **Declining at WARN arms write-ahead mode** for the WARN→STOP grace window
  (~30K tokens): the agent routes discussion state to disk *incrementally* at
  each natural pause (settled points → `decisions.md`/analysis docs; open
  threads → the launcher), so the eventual STOP rollover is cheap and nearly
  lossless.
- **STOP (≥150K) goes automatic.** No ask; the agent finishes only the current
  *atomic step*, then rolls over. Mid-discussion, the atomic step is the
  current exchange: answer the user's message first, then roll over, carrying
  the live question verbatim into the launcher's START HERE so the successor
  re-poses it.

Consent lives in this trigger policy — WARN is the ask; STOP in `auto` mode
does not add a second "really launch?" gate (that would recreate `manual`
inside `auto`).

## Relaunch knobs

`context-budget.env` (same file as the thresholds):

```sh
# Relaunch behavior at session-rollover's closing step:
#   off    — emit the paste-ready bootstrap prompt only
#   manual — consent-gated: the agent asks, then runs launch-next-session.sh itself
#   auto   — background-launch the successor where the runtime supports it
#            (claude --bg); fall back to manual elsewhere
ROLLOVER_RELAUNCH=manual
ROLLOVER_RUNTIME=claude   # fallback default only — the actual relaunch runtime
                          # comes from the dying session's own registry record
```

Workspace-level only — no per-project override: the multi-session operating
model varies *sessions* per project, not relaunch policy. `ROLLOVER_RUNTIME`
is a fallback for unregistered sessions; a registered codex session relaunches
a codex successor.

`scripts/launch-next-session.sh <project> [--runtime …] [--bg]` bakes the
load-bearing bootstrap prompt in **verbatim** and launches the chosen runtime
seeded with it. All five runtimes get seeded-interactive launch (`claude`,
`codex`, `gemini -i`, `opencode --prompt`, `copilot -i`); detached background
(`--bg`) is claude-only. Vendor flags live only in the script — re-verify
against `--help` before changing them.

**Option inheritance:** `work/<project>/.rollover-options` (optional; written
by the dying session at `session-rollover` step 6, only from what it actually
knows about its own launch — an absent or stale key is left untouched) holds
three keys: `ROLLOVER_OPT_APPROVAL=default|auto|full` (normalized
approval/permission level, mapped to each runtime's own flag —
e.g. `auto` → codex `--ask-for-approval never`, gemini `--approval-mode
auto_edit`, opencode `--auto`, copilot `--allow-all-tools`; `full` → the
stronger bypass variant of each), optional `ROLLOVER_OPT_MODEL=<model-id>`
(passed through as `--model`), and optional `ROLLOVER_OPT_EXTRA=<raw flags>`
(word-split and appended verbatim — the escape hatch for anything the
normalized mapping doesn't cover). When the file is absent, or
`ROLLOVER_OPT_APPROVAL` is unset/`default`, `launch-next-session.sh` adds no
extra flags — the successor launches with each runtime's own defaults, same
as before this existed.

**Chained rollovers & re-attach.** Background successor chains
(`ROLLOVER_RELAUNCH=auto`, `--bg`) are claude-only (ADR-0003) — on
codex/gemini/opencode/copilot the launcher always prints the ready-to-run
command instead of executing it, so every hop in a non-claude chain is
already human-mediated. To bring a claude chain into an interactive terminal,
run `scripts/attach-session.sh <project>` — the front door for re-attach; it
resolves the latest session for the work item (`work/<project>/.active-session`
lock, falling back to the newest `.context-budget/sessions/` record for that
project when no lock exists) and prints a one-line status
(`project=… runtime=… session=… age=…s live=yes|no locked=yes|no`). Don't
relaunch a session that's still live and locked — the lock enforces one
active session per project — instead the script `exec`s
`claude --resume <session_id>` on a real TTY (no `claude attach` subcommand
exists; `-r/--resume` is the closest supported attach-by-id form, verified
against live `--help` 2026-08-06). For a non-claude runtime it reports that
attach is not possible (those runtimes have no background sessions — the
launcher's `--bg` is claude-only — so the session is already interactive in
someone's terminal). If the lock is released or stale, it prints the launch
hint instead: run `scripts/launch-next-session.sh <project>` from a real
terminal — it `exec`s the successor interactively with options inherited from
`.rollover-options` as above.

## Multi-session model (session-keyed registry + per-project lock)

> **Status:** implemented 2026-08-05 (session-keyed registry + `register
> --project` lock + `release`; regression-tested in
> `scripts/tests/context-budget-registry.test.sh`).

Operating model: one developer runs multiple work items concurrently, each
with its own main session in the same workspace, possibly across runtimes.
Every element must hold under N concurrent sessions:

- **Measurement is per-session.** Registry state moves to
  `.context-budget/sessions/<runtime>-<session-id>.json`
  (`{runtime, artifact, project, registered_at}`); each session writes only
  its own file and resolves itself via runtime env-var identity first
  (`CLAUDE_CODE_SESSION_ID`, `CODEX_THREAD_ID`, `COPILOT_AGENT_SESSION_ID`;
  the Claude Code hook bypasses even that — it receives the exact
  `transcript_path` on stdin). This replaces the scalar
  `session-<runtime>.json`, where `check`/`record` prefer the registry over
  re-discovery, so session A can measure session B's artifact (fired live
  2026-08-05: a `--bg` demo session clobbered the design session's entry).
- **Work-item ownership is per-project.** An advisory lock
  (`work/<proj>/.active-session`: runtime + session-id + timestamp) enforces
  one *active* session per project — the launcher/ledger REPLACE semantics are
  single-writer by construction, and concurrent rollovers on one work item
  would silently destroy each other. The dying session releases the lock after
  the rollover-verification gate; the successor's `register` acquires it;
  stale locks (artifact untouched for hours) are reclaimable.
- **Relaunch targets the dying session's own project** — read from its own
  session record, never from a global "active project" scalar (rejected:
  breaks with concurrent sessions by construction).
- **Successor confirmation** = a new session file appears with the same
  project and a different session-id.
- **Gemini exception:** exact counts come from the shared workspace telemetry
  log, which is architecturally single-session-per-workspace; a second
  concurrent gemini session falls back to estimate-only.

## Per-runtime adapters

Session formats are undocumented internals; each runtime gets one discover + one
measure function behind a fixed output contract, so format drift breaks one
function, never the skills/docs/hooks. Where parsing fails, the fallback is
always a bytes÷4 estimate (`method=estimate`), never "unsupported" — ±25% is
fine given the WARN→STOP margin.

| Runtime | Artifact | Signal | Fidelity |
| --- | --- | --- | --- |
| Claude Code | `~/.claude/projects/<cwd-slug>/$CLAUDE_CODE_SESSION_ID.jsonl` when that var is set (transcript basename = session id), else newest `.jsonl` in the slug dir (slug = cwd with `/` and `.` → `-`) | last main-chain `message.usage` sum of input + cache-read + cache-creation tokens; sidechain (sub-agent) rows excluded — they have their own windows | exact (verified 2026-07-22, this workspace) |
| Codex | `~/.codex/sessions/YYYY/MM/DD/rollout-*.jsonl` — pinned to `rollout-*-<id>.jsonl` when `$CODEX_THREAD_ID` is set (exported to every shell Codex spawns; equals the rollout UUID), else cwd-filtered newest-mtime fallback | last `last_token_usage.total_tokens` | exact (verified 2026-07-22, origin workspace); pin live-verified 2026-07-23 |
| Copilot VS Code | `$VSCODE_TARGET_SESSION_LOG` when set (Copilot terminal sessions export it — on current builds a `debug-logs/<id>` dir whose basename is the session id), mapped to `~/Library/Application Support/<app>/User/workspaceStorage/<hash>/chatSessions/<id>.jsonl` (`<app>` = Code, Code - Insiders, VSCodium; `<hash>` found by grepping the workspace path in `workspace.json`) — deterministic, so it pins the live session even when a sibling's log is newer. Falls back to newest-mtime only when the var is unset (older builds), which can race | last `"promptTokens":N` via flat `grep -o` — these files reach 4–5MB with multi-MB single-line records; jq times out | exact (verified 2026-07-23, origin workspace) |
| Copilot CLI | root `${COPILOT_HOME:-~/.copilot}`; `session-state/<id>/events.jsonl` pinned via `$COPILOT_AGENT_SESSION_ID` (CLI ≥1.0.29, exported to shell commands), else newest-mtime across `session-state/` then legacy `history-session-state/` | tries `promptTokens`/`input_tokens`/`inputTokens`, else estimate | exact (verified 2026-08-05 against a live CLI 1.0.78 session — 73.0k UI match; see `work/automatic-session-rollover/smoke-test-copilot.md`) |
| Gemini CLI | workspace `.gemini/telemetry.log` (local OTLP export, wired in tracked `.gemini/settings.json`), else `~/.gemini/tmp/<hash>/logs.json` | last response's input tokens from the telemetry log (`input_token_count` or OTel `gen_ai.usage.input_tokens`); chat logs carry no token counts → bytes÷4. The telemetry log is shared append-only across sessions, so `register` resets it — a new session never reads the previous session's counts | exact when the telemetry log has data (**unverified** against a live session); estimate otherwise |

Non-macOS: the Copilot VS Code storage root differs (Linux `~/.config/Code/…`,
Windows `%APPDATA%/Code/…`); BSD `stat -f` already falls back to GNU `stat -c`;
replace the `osascript` notification in `watch` with `notify-send` or equivalent.

**Remaining limitation — gemini only.** The session-keyed registry (see
"Multi-session model" above; shipped 2026-08-05) lets concurrent sessions of
any runtime coexist in one workspace, each measuring its own artifact. Gemini
is the exception: its exact counts come from the shared workspace telemetry
log, which is architecturally single-session-per-workspace. `register` guards
the boundary — a telemetry log another live session wrote to in the last 10
minutes is left alone, and the new session degrades to a chat-log bytes÷4
estimate. Explicit `--transcript` still overrides everything.

## How warnings reach the agent (layered, D8)

No single mechanism covers every runtime, so four layers overlap:

1. **In-band hook (all five runtimes):** each runtime's own committed hook
   wiring pushes a WARN/STOP message into the agent's turn. Escalation-only
   (one WARN + one STOP per session), throttled to one check/minute, fails
   open — any hook error exits 0 (or emits the vendor's silent-JSON shape) so
   it can never block real work. Claude Code's wiring lives in
   `.claude/settings.json` (gitignored — copy the `hooks` block from
   `.claude/settings.json.example`); the other four ship committed. Full
   per-runtime wiring/channel/friction breakdown: "Vendor hook deployments"
   below.
2. **Mandatory checkpoints in long-running skills (all runtimes):** `onboard-repo`
   and `rlm` carry a measured-checkpoint clause — `record` at every phase
   boundary and act on the exit code.
3. **Polling watcher (hook-less runtimes):** `watch` posts an OS notification on
   status escalation.
4. **Standing instruction:** the "Context Budget" section in `CONTEXT.md`
   (read by every runtime via the symlinked entrypoints).

## Vendor hook deployments

One shared core, `scripts/hooks/context-budget-hook-lib.sh`, holds all the
logic that must not drift between runtimes — throttle (`CHECK_EVERY`, default
60s), escalation-only emission (only on a WARN/STOP transition, tracked in
`.context-budget/hook-<runtime>-<session>.status`), and fail-open (any
error returns cleanly, never blocks a turn). Each per-runtime wrapper is thin:
it owns only stdin parsing and the vendor-specific output envelope, then calls
into the shared lib for the actual check and message text.

| Runtime | Wiring file | Event | In-band channel | Friction gate |
| --- | --- | --- | --- | --- |
| Claude Code | `.claude/settings.json` (gitignored; copy from `.claude/settings.json.example`) → `scripts/hooks/context-budget-claude-hook.sh` | `PostToolUse` | stderr text + `exit 2` (Claude Code surfaces stderr as an interrupting message on a non-zero exit) | None beyond the local settings copy — no vendor-side trust gate. |
| Codex | `.codex/config.toml` `[[hooks.UserPromptSubmit]]` → `context-budget-codex-hook.sh` | `UserPromptSubmit` | `hookSpecificOutput` JSON on stdout (`{hookSpecificOutput:{hookEventName,additionalContext}}`), `exit 0` | **Hash-based hook trust:** the first run of the hook in a repo prompts the human to approve it (hash recorded; editing the script re-prompts). Automation/CI must pass `--dangerously-bypass-hook-trust`. |
| Gemini CLI | `.gemini/settings.json` `hooks.BeforeAgent` → `context-budget-gemini-hook.sh` | `BeforeAgent` | JSON-only stdout — gemini hooks require valid JSON on every invocation; the wrapper emits `{}` when silent (no jq, no escalation) and `{hookSpecificOutput:{additionalContext}}` on WARN/STOP | Measurement reads the workspace `.gemini/telemetry.log`, not the payload's `transcript_path` (the chat transcript carries no token counts) — exact only once the telemetry log has an entry for this session. **Known limitation:** the telemetry log is shared and append-only across sessions in the workspace, so a successor gemini session's *first-turn* `BeforeAgent` check can read the predecessor's last (large) entry before its own first response lands, and spuriously report STOP on turn one. Accepted — gemini chains are human-launched anyway (see "Chained rollovers & re-attach" above), so a spurious first-turn STOP is caught by a human before it matters. |
| opencode | `.opencode/opencode.json` `"plugin"` array → `.opencode/plugins/context-budget.js`, which shells out to `context-budget-opencode-hook.sh <sessionID>` | `chat.message` | the plugin `push`es a message `Part` (`output.parts.push(...)`) | opencode's Part schema is strict: a bare `{type,text}` part fails validation and kills the turn — every part needs `id`, `sessionID`, and `messageID`. Also: `.opencode/plugins/*.js` is **not** auto-discovered in this repo (empirically verified) — a plugin must be explicitly listed in `opencode.json`'s `plugin` array or it never runs. Measurement is a sqlite read from `~/.local/share/opencode/opencode.db` (`message.data` per-turn `tokens.total`, with a session-column sum fallback; no size-estimate fallback, since the db is shared across all sessions). |
| Copilot CLI | `.github/hooks/context-budget.json` → `context-budget-copilot-hook.sh sessionStart` / `... agentStop` | `sessionStart` (WARN/STOP) and `agentStop` (STOP only) | `sessionStart`: `{additionalContext}` JSON. `agentStop`: `{decision:"block",reason}` — **blocks only at STOP**, because `additionalContext` is model-discounted (phrased as tooling status, easy to ignore) while `block` is a strong lever; guarded by `stop_hook_active` so it never fights the CLI's 8-block continuation limit. | **Folder-trust gate:** repo-committed hooks silently no-op unless the workspace is listed in `~/.copilot/config.json` → `trustedFolders` — no error, no visible signal, the hook simply never fires. Must be pre-seeded (manually, or via config) before hooks work, including in CI. |

## Session registration

`register` writes `.context-budget/sessions/<runtime>-<session-id>.json`
(`runtime, session_id, artifact, project, registered_at`) pinning the exact
artifact, because newest-mtime discovery is ambiguous under concurrent sessions.
The session id comes from the runtime's own env var first
(`CLAUDE_CODE_SESSION_ID`, `CODEX_THREAD_ID`, `COPILOT_AGENT_SESSION_ID`,
`VSCODE_TARGET_SESSION_LOG` basename; gemini has none → fixed id `workspace`),
else it is derived from the artifact path. `check`/`record` resolve-self: they
read only their *own* session file — never another session's — and fall back to
discovery. Precedence in every command: explicit `--transcript` > own session
file > discovery.
The Claude Code hook receives the exact transcript path on stdin, bypassing both.

`register --project <work-item>` also acquires the advisory work-item lock
`work/<proj>/.active-session` (runtime + session-id + timestamp; one *active*
session per work item). A lock held by a live session is warned about, never
stolen; a stale one (holder's artifact untouched > `CONTEXT_LOCK_STALE_SECS`,
default 3h) is reclaimed. `release [--project <proj>]` frees a lock held by
this session (project defaults to the one recorded at registration) — the
`session-rollover` skill calls it after the verification gate.
For Claude Code, registration is also mechanical: a `SessionStart` hook in
`.claude/settings.json.example` runs `register` with the transcript path from
the hook payload at every session start/resume, so even an agent that ignores
`CONTEXT.md` gets pinned (and sees the status line — `SessionStart` hook stdout
is added to the session context).

## Ledger

`record` appends one JSON line per measurement to
`work/context-decay/context-ledger.jsonl` — the safety net doubles as research
data (token growth per workflow phase, hot workflows, estimate-mode accuracy):

```json
{"ts":"2026-07-22T12:00:00Z","runtime":"claude","session":"<file>","tokens":91000,
 "method":"exact","threshold":150000,"status":"OK","label":"onboard-repo: step 4 done"}
```

## Known limitations

- Copilot **VS Code** measurement (`copilot_vscode_measure`) is plausible but
  unverified on current builds — needs a Copilot-licensed VS Code
  (`work/automatic-session-rollover/issues/01-vscode-agent-mode-hooks.md`).
  The CLI adapter was live-verified 2026-08-05.
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
