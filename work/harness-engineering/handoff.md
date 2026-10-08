<!--
PURPOSE: This is the LEDGER (provenance log). Append-only, newest block on
TOP. Each "# Session Handoff" block records what happened in one session.
Read the TOP block only; older blocks are in handoff-archive.md. Forward
"what to do next" belongs in next-session.md, NOT here.
Convention: docs/work-directory-conventions.md.
-->

# Session Handoff — 2 (2026-10-08)

1. Ticket 02 (M45) done, commit `87b5776`: `scripts/check-drift.sh`
   (dead backticked paths, gotchas past review age, CONTEXT.md over 16,000
   bytes, unindexed docs; ADR hits warn). Suite
   `scripts/tests/test-check-drift.sh` D1–D4. Checkpoint step 1 now runs
   it; CI gains a weekly schedule. Full run-checks 35/0/0. Card M45
   archived; new open card **L63** (two removed scripts in the
   `workspace-structure.md` tree). Scorecard 5/107/5/0/6. Two Tier-2 notes.
2. First run on `main`: one ADR-0009 warning, nothing failing. L58/L59
   were already fixed by `template-maintenance`.
3. Rolled over at 116K by pre-flight (not WARN): ticket 03 is doc-heavy
   and would have ended near STOP. Next: ticket 03 (L60).

Learnings:
- Bash 3.2 (macOS) fails to parse a `case` with `pat)` arms inside
  `$( … )` ("syntax error near `;;`"); use `if` there.

# Session Handoff — 1 (2026-10-08)

1. Ticket 01 (M44) done, commit `540cdba`: `scripts/run-checks.sh` (full
   33 checks/120s, `--fast` 23/13s), `# run-checks: slow` marker in 10
   scripts, exit 77 = skip, opt-in `scripts/git-hooks/pre-commit`
   (`core.hooksPath`), `.github/workflows/checks.yml`. Suite:
   `scripts/tests/test-run-checks.sh` (R1–R7). Card M44 archived, scorecard
   5/106/5/0/6. Two Tier-2 notes in `decisions.md`.
2. `test-jev.sh` made hermetic. `start_stub` ran in `$(...)`, so a slow stub
   left the endpoint empty (live-URL fallback, the session-2 flake), and stub
   pids never reached the trap. About 90 leaked stub servers were killed.
3. **CI is unverified.** I simulated it on macOS (agent CLIs off PATH, empty
   HOME, `CI=true`, gh by `GH_TOKEN`, `USER` set): 33/0/0. Linux portability
   of the suites is unknown until the user pushes. Docker's daemon was down.
4. Rolled over at WARN (127K) after ticket 01. Next: ticket 02 (M45).

Learnings:
- Several scripts die on `USER: unbound variable` under `env -i`
  (`context-budget.sh:672`). Real runners set USER; harmless unless a CI
  strips env.
