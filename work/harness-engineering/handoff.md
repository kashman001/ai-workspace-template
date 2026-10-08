<!--
PURPOSE: This is the LEDGER (provenance log). Append-only, newest block on
TOP. Each "# Session Handoff" block records what happened in one session.
Read the TOP block only; older blocks are in handoff-archive.md. Forward
"what to do next" belongs in next-session.md, NOT here.
Convention: docs/work-directory-conventions.md.
-->

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

# Session Handoff — 2026-10-08 (session 0: scaffolded from the harness-engineering review)

1. Scaffolded from a `context-memory-hardening` session 4 conversation: the
   user asked what the template could learn from Böckeler's harness
   engineering article; five ideas were accepted and filed as cards M44,
   M45, L60, L61, L62. Article summary in `source-notes.md`.
2. Five tickets under `issues/`; no code yet. Next: ticket 01 (launcher).
