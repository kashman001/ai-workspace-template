# S14 probes — does a cleared session start on its own?

Procedure: `s14-runbook.md` §2–3. Spec: `spec.md` §4 (S14/S15).

| run | date | claude version (claude --version) | turn started without typing? (PASS/FAIL) | first tool call | evidence |
|---|---|---|---|---|---|
| 1 | 2026-10-15 | 2.1.300 (Claude Code) | FAIL | `Bash` — `cat work/clear-session-loop/next-session.md` (after the user typed) | User's first message: "go — probe run 1: FAIL, idle for 60 s". The `SessionStart:clear` hook did fire and seeded the bootstrap prompt as context (record bound seq 5 to the new session id), but no turn ran until the user typed. |
| 2 | 2026-10-15 | 2.1.300 (Claude Code) | FAIL | `Bash` — `cat work/clear-session-loop/next-session.md` (after the user typed) | User's first message: "go — probe run 2: FAIL, idle for 60 s". Same shape as run 1: `SessionStart:clear` bound seq 6 and seeded the prompt as context; no turn until the user typed. |

**Result (S15): FAIL, 2 of 2.** A cleared session does not start on its own;
the human presses `/clear`, then types `go`. Docs updated per `spec.md` §4 FAIL
branch.
