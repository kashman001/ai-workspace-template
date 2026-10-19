---
id: 02-l95-dispatch-contract
title: L95 — dispatch contract: read-first, Remember:, WIP commits, proved DONE
status: todo
kind: work
wave: 1
blocked_by: []
tier: standard
check: bash "$WORKSPACE_ROOT/scripts/tests/test-fleet-dispatch-contract.sh" >/dev/null 2>&1
sessions: []
isolated: yes
---

## Goal
Card: `docs/template-workspace-backlog.html` → L95 (grep the ID; read only that card). Do not edit the backlog files — the reconcile node moves cards.
Synthesis entries R2, R3, R4, R19 in `work/external-tools-review/synthesis.md` (Theme A, Theme E). `scripts/fleet.sh dispatch-contract` output gains: a read-first file list (CONTEXT.md, the work item launcher; built-in Explore/Plan subagents start without CLAUDE.md); a `Remember:` section requested in the return; for worktree children, commit WIP at each checkpoint; a `DONE` return must quote its check command and output. Test-first in `scripts/tests/test-fleet-dispatch-contract.sh`. Docs: `docs/context-budget.md` → "Dispatching long-running children"; `docs/plans.md` example `Done when the orchestrator says so` → a named check command (if `scripts/tests/fixtures/plan-01-concept/` or `test-doc-consistency.sh` pins that text, update them together).

## Acceptance
- [ ] new suite cases seen failing before the change (quoted in Log)
- [ ] suite passes after (node check)
- [ ] both docs updated; `scripts/check-workspace-structure.sh` passes

## Log
