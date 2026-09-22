# Next Session — template-improvement-review (Stage 4: cutover, session 17)

> **This file is the LAUNCHER (catch-up prompt).** Forward-only, REPLACED at
> each rollover. Past-tense provenance lives in `handoff.md`.
> Convention: docs/work-directory-conventions.md.

## Mission

All eight Stage 4 phases are merged on `stage4` (head 9cfa3d5, 30 commits
ahead of `main`, every suite green there). **This session is the cutover:**
bring `stage4` into `main`, import the session counter into the record, and
prove the new scripts with one attended `--clear` rollover and a two-session
supervised chain on this item.

**Rules (user, binding, 2026-09-21):** the user is away overnight and checks
back in the morning. Keep running. Do every step that is safe without a
human, then hand the human-only steps over by rolling over with
`--loop-mode interactive` (the successor waits for the human at a fresh
window). **Never sit idle waiting**: the old supervisor's watchdog kills an
idle child after 4h (`SESSION_LOOP_KILL_AFTER`). Every doc the user reads:
short, plain, self-contained (memory `review-docs-plain-language`).

## What is safe unattended, what is not

Safe (do it): reading, a scratch `git clone` of `main` with `stage4` merged
into it, running suites and the counter import there, writing the runbook,
bookkeeping commits on `main` (tracker, ledger, launcher, runbook).

Not safe unattended (hand over): merging `stage4` into the live `main`
checkout (this session's own hooks and the running supervisor pid 47660
execute scripts from that tree; the new hooks expect a record that does not
exist yet), ending the old chain, the attended `--clear`, starting the new
chain. These are the human's steps, with you at the keyboard next to them.

## Read these, in order

1. `work/template-improvement-review/plans/fleet-plan.md` (whole; one screen).
2. `work/template-improvement-review/stage4-tracker.md` ("Now" + rows 8 and
   cutover).
3. `issues/10-cutover.md` (under `work/template-improvement-review/`; its
   checkboxes are the acceptance list), then
   `session-management-review-findings.md`: grep `cutover` and read those
   paragraphs (Part 4, ~lines 765–830) — what the cutover was designed to do,
   in which order, and the counter import verb.
4. In the `stage4` worktree (`.claude/worktrees/stage4/`):
   `work/template-improvement-review/plans/phase-8.md` "Concerns for the
   parent" (1: launcher+supervisor land together; 2: the `/clear` seed needs
   one attended `--clear`, fallback named; 4: two scripts still read
   `.active-session`); the rewritten `skills/session-rollover/SKILL.md`
   and `docs/context-budget.md` "Verbs and reason codes" (the new vocabulary
   you will run the cutover with); `scripts/tests/test-import-session-seq.sh`
   header (how the import is exercised).
5. `handoff.md` top block only.

## Do NOT reload

Findings Parts 1–3, stage1/2/3 reports, `review.md`, `decisions.md` (append
only), backlog HTML whole, any script whole (grep them), `plans/phase-{1..7}.md`,
`dispatch/*.md`.

## State snapshot

- `main` = c47edeb (session 16 bookkeeping) + this rollover's commit; clean;
  ahead of origin (do not push).
- `stage4` = 9cfa3d5, checked out ONLY at `.claude/worktrees/stage4` (clean).
  Never check it out in the primary tree.
- Old chain live: supervisor pid 47660 (`--max-sessions 15`, old
  `session-loop.sh` from frozen `main`); this session is its child. Confirm:
  `pgrep -f session-loop.sh`; `scripts/context-budget.sh supervised --project template-improvement-review`.
- Root `ROLLOVER_RELAUNCH=manual`, item override `auto`. `.session-seq` = 17
  after this launch.
- Session 16 cost ~60K→~112K with one agent (~420K agent tokens).

## First actions

1. `scripts/context-budget.sh register --project template-improvement-review`.
2. Confirm the state snapshot (`git -C .claude/worktrees/stage4 status --short`
   empty; `git log --oneline main..stage4 | wc -l` = 30; supervisor live).
3. Tracker: cutover row → `in progress`, Started today; rewrite "Now".
4. **Rehearse in a clone** (never the worktree, never the main checkout —
   scripts resolve their root via `git rev-parse --git-common-dir`):
   `git clone -q . <scratchpad>/cutover-rehearsal`, there `git merge --no-ff stage4`
   (from `main`), resolve nothing by hand — a conflict is a finding, record it.
   Copy `work/template-improvement-review/.session-seq` (and only that) into
   the clone's item, run the counter import verb the way
   `test-import-session-seq.sh` does, show the resulting record. Run every
   suite in the clone with `bash` (no `timeout`), all rc=0, plus the Python
   ledger suite, in the background (~10 min). Unset the four `TF_SESSION_*`
   variables first.
5. Write `work/template-improvement-review/cutover-runbook.md` (one page,
   plain): the exact commands for the human's steps in order — end the old
   chain cleanly, merge `stage4` into `main`, import the counter, attended
   `--clear` rollover (what to look for: the seed line in the fresh session's
   context; the fallback if absent, per phase-8 Concern 2), start the new
   chain with `--max-sessions 2`, and what "done" looks like (verdict codes).
   Include the rehearsal evidence (suite rc lines, record contents).
6. Bookkeeping commit on `main` (tracker, runbook; never a script).
   `record --label "cutover rehearsal"`.
7. Roll over: `session-rollover` steps (prep → handoff block → this launcher
   rewritten as "session 18: attended cutover, wait for the human, then run
   the runbook with them" → `seq-sync --session 17` → `record` → if
   supervised, `scripts/launch-next-session.sh template-improvement-review --emit --loop-mode interactive --loop-reason "cutover needs the human at the keyboard: live merge, attended --clear, new chain"`
   as the very last command; if not supervised, end with the paste-ready
   prompt.

If the rehearsal merge conflicts or a suite is red in the clone: do not
touch `stage4` or `main` scripts yourself. Record it in the runbook under
"Blockers", in the tracker Notes, and still roll over interactive; the human
decides whether to dispatch a fix agent.
