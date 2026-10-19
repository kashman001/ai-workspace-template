---
id: 10-live-reprobe-vscode
title: User re-probes VS Code Copilot live: one record per chat, exact count, no claude record
status: done
kind: hitl
wave: 4
blocked_by: [09-reconcile-w3]
sessions: [14]
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
- s14 · started, tier frontier
- s14 · PASS (user ran it in the probe clone at 7b18ce1, 2026-10-18). Two new VS Code Copilot chats, 22dcc436… and 37e69d81…: turn 1 `runtime=copilot-cli method=estimate tokens=33151` / `32986`; turn 2 `runtime=copilot-cli method=exact tokens=42785` (both), each on its own `session-state/<sid>/events.jsonl`. `.context-budget/sessions/` has exactly `copilot-cli-<sid>.json` for each, and no copilot-vscode or claude record for either sid. The `copilot-vscode-90bc99b7…` and `copilot-vscode-d5d80a4e…` files are from 2026-10-13, before the fix.
- human · done
