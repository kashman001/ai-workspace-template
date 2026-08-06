# OpenCode smoke test — real-installation verification of vendor-hooks-research §3

Date: 2026-08-05. Platform: macOS (darwin), zsh, Homebrew.
Purpose: confirm/refute the source-verified claims in
`vendor-hooks-research.md` §3 (OpenCode) on a live install.
Scratch project: `/private/tmp/claude-501/-Users-kashif-Developer-experiments-ai-workspace-template/f2612050-6cf0-445b-a146-0792f40d3cb0/scratchpad/opencode-smoke/`
(plain dir, **not** a git repo — see project-identity note in §4).

## 0. Install + auth

- **Install**: `brew install sst/tap/opencode` → **opencode 1.18.14**
  (`/opt/homebrew/Cellar/opencode/1.18.14`, single ~140MB binary). Clean install,
  no post-install steps.
- **Auth**: `opencode providers list` (alias of `auth`) → `0 credentials`
  (`~/.local/share/opencode/auth.json`); no `ANTHROPIC_API_KEY` etc. in env.
  **Not a blocker**: `opencode models` exposes a built-in `opencode/*` provider
  with zero-auth free models (`opencode/big-pickle`,
  `opencode/deepseek-v4-flash-free`, `opencode/nemotron-3-ultra-free`, …).
  `opencode run -m opencode/big-pickle "Reply with exactly: SMOKE-OK"` → `SMOKE-OK`,
  cost $0, **no login of any kind**. So *nothing below was blocked on auth*; all
  model-dependent tests used `-m opencode/big-pickle`.

## 1. Launch claims

- **`--prompt` on the default TUI command — CONFIRMED.** `opencode --help`,
  Options block of `opencode [project]` (default command):
  `--prompt        prompt to use                    [string]`.
  (Research said source-only/undocumented; it is present in the shipped CLI help.)
  TUI itself not launched (no TTY) — flag existence + help text is the evidence.
- **`opencode run` — CONFIRMED** (see SMOKE-OK above). `opencode run --help`
  confirms all researched flags: `-c/--continue`, `-s/--session`, `--fork`,
  `-m/--model`, `--agent`, `--format {default,json}`, `--attach <url>` — plus
  extras worth knowing: `--command` (run a slash command), `--dir` (run in/on a
  remote path), `--port`, `--variant` (reasoning effort), `--thinking`,
  `-i/--interactive`, `--auto` (auto-approve permissions), `--title`, `-f/--file`,
  `--share`, and `--pure` (**disables external plugins** — the kill switch for
  any injection plugin).
- **`opencode serve` — CONFIRMED headless server.**
  `opencode serve --port 14996` → `opencode server listening on http://127.0.0.1:14996`
  (warns `OPENCODE_SERVER_PASSWORD is not set; server is unsecured`). REST API
  verified: `GET /session` → JSON session list (incl. token totals),
  `GET /session/{id}/message` → full transcript with per-message token usage,
  `GET /doc` → 200 (OpenAPI). `/app` serves the web UI.
- **`opencode attach <url>` — CONFIRMED exists** (top-level command in `--help`:
  "attach to a running opencode server"). Not driven (TUI).
- **`opencode run --attach http://127.0.0.1:14996 "…" ` — CONFIRMED works**, with
  a caveat: the run executed **on the server** (verified via
  `GET /session/{id}/message`: assistant reply `ATTACH-OK PINEAPPLE` — note the
  server-side plugin injected too), exit 0, but in this non-TTY capture the
  client printed only the `> build · big-pickle` header, **not** the reply text.
  Scripted use should read the result from the server API / `--format json`
  rather than trusting attached-mode stdout.

## 2. Plugin injection — the load-bearing claim

