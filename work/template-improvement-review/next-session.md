# Catchup prompt — Template Improvement Review (paste into a new agent session)

We're resuming template-improvement-review. Works in any runtime (Claude Code,
Codex, Gemini, OpenCode) — all read `CONTEXT.md` via their entrypoint.

> **This file is the LAUNCHER (catch-up prompt).** Forward-only, and REPLACED
> at each rollover: it holds what to do next, still-binding constraints, and
> pointers — never session history. Past-tense provenance lives in
> `handoff.md` (the append-only ledger). Convention:
> docs/work-directory-conventions.md.

## >>> START HERE <<<

Session 1 is pooling open threads into `review.md` and working the list.

1. Read `review.md`; pick the top undelivered item.
2. Deliver it with its backlog update; run the suites; record any
   autonomous assumption in `decisions.md`.
3. Repeat until the list is drained or the budget says roll over.

## Constraints already decided (do not re-litigate)

- The user authorised autonomous improvement of the template in this item
  (2026-09-10). Design-gap cards from the options brief may be built under
  stated assumptions, recorded in `decisions.md`; the earlier
  template-maintenance "do not design solo" rule is superseded for this item.

## Read these first, in order

1. `work/template-improvement-review/README.md`
2. `work/template-improvement-review/handoff.md` (top block)
3. `work/template-improvement-review/review.md`
