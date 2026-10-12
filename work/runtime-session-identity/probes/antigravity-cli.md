# Probe — Antigravity CLI

- **Version:** `agy` 1.3.3 (`~/.local/bin/agy`, Go binary), model reported `gemini-3.8-flash-high`
- **Date:** 2026-10-12 (session 3)
- **Where:** fresh clone of WS at `<scratchpad>/ws-agy` (HEAD `12ad070`), under `/private/tmp/...`, outside the `trustedWorkspaces: ["/Users/kashif"]` entry in `~/.gemini/antigravity-cli/settings.json`.
- **Clone-only changes:** `.agents/hooks.json` with one named hook `probe` that registers
  `<scratchpad>/agy-cap.sh <Event>` for `PreToolUse`, `PostToolUse` (matcher `*`),
  `PreInvocation`, `PostInvocation` and `Stop`. The script saves the stdin payload plus
  `env | grep -iE 'antigravity|agy|jetski|gemini|conversation'` to `<scratchpad>/agy-payloads/`.
  `.agents/probe.sh` prints the same env grep, `pwd`, pid/ppid.
- **Docs source:** no `--help` coverage of hooks. The hook spec is embedded in the binary
  (`strings agy`, "Lifecycle Hooks (`hooks.json`)" section) and the bundled guide
  `~/.gemini/antigravity-cli/builtin/skills/antigravity_guide/`.
- **Commands run** (cwd = clone, `< /dev/null`):
  1. `agy -p '<run env grep; pwd>' --sandbox --print-timeout 150s --output-format json` (run1)
  2. same, prompt `sh .agents/probe.sh`, with the PreToolUse hook returning
     `{"decision":"allow","permissionOverrides":["command(sh .agents/probe.sh)"]}` (run2)
  3. two concurrent `agy -p` runs, started 2 s apart (q4a/q4b)
  4. from my shell, in the clone: `env -i HOME USER PATH ANTIGRAVITY_CONVERSATION_ID=<run2 id> scripts/context-budget.sh register` (with and without `--runtime antigravity`)
- **Not run:** `--dangerously-skip-permissions`. The Claude Code auto-mode classifier
  denied it ("Create Unsafe Agents"). Without it, headless mode auto-denies every
  `run_command`, so the agent's own shell never ran (see Q1).

## How Antigravity works (facts the plan needs)

- **Session id = `conversationId`** (UUID). `--output-format json` prints it as
  `conversation_id`; `--conversation <id>` resumes it.
- **Transcript:** `~/.gemini/antigravity-cli/brain/<id>/.system_generated/logs/transcript_full.jsonl`
  (plus a compact `transcript.jsonl` and `chunks/`). A per-conversation SQLite store
  also lands at `~/.gemini/antigravity-cli/conversations/<id>.db`. The IDE and app use
  `antigravity-ide/` and `antigravity/` in place of `antigravity-cli/` (per the embedded doc).
- **Tokens:** each `PLANNER_RESPONSE` line carries `input_tokens`, `cache_read_tokens`,
  `output_tokens`. A measurer can read the last one.
- **Hooks:** `hooks.json` in a customization root: workspace `.agents/` (also `.agent/`,
  `_agents/`, `_agent/`), a global root, or `plugins/<name>/hooks.json`. Top-level keys
  are hook *names*; each names events. Events: `PreToolUse`, `PostToolUse` (grouped,
  `matcher` + `hooks`), `PreInvocation`, `PostInvocation`, `Stop` (flat). **No
  SessionStart event**; `PreInvocation` with `invocationNum: 0` is the first event of a
  conversation. Command runs via `sh -c` with cwd = the directory holding `hooks.json`.
  Payload keys are camelCase.
- **None of our committed hook files are read by `agy`** (`.claude/`, `.codex/`,
  `.github/hooks/`, `.gemini/settings.json`); it needs its own `.agents/hooks.json`.

## Q1 — env id in the agent's shell

**Verdict: blocked in the agent's shell; YES in hook processes.**

Hook processes get `ANTIGRAVITY_CONVERSATION_ID` equal to the payload's `conversationId`
(run1, `PreInvocation-152305-2386.env`):

```
ANTIGRAVITY_CONVERSATION_ID=ed75a355-63bb-44d4-9a2b-8aee475bfaf2
PWD=<scratchpad>/ws-agy/.agents
```

The agent's `run_command` never ran. run1 and run2 both ended with
`"denied_actions":[{"action":"command","display_name":"RunCommand"}]` and stderr:

```
jetski: no output produced — a tool required the "command" permission that headless mode
cannot prompt for, so it was auto-denied. Add an allow-rule under permissions.allow in
settings.json (e.g. command(<target>)). Alternatively, re-run with
--dangerously-skip-permissions to auto-approve all tools.
```

