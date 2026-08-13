# Catchup prompt — feedback-intake (paste into a new agent session)

We're resuming feedback-intake. Works in any runtime (Claude Code, Codex,
Gemini, OpenCode) — all read `CONTEXT.md` via their entrypoint.

> **This file is the LAUNCHER (catch-up prompt).** Forward-only, and REPLACED
> at each rollover: it holds what to do next, still-binding constraints, and
> pointers — never session history. Past-tense provenance lives in
> `handoff.md` (the append-only ledger). Convention:
> docs/work-directory-conventions.md.

## >>> START HERE <<<

Objective: design the intake convention for user/production signal (gap G1
of the SDLC map). Nothing designed yet — this is session 1 of real work.

1. `scripts/context-budget.sh register --project feedback-intake`
2. Read the seed context: `work/sdlc-ai-mapping/sdlc-map.md` — gap register
   row G1 plus the N1 and N7 entries (targeted reads; the file is long).
3. Brainstorm/grill the design with the user: where does signal land
   (a `work/…` inbox? a doc convention? a skill?), what forms it takes,
   and which existing skill consumes each form (`triage`, `to-spec`, `rlm`).
4. Decide skill-vs-doc-vs-convention per `docs/workspace-structure.md` →
   "Authoring a Team Capability", then implement.

## Constraints already decided (do not re-litigate)

- Scope is the *routing convention*, not new analysis tooling — `rlm`,
  `triage`, `to-spec` already exist and should be consumed, not duplicated
  (`work/sdlc-ai-mapping/decisions.md`, 2026-08-13 gap dispositions).
- Postmortem convention is **not** this effort — that's gap G6, a template
  backlog card.
- Must be agent-agnostic and shipped for downloaders (project memory:
  template additions are first-class).

## Read these first, in order

1. `work/feedback-intake/README.md`
2. `work/feedback-intake/handoff.md` (top block)
3. `work/sdlc-ai-mapping/sdlc-map.md` — G1 row + N1/N7 entries (targeted)
