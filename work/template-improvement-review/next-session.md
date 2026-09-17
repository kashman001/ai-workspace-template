# Next Session — template-improvement-review (Stage 4: wave B, phase 3, one agent)

> **This file is the LAUNCHER (catch-up prompt).** Forward-only, REPLACED at
> each rollover. Past-tense provenance lives in `handoff.md`.
> Convention: docs/work-directory-conventions.md.

## Mission

**Stage 4 by a fleet, one wave per session.** Plan: `plans/fleet-plan.md`
(read it whole; it is one screen). Position: waves A done (phases 1, 2 merged
to `stage4`); **this session runs wave B = phase 3 only** (measurer on the
record), as one agent in its own worktree; the parent never edits a script.
Then roll over hands-off; session 13 runs wave C (phases 4 ∥ 6).

**Rules (user, binding):** successor sessions start on their own — rollover
with `--loop-mode handsoff`, no per-wave okay. Every doc the user reads:
short, plain, self-contained (memory `review-docs-plain-language`).

## Read these, in order

1. `work/template-improvement-review/plans/fleet-plan.md` (whole).
2. `work/template-improvement-review/stage4-tracker.md` (whole).
3. `work/template-improvement-review/issues/04-phase-3-measurer-on-the-record.md`.
4. In the `stage4` worktree (`.claude/worktrees/stage4/`): `plans/phase-1.md`
   (the helper's interface: `session_record_update <record> <pre> <filter>`,
   exit 0/1/3/4, `reason=` codes) and `plans/phase-2.md` "Decisions" (fleet.sh
   reads `check`'s `runtime=`/`artifact=` lines — phase 3 must keep them or
   update `resolve_own_session` in `scripts/fleet.sh`).
5. `evaluation/stage3-design-v2.md`: record table (grep `| Block |`, lines
   50–58), "Who is alive" (line 60), "How the successor finds its number"
   (line 64), footnote `[^liveness]`.
6. `handoff.md` top block only.

## Do NOT reload

Findings Parts 1–4 beyond the phase 3 paragraph (grep `Phase 3 —`), stage1/
stage3 reports, `review.md`, `decisions.md` (append only), backlog HTML whole,
the big scripts whole (the agent greps them, not you).

## State snapshot

- `main` = session 11 bookkeeping commit; clean; ahead of origin (do not push).
- `stage4` = 4 commits ahead of `main` (8cb363d, 1e6f857, f07f5ea, 5a4aec6),
  checked out ONLY at `.claude/worktrees/stage4` (clean). Never check it out in
  the primary tree: the supervisor and your hooks read the old scripts there.
- **Supervisor pid 72900 is live** (old `session-loop.sh` on frozen `main`).
  Session 11 was 7 of 10; cap lands around session 14 — restart with
  `scripts/session-loop.sh template-improvement-review --reset-cap` then.
- Root `ROLLOVER_RELAUNCH=manual`, item override `auto`. Counter `.session-seq`
  = 12 after this launch.
- Session 11 cost ~118K with two agents; one agent should leave headroom.

## First actions

1. `scripts/context-budget.sh register --project template-improvement-review`
2. Confirm: `ps -p 72900`; `git -C .claude/worktrees/stage4 status --short`
   empty; `git log --oneline main..stage4` shows the 4 commits.
3. Tracker: phase 3 → `in progress`, Started today; rewrite "Now".
4. `git worktree add -b s4-phase-3 .claude/worktrees/s4-phase-3 stage4`, then
   `scripts/context-budget.sh dispatch-open --project template-improvement-review --task phase-3 --report /Users/kashif/Developer/experiments/ai-workspace-template/work/template-improvement-review/dispatch/phase-3.md`
   (absolute report path; the agent's worktree is elsewhere).
5. Launch ONE `general-purpose` agent (not `repo-navigator`, which is
   read-only). Its prompt carries, verbatim: the dispatch contract printed in
   step 4; the worktree path + branch and "every edit and command inside it";
   the do-not-touch list from fleet-plan "One agent, one phase" (tracker,
   launcher, ledger, decisions, `.claude/settings.json`, never
   `context-budget.sh register|record|release` on any project); the reads
   (ticket 04, fleet-plan contract, phase-1/phase-2 plan files, design
   sections above, Part 4 `Phase 3 —` paragraph); the order of work (write
   `plans/phase-3.md` first with tasks/decisions/empty Evidence; test-first;
   run EVERY suite with `bash`, no `timeout`, all rc=0; fill Evidence; one
   commit on `s4-phase-3` with a `Decision:` trailer and the Co-Authored-By
   line; clean tree; do not merge). Say the phase 2 caveat: keep `check`'s
   `runtime=`/`artifact=` output or update `scripts/fleet.sh`.
6. On DONE: verify `git -C .claude/worktrees/s4-phase-3 status` clean and
   `git diff --stat stage4..s4-phase-3`; `dispatch-close --status DONE`;
   `git -C .claude/worktrees/stage4 merge --no-ff s4-phase-3`; run every suite
   in that worktree **in the background** (~10 min; never merge while it runs):
   `for t in scripts/tests/*.sh; do bash "$t" >log 2>&1; echo "$t rc=$?"; done`.
   Red → send the failure back to the same agent (SendMessage); never fix it
   in the parent.
7. Green: tracker row 3 `done` + commits; copy the plan file's Decisions into
   `decisions.md` as Tier-2 notes; `git worktree remove` the agent worktree and
   `git branch -D s4-phase-3` (check `git branch --merged stage4` first —
   `-d` compares against `main` and refuses). Commit bookkeeping on `main`
   (never a script). `record --label "wave B"`.
8. Roll over through the live supervisor, hands-off: `session-rollover`
   steps (prep → handoff block → this launcher rewritten for wave C →
   `seq-sync --session 12` → `record --label "rollover complete: …"` →
   `scripts/launch-next-session.sh template-improvement-review --emit --loop-mode handsoff --loop-reason "<why>"`
   as the very last command). Wave C = phases 4 ∥ 6, two agents; merge 4
   before 6.