A PreToolUse hook answering `allow` plus `permissionOverrides` did **not** lift the
headless deny (run2). The only allow-list is the user's global
`~/.gemini/antigravity-cli/settings.json`; I did not edit it. The binary references
`process.env.ANTIGRAVITY_CONVERSATION_ID` in embedded JS, which suggests (unverified)
that spawned processes inherit it too.

**To unblock:** one run with `--dangerously-skip-permissions` in the scratch clone, or a
temporary `command(sh .agents/probe.sh)` allow-rule in the global settings, or an
interactive `agy` session where a person approves the command.

## Q2 — hooks fire? payload fields

**Verdict: YES**, with no trust step: the clone is outside `trustedWorkspaces` and the
hooks fired anyway, with no prompt. (Contrast: Codex and Copilot skip untrusted hooks
silently.)

`PreInvocation` (run1, the first event, `invocationNum: 0`):

```json
{
  "artifactDirectoryPath": "/Users/kashif/.gemini/antigravity-cli/brain/ed75a355-63bb-44d4-9a2b-8aee475bfaf2",
  "conversationId": "ed75a355-63bb-44d4-9a2b-8aee475bfaf2",
  "initialNumSteps": 1,
  "invocationNum": 0,
  "modelName": "gemini-3.8-flash-high",
  "transcriptPath": "/Users/kashif/.gemini/antigravity-cli/brain/ed75a355-63bb-44d4-9a2b-8aee475bfaf2/.system_generated/logs/transcript_full.jsonl",
  "workspacePaths": ["<scratchpad>/ws-agy"]
}
```

`PreToolUse` adds `stepIdx` and `toolCall {name: "run_command", args: {CommandLine, Cwd, …}}`;
same `conversationId` / `transcriptPath`. `transcriptPath` exists on disk by the time
the run ends (`ls` of the `logs/` dir shows `transcript_full.jsonl`, 1482 bytes).

`PostToolUse`, `PostInvocation` and `Stop` did **not** fire in these runs: each one
ended on the denied tool call. Their firing is unverified.

## Q3 — `register` binds its own transcript

**Verdict: NO. It binds the wrong file and reports OK.**

`register` with no `--runtime`, `ANTIGRAVITY_CONVERSATION_ID` set:

```
registered gemini session workspace artifact: /Users/kashif/.gemini/tmp/kashif/logs.json
runtime=gemini method=estimate tokens=0 threshold=150000 warn=120000 pct=0 status=OK cache=- artifact=/Users/kashif/.gemini/tmp/kashif/logs.json
```

`detect_runtime` has no Antigravity case; it falls to newest-file discovery and picks
the stale Gemini CLI log. `--runtime antigravity` → `error: no session artifact found
for runtime=antigravity` (exit 3).

Side finding: under `env -i` without `USER`, `register` dies with
`scripts/context-budget.sh: line 862: USER: unbound variable`. That's harmless in
normal shells, which set `USER`.

## Q4 — concurrency

**Verdict: YES on the hook side** (two live sessions, each hook payload carried its
own id and transcript). Agent shell: blocked, as in Q1.

| Run | `conversation_id` (stdout) | hook `conversationId` + env var | PreToolUse `CommandLine` |
|---|---|---|---|
| q4a | `3f54bbb1-…0a21` | `3f54bbb1-…0a21` (both) | `sh .agents/probe.sh A` |
| q4b | `1c5c2d00-…70e8` | `1c5c2d00-…70e8` (both) | `sh .agents/probe.sh B` |

Each `transcriptPath` names its own `brain/<id>/` directory. There is no newest-file
step anywhere in this path.

## What this means for the plan

Antigravity looks like the Claude model: register from a hook with the payload's
exact id and transcript, keyed on `conversationId`, using `PreInvocation` /
`invocationNum == 0` in place of SessionStart. That needs a new adapter row
(`antigravity`), a committed `.agents/hooks.json`, a discover/measure pair over
`brain/<id>/…/transcript_full.jsonl`, and a `detect_runtime` case on
`ANTIGRAVITY_CONVERSATION_ID`. Without that case, auto-detection actively mis-binds
(Q3). Whether agent-run `record` can use the env var waits on Q1.

## Cleanup owed

- `<scratchpad>/ws-agy`, `agy-payloads/`, `agy-cap.sh`, `agy-run*.json` (disposable).
- 4 probe conversations under `~/.gemini/antigravity-cli/brain/` and
  `conversations/` (ids `ed75a355`, `88f69013`, `3f54bbb1`, `1c5c2d00`):
  delete them on the user's say-so.
