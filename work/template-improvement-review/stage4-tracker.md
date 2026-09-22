# Stage 4 tracker — session-management implementation

> Answers, at any moment: **what is the plan** (Part 4 of
> `session-management-review-findings.md`, line 765), **where are we** (the
> "Now" line), **what remains** (every row not `done`). Update at every phase
> boundary and every rollover; the launcher (`next-session.md`) points here.
> Status vocabulary: `todo` · `in progress` · `blocked: <why>` · `done`.

**Now:** Wave E done on `stage4` (phase 7 by one worktree agent; merged 5c7edc0, all 21 shell suites + ledger suite green there after the merge, lock race gone). Next: session 16 runs wave F = phase 8 (skill, docs, ADRs, ignore file, env, doc test, plus the mirror removal phase 7 deferred with its exact readers and pins listed in `plans/phase-7.md` Concerns 1). `main` frozen; chain restarted with `--reset-cap` at session 15 (supervisor `--max-sessions 15`).

**Sessions used so far in Stage 4:** 7 (session 9 planning; session 10 tickets + phase 0; session 11 fleet plan + wave A; session 12 wave B; session 13 wave C; session 14 wave D; session 15 wave E). Re-estimated after phase 3: one parent session per wave holds, so ~7 more (waves C–F + cutover, plus one spare); the delegated estimate of ~10–12 total stands.

| Phase | Deliverable | Status | Est. | Used | Started | Done | Commit | Notes |
|---|---|---|---|---|---|---|---|---|
| 0 | Live chain ended; relaunch default manual + per-item auto; counter import | done | 1 | 1 | 2026-09-16 | 2026-09-17 | 131142a | chain kept — main frozen, waves on `stage4`; see plans/phase-0.md |
| 1 | Record helper `scripts/lib/session-lib.sh` + test | done | 1 | 1 | 2026-09-17 | 2026-09-17 | 8cb363d (merge 1e6f857) | agent in worktree; `session_record_update`, 55 asserts, race 3×20 → seq 60. **S8 lock race flaked twice** (phase 6 agent on a clean 0a117c6 extract; parent on stage4 4bb8a5d with nothing else running: writer 2 rc=4 at iteration 0, total 59); green on rerun both times — if it bites a third time, the `mkdir` lock's stale sweep is racing, fix it in phase 7. **Third sighting (session 14, S10a on 256b36b):** the lock loop's `[ -d "$lock" ] || refuse record_unwritable` fires when the holder releases between the failed `mkdir` and the check — phase 7 retries instead of refusing |
| 2 | Fleet extraction `scripts/fleet.sh` (pure move) | done | 1 | 1 | 2026-09-17 | 2026-09-17 | f07f5ea (merge 5a4aec6) | measurer −189 lines (Part 4 said ~400); fleet.sh leans on `check` output — phase 3 must keep `runtime=`/`artifact=` lines |
| 3 | Measurer verbs on the record | done | 3 | 1 | 2026-09-17 | 2026-09-17 | d4fb3b6 (merge 0a117c6) | agent in worktree; measurer 1265→1017; registry record kept, side files gone; registry suite 187 asserts, numbering 18; `check` output kept for fleet.sh |
| 4 | Launcher on the record; first end-to-end slice | done | 3 | 1 | 2026-09-18 | 2026-09-18 | 5330f86 (merge 26b214c) | agent in worktree; launcher 1319→512, 12 gates, one record write; launcher suite 193 asserts, emit 54; `.session-seq` + sidecars now write-only mirrors for phase 5; clear-seed hook + suite deleted — stage4 `.claude/settings.json` SessionStart entry is a guarded no-op until phase 8 removes it; `--clear` prompt in `launch.pending.prompt` has no injector yet |
| 5 | Supervisor with three verdicts | done | 3 | 1 | 2026-09-18 | 2026-09-18 | 4299159 (merge 256b36b) | agent in worktree; wrapper commit f771dd4 first; supervisor 1002→381 lines, suite 105 asserts with stub children through the real launcher `--emit`; spent stage = `staged_invalid leg=spent`; sentinel, flush-hash, budget/alarm-stop/chain-closed files gone. **Still written for readers phase 5 may not edit:** `.session-loop` marker (measurer `supervised`), `.next-command` + `.session-seq.bump.json` (hook-lib turn-end self-kill) — phase 7/8 move those reads to `chain.supervisor` / `staged.by`; `--clear` injector is phase 7/8's |
| 6 | Hook dispatcher + adapter table | done | 2 | 1 | 2026-09-18 | 2026-09-18 | 67dc8a9 (merge 4bb8a5d) | agent in worktree; `context-budget-hook.sh` + `context-budget-adapters.conf` (6 rows); 7 wrappers are one-line shims at their old paths, lib kept; 47 fixtures, vendor suite 150 asserts; configs untouched (optional later: point them at the dispatcher, drop shims); docs prose is phase 8's |
| 7 | Probes rewritten; Claude Code acceptance | done | 2 | 1 | 2026-09-21 | 2026-09-21 | 30f2632 (merge 5c7edc0) | agent in worktree; probes V1/V3/V10 as scripts under `evaluation/probes/` sharing one assertion lib; twin suite `test-probe-twins.sh` 37 asserts runs the same scripts under a stub `claude` that honours the real hooks; H1 spent stage + H2 refused hand `--emit`; lock fix fae4746 (retry a lost race only; lib suite 64 asserts, 5× green); Claude Code acceptance in a scratch clone (V1 18/18, V3 `--max-sessions 2` 15/15: staged, staged, cap). **Mirror removal deferred to phase 8** (third `.session-loop` reader = launcher `invoked_by_supervisor`; `.next-command` is also `--emit`'s output contract; readers + pins in plans/phase-7.md Concerns 1). Suites: 21 shell + ledger green on `stage4` after the merge, no flake |
| 8 | Skill, docs, ADRs, ignore file, env, doc test | todo | 2 | 0 | | | | |
| cutover | Import + attended rollover + 2-session chain on this item | todo | 1 | 0 | | | | |

## How to update

- Starting a phase: write `plans/phase-<n>.md` (task-level plan), set `in progress`, fill Started.
- Ending a phase: all suites green, set `done`, fill Done + Commit, bump Used, rewrite the "Now" line.
- Every rollover: bump Used on the in-progress row and rewrite the "Now" line.
- Estimate drifting by more than 2 sessions: say so in Notes and in the ledger.
