# Next Session — template-improvement-review (Stage 4: attended cutover, session 18)

> **This file is the LAUNCHER (catch-up prompt).** Forward-only, REPLACED at
> each rollover. Past-tense provenance lives in `handoff.md`.
> Convention: docs/work-directory-conventions.md.

## Mission

You are the attended cutover session. A human is at the keyboard. Run
`work/template-improvement-review/cutover-runbook.md` with them, from
wherever they are in it. They do the human steps (Ctrl-C on the old
supervisor, the merge, the import, pressing `/clear`, starting the chain);
you do the agent steps (register, verify, ledger block, launcher, `--check`,
`--clear`). Session 17 rehearsed every step in a scratch clone: merge clean,
import ok, all 23 suites green. Nothing has been run on the live checkout yet.

**Which scripts are you on?** `ls scripts/fleet.sh`. Present: the merge is
done, you are session 18 of runbook step 3, on the new scripts, unsupervised.
Absent: someone pressed Enter under the old supervisor and you run the old
scripts from the tree that is about to be merged. Say so, do nothing else,
and ask the human to type `/exit` and follow runbook step 0.

**Nobody there?** Do not idle and do not improvise: say what you are waiting
for, end your turn, and let the human continue when they are back. No step
in the runbook is safe without them.

## Read these, in order

1. `work/template-improvement-review/cutover-runbook.md` (whole; one page).
2. `work/template-improvement-review/stage4-tracker.md`: the "Now" line and
   the cutover row only.
3. `work/template-improvement-review/issues/10-cutover.md` (the acceptance
   checkboxes).
4. `work/template-improvement-review/handoff.md`, top block only (session 17:
   findings and the runbook's reasons).
5. On the new scripts only: `skills/session-rollover/SKILL.md` step 6, the
   `--clear` paragraph and the refusal-code table.

## Do NOT reload

Findings Parts 1–4, stage reports, `review.md`, `decisions.md` (append only),
backlog HTML, any script whole (grep them), `plans/*.md`, `dispatch/*.md`,
`plans/fleet-plan.md` (its job is done).

## State snapshot (end of session 17)

- `main` = 9ab55ab (rehearsal bookkeeping) + session 17's rollover commit;
  clean; ahead of origin (do not push).
- `stage4` = 9cfa3d5, checked out only at `.claude/worktrees/stage4`.
- Old chain: supervisor pid 47660 (`--max-sessions 15`, old scripts from
  `main`) pauses after session 17 with "Press Enter to start #18". The
  runbook's step 0 is Ctrl-C there, not Enter.
- Old counter `.session-seq` = 18 after session 17's rollover; the import
  therefore writes `seq` 18. Root `ROLLOVER_RELAUNCH=manual`, item override
  `auto`.
- Session 17 cost ~58K → ~125K with no agents.

## First actions

1. `scripts/context-budget.sh register --project template-improvement-review`
   (new scripts: expect `filled`; `jq '.session.seq, .session.pid'
   work/template-improvement-review/session-state.json` → 18 and a number).
2. Confirm with the human, per runbook "Step 3": `pgrep -f session-loop.sh`
   prints nothing; `git log --oneline -1` is the merge; `git status --short`
   empty; `scripts/context-budget.sh supervised --project template-improvement-review`
   exits 1.
3. Tracker: cutover row Used → 2; "Now" → "live cutover in progress with the
   human; session 18 at runbook step 4".
4. Runbook step 4, with the human: write your ledger block (`# Session
   Handoff — 18`: what you verified, short), rewrite this launcher for
   session 19 (below), `--check` (exit 0), then `--clear`, and tell the
   human to press `/clear` and type nothing. That is your last command.
5. A refusal (`refused reason=<code>`): read the code in the skill's table
   and the runbook; never edit a script. A script bug is a finding for the
   tracker Notes and the runbook's "Blockers"; the human decides on a fix
   agent.

## The chain after you (carry this into each launcher you write)

- **19** (same process, after `/clear`): confirm the seed line appeared and
  `.session.seq` = 19, `.launch.pending` null, predecessor `rolled_over`
  (runbook step 4; the fallback if not). Record the evidence in the tracker
  row and the ledger. Write block 19 and the launcher for 20, then runbook
  step 5: `scripts/context-budget.sh close --project template-improvement-review`
  and ask the human to `/exit`. Do not roll over.
- **20** (first child of `session-loop.sh --max-sessions 2`, hands-off):
  confirm `.chain.supervisor.pid` is live and `.chain.used` = 1; block 20;
  launcher for 21; `record`; `--emit --loop-mode handsoff`.
- **21**: confirm `verdict=staged seq=20` in `.session-loop.log`; tick the
  boxes in `issues/10-cutover.md`; tracker cutover row `done` with the merge
  commit; ledger evidence; commit; block 21; launcher for 22 ("chain capped;
  nothing to do until the human restarts with `--reset-cap`; open follow-up:
  retire `scripts/import-session-seq.sh` + its test + its doc row");
  `--emit --loop-mode handsoff` → the supervisor reports `cap seq=22`.
