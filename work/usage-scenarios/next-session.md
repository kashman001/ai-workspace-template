# Catchup prompt — usage-scenarios (paste into a new agent session)

We're resuming usage-scenarios. Works in any runtime (Claude Code, Codex,
Gemini, OpenCode) — all read `CONTEXT.md` via their entrypoint.

> **This file is the LAUNCHER (catch-up prompt).** Forward-only, and REPLACED
> at each rollover: it holds what to do next, still-binding constraints, and
> pointers — never session history. Past-tense provenance lives in
> `handoff.md` (the append-only ledger). Convention:
> docs/work-directory-conventions.md.

## Mission (session 3): walk the user through the analysis

Build phase is COMPLETE and merged to main (sessions 1–2). This session is
**interactive**: the user wants to walk through the gap analysis together
and decide what to act on. Do not start building anything until a gap is
explicitly picked.

## Read these, in order

1. `work/usage-scenarios/gaps-and-coverage.md` — the payoff artifact:
   8 ranked gaps, simplicity guardrails (binding don't-build list),
   recommended sequencing. This is the walk-through agenda.
2. `work/usage-scenarios/scenarios.md` — skim §3/§4 headings + §5 matrix
   for reference during discussion; zoom in per-scenario only when the
   user asks.

## Do NOT reload

- `ground-truth.md` — evidence base; open only to verify a specific fact
  the user challenges.
- The session-1 subagent raw reports — gone; ground-truth.md IS the
  distillate.
- docs/context-budget.md, workspace-structure.md, usage-scenarios.html,
  ADRs — mined already; targeted reads only.

## Constraints already decided (do not re-litigate)

- Simplicity guardrails (user, 2026-08-08): per-gap don't-build list in
  gaps-and-coverage.md is binding; prefer documenting over building; push
  back when a simple path exists.
- `ROLLOVER_RELAUNCH=auto` via committed per-item context-budget.env.
- usage-scenarios.html supersede is a recommendation (Gap 7), pending user
  endorsement — likely a walk-through topic.
- Brief req 10 (team capabilities) → E18/Gap 8, docs-only.

## Likely walk-through outcomes (capture as you go)

- Per-gap verdicts: act now / later / won't do → record in decisions.md
  (`/decision`) and update the M15 backlog card when the list settles.
- New work items for picked-up gaps (`/create-work-item`); Gap 1
  (multi-user) wants a wayfinder map if picked.

## State snapshot

- Branch: main (worktree branch merged + deleted at session-2 close).
- Backlog: M15/M16/L32/L33 Open (4). All build tasks done.
- No running processes, no open subagents.
