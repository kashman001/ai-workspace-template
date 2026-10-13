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
- **Skip-permissions run:** the Claude Code auto-mode classifier denied
  `--dangerously-skip-permissions` when I tried it, so the user ran that one
  command (run q1) from Claude Code's `!` prompt. Without the flag, headless
  mode auto-denies every `run_command`.

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

**Verdict: YES.** Hook processes and the agent's shell both get it.

The user ran this from Claude Code's `!` prompt (so it inherited that session's env; see Q3):
`agy -p '… sh .agents/probe.sh scripts/context-budget.sh register' --dangerously-skip-permissions --print-timeout 150s --output-format json`
(run q1, conversation `c2d716d4-0746-40eb-8520-11f747580f2a`). The agent shell's env
(`ANTIGRAVITY_SOURCE_METADATA` and `ANTIGRAVITY_CSRF_TOKEN` values trimmed):

```
ANTIGRAVITY_AGENT=1
ANTIGRAVITY_CONVERSATION_ID=c2d716d4-0746-40eb-8520-11f747580f2a
ANTIGRAVITY_APP_DATA_DIR=/Users/kashif/.gemini/antigravity-cli
ANTIGRAVITY_LS_VERSION=cli-1.3.3
ANTIGRAVITY_SOURCE_METADATA={"tool":{"conversationId":"c2d716d4-…","stepIndex":2,"toolCall":{…}}}
ANTIGRAVITY_TRAJECTORY_ID=c3151dcb-4533-48ef-9271-af8e158e72a4
ANTIGRAVITY_PROJECT_ID=default-cli-project
```

`ANTIGRAVITY_CONVERSATION_ID` equals the `conversation_id` in stdout and in every hook payload.
`ANTIGRAVITY_APP_DATA_DIR` gives the transcript root directly
(`$ANTIGRAVITY_APP_DATA_DIR/brain/$ANTIGRAVITY_CONVERSATION_ID/.system_generated/logs/transcript_full.jsonl`),
so the IDE (`antigravity-ide/`) and app (`antigravity/`) need no path guessing.

Before that, headless runs without `--dangerously-skip-permissions` auto-denied
every `run_command` (runs 1–2, `"denied_actions":[{"action":"command",…}]`), and a
PreToolUse hook answering `allow` + `permissionOverrides` did not lift the deny.

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

Run q1 (the command ran) also fired `PostToolUse` (`stepIdx`, `error: ""`),
`PostInvocation` (`invocationNum` 0 and 1) and `Stop` (`terminationReason: "NO_TOOL_CALL"`),
all with the same `conversationId` + `transcriptPath`. In runs 1–2 these events never
fired, because each run ended on the denied tool call.

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

**From inside the agent's shell (run q1): it bound the *parent* Claude Code session.**

```
registered claude session 62df08d9-… artifact: ~/.claude/projects/…/62df08d9-….jsonl
runtime=claude method=exact tokens=121140 … status=WARN
```

`agy` was launched from Claude Code's `!` prompt, so its agent shell inherited
`CLAUDECODE` / `CLAUDE_CODE_SESSION_ID` / `TF_SESSION_SEQ`. `detect_runtime`
checks `CLAUDECODE` first and wins. Any runtime started from another runtime's shell
hits this: the outer runtime's id vars leak in. Fix: detect the innermost runtime
first. `ANTIGRAVITY_AGENT=1` / `ANTIGRAVITY_CONVERSATION_ID` belong to the
process that's actually running, so they should beat the inherited `CLAUDECODE`.
The record went to the scratch clone's `.context-budget/`, not this checkout.

Side finding: under `env -i` without `USER`, `register` dies with
`scripts/context-budget.sh: line 862: USER: unbound variable`. That's harmless in
normal shells, which set `USER`.

## Q4 — concurrency

**Verdict: YES on the hook side** (two live sessions, each hook payload carried its
own id and transcript). Agent shell: not run concurrently, but Q1 shows each shell
carries its own `ANTIGRAVITY_CONVERSATION_ID`, so it is separable.

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
(Q3). Agent-run `record` can key on `ANTIGRAVITY_CONVERSATION_ID` (Q1), and
`detect_runtime` must rank it above inherited outer-runtime vars like `CLAUDECODE`.

## Cleanup owed

- `<scratchpad>/ws-agy`, `agy-payloads/`, `agy-cap.sh`, `agy-run*.json` (disposable).
- 5 probe conversations under `~/.gemini/antigravity-cli/brain/` and
  `conversations/` (ids `ed75a355`, `88f69013`, `3f54bbb1`, `1c5c2d00`, `c2d716d4`):
  delete them on the user's say-so.

## Post-fix (s9)

Antigravity CLI 1.3.3, probe clone `ws-identity-probe-s9` at 191944f. Two `agy -p "Reply with
just: ok agy-A|B"` sessions ran at once from a clean env. They used no tools: the agent
permission classifier blocked `--dangerously-skip-permissions`, and `-p` can't approve a shell
command.

- **Hooks:** `.agents/hooks.json` fired `PreInvocation` (`invocationNum: 0`) once per
  conversation, each with its own `conversationId` + `transcriptPath`.
- **Registry:** one `antigravity-<id>.json` per conversation pointing at its own
  `brain/<id>/.system_generated/logs/transcript_full.jsonl` (`pid: null`). `check --runtime
  antigravity --session-id <id>` gives `method=exact` for each.
- **Agent shell (`./probe-env.sh antigravity`):** not run. It is on the user checklist
  (interactive `agy`, approve the command).

**User row 2 (interactive `agy`, two terminals; conversations `f25aa2ff`, `576d04fa`):** each
agent shell has its own `ANTIGRAVITY_CONVERSATION_ID`, so `register` and `check` bound its own
`transcript_full.jsonl` (`method=exact`). The hooks fired on every invocation (`invocationNum`
0, 1, 2), each with its own `conversationId`. One record per conversation. `agy` auto-updated
1.3.3 → 1.3.4 between the two sessions, with no effect.

**Result: PASS (agent side and hook side).**

Cleanup owed: s9 conversations `1df25ea1`, `fa6ea8ea`, `f25aa2ff`, `576d04fa`.
