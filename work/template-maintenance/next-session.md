# Catchup prompt — template-maintenance (paste into a new agent session)

> **This file is the LAUNCHER.** Forward-only, REPLACED at each rollover.
> Provenance lives in `handoff.md`. Convention: docs/work-directory-conventions.md.

## >>> START HERE <<<

**Standing — take direction from the user.** No queued work. Session 17
closed the doc-gap cards L53, L55–L59 (see the top block of `handoff.md`).

Open for the user's decision: **L54** — when to cut a release and bump
`TEMPLATE_VERSION` (`docs/template-usage.md` → "Upgrading later").

1. `scripts/context-budget.sh register --project template-maintenance`, then
   `git log --oneline -3` and `git status --short`.
2. Ask the user what to work on; for backlog work, grep the card ID in
   `docs/template-workspace-backlog.html` (targeted read).

## Constraints

- Don't push main. Report how far ahead of origin it is.
- Another session may work `harness-engineering` on this checkout: commit
  only your own files; re-read the backlog right before each edit.
