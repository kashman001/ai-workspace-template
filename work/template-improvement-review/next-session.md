# Next Session — template-improvement-review (Stage 4: wave E, phase 7, one agent)

> **This file is the LAUNCHER (catch-up prompt).** Forward-only, REPLACED at
> each rollover. Past-tense provenance lives in `handoff.md`.
> Convention: docs/work-directory-conventions.md.

## Mission

**Stage 4 by a fleet, one wave per session.** Plan: `plans/fleet-plan.md`
(read it whole; one screen). Position: waves A–D done (phases 1–6 merged to
`stage4`, head 256b36b, 16 commits ahead of `main`); **this session runs
wave E = phase 7** (probes on record fields, stub-runtime twins, Claude Code
acceptance, and the `session-lib.sh` lock fix), one agent in its own worktree;
the parent never edits a script. Then roll over hands-off; session 16 runs
wave F (phase 8).

**Rules (user, binding):** successor sessions start on their own — rollover
with `--loop-mode handsoff`, no per-wave okay. Every doc the user reads:
short, plain, self-contained (memory `review-docs-plain-language`).

**No human in the loop:** the probe rewrite, the stub twins, the lock fix and
every suite run happen unattended in the agent's worktree. The Claude Code
acceptance runs (attended rollover + `--max-sessions 2` chain on a throwaway
item) need a logged-in Claude Code process: the agent may drive them headless
from its worktree if it can prove the login works (`claude -p` on a trivial
prompt first); if it cannot, it finishes everything else, records exactly which
commands the human must run in `plans/phase-7.md`, returns DONE_WITH_CONCERNS,
and this session rolls over with `--loop-mode interactive` carrying that
request verbatim. Never block the whole wave on the acceptance runs.

## Read these, in order

1. `work/template-improvement-review/plans/fleet-plan.md` (whole).
2. `work/template-improvement-review/stage4-tracker.md` (whole; row 1 notes
   carry the lock-race fix, row 5 notes the two mirrors phase 5 left).
3. `issues/08-phase-7-probes-and-acceptance.md` (under
   `work/template-improvement-review/`).
