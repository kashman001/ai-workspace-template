# Usage Scenarios — scenario catalog for evaluating the workspace template

Governing skill(s): none.

> **MAINTENANCE MODE (2026-08-09).** The work item's mission is complete —
> all 8 gaps resolved or deliberately deferred (see `handoff.md` top block).
> This directory stays because committed docs point into
> `scenarios.md` §3 (the canonical external-scenario catalog); do not delete
> it. Edit `scenarios.md` only to keep the catalog accurate as the template
> evolves. Deferred residuals and their wake-up conditions are listed in
> `next-session.md`.

**Start here:** `next-session.md` (catch-up launcher) → `handoff.md`
(session ledger, top block).

## What this is

A structured catalog of usage scenarios for this workspace template: the
external scenarios (how a developer adopts and uses the template day-to-day)
and the critical internal scenarios (rollover, compaction, multi-session
handoff, budget enforcement, etc.). The catalog is an evaluation lens — each
scenario should let us judge whether the template supports it well, drive
improvements, and reveal gaps in evaluation and testing coverage.

## Files

- `next-session.md` — forward launcher (what to do next). REPLACED each rollover.
- `handoff.md` — session ledger (what happened). APPEND newest-on-top; archive
  to `handoff-archive.md` when it exceeds the two most recent sessions.
- `scenarios.md` — the scenario catalog itself; §3 is the canonical
  external-scenario catalog that committed docs link to.
