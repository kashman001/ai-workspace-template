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

## 2026-08-07 — GitHub access: gh CLI required, GitHub MCP fully removed
**Chose:** Delete the GitHub MCP fragment and all wiring (opencode block, PAT-export plumbing, docker dep); promote `gh` to a required dependency verified at setup (`check-dependencies.sh` req + `gh auth login` in the auth runbook).
**Because:** Largest per-server context cost (~900 tokens standing) for tools the ADR-0002 transcript scan showed are almost never used; gh CLI covers the capability at zero standing cost in every runtime.
**Rejected:** Keeping the fragment as a documented escape hatch — doc surface for a path nobody takes; re-add is one 8-line file (recipe kept in mcp-fragments/README.md). Keeping PAT export — its only consumer was the MCP server; gh manages its own keychain credential.
**Blast radius:** mcp-fragments/, opencode.json, .claude/settings.json.example, .mcp.json.example, .vscode/mcp.json.example, scripts/check-dependencies.sh, scripts/check-service-access.sh, docs/{mcp-setup,service-access,workspace-setup,template-usage,recommended-tooling,setup-guide.html,runbooks/*}, ADR-0002 amendment.
**Promote?:** no — implements existing ADR-0002 direction, recorded there as an amendment

## 2026-08-07 — L18 env-knob precedence: capture/restore over default-only env file
**Chose:** Per-variable precedence in `context-budget.sh` — capture explicit env values for the three knobs before sourcing `context-budget.env`, restore after (the `launch-next-session.sh` ROLLOVER_* pattern); plus regression test T16.
**Because:** The old guard keyed on `CONTEXT_DUMB_ZONE_TOKENS` alone, so the env file silently clobbered any other knob's explicit override (bit the M14 lock reclaim live).
**Rejected:** Switching `context-budget.env` to default-only assignments (`: "${VAR:=…}"`) — fixes all consumers in one place but inverts the per-item `work/<proj>/context-budget.env` override chain in `launch-next-session.sh` (global sourced first would win over per-item), and per-item env files are user-authored plain assignments.
**Blast radius:** scripts/context-budget.sh lines 42–52; scripts/tests/test-context-budget-registry.sh (T16).
**Promote?:** no
