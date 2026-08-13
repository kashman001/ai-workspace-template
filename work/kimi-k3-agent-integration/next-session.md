# Catchup prompt — Kimi K3 Agent Integration (paste into a new agent session)

We're resuming kimi-k3-agent-integration. Works in any runtime (Claude Code,
Codex, Gemini, OpenCode) — all read `CONTEXT.md` via their entrypoint.

> **This file is the LAUNCHER (catch-up prompt).** Forward-only, and REPLACED
> at each rollover: it holds what to do next, still-binding constraints, and
> pointers — never session history. Past-tense provenance lives in
> `handoff.md` (the append-only ledger). Convention:
> docs/work-directory-conventions.md.

## >>> START HERE <<<

Objective: pick the runtime for driving this workspace with Kimi K3, then
design the integration. Research is DONE (findings in `handoff.md` top block);
the runtime decision is the open item.

1. Read `handoff.md` (top block) — runtime comparison + recommendation.
2. Ask the user to decide among:
   a. **OpenCode + Moonshot provider, with a Claude Code env-var trial first
      (recommended)** — trial to judge K3 quality, then durable OpenCode wiring.
   b. OpenCode only (skip trial).
   c. Claude Code → Moonshot Anthropic-compatible endpoint as the main setup.
   d. Kimi Code CLI as a new seventh runtime (advised against for now — churn).
3. Record the decision (`/decision …`, Tier-2 note in this work dir), then
   brainstorm → design doc → implementation plan (superpowers flow), covering:
   provider/API-key config, model selection, and any template wiring
   (context-budget hooks, launcher support, docs for downloaders).

## Constraints already decided (do not re-litigate)

- **API-key only** — Moonshot subscriptions unavailable; all options must work
  pay-per-token (verified: K3 is fully available via platform.kimi.ai keys,
  ~$3/$15 per M tokens).
- Any integration must be agent-agnostic-friendly and shipped/documented for
  template downloaders (project memory: template additions are first-class).

## Read these first, in order

1. `work/kimi-k3-agent-integration/README.md`
2. `work/kimi-k3-agent-integration/handoff.md` (top block)
