# Catchup prompt — template-maintenance (paste into a new agent session)

> **This file is the LAUNCHER.** Forward-only, REPLACED at each rollover.
> Provenance lives in `handoff.md`. Convention: docs/work-directory-conventions.md.

## >>> START HERE <<<

**Mission.** No queued jobs. The backlog has one open card, **L74**
(`scripts/tests/test-session-lib.sh` S8 fails intermittently). Ask the user
whether to take it, or what's next.

**Waiting on the user:**
- Run `scripts/migrate-glossary.sh` on `~/Developer/experiments/NeogeoEmu`?
  It will refuse until that repo has a first commit (it has none). Never run it
  on a real project without the user's go-ahead.
- Delete `skills/code-review/workspace.patch` once mattpocock/skills#1242 lands
  (the sync now says so when the issue closes).

**State:** `main` pushed at the end of session 23. On a push after 2026-10-09,
bump `TEMPLATE_VERSION` to that day.

**Do NOT reload:** L72/M49/L73 are done (ledger block 23).

## First actions

1. `scripts/context-budget.sh register --project template-maintenance`.
2. Ask the user what to take next (L74 is the only open card).
