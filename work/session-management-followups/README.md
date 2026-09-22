# Session Management Follow-ups — close the engineering threads left open after the Stage 4 cutover

Governing skill(s): none formal — each ticket runs `tdd`; sessions end via
`session-rollover` (continue) or `checkpoint` (stop).

**Start here:** `next-session.md` (catch-up launcher) → `handoff.md`
(session ledger, top block).

## What this is

`template-improvement-review` (sessions 1–23, closed 2026-09-22) rebuilt the
session-management subsystem on one record per work item and cut it over to
main. Three engineering threads were recorded as outside that item's scope.
This item works them, one ticket at a time, under a hands-off session loop.
Every change lands with its backlog update (`docs/template-workspace-backlog.html`,
per its "Maintaining this backlog" section) and a Decision note where an
alternative was rejected.

The open work was sorted into four categories; only the first is in scope:

1. **Engineering follow-through (this item):** two scripts still read the
   retired `.active-session` file; two ledger-heading parsers disagree; no
   template version marker exists for downstream upgrades. Tickets 01–03.
2. **Scaffolded lanes needing the human's design input:** `feedback-intake`
   and `quality-gates` (session 1 never happened). Not mechanical; the human
   starts them when ready.
3. **Human-only items:** the Kimi K3 runtime choice, the other machine's
   reset and git email fix, the pre-filter backup bundle, the five locked
   worktrees, the learn-agentic-workflows course, the Gemini key and Copilot
   CLI install. Listed in `work/template-improvement-review/review.md` §E.
4. **Parked by design:** `review.md` §F. No action.

## Success criteria

- Ticket 01: `scripts/attach-session.sh` and
  `scripts/statusline-context-budget.sh` read ownership and liveness from
  `work/<p>/session-state.json` through `scripts/lib/session-lib.sh`; no
  script outside `import-session-seq.sh` (which deletes it) names
  `.active-session`; their suites assert the new behaviour.
- Ticket 02: one ledger-heading rule; `scripts/check-ledger.py` and the
  launcher's `top_ledger_session` accept and reject the same headings, proven
  by a test that runs both over the same fixtures.
- Ticket 03: a workspace-level template version marker exists, is documented
  in `docs/template-usage.md`, is checked by a test, and the assumption behind
  its shape is a Decision note in `decisions.md`.
- Every ticket's backlog card is resolved and archived; all suites under
  `scripts/tests/` plus `python3 scripts/tests/test-check-ledger.py` and
  `scripts/check-workspace-structure.sh` are green on main.
- `work/README.md` row for this item reads Complete.

## Files

- `next-session.md` — forward launcher (what to do next). REPLACED each rollover.
- `handoff.md` — session ledger (what happened). APPEND newest-on-top; archive
  to `handoff-archive.md` when it exceeds the two most recent sessions.
- `issues/NN-<slug>.md` — one tracer-bullet ticket per thread, worked in order.
- `decisions.md` — Tier-2 decision notes (assumptions made in the human's absence).
- `context-budget.env` — `ROLLOVER_RELAUNCH=auto` so `session-loop.sh` may run this item.
