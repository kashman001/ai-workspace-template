# Next Session — template-improvement-review (Stage 4: close phase 0, then fleet plan + parallel execution)

> **This file is the LAUNCHER (catch-up prompt).** Forward-only, REPLACED at
> each rollover. Past-tense provenance lives in `handoff.md`.
> Convention: docs/work-directory-conventions.md.

## Mission

**Stage 4, executed by a fleet.** User's direction (2026-09-17, session 10):
plan the remaining phases as a dependency graph, then run them **in parallel
with a fleet of agents**, one agent per phase, each in its own worktree
against its own throwaway work item; the parent stays lean (writes the
fleet plan, dispatches, merges, runs suites) and never edits the scripts
itself. Position: phase 0 of 9 + cutover; see `stage4-tracker.md`.

**Waves (from Part 4 "Order and gates"):** A = phases 1 ∥ 2 · B = 3 ·
C = 4 ∥ 6 · D = 5 · E = 7 · F = 8 · cutover attended, by the parent.
Only A and C have parallelism; the rest is a chain. Each wave merges to
`main` on green before the next starts. Read-only prep for a later wave
(its `plans/phase-<n>.md` draft from the ticket + design tables) may run
early in parallel, but no code for a phase before its blockers merge.

**Readability rule (user, binding for every doc they read):** short; plain
language; self-contained; each concept introduced by a diagram or a
two-sentence explanation. Memory `review-docs-plain-language`.

**No-human-in-the-loop clause:** phase 1 needs no user input. Work on a
branch or worktree against a throwaway work item; `template-improvement-review`
stays on the old scripts until cutover.

## Read these, in order

1. `work/template-improvement-review/stage4-tracker.md` (whole).
2. `work/template-improvement-review/issues/02-phase-1-record-helper.md`.
3. `work/template-improvement-review/evaluation/stage3-design-v2.md` — the
   record table and the two lock/liveness footnotes only (grep `| Block |`,
   `[^lock]`, `[^liveness]`).
4. `work/template-improvement-review/plans/phase-0.md` — "Decisions made
   here" (the record's `schema: 1` shape phase 1 inherits).
5. `work/template-improvement-review/handoff.md` — top block only.

## Do NOT reload

Parts 1–4 of the findings file, the stage1-*/stage3-* reports, `review.md`,
`decisions.md` (append only), backlog HTML whole, the three big scripts whole
(grep them).

## State snapshot

- `main` = commit of session 10; clean; ahead of origin (do not push).
- **No supervisor should be running.** Session 10 staged nothing; the old
  supervisor (pid 72900) logs a deliberate quit and exits when session 10
  is closed. Old counter `.session-seq` = 10.
- Root `ROLLOVER_RELAUNCH=manual`; this item's `context-budget.env` says
  `auto` (for after cutover). Until cutover every session here is started
  by hand.

## First actions

1. `scripts/context-budget.sh register --project template-improvement-review`
2. Verify the chain ended: `ps -p 72900` prints nothing;
   `tail -3 work/template-improvement-review/.session-loop.log` shows the
   quit verdict for session #10; `.session-loop` state file is gone. If the
   supervisor is still alive, stop: report it and do not edit any script.
3. Tracker: phase 0 → `done`, fill Done + Commit (131142a).
   `record --label "phase 0 done"`.
4. Write `plans/fleet-plan.md` (short, plain, one table): the waves above;
   per agent — worktree/branch name, throwaway item name, ticket, plan file
   to write first, suites that must be green, what it hands back (branch +
   plan file + record evidence); parent's merge/verify loop per wave;
   hazards (measurer hooks measure the parent itself — agents edit only in
   their worktree; never two agents on one script in one wave; `main "$@"`
   wrapper commit first in phase 5). Dispatch records:
   `scripts/context-budget.sh dispatch-open --project template-improvement-review --task <phase-n> --report <path>` per agent, `dispatch-close` at yield.
5. Show the user the fleet plan (one screen) and get the go; then launch
   wave A (phases 1 and 2) as two parallel agents with worktree isolation.
   Merge on green, run all `scripts/tests/*.sh`, update tracker rows, then
   wave B. Decide subagent type/skill per the workspace's agent profiles
   (`.claude/agents/`) and the Workflow tool if the user wants orchestration.
6. At each boundary: tracker "Now" line + row, `record --label "<wave>"`.
   At WARN: `session-rollover`, staging nothing (no supervisor): write the
   files, commit, and tell the user to start the next session by hand.
