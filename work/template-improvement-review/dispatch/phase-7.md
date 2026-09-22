# Dispatch report — phase 7 (probes and acceptance)

Worktree `.claude/worktrees/s4-phase-7`, branch `s4-phase-7` from `stage4` (256b36b).

## [gen 1] 2026-09-21 — orientation done, plan being written

Finished: read the ticket, fleet contract, phase-4/5 plans, the probe criteria
(stage2-design-part2, stage3-scenario-evaluation, stage3-design-v2), the
supervisor, launcher, measurer (`supervised`, `successor_advisory`, `register`),
hook lib (`budget_hook_should_exit`), fleet.sh, and the three suites the twins
reuse. Login proven from the worktree: `claude -p "Reply with exactly: ok"` → `ok` rc 0.

Findings that shape the plan:
- Every script resolves its root through `git rev-parse --git-common-dir`, so
  from the worktree they drive the MAIN checkout's `work/`; only the hook lib
  honours `WORKSPACE_ROOT`. The acceptance therefore runs in a `git clone` of
  the branch under the scratchpad (item `work/s4-scratch/` inside the clone).
- `test-session-loop.sh` already pins the seeded spent stage (R6) and
  `no_supervisor` (R7); the phase-7 cases will be end-to-end runs in the twin suite.
- Mirror removal: the `.session-loop` marker has a third reader outside the
  editable places (launcher `invoked_by_supervisor`) → leaving it to phase 8.

Next: write `plans/phase-7.md`, commit; lock fix (test first, lib suite ×5).
Open items: none yet.

## [gen 1] — lock fix, probes and twins committed

Finished: plan (54b623c); lock fix `scripts/lib/session-lib.sh` + S10i–S10q,
lib suite 5× rc=0 (fae4746); probes `evaluation/probes/{lib,v1-attended-rollover,v3-chain,v10-fleet}.sh`
and `scripts/tests/test-probe-twins.sh` (37 asserts: T1/T3/T10 twins + H1 spent
stage + H2 refused hand stage), green 3×; test-session-loop 105/105, lib 64/64.
Found on the way: my shell inherits `TF_SESSION_LOOP=1`/`TF_SESSION_LOOP_PROJECT`
from the parent's live chain — the probe lib and the suite unset the chain env.
Mirror removal: left to phase 8 (plan decision 5).
Next: Claude Code acceptance in a scratch clone (V1 with `claude -p`, V3 under
expect), then the full suite run and Evidence.
Open items: none.

## [gen 1] — acceptance runs green

Finished: V1 attended rollover with the real `claude` (18/18; two real session
ids, `run:` line executed as #2, SessionEnd released #2) and V3 supervised
chain `--max-sessions 2 --driver expect` (15/15; `staged seq=1`, `staged seq=2`,
`cap seq=3`; both children ended by the turn-end hook, rc 143). Workspace: a
clone of the branch at f2cebb2 under the scratchpad (root resolution goes
through git-common-dir; see plan decision 3). No stray claude/expect process.
Next: full suite rc lines (running), Evidence + final commit.
Open items: none.

## [gen 1] — done

Every suite rc=0 (22 lines, incl. the new test-probe-twins.sh) and
check-ledger; Evidence and Concerns written to plans/phase-7.md and
committed. Branch s4-phase-7 not merged; tree clean; no stray process.
Mirror decision: left to phase 8 (exact places listed under Concerns 1).
Open items: none.
