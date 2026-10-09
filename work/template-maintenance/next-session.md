# Catchup prompt — template-maintenance (paste into a new agent session)

> **This file is the LAUNCHER.** Forward-only, REPLACED at each rollover.
> Provenance lives in `handoff.md`. Convention: docs/work-directory-conventions.md.

## >>> START HERE <<<

Nothing to build. The top ledger block is session 20, which fixed the DeepSeek
Harness cards M46, M47 and L66–L69. One backlog card is still open: **L70**
(code-review should group findings into blockers and suggestions). It waits on
upstream issue mattpocock/skills#1242. The local `skills/code-review/` stays
pristine.

Pushed after session 20. `checks` run 37987347172 passed 40/0/0, the first
run with the M47 rule (under `CI`, a skip fails the run).

## First actions

1. `scripts/context-budget.sh register --project template-maintenance`.
2. Check #1242 (`gh issue view 1242 -R mattpocock/skills`). If upstream
   merged it, refresh with `scripts/sync-vendored-skills.sh` and resolve L70.
   If upstream declined, close L70 as Won't fix with a `decisions.md` note.
3. Otherwise, ask the user what to work on next.
