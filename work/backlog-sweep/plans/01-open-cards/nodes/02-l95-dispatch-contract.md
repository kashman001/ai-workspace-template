---
id: 02-l95-dispatch-contract
title: L95 — dispatch contract: read-first, Remember:, WIP commits, proved DONE
status: done
kind: work
wave: 1
blocked_by: []
tier: standard
check: bash "$WORKSPACE_ROOT/scripts/tests/test-fleet-dispatch-contract.sh" >/dev/null 2>&1
sessions: [3]
isolated: yes
---

## Goal
Card: `docs/template-workspace-backlog.html` → L95 (grep the ID; read only that card). Do not edit the backlog files — the reconcile node moves cards.
Synthesis entries R2, R3, R4, R19 in `work/external-tools-review/synthesis.md` (Theme A, Theme E). `scripts/fleet.sh dispatch-contract` output gains: a read-first file list (CONTEXT.md, the work item launcher; built-in Explore/Plan subagents start without CLAUDE.md); a `Remember:` section requested in the return; for worktree children, commit WIP at each checkpoint; a `DONE` return must quote its check command and output. Test-first in `scripts/tests/test-fleet-dispatch-contract.sh`. Docs: `docs/context-budget.md` → "Dispatching long-running children"; `docs/plans.md` example `Done when the orchestrator says so` → a named check command (if `scripts/tests/fixtures/plan-01-concept/` or `test-doc-consistency.sh` pins that text, update them together).

## Acceptance
- [x] new suite cases seen failing before the change (quoted in Log)
- [x] suite passes after (node check)
- [x] both docs updated; `scripts/check-workspace-structure.sh` passes

## Log
- s3 · started, tier standard
- s3-b · red first: test-fleet-dispatch-contract.sh K8a-K8f all FAILED ("results: 24 passed, 6 failed", e.g. "no [Remember:] in ..."); after scripts/fleet.sh change: "results: 30 passed, 0 failed".
- s3-b · docs/context-budget.md (Dispatching section) and docs/plans.md example (now a named `plan.sh check` command) updated; check-workspace-structure.sh "All checks passed", test-doc-consistency 17/0, test-check-plans 6/0. Fixtures in scripts/tests/fixtures/plan-01-concept left as-is (not pinned by docs text). On disk: fleet.sh, suite, 2 docs; not done: backlog (reconcile node job).
- s3 · check passed → done
