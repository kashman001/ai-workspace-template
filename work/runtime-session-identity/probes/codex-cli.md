# Probe — Codex CLI

- **Version:** `codex-cli 0.153.4` (`/opt/homebrew/bin/codex` → `/opt/homebrew/Caskroom/codex/0.153.4/bin/codex`), model reported `gpt-5.6-terra`
- **Date:** 2026-10-12
- **Where:** fresh clone of WS at `<scratchpad>/ws-codex` (HEAD `0ecbfa7`), under `/private/tmp/...` — outside the `[projects."/Users/kashif"]` trusted root in `~/.codex/config.toml`.
- **Clone-only changes:** `scripts/hooks/context-budget-codex-hook.sh` and `context-budget-stop-hook.sh` wrapped to tee stdin + `env | grep -i codex` to `<scratchpad>/codex-payloads/`, then pipe the payload on to the real dispatcher. One probe-only `[[hooks.SessionStart]]` entry appended to the clone's `.codex/config.toml` (script `<scratchpad>/ss-probe.sh` saves the payload and whether `transcript_path` exists yet).
- **Commands run** (all with cwd = clone, `< /dev/null`):
  1. `codex exec --dangerously-bypass-approvals-and-sandbox --json 'run `env | grep -i codex` and `pwd` ...'` (run1, no hook-trust flag)
  2. `codex exec --dangerously-bypass-approvals-and-sandbox --dangerously-bypass-hook-trust --json 'run `echo $CODEX_THREAD_ID` ...'` (run2)
  3. same flags, agent runs `scripts/context-budget.sh register --runtime codex; ls .context-budget/sessions; echo TID=$CODEX_THREAD_ID` (run3, SessionStart probe added)
  4. same flags, agent runs `env -u CODEX_THREAD_ID -u CODEX_SESSION_ID scripts/context-budget.sh register --runtime codex` (run4)
  5. two concurrent `codex exec` (started 3 s apart), each `sleep 20; env -u CODEX_THREAD_ID -u CODEX_SESSION_ID scripts/context-budget.sh register --runtime codex` (q4a/q4b)
  6. control: two concurrent, same but **without** `env -u` (q4c/q4d)
  7. `strings .../bin/codex | grep -oE '\b(SessionStart|...|Stop)\b' | sort | uniq -c`

## Q1 — env id in the agent's shell

**Verdict: YES** (agent shell). **NO in hook processes.**

run1 (`env | grep -i codex`, thread `01a131b7-918a-7e03-b076-f938f249089f`):

```
CODEX_CI=1
CODEX_SESSION_ID=01a131b7-918a-7e03-b076-f938f249089f
CODEX_THREAD_ID=01a131b7-918a-7e03-b076-f938f249089f
```

Both `CODEX_THREAD_ID` and `CODEX_SESSION_ID` are set and equal the thread id from
`thread.started`, which is the UUID suffix of the rollout:
`~/.codex/sessions/2026/10/12/rollout-2026-10-12T15-04-36-01a131b7-918a-7e03-b076-f938f249089f.jsonl`.

Hook processes (UserPromptSubmit, Stop, SessionStart) get **no** `CODEX_*` variables:
`grep -E '^CODEX_' codex-payloads/*.env` → no match; `env | grep -i codex` in the hook
shows only `PATH` and `PWD` (because the path contains "codex"). Hooks must take the id
from the payload, not the env.

## Q2 — hooks fire? payload fields

**Verdict: PARTIAL** — fire in `codex exec` only with hook trust; untrusted = silently skipped.

