# Vendor Hook & Seeded-Launch Research (as of 2026-08-05)

Primary-source facts for closing the context-budget detection gap (open question 3
in `relaunch-analysis.md`): per runtime, can a hook/event/plugin run
`scripts/context-budget.sh` automatically at turn boundaries and push the
WARN/STOP result **in-band** (into the model's context), rather than relying on
the agent remembering to poll `record`? Plus seeded-launch facts for opencode
and copilot. Sources: installed CLIs' `--help`/bundled docs, vendor source
repos, and official docs sites only. Verification dates inline; CLIs move fast —
re-verify before shipping.

**Headline: the relaunch-analysis matrix line "no in-band push — agent
discipline only" for codex/gemini is stale.** Both now ship Claude-Code-style
hook systems, and so does Copilot CLI. All four runtimes are push-capable.

---

## 1. Codex CLI (OpenAI) — codex-cli 0.142.4 (installed)

**Hooks system: yes, stable.** `codex features list` (local, 2026-08-05) shows
`hooks  stable  true`. `codex exec --help` exposes
`--dangerously-bypass-hook-trust` ("Run enabled hooks without requiring
persisted hook trust").

- **Events (11)** — verified against
  `codex-rs/config/src/hook_config.rs` (github.com/openai/codex, main,
  fetched 2026-08-05): `PreToolUse`, `PermissionRequest`, `PostToolUse`,
  `PreCompact`, `PostCompact`, `SessionStart`, `SessionEnd`,
  `UserPromptSubmit`, `SubagentStart`, `SubagentStop`, `Stop`. Event names are
  deliberately Claude-Code-compatible (the generated schema for
  `stop.command.output` even says "Claude requires `reason` when `decision` is
  `block`"; repo also carries `codex-rs/external-agent-migration/` for
  importing Claude/Cursor hook configs).
- **Config** — TOML in `~/.codex/config.toml` or `<repo>/.codex/config.toml`
  (also `hooks.json` in the same dirs). Shape per official docs
  (https://developers.openai.com/codex/hooks → redirects to
  https://learn.chatgpt.com/docs/hooks, fetched 2026-08-05):

  ```toml
  [[hooks.PreToolUse]]
  matcher = "^Bash$"
  [[hooks.PreToolUse.hooks]]
  type = "command"
  command = "…"
  timeout = 30
  ```

- **Payload** — hook command gets JSON on stdin. `Stop` input
  (`codex-rs/hooks/schema/generated/stop.command.input.schema.json`, fetched
  2026-08-05) includes `session_id`, **`transcript_path`**, `cwd`, `model`,
  `turn_id`, `last_assistant_message`, `stop_hook_active`. Note
  `transcript_path`: the hook is *handed* the session artifact
  context-budget.sh currently has to discover.
- **In-band output: yes, two channels.**
  - `UserPromptSubmit` output schema supports
    `hookSpecificOutput.additionalContext` (string) — injected as context for
    the turn (`user-prompt-submit.command.output.schema.json`;
    `codex-rs/core/src/hook_runtime.rs` `ContextInjectingHookOutcome` covers
    `SessionStart` and `UserPromptSubmit`). Docs: additionalContext is capped
    ~2,500 tokens by default; oversize spills to disk with a preview.
  - `Stop` output `decision: "block"` + `reason`: per official docs, "tells
    Codex to continue with an automated prompt using your provided reason as
    the continuation text" — i.e. the reason string reaches the model as the
    next turn's prompt.
- **Trust model caveat** — non-managed command hooks require explicit user
  review; trust is recorded against the hook's hash (changed hook ⇒
  re-approval; manage via `/hooks` in the TUI). Automation can bypass with
  `--dangerously-bypass-hook-trust`. Admins: `allow_managed_hooks_only` in
  `requirements.toml` (docs/config.md, openai/codex main, fetched 2026-08-05).
- **Legacy `notify`** — still exists (`codex-rs/config/src/config_toml.rs`
  L209-211: "Optional external command to spawn for end-user notifications",
  `pub notify: Option<Vec<String>>`) but it is user-notification-only (e.g.
  agent-turn-complete desktop alert); its output never reaches the model.
  Superseded for our purpose by the hooks system.

**Verdict: PUSH-CAPABLE** — `UserPromptSubmit` hook running
`context-budget.sh` and emitting `additionalContext` on WARN/STOP, or a `Stop`
hook blocking with the rollover instruction as `reason`.

---

## 2. Gemini CLI (Google) — gemini-cli 0.46.0 (installed, Homebrew)

**Hooks system: yes, first-class.** `gemini --help` lists `gemini hooks`
("Manage Gemini CLI hooks"), whose only subcommand today is `gemini hooks
migrate` — "Migrate hooks from Claude Code to Gemini CLI" (local, 2026-08-05).
The authoritative reference ships **inside the installed package**:
`/opt/homebrew/Cellar/gemini-cli/0.46.0/libexec/lib/node_modules/@google/gemini-cli/bundle/docs/hooks/`
(`index.md`, `reference.md`, `writing-hooks.md`, `best-practices.md`); same
docs online at https://geminicli.com/docs/hooks/reference/ (HTTP 200 verified
2026-08-05). All claims below are from the bundled v0.46.0 `reference.md`.

- **Events (11)**: tool — `BeforeTool`, `AfterTool`; agent — `BeforeAgent`,
  `AfterAgent`; model — `BeforeModel`, `BeforeToolSelection`, `AfterModel`;
  lifecycle — `SessionStart`, `SessionEnd`, `Notification`, `PreCompress`.
- **Config** — `settings.json` `hooks` object; precedence project
  `.gemini/settings.json` → user `~/.gemini/settings.json` → system
  `/etc/gemini-cli/settings.json` (bundled `index.md` L94-99). This workspace
  already runs a `BeforeTool` hook there (graphify reminder) whose JSON output
  uses `decision`/`additionalContext` — working proof on this machine.
- **Mechanics** — stdin JSON in, stdout JSON out; exit 0 = parse stdout, exit
  2 = block with stderr as reason. Base input includes `session_id`,
  **`transcript_path`** ("Absolute path to session transcript JSON"), `cwd`,
  `hook_event_name`, `timestamp` — again, the per-session artifact is handed
  to the hook.
- **In-band output: yes, several channels.**
  - `BeforeAgent` — fires after every user prompt submission;
    `hookSpecificOutput.additionalContext` is "appended to the prompt for this
    turn only". Direct equivalent of Claude's `UserPromptSubmit` push.
  - `AfterTool` — `hookSpecificOutput.additionalContext` "appended to the tool
    result for the agent".
  - `AfterAgent` — fires once per turn after the final response; `decision:
    "deny"` + `reason` sends the reason "to the agent as a new prompt" (retry
    semantics — usable as a Stop-style continuation push, though heavier).
  - `SessionStart` — `additionalContext` injected as first turn.
- **Bonus** — `AfterModel` input includes the stable `LLMResponse` with
  `usageMetadata.totalTokenCount`: a hook could read real token usage straight
  from the API envelope, no artifact parsing at all.

**Verdict: PUSH-CAPABLE** — `BeforeAgent` hook in `.gemini/settings.json`
running `context-budget.sh` and returning `additionalContext` on WARN/STOP.

---

## 3. OpenCode (sst) — CLI not installed; docs + source verified

Sources: https://opencode.ai/docs/plugins/ and https://opencode.ai/docs/cli/
(fetched 2026-08-05); type definitions
`packages/plugin/src/index.ts` and TUI command source
`packages/opencode/src/cli/cmd/tui.ts` (github.com/sst/opencode, `dev`
branch, fetched 2026-08-05).

- **Plugin API** — JS/TS plugins (this workspace: `.opencode/plugins/
  graphify.js`) export `async ({ client, project, directory, worktree,
  serverUrl, $ }) => Hooks`. `$` is Bun's shell API (**plugins can run shell
  commands**); `client` is a full OpenCode SDK client bound to the running
  server.
