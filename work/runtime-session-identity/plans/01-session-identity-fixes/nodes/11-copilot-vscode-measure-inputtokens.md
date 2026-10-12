---
id: 11-copilot-vscode-measure-inputtokens
title: copilot-vscode measures inputTokens on session-state transcripts
status: todo
kind: work
wave: 3
blocked_by: [08-reconcile-w2]
tier: standard
sessions: []
---

## Goal

Found at reconcile 08. `copilot_vscode_measure` (`scripts/context-budget.sh`) reads only
`"promptTokens"`; a live `~/.copilot/session-state/<sid>/events.jsonl` (the VS Code agent's
transcript since node 05) carries `inputTokens`, so a copilot-vscode record bound to one falls
back to a size estimate. `copilot_cli_measure` already reads `inputTokens`. Make the
copilot-vscode measure exact on a session-state transcript; keep the `chatSessions`
`promptTokens` path.

## Acceptance

- [ ] Suite case: `check` on a copilot-vscode record whose artifact is a session-state `events.jsonl` with `inputTokens` reports `method=exact` and that count
- [ ] Old chatSessions `promptTokens` cases still pass

## Log
