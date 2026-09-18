<!--
PURPOSE: This is the LEDGER (provenance log). Append-only, newest block on
TOP. Each "# Session Handoff" block records what happened in one session.
Read the TOP block only; older blocks are in handoff-archive.md. Forward
"what to do next" belongs in next-session.md, NOT here.
Convention: docs/work-directory-conventions.md.
-->

# Session Handoff — 14 (2026-09-18): Stage 4 wave D (phase 5, supervisor with three verdicts) done by one agent; merged to `stage4`; chain cap reached

**Summary.** One general-purpose agent in `.claude/worktrees/s4-phase-5` (off
`stage4` 4bb8a5d), dispatch contract in its prompt. Returned DONE_WITH_CONCERNS
in 28 min, ~288K agent tokens: five commits (plan 1966929; `main "$@"` wrapper
f771dd4 with no other change, old suite 222/222 before and after; body +
stub-child suite 4299159; launcher mirror deletions bbd31e6; evidence 6418a82).
Supervisor 1002→381 lines; `test-session-loop.sh` 105 asserts, stub children
staged through the real launcher `--emit`. Merged `--no-ff` 256b36b; full run on
`stage4`: 20 shell suites + Python ledger suite, one red (`test-session-lib.sh`
S10a lock race, lib untouched by the branch), green on two reruns. Tracker row 5
done; Tier-2 note in `decisions.md`; report `dispatch/phase-5.md`; plan +
Evidence + "Concerns for the parent" in `plans/phase-5.md` (on `stage4`).
Bookkeeping commit d14cc8e on `main`. Agent worktree and branch removed.
Nothing pushed; `main` ahead 23 after this rollover's commit. Parent cost ~58K→
~101K at prep.

**Decisions.** Phase 5 (decisions.md 2026-09-18): spent stage = `staged_invalid
leg=spent`; `no_own_measurement` from the record's `registered_at`; stall guard
watches the three markdown files + `handoff-archive.md`; watchdog kept on the
record; `--reset-cap` standalone; the `--clear` prompt is not the supervisor's.
Two mirrors STILL written because their readers are files phase 5 may not edit:
`.session-loop` marker (measurer `supervised`) and `.next-command` +
`.session-seq.bump.json` (hook-lib turn-end self-kill). Parent: S10a not sent
back (d14cc8e trailer) — third lock-race sighting, the lock fix is phase 7's.

**Learnings:**
- `test-session-lib.sh` lock race, strike three (S8 ×2, S10a ×1): the loop's
  `[ -d "$lock" ] || refuse record_unwritable` fires when the holder releases
  between the failed `mkdir` and the check (`scripts/lib/session-lib.sh:60-61`
  on `stage4`). Fix = retry, not refuse. In tracker row 1 notes.
- Parked (agent, plans/phase-5.md Evidence): bash 3.2 fails to parse a literal
  `(` before `$(… "?" …)` inside double quotes.
- The harness cwd moved into the stage4 worktree again from a `cd` in a
  compound command; `cd` back to the root restores it. Already in
  `docs/operational-knowledge.md`.

**Open / next.** Wave E = phase 7 alone (ticket 08: probes on record fields,
stub-runtime twins, Claude Code acceptance on the throwaway item), plus the
lock fix. Phase 7's plan decides whether it also moves `supervised` to
`chain.supervisor` and hook-lib to `staged.by` (then deletes the two mirrors)
or leaves that to phase 8. Carry-overs unchanged: stage4 `.claude/settings.json`
clear-seed SessionStart entry (phase 8); prose naming `--bg`/`--unstage`/
`.rollover-options` (phase 8); vendor configs naming shim paths (optional);
stale `.gitignore` lines for deleted state files (phase 8). **Chain: this
session was 10 of 10 — the `--emit` at this rollover trips the cap; the
supervisor reports `cap` and stops. Restart: `scripts/session-loop.sh
template-improvement-review --reset-cap`.**

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