- **Hooks interface** (`export interface Hooks`, packages/plugin/src/index.ts):
  `event` (receives every bus event, incl. `session.idle`, `session.created`,
  `session.compacted`, `session.error`…), `chat.message`, `chat.params`,
  `chat.headers`, `permission.ask`, `command.execute.before`,
  `tool.execute.before`, `tool.execute.after`, `shell.env`,
  `tool.definition`, plus experimental `chat.messages.transform`,
  `chat.system.transform`, `session.compacting`,
  `compaction.autocontinue`, `text.complete`.
- **In-band injection channels:**
  - `chat.message` — fires on each new user message with mutable
    `output: { message: UserMessage; parts: Part[] }`; a plugin can append a
    text part carrying the WARN/STOP line (per-user-turn push, the
    `UserPromptSubmit` analogue).
  - `tool.execute.after` — mutable `output.output` (string): append budget
    status to a tool result. (`tool.execute.before` mutable `output.args` is
    what the existing graphify plugin uses.)
  - `event` on `session.idle` + `client` — a plugin can observe turn
    completion and push follow-up via the SDK (out-of-turn, heavier).
  - Caveat: mutation semantics are established by official examples for the
    tool hooks; `chat.message` part-append is typed as mutable output but not
    explicitly documented as a context-injection recipe — smoke-test before
    relying on it.
