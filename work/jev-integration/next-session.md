# Catchup prompt — jev-integration (paste into a new agent session)

We're resuming `jev-integration`. Works in any runtime (Claude Code, Codex,
Gemini, OpenCode) — all read `CONTEXT.md` via their entrypoint.

> **This file is the LAUNCHER (catch-up prompt).** Forward-only, and REPLACED
> at each rollover: it holds what to do next, still-binding constraints, and
> pointers — never session history. Past-tense provenance lives in
> `handoff.md` (the append-only ledger). Convention:
> docs/work-directory-conventions.md.

## Mission

Research wave 1 on Jev is complete and closed (`research/synthesis.md`,
commit c719edd). The only remaining step is **human-only**: pose the fit
decision to the user, work it through with `grill-with-docs`, and record the
outcome as a Tier-2 note in `decisions.md`. No integration code or spec until
`decisions.md` records the fit.

## >>> START HERE <<<

Position: **wave closed; fit decision open; this session is interactive
(the supervisor waited for a human before starting it).**

1. `scripts/context-budget.sh register --project jev-integration` (expect `seq=6`).
2. **Re-pose the open question to the user, verbatim:**

   > **Fit decision** in `decisions.md`: which template seam(s) a typed-decision
   > model serves better than the current runtime (or none), with the rejected
   > alternatives and the evidence from `research/`.

   Point the user at `research/synthesis.md` §5 (provisional seam table) and
   §6, and `research/seam-inventory.md`. Then run `grill-with-docs` with them;
   the outcome is a Tier-2 note in `decisions.md` via `/decision` (what + why
   + rejected alternatives, citing claim ids from `research/`).
3. **If nobody answers** (no human in the loop): do NOT decide the fit
   yourself and do NOT start design work. Commit nothing new, leave the
   question open in this launcher, and end the session with `checkpoint`
   (stop door) rather than rolling over again — a re-roll would loop the
   supervisor on the same question.
4. After the note exists: `scripts/context-budget.sh record --label "fit decision recorded"`,
   commit (do not push; report how far ahead main is), then — only if the
   decision is "integrate" — `to-spec` is the next governing skill.

## Do NOT reload

- The research records beyond the synthesis §5–§6 and the seam inventory;
  every claim id cited there resolves to a `record.md` row if the human wants
  the evidence (grep the id — do not read whole records).
- Any corrections debate (settled; `rulings.md` through R41), the sweep
  (`sweep.md`), or whether to add a fourth subject (R0.1: no).
- The seam inventory's session-lifecycle seams (deterministic by ADR-0011).

## Constraints already decided (do not re-litigate)

- Template rules apply to anything that ships: agent-agnostic, CLI-first or
  `mcp-fragments/`, credentials in the keychain, documented as a first-class
  template addition.
- Research before design: no integration code or spec until a fit decision
  is recorded in `decisions.md`.
- Raw `pass/*.md`, `fact-check.md`, and every brief are provenance — never edited.
- The orchestrator rules; agents recommend. The fit decision itself is the
  user's — the agent grills, records, and does not pre-empt it.

## State snapshot

- Branch `main`, clean, 15+ commits ahead of `origin/main`, not pushed.
- `work/jev-integration/research/`: `synthesis.md` (final), `seam-inventory.md`,
  `schema.md`, `rulings.md` (through R41), `sweep.md`, and per subject the
  record/profile/pass/fact-check/corrections sets. No `decisions.md` yet.
  All dispatch records closed.
- `context-budget.env` here sets `ROLLOVER_RELAUNCH=auto`; the supervisor
  (`session-loop.sh`) runs the chain — this session was staged interactive.

## Read these first, in order

1. `work/jev-integration/handoff.md` (top block)
2. `research/synthesis.md` §5–§6
3. `research/seam-inventory.md` (only once the grill reaches a specific seam)
4. `skills/grill-with-docs/SKILL.md`, `skills/decision-log/SKILL.md`
