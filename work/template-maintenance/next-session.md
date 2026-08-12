> **This file is the LAUNCHER (catch-up prompt).** Forward-only, and REPLACED
> at each rollover: it holds what to do next, still-binding constraints, and
> pointers — never session history. Past-tense provenance lives in `handoff.md`
> (the append-only ledger). Convention: docs/work-directory-conventions.md.

## Mission

**Work the house-sale-derived backlog cards, in order: M26 → L36 → L37**
(filed 2026-08-12 from the house-sale instance evidence pass, commit
`bc0f682`; cards in `docs/template-workspace-backlog.html`):

- **M26** — document a supported no-git ("private") workspace mode: privacy
  posture in CONTEXT.md template text, Tier-1 decision capture fallback
  (dated decisions.md line when no commits), mark git-dependent machinery
  N/A in this mode. Labeling, not new machinery.
- **L36** — extend template-usage §5 prune list beyond `work/` to
  template-only files; consider interactive prune in `scripts/setup.sh`;
  verify template-update flow triggers the M19 ledger-migration shim.
- **L37** — portable agent brief: lightweight convention (or small skill)
  for sealed, dated, self-contained briefs to out-of-workspace agents, with
  supersession header + never-reveal section; document next to the
  dispatch-record pattern in work-directory-conventions.

Resolve each card with a `Fixed:` note (card moves to the archive pair) per
the backlog's "Maintaining this backlog" section.

One optional thread from the 2026-08-06 context audit, awaiting user appetite:
trim the remaining empty-session floor — workspace-level GitHub MCP was
removed 2026-08-07 (L30, commit `2ba9f11`). Still open, both user-global:
claude.ai connectors (~410 tokens, claude.ai settings) and the superpowers
plugin (~1.8K). Numbers: `handoff.md` (2026-08-06 block), Learnings.

## Read these, in order

1. `work/template-maintenance/handoff.md` (top block) — what last shipped.

## Do NOT reload

- The 2026-08-06 context-audit methodology — settled; the durable gotchas are
  in `docs/operational-knowledge.md` (/context under-report; concurrent
  registry clobber).
- L17/L18 and L25–L30 details — resolved cards in
  `docs/template-workspace-backlog-archive.html`; don't re-open.
- `docs/context-budget.md` whole-file — it has a section index; grep the
  header you need.

## State snapshot

- Branch `main`, clean, pushed through `b366240` (L17+L18 merged
  2026-08-07 at user direction; the feature branch is deleted).
- Vendored skill pins: `wayfinder` and `writing-for-agents` at upstream
  `8b36d4f` (clone: `~/Developer/references/mattpocock-skills`).

## First actions

1. `scripts/context-budget.sh register` (skip if the Claude Code SessionStart
   hook already ran it).
2. Ask the user (or run a fresh evidence pass) for the next task.
