# Probe — Gemini CLI 0.46.0

- **Binary:** `/opt/homebrew/bin/gemini` → `/opt/homebrew/Cellar/gemini-cli/0.46.0/libexec/lib/node_modules/@google/gemini-cli` (`gemini --version` → `0.46.0`)
- **Date:** 2026-10-12
- **Where:** scratch clone `<scratchpad>/ws-gemini` (`git clone WS`); gemini never ran with cwd in WS.
- **Live status:** BLOCKED on auth. No `GEMINI_API_KEY` in env or keychain, and no auth type in `~/.gemini/settings.json`. Per `docs/operational-knowledge.md`, `oauth-personal` is dead on 0.46 and Vertex ADC returns 403. Everything below marked "static" comes from the installed bundle (`bundle/chunk-6ZHP2EJW.js`) and from July-era files under `~/.gemini/tmp/`.

Commands run (all in the clone unless noted):

```
gemini --version; gemini --help
# capture wiring in clone only: BeforeAgent shim tees stdin+env to scratch;
# capture-only hooks added for SessionStart / SessionEnd / AfterAgent
GEMINI_CLI_TRUST_WORKSPACE=true gemini -p 'run `env | grep -i gemini` and `pwd` in the shell and print the output' --yolo -o json </dev/null
GEMINI_CLI=1 scripts/context-budget.sh register --runtime gemini      # plain shell, not agent shell
ls/jq over ~/.gemini/tmp/ai-workspace-template/chats/*.jsonl         # July sessions, read-only
grep/sed over the npm bundle for GEMINI_SESSION_ID, transcript_path, HookEventName, "session.id", recordMessageTokens
```

Live run result (rc=41; no hook fired, no payload captured, no telemetry.log written):

```
{ "session_id": "f8c25859-6796-4430-a168-3f882f17025e",
  "error": { "message": "Please set an Auth method in your /Users/kashif/.gemini/settings.json or specify one of the following environment variables before running: GEMINI_API_KEY, GOOGLE_GENAI_USE_VERTEXAI, GOOGLE_GENAI_USE_GCA", "code": 41 } }
```

Even when auth fails, `-o json` prints a per-run `session_id` UUID.

## Q1 env id — Verdict: NO (static; live check blocked)

Shells spawned by the agent's shell tool get the sanitized parent env plus `GEMINI_CLI=1`, `TERM`, `PAGER` and `GIT_PAGER`. They get no session id:

```
const baseEnv = { ...sanitizedEnv,
  [GEMINI_CLI_IDENTIFICATION_ENV_VAR]: GEMINI_CLI_IDENTIFICATION_ENV_VAR_VALUE,   // GEMINI_CLI = "1"
  TERM: "xterm-256color", PAGER: ..., GIT_PAGER: ... };
```

`GEMINI_CLI_SESSION_ID` appears in the bundle, but only as a clearcut telemetry key (`gemini_cli_key: 40 /* GEMINI_CLI_SESSION_ID */`). It is not an env var. Only **hook** processes get a session id in their env (Q2).

## Q2 hooks — Verdict: PARTIAL (payload shape YES from static analysis; firing BLOCKED live)

- **Live:** no hook fired. The auth error happens before the hook system starts, so the capture dir stayed empty for BeforeAgent, SessionStart, SessionEnd and AfterAgent.
- **Event names in 0.46** (`HookEventName`): BeforeTool, AfterTool, BeforeAgent, Notification, AfterAgent, **SessionStart**, **SessionEnd**, PreCompress, BeforeModel, AfterModel, BeforeToolSelection. SessionStart and SessionEnd both exist.
- **Every hook payload gets these base fields:**
  ```
  createBaseInput(eventName) {
    const transcriptPath = this.context.geminiClient?.getChatRecordingService()?.getConversationFilePath() ?? "";
    return { session_id: this.context.config.getSessionId(), transcript_path: transcriptPath,
             cwd: ..., hook_event_name: eventName, timestamp: ... };
  }
  ```
  `transcript_path` can be `""`, for example in a SessionStart hook that fires before chat recording starts.
