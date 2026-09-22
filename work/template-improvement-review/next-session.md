# Next Session — template-improvement-review (Stage 4: wave F, phase 8, one agent)

> **This file is the LAUNCHER (catch-up prompt).** Forward-only, REPLACED at
> each rollover. Past-tense provenance lives in `handoff.md`.
> Convention: docs/work-directory-conventions.md.

## Mission

**Stage 4 by a fleet, one wave per session.** Plan: `plans/fleet-plan.md`
(read it whole; one screen). Position: waves A–E done (phases 1–7 merged to
`stage4`, head 5c7edc0, 22 commits ahead of `main`); **this session runs
wave F = phase 8** (skill, docs, ADRs, ignore file, env, doc test, plus the
mirror removal phase 7 deferred), one agent in its own worktree; the parent
never edits a script. Then roll over hands-off; session 17 is the cutover
(attended: import + attended rollover + 2-session chain on this item).

**Rules (user, binding):** successor sessions start on their own — rollover
with `--loop-mode handsoff`, no per-wave okay. Every doc the user reads:
short, plain, self-contained (memory `review-docs-plain-language`).

**No human in the loop:** everything in phase 8 is docs, skill, ADR, config
and script edits plus suite runs; all of it happens unattended in the agent's
worktree. Nothing in this wave needs a login. If the agent hits a genuine
design fork that only the user can settle, it finishes everything else,
writes the question into `plans/phase-8.md` under "Questions for the user",
returns DONE_WITH_CONCERNS, and this session rolls over with
`--loop-mode interactive` carrying the question verbatim. Never block the
wave on it.

## Read these, in order

1. `work/template-improvement-review/plans/fleet-plan.md` (whole).
2. `work/template-improvement-review/stage4-tracker.md` (whole; row 7 notes
   name what phase 7 deferred).
3. `issues/09-phase-8-skill-docs-adrs.md` (under
   `work/template-improvement-review/`).
