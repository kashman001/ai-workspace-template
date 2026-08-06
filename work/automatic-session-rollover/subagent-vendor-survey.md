# Vendor subagent/child-session capability survey

Method: live `--help` on installed CLIs (gold standard per task brief) + official docs
(WebFetch/WebSearch) + local repo config as hook-vocabulary evidence. No live sessions
started for codex/gemini/opencode per machine gotchas in the task brief.

Versions observed on this machine:
- codex-cli **0.142.4** (`/opt/homebrew/bin/codex`)
- gemini-cli **0.46.0** (`/opt/homebrew/bin/gemini`)
- opencode **1.18.14** (`/opt/homebrew/bin/opencode`)
- GitHub Copilot CLI **1.0.78** (`/opt/homebrew/bin/copilot`)

---

## 1. Codex (OpenAI codex-cli 0.142.4)

**1. Mechanism.** Documented: **"Subagents"** — official docs at
`https://developers.openai.com/codex/subagents` (redirects to
`https://learn.chatgpt.com/docs/agent-configuration/subagents`). Not a CLI subcommand —
`codex --help` has no `agent`/`task`/`subagent` verb. It's a **model-invoked, prompt-triggered**
capability ("spawn two agents", "delegate this in parallel") that Codex only exercises when
explicitly asked; the interactive TUI exposes an `/agent` slash command to "switch between active
agent threads" (per official docs — this is an in-session command, invisible to `--help`, not
independently verified live per the no-live-session constraint).

**2. Child identity.** Documented: subagents run in **"agent threads"** visible in the main
thread's activity feed ("Open a subagent thread from the activity shown in the main thread to
inspect its work"). Official docs do **not** state whether thread IDs are written to disk
(e.g. under `~/.codex/sessions/`) or otherwise addressable outside the parent's live TUI. No
evidence found for a standalone on-disk transcript per subagent thread.

**3. Resumable independently?** No evidence found. `codex resume`/`codex fork` (confirmed live via
`--help`) operate on top-level interactive **sessions** (UUID or name, `--last` for most recent),
not on subagent threads specifically. Whether a subagent thread survives as an independently
resumable unit after the parent session ends is undocumented.

**4. Usage reporting.** No evidence found. Docs only note qualitatively that "each subagent does
its own model and tool work" so "subagent workflows consume more tokens than comparable
single-agent runs" — no per-subagent token/cost breakdown documented.

