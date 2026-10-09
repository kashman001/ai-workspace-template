# Catchup prompt — template-maintenance (paste into a new agent session)

> **This file is the LAUNCHER.** Forward-only, REPLACED at each rollover.
> Provenance lives in `handoff.md`. Convention: docs/work-directory-conventions.md.

## >>> START HERE <<<

**Mission.** Standing upkeep. Nothing is queued: the template backlog has
**0 open cards**. Session 22 resolved L70, M48 and L71 (ledger block 22).

**State:** `main` is clean and 6 commits ahead of origin. Pushing is the user's call.
`TEMPLATE_VERSION` is already `2026-10-09` on origin, so a push needs no bump
today; on a later day, bump it to that day before pushing.

**Do NOT reload:**
- The patched vendored-skill class (`scripts/sync-vendored-skills.sh`,
  `skills/code-review/workspace.patch`) is done and tested.
- The `isolated: yes` recipe and the closing review wave in
  `skills/plans/SKILL.md` are done.

## First actions

1. `scripts/context-budget.sh register --project template-maintenance`.
2. Ask the user what to take on next. Candidates:
   - push `main`;
   - comment on mattpocock/skills#1242, only if the user asks;
   - promote the GLOSSARY.md decision to an ADR (`decisions.md`, "Promote?: yes");
   - migrate older projects whose glossary still lives in CONTEXT.md (ledger block 21, open question).
3. At the next Matt Pocock refresh, if the code-review patch fails, rewrite it
   against the re-copied file. If upstream has landed #1242, delete the patch.
