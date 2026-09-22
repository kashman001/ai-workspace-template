# Next Session — template-improvement-review (post-Stage 4 follow-through, session 23)

> **This file is the LAUNCHER (catch-up prompt).** Forward-only, REPLACED at
> each rollover. Past-tense provenance lives in `handoff.md`.
> Convention: docs/work-directory-conventions.md.

## Mission

Stage 4 is complete and ticket 10 is closed. Session 22 (attended, after
the human's `--reset-cap` restart) shipped two template commits on the
human's instructions: 9bac406 (six items imported; `import-session-seq.sh`
kept as the downstream migration tool with `--status`; L47) and aa25002
(`register` mints `seq + 1` after a stop-door close; M39). Your job is to
confirm those two commits left the whole workspace green, tidy what the
human agrees to, and end through the stop door.

## Read these, in order

1. `work/template-improvement-review/handoff.md`, top block only (session
   22 addendum: what shipped, why the import script stays).
2. `git show --stat 9bac406 aa25002` (the two commits; do not open the
   backlog HTML whole).

## Do NOT reload

Findings Parts 1–4, stage reports, `review.md`, `decisions.md` (append only),
backlog HTML (grep the ID), any script whole (grep them), `plans/*.md`,
`dispatch/*.md`, `cutover-runbook.md`, `issues/*`, `stage4-tracker.md`.

## State snapshot (end of session 22)

- `main` = aa25002; clean apart from untracked `.rollover-options` in seven
  items and `.session-loop.log` in template-maintenance (old-script
  leftovers, nothing reads them); ahead of origin (do not push).
- Record: seq 22 closed through the stop door, then staged for 23 by
  `--emit --loop-mode interactive`; supervisor pid 99460 was live at emit.
- `scripts/import-session-seq.sh --status` reports every item fresh or new,
  exit 0.
- Suites run in session 22: import (44), registry (192), doc-consistency
  (7), numbering (18), ledger check. The rest of `scripts/tests/` was NOT
  run after the two commits.

## First actions

1. `scripts/context-budget.sh register --project template-improvement-review`
   (expect `seq=23`).
2. Run every suite: `for t in scripts/tests/test-*.sh; do bash "$t" >/dev/null 2>&1 || echo "FAIL $t"; done; python3 scripts/tests/test-check-ledger.py`.
   Any failure traced to 9bac406 or aa25002 is yours to fix (surgical,
   with the failing test as the goal); anything else is a finding for the
   ledger, not a fix.
3. Ask the human (interactive session) whether to delete the leftover
   `.rollover-options` / `.session-loop.log` files that `--status` lists;
   delete only on a yes.
4. Ledger block `# Session Handoff — 23`, short; keep two blocks in
   `handoff.md` (archive the session 21 block). `python3 scripts/check-ledger.py
   work/template-improvement-review` exit 0. Commit
   (`work(template-improvement-review): session 23 — ...`).
5. `scripts/context-budget.sh record --label "session 23 done: template-improvement-review"`,
   then `scripts/context-budget.sh close --project template-improvement-review`
   and end your turn. No rollover unless step 2 opened real work.
6. A refusal (`refused reason=<code>`): read the code in the skill's table
   and the runbook; never edit a script beyond step 2's remit.

## Open, outside this item's scope

`attach-session.sh` and `statusline-context-budget.sh` still read
`.active-session`. No template version marker exists (only the record's
`schema: 1`); the human may want one for downstream upgrades. Separate
tickets if the human wants them.