- **Seeded launch** — the default TUI command is `opencode [project]` with an
  explicit **`--prompt` option ("prompt to use")** — interactive session
  pre-seeded from the shell. Verified in source (`tui.ts` L73-102; not
  mentioned on the docs CLI page, source wins). `opencode run "<prompt>"` is
  the headless path (flags per docs: `--continue`/`-c`, `--session`/`-s`,
  `--fork`, `--model`, `--agent`, `--format json`, `--attach <url>`).
- **Background** — no single detached flag, but composable: `opencode serve`
  (headless API server), `opencode run --attach http://…` (drive a session on
  that server), `opencode attach` (connect a TUI to it later). Nearest
  equivalent of `claude --bg` + `claude attach`, at the cost of managing a
  server process.

**Verdict: PUSH-CAPABLE** (via a `.opencode/plugins/context-budget.js`
plugin; `chat.message`/`tool.execute.after` mutation — verify by smoke test
once the CLI is installed). **LAUNCH: seeded-interactive** (`opencode
--prompt "<text>"`; plus headless `opencode run` and a composable
serve/attach background story).

---

## 4. GitHub Copilot CLI / cloud agent — CLI not installed; official docs

Sources (all docs.github.com, fetched 2026-08-05): "About hooks"
(`/copilot/concepts/agents/about-hooks`), "Hooks configuration reference"
(`/copilot/reference/hooks-configuration`), "About Copilot CLI"
(`/copilot/concepts/agents/about-copilot-cli`), "Run CLI programmatically"
(`/copilot/how-tos/copilot-cli/automate-copilot-cli/run-cli-programmatically`),
"CLI command reference"
(`/copilot/reference/copilot-cli-reference/cli-command-reference`).

- **Hooks system: yes** — supported by **Copilot CLI** and the **Copilot
  cloud agent** (VS Code is not listed as a supported surface, but the
  reference documents PascalCase aliases — `SessionStart`, `PreToolUse`,
  `Stop` — labelled "VS Code compatible").
- **Events** — `sessionStart`, `sessionEnd`, `userPromptSubmitted`,
  `preToolUse`, `postToolUse`, `postToolUseFailure`, `agentStop`,
  `subagentStart`, `subagentStop`, `errorOccurred`, plus `preCompact`,
  `userPromptTransformed`, `permissionRequest`, `notification` in the
  reference.
- **Config** — JSON files: repo-level `.github/hooks/*.json`; personal level
  (CLI only) `~/.copilot/hooks/*.json`. Format: `{ "version": 1, "hooks":
  { "<event>": [ { "type": "command|http|prompt", … } ] } }`; command hooks
  take `bash`/`powershell`/`command`, `cwd`, `env`, `timeoutSec` (default
  30s). Exit 0 ⇒ stdout parsed as JSON.
- **Payload** — JSON on stdin; `agentStop` input includes `sessionId`, `cwd`,
  **`transcriptPath`**, `stopReason`, `stop_hook_active` — session artifact
  handed to the hook here too.
- **In-band output: yes.**
  - `agentStop`/`subagentStop`: `decision: "block"` + `reason` — the reason
    becomes "the prompt for the next turn", forcing continuation (CLI
    overrides the hook after 8 consecutive blocks to prevent loops).
  - `postToolUse`: `additionalContext` "appended to tool output for the
    model" (capped 10 KB across hooks); `postToolUseFailure` likewise.
  - `sessionStart`: can inject `additionalContext` into the session.
  - `preToolUse`: `permissionDecision` allow/deny/ask + `modifiedArgs`.
- **Seeded launch / background** — `copilot` starts interactive; `copilot -p
  "<prompt>"` (alias `--prompt`) is programmatic: "completes the task and then
  exits"; piped stdin (`echo … | copilot`) is an alternative. `--resume`
  resumes a previous interactive session, but **no documented way to start an
  interactive session pre-seeded with a fresh prompt**, and **no
  background/detached mode is documented**. (Curiosity: the `prompt` hook
  type fires a natural-language prompt on `sessionStart` for new interactive
  sessions — a repo-committed hook could auto-issue a fixed first prompt,
  which is a roundabout seeding channel for interactive sessions.)

