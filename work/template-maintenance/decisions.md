# Decisions — template-maintenance (Tier-2 notes)

## 2026-08-05 — Vendor writing-for-agents as a skill, not a docs page

- **Chose:** vendor upstream `writing-for-agents` into `skills/writing-for-agents/`
  (wayfinder pattern: pinned commit, provenance comment, refresh procedure;
  includes `SKILL-MECHANICS.md` + `agents/openai.yaml`).
- **Because:** its frontmatter triggers exactly when we want it loaded
  (creating/editing skills, touching AGENTS.md/CLAUDE.md) — active guidance;
  agent-agnostic for template downloaders.
- **Rejected:** copying it under `docs/` — passive reference nobody re-finds;
  loses model-invocation triggering.
- **Blast radius:** skills/, CONTEXT.md, docs/recommended-tooling.md, backlog.
- **Promote?:** no (pattern already ADR-adjacent via wayfinder precedent).
