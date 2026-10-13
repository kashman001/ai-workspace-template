---
id: 01-fix-copilot-vscode-exact-tokens
title: Read prompt_tokens so Copilot VS Code measures exact, test-first
status: todo
kind: work
wave: 1
blocked_by: []
sessions: []
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

- [ ] Field choice justified from real transcripts (VS Code and CLI), written in the Log
- [ ] New suite case in `scripts/tests/test-context-budget-registry.sh` seen failing before the fix
- [ ] Fix makes it pass; registry, hooks, statusline and doc-consistency suites green
- [ ] Live: `check` in the probe clone on a VS Code session reports `method=exact`

## Log
