# Cutover runbook — template-improvement-review

> Written by session 17 on 2026-09-21. One page. You (the human) run these
> steps in order with session 18 at the keyboard next to you. Every step
> was rehearsed in a scratch clone the same day: the merge is clean, the
> import works, all 23 test suites pass on the merged tree (evidence at the
> end). Nothing here was run on the live checkout yet.

## What this does

Moves this work item from the old session scripts (on `main`) to the new
ones (on `stage4`, 30 commits, phases 1–8). Four things happen: end the old
supervisor, merge, import the session counter into the new record, then
prove the new scripts twice — one attended `--clear` rollover and one
supervised chain of two sessions.

## What you should see before starting

- The old supervisor's terminal shows:
  `[session-loop] session #17 ended. Press Enter to start #18 (Ctrl-C to stop).`
- `git status --short` on `main` is empty. `stage4` = `9cfa3d5`, checked out
  only at `.claude/worktrees/stage4`.

## Step 0 — end the old chain (do NOT press Enter)

At that prompt press **Ctrl-C**. The old supervisor prints
`interrupted at the pause — ending the chain` and exits. Check:

```sh
pgrep -f session-loop.sh     # prints nothing
```

Why: the old supervisor and the old hooks run scripts straight from the
`main` checkout. Bash reads a script while it runs, so merging under a live
supervisor corrupts it. Nothing may run from `main` during step 1.

If you already pressed Enter: in that session 18 type `/exit` without doing
anything. The old supervisor logs a deliberate quit and ends. Then continue.

## Step 1 — merge stage4 into main

From the repo root:

```sh
git status --short                                   # must be empty
git merge --no-ff stage4 -m "cutover: merge stage4 into main (Stage 4 phases 1-8)"
git log --oneline -1
```

Expect `Merge made by the 'ort' strategy`, 115 files changed, no conflict
(rehearsal: one automatic merge in `docs/operational-knowledge.md`, nothing
by hand). A conflict means stop; nothing else in this file applies until it
is resolved.

## Step 2 — import the counter, remove the old state files

```sh
scripts/import-session-seq.sh template-improvement-review
# expect: import-session-seq: imported seq=18 (work/template-improvement-review/session-state.json)
scripts/import-session-seq.sh template-improvement-review
# expect: import-session-seq: noop seq=18 already imported (...)
cat work/template-improvement-review/session-state.json
# expect: {"schema": 1, "seq": 18}
```

The number is 18, not 17: session 17's own rollover advanced the old counter
when it staged session 18. Now delete the old scripts' state files (the new
scripts never read them, and the merged `.gitignore` no longer hides them):

```sh
cd work/template-improvement-review
rm -f .active-session .rollover-options .session-seq .session-seq.provenance.json \
      .session-seq.bump.json .session-loop .session-loop.budget .next-command.json \
      .next-command.stale .rollover-complete .session-loop.alarm-stop .chain-closed \
      .pending-clear-seed
cd -
git status --short           # empty again
```

Keep `.agent-dispatch/` (fleet records) and `.session-loop.log`.

Optional, safe: `git worktree remove .claude/worktrees/stage4 && git branch -d stage4`.

## Step 3 — start session 18 attended (no supervisor)

From the repo root run `claude`, then paste:

```
Work item template-improvement-review - rollover session #18. Read `work/template-improvement-review/next-session.md` and continue from **First actions**.
```

Its first action registers against the record. What you should see:

```sh
scripts/context-budget.sh register --project template-improvement-review   # says filled
jq '.session.seq, .session.pid' work/template-improvement-review/session-state.json   # 18, a number
scripts/context-budget.sh supervised --project template-improvement-review   # exit 1 = not supervised
```

A missing pid would make step 4 refuse `runtime_path_unsupported`; if so,
re-run the register line from inside the session's own shell.

## Step 4 — the attended `--clear` rollover (session 18 → 19)

Session 18 writes its ledger block (`# Session Handoff — 18`) and a new
`next-session.md` for session 19, then runs:

```sh
scripts/launch-next-session.sh template-improvement-review --check    # exit 0
scripts/launch-next-session.sh template-improvement-review --clear
```

It prints the bootstrap prompt for #19 and
`NOW PRESS /clear and type nothing`. You type `/clear`.

**What to look for:** the first thing in the cleared session is the
SessionStart hook output, and it must contain the line
`Work item template-improvement-review - rollover session #19. Read ...`.
That line is the seed. If the session then waits for input, type `continue`;
the seed is already in its context. Check the record:

