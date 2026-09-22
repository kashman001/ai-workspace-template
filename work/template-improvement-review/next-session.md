# Next Session — template-improvement-review (item closed after session 23)

> **This file is the LAUNCHER (catch-up prompt).** Forward-only, REPLACED at
> each rollover. Past-tense provenance lives in `handoff.md`.
> Convention: docs/work-directory-conventions.md.

## Mission

Nothing pending. Stage 4 is complete, ticket 10 is closed, and session 23
verified that commits 9bac406 and aa25002 left every suite green and
removed the old-script leftovers. The item was closed through the stop
door; only reopen it if the human hands over new work.

## Read these, in order

1. `work/template-improvement-review/handoff.md`, top block only (session 23).

## Do NOT reload

Findings Parts 1–4, stage reports, `review.md`, `decisions.md` (append only),
backlog HTML (grep the ID), any script whole (grep them), `plans/*.md`,
`dispatch/*.md`, `cutover-runbook.md`, `issues/*`, `stage4-tracker.md`.

## State snapshot (end of session 23)

- `main` clean; ahead of origin (do not push).
- Record: seq 23 closed through the stop door.
- All 23 `scripts/tests/test-*.sh` suites and `test-check-ledger.py` pass;
  `scripts/import-session-seq.sh --status` reports no leftovers, exit 0.

## First actions (only if reopened)

1. `scripts/context-budget.sh register --project template-improvement-review`
   (expect `seq=24`).
2. Do what the human asked; ledger block `# Session Handoff — 24`; keep two
   session numbers in `handoff.md`; `python3 scripts/check-ledger.py
   work/template-improvement-review` exit 0; commit; `record`; `close`.

## Open, outside this item's scope

`attach-session.sh` and `statusline-context-budget.sh` still read
`.active-session`. No template version marker exists (only the record's
`schema: 1`). Separate tickets if the human wants them.
