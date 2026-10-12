---
id: 06-one-hook-per-copilot-event
title: One hook config per Copilot event (nodes 3 + 8b)
status: doing
kind: work
wave: 2
blocked_by: [02-reconcile-w1]
sessions: [6]
---

## Goal

Findings: `work/runtime-session-identity/findings.md` → "Gaps", node 3 and 8b. Evidence: `probes/copilot-cli.md`, `probes/copilot-vscode.md`.

One Copilot turn fires three hook configs: `.github/hooks/context-budget-vscode.json`,
`.github/hooks/context-budget.json` (CLI) and `.claude/settings.json` `Stop` (as `claude`).
Make exactly one act per event: the claude entry and the duplicate copilot entry refuse a
Copilot payload (e.g. a `.copilot/session-state/` transcript path or the payload shape).

## Acceptance

- [ ] Suite case: a Copilot payload into the claude Stop shim writes no claude stamp or record
- [ ] Suite case: one Copilot turn's payloads through all three configs leave exactly one stamp
- [ ] Existing suites pass

## Log
- s6 · started, tier standard
