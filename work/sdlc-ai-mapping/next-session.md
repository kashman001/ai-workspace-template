# Catchup prompt — sdlc-ai-mapping (paste into a new agent session)

We're resuming sdlc-ai-mapping. Works in any runtime (Claude Code, Codex,
Gemini, OpenCode) — all read `CONTEXT.md` via their entrypoint.

> **This file is the LAUNCHER (catch-up prompt).** Forward-only, and REPLACED
> at each rollover: it holds what to do next, still-binding constraints, and
> pointers — never session history. Past-tense provenance lives in
> `handoff.md` (the append-only ledger). Convention:
> docs/work-directory-conventions.md.

## >>> START HERE <<<

The effort is **complete pending user sign-off**: the map is user-reviewed,
and all gap dispositions are executed (two work items scaffolded, four
backlog cards filed — see `handoff.md` top block). All three README success
criteria are met.

1. `scripts/context-budget.sh register --project sdlc-ai-mapping`
2. If the user signs off: run `checkpoint` to close this work item (update
   `work/README.md` status to closed/dormant); real work continues in
   `work/feedback-intake/` and `work/quality-gates/`.
3. If the user has feedback on the executed dispositions, apply it here
   (map/register edits) before closing.

## Constraints already decided (do not re-litigate)

- Graph model: N5 and N8 are real nodes; overlay per node with lane tags —
  `decisions.md` 2026-08-12.
- Gap dispositions (incl. G2+G3 merge, G7 out of scope) — `decisions.md`
  2026-08-13. Now executed; see the gap register's disposition column.
- Two views (numbered list + mermaid graph) are both kept on purpose.
- Evidence tiers ([measured]/[established]/[heuristic]/[hype]) come from
  `research-modern-qa.md`; don't restate claims without them.

## Read these first, in order

1. `work/sdlc-ai-mapping/README.md`
2. `work/sdlc-ai-mapping/handoff.md` (top block)
