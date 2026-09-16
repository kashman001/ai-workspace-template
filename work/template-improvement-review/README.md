# Template Improvement Review — fresh-eyes review of the workspace template + pooled improvement program

Governing skill(s): none formal — draws on `checkpoint`, `session-rollover`,
`decision-log`, and the backlog maintenance convention in
`docs/template-workspace-backlog.html`.

**Start here:** `next-session.md` (catch-up launcher) → `handoff.md`
(session ledger, top block).

## What this is

A review-and-improve effort over the template itself. It pools the open
threads scattered across the other `work/` items (the 5 open backlog cards
and their options brief under `template-maintenance`, the scaffolded-but-idle
`feedback-intake` and `quality-gates` lanes, dormant items with deferred
notes) into one prioritized list in `review.md`, then works that list:
fresh-eyes findings are fixed directly, design-gap conventions are built
under stated assumptions, and every change lands with its backlog update.

Distinct from `template-maintenance` (the standing upkeep umbrella): this
item is a bounded review program with an explicit end state.

## Success criteria

- `review.md` exists: a deduplicated, prioritized list of every open thread
  across `work/*`, the backlog, and a fresh-eyes pass, each with source and
  disposition (fix now / build / route / drop-with-reason).
- Every "fix now" item is delivered on main with its backlog update
  (resolved card or new card), and all test suites plus
  `scripts/check-workspace-structure.sh` stay green.
- Every "build" item ships with a `Decision:` note in `decisions.md`
  recording the assumption made in the user's absence, so the user can
  reverse it cheaply.
- `work/README.md` lists every work directory with a current status row.

## Files

- `next-session.md` — forward launcher (what to do next). REPLACED each rollover.
- `handoff.md` — session ledger (what happened). APPEND newest-on-top; archive
  to `handoff-archive.md` when it exceeds the two most recent sessions.
- `review.md` — the pooled, prioritized review list (the working deliverable).
- `decisions.md` — Tier-2 decision notes (assumptions made autonomously).
- `stage4-tracker.md` — Stage 4 progress: "Now" line + one row per phase (what is the plan / where are we / what remains). Plan itself: `session-management-review-findings.md` Part 4.
- `plans/phase-<n>.md` — task-level plan for one implementation phase, written when that phase starts.
