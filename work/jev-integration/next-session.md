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
make the fit decision: run the Phase 4 cross-subject sweep, apply what it
finds, write the synthesis, and roll over interactive with the fit question
open. No integration code or spec until `decisions.md` records the fit.

## >>> START HERE <<<

Position: **Phase 3 is closed** (every subject corrected in two rounds; all
dispatch generations closed). **Phase 4 sweep, the post-sweep corrections
pass, and the synthesis are not started.**

1. `scripts/context-budget.sh register --project jev-integration` (expect `seq=3`).
2. Read `research/rulings.md` in full (rulings through R23; the queued
   post-sweep rulings are listed under "Phase 3 closed") and
   `research/sweep-brief.md`. Do NOT read `record.md`/`fact-check.md`/
   `corrections.md` whole — grep them.
3. `scripts/fleet.sh dispatch-list --project jev-integration` — trust the
   records. Everything should be closed. If one is `open`, its report is
   partial: `dispatch-close --status KILLED`, then reopen and relaunch.
4. **Phase 4 sweep.** `scripts/fleet.sh dispatch-open --project jev-integration
   --task sweep --report work/jev-integration/research/sweep.md --brief
   work/jev-integration/research/sweep-brief.md --agent-type general-purpose`,
   then launch one `general-purpose` agent: "read and follow your brief
   exactly: work/jev-integration/research/sweep-brief.md" + the contract the
   script prints + tool guidance (curl/WebFetch, grep, write ONLY `sweep.md`).
   It settles R17 (cookbook L512–591 reading) and checks R20's mirror.
5. Rule on `sweep.md` in `rulings.md` (you rule; the agent recommends). Then
   ONE corrections pass per affected subject (gen 3 of `corr-<subject>`,
   brief `corrections-brief-3.md` modelled on `*/corrections-brief-2.md`)
   carrying the sweep rulings PLUS the queued ones: R18 (if the sweep confirms
   gen 2's reading of C50), R20, R21, R22 — text in `rulings.md`. Launch the
   passes in parallel. Verify on disk; close dispatches; rule on any round-3
   findings.
6. **Synthesis → `research/synthesis.md`**: the corrected facts with claim
   ids (start from the three `profile.md` files, they are the summaries);
   what changed vs standing claims S1–S6 (`schema.md`); the wave patterns;
   and a first, explicitly **provisional** list of template seams a
   typed-decision model could serve, from `research/seam-inventory.md`
   (verify a pointer before citing it), with what each needs from the API:
   closed option set + an `other` option (the API never abstains), a
   confidence-threshold policy (Choice/Score only — Noul has none),
   model-version pinning (alias vs `jev-1.13.0`), cost per call at $42/Btok
   input (output free), and the no-SLA / rate-limits-may-change terms. The
   fit **decision** is NOT this session's job; write the decision *question*
   verbatim at the end of the synthesis.
7. Close: `README.md` here (add a status line: research complete, fit
   decision pending) and the `work/README.md` row; ledger block
   `# Session Handoff — 3 (<date>)` on `handoff.md`; rewrite this launcher for
   the fit-decision session (`grill-with-docs` → `decisions.md` note; carry
   the decision question verbatim in First actions); commit (do not push;
   report how far ahead main is). Roll over per
   `skills/session-rollover/SKILL.md` with `--loop-mode interactive`.
8. `scripts/context-budget.sh record --label "<phase done>"` at every phase
   boundary. At WARN mid-phase: wait for running children (they die with the
   session), close their dispatches, then roll hands-off with position only.

## Do NOT reload

- The three gen-1 corrections debates (all settled; entries in each
  `corrections.md`). The R15 dispute is NOT settled — the sweep settles it (R17).
- The seam inventory's session-lifecycle seams (session-loop, context-budget,
  launcher, check-ledger): deterministic by ADR-0011, not candidates.
- Whether to add a fourth subject (R0.1: no).

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

- Branch `main`, committed at session 2's close; not pushed. Files under
  `work/jev-integration/research/`: `schema.md`, `rulings.md`,
  `sweep-brief.md`, `seam-inventory.md`, and per subject the pass/fact-check/
  corrections sets (`corrections-brief.md`, `corrections-brief-2.md`,
  `corrections.md` with two rounds). No `sweep.md`, no `synthesis.md`,
  no `decisions.md` yet.
- `context-budget.env` here sets `ROLLOVER_RELAUNCH=auto`; a supervisor
  (`session-loop.sh`) is running the chain — stage with `--emit`.

## Read these first, in order

1. `work/jev-integration/handoff.md` (top block)
2. `work/jev-integration/research/rulings.md`
3. `work/jev-integration/research/sweep-brief.md`
4. `skills/research-wave/SKILL.md` Phase 4 + "Handing the wave off" (when step 4 reaches it)
