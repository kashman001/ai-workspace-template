<!--
PURPOSE: This is the LEDGER (provenance log). Append-only, newest block on
TOP. Each "# Session Handoff" block records what happened in one session.
Read the TOP block only; older blocks are in handoff-archive.md. Forward
"what to do next" belongs in next-session.md, NOT here.
Convention: docs/work-directory-conventions.md.
-->

# Session Handoff — 13 (2026-09-18): Stage 4 wave C (phases 4 ∥ 6) done by two agents; merged to `stage4`

**Summary.** Two general-purpose agents in `.claude/worktrees/s4-phase-{4,6}`
(off `stage4` 0a117c6), dispatch contracts in their prompts, file split from
the fleet plan. Phase 6 (hook dispatcher, 67dc8a9) returned DONE in 16 min;
phase 4 (launcher on the record, 5330f86) DONE_WITH_CONCERNS in 23 min — four
handoff notes, no defects. Merged 4 first (26b214c, 21/21 green on `stage4`),
then 6 (4bb8a5d, 20/21: `test-session-lib.sh` S8 lock race, rerun 55/55).
Tracker rows 4 and 6 done; two Tier-2 notes in `decisions.md`; reports in
`dispatch/phase-{4,6}.md`; plans + Evidence in `plans/phase-{4,6}.md` (on
`stage4`). Bookkeeping commit 6ce5d8a on `main`. Agent worktrees and branches
removed. Nothing pushed; `main` ahead 21 after this rollover's commit.

**Decisions.** Phase 6 merge held until phase 4 was green (6ce5d8a trailer).
Phase 4: twelve gates, one record write, `no_supervisor` only for a
`TF_SESSION_LOOP=1` session, `.session-seq` + sidecars write-only for phase 5.
Phase 6: adapter table is a data file, seven wrappers become one-line shims
at their old paths, `jq_missing` on stderr exit 0 (decisions.md 2026-09-18).
S8 flake not sent back (no wave C branch touched the lib or its suite).

**Learnings:**
- Two agents per wave cost the parent ~53K (58K→111K at bookkeeping); agents
  spent ~325K (phase 4) and ~152K (phase 6). Fits one session with headroom.
- `test-session-lib.sh` S8 (3-writer lock race): second sighting, now in the
  tracker row 1 notes for phase 7. Strike three means fix the lock, not rerun.
- `cd` into a worktree moving the harness cwd: bit again, promoted to
  `docs/operational-knowledge.md`.
- Harness agents: "Agent finished" can arrive before its report when the
  agent still has background work; the hand-back message is the real signal.

**Open / next.** Wave D = phase 5 alone (supervisor, three verdicts), one
agent; first commit is the `main "$@"` wrapper on `session-loop.sh`. Carry-
overs for later phases: stage4 `.claude/settings.json` SessionStart entry for
the deleted clear-seed hook (guarded no-op; phase 8), `--clear` prompt in
`launch.pending.prompt` has no injector (phase 5/7 decide), prose naming
`--bg`/`--unstage`/`.rollover-options`/seed file in the skill, docs, ADR-0009,
`CONTEXT.md` (phase 8), vendor configs still name the shim paths (optional).
Chain: session 13 is 9 of 10 — the cap lands at session 14's rollover.

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

