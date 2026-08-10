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

## Open items — pursue as separate efforts

Three reliability bugs in the workspace machinery surfaced during this work
item's sessions but were scoped OUT of its mission. They remain Open cards
in `docs/template-workspace-backlog.html` (the authoritative record — grep
the ID there for evidence/impact/fix detail):

- **M16 (Medium)** — EnterWorktree mid-session relocates the claude
  transcript, staling the artifact path pinned by
  `scripts/context-budget.sh register`; a live session then looks dead and
  can be swept/taken over as a stale primary. Reproduced live in session 2.
- **L32 (Low)** — the budget hook's escalation throttle is keyed per
  session id only, so a subagent firing first can swallow the parent's
  WARN push; the parent crosses 120K unnotified.
- **L33 (Low)** — a successor session can trust a stale `next-session.md`
  when its checkout (or a worktree branched from lagging origin/main) is
  behind; mitigation today is prose-only (the launcher's "confirm
  `git log HEAD..origin/main` is empty" step). Recurred in session 2.
