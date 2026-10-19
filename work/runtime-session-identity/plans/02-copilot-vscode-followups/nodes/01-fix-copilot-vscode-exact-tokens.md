---
id: 01-fix-copilot-vscode-exact-tokens
title: Read prompt_tokens so Copilot VS Code measures exact, test-first
status: doing
kind: work
wave: 1
blocked_by: []
sessions: [11]
---

## Goal

Copilot Chat agent mode in VS Code writes no `inputTokens`/`promptTokens` lines to
`~/.copilot/session-state/<sid>/events.jsonl`, so `copilot_cli_measure`
(`scripts/context-budget.sh`) falls back to a size estimate. s10 chat D: estimate 33,857 vs
real 47,574 (~30% low, so WARN/STOP fire late). The exact count is there as `prompt_tokens`
inside `session.usage_checkpoint` → `promptCacheBreakState`. Evidence: probe clone
`~/Developer/experiments/ws-identity-probe-s9`, sessions `d5d80a4e…`, `90bc99b7…`.

First confirm which value is the live context (last `prompt_tokens` vs `frontier_tokens`;
any per-model or sub-conversation entries) and that CLI transcripts keep using `inputTokens`.
Then a registry-suite case with a VS Code-shaped fixture, seen red, then the fix.

## Acceptance

- [x] Field choice justified from real transcripts (VS Code and CLI), written in the Log
- [x] New suite case in `scripts/tests/test-context-budget-registry.sh` seen failing before the fix
- [x] Fix makes it pass; registry, hooks, statusline and doc-consistency suites green
- [ ] Live: `check` in the probe clone on a VS Code session reports `method=exact`

## Log
- s11 · started, tier standard
- s11 · field choice: `prompt_tokens` (in `session.usage_checkpoint` → `promptCacheBreakState[].models.<m>`), not `frontier_tokens` (always 2–3 lower). Real CLI transcript `~/.copilot/session-state/018beebd…`: checkpoint `prompt_tokens` 34944 = last `session.usage_record` `inputTokens` 34944, so it is the same live count; `ea38e6fe…` agrees (26842 = 26842). VS Code `d5d80a4e…`/`90bc99b7…` carry no `inputTokens` at all; only conversation `main`, one model per checkpoint in all transcripts read.
- s11 · found while checking CLI: checkpoint and `session.shutdown` lines also carry session-cumulative `inputTokens` under `modelMetrics`/`agentMetrics`/`providerModelMetrics` (018beebd: 102610 = sum of three calls), and CLI writes a checkpoint after every turn, so the old grep overcounted Copilot CLI mid-session (ea38e6fe after 2 calls: 47114 vs live ~24.6K). Same function, so fixed here too: each line cut at its first `"…Metrics":` key (after `prompt_tokens` in every real line checked).
- s11 · tests `scripts/tests/test-context-budget-registry.sh` Q3a (VS Code-shaped, red: `method=estimate tokens=95`), Q3b (CLI record after checkpoint wins, guard, green before), Q3c (cumulative Metrics, red: `tokens=102610`); fix in `copilot_cli_measure` (`scripts/context-budget.sh`); registry 279/0, statusline 20/0, vendor hooks 167/0, attach-session 27/0, doc-consistency 17/0. Real transcripts now: d5d80a4e 50205, 90bc99b7 47574, 018beebd 34944, all `method=exact`. Doc rows updated: `docs/context-budget.md` Copilot VS Code + Copilot CLI.
