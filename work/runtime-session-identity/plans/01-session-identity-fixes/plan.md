---
plan: 01-session-identity-fixes
status: open
replan: local
default_tier: standard
---

# Plan 01 — Session identity fixes

## Goal

Concurrent sessions in one workspace, across Codex, Copilot and Antigravity (CLI and VS
Code), each bind and measure their own transcript, never a sibling's. Discovery refuses
instead of guessing. Source: `work/runtime-session-identity/findings.md` → "Gaps" (nodes
1–8). Base SHA `bc1cce4`.

## Not yet specified
- s5 · detect_runtime now returns antigravity on ANTIGRAVITY_CONVERSATION_ID, ahead of CLAUDECODE; node 07 adds the adapter (discover/measure/session_id_for). Until then such a session dies with 'no session artifact'.
- s5 · detect_runtime order is now ANTIGRAVITY > COPILOT_AGENT_SESSION_ID > CODEX_THREAD_ID > CLAUDECODE > CODEX_SANDBOX/HOME > OPENCODE > VSCODE_TARGET_SESSION_LOG. Nodes 05 and 06 should check that a Copilot CLI run inside a VS Code terminal still resolves as intended.
- s6 · In a VS Code agent shell, auto-detect says copilot-cli, so agent register writes copilot-cli-<sid> while the VS Code hook writes copilot-vscode-<sid>: two records for one events.jsonl (from s6-c).
- s6 · A live Copilot events.jsonl names its token count prompt_tokens; neither copilot measure function reads it, so both fall back to a size estimate (from s6-c).
- s6 · Dispatcher now registers-only on non-check/non-turn-end events for register=hook rows; copilot/copilot-vscode shims called with no event argument now register instead of staying silent. Codex sandbox hook records carry pid:null — liveness must not rely on pid for codex (from s6-a).

## Out of scope

- Gemini CLI (superseded by Antigravity).
- Pushing `main` (the user's call).
- Probe cleanup (`findings.md` → "Cleanup owed", on the user's say-so).

## Replans

<!-- plan:begin board -->
| Wave | Node | Kind | Tier | Status |
|---|---|---|---|---|
| 1 | 01-refuse-instead-of-guess | work | standard | done |
| 1 | 02-reconcile-w1 | reconcile | frontier | done |
| 2 | 03-codex-hook-registration | work | standard | done |
| 2 | 04-copilot-cli-hook-registration | work | standard | done |
| 2 | 05-copilot-vscode-cli-runtime | work | standard | done |
| 2 | 06-one-hook-per-copilot-event | work | standard | doing |
| 2 | 07-antigravity-runtime | work | standard | doing |
| 2 | 08-reconcile-w2 | reconcile | frontier | todo |
| 3 | 09-phantom-records | work | standard | todo |
| 3 | 10-record-without-env-id | work | standard | todo |
| 3 | 11-remaining-surface-probes | hitl | frontier | todo |
| 3 | 12-reconcile-w3 | reconcile | frontier | todo |
| 4 | 13-docs | work | standard | todo |
| 4 | 14-reconcile-w4 | reconcile | frontier | todo |
| 5 | 15-review | work | standard | todo |
| 5 | 16-reconcile-w5 | reconcile | frontier | todo |
Frontier: none (06-one-hook-per-copilot-event doing, 07-antigravity-runtime doing). Remaining: 11 of 16. Sessions used: 2.
<!-- plan:end board -->
