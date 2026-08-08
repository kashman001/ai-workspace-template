# Brief — usage-scenarios (user input, 2026-08-08)

Seed requirements from the user for the scenario catalog. Treat these as the
requirements the template is evaluated **against** — several are aspirational
(not yet supported); the catalog's job is to expose exactly where.

## User requirements (near-verbatim)

1. **Product instantiation.** A product is onboarded into this workspace
   template to create a real concrete instance of it. The workspace can be put
   into a repo or remain strictly local (perhaps a local repo).
2. **Multi-repo products.** A product can have multiple repos — e.g. a SaaS
   product with multiple services, each with its own repo.
3. **Multiple people, multiple machines.** A person working on the product
   checks out the workspace/repo and works on a particular computer. There can
   be multiple such people.
4. **Per-person local settings.** Each person has their own local settings,
   including secrets for different services. Shared services can have shared
   keyvaults storing shared secrets; each computer can have a local vault.
   Each developer chooses which skills, tools, and MCP servers they want.
   Some tools/skills/services are **non-negotiable** (required for everyone);
   the rest are optional.
5. **Onboarding flows.** Consider three distinct onboardings: a product, a
   repo, and a new user/machine.
6. **Concurrent work items per person.** Each user can work on multiple
   projects at a time within a product; each gets its own work item directory.
7. **Root-level product documentation.** Documentation at the root explains
   the product overall: how it works, how it is built, how to debug it — and
   whatever else belongs at that level.
8. **Context window is a key consideration.** What gets put into the context
   window drives the design.
9. **Abstraction & recursion (the map metaphor).** Top level shows key details
   only; zooming in reveals more — like Google Maps from earth view down to a
   few houses on a street. Docs and context loading should follow this
   zoom-level structure.

## Evaluation directives

- Consider **what the agent harnesses already provide** (Claude Code, Codex,
  Gemini, OpenCode, Copilot) vs. what the template adds — don't rebuild
  harness features.
- Keep **ease of use and utility** in mind.
- Consider **concurrency**: across users, and within a single person's use
  (multiple sessions/work items on one machine).
- The catalog should also drive better **usage docs, internal docs, and
  architecture docs** (not just evaluation/testing).

## Working agreements

- Rollover is hands-free for this work item (`ROLLOVER_RELAUNCH=auto`,
  committed per-item override).
- User checks back later; work proceeds autonomously.
