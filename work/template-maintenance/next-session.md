> **This file is the LAUNCHER (catch-up prompt).** Forward-only, and REPLACED
> at each rollover: it holds what to do next, still-binding constraints, and
> pointers — never session history. Past-tense provenance lives in `handoff.md`
> (the append-only ledger). Convention: docs/work-directory-conventions.md.

## Mission

**No queued mission.** The previously queued `launch-next-session.sh` effort
was spun out into its own focused project on 2026-08-05 at the user's request —
resume it via `work/automatic-session-rollover/next-session.md`, not here.

Template-maintenance remains the umbrella for general template upkeep: pick up
new work from `docs/template-workspace-backlog.html` or user direction.

## Read these, in order

1. `work/template-maintenance/handoff.md` (top block) — what last shipped.

## State snapshot

- Branch `main`, clean and pushed after the skill-hardening commits.
- Vendored skill pins: `wayfinder` and `writing-for-agents` both at upstream
  `8b36d4f` (clone: `~/Developer/references/mattpocock-skills`).

## First actions

1. `scripts/context-budget.sh register`
2. Ask the user (or check the backlog) for the next template-maintenance task.
