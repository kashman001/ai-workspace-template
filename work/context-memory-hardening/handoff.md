<!--
PURPOSE: This is the LEDGER (provenance log). Append-only, newest block on
TOP. Each "# Session Handoff" block records what happened in one session.
Read the TOP block only; older blocks are in handoff-archive.md. Forward
"what to do next" belongs in next-session.md, NOT here.
Convention: docs/work-directory-conventions.md.
-->

# Session Handoff — 2026-10-07 (session 2: tickets 01–02 done, WARN rollover)

1. Ticket 01 (L49) done, commit `9996954`: "Cache the prefix, vary the
   tail" in `docs/context-budget.md`, pointer in `CONTEXT.md`, date-line
   warning in `check-workspace-structure.sh` + `test-context-prefix-stability.sh`.
   Hook audit in the ticket's `## Answer`: no hook change needed.
2. Ticket 02 (L50) done, commit `0e489b5`: ledger rows carry
   `cache_read_share` (Claude, Codex, OpenCode; `null` elsewhere); the
   check/record line shows `cache=NN%`. This session read `cache=99%`.
3. Three Tier-2 notes written to `decisions.md`. Scorecard now 3/96/4/0/6.
4. Rolled over at WARN (131K). Next: ticket 03 (M43).

Learnings:
- `scripts/tests/test-jev.sh` failed once (stub endpoint unused, request hit
  the live URL → 401), then passed on rerun with no change. Flaky; not filed.
- `test-launch-next-session.sh`, `test-plan.sh`, `test-session-loop.sh` lack
  the exec bit and `test-check-ledger.py` is Python: run suites as
  `bash`/`python3`, not `./`.

# Session Handoff — 2026-10-07 (session 1: scaffolded from context-memory-eval)

1. Created this item from the `context-memory-eval` session. The user
   accepted recommendations 1–4 and 6 and deferred 5.
2. Backlog cards M43, L49, L50, L51, D5 opened in
   `docs/template-workspace-backlog.html` (scorecard 5/94/4/0/6).
3. Five tickets written under `issues/`. Per-item `ROLLOVER_RELAUNCH=auto`
   added for the session loop.
4. No ticket started. Next: ticket 01 (see launcher).
