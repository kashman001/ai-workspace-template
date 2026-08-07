> **This file is the LAUNCHER (catch-up prompt).** Forward-only, and REPLACED
> at each rollover: it holds what to do next, still-binding constraints, and
> pointers — never session history. Past-tense provenance lives in `handoff.md`
> (the append-only ledger). Convention: docs/work-directory-conventions.md.

## Mission

**No queued mission.** Template-maintenance is the umbrella for general
template upkeep: pick up new work from `docs/template-workspace-backlog.html`
(2 Open cards) or user direction.

One optional thread from the 2026-08-06 context audit, awaiting user appetite:
trim the remaining empty-session floor — workspace-level GitHub MCP was
removed 2026-08-07 (L30, commit `2ba9f11`; user scope confirmed clean —
no `mcpServers` in `~/.claude.json`). Still open, both user-global:
claude.ai connectors (~410 tokens, claude.ai settings) and the superpowers
plugin (~1.8K). Numbers: `handoff.md` top block, Learnings.

## Read these, in order

1. `work/template-maintenance/handoff.md` (top block) — what last shipped.

## Do NOT reload

- The 2026-08-06 context-audit methodology — settled; the durable gotchas are
  in `docs/operational-knowledge.md` (/context under-report; concurrent
  registry clobber).
- L25–L29 details — resolved cards in
  `docs/template-workspace-backlog-archive.html`; don't re-open.
- `docs/context-budget.md` whole-file — it now has a section index; grep the
  header you need.

## State snapshot

- Branch `main`, clean, pushed through `a3da781` (L29).
- Vendored skill pins: `wayfinder` and `writing-for-agents` at upstream
  `8b36d4f` (clone: `~/Developer/references/mattpocock-skills`).

## First actions

1. `scripts/context-budget.sh register` (skip if the Claude Code SessionStart
   hook already ran it).
2. Ask the user (or check the backlog) for the next template-maintenance task.
