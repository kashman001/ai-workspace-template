# Stage 4 tracker — session-management implementation

> Answers, at any moment: **what is the plan** (Part 4 of
> `session-management-review-findings.md`, line 765), **where are we** (the
> "Now" line), **what remains** (every row not `done`). Update at every phase
> boundary and every rollover; the launcher (`next-session.md`) points here.
> Status vocabulary: `todo` · `in progress` · `blocked: <why>` · `done`.

**Now:** Wave C done on `stage4` (phases 4 and 6 by two worktree agents; merged 26b214c then 4bb8a5d, all suites green there after each merge — one `test-session-lib.sh` S8 lock-race flake, green on rerun, second sighting). Next: session 14 runs wave D = phase 5 alone (supervisor, three verdicts); its first commit is the `main "$@"` wrapper on `session-loop.sh`. `main` frozen; supervisor pid 72900 live (chain 9 of 10 at session 13 — the cap lands at session 14; restart with `--reset-cap`).

**Sessions used so far in Stage 4:** 5 (session 9 planning; session 10 tickets + phase 0; session 11 fleet plan + wave A; session 12 wave B; session 13 wave C). Re-estimated after phase 3: one parent session per wave holds, so ~7 more (waves C–F + cutover, plus one spare); the delegated estimate of ~10–12 total stands.

| Phase | Deliverable | Status | Est. | Used | Started | Done | Commit | Notes |
|---|---|---|---|---|---|---|---|---|
| 0 | Live chain ended; relaunch default manual + per-item auto; counter import | done | 1 | 1 | 2026-09-16 | 2026-09-17 | 131142a | chain kept — main frozen, waves on `stage4`; see plans/phase-0.md |
| 1 | Record helper `scripts/lib/session-lib.sh` + test | done | 1 | 1 | 2026-09-17 | 2026-09-17 | 8cb363d (merge 1e6f857) | agent in worktree; `session_record_update`, 55 asserts, race 3×20 → seq 60. **S8 lock race flaked twice** (phase 6 agent on a clean 0a117c6 extract; parent on stage4 4bb8a5d with nothing else running: writer 2 rc=4 at iteration 0, total 59); green on rerun both times — if it bites a third time, the `mkdir` lock's stale sweep is racing, fix it in phase 7 |
| 2 | Fleet extraction `scripts/fleet.sh` (pure move) | done | 1 | 1 | 2026-09-17 | 2026-09-17 | f07f5ea (merge 5a4aec6) | measurer −189 lines (Part 4 said ~400); fleet.sh leans on `check` output — phase 3 must keep `runtime=`/`artifact=` lines |
| 3 | Measurer verbs on the record | done | 3 | 1 | 2026-09-17 | 2026-09-17 | d4fb3b6 (merge 0a117c6) | agent in worktree; measurer 1265→1017; registry record kept, side files gone; registry suite 187 asserts, numbering 18; `check` output kept for fleet.sh |
| 4 | Launcher on the record; first end-to-end slice | done | 3 | 1 | 2026-09-18 | 2026-09-18 | 5330f86 (merge 26b214c) | agent in worktree; launcher 1319→512, 12 gates, one record write; launcher suite 193 asserts, emit 54; `.session-seq` + sidecars now write-only mirrors for phase 5; clear-seed hook + suite deleted — stage4 `.claude/settings.json` SessionStart entry is a guarded no-op until phase 8 removes it; `--clear` prompt in `launch.pending.prompt` has no injector yet |
| 5 | Supervisor with three verdicts | todo | 3 | 0 | | | | `main "$@"` wrapper commit first |
| 6 | Hook dispatcher + adapter table | done | 2 | 1 | 2026-09-18 | 2026-09-18 | 67dc8a9 (merge 4bb8a5d) | agent in worktree; `context-budget-hook.sh` + `context-budget-adapters.conf` (6 rows); 7 wrappers are one-line shims at their old paths, lib kept; 47 fixtures, vendor suite 150 asserts; configs untouched (optional later: point them at the dispatcher, drop shims); docs prose is phase 8's |
| 7 | Probes rewritten; Claude Code acceptance | todo | 2 | 0 | | | | |
| 8 | Skill, docs, ADRs, ignore file, env, doc test | todo | 2 | 0 | | | | |
| cutover | Import + attended rollover + 2-session chain on this item | todo | 1 | 0 | | | | |

## How to update

- Starting a phase: write `plans/phase-<n>.md` (task-level plan), set `in progress`, fill Started.
- Ending a phase: all suites green, set `done`, fill Done + Commit, bump Used, rewrite the "Now" line.
- Every rollover: bump Used on the in-progress row and rewrite the "Now" line.
- Estimate drifting by more than 2 sessions: say so in Notes and in the ledger.
