# Probe — Antigravity IDE (`ide-2.4.5`, model `gemini-3.8-flash-high`)

- **Where:** probe clone `~/Developer/experiments/ws-identity-probe-s9` (HEAD `7b18ce1`),
  opened in Antigravity IDE. The folder was already trusted: no trust prompt appeared and
  hooks ran from the first turn.
- **Run by the user, 2026-10-18 (backlog-sweep s4, card L86):** two chats in one window:
  `ag-ide-A` (`6be59cb3-99f3-…`) and `ag-ide-B` (`f8b7742e-c85a-…`). Each ran
  `./probe-env.sh antigravity <label>`, then sent `ok` turns. Antigravity.app (the
  standalone app) was not probed.
- **Raw output:** `probe-out/env-ag-ide-{A,B}.log` and
  `probe-out/hook-context-budget-antigravity-hook.log` in the clone.

## Q1 — env id in the agent's shell

**Verdict: YES** (agent shell and hook process).

The agent shell has `ANTIGRAVITY_CONVERSATION_ID` = the conversation id (also inside
`ANTIGRAVITY_SOURCE_METADATA`), plus `ANTIGRAVITY_TRAJECTORY_ID`, `ANTIGRAVITY_LS_VERSION=ide-2.4.5`,
`__CFBundleIdentifier=com.google.antigravity-ide` and the VS Code-style `VSCODE_*` vars.
`ANTIGRAVITY_APP_DATA_DIR` is **not** set. Process ancestry works (no sandbox):
`bash` → `language_server_macos_arm` → the IDE's `Electron` main process.

The hook process also has `ANTIGRAVITY_CONVERSATION_ID`, unlike Codex.

## Q2 — hooks fire? payload fields

**Verdict: YES.** The `.agents/hooks.json` `PreInvocation` hook fired for both chats, many
times per turn (22:23:14 → 22:25:47), each with its own conversation.

- **Payload:** `artifactDirectoryPath` (`~/.gemini/antigravity-ide/brain/<conv>`),
  `conversationId`, `initialNumSteps`, `invocationNum`, `modelName`, `transcriptPath`
  (`…/brain/<conv>/.system_generated/logs/transcript_full.jsonl`), `workspacePaths`. This is
  the CLI shape, with the IDE's data root (`antigravity-ide/`) in the paths.
- Turn-end entries for A and B at 22:25:33 and 22:25:47 carry their own
  `conversationId`/`transcriptPath`.

## Q3 — `register` from the agent's shell

**Verdict: NO from the shell; YES via the hook.**

`probe-env.sh`'s manual `register` printed `error: no session artifact found for
runtime=antigravity`. Cause: `antigravity_discover` (`scripts/context-budget.sh`) builds the
path from `ANTIGRAVITY_APP_DATA_DIR`, defaulting to `~/.gemini/antigravity-cli`. The IDE
doesn't set that var and keeps its transcripts under `~/.gemini/antigravity-ide/`, so the
lookup misses.

`check` in the same shell still resolved the right file
(`~/.gemini/antigravity-ide/brain/<conv>/…/transcript_full.jsonl`, `method=estimate`) because
the hook had already registered the chat from its payload's `transcriptPath`.

## Q4 — two concurrent sessions in one window

**Verdict: YES.** Each chat's shell and hook carry their own conversation id, each `check`
names its own transcript, and there is exactly one registry record per chat. Nothing crossed
over.

## Gaps

- **Agent-shell `register` fails in the IDE** (above). Harmless while the hook runs, but an
  agent following the "register by hand if hooks are disabled" rule gets an error. Fix:
  when `ANTIGRAVITY_APP_DATA_DIR` is unset, try each data root (`antigravity-cli/`,
  `antigravity-ide/`, `antigravity/`) for `brain/<id>/`; the id is unique, so this is not a
  guess.

**Result: PASS** (own transcript per chat, one record each, hooks per chat). One gap: manual
`register` from the IDE shell.
