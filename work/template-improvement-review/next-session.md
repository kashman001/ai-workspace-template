# Next Session — template-improvement-review (Stage 4: close phase 0, start phase 1)

> **This file is the LAUNCHER (catch-up prompt).** Forward-only, REPLACED at
> each rollover. Past-tense provenance lives in `handoff.md`.
> Convention: docs/work-directory-conventions.md.

## Mission

**Stage 4, phase 1.** Tickets are cut (`issues/01`–`10`). Phase 0 is done
except its first task, which completes when session 10 closes: the old
supervisor chain ends with a plain quit. Position: phase 0 of 9 + cutover;
see `stage4-tracker.md`.

**Readability rule (user, binding for every doc they read):** short; plain
language; self-contained; each concept introduced by a diagram or a
two-sentence explanation. Memory `review-docs-plain-language`.

**No-human-in-the-loop clause:** phase 1 needs no user input. Work on a
branch or worktree against a throwaway work item; `template-improvement-review`
stays on the old scripts until cutover.

## Read these, in order

1. `work/template-improvement-review/stage4-tracker.md` (whole).
2. `work/template-improvement-review/issues/02-phase-1-record-helper.md`.
3. `work/template-improvement-review/evaluation/stage3-design-v2.md` — the
   record table and the two lock/liveness footnotes only (grep `| Block |`,
   `[^lock]`, `[^liveness]`).
4. `work/template-improvement-review/plans/phase-0.md` — "Decisions made
   here" (the record's `schema: 1` shape phase 1 inherits).
5. `work/template-improvement-review/handoff.md` — top block only.

## Do NOT reload

Parts 1–4 of the findings file, the stage1-*/stage3-* reports, `review.md`,
`decisions.md` (append only), backlog HTML whole, the three big scripts whole
(grep them).

## State snapshot

- `main` = commit of session 10; clean; ahead of origin (do not push).
- **No supervisor should be running.** Session 10 staged nothing; the old
  supervisor (pid 72900) logs a deliberate quit and exits when session 10
  is closed. Old counter `.session-seq` = 10.
- Root `ROLLOVER_RELAUNCH=manual`; this item's `context-budget.env` says
  `auto` (for after cutover). Until cutover every session here is started
  by hand.

## First actions

1. `scripts/context-budget.sh register --project template-improvement-review`
2. Verify the chain ended: `ps -p 72900` prints nothing;
   `tail -3 work/template-improvement-review/.session-loop.log` shows the
   quit verdict for session #10; `.session-loop` state file is gone. If the
   supervisor is still alive, stop: report it and do not edit any script.
3. Tracker: phase 0 → `done`, fill Done + Commit (session 10's commit).
   `record --label "phase 0 done"`.
4. Phase 1: write `plans/phase-1.md` from ticket 02 and the record table
   (`scripts/lib/session-lib.sh`, `scripts/tests/test-session-record.sh`:
   read/filter/temp-write/rename under a `mkdir` lock; precondition false →
   silent no-op; empty result → refusal; `schema_mismatch`,
   `record_unreadable`; a deliberate two-writer race test). Set the row
   `in progress`. Implement on a branch; commit only with all
   `scripts/tests/*.sh` green.
5. At each boundary: tracker "Now" line + row, `record --label "<phase> <step>"`.
   At WARN: `session-rollover`, staging nothing (no supervisor): write the
   files, commit, and tell the user to start the next session by hand.
