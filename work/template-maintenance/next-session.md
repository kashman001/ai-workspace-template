# Next Session — template-maintenance (session 16)

## Mission

Blocked on user input. Session 15 wrote
`work/template-maintenance/open-cards-options-brief.md` — an options brief
for the 5 remaining open cards (M27 testability prompt, M28 UAT/beta,
M29 postmortem, L38 dep/suite health, L39 generic backlog), each with a
proposed shape and open questions. Nothing should be built until the user
answers those questions. With a user present: walk the brief card by card,
take direction, then implement per their picks. Unattended: there is
nothing further to prepare — do NOT design conventions solo and do NOT
regenerate the brief; verify state and stop.

## Read these, in order

1. `work/template-maintenance/open-cards-options-brief.md` — the deliverable
   to walk through with the user.
2. `work/template-maintenance/handoff.md` — top block only (session-15 close).

## Do NOT reload

- The 5 card bodies in the backlog — the brief summarizes them; grep the
  backlog only if the user challenges a detail.
- M16/M35 delivery details, `handoff-archive.md`, exit-ux-plan.md — historical.

## State snapshot

- Session-15 work on worktree branch `worktree-tm-s15-options-brief`
  (brief + this rollover); the launch ff-pushes it to main (launcher
  self-heal). Verify with `git log --oneline -2` post-launch.
- No code/test changes in session 15 — suites still 21 green as of s14
  (registry 122/0, launcher 221/0, loop 76/0). Backlog: 5 open / 77 resolved
  (unchanged; brief resolves nothing by itself).

## First actions

1. `scripts/context-budget.sh register --project template-maintenance`
2. `git fetch origin && git log HEAD..origin/main --oneline` — empty
   before trusting this launcher (staleness guard).
3. Continue per Mission.
