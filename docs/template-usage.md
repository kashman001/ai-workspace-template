<!--
File: docs/template-usage.md
Purpose: How to turn this template into a real project workspace.
See: docs/workspace-structure.md → "Agent Bootstrap Instructions"
-->

# Using this template

`ai-workspace-template` is a generic, agent-aware workspace scaffold. Every
project-specific value is a `<…>` placeholder or a stub with a header
comment. Turn it into a real workspace like this.

## 1. Create your workspace from the template

On GitHub, use **"Use this template"** (or clone and re-init git):

```bash
git clone https://github.com/<you>/ai-workspace-template.git <your-project>-workspace
cd <your-project>-workspace
rm -rf .git && git init
```

## 2. Fill in the placeholders

Replace every `<…>` placeholder and resolve the `TODO` / "Fill in" comments:

- **`CONTEXT.md`** — workspace name, one-paragraph purpose, single- vs
  multi-repo model. This is the front door every agent reads; do it first.
- **`README.md`** — the human one-pager. Drop the template framing.
- **`SPEC.md`** — product intent (single-repo) or delete it (pure multi-repo
  coordination layer).
- **`docs/repos-registry.md`** — one entry per product repo.
- **`docs/service-access.md`** — your GitHub username; add a section per extra
  service.
- **`.env.example`** — add a commented placeholder per service identifier.
- **`docs/system-design.md`, `operational-knowledge.md`, `workspace-setup.md`,
  `docs/repo-context/README.md`** — fill in as the project takes shape.

A fast way to find what's left:

```bash
grep -rIn --exclude-dir=.git -e '<[a-z-]\+>' -e 'TODO' -e 'Fill in:' .
```

## 3. Wire up agents & MCP

- Agent entrypoints are symlinks (`CLAUDE.md`, `AGENTS.md`, `GEMINI.md` →
  `CONTEXT.md`) — already created.
- Copy `.claude/settings.json.example` → `.claude/settings.local.json` and
  tailor permissions (gitignored).
- Copy `.mcp.json.example` → `.mcp.json` for Claude Code (gitignored).
- GitHub MCP, the workspace-local YouTube transcript MCP server, graphify MCP,
  and per-runtime notes (Claude/Codex/Gemini/OpenCode) are in
  `docs/mcp-setup.md`. Export the GitHub token before launching an agent:
  `export GITHUB_PERSONAL_ACCESS_TOKEN="$(gh auth token)"`.

## 4. Decide on the optional bits

- **graphify** — wired by default (`.gemini/settings.json`,
  `.opencode/plugins/graphify.js`, the `CONTEXT.md` graphify section). If you
  don't use it, delete those and the `.opencode/opencode.json` plugin entry.
- **Skills** — `skills/` ships with four reusable workflows: **checkpoint**
  (session-boundary wrap-up), **onboard-repo** (bring a repo into the workspace),
  **rlm** (Recursive Language Model loop for querying contexts too large to
  read into chat), and **decision-log** (capture the *why* behind a decision as a
  commit trailer + an ephemeral note in `work/<proj>/decisions.md`, promoted to a
  committed ADR under `docs/adr/` for lasting-weight calls). Add your own as needed
  and list each in `CONTEXT.md` → "Workspace Skills". Drop any you don't want (e.g.
  `rlm`'s leaf sub-LM is a nested `claude -p`, so it's most useful with Claude Code).
- **Scripts** — `scripts/setup.sh` (symlinks, config copies, `--clone-repos`),
  `check-workspace-structure.sh`, and `check-service-access.sh` are functional
  out of the box; extend them as the workspace grows.
- **Agent toolchain** — optional global tools (Claude Code status line,
  superpowers plugin, Matt Pocock engineering skills, Karpathy principles,
  graphify) are documented in `docs/recommended-tooling.md`, including the
  per-repo setup for graphify graphs and Matt Pocock config.

## 5. Reference

`docs/workspace-structure.md` is the authoritative map of the whole layout
and includes step-by-step **Agent Bootstrap Instructions** — point an agent
at that section to scaffold or extend a workspace.