**Verdict: PUSH-CAPABLE** (command hook on `agentStop`/`postToolUse` with
`reason`/`additionalContext`). **LAUNCH: headless-only** (`copilot -p` runs
and exits; no seeded-interactive flag, no detached mode).

---

## Summary matrix (verified 2026-08-05)

| Runtime | Hook mechanism | Turn-boundary event | In-band channel | Push verdict | Seeded launch |
|---|---|---|---|---|---|
| **claude** (baseline) | settings hooks (already deployed) | Stop / UserPromptSubmit | hook stdout → model | PUSH-CAPABLE (live today) | `claude "<prompt>"`, `claude --bg` |
| **codex** 0.142.4 | `[[hooks.<Event>]]` in `~/.codex/config.toml` or `.codex/config.toml`; 11 Claude-compatible events; hash-based trust gate | `Stop`, `UserPromptSubmit` | `additionalContext` (~2.5K-token cap) / Stop-block `reason` → continuation prompt | **PUSH-CAPABLE** | `codex "<prompt>"` (unchanged) |
| **gemini** 0.46.0 | `hooks` object in `.gemini/settings.json` (project/user/system); 11 events; `gemini hooks migrate` from Claude Code | `BeforeAgent`, `AfterAgent` | `additionalContext` appended to prompt / deny-`reason` as new prompt | **PUSH-CAPABLE** | `gemini -i "<prompt>"` (unchanged) |
| **opencode** (dev) | JS plugin `.opencode/plugins/*.js`; Hooks interface + full event bus; Bun `$` shell + SDK client | `chat.message` (per user turn), `session.idle` (bus) | mutate `chat.message` parts / `tool.execute.after` output; SDK prompt push | **PUSH-CAPABLE** (smoke-test the mutation channel) | **seeded-interactive**: `opencode --prompt "<text>"`; headless `opencode run`; background via `serve`+`attach` |
| **copilot CLI** | JSON hooks `.github/hooks/*.json` (repo) / `~/.copilot/hooks/*.json` (personal); 14 events; also cloud agent | `agentStop`, `userPromptSubmitted` | Stop-block `reason` → next-turn prompt / `additionalContext` on postToolUse & sessionStart (10 KB cap) | **PUSH-CAPABLE** | **headless-only**: `copilot -p` (runs+exits); `--resume`; no detached mode |

No runtime in scope is USER-VISIBLE-ONLY or POLL-ONLY. Codex's legacy
`notify` (config_toml.rs L209) is the only user-visible-only mechanism and is
superseded by its hooks.

## Implications for the context-budget push model

1. **The detection gap (relaunch-analysis "open question 3") is closable on
   every runtime.** The "agent discipline only" rows for codex/gemini are
   stale; both now take a hook that runs `scripts/context-budget.sh` at a
   turn boundary and injects WARN/STOP text the model actually sees —
   mirroring the Claude Code hook. The pure-discussion failure mode (agent
   never runs `record`) disappears wherever the hook is installed.
2. **Every hook payload includes the session artifact path**
   (`transcript_path` on codex and gemini, `transcriptPath` on copilot).
   `context-budget.sh` can take it via its existing `--transcript` override —
   this *also* fixes the scalar-registry/session-discovery problems recorded
   in relaunch-analysis for hook-driven invocations, and dissolves gemini's
   single-session-per-workspace telemetry limitation for the hook path
   (telemetry stays as the non-hook fallback).
3. **Event choice per runtime:** codex `UserPromptSubmit` (+ optional `Stop`),
   gemini `BeforeAgent` (+ optional `AfterAgent`), opencode `chat.message`
   plugin, copilot `agentStop` (avoid its 8-block continuation guard by only
   blocking at STOP, not every turn). Per-turn cost: one shell exec each.
4. **Frictions to plan for:** codex requires per-user hook trust approval
   (first run prompts; hash changes re-prompt; CI needs
   `--dangerously-bypass-hook-trust` or managed `requirements.toml` hooks);
   gemini hooks demand JSON-only stdout (existing graphify hook shows the
   pattern); opencode's chat-message mutation channel should be smoke-tested
   once the CLI is installed; copilot personal hooks live outside the repo
   (`~/.copilot/hooks/`) unless committed at `.github/hooks/`.
5. **Launcher matrix updates** for `launch-next-session.sh`: opencode gains a
   real seeded-interactive branch (`opencode --prompt`) and a composable
   background story (`opencode serve` + `run --attach` + `attach`); copilot
   remains headless-only (`copilot -p`), no background tier — the
   ready-to-run-command fallback stands.
