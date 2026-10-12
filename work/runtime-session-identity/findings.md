# Findings and draft plan: runtime session identity

Evidence: `probes/<surface>.md`. CLI probes ran 2026-10-12 (sessions 2 and 3). The
IDE probes are pending (`probes/user-checklist.md`).

## Where we stand

| | Codex CLI 0.153.4 | Copilot CLI 1.0.78 | Gemini CLI 0.46.0 | Antigravity CLI 1.3.3 |
|---|---|---|---|---|
| Q1: id env var in the agent's shell | YES (`CODEX_THREAD_ID`, `CODEX_SESSION_ID`) | YES (`COPILOT_AGENT_SESSION_ID`) | NO (only `GEMINI_CLI=1`); hooks get `GEMINI_SESSION_ID` | YES (`ANTIGRAVITY_CONVERSATION_ID`, plus `ANTIGRAVITY_APP_DATA_DIR`); hooks get it too |
| Q2: hooks fire, payload has the id and transcript | YES once trusted; untrusted = skipped silently. A SessionStart event exists, and its payload has `session_id` + `transcript_path` | YES once trusted. `sessionStart` has `sessionId`; `transcriptPath` only on `agentStop` (path derivable from the id) | Code says YES (SessionStart/SessionEnd, `session_id` + `transcript_path`); not seen live (no auth) | YES, no trust step. `.agents/hooks.json`; every payload has `conversationId` + `transcriptPath`. No SessionStart: first `PreInvocation` (`invocationNum: 0`) |
| Q3: `register` binds its own transcript | YES when the var is set | YES when the var is set | NO: `no session artifact found`; the `logs.json` fallback is out of date for 0.46 | **NO: from a plain shell it auto-detects gemini (stale `logs.json`, reports OK); launched from Claude Code it binds the parent Claude session** |
| Q4: two sessions at once, var unset | **NO: each bound the other's transcript** | **NO: each bound the other's transcript** | Blocked live; telemetry carries `session.id`, so it is separable | YES on the hook side (each payload carried its own id); each shell has its own env id |

When the env var is set (the normal CLI case), Codex and Copilot bind
correctly. The newest-file fallback is wrong whenever two sessions are live.
That makes it unsafe for any surface that doesn't set the var.

## Gaps → draft plan nodes (each with its proving check)

1. **Hook-side registration for Codex.** Add `[[hooks.SessionStart]]` to
   `.codex/config.toml` and set the codex adapter row to `register=hook`.
   Check: suite case where a SessionStart payload with the env var unset
   writes `codex-<sid>.json` pointing at the payload's transcript.
2. **Hook-side registration for Copilot CLI.** Set the `copilot` row to
   `register=hook`, derive the transcript from `sessionId` under
   `${COPILOT_HOME:-~/.copilot}`, and fix the `COPILOT_STATE_DIR` default
   that ignores `COPILOT_HOME`. Check: suite case with a custom `COPILOT_HOME`.
3. **Copilot CLI fires the VS Code hook file and (likely) the Claude
   hooks.** Make the copilot-vscode and claude hook entries refuse
   payloads from the CLI (e.g. an id shape or `COPILOT_AGENT_SESSION_ID`
   check), so the CLI writes no stray `copilot-vscode-*` or claude
   records. Confirm the Claude-hook claim first; it is inferred from
   stderr. Check: a CLI-shaped payload into each hook writes nothing.
4. **Refuse instead of guess.** In the discovery fallback (codex, copilot-cli,
   copilot-vscode): if more than one candidate transcript is live
   (recent mtime, matching cwd), refuse with a reason code instead of taking
   the newest. Check: the two-concurrent-fixtures case exits non-zero
   instead of swapping.
5. **Agent-run commands without the env var.** `record` from a shell with no
   id var must find its own registry record. Options: walk the ancestor
   pids to the registered `pid`, or have the hook's context message carry
   the id for `--session-id`. The choice depends on the IDE probes (one app
   server process can host several threads).
6. **Antigravity: add as a runtime** (replaces the Gemini node; Gemini CLI is
   superseded). New `antigravity` adapter row with `register=hook`; a committed
   `.agents/hooks.json` whose `PreInvocation` handler registers on
   `invocationNum == 0` from the payload's `conversationId` + `transcriptPath`;
   discover/measure over
   `~/.gemini/antigravity-cli/brain/<id>/.system_generated/logs/transcript_full.jsonl`
   (last `PLANNER_RESPONSE` `input_tokens` + `cache_read_tokens`); a
   `detect_runtime` case on `ANTIGRAVITY_CONVERSATION_ID` so auto-detect stops
   mis-binding to gemini. Check: suite case where a `PreInvocation` payload writes
   `antigravity-<id>.json` pointing at its transcript, and `register` with only
   the env var set picks `antigravity`. Evidence: `probes/antigravity-cli.md`.
   Also: `detect_runtime` must rank `ANTIGRAVITY_CONVERSATION_ID` above
   inherited outer-runtime vars (`CLAUDECODE`). An `agy` launched from Claude
   Code otherwise registers as the parent Claude session. That ordering bug hits
   any nested runtime, so check node 4 against it too.
7. **Docs.** Hook trust is required (Codex and Copilot skip untrusted hooks
   silently); update the support matrix and the adapter table in
   `docs/context-budget.md`.
8. **IDE surfaces.** Nodes to be added from the IDE probe results.

Order: 4 first (it's a safety net for everything else), then 1, 2, 3 and 6
can run in parallel. 5 follows the IDE probes. 7 closes.

## Cleanup owed

- Antigravity probe leftovers: see `probes/antigravity-cli.md` → "Cleanup owed".
- Scratch clones `ws-codex`, `ws-copilot`, `ws-gemini` and
  `codex-payloads/` are in this session's scratchpad (disposable).
- About 8 probe rollouts in `~/.codex/sessions/2026/10/12/` (15:04–15:07);
  delete them on the user's say-so.
