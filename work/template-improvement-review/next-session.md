# Next Session — template-improvement-review (Stage 4 complete, session 23)

> **This file is the LAUNCHER (catch-up prompt).** Forward-only, REPLACED at
> each rollover. Past-tense provenance lives in `handoff.md`.
> Convention: docs/work-directory-conventions.md.

## Mission

Stage 4 is complete: the cutover to the new session scripts is done (merge
37d4100) and the supervised chain reached its cap of 2 (sessions 20 and 21).
You exist only because the human restarted the supervisor with
`scripts/session-loop.sh template-improvement-review --reset-cap`. Session
22 (the first post-cap restart) closed the last follow-up: the six other items
are imported and the import script stays, with `--status`. There is no
planned work for this item: register, confirm the record, and end via
`scripts/context-budget.sh close` (the stop door), not a rollover.

## Read these, in order

1. `work/template-improvement-review/handoff.md`, top block only (session
   22 addendum: imports done, ticket 10 closed).
2. `work/template-improvement-review/stage4-tracker.md`: the "Now" line only.
3. `work/template-improvement-review/issues/10-cutover.md` (done).

## Do NOT reload

Findings Parts 1–4, stage reports, `review.md`, `decisions.md` (append only),
backlog HTML, any script whole (grep them), `plans/*.md`, `dispatch/*.md`,
`cutover-runbook.md`, other `issues/*`.

## State snapshot (end of session 22)

- `main` = fee0f81 + session 22's bookkeeping commit; clean apart from 13
  untracked old-script state files in six *other* work items (leave them);
  ahead of origin (do not push).
- Record: seq 22 closed through the stop door (no rollover, no successor
  launch).
- Cost floor: ~58–63K at `register` for a fresh Claude Code session here.

## First actions

1. `scripts/context-budget.sh register --project template-improvement-review`
   (expect `seq=23`).
2. Ledger block `# Session Handoff — 23`, short; keep two blocks in
   `handoff.md` (archive block 21). `python3 scripts/check-ledger.py
   work/template-improvement-review` exit 0. Commit
   (`work(template-improvement-review): session 23 — ...`).
3. `scripts/context-budget.sh record --label "session 23 done: template-improvement-review"`,
   then `scripts/context-budget.sh close --project template-improvement-review`
   and end your turn. No rollover: there is no session 24 to plan.
4. A refusal (`refused reason=<code>`): read the code in the skill's table
   and the runbook; never edit a script. A script bug is a finding for the
   tracker Notes; the human decides on a fix agent.

## Open, outside this item's scope

`attach-session.sh` and `statusline-context-budget.sh` still read
`.active-session`; backlog M39 (an attended `register` after a stop-door
close adopts the closed session's number). Not this item's job; a separate ticket if the human
wants it.
