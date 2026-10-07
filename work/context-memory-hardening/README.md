# context-memory-hardening — Ship the accepted context/memory-engineering recommendations

Governing skill(s): `tdd` (script tickets), `decision-log` (ticket 05).

**Start here:** `next-session.md` (catch-up launcher) → `handoff.md`
(session ledger, top block).

## What this is

This item carries out the five recommendations the user accepted from the
`context-memory-eval` evaluation. They are backlog cards **L49, L50, M43,
L51, D5**. Each card is one ticket under `issues/`. It's built to run
unattended under `scripts/session-loop.sh context-memory-hardening`.

**Research behind it, read on demand:**

- `work/context-memory-eval/eval.md` — scorecard, evidence, and the ranked
  recommendations. Ticket N maps to recommendation N, except ticket 05 maps
  to recommendation 6.
- `work/context-memory-eval/source-notes.md` — the outside framework,
  concepts C1–C11.
- `work/context-memory-eval/decisions.md` — why recommendation 5 (async
  consolidation) is out of scope here.

## Success criteria

- Tickets 01–05 all show `**Status:** done` with every box ticked, or a
  note explaining any box that can't be ticked.
- Cards L49, L50, M43, L51, D5 are resolved and moved to
  `docs/template-workspace-backlog-archive.html`, the scorecard is updated,
  and each card has a `Fixed:` line naming its commit.
- Every `scripts/tests/test-*` suite passes. `scripts/check-workspace-structure.sh`
  and `python3 scripts/check-ledger.py` exit 0.
- One commit per ticket, each with a `Decision:` trailer. Nothing is pushed
  (pushing main is the user's call).

## Files

- `next-session.md` — forward launcher (what to do next). REPLACED each rollover.
- `handoff.md` — session ledger (what happened). APPEND newest-on-top; archive
  to `handoff-archive.md` when it exceeds the two most recent sessions.
- `issues/NN-<slug>.md` — the five tickets, in order.
- `context-budget.env` — per-item `ROLLOVER_RELAUNCH=auto` so the session loop can chain.
- `decisions.md` — Tier-2 notes, created when the first decision is recorded.
