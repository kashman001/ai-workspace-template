# Probe — Codex VS Code extension (`openai.chatgpt`, Codex 0.162.0-alpha.17.2)

- **Where:** probe clone `~/Developer/experiments/ws-identity-probe` (made by
  `make-ide-probe-clone.sh` at HEAD `bc1cce4`), opened in VS Code and trusted. It sits
  under the `[projects."/Users/kashif"]` trusted root, and Codex added its own
  `[projects.".../ws-identity-probe"]` trust entry.
- **Run by the user, 2026-10-12:** two Codex chats in one window: `vscode-A`
  (`01a131e4-ce22-…`) and `vscode-B` (`01a131e7-9c4f-…`). Each ran `./probe-env.sh codex
  <label>`, then sent `ok` turns.
- **Raw output:** `probe-out/env.log`, `probe-out/hook-context-budget-codex-hook.log`
  (UserPromptSubmit) and `probe-out/hook-context-budget-stop-hook.log` (Stop) in the clone.
  The Stop wrapper was added mid-probe (16:00), so only the turns after that are logged.

## Q1 — env id in the agent's shell

**Verdict: YES** (agent shell). **NO in hook processes**, the same as the CLI.

The agent shell has `CODEX_SESSION_ID` = `CODEX_THREAD_ID` = the session id, plus
`CODEX_INTERNAL_ORIGINATOR_OVERRIDE=codex_vscode` (identifies the surface), `CODEX_SANDBOX=seatbelt`
and the VS Code extension-host vars (`VSCODE_PID`, `VSCODE_IPC_HOOK`, …). The hook process
inherits `CODEX_INTERNAL_ORIGINATOR_OVERRIDE` and the `VSCODE_*` vars but **no**
`CODEX_SESSION_ID`/`CODEX_THREAD_ID`. Hooks must take the id from the payload.

`ps` is blocked in the seatbelt sandbox (`/bin/ps: Operation not permitted`), so the process
ancestry is empty and `register` writes `pid: null`.

## Q2 — hooks fire? payload fields

**Verdict: YES once trusted.** Before that, they are skipped silently.

- **Trust timing:** the extension asked to trust the two project hooks (`user_prompt_submit`,
  `stop`) only **after** the first turns had already run. Codex wrote the trust to
  `~/.codex/config.toml` → `[hooks.state."<clone>/.codex/config.toml:<event>:0:0"] trusted_hash`
  at 15:56. vscode-A's turns at 15:54 and 15:55 logged no hook; nothing warned about it.
- **After trust**, both events fired for **both** chats. That includes vscode-A, which was
  started before the trust was granted, so a chat doesn't need a restart (16:01 entries).
- **UserPromptSubmit payload:** `session_id`, `turn_id`, `transcript_path` (the rollout
  `.jsonl`), `cwd`, `hook_event_name`, `model`, `permission_mode`, `prompt`. This is the CLI
  shape.
- **Stop payload:** the same ids, plus `stop_hook_active` and `last_assistant_message`.
  The stop shim is called with `codex` on argv.
- No SessionStart is wired in this repo's `.codex/config.toml`, so it wasn't observed here.
  The CLI probe showed that one exists.

## Q3 — `register` from the agent's shell

**Verdict: YES.** Both chats bound their own rollout file
(`rollout-…-01a131e4-….jsonl`, `rollout-…-01a131e7-….jsonl`), `method=estimate`, via
`CODEX_THREAD_ID`.

## Q4 — two concurrent sessions in one window

**Verdict: YES.** Each chat's shell has its own env id. Each hook payload carries its own
`session_id`/`transcript_path`. The dispatcher keeps separate
`.context-budget/hook-codex-<sid>.{stamp,status}` files (both `OK`). Nothing crossed over.

## Side observation — Claude Code extension in the same window

When the folder opened (15:50), the Claude Code VS Code extension spawned **two** `claude`
processes (`--output-format stream-json …`, pids 41605/41582). Their SessionStart hooks
registered `claude-<sid>.json` records whose artifact
(`~/.claude/projects/-Users-kashif-Developer-experiments-ws-identity-probe/<sid>.jsonl`)
**does not exist**, since no chat was ever typed. These are pre-warmed idle sessions that
leave phantom registry records.

## Implications for a fix

- Same as the Codex CLI: register from the hook (`session_id` + `transcript_path` are in
  every payload) and never read `CODEX_*` in the hook.
- Document the trust step for the extension: approve the hooks, then the **next** turn runs
  them. Turns before approval are unmeasured, and nothing says so.
- `pid: null` in the sandbox means liveness can't come from the pid for Codex in VS Code.
  The registry's stale-record pruning must not depend on it.

## Post-fix (s9)

User row 4: two new Codex chats in the probe clone `ws-identity-probe-s9`
(threads `01a13645-4dba…`, `01a13645-8d6e…`).

- **Agent side: PASS.** Each chat has its own `CODEX_THREAD_ID`, `register` and `check` bound its
  own rollout, one record per chat. `method=estimate` in the first turn, as with the CLI.
- **Hook side: GAP.** No hook-trust prompt appeared and no Codex hook fired, even on a later
  turn. `~/.codex/config.toml` has `[projects."…/ws-identity-probe-s9"] trust_level = "trusted"`
  but no `[hooks.state."…/ws-identity-probe-s9/.codex/config.toml:…"] trusted_hash` entries. The
  old clone has them, from an earlier prompt. The extension skips untrusted hooks silently, so
  a fresh copy of the workspace gets no budget warnings in Codex VS Code and no sign why.
  Workaround under test (row 4b): run `codex` once in the folder from a terminal so the CLI
  prompts for hook trust.
- **Row 4b (workaround confirmed):** running `codex` once in the folder from a terminal showed
  the hook-trust prompt. The user allowed all hooks, and `hooks.state` entries for
  `session_start`, `user_prompt_submit` and `stop` appeared. On the next turn, both
  already-open VS Code chats fired UserPromptSubmit + Stop with their own `session_id`; the CLI
  session (`01a13648…`) fired SessionStart too. One record per session, no cross-binding.

**Result: PASS once hooks are trusted. GAP: the extension never prompts for hook trust. It skips
the hooks silently until hook trust is granted from the CLI (backlog card to file).**