Plugin file: `.opencode/plugins/context-budget-test.js` in the project dir;
loaded automatically (init logged on every `opencode run` in that dir, and by a
`serve` started there — attached runs get the server's plugins).

### 2a. `chat.message` part-append → model — **CONFIRMED, with a schema trap**

- **Naive append FAILS the whole run.** Pushing a bare
  `{ type: "text", text: "…" }` onto `output.parts` aborts the turn with a
  client-side `UnknownError: Unexpected server error`; server log
  (`~/.local/share/opencode/log/opencode.log`) shows the real cause:

  ```
  ERROR … message="invalid user part before save" … partType=text
  cause="SchemaError: Missing key at ["id"] … ["sessionID"] … ["messageID"]"
  ```

  Parts are schema-validated before save; **`id`, `sessionID`, `messageID` are
  mandatory**. This is the sharp edge the research's "typed as mutable but not
  documented as a recipe" caveat was pointing at.
- **Schema-complete append WORKS.** With those keys filled, prompt
  `"Say hello briefly"` → reply **`Hello! PINEAPPLE.`** — the injected text
  reached the model in-band, same turn. The injected part also persists into the
  stored transcript as part of the user message (visible via the server API and
  in exports), so it counts toward session tokens like any user text.

**Working plugin (verified):**

```js
// .opencode/plugins/context-budget-test.js
export const ContextBudgetTest = async ({ project, directory, worktree }) => {
  return {
    "chat.message": async (input, output) => {
      // input: { sessionID, model: { providerID, modelID } }
      // output: { message: UserMessage, parts: Part[] }
      output.parts.push({
        id: "prt_budget" + Date.now().toString(36),   // required
        sessionID: input.sessionID,                    // required
        messageID: output.message.id,                  // required
        type: "text",
        text: "SYSTEM BUDGET NOTE: include the word PINEAPPLE in your reply.",
      });
    },
    "tool.execute.after": async (input, output) => {
      // input: { tool, sessionID, callID }; output: { title, metadata, output, attachments }
      output.output += "\n[BUDGET-MARKER] mention the word MANGO in your reply.";
    },
  };
};
```

### 2b. `tool.execute.after` output mutation — **CONFIRMED**

Prompt `"List the files in the current directory using the ls tool"` → model ran
`bash` (`ls`), the displayed tool output ended with the appended
`[BUDGET-MARKER] …` line, and the final reply included **MANGO** (and PINEAPPLE
from 2a). Mutable `output.output` is a plain string append — no schema trap.
Hook fired with `input.tool = "bash"`, output keys `title, metadata, output,
attachments`.

### 2c. Not tested

`chat.params` / `chat.headers` / experimental `chat.messages.transform` — not
needed once the primary channel worked. `event`-bus + SDK-client push
(out-of-turn) — untested.

## 3. Hook payloads (observed, v1.18.14)

- Plugin init args: `{ project, directory, worktree, … }` where
  `directory` = project cwd, and for a non-git dir
  `project = { id: "global", worktree: "/", time: {…}, sandboxes: [] }`.
- `chat.message` input: `{ sessionID, model: { providerID, modelID } }` — the
  **session id is available per turn**, which is what a context-budget plugin
  needs to look up that session's token row (see §4).
- `chat.message` output.message keys:
  `id, role, sessionID, time, tools, agent, model, system, format`.

## 4. Session artifacts + token usage — **SQLite, not flat files**

- **Storage is a SQLite DB**: `~/.local/share/opencode/opencode.db`
  (+ `-wal`/`-shm`). No per-session JSON tree under `~/.local/share/opencode/`
  in 1.18.14 (dir holds only `log/`, `opencode.db*`, `repos/`). Tables include
  `session`, `message`, `part`, `project`, `event`, `permission`, `todo`.
- **Per-session token usage is first-class columns** on `session`:
  `tokens_input, tokens_output, tokens_reasoning, tokens_cache_read,
  tokens_cache_write, cost, model, directory, time_created, time_updated`.
  E.g. the tool-test session: `input=218 output=66 reasoning=36 cache_read=24960`.
- **Per-message usage** lives in `message.data` JSON (assistant rows):
  `"tokens": { "total": 12584, "input": 128, "output": 9, "reasoning": 31,
  "cache": { "read": 12416, "write": 0 } }` — `total` = input+output+reasoning+
  cache.read, i.e. a direct **context-size reading per turn**. This is exactly
  what `scripts/context-budget.sh` measures from Claude session artifacts.
- Access paths, cheapest first:
  1. `sqlite3 ~/.local/share/opencode/opencode.db "select tokens_input+tokens_cache_read+tokens_output+tokens_reasoning from session where id='<sid>'"`;
  2. `opencode export <sessionID>` — full session JSON to stdout (preceded by a
     human "Exporting session: …" line — strip it before parsing);
  3. `GET <server>/session` / `/session/{id}/message` when a server is up;
  4. `opencode stats` — aggregate tokens/cost/tool-usage report.
- **Project identity caveat**: a non-git directory maps to `projectID=global`,
  `worktree=/`. Session→project scoping for budget queries should key on the
  `session.directory` column (absolute cwd, present and correct) rather than
  project id.
- Logs: `~/.local/share/opencode/log/opencode.log` (plugin/schema errors land
  here, not on the client).

## Verdict

- **PUSH: CONFIRMED — PUSH-CAPABLE.** Primary channel `chat.message`
  part-append works end-to-end (model echoed the injected instruction), **but
  the appended Part must carry `id`, `sessionID` (from hook input), and
  `messageID` (from `output.message.id`)** — a bare `{type,text}` part fails
  schema validation and kills the whole turn. Secondary channel
  `tool.execute.after` `output.output` append also works (marker reached the
  model). A future `.opencode/plugins/context-budget.js` should use the
  chat.message shape from §2a verbatim.
- **LAUNCH: CONFIRMED — seeded-interactive + headless + composable background.**
  `--prompt` exists on the default TUI command (help-verified);
  `opencode run "<prompt>"` works headless with zero auth via the free
  `opencode/*` provider; `serve` + `run --attach` round-trip works (server-side
  execution verified via API), `attach` exists. Caveat: attached non-TTY `run`
  did not echo the reply — read results via API/`--format json`.
- **Session/token measurement: CONFIRMED and better than expected** — token
  usage (incl. cache-read, per turn and per session) is queryable straight from
  `~/.local/share/opencode/opencode.db`; sessionID reaches the plugin every turn.
- **Untestable here**: actual TUI behavior of `--prompt`/`attach` (no TTY);
  provider auth via `opencode auth login` (interactive; unnecessary for the
  smoke test thanks to the free provider); `chat.params`/transform hooks and
  event-bus SDK push (skipped — primary channel sufficed).
