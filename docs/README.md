<!--
File: docs/README.md
Purpose: Index of workspace documentation — which doc answers which need.
-->

# Workspace Docs — Index

One row per need. Open only the doc you need (see `docs/zoom-model.md` for
why loading less is the point).

## Using the workspace

| I want to… | Read |
|---|---|
| Instantiate the template for my project | [`template-usage.md`](template-usage.md) (markdown) or the rendered [`setup-guide.html`](setup-guide.html) |
| Get a machine ready (tools, auth) | [`runbooks/`](runbooks/README.md) — paired with `scripts/check-*.sh`; required-vs-optional table in [`recommended-tooling.md`](recommended-tooling.md) |
| Understand the directory layout and conventions | [`workspace-structure.md`](workspace-structure.md) (rendered: [`workspace-structure.html`](workspace-structure.html)) |
| Know what context to load for a task | [`zoom-model.md`](zoom-model.md) |
| Track a multi-session effort under `work/` | [`work-directory-conventions.md`](work-directory-conventions.md) |
| Measure context and roll sessions over | [`context-budget.md`](context-budget.md) |
| Authenticate to services / add a credential | [`service-access.md`](service-access.md) + [`runbooks/authentication.md`](runbooks/authentication.md) |
| Configure MCP servers (lean-by-default) | [`mcp-setup.md`](mcp-setup.md) |
| Onboard or navigate a product repo | [`repos-registry.md`](repos-registry.md), [`repo-context/`](repo-context/README.md) |
| Avoid known build/CI/shell traps | [`operational-knowledge.md`](operational-knowledge.md) |

## Developing your product here

| I want to… | Read |
|---|---|
| Capture what the product is (Z0) | root `SPEC.md` + [`system-design.md`](system-design.md) |
| Add a team capability (script/skill/agent/runbook) | [`workspace-structure.md`](workspace-structure.md) → "Authoring a Team Capability" |
| Record why a decision was made | [`adr/README.md`](adr/README.md) (three tiers; `/decision`) |
| Set up the optional agent toolchain | [`recommended-tooling.md`](recommended-tooling.md) |

## Developing the template itself

| I want to… | Read |
|---|---|
| See open findings / report one | [`template-workspace-backlog.html`](template-workspace-backlog.html) (maintenance convention inside; settled cards: [`template-workspace-backlog-archive.html`](template-workspace-backlog-archive.html)) |
| Run the template's test suites | `scripts/tests/` (nine suites; `test-template-instantiation.sh` clones committed state — commit first) |
| Read retired docs | [`archive/`](archive/) |
