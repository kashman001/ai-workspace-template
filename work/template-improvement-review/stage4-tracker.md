# Stage 4 tracker — session-management implementation

> Answers, at any moment: **what is the plan** (Part 4 of
> `session-management-review-findings.md`, line 765), **where are we** (the
> "Now" line), **what remains** (every row not `done`). Update at every phase
> boundary and every rollover; the launcher (`next-session.md`) points here.
> Status vocabulary: `todo` · `in progress` · `blocked: <why>` · `done`.

**Now:** Tickets cut (issues/01–10, commit 0c1dd35). Phase 0 in progress: tasks 2–5 done and tested (env flip + per-item override, jq pin, notify path, import script); task 1 (end the chain) completes when session 10 is closed by hand with nothing staged. Next: session 11 (by hand) confirms the chain ended, marks phase 0 done, writes `plans/fleet-plan.md` and runs the phases as a fleet, one wave per session (1∥2 → 3 → 4∥6 → 5 → 7 → 8 → cutover), rolling over through the live supervisor; user's direction 2026-09-17.

**Sessions used so far in Stage 4:** 2 (session 9 planning; session 10 tickets + phase 0). Estimate: 15–19 parent sessions if the parent edits; ~10–12 if phases are delegated to subagents. Re-estimate after phase 3.

| Phase | Deliverable | Status | Est. | Used | Started | Done | Commit | Notes |
|---|---|---|---|---|---|---|---|---|
| 0 | Live chain ended; relaunch default manual + per-item auto; counter import | in progress | 1 | 1 | 2026-09-16 | | | chain KEPT (amended 2026-09-17: main frozen, waves on `stage4`); tasks 2–5 done, see plans/phase-0.md |
| 1 | Record helper `scripts/lib/session-lib.sh` + test | todo | 1 | 0 | | | | |
| 2 | Fleet extraction `scripts/fleet.sh` (pure move) | todo | 1 | 0 | | | | |
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
