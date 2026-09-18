# Next Session — template-improvement-review (Stage 4: wave C, phases 4 ∥ 6, two agents)

> **This file is the LAUNCHER (catch-up prompt).** Forward-only, REPLACED at
> each rollover. Past-tense provenance lives in `handoff.md`.
> Convention: docs/work-directory-conventions.md.

## Mission

**Stage 4 by a fleet, one wave per session.** Plan: `plans/fleet-plan.md`
(read it whole; it is one screen). Position: waves A and B done (phases 1, 2,
3 merged to `stage4`); **this session runs wave C = phases 4 ∥ 6** (launcher
on the record; hook dispatcher), two agents in their own worktrees; the
parent never edits a script. Merge 4 before 6. Then roll over hands-off;
session 14 runs wave D (phase 5).

**Rules (user, binding):** successor sessions start on their own — rollover
with `--loop-mode handsoff`, no per-wave okay. Every doc the user reads:
short, plain, self-contained (memory `review-docs-plain-language`).

## Read these, in order

1. `work/template-improvement-review/plans/fleet-plan.md` (whole).
2. `work/template-improvement-review/stage4-tracker.md` (whole).
3. `issues/05-phase-4-launcher-on-the-record.md` and
   `issues/07-phase-6-hook-dispatcher.md` (under
   `work/template-improvement-review/`).
4. In the `stage4` worktree (`.claude/worktrees/stage4/`):
   `work/template-improvement-review/plans/phase-3.md` "Interface" (lines
   20–47: the record verbs, exit codes, `reason=` codes, how `register` binds
   via `TF_SESSION_PROJECT`+`TF_SESSION_SEQ` or `launch.pending`) and
   "Decisions" (48–60). Phase 4 builds on these; phase 6's dispatcher calls
   `register`/`release`.
5. `evaluation/stage3-design-v2.md`: record table (lines 50–58), "How the
   successor finds its number" (line 64), and the launcher gate/refusal
   table (grep `launcher_stale`), plus the adapter table (grep `adapter`).
6. `session-management-review-findings.md`: only the `**Phase 4 —` and
   `**Phase 6 —` paragraphs (grep them).
7. `handoff.md` top block only.

## Do NOT reload

Findings Parts 1–4 beyond the two paragraphs, stage1/stage3 reports,
`review.md`, `decisions.md` (append only), backlog HTML whole, the big
scripts whole (the agents grep them, not you), `plans/phase-{1,2}.md`
(settled; phase-3 Interface supersedes what wave C needs).

## State snapshot

- `main` = e1778da (session 12 bookkeeping) + this rollover's commit; clean;
  ahead of origin (do not push).
- `stage4` = 0a117c6, 7 commits ahead of `main`, checked out ONLY at
  `.claude/worktrees/stage4` (clean). Never check it out in the primary tree.
- **Supervisor pid 72900 is live** (old `session-loop.sh` on frozen `main`).
  Session 12 was 8 of 10; **the cap lands around session 14** — when the
  chain closes, restart with
  `scripts/session-loop.sh template-improvement-review --reset-cap`.
- Root `ROLLOVER_RELAUNCH=manual`, item override `auto`. Counter
  `.session-seq` = 13 after this launch.
- Session 12 cost ~100K with one agent; session 11 ~118K with two. Two
  agents fit, but keep prompts lean and load nothing beyond the list above.
- `test-session-loop.sh` D5b-g failed once on session 12 (timing race, 97 s
  hold), green on rerun. If it fails again on a tree that did not touch the
  alarm code, rerun once before sending it back.

## First actions

1. `scripts/context-budget.sh register --project template-improvement-review`
2. Confirm: `ps -p 72900`; `git -C .claude/worktrees/stage4 status --short`
   empty; `git log --oneline main..stage4` shows 7 commits (top 0a117c6).
