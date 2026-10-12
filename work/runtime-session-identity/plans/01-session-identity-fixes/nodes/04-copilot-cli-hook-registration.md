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

- [ ] Suite case: `sessionStart` payload with a custom `COPILOT_HOME` registers `<COPILOT_HOME>/session-state/<sid>/events.jsonl`
- [ ] Existing suites pass

## Log
- s6 · started, tier standard
