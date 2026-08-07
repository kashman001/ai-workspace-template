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

## 2026-08-05 — Inline the handoff contract instead of vendoring the handoff skill

- **Chose:** inline the three load-bearing rules of the global `handoff` skill
  (reference artifacts by path/URL; include a suggested-skills section; redact
  secrets/PII) directly into `skills/checkpoint/SKILL.md` and
  `skills/session-rollover/SKILL.md`, with a one-line "the global skill may draft,
  the contract binds" note.
- **Because:** both skills named `handoff` as a prerequisite that ships with
  mattpocock/skills, not with this template — downloaders got a broken dependency
  (violates the "template additions are first-class / agent-agnostic" rules).
- **Rejected:** vendoring the whole handoff skill — another pinned copy to
  maintain, for ~10 lines of rules that fit inline.
- **Blast radius:** skills/checkpoint/, skills/session-rollover/, CONTEXT.md
  checkpoint bullet.
- **Promote?:** no (small-scope consistency fix; reversible).

## 2026-08-06 — Demand-load trims: index over split, condense over delete
**Chose:** In-file section index + grep-the-header access note for docs/context-budget.md; shell-heredoc append + 16KB archive rule for decisions.md; condensing (not deleting) CONTEXT.md's graphify / tool-loading / backlog sections.
**Because:** Context audit showed the cost is whole-file loads, not file existence; an index fixes access without breaking the file's 11 inbound pointers, and condensed sections keep every rule reachable via a verified pointer target.
**Rejected:** Splitting context-budget.md into multiple files — churns 11 pointers across docs/skills for the same saving; deleting CONTEXT.md sections outright — graphify rules and backlog discipline are per-session guidance, and recommended-tooling.md §5 circularly pointed back at CONTEXT.md for removal steps.
**Blast radius:** CONTEXT.md, docs/context-budget.md, skills/decision-log/SKILL.md, docs/recommended-tooling.md §5, both backlog HTML files (L25–L27).
**Promote?:** no
