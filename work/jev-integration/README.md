# jev-integration — Evaluate and (if it fits) integrate TypeSafe's Jev model into this template

Governing skill(s): `research-wave` (session 1), then `grill-with-docs` →
`to-spec` → `to-tickets` once the research settles whether and where it fits.

**Start here:** `next-session.md` (catch-up launcher) → `handoff.md`
(session ledger, top block).

**Status (2026-09-25):** research wave 1 complete — synthesis at
`research/synthesis.md`; live spike run with the user's key (`research/spike.md`,
2026-09-24) closing the open facts; fit decision still pending — posed in
session 6, four questions open in `next-session.md` (to be recorded in
`decisions.md`).

## What this is

[Jev](https://typesafe.ai) is TypeSafe's "first public System One Model,
optimized for automation": an API model that returns **typed decisions with
confidence estimates** instead of text, sold on not hallucinating and needing
no human in the loop, at a per-token price far below chat models (docs:
<https://docs.typesafe.ai/>, console: <https://console.typesafe.ai/>). This
item finds out what Jev actually is and offers, whether any of this
template's automation seams want a typed-decision model (candidates: the `rlm`
leaf classifier, `triage` categorisation, `doc-review`, the session-loop's
stall/halt judgement, the ledger and backlog checks), and if so, ships the
integration the way the template ships everything else: agent-agnostic
(Codex, Gemini, OpenCode and downloaders, not only Claude Code), CLI-first or
an `mcp-fragments/` entry, credentials in the OS keychain, documented in
`docs/service-access.md`.

Session 1 is research only: a `research-wave` over the questions in the
launcher, findings fact-checked before anything is claimed. No code until a
decision note says where Jev fits.

## Success criteria

<!-- No spec.md yet; one is written via to-spec only if the research says "go". -->

- **Research record** under `research/`: fact-checked, source-cited answers
  to what Jev is (model class, API surface, request/response schema, SDKs,
  latency), its terms (pricing, limits, auth, data retention, licensing, any
  evaluation tier), and how it is meant to be integrated (SDK, HTTP, MCP).
- **Fit decision** in `decisions.md`: which template seam(s) a typed-decision
  model serves better than the current runtime (or none), with the rejected
  alternatives and the evidence from `research/`.
- **If go:** `spec.md` (via `to-spec`) and tickets under `issues/`; the
  integration lands agent-agnostic, credential-safe, and documented for
  downloaders, with a test that proves it without a live key.
- **If no-go:** the item closes through the stop door with the reasoning
  recorded in `decisions.md` and this README's status line.

## Files

- `next-session.md` — forward launcher (what to do next). REPLACED each rollover.
- `handoff.md` — session ledger (what happened). APPEND newest-on-top; archive
  to `handoff-archive.md` when it exceeds the two most recent sessions.
- `research/<subject>/` — one directory per research-wave subject (pass,
  fact-check, corrections), created by session 1.
- `decisions.md` — Tier-2 decision notes, created when the first decision lands.
- `context-budget.env` — per-item relaunch policy (`auto`) so `scripts/session-loop.sh jev-integration` chains unattended.
