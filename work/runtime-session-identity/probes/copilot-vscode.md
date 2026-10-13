# Probe — GitHub Copilot Chat, agent mode, in VS Code

- **Where:** probe clone `~/Developer/experiments/ws-identity-probe` (HEAD `bc1cce4`),
  opened in VS Code and trusted. `.vscode/settings.json` enables `.github/hooks/`.
- **Run by the user, 2026-10-12:** two Copilot agent chats in one window: `copilot-A`
  (`5cd5317c-c6f0-…`) and `copilot-B` (`2d9ebe1a-086c-…`). Each ran
  `./probe-env.sh copilot-vscode <label>`, then sent `ok`.
- **Raw output:** `probe-out/env.log`, `hook-context-budget-copilot-vscode-hook.log`,
  `hook-context-budget-copilot-hook.log`, `hook-context-budget-stop-hook.log` in the clone.

**Headline:** Copilot agent mode in VS Code now runs on the **Copilot CLI runtime**
(`…/@github/copilot-sdk-darwin-arm64/…/copilot-runtime`). Its transcript is the CLI's
`~/.copilot/session-state/<sid>/events.jsonl`, and every turn fires **three** hook configs.

## Q1 — env id in the agent's shell

**Verdict: YES.** `COPILOT_AGENT_SESSION_ID=<sid>`, matching the hook payloads. Also present:
`AI_AGENT=github_copilot_vscode_agent` (identifies the surface), `COPILOT_CLI=1` and
`COPILOT_HOME=~/.copilot`. **`VSCODE_TARGET_SESSION_LOG` is not set.**

Process ancestry: `bash ← bash ← copilot-runtime (pid 5349, shared by both chats) ← Code
Helper (extension host) ← Code`. One runtime process serves every chat, so a pid can't tell
the sessions apart.

## Q2 — hooks fire; payload fields

**Verdict: YES, with no trust step beyond folder trust. But three hook sets fire per event.**

For each SessionStart and each turn end, these all ran with the same session id:

