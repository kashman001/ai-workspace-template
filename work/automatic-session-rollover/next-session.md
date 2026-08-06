# Catchup prompt — Automatic Session Rollover (paste into a new agent session)

> **This file is the LAUNCHER (catch-up prompt).** Forward-only, REPLACED at
> each rollover. Past-tense provenance lives in `handoff.md` (append-only
> ledger, newest block on top). Convention: docs/work-directory-conventions.md.

## Mission

The subagent-rollover research doc now has an HTML review rendition
(`subagent-rollover-research.html`, structure: problem → model → machinery →
findings → proposal → evaluation). The user's next directive (given mid-turn,
NOT started): **enumerate rollover scenarios** — mainline functional flows
plus corner/edge cases across resilience, recoverability, and performance —
so the team can (a) keep them in mind while working through the doc and
(b) use them as the evaluation harness, *before* implementing anything. The
user also asked: "is there a dimension I missed?" — answer that first.

## Read these, in order

1. `subagent-rollover-research.md` — §13 only (S1–S10 scenarios, I1–I8
   invariants, P1–P5 fault properties, cost model): the seed the new catalog
   must extend, not duplicate. Demand-load other sections per §-pointer as
   needed; the HTML mirrors the same content restructured.
2. `handoff.md` top block — the session-12 record, including candidate
   missing dimensions already sketched (concurrency/contention incl. human
   attach during drain, observability/auditability, cost/token-economy,
   record schema evolution, opaque-runtime degradation, human-in-the-loop
   policy edges).

## First actions

1. `scripts/context-budget.sh register --project automatic-session-rollover`
   (also `git pull --ff-only` if the checkout lags origin/main).
2. Answer the user's open question (missed dimensions), agree the dimension
   set, then build the scenario catalog — likely as a new section of the HTML
   doc (keep the md note in sync or record where the catalog is
   authoritative). Mainline + edge/corner cases per dimension, each phrased
   with pass criteria so it can become an acceptance/fault-injection test.

## Do NOT reload

- `handoff-archive.md` and blocks before session 12 — superseded.
- The vendor-hook-deployments plan + SDD artifacts — done; git history is
  the record.
- The research-agent transcripts/scratchpad — findings fully captured in the
  three committed research files.
- Backlog card **L17** — separate follow-up thread.
- The full HTML file — only open the section being edited; it duplicates the
  md content you already have pointers into.

## Constraints already decided (do not re-litigate)

- Vendor-agnostic layering is mandatory (neutral contract, per-runtime
  adapters, graceful degradation without child handles).
- Child rollover verb = successor dispatch, never resume.
- Parent must not roll over with live children (drain mode; release-order
  enforcement in the lock system).
- Scenarios-before-implementation ordering is the user's explicit direction.
- Standing push-to-main approval applies.

## State snapshot (at session-12 rollover, 2026-08-06)

- Branch `main` pushed through `d93daea` (HTML doc); this rollover's commit
  follows. Uncommitted at rollover: ledger + handoff/decisions/ops-knowledge
  appends (go into the rollover commit); `.active-session` lock untracked by
  design.
- No running background agents or servers (the localhost:8749 preview server
  was killed). No worktrees.
- No `.rollover-options` file — launch flags unknown again (skill: leave
  absent); successor launches with runtime defaults.

## At session end

Release the lock: `scripts/context-budget.sh release --project automatic-session-rollover`.
