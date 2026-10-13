# Catchup prompt — template-maintenance (paste into a new agent session)

> **This file is the LAUNCHER.** Forward-only, REPLACED at each rollover.
> Provenance lives in `handoff.md`. Convention: docs/work-directory-conventions.md.

## >>> START HERE <<<

**Mission.** Add a `plan.sh` verb (e.g. `plans`, or `status --all`) that lists
every work item's plans with progress: item, plan, open/closed, wave n of m,
done/total, blocked count. One line per plan; support `--json`. TDD it in
`scripts/tests/test-plan.sh`, document it in `docs/plans.md`'s verb table and the
`plan.sh` usage header, then `scripts/run-checks.sh`, file and resolve a backlog
card, and commit. (Requested by the user 2026-10-12. The backlog was 0/138/5/0/6 before this.)

**Waiting on the user:**
- Run `scripts/migrate-glossary.sh` on `~/Developer/experiments/NeogeoEmu`?
  It refuses until that repo has a first commit. Never run it on a real
  project without the user's go-ahead.
- Delete `skills/code-review/workspace.patch` once mattpocock/skills#1242 lands
  (the sync says so when the issue closes).

**State:** `main` pushed at session-24 end (TEMPLATE_VERSION 2026-10-12).
On the next push after that day, bump it again.

**Optional later (not queued):** pstack `arena`/`swarm`/`hillclimb` were left out
as Cursor-bound; revisit only as an agent-agnostic rewrite.

**Do NOT reload:** skill-packs and skill-ceremony work is done (ledger block 24;
reports `skill-packs-report.md`, `skill-ceremony-report.md`).

## Plan position

<!-- plan:begin position -->
Position: plan 01-skill-ceremony, closed, wave 4 of 4, done 12/12, doing 0, todo 0, blocked 0, dropped 0, sessions 1.
Frontier: none. Remaining: 0 of 12.
<!-- plan:end position -->

## First actions

1. `scripts/context-budget.sh register --project template-maintenance`.
2. Do the Mission above, then ask the user what's next.