| Config file | Script / argv | Event names | Payload |
|---|---|---|---|
| `.github/hooks/context-budget-vscode.json` | `copilot-vscode-hook.sh` `SessionStart`/`Stop` | `SessionStart`, `Stop` | snake_case: `session_id`, `transcript_path` (Stop only), `cwd`, `source`, `initial_prompt`, `stop_reason` |
| `.github/hooks/context-budget.json` (the **CLI** config) | `copilot-hook.sh` `sessionStart`/`agentStop` | `sessionStart`, `agentStop` | camelCase: `sessionId`, `transcriptPath` (agentStop only), `initialPrompt`, `stopReason` |
| `.claude/settings.json` (**Claude Code's** config) | `stop-hook.sh claude` | `Stop` only | the same snake_case Copilot payload |

- `transcript_path` = `~/.copilot/session-state/<sid>/events.jsonl` (it exists).
  SessionStart carries no transcript path.
- Copilot reads Claude Code's `.claude/settings.json` hooks, so the **Claude** Stop shim runs
  on every Copilot turn with a Copilot payload. In this run it left no `claude` stamp or
  record, but it is a live path for misattribution.

## Q3 — `register` from the agent's shell

**Verdict: NO.** `register` failed in both chats with `error: no session artifact found
for runtime=copilot-vscode`. `copilot_vscode_discover` (scripts/context-budget.sh:175)
only knows `VSCODE_TARGET_SESSION_LOG` (unset here) and
`workspaceStorage/<hash>/chatSessions/`. These sessions write neither.
`COPILOT_AGENT_SESSION_ID` is not consulted for this runtime.

Hook-side registration (`register=hook`) *did* write
`sessions/copilot-vscode-<sid>.json`, but with a **wrong artifact**:
`~/.copilot/chatSessions/<sid>.jsonl`, which doesn't exist. The `chat-sessions`
derivation (scripts/hooks/context-budget-hook.sh:104) assumes
`transcript_path = …/GitHub.copilot-chat/transcripts/<sid>.jsonl` and goes three `dirname`s
up. With the new `session-state/<sid>/events.jsonl` path, it lands on `~/.copilot`. The
transcript guard then goes silent, so **the copilot-vscode hook never measures**.

The CLI hook config (`.github/hooks/context-budget.json`, `copilot-state` derivation)
*did* measure: `.context-budget/hook-copilot-cli-<sid>.status` = `OK` for both chats.

## Q4 — two concurrent sessions in one window

**Verdict: YES on identity, with a broken binding.** Each env id and each payload is
per-chat (two distinct sids, no cross-over). But the copilot-vscode records point at
nonexistent files, so the copilot-vscode adapter measures neither session. Only the
copilot-cli adapter, firing through the CLI hook config, measures correctly.

## Implications for a fix

- Treat Copilot-in-VS-Code (this build) as the **Copilot CLI runtime**:
  `session-state/<sid>/events.jsonl`, id from `COPILOT_AGENT_SESSION_ID` (agent shell) or
  the payload (hooks). Detect the surface with `AI_AGENT=github_copilot_vscode_agent`.
- Fix the `chat-sessions` derivation: when `transcript_path` already ends in
  `session-state/<sid>/events.jsonl`, use it as is. Keep the old `workspaceStorage` path only
  for builds that still emit it.
- `copilot_vscode_discover`: use `COPILOT_AGENT_SESSION_ID` before
  `VSCODE_TARGET_SESSION_LOG`/newest-mtime.
- Pick **one** hook config per event. Today the CLI and VS Code configs both measure, and
  Claude Code's Stop shim also runs. Either drop the duplicate configs or make the
  dispatcher recognise a Copilot payload, for example by the `.copilot/session-state/` path,
  and refuse to measure it as `claude`.

## Post-fix (s9)

User row 5: two Copilot Chat Agent-mode chats in `ws-identity-probe-s9` (sessions `a058b12d`,
`2413acaf`).

- **Agent side: PASS on binding.** Each chat has its own `COPILOT_AGENT_SESSION_ID`, and
  `register --runtime copilot-vscode` bound its own `~/.copilot/session-state/<sid>/events.jsonl`
  (the pre-fix `chatSessions` bug is gone). `check` auto-detects `copilot-cli` and reports the
  same artifact. `method=estimate` (CLI sessions measured `exact`, so look into why).
- **Oddity 1: two records per chat** (`copilot-vscode-<sid>.json` and `copilot-cli-<sid>.json`,
  same artifact). No cross-binding, but duplicates. Decide whether that is acceptable.
- **Oddity 2: no hook fired** (copilot, copilot-vscode and claude hook logs empty for these
  chats). Check whether VS Code needs the workspace hook files enabled or trusted
  (`chat.hooks`-style setting), and whether the `copilot-cli` record came from the agent `check`
  rather than a hook.

**Result: binding PASS; hooks not firing + duplicate records → investigate in s10.**

## Re-probe (s10)

Two new chats, labels `copilot-vscode-C` (`d5d80a4e…`) and `-D` (`90bc99b7…`), at 12:32–12:33.
The s9 logs were re-read too.

- **Binding: PASS.** Each chat's env id and `register` bound its own `events.jsonl`; no crossover.
- **Correction: hooks DID fire, in s9 and s10.** The s9 "hooks silent" line was a misread.
  Per chat: CLI config `sessionStart` + `agentStop` (measured, `hook-copilot-cli-<sid>.status` = `OK`),
  VS Code config `SessionStart` + `Stop`, Claude's `Stop` shim, and Claude's `PostToolUse`
  hook: **four hook sets per event**, two of them Claude Code's.
- **Duplicate records explained:** the CLI hook config writes `copilot-cli-<sid>.json`;
  `register --runtime copilot-vscode` writes `copilot-vscode-<sid>.json`. Same artifact.
- **New gap: `method=estimate` undercounts ~30%.** The VS Code transcript has no
  `inputTokens` (CLI transcripts use `session.usage_record`); the exact count is
  `prompt_tokens` in `session.usage_checkpoint` → `promptCacheBreakState`. Chat D: estimate
  33,857 vs `prompt_tokens` 47,574.

**Follow-up:** plan `02-copilot-vscode-followups` (fix the count; decide hook fan-out and duplicates).
