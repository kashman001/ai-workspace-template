# Catchup prompt — quality-gates (paste into a new agent session)

We're resuming quality-gates. Works in any runtime (Claude Code, Codex,
Gemini, OpenCode) — all read `CONTEXT.md` via their entrypoint.

> **This file is the LAUNCHER (catch-up prompt).** Forward-only, and REPLACED
> at each rollover: it holds what to do next, still-binding constraints, and
> pointers — never session history. Past-tense provenance lives in
> `handoff.md` (the append-only ledger). Convention:
> docs/work-directory-conventions.md.

## >>> START HERE <<<

Objective: design the quality-enablement lane's deliverables (gap G2+G3 of
the SDLC map). Nothing designed yet — this is session 1 of real work.

1. `scripts/context-budget.sh register --project quality-gates`
2. Read the seed context: `work/sdlc-ai-mapping/sdlc-map.md` — gap register
   rows G2/G3, the N4 entry, and the cross-cutting-lanes table (targeted
   reads; the file is long). For evidence tiers behind any tooling claim,
   `work/sdlc-ai-mapping/research-modern-qa.md` is the source.
3. Start with G3 (agreed first deliverable): CI quality-gate guidance —
   which gates, AI failure-triage, flake policy. Decide with the user
   whether it lands as a doc (`docs/…`), a skill, or both, per
   `docs/workspace-structure.md` → "Authoring a Team Capability".
4. Then scope the broader lane: test-infrastructure guidance and AI
   test-tooling adoption criteria (evidence-tier-aware).

## Constraints already decided (do not re-litigate)

- G3 is merged into this effort; gate policy is its **first** deliverable
  (`work/sdlc-ai-mapping/decisions.md`, 2026-08-13 gap dispositions).
- Respect the evidence tiers from `research-modern-qa.md` — don't restate
  tooling claims without them; don't recommend [hype]-tier tooling.
- Release engineering (G7) stays out of scope — runbooks + `wizard` are the
  escape hatch.
- Must be agent-agnostic and shipped for downloaders (project memory:
  template additions are first-class).

## Read these first, in order

1. `work/quality-gates/README.md`
2. `work/quality-gates/handoff.md` (top block)
3. `work/sdlc-ai-mapping/sdlc-map.md` — G2/G3 rows + N4 entry + lane table
   (targeted)