3. Tracker: rows 4 and 6 → `in progress`, Started today; rewrite "Now".
4. For n in 4 6: `git worktree add -b s4-phase-<n> .claude/worktrees/s4-phase-<n> stage4`,
   then `scripts/context-budget.sh dispatch-open --project template-improvement-review --task phase-<n> --report /Users/kashif/Developer/experiments/ai-workspace-template/work/template-improvement-review/dispatch/phase-<n>.md`
   (absolute report path; the agents' worktrees are elsewhere).
5. Launch TWO `general-purpose` agents in one message (not
   `repo-navigator`, which is read-only). Each prompt carries, verbatim: its
   dispatch contract from step 4; its worktree path + branch and "every edit
   and command inside it"; the do-not-touch list from fleet-plan "One agent,
   one phase" (tracker, launcher, ledger, decisions, `.claude/settings.json`,
   never `context-budget.sh register|record|release` on any real project);
   its reads (its ticket, fleet-plan contract, phase-3 Interface+Decisions,
   design sections above, its Part 4 paragraph); the order of work (write
   `plans/phase-<n>.md` first with tasks/decisions/empty Evidence;
   test-first; run EVERY suite with `bash`, no `timeout`, all rc=0; fill
   Evidence; one commit on `s4-phase-<n>` with a `Decision:` trailer and the
   Co-Authored-By line; clean tree; do not merge).
   **File split (hazard "Two agents, one script"):** phase 4 owns
   `scripts/launch-next-session.sh`, `scripts/hooks/rollover-clear-seed.sh`
   (deleting it), `scripts/tests/test-launch-next-session.sh`,
   `test-emit-mode.sh`, `test-rollover-clear-seed.sh` (deleting it),
   `.gitignore` (seed-file line only). Phase 6 owns every other file under
   `scripts/hooks/`, the new dispatcher + adapter table, and
   `test-vendor-budget-hooks.sh`. **Neither edits `scripts/context-budget.sh`
   or `scripts/lib/session-lib.sh`**; a needed measurer change is reported
   as DONE_WITH_CONCERNS, not made. If phase 4 must touch
   `test-session-loop.sh` (the supervisor's bootstrap calls the launcher),
   it says so in its plan and keeps the edit minimal; phase 6 does not touch
   that suite. Phase 4's remedy text still naming `seq-sync` (launcher lines
   ~323/582/1217, pinned by T23i4/E8d) is phase 4's to rewrite.
6. On each DONE: verify `git -C .claude/worktrees/s4-phase-<n> status` clean
   and `git diff --stat stage4..s4-phase-<n>`; `dispatch-close --status DONE`.
   **Merge 4 first**: `git -C .claude/worktrees/stage4 merge --no-ff s4-phase-4`;
   run every suite there **in the background** (~10 min; never merge while
   it runs): `for t in scripts/tests/*.sh; do bash "$t" >log 2>&1; echo "$t rc=$?"; done`.
   Green → merge 6 the same way, suites again. Red → send the failure back to
   the same agent (SendMessage); never fix it in the parent. If phase 6
   finishes first, hold its merge until 4 is green.
7. Green: tracker rows 4 and 6 `done` + commits; copy each plan file's
   Decisions into `decisions.md` as Tier-2 notes; `git worktree remove` both
   agent worktrees and `git branch -D` both branches (check
   `git branch --merged stage4` first — `-d` compares against `main`).
   Commit bookkeeping on `main` (never a script). `record --label "wave C"`.
8. Roll over through the live supervisor, hands-off: `session-rollover`
   steps (prep → handoff block → this launcher rewritten for wave D →
   `seq-sync --session 13` → `record --label "rollover complete: …"` →
   `scripts/launch-next-session.sh template-improvement-review --emit --loop-mode handsoff --loop-reason "<why>"`
   as the very last command). Wave D = phase 5 alone, one agent; its first
   commit is the `main "$@"` wrapper on `session-loop.sh`. Use `git -C` and
   absolute paths; a `cd` into a worktree moves the harness cwd.
