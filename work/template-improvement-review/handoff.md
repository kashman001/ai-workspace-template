<!--
PURPOSE: This is the LEDGER (provenance log). Append-only, newest block on
TOP. Each "# Session Handoff" block records what happened in one session.
Read the TOP block only; older blocks are in handoff-archive.md. Forward
"what to do next" belongs in next-session.md, NOT here.
Convention: docs/work-directory-conventions.md.
-->

# Session Handoff — 12 (2026-09-17): Stage 4 wave B (phase 3, measurer on the record) done by one agent; merged to `stage4`

**Summary.** One general-purpose agent in `.claude/worktrees/s4-phase-3` (off
`stage4`) with the dispatch contract in its prompt. Returned DONE: measurer
`register`/`release`/`close`/`--check` now write the per-item record through
`session_record_update`; registry suite rewritten (187 asserts), numbering
suite rewritten (18); `seq-sync`/`opts-sync`/`rollover-complete` refuse with
a pointer; `rollover-prep.sh`, `capture-rollover-options.sh` and three suites
deleted; measurer 1265→1017 lines. Commit d4fb3b6, merged `--no-ff` 0a117c6.
Full suite on `stage4`: 21 suites, one red (`test-session-loop.sh` D5b-g, a
reap/notify timing race phase 3 never touched), rerun 221/221 green — treated
as a flake (bookkeeping commit e1778da on `main` says so). Agent worktree and
branch removed. Tracker row 3 done; two Tier-2 notes in `decisions.md`;
report in `dispatch/phase-3.md`; plan + Evidence in `plans/phase-3.md` (on
`stage4`). Nothing pushed; `main` ahead 19.

**Decisions.** Registry record stays, per-item side files go; `record`/
`watch`/`supervised` unchanged; `owner_live` is logged not refused;
non-owner `release` exits 1; env binding needs both vars and an equal seq
(decisions.md 2026-09-17, phase 3 notes). D5b-g flake not sent back to the
agent (commit e1778da trailer).

**Learnings:**
- One agent per wave cost the parent ~40K (57K→97K at prep); the agent
  itself spent ~285K tokens over 75 min, most of it the two suite rewrites.
- `test-session-loop.sh` D5b-g can fail under load with a 97 s hold; first
  strike — if it bites again, the alarm-reap race is real, not the test.
- Phase 3 left prose naming `seq-sync` in `launch-next-session.sh` remedy
  text (lines ~323/582/1217, pinned by T23i4/E8d) for phase 4, and skill/
  README/.gitignore mentions for phase 8. Child locks are no longer written
  by `register` (fleet, phase 7).
- The primary session's `cd` into a worktree inside a compound Bash command
  moves the harness cwd there; use `git -C` and absolute paths instead.

**Open / next.** Wave C: phases 4 ∥ 6, two agents on `s4-phase-4` and
`s4-phase-6` from `stage4`; merge 4 before 6. Hazard: phase 4 deletes the
clear-seed hook + its test; phase 6 owns every other hook. Chain: session 12
was 8 of 10; cap lands around session 14.

# Session Handoff — 11 (2026-09-17): Stage 4 wave A (phases 1 ∥ 2) done by a two-agent fleet; merged to `stage4`

**Summary.** Phase 0 marked done (131142a). `stage4` branched from `main`
and checked out only in `.claude/worktrees/stage4`. Wrote
`plans/fleet-plan.md` (waves A–F + cutover, per-agent contract, parent's
merge loop, hazards). Launched two general-purpose agents in parallel, each
in its own worktree (`s4-phase-1`, `s4-phase-2` off `stage4`), with the
dispatch contract from `dispatch-open` in their prompt. Both returned DONE:
phase 1 = `scripts/lib/session-lib.sh` + `test-session-lib.sh` (55 asserts,
race 3×20 → seq 60), commit 8cb363d; phase 2 = `scripts/fleet.sh` (five verbs,
pure move), measurer 1454→1265 lines, three suites renamed `test-fleet-*`,
commit f07f5ea. Merged with `--no-ff` (1e6f857, 5a4aec6); every suite run on
`stage4` after each merge: 24/24 rc=0. Agent worktrees and branches removed.
Dispatch reports in `dispatch/phase-{1,2}.md`. Nothing pushed; main ahead 16+.

**Decisions.** Rollovers hands-off, no per-wave okay (user, mid-session);
`stage4` never checked out in the primary tree; agents' interface/lock and
copy-not-share choices (decisions.md 2026-09-17, four notes).

**Learnings:**
- Two parallel agents plus merges and suites cost the parent ~60K (56K→118K);
  the agent prompts themselves are the big item. One agent per wave is cheap.
- `git branch -d` judges "merged" against the current branch (`main`), so it
  refuses branches merged into `stage4`; check `git branch --merged stage4`
  then `-D`.
- A branch named `stage4/phase-1` cannot coexist with branch `stage4` (ref
  namespace); hence `s4-phase-<n>`.
- The full suite run takes ~8–10 min (`test-session-loop.sh` is ~4 min);
  background it and never merge into the worktree while it runs.
- Phase 2 found Part 4's "~400 lines" was ~190; `fleet.sh` depends on the
  measurer's `check` printing `runtime=`/`artifact=` — phase 3 must keep them.

**Open / next.** Wave B: phase 3 (measurer on the record), one agent on
`s4-phase-3` from `stage4`; then wave C. Chain: session 11 was 7 of 10.

