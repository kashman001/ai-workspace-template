<!--
PURPOSE: This is the LEDGER (provenance log). Append-only, newest block on
TOP. Each "# Session Handoff" block records what happened in one session.
Read the TOP block only; older blocks are in handoff-archive.md. Forward
"what to do next" belongs in next-session.md, NOT here.
Convention: docs/work-directory-conventions.md.
-->

# Session Handoff — 5 (2026-10-15): probe run 1 recorded (FAIL); rolled over with `--clear` for run 2

**Summary.** Reached by `/clear` from the #4 addendum. The `SessionStart:clear` hook bound seq 5 and seeded the bootstrap prompt into context, but no turn started until the user typed "go — probe run 1: FAIL, idle for 60 s". Created `probes.md` and recorded run 1 as FAIL (claude 2.1.300). Archived the old #4 block to `handoff-archive.md`. Rolled over with `--clear` again for probe run 2; the user follows runbook §3.

# Session Handoff addendum — 4 (2026-10-15): hand-started continuation; chain reopened by hand; probe run 1 launched

**Numbering.** The user started this as "session #5", but #4 staged no successor, so `register` adopted seq 4 (owner dead, number kept). Hence an addendum to #4; the `/clear` successor is seq 5.

**Summary.** Started by hand with plain `claude` (no `session-loop.sh`), per `s14-runbook.md`. Added backlog card L90 to the archive (S13 shipped, S4 retired; Resolved 142→143) and listed `s14-runbook.md` and `probes.md` in README "Files". Then rolled over with `--clear` for probe run 1.

**Blocker hit.** `launch-next-session.sh --clear --check` refused `chain_closed`: the user's `/exit` of #4 under the loop set `.chain.closed` (`quit_plain`, by_seq 4), and the only sanctioned reopen (`session-loop.sh --reopen`) starts a supervisor, which `--clear` refuses. On the user's go-ahead, this session wrote `.chain.closed = null` to `session-state.json` with jq (the same write `--reopen` makes). Filed as open backlog card L91 (Open 2→3) and added a runbook "If something goes wrong" line.
