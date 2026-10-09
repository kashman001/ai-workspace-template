# Catchup prompt — template-maintenance (paste into a new agent session)

> **This file is the LAUNCHER.** Forward-only, REPLACED at each rollover.
> Provenance lives in `handoff.md`. Convention: docs/work-directory-conventions.md.

## >>> START HERE <<<

Nothing to build. The top ledger block is session 20, which fixed the DeepSeek
Harness cards M46, M47 and L66–L69. One backlog card is still open: **L70**
(code-review should group findings into blockers and suggestions). It waits on
upstream issue mattpocock/skills#1242. The local `skills/code-review/` stays
pristine.

`main` is ahead of `origin` and unpushed. Push is the maintainer's call. CI
has not yet run the M47 rule (under `CI`, a skip fails the run).

## First actions

1. `scripts/context-budget.sh register --project template-maintenance`.
2. If the maintainer has pushed since session 20, check the `checks` run:
   `gh run list --limit 1 --workflow checks.yml`. A failure that names
   "skipped in CI" means a check exits 77 on the runner. Either fix the
   check, or mark it `# run-checks: may-skip-in-ci` if a runner can never
   have what it needs.
3. Check #1242 (`gh issue view 1242 -R mattpocock/skills`). If upstream
   merged it, refresh with `scripts/sync-vendored-skills.sh` and resolve L70.
   If upstream declined, close L70 as Won't fix with a `decisions.md` note.
4. Otherwise, ask the user what to work on next.
