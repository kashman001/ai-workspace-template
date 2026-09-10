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

- Session-15 branch `worktree-tm-s15-options-brief` is merged into main
  (verified s16, 2026-09-03). Three fixes landed on main after it via PRs
  #41–#43 (M36 check-ledger heading, L44 TF_SESSION_LOOP scrub, M37
  --unstage atomic abandon); each carried its own backlog update.
- Suites re-run on current main in s16: 21/21 green (registry 122/0,
  launcher 249/0, loop 76/0, vendor-hooks 85/0). Backlog: 5 open / 80
  resolved (brief resolves nothing by itself).
- All five `.claude/worktrees/*` branches are merged into main; the
  worktrees are still present and locked — cleanup is a user call.

## First actions

1. `scripts/context-budget.sh register --project template-maintenance`
2. `git fetch origin && git log HEAD..origin/main --oneline` — empty
   before trusting this launcher (staleness guard).
3. Continue per Mission.
