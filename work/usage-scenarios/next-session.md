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
   trusting this launcher (L33 race). If in a fresh worktree, also
   `git merge --ff-only main` — worktrees branch from origin/main, which
   may lag local main.
2. **Deliver session-5 first if still pending**: branch
   `worktree-usage-scenarios-s5` (Gaps 3+8, commits through the session-5
   bookkeeping) is pushed to origin but NOT merged to main (background
   session; merge reserved for the user). If `git branch --contains
   <s5 tip> main` is empty: merge it to main (user or interactive session),
   push, delete the worktree + branches. Then start the mission.

## Mission (session 6): Gap 7 — zoom docs + execute the HTML retirement

Last M15 gap (sequencing + verdicts in decisions.md, 2026-08-08). Scope:

- Promote the catalog's §1/§1b/§1c (zoom-level model Z0–Z3 × O0–O4, zoom
  discipline, delegate-vs-zoom-in-place rule) from
  `work/usage-scenarios/scenarios.md` into a committed doc —
  `docs/zoom-model.md` or a workspace-structure.md section (pick one,
  note the choice).
- Retire `docs/usage-scenarios.html` to the archive with a pointer — the
  markdown E-catalog (scenarios.md §3) supersedes it. NO generated-view
  machinery. Fix the three stale `work/<user>_` references in whatever
  survives.
- The supersede decision may deserve ADR promotion (decisions.md note says
  "promote when Gap 7 executes, if contentious") — judge then.
- Close-out: when Gap 7 lands, M15 closes — update the card (Open→Fixed,
  scorecard) + change-log row per the backlog's maintenance section, and
  decide the work item's own fate (checkpoint/close).

## Read these, in order

1. `work/usage-scenarios/scenarios.md` §1/§1b/§1c ONLY (the promotion
   source) and §3 header (E-catalog role).
2. `work/usage-scenarios/decisions.md` — the usage-scenarios.html verdict
   note (blast radius lists the touchpoints).
3. `grep -rn "usage-scenarios.html" docs/ CONTEXT.md` — every pointer that
   must move to the survivor.

## Do NOT reload

- `ground-truth.md`, `gaps-and-coverage.md` — open only to verify a
  specific fact.
- The backlog HTMLs whole — grep the M15 card / change-log anchor only.

## Constraints already decided (do not re-litigate)

- Simplicity guardrails (user, 2026-08-08) binding: retire with a pointer,
  no generated-view machinery.
- Gaps 4 and 1 stay deferred until a second service/person is real.
- Nine test suites must stay green; test-template-instantiation.sh clones
  COMMITTED state — commit before running it.

## State snapshot

- Branch: `worktree-usage-scenarios-s5` pushed to origin; merge to main
  pending (see First actions #2). Session-4 work already on origin/main.
- Backlog: M15/M16/L32/L33 Open (4). Nine suites, 363 asserts, all green.
- No running processes, no open subagents.
