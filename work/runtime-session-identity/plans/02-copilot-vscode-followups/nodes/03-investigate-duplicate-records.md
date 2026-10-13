---
id: 03-investigate-duplicate-records
title: Investigate copilot-cli + copilot-vscode duplicate records; draft decision note
status: todo
kind: work
wave: 1
blocked_by: []
sessions: []
---

## Goal

Each Copilot VS Code chat has two registry records with the same artifact:
`copilot-cli-<sid>.json` (written by the CLI hook config) and `copilot-vscode-<sid>.json`
(written by `register --runtime copilot-vscode`). Investigate, without changing code:
which path writes each; whether duplicates affect the ambiguity refusal (two chats, no id
var), `prune_phantoms`, `check` auto-detection or the status line; whether the hook payload
or env can tell VS Code from the terminal (`AI_AGENT`?). Draft a Tier-2 note with options
and a recommendation (for example: accept, canonicalise to one runtime name, or dedupe by
session id). The answer may depend on node 02.

## Acceptance

- [ ] Writer of each record identified, with evidence
- [ ] Effect on ambiguity refusal, pruning, `check` and status line tested or reasoned from code (cite lines)
- [ ] Tier-2 note drafted in `decisions.md`: options, recommendation, rejected alternatives

## Log
