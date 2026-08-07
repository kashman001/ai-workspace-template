> **This file is the LAUNCHER (catch-up prompt).** Forward-only, and REPLACED
> at each rollover: it holds what to do next, still-binding constraints, and
> pointers — never session history. Past-tense provenance lives in `handoff.md`
> (the append-only ledger). Convention: docs/work-directory-conventions.md.

## Mission

**No queued mission.** Template-maintenance is the umbrella for general
template upkeep. The backlog (`docs/template-workspace-backlog.html`) is at
**0 Open cards** — pick up new work from user direction, or from findings a
fresh evidence pass surfaces.

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

- L17+L18 fixes live on branch `worktree-l17-l18-backlog-fixes` (pushed),
  awaiting user merge to `main` — the session that shipped them was
  worktree-isolated and does not push to main. Merge is a fast-forward-able
  `git merge worktree-l17-l18-backlog-fixes` from an up-to-date main.
- Vendored skill pins: `wayfinder` and `writing-for-agents` at upstream
  `8b36d4f` (clone: `~/Developer/references/mattpocock-skills`).

## First actions

1. `scripts/context-budget.sh register` (skip if the Claude Code SessionStart
   hook already ran it).
2. If `worktree-l17-l18-backlog-fixes` is unmerged, ask the user to merge it
   (or confirm and merge) before further backlog work — it carries the
   backlog/archive card moves.
3. Ask the user (or run a fresh evidence pass) for the next task.
