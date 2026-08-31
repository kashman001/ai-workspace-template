# Next Session — template-maintenance (session 15)

## Mission

No active mission — M16 closed in session 14. This work item is standing
maintenance. All 5 remaining open backlog cards (M27 testability prompt,
M28 UAT/beta, M29 postmortem, L38 dep/suite health, L39 generic backlog)
are convention/doc *design* gaps, not defects — each needs user input on
shape before building. Unattended: do NOT design conventions solo; instead
prepare a short options brief per card (grep each card, 5–10 lines each:
proposed shape, where it lands, open questions), commit it under
`work/template-maintenance/`, and stop with the questions open for the
user. With a user present: walk the cards, take direction.

## Read these, in order

1. `work/template-maintenance/handoff.md` — top block only (session-14
   close: M16 delivery, suite counts).
2. `docs/template-workspace-backlog.html` — the 5 open cards (grep the
   IDs; never load whole).

## Do NOT reload

- The M16 card/fix details — delivered; `handoff.md` top block has the
  summary, the archive backlog has the card.
- `handoff-archive.md`, prior-session plans, exit-ux-plan.md — historical.

## State snapshot

- Session-14 delivery on worktree branch `worktree-tm-s14-m16`
  (commit 6152b8d + rollover commit); the launch ff-pushes it to main
  (launcher self-heal). Verify with `git log --oneline -2` post-launch.
- Suites at close: all 21 green (registry 122/0, launcher 221/0,
  loop 76/0). Backlog: 5 open / 77 resolved.

## First actions

1. `scripts/context-budget.sh register --project template-maintenance`
2. `git fetch origin && git log HEAD..origin/main --oneline` — empty
   before trusting this launcher (staleness guard).
3. Continue per Mission.