- **Hook process env** also gets `GEMINI_SESSION_ID: input.session_id`, `GEMINI_PROJECT_DIR` and `GEMINI_CWD`, plus `CLAUDE_PROJECT_DIR` for compatibility. Command strings expand `$GEMINI_SESSION_ID`.
- **transcript_path is a per-session file and it carries token counts.** Chat recording writes `~/.gemini/tmp/<project-basename>/chats/session-<ts>-<sessionId[0:8]>.jsonl`. `<project-basename>` is checked against `.project_root`, which holds the absolute project path. Line 1 is `{"sessionId":"<full uuid>","projectHash":…,"startTime":…,"kind":"main"}`. In `recordMessageTokens`, each `gemini` message gets `tokens:{input,output,cached,thoughts,tool,total}`. The July chat files on disk have no `tokens` key, because those runs died on auth before any model reply.
- **Telemetry records do carry `session.id`.** `getCommonAttributes()` puts `"session.id": config.getSessionId()` on every log/metric record, and the OTel resource also has `"session.id"`. This could not be checked live because no telemetry.log was written.

## Q3 register — Verdict: BLOCKED (agent shell unavailable); plain-shell result shown

Could not run from the agent's shell (auth). From a plain shell in the clone with `GEMINI_CLI=1`:

```
$ GEMINI_CLI=1 scripts/context-budget.sh register --runtime gemini
error: no session artifact found for runtime=gemini        (rc=3)
```

No record and no artifact. The clone has no `.gemini/telemetry.log`. The fallback `find ~/.gemini/tmp -name logs.json` also finds nothing: 0.46 has a `logs/` **directory** (empty here) and per-session `chats/*.jsonl`. Even when the fallback does find a file, it searches across **all** projects and picks the newest one. `session_id_for gemini` still hard-codes `workspace`.

## Q4 concurrency — Verdict: BLOCKED live; static: separable

Two concurrent runs could not be started (auth). From the code:
- Both sessions would append to the same `outfile` (`.gemini/telemetry.log`), so their records **would interleave**. They can be told apart by the `session.id` attribute on each record and on the resource.
- Each session also writes its own `chats/session-…-<id8>.jsonl` with per-message `tokens`, so the two never share a chat file.
- `--session-id <uuid>` (new in `--help`) lets a launcher choose the id ahead of time.

## Implications for a fix

- Pin to the hook payload, the same way Claude Code does. Wire a **SessionStart** hook, which exists in 0.46, to register using payload `.session_id`, and switch `session_id_for gemini` from `workspace` to that id. The adapter already reads `payload:.session_id`.
- The best artifact is the per-session chat file (`transcript_path` / `~/.gemini/tmp/<proj>/chats/session-*-<id8>.jsonl`). Sum `tokens.total` or `tokens.input` from the last `gemini` message. Resolve it at BeforeAgent, because `transcript_path` may still be empty at SessionStart. Fallback: glob `chats/*-<id8>.jsonl` inside the dir whose `.project_root` equals the workspace.
- If telemetry stays the source, filter `.gemini/telemetry.log` by `attributes["session.id"]` and drop the reset-the-log heuristic and the "concurrent → estimate-only" one.
- The `logs.json` fallback is stale for 0.46. It also searches every project, so it can bind another project's session. Retire it or scope it to the matching `.project_root` dir.
- There is no env id in the agent's shell (Q1). A `register` run by the agent itself can only bind correctly through hook-written state keyed by `GEMINI_SESSION_ID`, or through a launcher passing `--session-id`.

## To unblock live verification

Needs an AI Studio key: `export GEMINI_API_KEY=…` (or store it in the keychain and export it in the shell that launches `gemini`). Then re-run the command above, plus two concurrent `gemini -p` runs in the clone, to confirm that hooks fire, see the real payload and check the `session.id` values in telemetry.log.
