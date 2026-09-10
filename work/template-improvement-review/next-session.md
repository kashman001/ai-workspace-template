# Next Session — template-improvement-review (session 3)

> **This file is the LAUNCHER (catch-up prompt).** Forward-only, REPLACED at
> each rollover. Past-tense provenance lives in `handoff.md`.
> Convention: docs/work-directory-conventions.md.

## Mission

The review list is drained (session 2, commit `39224b8`). This item is
**complete pending merge**; there is no unattended agent work left. With the
user present:

1. Merge `review/template-improvement-review-s1` into main (2 commits:
   `dc1f334`, `39224b8`); run the suites once more on main after the merge.
2. Walk `review.md` §E (user-only items) and take direction on each.
3. Ask whether the five build-under-assumption choices (`decisions.md`)
   stand — each is a cheap doc/skill reversal.
4. Decide L45's fix direction (repo-guard exemption for gitignored `work/`
   dirs vs. copy-back in `rollover-prep.sh`); then file it under
   `template-maintenance`, not here.

Unattended: verify state and stop — nothing to build.

## Read these, in order

1. `work/template-improvement-review/review.md` — §E only.
2. `work/template-improvement-review/handoff.md` — top block only.
3. `work/template-improvement-review/decisions.md`.

## Do NOT reload

- Other work items' launchers/ledgers; the options brief; `work/context-decay/*`.
- The backlog HTML files whole — grep an ID if needed.

## State snapshot

- Branch `review/template-improvement-review-s1`, clean tree, 2 ahead of
  main; main == origin/main.
- Suites 21/21 green; structure + ledger checks clean. Backlog 1 open (L45) /
  85 resolved.

## First actions

1. `scripts/context-budget.sh register --project template-improvement-review`
2. `git status --short && git log --oneline main..HEAD` — expect a clean tree and the two commits above.
3. Continue per Mission.
