# Next Session — template-maintenance (session 14)

## Mission

No active mission — the exit-UX arc (M35) closed in session 13. This work
item is standing maintenance: pick the next item from the open backlog
cards in `docs/template-workspace-backlog.html` (6 open), or take direction
from the user.

## Read these, in order

1. `work/template-maintenance/handoff.md` — top block only (session-13
   close: what shipped, suite counts).
2. `docs/template-workspace-backlog.html` — open cards, if choosing work.

## Do NOT reload

- `work/template-maintenance/exit-ux-plan.md` — delivered; historical.
- The archive backlog file, handoff-archive.md, or any prior-session plans.

## State snapshot

- main carries the M35 delivery (worktree tm-s13-exitux, fast-forwarded).
- Suites green at close: launcher 221/0, session-loop 76/0, structure
  check clean. Backlog: 6 open / 76 resolved.

## First actions

1. `scripts/context-budget.sh register --project template-maintenance`
2. Confirm main is current (`git pull --ff-only`) and suites still green
   before starting anything new.
