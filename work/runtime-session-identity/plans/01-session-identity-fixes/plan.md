---
plan: 01-session-identity-fixes
status: closed
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
- s6 · Correction to the s6-c prompt_tokens note: copilot_cli_measure reads inputTokens (exact on live events.jsonl); only copilot_vscode_measure (promptTokens only) falls back to a size estimate on a session-state transcript. Follow-up node copilot-vscode-measure-inputtokens (wave 3).
- s6 · For node 13 (docs): docs/context-budget.md needs the antigravity adapter row, .agents/hooks.json in the support matrix (agy fires hooks with no trust step, runs them from .agents/ — hence cd ..), the inject-json-only envelope, that the Copilot CLI config is the only Copilot config that acts, and that Claude SessionStart requires transcript_path.
- s6 · resolve_runtime_pid matches the process name to the runtime name, so antigravity (process agy) and sandboxed codex hooks record no pid; liveness for them must not rely on pid. No live run yet of codex SessionStart, copilot sessionStart, or agy against the committed hook configs — fixture-tested only; node 11 probes are the place to confirm.
- s7 · s7 · node 09: prune_phantoms deletes (not hides) a record whose artifact is missing >60 min after its last write, in register/record only; read-only check/--session-id don't prune, so fleet.sh/attach-session.sh see a phantom until some session registers/records. A pre-spawned session first used >1h later loses its record until it re-registers. Node 13 docs: document the 60-min phantom grace in docs/context-budget.md.
- s8 · Follow-up, not this plan's: copilot_vscode_discover/pick_unambiguous match the cwd with grep -qF "$(pwd)", a substring test (/x/ws also matches /x/ws2), which can refuse or bind wrongly across sibling-named workspaces.

## Out of scope

- Gemini CLI (superseded by Antigravity).
- Pushing `main` (the user's call).
- Probe cleanup (`findings.md` → "Cleanup owed", on the user's say-so).

## Replans

- 2026-10-12 (08-reconcile-w2): added 11-copilot-vscode-measure-inputtokens to wave 3 and to 12-reconcile-w3's blocked_by — copilot_vscode_measure reads only promptTokens, so a session-state transcript falls back to a size estimate. Local replan.

<!-- plan:begin board -->
| Wave | Node | Kind | Tier | Status |
|---|---|---|---|---|
| 1 | 01-refuse-instead-of-guess | work | standard | done |
| 1 | 02-reconcile-w1 | reconcile | frontier | done |
| 2 | 03-codex-hook-registration | work | standard | done |
| 2 | 04-copilot-cli-hook-registration | work | standard | done |
| 2 | 05-copilot-vscode-cli-runtime | work | standard | done |
| 2 | 06-one-hook-per-copilot-event | work | standard | done |
| 2 | 07-antigravity-runtime | work | standard | done |
| 2 | 08-reconcile-w2 | reconcile | frontier | done |
| 3 | 09-phantom-records | work | standard | done |
| 3 | 10-record-without-env-id | work | standard | done |
| 3 | 11-copilot-vscode-measure-inputtokens | work | standard | done |
| 3 | 11-remaining-surface-probes | hitl | frontier | dropped |
| 3 | 12-reconcile-w3 | reconcile | frontier | done |
| 4 | 13-docs | work | standard | done |
| 4 | 14-reconcile-w4 | reconcile | frontier | done |
| 5 | 15-review | work | standard | done |
| 5 | 16-reconcile-w5 | reconcile | frontier | done |
Frontier: none. Remaining: 0 of 17. Sessions used: 4.
<!-- plan:end board -->