- **run1, no `--dangerously-bypass-hook-trust`:** no payload files written, no `.context-budget/hook-codex-*` stamp, no warning/error in stderr or the `--json` stream. Hooks are **silently skipped** in exec mode when not trusted (no prompt, no blocking). Not separated: whether it is hook-hash trust or project trust (the clone is outside the trusted `/Users/kashif` root) — the one flag fixed both.
- **run2, with `--dangerously-bypass-hook-trust`:** both fired; stream carries an `error` item "`--dangerously-bypass-hook-trust` is enabled. Enabled hooks may run without review for this invocation." The dispatcher wrote `.context-budget/hook-codex-01a131b8-2805-7320-ad6c-bdfcf01cebaa.{stamp,status}` (status `OK`) but **no** `sessions/codex-*.json` (adapter is `register = agent`).

UserPromptSubmit payload (run2, cwd shortened):

```json
{
  "session_id": "01a131b8-2805-7320-ad6c-bdfcf01cebaa",
  "turn_id": "01a131b8-2837-7aa0-9419-edefc828821e",
  "transcript_path": "/Users/kashif/.codex/sessions/2026/10/12/rollout-2026-10-12T15-05-14-01a131b8-2805-7320-ad6c-bdfcf01cebaa.jsonl",
  "cwd": "<scratchpad>/ws-codex",
  "hook_event_name": "UserPromptSubmit",
  "model": "gpt-5.6-terra",
  "permission_mode": "bypassPermissions",
  "prompt": "run `echo $CODEX_THREAD_ID` in the shell and print the output"
}
```

Stop payload: same `session_id`/`turn_id`/`transcript_path`/`cwd`/`model`/`permission_mode`, plus
`"hook_event_name": "Stop"`, `"stop_hook_active": false`, `"last_assistant_message": "..."`.

`transcript_path` **matches the rollout file exactly**: `find ~/.codex/sessions -name '*01a131b8-2805*'`
→ the same path; `session_id` == `CODEX_THREAD_ID` == thread id.

**SessionStart exists and fires.** Binary strings list `SessionStart`, `SessionEnd`, `UserPromptSubmit`,
`PreToolUse`, `PostToolUse`, `PreCompact`, `PostCompact`, `SubagentStop`, `Stop`. With the probe
`[[hooks.SessionStart]]` entry (run3):

```json
{
  "session_id": "01a131b8-7e41-7cd0-823b-e2e99d02c54d",
  "transcript_path": "/Users/kashif/.codex/sessions/2026/10/12/rollout-2026-10-12T15-05-36-01a131b8-7e41-7cd0-823b-e2e99d02c54d.jsonl",
  "cwd": "<scratchpad>/ws-codex",
  "hook_event_name": "SessionStart",
  "model": "gpt-5.6-terra",
  "permission_mode": "bypassPermissions",
  "source": "startup"
}
```

In the Q4 runs the probe also logged the transcript file **already exists at SessionStart**
(`... exists=yes size=85105` for both sessions), so hook-side registration before the first prompt is possible.

## Q3 — `register` from the agent's shell

**Verdict: YES with `CODEX_THREAD_ID`; YES (single session) via fallback.**

run3 (env intact), thread `01a131b8-7e41-7cd0-823b-e2e99d02c54d`:

```
registered codex session 01a131b8-7e41-7cd0-823b-e2e99d02c54d artifact: /Users/kashif/.codex/sessions/2026/10/12/rollout-2026-10-12T15-05-36-01a131b8-7e41-7cd0-823b-e2e99d02c54d.jsonl
rc=0
codex-01a131b8-7e41-7cd0-823b-e2e99d02c54d.json
TID=01a131b8-7e41-7cd0-823b-e2e99d02c54d
```

`.context-budget/sessions/codex-01a131b8-....json` → `"session_id"` and `"artifact"` equal the
thread id and the SessionStart `transcript_path`. Correct.

run4 (`env -u CODEX_THREAD_ID -u CODEX_SESSION_ID`, alone in the clone), thread `01a131b8-dea6-7563-b8ce-9a8d5ad40ed2`:

```
registered codex session 01a131b8-dea6-7563-b8ce-9a8d5ad40ed2 artifact: .../rollout-2026-10-12T15-06-01-01a131b8-dea6-7563-b8ce-9a8d5ad40ed2.jsonl
rc=0
```