```sh
jq '.session.seq, .launch.pending, .launch.predecessor.disposition' work/template-improvement-review/session-state.json
# expect: 19, null, "rolled_over"
```

**Fallback if the seed line is absent** (phase-8 plan, Concern 2): paste the
#19 bootstrap prompt yourself, and note in the tracker's cutover row that the
seed did not show; the fix is for `register` to return the prompt in a
`hookSpecificOutput.additionalContext` envelope, a later agent's job. If
`.session.seq` is still `null` after `/clear`, the pid did not match: run
`scripts/context-budget.sh register --project template-improvement-review`
inside the session (it binds as 19, `filled`).

## Step 5 — session 19 ends so the chain can start

A chain stages its own first session, and the bootstrap refuses while a live
session owns the item. So session 19 writes its ledger block (`— 19`) and the
launcher for session 20, then ends through the stop door and exits:

```sh
scripts/context-budget.sh close --project template-improvement-review   # exit 0
```

then `/exit`. Check: `jq '.seq, .session.ended, .staged'` shows 19, a
non-null block, null.

## Step 6 — the supervised chain, two sessions

```sh
scripts/session-loop.sh template-improvement-review --max-sessions 2
```

Sessions 20 and 21 run in this terminal, one after the other, and each knows
its job from its launcher (20: confirm the chain, bookkeeping, roll over
`--emit --loop-mode handsoff`; 21: final evidence, tracker rows, roll over
`--emit`). Lines to expect, also in `work/template-improvement-review/.session-loop.log`:

| Line | Meaning |
| --- | --- |
| `session-loop: staging the first session` | bootstrap; session 20 starts |
| `session-loop: verdict=staged seq=20` | 20 rolled over; 21 starts |
| `session-loop: verdict=cap seq=22` | 21 rolled over; the cap of 2 is reached; 22 stays staged for a later `--reset-cap` restart |
| or `session-loop: verdict=quit_plain seq=21` | 21 exited without staging; the chain is closed (`--reopen` to run it again) |

Supervisor exit code 0 either way. Any `broken reason=` or `refused reason=`
line: stop and read the remedy printed on that same line. A session shorter
than 60 s is reported `broken staged_invalid leg=lifetime`; both sessions
take longer, or add `--min-lifetime 0`.

## Done looks like

- Record: `.chain.used` = 2, `.launch.predecessor.disposition` = `rolled_over`.
- Ledger: blocks 18–21 on top, `scripts/check-ledger.py work/template-improvement-review` exit 0.
- Tracker: cutover row `done` with the merge commit; ticket `issues/10-cutover.md` boxes ticked.
- Follow-up for any later session (an agent's job, one commit): delete
  `scripts/import-session-seq.sh`, `scripts/tests/test-import-session-seq.sh`
  and its row under "Reason codes" in `docs/context-budget.md` (the
  doc-consistency test pins that row). The `.session-seq*` ignore entries
  are already gone.

## Blockers

None found.

## Rehearsal evidence (session 17, 2026-09-21)

Scratch clone of `main` (a0dbf15) at the session's scratchpad,
`cutover-rehearsal/`; `TF_SESSION_*` unset.

- Merge: `git merge --no-ff origin/stage4` → `Merge made by the 'ort' strategy`,
  115 files changed, 6276 insertions, 9029 deletions; `docs/operational-knowledge.md`
  auto-merged; no conflict; rc 0.
- Import with the live counter (17) copied in:
  `imported seq=17` (rc 0), second run `noop seq=17 already imported` (rc 0);
  record `{"schema": 1, "seq": 17}`.
- Finding: after the import, `.session-seq` showed as untracked in the clone.
  The merged `.gitignore` keeps only `work/*/session-state.json` (+ `.lock/`)
  and `.session-loop.log`; the `.session-seq*` entries were dropped by phase 8.
  Hence the delete list in step 2.
- Suites, each run with `bash`, all rc 0: test-agent-entrypoints,
  test-attach-session, test-check-dependencies, test-context-budget-registry,
  test-doc-consistency, test-emit-mode, test-fleet-children,
  test-fleet-dispatch-contract, test-fleet-dispatch-records,
  test-import-session-seq, test-launch-next-session, test-link-local-work,
  test-parameterization, test-probe-twins, test-session-lib,
  test-session-loop-notify, test-session-loop, test-session-numbering,
  test-statusline-context-budget, test-template-instantiation,
  test-turn-end-exit, test-vendor-budget-hooks (22 shell) and
  `test-check-ledger.py` (Python). No `FAIL` line in any output.