4. In the `stage4` worktree (`.claude/worktrees/stage4/`),
   `work/template-improvement-review/plans/phase-7.md`: "Concerns for the
   parent" only (Concern 1 lists every reader and test pin of the three
   mirrors; 3 and 4 are two docs lines phase 8 writes). Then
   `plans/phase-5.md` "Decisions" 1–2 and 4 (why the mirrors exist; the
   `--clear` injector belongs to phase 8's skill) and `plans/phase-4.md`
   "Deleted" (lines ~116–125: flags and files whose prose mentions phase 8
   removes).
5. `session-management-review-findings.md`: only the `**Phase 8 —`
   paragraph (grep it, near line 806) and the ADR list at lines ~660–670
   (grep `ADR-001`).
6. `handoff.md` top block only.

## Do NOT reload

Findings Parts 1–4 beyond the pointers above, stage1/stage2/stage3 reports,
`review.md`, `decisions.md` (append only), backlog HTML whole, the big
scripts whole (the agent greps them, not you), `plans/phase-{1,2,3,6}.md`
(settled), `dispatch/*.md` (past reports), `evaluation/stage2-probes.md`
(phase 7 consumed it).

## State snapshot

- `main` = 8b4837e (session 15 bookkeeping) + this rollover's commit; clean;
  ahead of origin (do not push).
- `stage4` = 5c7edc0, 22 commits ahead of `main`, checked out ONLY at
  `.claude/worktrees/stage4` (clean). Never check it out in the primary tree.
- Chain restarted by the human at session 15 with `--reset-cap`; the
  supervisor runs `--max-sessions 15` from frozen `main` (old
  `session-loop.sh`). Confirm with `pgrep -f session-loop.sh` and
  `scripts/context-budget.sh supervised --project template-improvement-review`
  (0 = supervised, stage at the end; 1 = not supervised, the human pasted the
  prompt — then finish with the paste-ready prompt instead of `--emit`).
- Root `ROLLOVER_RELAUNCH=manual`, item override `auto`. Counter
  `.session-seq` = 16 after this launch.
- Session 15 cost ~59K→~117K with one agent (~295K agent tokens, 68 min).
- The `test-session-lib.sh` lock race is FIXED (phase 7): any lock-race red
  is a real failure now, never a rerun.
- **Phase 8 owns, on top of ticket 09:** (a) the mirror removal — move
  `context-budget.sh supervised` to `chain.supervisor`, the launcher's
  `invoked_by_supervisor` to `chain.supervisor.pid`, `budget_hook_should_exit`
  and `successor_advisory` to `staged`/`staged.by`; then delete the
  `.session-loop`, `.next-command`, `.session-seq.bump.json` writes and their
  pins (decide what `--emit` prints once `.next-command` is gone — the old
  supervisor on `main` never reads stage4's files, so nothing live breaks);
  the launcher's legacy `.chain-closed` read; (b) stage4
  `.claude/settings.json` clear-seed SessionStart entry (guarded no-op);
  (c) prose naming `--bg`/`--unstage`/`.rollover-options`/`.pending-clear-seed`
  in `skills/session-rollover/SKILL.md`, `docs/context-budget.md`, ADR-0009,
  `CONTEXT.md`; (d) stale `.gitignore` lines for deleted state files; (e) the
  `--clear` prompt injector (phase 5 decision 4; phase 4 deleted the seed
  hook); (f) two docs lines: scripts resolve their root via
  `git rev-parse --git-common-dir` so a worktree run drives the main checkout
  (`docs/operational-knowledge.md`), and supervised sessions' shells inherit
  `TF_SESSION_LOOP=1` (a hand `--emit` from a subagent is refused
  `no_supervisor`). Optional, only if cheap: vendor configs pointing at the
  dispatcher instead of the shims.

## First actions

1. `scripts/context-budget.sh register --project template-improvement-review`
2. Confirm: `git -C .claude/worktrees/stage4 status --short` empty;
   `git log --oneline main..stage4` shows 22 commits (top 5c7edc0); the
   supervisor check above.
3. Tracker: row 8 → `in progress`, Started today; rewrite "Now".
4. `git worktree add -b s4-phase-8 .claude/worktrees/s4-phase-8 stage4`, then
   `scripts/context-budget.sh dispatch-open --project template-improvement-review --task phase-8 --report /Users/kashif/Developer/experiments/ai-workspace-template/work/template-improvement-review/dispatch/phase-8.md`
   (absolute report path). Use `git -C` and absolute paths everywhere; a
   `cd` into a worktree moves the harness cwd (`docs/operational-knowledge.md`);
   if it happens, `cd` back to the root in the next command.
5. Launch ONE `general-purpose` agent (not `repo-navigator`). Its prompt
   carries, verbatim: the dispatch contract from step 4; its worktree path +
   branch and "every edit and command inside it"; the do-not-touch list from
   fleet-plan "One agent, one phase" (tracker, launcher, ledger, decisions,
   the MAIN checkout's `.claude/settings.json`, never
   `context-budget.sh register|record|release|close` on any real project);
   its reads (ticket 09, fleet-plan contract, phase-7 Concerns, phase-5
   Decisions 1–2 and 4, phase-4 Deleted, its Part 4 paragraph + ADR list);
   the no-human clause above; the phase 8 ownership list (a)–(f) above; the
   order of work (write `plans/phase-8.md` first with tasks/decisions/empty
   Evidence; mirror removal test-first as its own commits before the prose;
   run EVERY suite with `bash`, no `timeout`, all rc=0, plus
   `python3 scripts/tests/test-check-ledger.py` and the ticket's doc test;
   commits on `s4-phase-8` with a `Decision:` trailer and the Co-Authored-By
   line; clean tree; do not merge). **Files:** phase 8 owns the skill, docs,
   ADRs, `.gitignore`, env files, the stage4 `.claude/settings.json`, the
   doc test, and — for the mirror removal — the named functions in
   `scripts/context-budget.sh`, `scripts/launch-next-session.sh`,
   `scripts/session-loop.sh`, `scripts/hooks/context-budget-hook-lib.sh` and
   their pins under `scripts/tests/`. Every doc it writes: short, plain,
   self-contained. Expect ~300K agent tokens.
6. On DONE: verify `git -C .claude/worktrees/s4-phase-8 status` clean and
   `git diff --stat stage4..s4-phase-8`; `dispatch-close --status <S>`.
   `git -C .claude/worktrees/stage4 merge --no-ff s4-phase-8`; run every
   suite there **in the background** (~10 min; never merge while it runs):
   `for t in scripts/tests/*.sh; do bash "$t" >log 2>&1; echo "$t rc=$?"; done`
   plus the Python ledger suite and the doc test. Red → send it back to the
   same agent (SendMessage); never fix it in the parent.
7. Green: tracker row 8 `done` + commits; copy the plan's Decisions into
   `decisions.md` as a Tier-2 note; `git worktree remove` + `git branch -D`
   (check `git branch --merged stage4` first). Commit bookkeeping on `main`
   (never a script). `record --label "wave F"`.
8. Roll over: `session-rollover` steps (prep → handoff block → this launcher
   rewritten for the cutover, session 17, **attended**: the human must be
   present for the import + attended rollover + 2-session chain, so write the
   cutover launcher with an explicit "wait for the human" clause →
   `seq-sync --session 16` → `record --label "rollover complete: …"` → if
   supervised, `scripts/launch-next-session.sh template-improvement-review --emit --loop-mode interactive --loop-reason "<why>"`
   as the very last command (interactive, because the cutover is attended);
   if not supervised, end with the paste-ready prompt.