4. In the `stage4` worktree (`.claude/worktrees/stage4/`),
   `work/template-improvement-review/plans/phase-5.md`: "Interface", "Decisions"
   1–2 and 5, and "Concerns for the parent" (what the supervisor writes and
   reads; the `.session-loop` marker and `.next-command`/bump mirrors still
   written; `staged_invalid leg=spent`). Also `plans/phase-4.md` lines 22–60
   ("Interface": the launcher's gates and record write) if the agent needs the
   launcher side.
5. `evaluation/stage2-probes.md` (the chain probe and fleet probe the ticket
   rewrites) and `evaluation/stage3-design-v2.md` record table (lines 50–58)
   + the gate table's two supervisor rows (grep `supervisor start`).
6. `session-management-review-findings.md`: only the `**Phase 7 —` paragraph
   (grep it, ~line 805).
7. `handoff.md` top block only.

## Do NOT reload

Findings Parts 1–4 beyond the one paragraph, stage1/stage3 reports,
`review.md`, `decisions.md` (append only), backlog HTML whole, the big
scripts whole (the agent greps them, not you), `plans/phase-{1,2,3,4,6}.md`
beyond the pointers above (settled), `dispatch/*.md` (past reports).

## State snapshot

- `main` = d14cc8e (session 14 bookkeeping) + this rollover's commit; clean;
  ahead of origin (do not push).
- `stage4` = 256b36b, 16 commits ahead of `main`, checked out ONLY at
  `.claude/worktrees/stage4` (clean). Never check it out in the primary tree.
- **Chain restarted by the human with `--reset-cap`.** Session 14 was 10 of
  10; its `--emit` tripped the cap and the old supervisor (pid 72900, old
  `session-loop.sh` on frozen `main`) reported `cap` and stopped. This session
  exists because the human ran `scripts/session-loop.sh
  template-improvement-review --reset-cap`; confirm with `pgrep -f
  session-loop.sh` and `scripts/context-budget.sh supervised --project
  template-improvement-review` (0 = supervised, stage at the end; 1 = not
  supervised, the human pasted the prompt — then finish with the paste-ready
  prompt instead of `--emit`).
- Root `ROLLOVER_RELAUNCH=manual`, item override `auto`. Counter
  `.session-seq` = 15 after this launch.
- Session 14 cost ~101K at prep with one agent (~288K agent tokens, 28 min).
- Known flake, now a fix, not a rerun: `test-session-lib.sh` S8/S10a lock
  race (three sightings; `scripts/lib/session-lib.sh:60-61` on `stage4`: when
  `mkdir` fails and the lock dir is gone by the `-d` check, retry instead of
  refusing `record_unwritable`). **Phase 7 owns this one lib edit** — say so
  in its plan; nothing else in the lib changes.
- Phase 5 left two mirrors written because their readers are the measurer
  (`supervised` reads `.session-loop`) and hook-lib (`budget_hook_should_exit`
  reads `.next-command` + `.session-seq.bump.json`). Phase 7's plan decides:
  move those reads to `chain.supervisor` / `staged.by` and delete the mirrors
  now (touches `context-budget.sh` and `scripts/hooks/context-budget-hook-lib.sh`,
  both otherwise frozen), or leave it to phase 8. Either way the plan says
  which, with the rejected alternative.
- Carry-overs, not this wave's: stage4 `.claude/settings.json` clear-seed
  SessionStart entry (phase 8); prose naming `--bg`/`--unstage`/
  `.rollover-options` in skill/docs/ADR-0009/CONTEXT.md (phase 8); vendor
  configs naming shim paths (optional); stale `.gitignore` lines (phase 8);
  `--clear` prompt injector (phase 8's skill, per phase 5 decision 4).

## First actions

1. `scripts/context-budget.sh register --project template-improvement-review`
2. Confirm: `git -C .claude/worktrees/stage4 status --short` empty;
   `git log --oneline main..stage4` shows 16 commits (top 256b36b); the
   supervisor check above.
3. Tracker: row 7 → `in progress`, Started today; rewrite "Now".
4. `git worktree add -b s4-phase-7 .claude/worktrees/s4-phase-7 stage4`, then
   `scripts/context-budget.sh dispatch-open --project template-improvement-review --task phase-7 --report /Users/kashif/Developer/experiments/ai-workspace-template/work/template-improvement-review/dispatch/phase-7.md`
   (absolute report path). Use `git -C` and absolute paths everywhere; a
   `cd` into a worktree moves the harness cwd (`docs/operational-knowledge.md`);
   if it happens, `cd` back to the root in the next command.
5. Launch ONE `general-purpose` agent (not `repo-navigator`). Its prompt
   carries, verbatim: the dispatch contract from step 4; its worktree path +
   branch and "every edit and command inside it"; the do-not-touch list from
   fleet-plan "One agent, one phase" (tracker, launcher, ledger, decisions,
   `.claude/settings.json`, never `context-budget.sh register|record|release|close`
   on any real project); its reads (ticket, fleet-plan contract, phase-5
   Interface + Decisions 1–2, 5 + Concerns, stage2-probes.md, design record
   table + supervisor gate rows, its Part 4 paragraph); the no-human clause
   above; the order of work (write `plans/phase-7.md` first with tasks/
   decisions/empty Evidence; test-first; the lock fix as its own small commit
   with the lib suite run 5× green; run EVERY suite with `bash`, no `timeout`,
   all rc=0, plus `python3 scripts/tests/test-check-ledger.py`; fill Evidence
   with record contents and verdicts; commits on `s4-phase-7` with a
   `Decision:` trailer and the Co-Authored-By line; clean tree; do not merge).
   **Files:** phase 7 owns the probes (wherever `stage2-probes.md` puts them;
   new stub-twin suites go under `scripts/tests/`), the throwaway acceptance
   item `work/s4-scratch/` (never committed), the one lock-loop edit in
   `scripts/lib/session-lib.sh` + its suite, and — only if its plan takes the
   mirror removal — the `supervised` verb in `scripts/context-budget.sh`,
   `budget_hook_should_exit` in `scripts/hooks/context-budget-hook-lib.sh`, the
   mirror writes in `scripts/launch-next-session.sh`/`session-loop.sh`, and
   their test pins. Nothing else in the measurer or hooks; a wider need →
   DONE_WITH_CONCERNS. Expect ~300K agent tokens.
6. On DONE: verify `git -C .claude/worktrees/s4-phase-7 status` clean and
   `git diff --stat stage4..s4-phase-7`; `dispatch-close --status <S>`.
   `git -C .claude/worktrees/stage4 merge --no-ff s4-phase-7`; run every
   suite there **in the background** (~10 min; never merge while it runs):
   `for t in scripts/tests/*.sh; do bash "$t" >log 2>&1; echo "$t rc=$?"; done`
   plus the Python ledger suite. Red → send it back to the same agent
   (SendMessage); never fix it in the parent. A lock-race red after the fix is
   a real failure, not a flake.
7. Green: tracker row 7 `done` + commits; copy the plan's Decisions into
   `decisions.md` as a Tier-2 note; `git worktree remove` + `git branch -D`
   (check `git branch --merged stage4` first). Commit bookkeeping on `main`
   (never a script). `record --label "wave E"`.
8. Roll over: `session-rollover` steps (prep → handoff block → this launcher
   rewritten for wave F = phase 8 alone → `seq-sync --session 15` →
   `record --label "rollover complete: …"` → if supervised,
   `scripts/launch-next-session.sh template-improvement-review --emit --loop-mode handsoff --loop-reason "<why>"`
   as the very last command (`--loop-mode interactive` only if the acceptance
   runs need the human, carrying the exact commands); if not supervised, end
   with the paste-ready prompt.
