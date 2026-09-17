# Stage 4 tracker — session-management implementation

> Answers, at any moment: **what is the plan** (Part 4 of
> `session-management-review-findings.md`, line 765), **where are we** (the
> "Now" line), **what remains** (every row not `done`). Update at every phase
> boundary and every rollover; the launcher (`next-session.md`) points here.
> Status vocabulary: `todo` · `in progress` · `blocked: <why>` · `done`.

**Now:** Wave A done on `stage4` (phases 1 ∥ 2 by two worktree agents, merged 1e6f857 + 5a4aec6, all suites green there). Next: session 12 runs wave B (phase 3, measurer on the record) as one agent on `s4-phase-3` from `stage4`; parent merges in `.claude/worktrees/stage4`. `main` frozen; supervisor pid 72900 live (chain 7 of 10 at session 11).

**Sessions used so far in Stage 4:** 3 (session 9 planning; session 10 tickets + phase 0; session 11 fleet plan + wave A). Estimate: 15–19 parent sessions if the parent edits; ~10–12 if phases are delegated to subagents. Re-estimate after phase 3.

| Phase | Deliverable | Status | Est. | Used | Started | Done | Commit | Notes |
|---|---|---|---|---|---|---|---|---|
| 0 | Live chain ended; relaunch default manual + per-item auto; counter import | done | 1 | 1 | 2026-09-16 | 2026-09-17 | 131142a | chain kept — main frozen, waves on `stage4`; see plans/phase-0.md |
| 1 | Record helper `scripts/lib/session-lib.sh` + test | done | 1 | 1 | 2026-09-17 | 2026-09-17 | 8cb363d (merge 1e6f857) | agent in worktree; `session_record_update`, 55 asserts, race 3×20 → seq 60 |
| 2 | Fleet extraction `scripts/fleet.sh` (pure move) | done | 1 | 1 | 2026-09-17 | 2026-09-17 | f07f5ea (merge 5a4aec6) | measurer −189 lines (Part 4 said ~400); fleet.sh leans on `check` output — phase 3 must keep `runtime=`/`artifact=` lines |
| 3 | Measurer verbs on the record | todo | 3 | 0 | | | | |
| 4 | Launcher on the record; first end-to-end slice | todo | 3 | 0 | | | | |
| 5 | Supervisor with three verdicts | todo | 3 | 0 | | | | `main "$@"` wrapper commit first |
| 6 | Hook dispatcher + adapter table | todo | 2 | 0 | | | | |
| 7 | Probes rewritten; Claude Code acceptance | todo | 2 | 0 | | | | |
| 8 | Skill, docs, ADRs, ignore file, env, doc test | todo | 2 | 0 | | | | |
| cutover | Import + attended rollover + 2-session chain on this item | todo | 1 | 0 | | | | |

## How to update

- Starting a phase: write `plans/phase-<n>.md` (task-level plan), set `in progress`, fill Started.
- Ending a phase: all suites green, set `done`, fill Done + Commit, bump Used, rewrite the "Now" line.
- Every rollover: bump Used on the in-progress row and rewrite the "Now" line.
- Estimate drifting by more than 2 sessions: say so in Notes and in the ledger.
