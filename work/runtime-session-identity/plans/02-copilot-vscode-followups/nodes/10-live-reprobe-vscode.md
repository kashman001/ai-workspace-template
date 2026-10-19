---
id: 10-live-reprobe-vscode
title: User re-probes VS Code Copilot live: one record per chat, exact count, no claude record
status: todo
kind: hitl
wave: 4
blocked_by: [09-reconcile-w3]
sessions: []
---

## Goal

The user opens two new Copilot chats in VS Code in the probe clone (fresh labels) and has each
agent run `scripts/context-budget.sh register` by hand with `--runtime copilot-vscode`, then `check`
on its second turn (turn 1 is an estimate until the first `session.usage_checkpoint`; s12). Paste the
raw `runtime=` lines. Answer: `plan.sh done 10-live-reprobe-vscode --by human`, or `drop`.

## Acceptance

- [ ] Each chat has exactly one record, `copilot-cli-<sid>.json`; no `copilot-vscode-*` and no `claude-*` record
- [ ] Turn-2 `check` reports `method=exact`

## Log
