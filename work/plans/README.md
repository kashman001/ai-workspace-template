# plans — Explore "plans" as a first-class way to run structured, multi-session work

Governing skill(s): `grill-with-docs` (session 1: sharpen the concept against
what the workspace already has), `wayfinder` if the open questions outgrow one
session, then `to-spec` → `to-tickets` once the shape is settled.

**Start here:** `next-session.md` (catch-up launcher) → `handoff.md`
(session ledger, top block).

## What this is

A **plan** is a durable, on-disk description of a piece of work that an agent
runtime can execute: a **graph** of steps with explicit dependencies, run by
**loops** (a step or a whole branch repeats until a check passes), spread over
**sessions** (a plan outlives any one context window and resumes from disk).
Beyond dependencies, a plan is **parallelism-aware** (independent branches run
at once; the plan says what is safe to fan out) and **LLM-tier-aware** (each
step names the cheapest model tier that can do it, so a frontier model
orchestrates while cheap models do leaf work).

The workspace already has the pieces in isolation: `to-tickets` writes
blocking edges, `wayfinder` maps decision tickets with a frontier, the
Workflow tool and `research-wave` fan agents out and pipeline them, `/loop`
and `scripts/session-loop.sh` repeat and chain, `rlm` and the Agent tool's
`model` override pick tiers, and launcher/ledger carry work across sessions.
Nothing joins them: no single artifact says "these steps, in this order, in
parallel where allowed, on these tiers, until these checks pass, across as
many sessions as it takes". This item explores whether such an artifact
should exist, what it looks like, and how much of it is already covered.

Exploration first: the deliverable is a settled concept and decisions, not a
runner. Anything that ships later follows the template rules (agent-agnostic,
plain files, documented for downloaders).

## Success criteria

**Status (2026-09-30, session 19):** tickets 01–15 done — finished. Dogfood plan closed 18/18 in jev-integration; L48 verdict adopted as a recipe in the `plans` skill; dogfood fixes landed as tickets 12–15.

**Earlier status (2026-09-23, session 2): verdict = BUILD** — format + `plan.sh` state tooling + the `chain.plan` loop hook, no runner. All decisions settled in `decisions.md`; `concept.md` written; `spec.md` and `issues/` follow via `to-spec` / `to-tickets`.

- **Concept note** at `concept.md`: a one-page definition of a plan and its
  five properties (graph, loops, sessions, parallelism, tiers), a glossary of
  the terms used, and a worked example of one real plan (e.g. a research
  wave or a multi-ticket build) written in the proposed form.
- **Seam inventory** at `seams.md`: for each existing mechanism (`to-tickets`
  edges, `wayfinder` map, Workflow tool, `research-wave`, `/loop`,
  `session-loop.sh`, `fleet.sh` dispatch, `rlm` tiers, launcher/ledger),
  what part of a plan it already covers, what it lacks, and whether a plan
  would wrap it, replace it, or leave it alone.
- **Decisions** in `decisions.md`: the plan's file format and where it lives;
  how dependencies, parallel groups, loop exit checks, and tier hints are
  expressed; how a plan resumes after a session rollover; what is out of
  scope. Each with the rejected alternative.
- **Build/no-build verdict** recorded in `decisions.md` and this README's
  status line. If build: `spec.md` via `to-spec` and tickets under
  `issues/`. If no-build: the concept note still stands as the reference for
  why the existing pieces suffice.

## Files

- `next-session.md` — forward launcher (what to do next). REPLACED each rollover.
- `handoff.md` — session ledger (what happened). APPEND newest-on-top; archive
  to `handoff-archive.md` when it exceeds the two most recent sessions.
- `concept.md` — the one-page definition + worked example (created by session 1).
- `seams.md` — inventory of existing mechanisms vs. the plan concept (session 1).
- `decisions.md` — Tier-2 decision notes, created when the first decision lands.
