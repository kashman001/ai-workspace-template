# Next Session — template-improvement-review (Stage 4: wave D, phase 5, one agent)

> **This file is the LAUNCHER (catch-up prompt).** Forward-only, REPLACED at
> each rollover. Past-tense provenance lives in `handoff.md`.
> Convention: docs/work-directory-conventions.md.

## Mission

**Stage 4 by a fleet, one wave per session.** Plan: `plans/fleet-plan.md`
(read it whole; one screen). Position: waves A, B, C done (phases 1, 2, 3,
4, 6 merged to `stage4`); **this session runs wave D = phase 5** (supervisor
with three verdicts), one agent in its own worktree; the parent never edits a
script. Then roll over hands-off; session 15 runs wave E (phase 7).

**Rules (user, binding):** successor sessions start on their own — rollover
with `--loop-mode handsoff`, no per-wave okay. Every doc the user reads:
short, plain, self-contained (memory `review-docs-plain-language`).

## Read these, in order

1. `work/template-improvement-review/plans/fleet-plan.md` (whole).
2. `work/template-improvement-review/stage4-tracker.md` (whole).
3. `issues/06-phase-5-supervisor-three-verdicts.md` (under
   `work/template-improvement-review/`).
4. In the `stage4` worktree (`.claude/worktrees/stage4/`),
   `work/template-improvement-review/plans/phase-4.md` "Interface" (lines
   22–60: what the launcher now writes — `staged`, `launch.predecessor`,
   `launch.pending`; the `.session-seq` + sidecar write-only mirror phase 5
   deletes; bootstrap dispositions `stopped`/`abandoned`) and "Decisions"
   (61–74). Also `plans/phase-3.md` lines 24–34 (`register` binding via
   `TF_SESSION_PROJECT`+`TF_SESSION_SEQ`; the supervisor exports them).
5. `evaluation/stage3-design-v2.md`: record table (lines 50–58, the `chain`
   block is the supervisor's), "The supervisor's decision" (line 68 to the
   gate table), the gate table's two supervisor rows (grep `supervisor start`).
6. `session-management-review-findings.md`: only the `**Phase 5 —` paragraph
   (grep it).
7. `handoff.md` top block only.

## Do NOT reload

Findings Parts 1–4 beyond the one paragraph, stage1/stage3 reports,
`review.md`, `decisions.md` (append only), backlog HTML whole, the big
scripts whole (the agent greps them, not you), `plans/phase-{1,2,6}.md`
(settled), `dispatch/*.md` (past reports).

## State snapshot

- `main` = 6ce5d8a (session 13 bookkeeping) + this rollover's commit; clean;
  ahead of origin (do not push).
- `stage4` = 4bb8a5d, 10 commits ahead of `main`, checked out ONLY at
  `.claude/worktrees/stage4` (clean). Never check it out in the primary tree.
- **Supervisor pid 72900 is live** (old `session-loop.sh` on frozen `main`).
  Session 13 was 9 of 10, so **this session is 10 of 10: the cap lands at
  this session's rollover.** Still `--emit` at the end (harmless); the
  supervisor will report `cap` and stop, and the human restarts the chain
  with `scripts/session-loop.sh template-improvement-review --reset-cap`.
  Say so plainly in the handoff block and in the final reply.
- Root `ROLLOVER_RELAUNCH=manual`, item override `auto`. Counter
  `.session-seq` = 14 after this launch.
- Session 13 cost ~131K at rollover with two agents; one agent fits easily.
- Known flakes, both green on rerun, neither touched by a wave branch:
  `test-session-loop.sh` D5b-g (timing race, 97 s hold; one sighting) and
  `test-session-lib.sh` S8 (3-writer lock race; two sightings — a third
  means fix the lock in phase 7, not rerun). Phase 5 rewrites
  `test-session-loop.sh`, so a D5b-g failure there is the agent's to judge.
