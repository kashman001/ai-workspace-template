<!--
PURPOSE: This is the LEDGER (provenance log). Append-only, newest block on
TOP. Each "# Session Handoff" block records what happened in one session.
Read the TOP block only; older blocks are in handoff-archive.md. Forward
"what to do next" belongs in next-session.md, NOT here.
Convention: docs/work-directory-conventions.md.
-->

# Session Handoff — 6 (2026-10-15): probe run 2 recorded (FAIL); S15 FAIL branch landed; item closed

**Summary.** Reached by `/clear` (seq 6); again no turn until the user typed "go — probe run 2: FAIL, idle for 60 s". Recorded run 2 in `probes.md` (FAIL, claude 2.1.300) — 2 of 2 FAIL. S15 FAIL branch: `launch-next-session.sh` line now says "PRESS /clear, then type go"; test L1i updated and seen red first (187/188), 188/188 after the fix; same wording in `skills/session-rollover/SKILL.md`, the `docs/context-budget.md` clear bullet, and a TADR-0009 amendment. Bootstrap prompt unchanged. Backlog: new resolved card L92 in the archive (Resolved 143→144). README Status and `work/README.md` row set to Finished. Checkpoint (stop door), no rollover. L91 stays open.

# Session Handoff — 5 (2026-10-15): probe run 1 recorded (FAIL); rolled over with `--clear` for run 2

**Summary.** Reached by `/clear` from the #4 addendum. The `SessionStart:clear` hook bound seq 5 and seeded the bootstrap prompt into context, but no turn started until the user typed "go — probe run 1: FAIL, idle for 60 s". Created `probes.md` and recorded run 1 as FAIL (claude 2.1.300). Archived the old #4 block to `handoff-archive.md`. Rolled over with `--clear` again for probe run 2; the user follows runbook §3.