The cwd-substring + newest-mtime fallback binds correctly **when only one session is live**.

## Q4 — two concurrent sessions in one clone

**Verdict: NO** (fallback cross-wires). Control with `CODEX_THREAD_ID` set: YES.

q4a/q4b (each `sleep 20` then register with the id vars unset):

```
== a  thread 01a131b9-4ba4-7673-a314-809fb9c942d7
registered codex session 01a131b9-5776-7620-aff4-682e1a0b4778 artifact: .../rollout-2026-10-12T15-06-32-01a131b9-5776-...jsonl
TID=01a131b9-4ba4-7673-a314-809fb9c942d7
== b  thread 01a131b9-5776-7620-aff4-682e1a0b4778
registered codex session 01a131b9-4ba4-7673-a314-809fb9c942d7 artifact: .../rollout-2026-10-12T15-06-29-01a131b9-4ba4-...jsonl
TID=01a131b9-5776-7620-aff4-682e1a0b4778
```

**Each session bound the other's rollout** — a full swap: each one's own rollout was the one it
had just appended to, but the sibling's was newer by mtime when it looked. Both
`sessions/codex-*.json` files exist and look right by name, so nothing on disk shows the
cross-wiring. Each session's budget readings would track the sibling.

Control q4c/q4d (same, `CODEX_THREAD_ID` left set): each registered its own thread
(`01a131b9-e254-...` → `rollout-...-e254-...`, `01a131b9-ee1f-...` → `rollout-...-ee1f-...`). Correct.

## Implications for a fix

- In the Codex CLI agent shell `CODEX_THREAD_ID` (and `CODEX_SESSION_ID`) is reliable, so agent-side `register` is already correct. The race only shows up when the var is missing (other surfaces/older builds, `env -u`, a shell started outside Codex). Make the fallback refuse to pick when more than one cwd-matching rollout is live, instead of choosing by newest mtime.
- Codex 0.153.4 has `SessionStart` (payload has `session_id`, `transcript_path`, `source`, and the rollout file already exists), so Codex can register from the hook the way Claude Code does: add `[[hooks.SessionStart]]` → dispatcher and flip the adapter row from `register = agent` to hook-side.
- UserPromptSubmit/Stop payloads also carry the exact `session_id` + `transcript_path`. The UserPromptSubmit hook could register (or heal a missing or wrong registration) on every turn, so it doesn't depend on SessionStart.
- Hook code must read ids from the payload only: hook processes get no `CODEX_*` env vars.
- Hooks are **silently skipped** under `codex exec` without hook/project trust (no prompt or warning). Anything relying on hooks needs a documented trust step (interactive trust once, or `--dangerously-bypass-hook-trust` for automation), and the agent-side `register` must stay as the fallback.

## Post-fix (s9)

Codex CLI 0.162.1, probe clone `ws-identity-probe-s9` at 191944f. Two pairs of `codex exec
--json -s workspace-write` sessions ran from a clean env, each running
`./probe-env.sh codex <label>` and then `sleep 20`.

- **Hooks untrusted (pair `cli-A/B`):** hooks were skipped, as before. The agent-side `register`
  bound each session's own rollout through `CODEX_THREAD_ID`.
- **Hooks trusted (pair `codex-A/B`, `--dangerously-bypass-hook-trust`, user-approved):**
  SessionStart, UserPromptSubmit and Stop fired once per session, each payload carrying its own
  `session_id` + `transcript_path`. `check` from each agent shell reported its own rollout.
- **Registry:** one `codex-<sid>.json` per session (four sessions, four records, no
  cross-binding).
- `method=estimate` during the first turn (no `token_count` event yet). The same session measured
  afterwards gives `method=exact`.
- **Not tested here:** the interactive hook-trust prompt. That is on the user checklist.

**Result: PASS.**
