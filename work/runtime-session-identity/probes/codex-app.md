# Probe — Codex desktop (Codex inside ChatGPT.app, Codex 0.162.0-alpha.17.2)

- **Which app:** the standalone `codex-app` cask is discontinued upstream (brew names
  `chatgpt` as its replacement), so this probes Codex inside ChatGPT.app. It reports itself
  as `CODEX_INTERNAL_ORIGINATOR_OVERRIDE=Codex Desktop` and runs the bundled
  `ChatGPT.app/…/codex-cli/CodexCLI.app` binary. Decision: `work/backlog-sweep/decisions.md`.
- **Where:** probe clone `~/Developer/experiments/ws-identity-probe-s9` (HEAD `7b18ce1`),
  opened as a local folder (seatbelt sandbox, `CODEX_PERMISSION_PROFILE=:workspace`). Hooks
  were already trusted from earlier CLI runs: no trust prompt.
- **Run by the user, 2026-10-18 (backlog-sweep s4, card L86):** two chats: `codex-app-A`
  (`01a15236-1626-…`) and `codex-app-B` (`01a15238-bf25-…`). Each ran
  `./probe-env.sh codex <label>`, then sent `ok` turns.
- **Raw output:** `probe-out/env-codex-app-{A,B}.log`,
  `probe-out/hook-context-budget-codex-hook.log` (SessionStart, UserPromptSubmit) and
  `probe-out/hook-context-budget-stop-hook.log` (Stop) in the clone.

## Q1 — env id in the agent's shell

**Verdict: YES** (agent shell). **NO in hook processes**, the same as the CLI and VS Code.

The agent shell has `CODEX_SESSION_ID` = `CODEX_THREAD_ID` = the session id, plus
`CODEX_INTERNAL_ORIGINATOR_OVERRIDE=Codex Desktop`, `CODEX_SANDBOX=seatbelt` and
`CODEX_SANDBOX_NETWORK_DISABLED=1`. The hook process inherits the originator and the
`CODEX_APP_*`/`CODEX_CLI_PATH` vars but **no** `CODEX_SESSION_ID`/`CODEX_THREAD_ID`.

`ps` is blocked in the sandbox (`/bin/ps: Operation not permitted`), so ancestry is empty and
`register` writes `pid: null`, as in VS Code.

## Q2 — hooks fire? payload fields

**Verdict: YES.** For both chats, the `.codex/config.toml` hooks fired SessionStart
(22:30:40, 22:33:36), UserPromptSubmit, and Stop (`context-budget-stop-hook.sh codex`), each
with its own `session_id`/`transcript_path`.

- Payloads have the CLI shape: `session_id`, `turn_id` (not on SessionStart),
  `transcript_path` (the rollout `.jsonl`), `cwd`, ….
- **Cross-runtime leak:** Codex Desktop **also** runs the `.claude/settings.json` Stop hook.
  `context-budget-stop-hook.sh claude` fired at 22:34:27 and 22:34:31, next to the `codex`
  calls, with Codex env and a Codex payload. It wrote no claude record or status file, so it
  was harmless here, but a Claude hook is running under the wrong runtime label.
  Neither the Codex CLI nor the VS Code extension showed this (their stop logs have only
  `codex`).

## Q3 — `register` from the agent's shell

**Verdict: YES.** Both chats bound their own rollout file
(`rollout-2026-10-18T22-30-39-01a15236-….jsonl`, `rollout-2026-10-18T22-33-33-01a15238-….jsonl`),
`method=estimate`, via `CODEX_THREAD_ID`.

## Q4 — two concurrent sessions in one window

**Verdict: YES.** Each chat's shell has its own thread id, each hook payload its own
`session_id`/`transcript_path`, and there is exactly one registry record per chat. Nothing
crossed over.

## Gaps

- **Claude Stop hook runs under Codex Desktop** (above). Today the claude branch finds no
  claude session and does nothing; if it ever matched, a Codex turn could write Claude
  budget state. Fix direction: the stop shim should check the payload/env matches the
  runtime on argv (for example, ignore `claude` when `CODEX_INTERNAL_ORIGINATOR_OVERRIDE` is
  set or the `transcript_path` is under `~/.codex/`).
- Untrusted hooks would be skipped silently, as in VS Code (`codex-vscode.md`). Not
  re-tested here; hooks were already trusted.

**Result: PASS** (own transcript per chat, one record each, hooks per chat). One new gap: the
Claude Stop hook leaks into Codex Desktop.
