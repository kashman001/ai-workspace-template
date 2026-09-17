<!--
PURPOSE: This is the LEDGER (provenance log). Append-only, newest block on
TOP. Each "# Session Handoff" block records what happened in one session.
Read the TOP block only; older blocks are in handoff-archive.md. Forward
"what to do next" belongs in next-session.md, NOT here.
Convention: docs/work-directory-conventions.md.
-->

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

# Session Handoff — 10 (2026-09-16): Stage 4 tickets cut; phase 0 tasks 2–5 done; chain ended by a plain quit

**Summary.** Cut ten tickets from Part 4 (`issues/01`–`10`, one per phase +
cutover, edges per "Order and gates"; commit 0c1dd35, no user quiz — the
launcher fixed the granularity). Phase 0 (`plans/phase-0.md`): root
`ROLLOVER_RELAUNCH` flipped to `manual` with a committed per-item `auto`
override for this item; `jq` pinned by `test-check-dependencies.sh` D5;
`SESSION_LOOP_NOTIFY` now resolves from the env file's own location
(`test-session-loop-notify.sh` N4; doc paragraph corrected);
`scripts/import-session-seq.sh` + `test-import-session-seq.sh` (26 asserts)
on a throwaway item. All suites green before commit. **Chain ended:** this
session staged no successor; closing it by hand with nothing staged makes the
old supervisor (pid 72900) log a deliberate quit and exit 0. Nothing pushed.

**Decisions.** Record file `session-state.json` with `schema: 1`; import
compares rather than consumes the counter; notify path via `BASH_SOURCE`
(decisions.md 2026-09-16).

**Learnings:**
- macOS has no `timeout`; a suite loop wrapped in it reports rc=127 for every
  suite and looks like a run. Check the per-suite rc line before trusting it.
- macOS 15+ ships `/usr/bin/jq`, so a "jq absent" test needs a PATH built
  without it, not just a bare PATH.
- Tickets + phase 0 + bookkeeping fit one session (WARN at ~125K) only
  because the big scripts were grepped, never read.

**Open / next.** User direction after the session summary (2026-09-17): plan
the remaining phases as a dependency graph and execute them in parallel with
a fleet of agents. Then: one wave per session, rolling over through the LIVE
supervisor (chain kept; `main` frozen, waves on `stage4`). Session 11: mark phase 0 `done`, write `plans/fleet-plan.md` (waves
1∥2 → 3 → 4∥6 → 5 → 7 → 8 → cutover), get the go, launch wave A.