- Carry-overs, not this wave's: stage4 `.claude/settings.json` SessionStart
  entry for the deleted clear-seed hook (guarded no-op; phase 8); vendor
  configs still name the hook shim paths (optional cleanup); prose naming
  `--bg`/`--unstage`/`.rollover-options` in skill/docs/ADR-0009/CONTEXT.md
  (phase 8). `--clear`'s prompt sits in `launch.pending.prompt` with no
  injector: phase 5's plan says whether the supervisor or phase 7 owns that.

## First actions

1. `scripts/context-budget.sh register --project template-improvement-review`
2. Confirm: `ps -p 72900`; `git -C .claude/worktrees/stage4 status --short`
   empty; `git log --oneline main..stage4` shows 10 commits (top 4bb8a5d).
3. Tracker: row 5 → `in progress`, Started today; rewrite "Now".
4. `git worktree add -b s4-phase-5 .claude/worktrees/s4-phase-5 stage4`, then
   `scripts/context-budget.sh dispatch-open --project template-improvement-review --task phase-5 --report /Users/kashif/Developer/experiments/ai-workspace-template/work/template-improvement-review/dispatch/phase-5.md`
   (absolute report path). Use `git -C` and absolute paths everywhere; a
   `cd` into a worktree moves the harness cwd (`docs/operational-knowledge.md`).
5. Launch ONE `general-purpose` agent (not `repo-navigator`). Its prompt
   carries, verbatim: the dispatch contract from step 4; its worktree path +
   branch and "every edit and command inside it"; the do-not-touch list from
   fleet-plan "One agent, one phase" (tracker, launcher, ledger, decisions,
   `.claude/settings.json`, never `context-budget.sh register|record|release|close`
   on any real project); its reads (ticket, fleet-plan contract, phase-4
   Interface+Decisions, phase-3 register binding, design sections above, its
   Part 4 paragraph); the order of work (write `plans/phase-5.md` first with
   tasks/decisions/empty Evidence; **first commit = `main "$@"` wrapper on
   `scripts/session-loop.sh` with no other change, then the body**;
   test-first; run EVERY suite with `bash`, no `timeout`, all rc=0, plus
   `python3 scripts/tests/test-check-ledger.py`; fill Evidence; commits on
   `s4-phase-5` with a `Decision:` trailer and the Co-Authored-By line; clean
   tree; do not merge). **Files:** phase 5 owns `scripts/session-loop.sh`,
   `scripts/tests/test-session-loop.sh`, `test-session-loop-notify.sh`, and
   may delete the `.session-seq`/sidecar mirror writes in
   `scripts/launch-next-session.sh` + their pins in `test-launch-next-session.sh`
   /`test-emit-mode.sh` (say so in the plan, minimal). **Never edits
   `scripts/context-budget.sh`, `scripts/lib/session-lib.sh`, or anything
   under `scripts/hooks/`**; a needed measurer change → DONE_WITH_CONCERNS.
   Two agents last wave cost the agents ~325K/~152K tokens; expect the same.
6. On DONE: verify `git -C .claude/worktrees/s4-phase-5 status` clean and
   `git diff --stat stage4..s4-phase-5`; `dispatch-close --status <S>`.
   `git -C .claude/worktrees/stage4 merge --no-ff s4-phase-5`; run every
   suite there **in the background** (~10 min; never merge while it runs):
   `for t in scripts/tests/*.sh; do bash "$t" >log 2>&1; echo "$t rc=$?"; done`
   plus the Python ledger suite. Red → send it back to the same agent
   (SendMessage); never fix it in the parent.
7. Green: tracker row 5 `done` + commits; copy the plan's Decisions into
   `decisions.md` as a Tier-2 note; `git worktree remove` + `git branch -D`
   (check `git branch --merged stage4` first). Commit bookkeeping on `main`
   (never a script). `record --label "wave D"`.
8. Roll over hands-off: `session-rollover` steps (prep → handoff block → this
   launcher rewritten for wave E = phase 7 alone → `seq-sync --session 14` →
   `record --label "rollover complete: …"` →
   `scripts/launch-next-session.sh template-improvement-review --emit --loop-mode handsoff --loop-reason "<why>"`
   as the very last command). The chain cap will close the chain after this
   emit; the wave E launcher must open with "the human restarted the chain
   with `--reset-cap`" as its state, and the final reply must tell the user.
