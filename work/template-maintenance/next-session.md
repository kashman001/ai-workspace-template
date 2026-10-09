# Catchup prompt — template-maintenance (paste into a new agent session)

> **This file is the LAUNCHER.** Forward-only, REPLACED at each rollover.
> Provenance lives in `handoff.md`. Convention: docs/work-directory-conventions.md.

## >>> START HERE <<<

Standing — take direction from the user. No open backlog cards;
`TEMPLATE_VERSION` is `2026-10-08`.

1. `scripts/context-budget.sh register --project template-maintenance`, then
   `git log --oneline -3`, `git status --short`, and
   `git rev-list --count origin/main..main`.
2. The user pushes `main` and checks the first CI run
   (`.github/workflows/checks.yml`). If CI fails, fix it without changing
   the `TEMPLATE_VERSION` date; one commit per fix with a `Decision:`
   trailer.
3. Otherwise ask the user what to work on next.

## Constraints

- Bump `TEMPLATE_VERSION` on each push of template-facing changes;
  `work/`-only changes need none. No changelog file.
- Don't push main. Report how far ahead of origin it is.
