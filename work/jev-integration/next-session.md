# Catchup prompt — jev-integration (paste into a new agent session)

We're resuming `jev-integration`. Works in any runtime (Claude Code, Codex,
Gemini, OpenCode) — all read `CONTEXT.md` via their entrypoint.

> **This file is the LAUNCHER (catch-up prompt).** Forward-only, and REPLACED
> at each rollover: it holds what to do next, still-binding constraints, and
> pointers — never session history. Past-tense provenance lives in
> `handoff.md` (the append-only ledger). Convention:
> docs/work-directory-conventions.md.

## Mission

Research wave 1 on Jev is complete (`research/synthesis.md`). Close the wave's
paperwork, then pose the fit decision to the human and record it in
`decisions.md` via `grill-with-docs`. No integration code or spec until
`decisions.md` records the fit.

## >>> START HERE <<<

Position: **Phase 4 closed; all corrections applied; `research/synthesis.md`
is final except a §1 re-check.** Small close steps remain, then the human.

1. `scripts/context-budget.sh register --project jev-integration` (expect `seq=5`).
2. `scripts/fleet.sh dispatch-list --project jev-integration` — all closed; none should be `open`.
3. **§1 re-check** of `research/synthesis.md` against the gen-3 changes only
   (grep, don't read whole records): C50 in `what-jev-is/record.md` (denominator
   caveat + cookbook per figure), IP S2 wording ("contradicted for Noul"),
   S4 price-FAQ answer (`terms` 1.7 now quoted in `what-jev-is` S4), profile
   "early access" (stale `<meta>`). Fix any §1 sentence they contradict.
4. Close: add a status line to `README.md` here after "Start here" (research
   wave 1 complete 2026-09-23; fit decision pending; synthesis at
   `research/synthesis.md`); update `work/README.md` row L23 to the same;
   `scripts/context-budget.sh record --label "wave close"`; commit (do not
   push; report how far ahead main is).
5. **Pose the fit decision** — this is human-only. Roll over with
   `--loop-mode interactive` carrying the question verbatim:

   > **Fit decision** in `decisions.md`: which template seam(s) a typed-decision
   > model serves better than the current runtime (or none), with the rejected
   > alternatives and the evidence from `research/`.

   Inputs for the human: `research/synthesis.md` §5 (provisional seam table)
   and §6; `research/seam-inventory.md`. Run `grill-with-docs` with the human;
   the outcome is a Tier-2 note in `decisions.md` (`/decision`).
6. `scripts/context-budget.sh record --label "<step done>"` at each boundary.

## Do NOT reload

- Any corrections debate (three rounds, all settled; `rulings.md` through R41).
- The sweep (`sweep.md`) beyond what §3 of the synthesis already summarises.
- The seam inventory's session-lifecycle seams (deterministic by ADR-0011).
- Whether to add a fourth subject (R0.1: no).

## Constraints already decided (do not re-litigate)

- Template rules apply to anything that ships: agent-agnostic, CLI-first or
  `mcp-fragments/`, credentials in the keychain, documented as a first-class
  template addition.
- Research before design: no integration code or spec until a fit decision
  is recorded in `decisions.md`.
- Raw `pass/*.md`, `fact-check.md`, and every brief are provenance — never edited.
- The orchestrator rules; agents recommend.

## State snapshot

- Branch `main`, committed at session 4's close; not pushed. Under
  `work/jev-integration/research/`: `schema.md` (with the verification scale),
  `rulings.md` (through R41, "Phase 4 closed"), `sweep.md`, `seam-inventory.md`,
  `synthesis.md`, and per subject the pass/fact-check/corrections sets (three
  rounds). No `decisions.md` yet. All dispatch records closed.
- `context-budget.env` here sets `ROLLOVER_RELAUNCH=auto`; a supervisor
  (`session-loop.sh`) runs the chain — stage with `--emit`.

## Read these first, in order

1. `work/jev-integration/handoff.md` (top block)
2. `research/synthesis.md` §5–§6
3. `skills/session-rollover/SKILL.md` step 6 (interactive rollover)
