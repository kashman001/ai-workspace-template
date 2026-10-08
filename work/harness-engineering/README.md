# harness-engineering — Make the template's checks run themselves and keep up with drift

Governing skill(s): `tdd` (script tickets), `decision-log` (any choice with
a rejected alternative).

**Start here:** `next-session.md` (catch-up launcher) → `handoff.md`
(session ledger, top block).

## What this is

This item applies the useful parts of Birgitta Böckeler's "Harness
engineering for coding agent users" (martinfowler.com, 2026-04) to the
template itself. The article sorts the controls around a coding agent into
**guides** (steer before it acts: `CONTEXT.md`, skills, gotchas) and
**checks** (catch problems after: scripts, tests, hooks). The template has
plenty of both, but its checks only run when an agent remembers, nothing
sweeps for drift, and repeated gotchas never become checks. Five backlog
cards, one ticket each: **M44, M45, L60, L61, L62**. Built to run unattended
under `scripts/session-loop.sh harness-engineering`.

**Status: finished (2026-10-08, session 4).** All five tickets done; follow-up
gaps are open cards L64 and L65.

Article summary (read on demand, don't refetch): `source-notes.md`.

Related but separate: `work/quality-gates/` writes gate guidance for the
*product repos* people build with the template; this item fixes the
template's *own* checks. Its ticket 01 output is an input there.

## Success criteria

- Tickets 01–05 all show `**Status:** done` with every box ticked, or a
  note explaining any box that can't be ticked.
- Cards M44, M45, L60, L61, L62 resolved and moved to
  `docs/template-workspace-backlog-archive.html`, scorecard updated, each
  with a `Fixed:` line naming its commit.
- `scripts/run-checks.sh` (ticket 01) exits 0 on `main`; it runs every
  `scripts/tests/` suite and every `check-*` script.
- One commit per ticket, each with a `Decision:` trailer. Nothing is pushed
  (pushing main is the user's call).

## Files

- `next-session.md` — forward launcher (what to do next). REPLACED each rollover.
- `handoff.md` — session ledger (what happened). APPEND newest-on-top; archive
  to `handoff-archive.md` when it exceeds the two most recent sessions.
- `source-notes.md` — the article, summarized, with how each idea maps to the template.
- `issues/NN-<slug>.md` — the five tickets, in order.
- `context-budget.env` — per-item `ROLLOVER_RELAUNCH=auto` so the session loop can chain.
- `decisions.md` — Tier-2 notes, created when the first decision is recorded.