**5. Nesting.** Documented, but with source conflict:
   - Official docs (learn.chatgpt.com) name only `agents.max_concurrent_threads_per_session`
     ("caps concurrently open spawned-agent threads, excluding the primary") with no stated
     default and no explicit nesting-depth knob.
   - A third-party source (codex.danielvaughan.com, unofficial) claims `agents.max_threads`
     (default 6) and `agents.max_depth` (default 1 — "a child agent can spawn but cannot recurse
     deeper without an explicit change"), implying **one level of nesting is possible by default,
     configurable**.
   Treat the nesting-is-possible claim as **documented but only via a secondary source**; the
   config *key name* itself is inconsistent between official and secondary sources — verify
   against a live `codex features list` / `config.toml` schema before depending on it.

**6. Lifecycle hooks.** Codex has a general **hooks** system (confirmed live: `--dangerously-bypass-hook-trust`
flag exists; local evidence at `.codex/config.toml` in this workspace wires
`[[hooks.UserPromptSubmit]]` → `scripts/hooks/context-budget-codex-hook.sh`). Per third-party
docs (codex.danielvaughan.com "Codex CLI Hooks" guide, first shipped v0.114/March 2026) the event
vocabulary includes `SessionStart`, `UserPromptSubmit`, `PreToolUse`, `PostToolUse`, `Stop`, and
turn-scoped events carry a `turn_id`. **No event in the documented vocabulary is subagent-thread
scoped** (e.g. no `SubagentStart`/`SubagentStop`) — no evidence found of hook events specific to
subagent-thread lifecycle as distinct from the main session's own hooks.

---

## 2. Gemini (gemini-cli 0.46.0)

**1. Mechanism.** Documented: **"Subagents"**, introduced gemini-cli v0.38.1 (Google Developers
Blog: "Subagents have arrived in Gemini CLI"; official docs
`https://geminicli.com/docs/core/subagents/`, mirrored at
`github.com/google-gemini/gemini-cli/blob/main/docs/core/subagents.md`). **Not surfaced as a
top-level CLI verb** in live `--help` (`gemini --help` lists only `mcp`, `extensions`, `skills`,
`hooks`, `gemma`) — confirms the task brief's caution about stale docs shipping non-existent
flags; this feature is real but is **not** a `gemini subagent` or `gemini agent` subcommand.
Subagents are "exposed to the main agent as a tool of the same name" and can be force-invoked
with `@subagent_name` at the start of a prompt, or delegated automatically by the main agent. A
remote variant exists via the **Agent-to-Agent (A2A) protocol** for cross-machine subagents (docs
reference "Remote Subagents", not independently explored here).

**2. Child identity.** Docs state interactions with a subagent happen "in a separate context
loop" but do **not** specify a session-id scheme or an on-disk transcript path for a subagent
run, distinct from `gemini --session-id`/`--list-sessions` (confirmed live: gemini-cli has
general session save/list/resume/delete flags — `-r/--resume`, `--session-file`, `--session-id`,
`--list-sessions`, `--delete-session` — but these are undocumented as applying to subagent
sub-sessions specifically). **No evidence found** tying subagent runs to a discoverable id.

**3. Resumable independently?** No evidence found of a way to resume a specific subagent
invocation. The general `--resume`/`--session-id` flags are for whole gemini-cli sessions.

**4. Usage reporting.** No evidence found of per-subagent token/usage output.

**5. Nesting.** No evidence found either way in the fetched docs excerpt.

**6. Lifecycle hooks.** Gemini CLI has a **hooks** system confirmed live (`gemini hooks --help`
→ only a `migrate` subcommand shown, i.e. hooks are authored in `settings.json`, not built via a
CLI verb). Local evidence, `.gemini/settings.json` in this workspace, shows two wired events:
`BeforeTool` (matcher-based, e.g. gates `read_file|list_directory`) and a second block whose
shown snippet elides the event name but wires `scripts/hooks/context-budget-gemini-hook.sh`
(context-budget docs describe this as a session/turn-boundary push, consistent with Claude Code's
`Stop`-equivalent). **No evidence found** of a hook event scoped to subagent start/stop
specifically (e.g. no `SubagentStop` analog documented for gemini-cli, unlike Claude Code's own
`SubagentStop` hook which this survey was not asked to cover).

---

## 3. OpenCode (1.18.14)

**1. Mechanism.** Documented AND observable live: **"agents" with a `primary`/`subagent` mode**,
invoked via the **Task tool**. Live evidence: `opencode agent create --help` shows
`--mode <all|primary|subagent>` and a `--permissions/--tools` list that includes `task` as an
allowable tool — i.e. the delegation primitive is literally a tool named `task` that a
`primary`-mode agent calls to invoke a `subagent`-mode agent. Official docs
(`https://opencode.ai/docs/agents/`, confirmed via WebFetch) name two built-in primary agents
(**Build**, full tools; **Plan**, restricted/read-only) and three built-in subagents (**General**,
**Explore**, **Scout**); "Subagents are exposed to the main agent as a tool of the same name."
Manual invocation via `@name` is also supported.

**2. Child identity.** Opencode has a general, CLI-visible **session** concept: `opencode session
list`, `opencode session delete <sessionID>`, `opencode export [sessionID]` (all confirmed live).
Docs additionally reference TUI keybinds `session_child_first` and `session_parent` for navigating
"between the main conversation and specialized subagent work" — this is **documented evidence of
a parent/child session hierarchy** distinct from ordinary sessions, but the docs excerpt fetched
does **not** confirm that a subagent's child session gets its own listable `sessionID` in
`opencode session list`/`opencode export`. Reasonable to infer (session storage is unified) but
**not directly confirmed** — flag as inference, not fact.

**3. Resumable independently?** `opencode run --session <id> [--fork]` and top-level
`-s/--session`, `-c/--continue`, `--fork` (all confirmed live) resume/fork **sessions** by id.
Whether a subagent's child-session id is a valid target for these flags is **not documented** in
the fetched page — undetermined.

**4. Usage reporting.** `opencode stats` (confirmed live) reports "token usage and cost
statistics" with `--days`, `--tools`, `--models`, `--project` filters — **no `--agent` or
per-session/per-subagent filter flag observed**, so per-child usage breakout is **not evidenced**
at the CLI-flag level, though `--models`/`--tools` breakdowns could incidentally attribute some
subagent tool calls. `opencode export <sessionID>` dumps full session JSON, which — if child
sessions are separately exported — would carry that session's own token accounting; unconfirmed.

**5. Nesting.** Documented and explicit: **"subagents cannot call other subagents"** — official
docs state this outright, citing prevention of infinite loops and excessive token usage. This is
the clearest, most confident finding in the whole survey.

**6. Lifecycle hooks.** OpenCode's extension surface is **JS plugins**, not a declarative
hook-event JSON like the other three. Local evidence: `.opencode/opencode.json` in this workspace
registers `.opencode/plugins/graphify.js` and `.opencode/plugins/context-budget.js` — plugin code,
not config-declared event names, so the hook vocabulary lives in the plugin JS/TS API surface
(not enumerated here; would require reading the opencode plugin SDK types, out of scope for
`--help`-first method). No CLI `--help` surface exposes hook/event names. No evidence found of a
subagent-lifecycle-specific plugin event.

---

## 4. GitHub Copilot CLI (1.0.78)

**1. Mechanism.** Documented AND observable live — the richest surface of the four. Live
`copilot help commands` output has a dedicated **"Agents / Subagents"** section:
- **`/fleet`** — "Enable fleet mode for parallel subagent execution."
- **`/tasks`** — "View and manage tasks (subagents and shell commands)."
- **`/delegate`** — sends the session to GitHub, which creates a PR (cloud delegation, different
  from local subagents).
- **`/subagents`** — "Configure default and per-agent subagent models."
- **`--agent <agent>`** top-level flag — "Specify a custom agent to use."
Official docs confirm: `https://docs.github.com/en/copilot/concepts/agents/copilot-cli/fleet` and
`https://docs.github.com/en/copilot/how-tos/copilot-cli/speed-up-task-completion`. `/fleet` takes
an implementation plan, the main agent decides whether/how to split it into independent subtasks,
and — acting as **orchestrator** — runs subagents **in parallel** where possible, managing
inter-task dependencies.

**2. Child identity.** `/tasks` lists "background tasks relating to the current session,
including any subtasks handled by subagents" (docs). Stronger, **live-confirmed** evidence: the
top-level `--connect[=sessionId]` flag help text reads *"Connect directly to a remote session
(optionally specify session ID **or task ID**)"*, and `--session-id <id>` help text reads
*"Resume an existing session **or task** by ID, or set the UUID for a new session"* — Copilot CLI
treats **tasks (subagent runs) as a first-class identity class alongside sessions, each
independently addressable by ID**. This is the strongest child-identity finding of the four
runtimes.

**3. Resumable independently?** Yes — inferred with fair confidence from the `--connect`/
`--session-id` help text above (a subagent task ID is accepted wherever a session ID is), plus the
interactive `/tasks` UI lets you "press Enter to view details" on a given subtask (docs). Not
independently tested live (per method constraints, no live sessions were started), so this is
**"observable in --help" + docs corroboration**, not directly executed and verified.

**4. Usage reporting.** `/limits` ("View or edit session limits; the AI Credit limit is a soft
cap"), `/usage` ("Display session usage metrics and statistics"), and `--max-ai-credits <credits>`
(confirmed live) exist at the **session** level. No `--help`/docs evidence of a **per-subagent-task**
token/credit breakdown distinct from the parent session's aggregate usage — undetermined whether
`/tasks` task-detail view (Enter on a task) surfaces per-task usage; not confirmed either way.

**5. Nesting.** No evidence found. Neither `--help` nor the fetched docs page states whether a
`/fleet`-spawned subagent can itself invoke `/fleet` to spawn further subagents.

**6. Lifecycle hooks.** Copilot CLI has a declarative hook system distinct from a plugin-code
model (confirmed via local evidence): `.github/hooks/context-budget.json` in this workspace wires
`sessionStart` and `agentStop` events to
`scripts/hooks/context-budget-copilot-hook.sh`. The **`agentStop`** event name is notable — it is
phrased generically ("agent" rather than "session"), which is suggestive but **not confirmed** to
fire per-subagent-task in addition to (or instead of) the top-level session; no docs evidence
either way. `copilot plugin --help` states plugins can bundle "additional skills, agents, hooks,
MCP servers, and LSP servers," implying a richer hook-event vocabulary exists for plugin authors
than the two events wired locally — not enumerated here (would require the plugin SDK docs,
out of scope for the --help-first method budget).

---

## Cross-cutting observations

- **All four** runtimes now have *some* subagent/delegation concept (as of the versions on this
  machine) — this is a fast-moving area; codex's and gemini's subagent features both look
  recently shipped (gemini-cli v0.38.1; codex hooks first shipped v0.114/March 2026) and are
  **invisible to top-level `--help`** in both cases — they're either prompt-triggered (codex) or
  a runtime "tool exposed to the model" (gemini, opencode) rather than a CLI verb. Copilot is the
  outlier: its subagent surface (`/fleet`, `/tasks`, `/subagents`, `--agent`) is fully enumerated
  in `copilot help commands`.
- **Copilot CLI is the only runtime with live, `--help`-confirmed evidence of task-scoped IDs**
  usable for resume/connect independent of the parent session (`--connect`/`--session-id` accept
  "session ID or task ID").
- **OpenCode is the only runtime with an explicit, documented nesting prohibition**
  ("subagents cannot call other subagents") — a clean, unambiguous design constraint. Codex's
  nesting story is murkier (conflicting official vs. secondary-source config key names). Gemini
  and Copilot: no evidence found either way.
- **No runtime documents per-child token/usage reporting as a first-class, `--help`-visible
  feature.** Usage/credit accounting (`opencode stats`, copilot `/usage`/`/limits`) is
  session-level in all documented cases; anything finer-grained is unconfirmed.
- **Hook vocabularies differ in shape, not just names**: codex and copilot use declarative
  JSON/TOML hook config with named lifecycle events (`UserPromptSubmit`, `sessionStart`,
  `agentStop`, etc., confirmed via this workspace's own `.codex/config.toml` and
  `.github/hooks/context-budget.json`); gemini uses declarative JSON hooks too
  (`.gemini/settings.json`, `BeforeTool` + a second event) but exposes only a `migrate` CLI verb,
  no `list`; opencode uses **JS plugin code**, not declarative config, so its event vocabulary
  isn't visible from `--help` or a settings file at all. **None of the four documents a hook
  event scoped specifically to subagent/child start-stop** — every hook event we found evidence
  for is session/turn-scoped on the *parent*, not child-scoped.
