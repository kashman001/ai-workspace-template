---
id: 04-copilot-cli-hook-registration
title: Hook-side registration for Copilot CLI (node 2)
status: doing
kind: work
wave: 2
blocked_by: [02-reconcile-w1]
sessions: [6]
---

## Goal

Findings: `work/runtime-session-identity/findings.md` → "Gaps", node 2. Evidence: `probes/copilot-cli.md`.

Set the `copilot` adapter row to `register=hook`, derive the transcript from `sessionId`
under `${COPILOT_HOME:-~/.copilot}/session-state/<sid>/events.jsonl`, and fix the
`COPILOT_STATE_DIR` default that ignores `COPILOT_HOME`.

## Acceptance

- [x] Suite case: `sessionStart` payload with a custom `COPILOT_HOME` registers `<COPILOT_HOME>/session-state/<sid>/events.jsonl`
- [x] Existing suites pass

## Log
- s6 · started, tier standard
- s6-b · red: added F1a-F1d to scripts/tests/test-context-budget-registry.sh; F1a/F1c/F1d FAIL before the fix (no copilot-cli record written; the check hook reads ~/.copilot, not COPILOT_HOME); F1b (silent fresh start) passes as a guard
- s6-b · green: copilot row register=agent→hook in scripts/hooks/context-budget-adapters.conf; copilot-state default now ${COPILOT_STATE_DIR:-${COPILOT_HOME:-$HOME/.copilot}/session-state} in scripts/hooks/context-budget-hook.sh; one paragraph in docs/context-budget.md; F1a-F1d pass, registry 215/0, vendor-hooks 150/0, and all 18 context-budget-referencing suites under scripts/tests/ pass
- s6-b · done: committed on branch worktree-agent-a38dff2de2c3ddd89 (adapter row, hook derivation, F1 cases, docs/context-budget.md paragraph); main merged (already up to date). Not on disk: no live Copilot CLI re-probe of hook registration; nodes 3/4 work (CLI firing the VS Code + Claude hooks, mtime refusal) untouched
