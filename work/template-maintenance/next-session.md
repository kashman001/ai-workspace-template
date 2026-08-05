> **This file is the LAUNCHER (catch-up prompt).** Forward-only, and REPLACED
> at each rollover: it holds what to do next, still-binding constraints, and
> pointers — never session history. Past-tense provenance lives in `handoff.md`
> (the append-only ledger). Convention: docs/work-directory-conventions.md.

## Mission

**No active mission.** The upstream skill sync (clone `8b36d4f`) is executed
and pushed (`823f8c2`); see the top block of `handoff.md` for what shipped.

## Candidate next focus (pick with the user)

- **Wayfinder smoke test** — deferred from before the sync, now unblocked:
  exercise `/wayfinder` end-to-end on a small real effort (map + a couple of
  decision tickets under `work/<effort>/`) to validate the vendored skill +
  `docs/agents/issue-tracker.md` wiring.
- Next upstream sync: only when `mattpocock/skills` releases new skills out
  of `in-progress/` (still-binding: released buckets only; `claude-handoff`
  stays anti-recommended vs `session-rollover`/`handoff`).

## First actions

1. `scripts/context-budget.sh register`
2. Confirm a focus with the user before starting multi-session work.
