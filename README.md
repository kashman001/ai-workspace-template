<!--
File: README.md
Purpose: Workspace one-pager for humans landing here.
Fill in: replace the description with what THIS workspace coordinates.
See: docs/workspace-structure.md → "Top-Level Layout"
-->

# ai-workspace-template

A reusable starting point for an **AI-agent-aware development workspace** —
a coordination layer that ties together product repos, shared docs, agent
skills, and active work, shared across Claude Code, Codex, OpenCode, and
Gemini.

**Using this template?** Start with the visual setup guide —
**[kashman001.github.io/ai-workspace-template/setup-guide.html](https://kashman001.github.io/ai-workspace-template/setup-guide.html)**
(rendered; diagrams + step-by-step for humans and AI agents). Source:
[`docs/setup-guide.html`](docs/setup-guide.html). Prefer Markdown?
[`docs/template-usage.md`](docs/template-usage.md).

**Looking for a specific doc?** [`docs/README.md`](docs/README.md) indexes
every workspace doc by need (using the workspace · developing your product ·
developing the template).

**Want to see how the workspace is meant to be used?** Two docs:
[`docs/zoom-model.md`](docs/zoom-model.md) — how product knowledge is layered
so agents load only what a task needs — and the scenario catalog
([`work/usage-scenarios/scenarios.md`](work/usage-scenarios/scenarios.md) §3,
E1–E18: lifecycle, personal layer, working loop, knowledge access,
concurrency, team capabilities — an evaluation artifact from template
development; coverage notes there reflect its writing date). The older HTML walkthrough is retired at
[`docs/archive/usage-scenarios.html`](docs/archive/usage-scenarios.html).

**Want the full workspace guide?** Every directory, convention, and the
step-by-step agent bootstrap, rendered for easy reading —
**[kashman001.github.io/ai-workspace-template/workspace-structure.html](https://kashman001.github.io/ai-workspace-template/workspace-structure.html)**
· source [`docs/workspace-structure.md`](docs/workspace-structure.md) (regenerate
the HTML with [`scripts/build-guide-html.sh`](scripts/build-guide-html.sh), which needs
[`pandoc`](https://pandoc.org)).

**Working in a scaffolded workspace?** Start here →
[`CONTEXT.md`](CONTEXT.md)

**Not an engineer?** Status, decisions, and how to contribute — with the
only six terms you need — live in
[`docs/for-non-engineers.md`](docs/for-non-engineers.md).

**Improving the template itself?** Review findings and their status live in the
backlog —
[rendered](https://kashman001.github.io/ai-workspace-template/template-workspace-backlog.html)
· source [`docs/template-workspace-backlog.html`](docs/template-workspace-backlog.html).
See "Maintaining this backlog" in that file for the update convention.
