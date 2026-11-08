# Catchup prompt — template-maintenance (paste into a new agent session)

> **This file is the LAUNCHER.** Forward-only, REPLACED at each rollover.
> Provenance lives in `handoff.md`. Convention: docs/work-directory-conventions.md.

## >>> START HERE <<<

**Mission.** None queued. Session 27 refreshed the vendored skills from all
four upstreams and added three pstack skills (`83adec7`, `a95b1fe`). Ask the
user what's next. Open backlog cards: L85, L86.

**No human in the loop:** do not pick new work; run `checkpoint` and stop
with the question open.

## Read these, in order

1. `work/template-maintenance/handoff.md` — block 27 only.

## Do NOT reload

- The skill refresh and the eight-skill evaluation: done and recorded in
  `skill-packs-analysis.md` → "Refresh evaluation (2026-11-07)".
- `skills/code-review/workspace.patch` "may have landed" sync note:
  #1242 was declined upstream; keep the patch.

## State snapshot

- Branch `main`, clean, 2+ commits ahead of origin, not pushed (push is the user's call).

## First actions

1. `scripts/context-budget.sh register --project template-maintenance`
2. Ask the user what's next (L85, L86, or new work).
