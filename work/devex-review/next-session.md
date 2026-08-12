# Catchup prompt — DevEx Review (paste into a new agent session)

We're resuming devex-review. Works in any runtime (Claude Code, Codex, Gemini,
OpenCode) — all read `CONTEXT.md` via their entrypoint.

> **This file is the LAUNCHER (catch-up prompt).** Forward-only, and REPLACED
> at each rollover: it holds what to do next, still-binding constraints, and
> pointers — never session history. Past-tense provenance lives in
> `handoff.md` (the append-only ledger). Convention:
> docs/work-directory-conventions.md.

## Mission

The DevEx review is done (session 1); this session PLANS THE FIX WORK with the
user. Turn the review's prioritized fix list into an agreed, sequenced plan —
what to fix, in what order, at what scope — and file the backlog candidates.

## Read these, in order

1. `work/devex-review/findings/devex-review.md` — the synthesis: 6 themes,
   prioritized 7-item fix list, backlog-card candidates (bottom section).
2. `work/devex-review/handoff.md` (top block only).
3. Raw persona reports (`findings/dev-persona.md`, `pm-persona.md`,
   `qa-persona.md`) — demand-load per finding while planning; do NOT read whole
   up front.

## Do NOT reload

- The persona review process/prompts — reviews are complete; never re-dispatch.
- `docs/context-budget.md`, `docs/workspace-structure.md` in full — the review
  already extracted what matters; findings cite exact lines.

## Constraints already decided (do not re-litigate)

- Specs are load-bearing for QA — test plans depend on them (user directive).
- Specs for major initiatives are a PM+dev collaboration, mix varying by
  project (user directive) — spec-workflow fixes must support this.
- Review scope was read-only; fixes were deliberately deferred to planning.

## State snapshot

- Branch: `main`, clean except `work/kimi-k3-agent-integration/` (another
  effort's untracked item — leave it alone).
- `work/devex-review/` committed. No running processes, no open agents.

## First actions

1. `scripts/context-budget.sh register --project devex-review`
2. File backlog candidates from `findings/devex-review.md` (bottom section)
   into `docs/template-workspace-backlog.html` per its "Maintaining this
   backlog" section (targeted edits — grep IDs, never load whole).
3. With the user, sequence the 7-item fix list into work packages (candidate
   split: (a) clean day-1 state, (b) spec workflow + QA seat, (c) setup
   correctness pass, (d) PM entry point, (e) minimal-mode docs). Decide
   whether this stays one work item or spawns a wayfinder map.
