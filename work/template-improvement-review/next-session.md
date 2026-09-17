# Next Session — template-improvement-review (Stage 4: wave A via a fleet; one wave per session)

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
Only A and C have parallelism; the rest is a chain. **One wave per session**
(user, 2026-09-17): finish the wave, roll over through the live supervisor,
and the successor starts the next wave. Each wave merges to the integration
branch **`stage4`** (never `main`) on green; `main` keeps the old scripts
until cutover, so the supervisor and the parent's hooks keep running on
unchanged code. Agents' worktrees branch off `stage4`. Read-only prep for a later wave
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
- **Supervisor pid 72900 is live and runs this chain** (old `session-loop.sh`
  on `main`, which stays frozen until cutover). Chain budget: session 10 was
  6 of 10; the cap will hit around wave D — restart with
  `scripts/session-loop.sh template-improvement-review --reset-cap` when it
  does. Old counter `.session-seq` = 11 after this launch.
- Root `ROLLOVER_RELAUNCH=manual`; this item's `context-budget.env` says
  `auto` (for after cutover). Until cutover every session here is started
  by hand.

## First actions

1. `scripts/context-budget.sh register --project template-improvement-review`
2. Confirm `ps -p 72900` shows the supervisor and `git branch --list stage4`
   is empty; create `stage4` from `main`. Never edit a script on `main`.
3. Tracker: phase 0 → `done`, fill Done + Commit (131142a); Notes: "chain
   kept — main frozen, waves on stage4". `record --label "phase 0 done"`.
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
   Merge to `stage4` on green, run all `scripts/tests/*.sh` on `stage4`,
   update tracker rows. Then roll over (step 6) — wave B is the next session. Decide subagent type/skill per the workspace's agent profiles
   (`.claude/agents/`) and the Workflow tool if the user wants orchestration.
6. At each boundary: tracker "Now" line + row, `record --label "<wave>"`.
   End of wave, or WARN: `session-rollover` through the live supervisor
   (`launch-next-session.sh … --emit --loop-mode interactive`), launcher
   naming the next wave. Interactive, so the user can okay each fleet launch.
