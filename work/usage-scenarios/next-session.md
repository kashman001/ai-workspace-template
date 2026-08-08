# Catchup prompt — usage-scenarios (paste into a new agent session)

We're resuming usage-scenarios. Works in any runtime (Claude Code, Codex,
Gemini, OpenCode) — all read `CONTEXT.md` via their entrypoint.

> **This file is the LAUNCHER (catch-up prompt).** Forward-only, and REPLACED
> at each rollover: it holds what to do next, still-binding constraints, and
> pointers — never session history. Past-tense provenance lives in
> `handoff.md` (the append-only ledger). Convention:
> docs/work-directory-conventions.md.

## First actions

1. `git fetch origin` + confirm `git log HEAD..origin/main` is empty before
   trusting this launcher (L33 race).
2. **Deliver session-5 if still pending**: branch
   `worktree-usage-scenarios-s5` (Gaps 3+8+7+4+1, M15 close, docs index,
   review fixes) is pushed to origin but NOT merged to main (background
   session; merge reserved for the user). If main doesn't contain its tip:
   merge, push, delete worktree + branches.

## Mission: close out the work item

The catalog's mission is COMPLETE — all 8 gaps resolved or deliberately
deferred (ledger top block has the full account). Remaining is wrap-up:

- Run the `checkpoint` skill for the work item: confirm backlog/docs/memory
  reconciled (M15 already archived), then decide the work directory's fate —
  it stays as the scenario catalog's home (docs point into
  `work/usage-scenarios/scenarios.md` §3, so the directory is NOT deletable;
  mark its README as maintenance-mode).
- Deferred-by-design residuals (do NOT build now; revisit when real):
  - Gap 4 vault tooling — when a second (shared) service exists.
  - Gap 1 phases 2–3 (shared liveness ADR, collision-proof numbering,
    team-workspace doc) — when a second person is real. Breakage points:
    workspace-structure.md → "Before You Add a Teammate".
- Open backlog cards M16, L32, L33 are separate efforts, not this item's.

## Constraints already decided (do not re-litigate)

- Simplicity guardrails (user, 2026-08-08) binding; prefer documenting
  over building.
- Nine test suites must stay green; test-template-instantiation.sh clones
  COMMITTED state — commit before running it.
- The E-catalog (scenarios.md §3) is the canonical external-scenario doc;
  the HTML is retired in docs/archive/ — never resurrect it.

## State snapshot

- Branch `worktree-usage-scenarios-s5` pushed; merge to main pending.
- Backlog: M16/L32/L33 Open (3); scorecard 3/50/4/0/6.
- Nine suites, 363 asserts, all green. No running processes.
