# Catchup prompt — jev-integration (paste into a new agent session)

We're resuming `jev-integration`. Works in any runtime (Claude Code, Codex,
Gemini, OpenCode) — all read `CONTEXT.md` via their entrypoint.

> **This file is the LAUNCHER (catch-up prompt).** Forward-only, and REPLACED
> at each rollover: it holds what to do next, still-binding constraints, and
> pointers — never session history. Past-tense provenance lives in
> `handoff.md` (the append-only ledger). Convention:
> docs/work-directory-conventions.md.

## Mission

Finish research wave 1 on Jev (TypeSafe's typed-decision API) so a human can
make the fit decision: rule on the Phase 4 sweep, apply what it found, finish
the synthesis, and roll over interactive with the fit question open. No
integration code or spec until `decisions.md` records the fit.

## >>> START HERE <<<

Position: **Phase 3 closed. Phase 4 sweep DONE and RULED (R24–R37); nothing applied yet.** The synthesis
is DRAFTED at `research/synthesis-draft.md` with §3 (what the sweep found)
and the sweep-confirmed patterns in §4 unfilled. **Not started: the gen-3
corrections pass, the final synthesis, the close.**

1. `scripts/context-budget.sh register --project jev-integration` (expect `seq=4`).
2. Read `research/rulings.md` from "## Phase 3 closed" down, then
   `research/sweep.md` — its `## Summary` and `## Findings` tables (grep
   for `severity (high` rows first). Do NOT read `record.md`/`fact-check.md`/
   `corrections.md` whole — grep them. Do NOT redo the claim-id grep: the
   ids are already in `synthesis-draft.md`.
3. `scripts/fleet.sh dispatch-list --project jev-integration` — every record incl. `sweep` gen 1 should be closed; an `open` one is partial: `dispatch-close --status KILLED`, reopen, relaunch.
4. **Verify the rulings R24–R37** (`rulings.md` § "Phase 4 — sweep rulings") against each finding's row in `sweep.md`; they were made from the sweep's summary. Amend by appending (never edit a ruling): R38+. R17 is settled by R24 (gen 2's
   reading; R18 active) and R20 by R26. R29 adopts the sweep's `## Scale
   definition` into `schema.md` and re-scores all three subjects in ONE
   coordinated round — never one at a time.
5. **One corrections pass per affected subject** (gen 3 of `corr-<subject>`;
   brief `<subject>/corrections-brief-3.md` modelled on
   `what-jev-is/corrections-brief-2.md`: hard rules by reference, one bullet
   per ruling with the exact target text, report appended as `## Third round
   (gen 3, <date>)`). Carry the sweep rulings PLUS the queued ones: R18 (active
   per R24), R20 (`what-jev-is` C14 + `integration-paths` 5.12 mirror),
   R21 (`terms` 6.6/V10 chunk counts 2→1: `record.md` L97 "fresh grep 2
   each", `verification.md` L23), R22 (served-homepage line "Set the
   thresholds for when it acts autonomously and when it asks for review." →
   `what-jev-is` S3 row L25 note + appendix, `documented`). `dispatch-open`
   each, launch in parallel, verify on disk, `dispatch-close`, rule on any
   round-3 findings.
6. **Finish the synthesis**: fill §3 of `research/synthesis-draft.md` (per-
   sweep finding counts, the R17 outcome, formatting rows fixed, stale counts
   marked, rulings applied), add the sweep's confirmed/new patterns to §4,
   re-check §1 against any claim the corrections changed, then
   `git mv research/synthesis-draft.md research/synthesis.md` and drop the
   DRAFT marker from its title. Keep §6 (the decision question) verbatim.
7. Close: `README.md` here (add a status line: research complete, fit
   decision pending) and the `work/README.md` row (L23); ledger block
   `# Session Handoff — 4 (<date>)` on `handoff.md`; rewrite this launcher for
   the fit-decision session (`grill-with-docs` → `decisions.md` note; carry
   the decision question verbatim in First actions); commit (do not push;
   report how far ahead main is). Roll over per
   `skills/session-rollover/SKILL.md` with `--loop-mode interactive`.
8. `scripts/context-budget.sh record --label "<phase done>"` at every phase
   boundary. At WARN mid-phase: wait for running children (they die with the
   session), close their dispatches, then roll hands-off with position only.

## Do NOT reload

- The three gen-1/gen-2 corrections debates (all settled; entries in each
  `corrections.md`). R15/R17 is settled by the sweep's quoted lines only.
- The seam inventory's session-lifecycle seams (deterministic by ADR-0011).
- Whether to add a fourth subject (R0.1: no).
- The seam pointers: all re-verified on disk in session 3 (ledger block 3).

## Constraints already decided (do not re-litigate)

- Template rules apply to anything that ships: agent-agnostic, CLI-first or
  `mcp-fragments/`, credentials in the keychain, documented as a first-class
  template addition.
- Research before design: no integration code or spec until a fit decision
  is recorded in `decisions.md`.
- Wave scope fixed at three subjects (R0.1); off-limits: accounts, keys, API
  calls, spend (R0.4). Raw `pass/*.md`, `fact-check.md`, and every brief are
  provenance — never edited.
- Corrections mark each changed claim `(corrected <date>; previously: "…")`.
- The orchestrator rules; agents recommend. Two agents disagreeing on a
  source line → the sweep re-fetches the line, never a ruling from summaries.

## State snapshot

- Branch `main`, committed at session 3's close; not pushed. Files under
  `work/jev-integration/research/`: `schema.md`, `rulings.md` (through R37),
  `sweep-brief.md`, `sweep.md` (gen 1 DONE, 23 findings, ruled R24–R37), `seam-inventory.md`,
  `synthesis-draft.md`, and per subject the pass/fact-check/corrections sets
  (two rounds each). No `synthesis.md`, no `decisions.md` yet.
- `context-budget.env` here sets `ROLLOVER_RELAUNCH=auto`; a supervisor
  (`session-loop.sh`) is running the chain — stage with `--emit`.

## Read these first, in order

1. `work/jev-integration/handoff.md` (top block)
2. `work/jev-integration/research/rulings.md` (from "## Phase 3 closed")
3. `work/jev-integration/research/sweep.md` (Summary + Findings)
4. `skills/research-wave/SKILL.md` Phase 4 + "Handing the wave off"
