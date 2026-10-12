---
id: 11-copilot-vscode-measure-inputtokens
title: copilot-vscode measures inputTokens on session-state transcripts
status: doing
kind: work
wave: 3
blocked_by: [08-reconcile-w2]
tier: standard
sessions: [7]
---

## Goal

Found at reconcile 08. `copilot_vscode_measure` (`scripts/context-budget.sh`) reads only
`"promptTokens"`; a live `~/.copilot/session-state/<sid>/events.jsonl` (the VS Code agent's
transcript since node 05) carries `inputTokens`, so a copilot-vscode record bound to one falls
back to a size estimate. `copilot_cli_measure` already reads `inputTokens`. Make the
copilot-vscode measure exact on a session-state transcript; keep the `chatSessions`
`promptTokens` path.

## Acceptance

- [x] Suite case: `check` on a copilot-vscode record whose artifact is a session-state `events.jsonl` with `inputTokens` reports `method=exact` and that count
- [x] Old chatSessions `promptTokens` cases still pass

## Log
- s7 · started, tier standard
- s7-c · Q1/Q2 cases appended to scripts/tests/test-context-budget-registry.sh; Q1b red before fix (method=estimate tokens=34)
- s7-c · copilot_vscode_measure in scripts/context-budget.sh now delegates to copilot_cli_measure (promptTokens|inputTokens|input_tokens) after the fresh check; registry 240/0, statusline 20/0, vendor-budget-hooks 165/0
- s7-c · on disk: fix commit c0f4dd4 + main merged (95800af) on branch worktree-agent-ad8b099e257d3ad3e, registry 240/0 after merge; not done: push, plan.sh status write
