# Catchup prompt — usage-scenarios (paste into a new agent session)

We're resuming usage-scenarios. Works in any runtime (Claude Code, Codex,
Gemini, OpenCode) — all read `CONTEXT.md` via their entrypoint.

> **This file is the LAUNCHER (catch-up prompt).** Forward-only, and REPLACED
> at each rollover: it holds what to do next, still-binding constraints, and
> pointers — never session history. Past-tense provenance lives in
> `handoff.md` (the append-only ledger). Convention:
> docs/work-directory-conventions.md.

## Mission

Build the usage-scenario catalog as an evaluation lens for the template:
external scenarios (done, §3) + critical internal scenarios (§4, NEXT) +
scenario→docs→tests coverage matrix (§5), then a gap analysis with concrete
recommendations (`gaps-and-coverage.md`). The catalog also drives future
usage/internal/architecture docs. User is away; work autonomously; rollover
is hands-free (auto).

## Read these, in order

1. `work/usage-scenarios/brief.md` — requirements + evaluation directives.
2. `work/usage-scenarios/scenarios.md` — §1–3 done; §4/§5 are stubs to fill.
3. `work/usage-scenarios/ground-truth.md` — ALL evidence (four distilled
   audit reports). §D has the internal-mechanism groups A–G and the test
   coverage map — §4 of scenarios.md is written from it.

## Do NOT reload

- The four subagent raw reports — gone; `ground-truth.md` IS the distillate.
- docs/context-budget.md, docs/workspace-structure.md, usage-scenarios.html,
  ADRs — already mined into ground-truth.md; re-read only to verify a
  specific fact you're about to assert.
- Zoom-model design debate — settled in scenarios.md §1/§1b/§1c (two
  orthogonal dimensions + agent profiles). Don't re-derive.
- `ROLLOVER_RELAUNCH=auto` decision — committed, constraint below.

## Constraints already decided (do not re-litigate)

- Rollovers for this work item run hands-free: `ROLLOVER_RELAUNCH=auto` via
  committed `work/usage-scenarios/context-budget.env` (user, 2026-08-08).
- Catalog supersets the existing docs/usage-scenarios.html (option (a),
  session 1); the HTML doc's fate is decided later, in recommendations.

## State snapshot

- Branch: main; work committed at session-1 rollover.
- Tasks: #3 (internal catalog §4) in progress; #4 (gaps-and-coverage.md);
  #5 (close-out: backlog note, final commit) pending.
- No running processes, no open subagents.

## First actions

1. `scripts/context-budget.sh register --project usage-scenarios`
   (SessionStart hook registers the session; this adds the project claim →
   primary role.)
2. Fill `scenarios.md` §4 (internal catalog I1…In) from ground-truth §D:
   one entry per mechanism-scenario group with support status + test status.
3. Fill §5 coverage matrix (scenario ↔ doc home ↔ test/eval coverage).
4. Write `gaps-and-coverage.md`: ranked gaps (multi-user, product
   onboarding/Z0 docs, non-negotiable tooling manifest, shared secrets,
   personal layer unevenness, template-level eval harness, doc-architecture
   zoom restructure) + concrete recommendations, each tagged with which
   E/I scenarios it moves.
5. Update the template backlog (per CONTEXT.md → Template Backlog) with a
   card pointing at the catalog; note the three un-carded Open findings
   (CL-1/2/3) surfaced in ground-truth §A.
6. Close out: ledger block, replace this launcher, commit.
