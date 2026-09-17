# Stage 4 tracker — session-management implementation

> Answers, at any moment: **what is the plan** (Part 4 of
> `session-management-review-findings.md`, line 765), **where are we** (the
> "Now" line), **what remains** (every row not `done`). Update at every phase
> boundary and every rollover; the launcher (`next-session.md`) points here.
> Status vocabulary: `todo` · `in progress` · `blocked: <why>` · `done`.

**Now:** Wave B done on `stage4` (phase 3, measurer on the record, by one worktree agent; merged 0a117c6, all 21 suites green there). Next: session 13 runs wave C = phases 4 ∥ 6, two agents on `s4-phase-4` and `s4-phase-6` from `stage4`; merge 4 before 6. `main` frozen; supervisor pid 72900 live (chain 8 of 10 at session 12).

**Sessions used so far in Stage 4:** 4 (session 9 planning; session 10 tickets + phase 0; session 11 fleet plan + wave A; session 12 wave B). Re-estimated after phase 3: one parent session per wave holds, so ~7 more (waves C–F + cutover, plus one spare); the delegated estimate of ~10–12 total stands.

| Phase | Deliverable | Status | Est. | Used | Started | Done | Commit | Notes |
|---|---|---|---|---|---|---|---|---|
| 0 | Live chain ended; relaunch default manual + per-item auto; counter import | done | 1 | 1 | 2026-09-16 | 2026-09-17 | 131142a | chain kept — main frozen, waves on `stage4`; see plans/phase-0.md |
| 1 | Record helper `scripts/lib/session-lib.sh` + test | done | 1 | 1 | 2026-09-17 | 2026-09-17 | 8cb363d (merge 1e6f857) | agent in worktree; `session_record_update`, 55 asserts, race 3×20 → seq 60 |
| 2 | Fleet extraction `scripts/fleet.sh` (pure move) | done | 1 | 1 | 2026-09-17 | 2026-09-17 | f07f5ea (merge 5a4aec6) | measurer −189 lines (Part 4 said ~400); fleet.sh leans on `check` output — phase 3 must keep `runtime=`/`artifact=` lines |
| 3 | Measurer verbs on the record | done | 3 | 1 | 2026-09-17 | 2026-09-17 | d4fb3b6 (merge 0a117c6) | agent in worktree; measurer 1265→1017; registry record kept, side files gone; registry suite 187 asserts, numbering 18; `check` output kept for fleet.sh |
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
