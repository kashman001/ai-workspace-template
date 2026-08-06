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
scripts/context-budget.sh children               # per-subagent sweep, WARN/STOP only (claude)
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
- **Dispatching a long-running subagent:** `scripts/context-budget.sh
  dispatch-contract --report <path> [--brief <path>] [--gen <n>]` — emit the
  rollover contract into the child's prompt (see "Dispatching long-running
  children").

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

**Per-work-item override:** an optional `work/<project>/context-budget.env`
may set `ROLLOVER_RELAUNCH` (and/or `ROLLOVER_RUNTIME`) for that work item
alone — e.g. one project runs hands-free `auto` chaining while the workspace
default stays `manual`. Precedence in `launch-next-session.sh`: explicit
environment variable > per-item file > global `context-budget.env` > built-in
default (`off`). The per-item file is **committed** — it is standing policy
(unlike `.active-session` and `.rollover-options`, which are per-launch
state), so it applies to anyone who clones the workspace. Only the relaunch
knobs are read per-item; WARN/STOP thresholds remain workspace-global.
`ROLLOVER_RUNTIME` is a fallback for unregistered sessions; a registered
codex session relaunches a codex successor.

`scripts/launch-next-session.sh <project> [--runtime …] [--bg]` bakes the
load-bearing bootstrap prompt in **verbatim** and launches the chosen runtime
seeded with it. The prompt leads with "Work item `<project>` - rollover
session #N" and claude successors additionally get `--name "<project> #N"`,
so session titles (picker, terminal title) read as work item + lineage
number instead of a guess auto-generated from early session content; N lives
in machine-local `work/<project>/.session-seq` (incremented per real launch,
never by `--dry-run`). All five runtimes get seeded-interactive launch (`claude`,
`codex`, `gemini -i`, `opencode --prompt`, `copilot -i`); detached background
(`--bg`) is claude-only. Vendor flags live only in the script — re-verify
against `--help` before changing them.

