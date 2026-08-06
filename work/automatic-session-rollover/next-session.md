# Catchup prompt — Automatic Session Rollover (paste into a new agent session)

> **This file is the LAUNCHER (catch-up prompt).** Forward-only, REPLACED at
> each rollover. Past-tense provenance lives in `handoff.md` (append-only
> ledger, newest block on top). Convention: docs/work-directory-conventions.md.

## Mission

The vendor-hook-deployments plan is COMPLETE (all 9 tasks, final review,
pushed). A new research phase just concluded: **parent-managed subagent
rollover** — the full design note is
`work/automatic-session-rollover/subagent-rollover-research.md` (committed,
`4fa0cdb`). Nothing from it is implemented yet. The next session's job is
whatever the user directs — most likely: discuss/refine the research doc, or
start turning its §14 "Suggested next steps" into implementation slices
(wayfinder decision tickets or an SDD plan).

## First actions

1. `git pull --ff-only` if the checkout lags origin/main.
2. `scripts/context-budget.sh register --project automatic-session-rollover`.
3. Read `subagent-rollover-research.md` — TL;DR + §14 first; demand-load the
   rest per section as the discussion needs it (it's long by design: it
   carries state machines, invariants, scenario suite, cost model for
   evaluation).

## Constraints already decided (do not re-litigate)

- Vendor-agnostic layering is mandatory (user directive + project memory):
  neutral contract, per-runtime adapters, graceful degradation where a
  runtime exposes no child handles.
- Child rollover verb = successor dispatch, never resume (evidence: the
  141.8K resumed implementer; resume retains full history).
- Parent must not roll over with live children (drain mode) — successors
  cannot adopt a predecessor's children; enforce via lock release-order.
- Standing push-to-main approval applies.

## Do NOT reload

- `handoff-archive.md` and handoff blocks before session 11b — superseded.
- The vendor-hook-deployments plan + SDD artifacts — plan done, workspace
  deleted; git history is the record.
- The three research-agent transcripts/scratchpad — their findings are fully
  captured in the three committed files (`subagent-rollover-research.md`,
  `-stats.md`, `subagent-vendor-survey.md`).
- Backlog card **L17** — known follow-up minors from the code plan; separate
  from this research thread.

## State snapshot (at session-11b rollover, 2026-08-06)

- Branch `main` pushed through `4fa0cdb`; this rollover's commit will follow.
- Uncommitted at rollover: only `work/context-decay/context-ledger.jsonl`
  (goes into the rollover commit) + the live `.active-session` lock
  (untracked by design).
- No running background agents (all three research agents completed and were
  harvested). No worktrees. Suites untouched this phase.
- No `.rollover-options` file — session didn't know its own launch flags
  (skill: leave absent); successor launches with runtime defaults.

## At session end

Release the lock: `scripts/context-budget.sh release --project automatic-session-rollover`.
