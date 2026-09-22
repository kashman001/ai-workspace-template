# Next Session — template-improvement-review (Stage 4: supervised chain, session 21)

> **This file is the LAUNCHER (catch-up prompt).** Forward-only, REPLACED at
> each rollover. Past-tense provenance lives in `handoff.md`.
> Convention: docs/work-directory-conventions.md.

## Mission

You are session 21, the second and last child of `scripts/session-loop.sh
template-improvement-review --max-sessions 2` (runbook step 6), hands-off:
nobody is at the keyboard. Your job is to record the final chain evidence,
close the cutover row and ticket, and roll over with `--emit --loop-mode
handsoff` so the supervisor reports `verdict=cap seq=22` and stops. Small
session; do not start new work.

## Read these, in order

1. `work/template-improvement-review/cutover-runbook.md`, step 6 and "Done
   looks like" only.
2. `work/template-improvement-review/stage4-tracker.md`: the "Now" line and
   the cutover row only.
3. `work/template-improvement-review/handoff.md`, top block only (session 20:
   chain leg 1 evidence).
4. `work/template-improvement-review/issues/10-cutover.md` (the checkboxes).

## Do NOT reload

Findings Parts 1–4, stage reports, `review.md`, `decisions.md` (append only),
backlog HTML, any script whole (grep them), `plans/*.md`, `dispatch/*.md`,
other `issues/*`, `skills/session-rollover/SKILL.md` beyond its refusal-code
table.

## State snapshot (end of session 20)

- `main` = e5be261 + session 20's bookkeeping commit; clean apart from 13
  untracked old-script state files in six *other* work items (leave them);
  ahead of origin (do not push).
- Runbook steps 0–5 done live (merge 37d4100; attended `--clear` rollover
  18 → 19 confirmed; 19 ended via `close` + `/exit`). Step 6 in progress:
  session 20 ran as chain leg 1 (supervisor pid 74444 live, `supervised`
  rc 0, `.chain.used` 1 of cap 2, log `staging the first session` →
  `starting session #20 (1 of 2)`) and rolled over `--emit --loop-mode
  handsoff`.
- Cost floor: ~63K at `register` for a fresh Claude Code session here.
- Log lines in `.session-loop.log` carry a timestamp and no `session-loop:`
  prefix; the runbook table shows the terminal form. Same lines.

## First actions

1. `scripts/context-budget.sh register --project template-improvement-review`
   (expect `seq=21`).
2. Chain evidence: `tail -5 work/template-improvement-review/.session-loop.log`
   → a `verdict=staged seq=20` line (or the equivalent "session #20 rolled
   over cleanly (mode=handsoff …)" then "starting session #21 (2 of 2)");
   `jq '.chain, .launch.predecessor' work/template-improvement-review/session-state.json`
   → `.chain.used` = 2, supervisor pid live (`kill -0 <pid>`),
   `.launch.predecessor.disposition` = `rolled_over`, predecessor seq 20;
   `scripts/context-budget.sh supervised --project template-improvement-review`
   → rc 0.
3. Ticket: tick the boxes in `issues/10-cutover.md` for the import, the
   attended rollover, and the chain; leave the retire-import box unticked.
4. Tracker: cutover row `done`, Done date 2026-09-22, Commit 37d4100 (the
   merge), Used → 5, the step-2 evidence appended to its Notes; "Now" →
   "Stage 4 complete: cutover done (37d4100), chain capped at 2. Nothing to
   do until the human restarts with `--reset-cap`. Open follow-up: retire
   the import script after the six other items are imported."
5. Ledger block `# Session Handoff — 21`: the evidence, short. Keep two
   blocks in `handoff.md` (archive block 19 to the top of
   `handoff-archive.md`). `python3 scripts/check-ledger.py work/template-improvement-review` exit 0.
6. Rewrite this launcher for session 22 (below). Commit the bookkeeping
   (`work(template-improvement-review): session 21 — ...`).
7. `scripts/context-budget.sh record --label "rollover complete: template-improvement-review"`,
   then `scripts/launch-next-session.sh template-improvement-review --emit --loop-mode handsoff --loop-reason "cutover chain leg 2 done; Stage 4 complete"`.
   That is your last command; end your turn. The supervisor reports
   `cap seq=22` and exits 0.
8. A refusal (`refused reason=<code>`): read the code in the skill's table
   and the runbook; never edit a script. A script bug is a finding for the
   tracker Notes and the runbook's "Blockers"; the human decides on a fix
   agent.

## The launcher you write for session 22

Mission: chain capped; nothing to do until the human restarts with
`scripts/session-loop.sh template-improvement-review --reset-cap`. One open
follow-up, an agent's job in one commit, only after every live work item
with a `.session-seq` file has been imported (six other items today:
automatic-session-rollover, context-decay, devex-review, sdlc-ai-mapping,
template-maintenance, usage-scenarios): delete
`scripts/import-session-seq.sh`, `scripts/tests/test-import-session-seq.sh`,
and its row under "Reason codes" in `docs/context-budget.md` (the
doc-consistency test pins that row), then run the shell suites. Also open
(outside this item's scope): `attach-session.sh` and
`statusline-context-budget.sh` still read `.active-session`.
