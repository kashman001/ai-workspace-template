# Next Session — template-improvement-review (Stage 4: attended cutover, session 19)

> **This file is the LAUNCHER (catch-up prompt).** Forward-only, REPLACED at
> each rollover. Past-tense provenance lives in `handoff.md`.
> Convention: docs/work-directory-conventions.md.

## Mission

You are session 19, the first session the new scripts launched, in the same
Claude Code process as session 18 after `/clear`. A human is at the keyboard.
Your job is runbook step 4's verification and then step 5: prove the
attended `--clear` rollover worked, record the evidence, write your ledger
block and the launcher for session 20, then end through the stop door
(`close`) and ask the human to `/exit` so the supervised chain can start.
Do not roll over. Do not start the chain yourself.

**Nobody there?** Say what you are waiting for, end your turn, let the human
continue when they are back.

## Read these, in order

1. `work/template-improvement-review/cutover-runbook.md`, steps 4–6 and
   "Done looks like" only.
2. `work/template-improvement-review/stage4-tracker.md`: the "Now" line and
   the cutover row only.
3. `work/template-improvement-review/handoff.md`, top block only (session 18:
   what was verified live, the untracked-files finding).
4. `work/template-improvement-review/issues/10-cutover.md` (the boxes; tick
   nothing yet — session 21 ticks them with the chain evidence).

## Do NOT reload

Findings Parts 1–4, stage reports, `review.md`, `decisions.md` (append only),
backlog HTML, any script whole (grep them), `plans/*.md`, `dispatch/*.md`,
`skills/session-rollover/SKILL.md` beyond its refusal-code table (step 6).

## State snapshot (end of session 18)

- `main` = 37d4100 (the merge) + session 18's bookkeeping commit; clean apart
  from 13 untracked old-script state files in six *other* work items (see
  ledger block 18; leave them); ahead of origin (do not push).
- `stage4` = 9cfa3d5, still checked out at `.claude/worktrees/stage4`
  (removal optional, runbook step 2).
- No supervisor running. Record: session 18 bound `seq` 18, pid 34573,
  unsupervised; session 18 ran `--check` then `--clear` as its last command.
- Session 18 cost ~64K at register (hook context floor) → ~75K at rollover.

## First actions

1. `scripts/context-budget.sh register --project template-improvement-review`
   (harmless if the SessionStart hook already bound you; expect `seq=19`).
2. Runbook step 4 evidence — did the seed line
   `Work item template-improvement-review - rollover session #19. Read ...`
   appear in your SessionStart hook output? Then:
   `jq '.session.seq, .launch.pending, .launch.predecessor.disposition' work/template-improvement-review/session-state.json`
   → expect `19`, `null`, `"rolled_over"`. Fallback if the seed was absent
   or `.session.seq` was `null`: runbook step 4's last paragraph; note it in
   the tracker's cutover row (the fix is a later agent's job).
3. Tracker: cutover row Used → 3, add the step-4 evidence (seed shown or
   not, the three jq values) to its Notes; "Now" → "session 19 at runbook
   step 5; chain of 2 next".
4. Ledger block `# Session Handoff — 19`: the evidence above, short. Keep
   two blocks in `handoff.md` (archive block 17 to the top of
   `handoff-archive.md`). `python3 scripts/check-ledger.py work/template-improvement-review` exit 0.
5. Rewrite this launcher for session 20 (chain plan below). Commit the
   bookkeeping (`work(template-improvement-review): session 19 — ...`).
6. Runbook step 5: `scripts/context-budget.sh close --project template-improvement-review`
   (exit 0), then tell the human to `/exit` and, from the repo root, run
   `scripts/session-loop.sh template-improvement-review --max-sessions 2`
   (runbook step 6). Check they can verify after `/exit`:
   `jq '.seq, .session.ended, .staged' work/template-improvement-review/session-state.json`
   → `19`, non-null, `null`. That is your last command.
7. A refusal (`refused reason=<code>`): read the code in the skill's table
   and the runbook; never edit a script. A script bug is a finding for the
   tracker Notes and the runbook's "Blockers"; the human decides on a fix
   agent.

## The chain after you (carry this into each launcher you write)

- **20** (first child of `session-loop.sh --max-sessions 2`, hands-off):
  register; confirm `.chain.supervisor.pid` is live and `.chain.used` = 1
  (`jq '.chain' work/template-improvement-review/session-state.json`);
  tracker Used → 4 with that evidence; block 20 (archive 18); launcher for
  21; commit; `scripts/context-budget.sh record --label "rollover complete: template-improvement-review"`;
  `scripts/launch-next-session.sh template-improvement-review --emit --loop-mode handsoff --loop-reason "cutover chain leg 1 done"`.
- **21**: register; confirm `verdict=staged seq=20` in
  `work/template-improvement-review/.session-loop.log` and `.chain.used` = 2;
  tick the boxes in `issues/10-cutover.md` (import, attended rollover, chain;
  leave the retire-import box); tracker cutover row `done` with the merge
  commit 37d4100, Used → 5; ledger block 21 with the evidence (archive 19);
  commit; launcher for 22 ("chain capped; nothing to do until the human
  restarts with `--reset-cap`; open follow-up: retire
  `scripts/import-session-seq.sh` + `scripts/tests/test-import-session-seq.sh`
  + its row under "Reason codes" in `docs/context-budget.md`, after every
  live work item with a `.session-seq` is imported"); `record`;
  `--emit --loop-mode handsoff` → the supervisor reports `cap seq=22`.
