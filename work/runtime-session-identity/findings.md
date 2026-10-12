# Findings and draft plan: runtime session identity

Evidence: `probes/<surface>.md`. CLI probes ran 2026-10-12 (sessions 2 and 3). The
VS Code probes (Codex, Copilot) ran 2026-10-12 (session 4). The Antigravity IDE/app
and Codex desktop app probes are still open (`probes/user-checklist.md` steps 3–4).

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

**VS Code (session 4):**

- **Codex extension:** behaves like the CLI. `CODEX_THREAD_ID` is in the agent shell;
  payloads carry `session_id` + `transcript_path`. The hooks are skipped silently until
  trusted, and trust lands after the turn that prompted it, then applies to already-open
  chats. Two chats stayed separate. The sandbox blocks `ps`, so `pid: null`.
- **Copilot agent mode:** now runs on the Copilot CLI runtime, with the transcript at
  `~/.copilot/session-state/<sid>/events.jsonl` and `COPILOT_AGENT_SESSION_ID` in the shell.
  `VSCODE_TARGET_SESSION_LOG` is not set. The copilot-vscode adapter is **broken** here:
  agent `register` fails, and the hook registers a nonexistent
  `~/.copilot/chatSessions/<sid>.jsonl`, so nothing is measured by that adapter. Each event
  fires three hook configs: VS Code, CLI and Claude's `Stop`. Only the CLI config measured
  correctly.
- **Claude Code extension:** opening the folder pre-spawned two idle `claude` processes
  that registered records for transcripts that never got written (phantom records).

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
   the id for `--session-id`. IDE result: pid-walk is out. Copilot's
   `copilot-runtime` is one process for every chat, and Codex's sandbox
   blocks `ps` (`pid: null`). Use the env id where it exists (Codex, Copilot
   both have one); otherwise the hook-supplied id.
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
8. **IDE surfaces.**
   - 8a. **Copilot VS Code on the CLI runtime.** Fix the hook's
     `chat-sessions` derivation to use a `session-state/<sid>/events.jsonl`
     `transcript_path` as is, and make `copilot_vscode_discover` use
     `COPILOT_AGENT_SESSION_ID`. Check: a suite case with the new payload
     shape registers the existing `events.jsonl`, and agent `register` with only
     `COPILOT_AGENT_SESSION_ID` set binds it.
   - 8b. **One hook config per Copilot event.** Today the VS Code, CLI and
     Claude `Stop` configs all fire for a Copilot-in-VS-Code turn. Merge with
     node 3: the claude and duplicate copilot entries refuse a Copilot
     payload (`.copilot/session-state/` path). Check: a Copilot payload into
     the claude Stop shim writes nothing, and one turn writes one stamp.
   - 8c. **Phantom records.** Claude Code's VS Code extension pre-spawns idle
     sessions whose transcripts never appear. Prune or ignore records whose
     artifact is still missing after a grace period. Check: a stale record
     with a missing artifact is ignored by `record`/`status`.
   - 8d. **Docs for the Codex extension trust step** (fold into node 7).

Order: 4 first (it's a safety net for everything else), then 1, 2, 3 and 6
can run in parallel. 5 follows the IDE probes. 7 closes.

## Cleanup owed

- Antigravity probe leftovers: see `probes/antigravity-cli.md` → "Cleanup owed".
- Scratch clones `ws-codex`, `ws-copilot`, `ws-gemini` and
  `codex-payloads/` are in this session's scratchpad (disposable).
- About 8 probe rollouts in `~/.codex/sessions/2026/10/12/` (15:04–15:07);
  delete them on the user's say-so.
- IDE probe clone `~/Developer/experiments/ws-identity-probe`, plus its trust entries:
  `[projects.".../ws-identity-probe"]` and two `[hooks.state."…/ws-identity-probe/…"]` in
  `~/.codex/config.toml`. Also the two Codex VS Code rollouts (15:54, 15:57) and two Copilot
  `~/.copilot/session-state/{5cd5317c…,2d9ebe1a…}` dirs.