**Option inheritance:** `work/<project>/.rollover-options` (optional; written
by the dying session at `session-rollover` step 6, only from what it actually
knows about its own launch — an absent or stale key is left untouched) holds
three keys: `ROLLOVER_OPT_APPROVAL=default|edits|auto|full` (normalized
approval/permission level, mapped to each runtime's own flag — `edits`
auto-approves file edits only: claude `--permission-mode acceptEdits`, codex
`--ask-for-approval never`, gemini `--approval-mode auto_edit`, opencode
`--auto`, copilot `--allow-all-tools`; `auto` is the most autonomous mode the
runtime offers *with* a safety net — claude `--permission-mode auto`
(classifier-vetted: routine actions run unattended, risky ones are blocked);
runtimes without a classifier equivalent fall back to their `edits` mapping
with a note; `full` → the stronger bypass variant of each), optional
`ROLLOVER_OPT_MODEL=<model-id>`
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
(`project=… runtime=… session=… role=primary|auxiliary|child|superseded|none
age=…s live=yes|no locked=yes|no`). Don't
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
> --project` lock + `release`); session roles 2026-08-06; child registry,
> release-order guard, `superseded_by` back-stamp and `--takeover`
> 2026-08-06 (slice 1). Regression-tested in
> `scripts/tests/test-context-budget-registry.sh`.

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
  would silently destroy each other. `launch-next-session.sh` releases the
  dying session's own lock immediately before launching (release-before-launch:
  the successor's `register` must not race it, and the attached-manual path
  `exec`s, after which nothing can release); a foreign holder's lock is never
  removed. A `SessionEnd` hook (shipped in `.claude/settings.json.example`;
  claude-only — other runtimes have no end hook) runs `release` on exit, so a
  plainly-closed primary session frees its lock instead of squatting until the
  stale threshold. Without either, the dying session releases manually after
  the rollover-verification gate. The successor's `register` acquires it; stale
  locks (artifact untouched for hours) are reclaimable. The lock file is
  **gitignored**: its validity comes from the holder's artifact mtime, not its
  content, so a committed copy is at best noise and at worst a resurrected
  stale claim on checkout.
- **Session roles — one primary per work item.** Each session engaging a work
  item (`register --project X`) holds exactly one of four roles, recorded in
  its registry file and shown as `role=` by `register`/`attach-session.sh`
  (and in the Claude Code status line via
  `scripts/statusline-context-budget.sh`):
  - **primary** — the lock holder; sole writer of the item's launcher/ledger
    (`next-session.md`/`handoff.md`/`.rollover-options`) and sole rollover
    authority. The lock *is* the primary marker: a session is primary iff
    `work/<proj>/.active-session` carries its identity — on any conflict the
    lock wins over a record's cached `role` claim.
  - **auxiliary** — a concurrent helper registered against the item while a
    live primary holds the lock (review, side-quest). It gets measured and
    associated but never contends for the lock, must not write the
    launcher/ledger, and must not roll the item over.
  - **child** — a subagent session registered *by its parent* against the
    item (`register --parent-session <sid> [--agent-id <id>]
    --transcript <child-artifact> --project X`). The child's session id is
    derived from the artifact, never the env (the registering process is the
    parent); its record carries `parent_session_id`, `depth` (parent's + 1;
    the parent must itself be registered), and optionally `agent_id`. Unlike
    an auxiliary, a child holds a lock and writes its task report — but it
    never contends for the *project* lock: it gets a per-child lock at
    `work/<proj>/.agent-locks/<runtime>-<session-id>.json`, granted only
    when the chain of parent pointers terminates at the current
    project-lock holder (transitive validity, ≤10 hops); otherwise a loud
    refusal degrades it to auxiliary.
  - **superseded** — a former primary after rollover; terminal.
    `launch-next-session.sh` stamps the dying session's record
    (`role=superseded`, `superseded_at`) alongside the pre-launch lock
    release, so the lineage is auditable and a dead predecessor is never
    mistaken for a usable session. At every rollover the newest session in
    the lineage thus becomes primary automatically (release → launch →
    successor's `register` acquires). The successor completes the chain: on
    primary acquisition it back-stamps `superseded_by: <runtime>-<sid>` onto
    the newest same-project superseded record not yet claimed by a
    successor (the launcher can't — the runtime generates the successor's
    id after the stamp), making the lineage walkable in both directions.
- **Release order is bottom-up (I4).** `release` first sweeps stale child
  locks (holder artifact older than the stale threshold — the same liveness
  rule as the project lock), then refuses (exit 3) while live child locks
  block the releaser: the project holder is blocked by any live child lock;
  a child is blocked by live locks naming it as parent. A child's own
  release removes only its `.agent-locks/` file. `.agent-locks/` is
  gitignored for the same reason as the project lock.
- **`register --takeover` is the explicit steal.** It wins even against a
  live holder (human authority beats liveness heuristics), and it is
  recorded, never silent: the old holder's registry record is stamped
  `role=superseded` + `superseded_at` + `superseded_by=<new holder>`, and
  the takeover is announced loudly on stderr. Without the flag, a live
  holder always demotes the newcomer to auxiliary.
- **Relaunch targets the dying session's own project** — read from its own
  session record, never from a global "active project" scalar (rejected:
  breaks with concurrent sessions by construction).
- **Successor confirmation** = a new session file appears with the same
  project and a different session-id.
- **Gemini exception:** exact counts come from the shared workspace telemetry
  log, which is architecturally single-session-per-workspace; a second
  concurrent gemini session falls back to estimate-only.

## Worktrees (workspace-root anchoring)

**Coordination state is keyed to the repository, never to a checkout**
(issue 05, session 19). All coordination scripts resolve `WORKSPACE_ROOT`
through `git rev-parse --git-common-dir` (parent of the shared `.git`), so a
script invoked from any git worktree — Claude Code's `.claude/worktrees/`,
a manually created one, any runtime — reads and writes the **main
checkout's** `.context-budget/`, per-work-item locks, ledger, and
`.session-seq`. Consequences:

- `register`/`record`/`release`/statusline/hooks behave identically in a
  worktree and in the main checkout; the old register-before-isolate
  discipline is obsolete.
- `launch-next-session.sh` invoked from a worktree first syncs the main
  checkout (verifies the worktree has no uncommitted `work/<proj>/` changes
  and no unpushed commits, then `pull --ff-only`s the main checkout; loud
  exit-3 refusal on each — human problem), and launches the successor from
  the main root. The former "no auto-relaunch from worktrees" rule is
  retired.
- Fallback: outside a git repo (template pre-`git init`), or when the git
  root is not this workspace, resolution reverts to the script-relative
  root — single-checkout behavior unchanged.
- A worktree may be deleted while its session still has registry entries or
  locks in the shared root; the release-time stale sweep covers that.

## Per-child sweep (`children`)

No runtime reports a subagent's context usage to its parent — the parent must
measure the child transcript artifacts directly (research R1). `children
[--parent-session <sid>] [--all]` does that sweep for Claude Code sessions
(the only runtime with a verified per-child artifact layout; anything else
dies loudly):

- Enumerates `<parent-artifact-dir>/<parent-uuid>/subagents/agent-*.jsonl`
  (direct children only — a child's own children are its business, R8) and
  measures each with a sidechain-*inclusive* variant of the Claude adapter: a
  subagent transcript's rows are all `isSidechain: true`, so the self-measure
  filter would silently degrade every child to a size estimate.
- **Escalation-only output:** only WARN/STOP children print (one check-style
  `agent= tokens= … status= age= type=` line each; `age` = artifact mtime age,
  the usual liveness signal; `type` = `agentType` from the `.meta.json`
  sibling). `--all` lists OK children too. Summary count goes to stderr.
- **Exit code = worst child status** (0 OK / 1 WARN / 2 STOP), so a parent
  can gate on the sweep exactly like its own `check`. Default parent is the
  current session; `--parent-session <sid>` sweeps another *registered*
  session's children.

What to do when the sweep escalates is the next section's R3 rule: roll the
child (fresh dispatch), don't resume it.

## Dispatching long-running children (`dispatch-contract`, R2/R3)

A child can't measure itself (D1 applies twice over — it has no hook wiring
and no envelope), and no runtime lets a parent reliably message a running
child. So child rollover rests on two portable rules, workable in every
runtime with no child handles at all (research §8/§10/§11):

- **R2 — every long-running child is dispatched under a contract.**
  `dispatch-contract --report <path> [--brief <path>] [--gen <n>]` emits the
  block to include in the child's dispatch prompt: checkpoint by appending a
  progress block to the report file at every work-unit boundary (the report's
  mtime doubles as the child's heartbeat), cap the final return at 15 lines
  with detail in the report, first return line from
  `DONE | DONE_WITH_CONCERNS | BLOCKED | NEEDS_CONTEXT | ROLLOVER_NEEDED`,
  and — on a checkpoint request — flush and yield rather than push on.
  `ROLLOVER_NEEDED` is only ever a *response* (to a checkpoint request, or to
  a WARN/STOP line pushed by the child's own runtime hooks), never the
  child's self-assessment. The subcommand is stateless, runtime-agnostic,
  and ASCII-only (dispatch prompts traverse `%q` and BSD sed in launch
  paths).
- **R3 — successor dispatch is the only rollover verb.** Resume is for
  *continuation* (e.g. SDD fix rounds), and every resume stacks history onto
  the child's transcript — the research's motivating 141.8K child was a
  resumed one. Before any resume, sweep (`children`); at WARN/STOP, ask the
  child to checkpoint, then dispatch a *fresh* child with `--gen N+1` (the
  contract then opens with "read the report file first; finish its open
  items"). Child WARN is the parent's decision, no human ask — humans are
  only consulted at the top level (R7).

Task sizing is the cheapest prevention: scope child tasks so the expected
peak stays under WARN (the measured median child is ~67K; the tail is what
the sweep catches). Deferred to a later slice: parent-persisted dispatch
records and generation fencing (R4), drain mode (R6).

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

The ledger is **gitignored** (machine-local telemetry, same class as
`.gemini/telemetry.log` and the `.active-session` locks): hook appends would
otherwise dirty the tree every session. It is not regenerable — when mining it
for analysis, commit a deliberate dated snapshot (as
`work/automatic-session-rollover/subagent-rollover-stats.md` did), never the
live append-file.

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
