> **This file is the LAUNCHER (catch-up prompt).** Forward-only, and REPLACED
> at each rollover: it holds what to do next, still-binding constraints, and
> pointers — never session history. Past-tense provenance lives in `handoff.md`
> (the append-only ledger). Convention: docs/work-directory-conventions.md.

## Mission

**No active mission.** The skill-hardening batch (8 approved improvements from
the mattpocock/skills comparison, incl. vendoring `writing-for-agents`) is
fully executed and pushed to `main`. This work item is idle until new template
maintenance arrives (upstream sync, review findings, or a new improvement
batch).

## Read these, in order

1. `work/template-maintenance/handoff.md` (top block) — what the last session
   shipped.
2. `docs/template-workspace-backlog.html` — open findings, if picking up new
   maintenance work.

## Do NOT reload

- `skill-hardening-plan.md` — fully executed; kept as provenance only.
- The skill-comparison subagent reports — superseded and shipped.
- `handoff-archive.md` — older session history.

## State snapshot

- Branch `main`, clean and pushed after the skill-hardening commits.
- Vendored skill pins: `wayfinder` and `writing-for-agents` both at upstream
  `8b36d4f` (clone: `~/Developer/references/mattpocock-skills`).

## First actions

1. `scripts/context-budget.sh register`
2. Ask the user (or check the backlog) for the next maintenance objective.
