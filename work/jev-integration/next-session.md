# Catchup prompt — jev-integration (paste into a new agent session)

We're resuming `jev-integration`. Works in any runtime (Claude Code, Codex,
Gemini, OpenCode) — all read `CONTEXT.md` via their entrypoint.

> **This file is the LAUNCHER (catch-up prompt).** Forward-only, and REPLACED
> at each rollover: it holds what to do next, still-binding constraints, and
> pointers — never session history. Past-tense provenance lives in
> `handoff.md` (the append-only ledger). Convention:
> docs/work-directory-conventions.md.

## >>> START HERE <<<

Position: item scaffolded, no research done. Objective for this session:
run a `research-wave` on Jev (TypeSafe's typed-decision "System One Model",
<https://typesafe.ai>) so the next session can rule on whether and where it
fits this template. Research only — no integration code, no spec yet.

1. `scripts/context-budget.sh register --project jev-integration` (first
   registered session of this item; expect `seq=1`).
2. Read `README.md` here ("What this is" + success criteria), then open
   `skills/research-wave/SKILL.md` and follow it as the orchestrator: rule,
   do not research. Subject directories go under
   `work/jev-integration/research/<subject>/`.
3. Fix the subject list before launching anything. Proposed (adjust, do not
   expand past four — each subject costs five to eight agents):
   - **what-jev-is** — what a "System One Model" is per TypeSafe's own docs
     and launch post (`typesafe.ai/blog/introducing-system-one-models-and-jev`);
     the API surface: endpoints, request/response schema, how a decision and
     its confidence come back, SDKs, latency, model versions.
   - **terms** — pricing (the site claims "$42 per billion input tokens" and
     "production prices"), rate limits, auth (console API keys), data
     retention and privacy, licence/terms of service, any free or evaluation
     tier.
   - **integration-paths** — how TypeSafe intends Jev to be called (SDKs,
     plain HTTP, MCP server, CLI), what examples exist, and how it behaves on
     inputs outside its decision schema.
   Landmines to put in each pass brief: the site is marketing copy — every
   number must trace to docs or the console; "no hallucinations" is a claim,
   not a finding; do not confuse Jev with other products named jev/JEV.
4. Phase 4 synthesis lands in `research/synthesis.md`: the corrected facts,
   and a first, explicitly provisional list of template seams a typed-decision
   model could serve (`rlm` leaf classification, `triage`, `doc-review`,
   session-loop stall/halt judgement, ledger/backlog checks) with what each
   would need from the API. The fit **decision** is the next session's job
   (`grill-with-docs`, then a `decisions.md` note), not this one's.
5. At `scripts/context-budget.sh record` WARN/STOP or when the wave is done:
   ledger block on `handoff.md` (`# Session Handoff — 1 (<date>): …`),
   rewrite this launcher for the fit-decision session, update the
   `work/README.md` row, commit. Do not push main; report how far ahead it is.

## Constraints already decided (do not re-litigate)

- Template rules apply to anything that ships: agent-agnostic (works for
  Codex/Gemini/OpenCode and downloaders, not only Claude Code), CLI-first or
  `mcp-fragments/`, credentials in the keychain (`docs/service-access.md`),
  documented as a first-class template addition.
- Research before design: no integration code or spec until a fit decision
  is recorded in `decisions.md`.
- `research-wave` is the session-1 workflow (user's choice, 2026-09-22).

## Read these first, in order

1. `work/jev-integration/README.md`
2. `work/jev-integration/handoff.md` (top block)
3. `skills/research-wave/SKILL.md` (when step 2 reaches it)
