# Dev-AI Workspace Structure (Generic Template)

This document describes a reusable pattern for organizing a **multi-repo
development workspace** that is shared between humans and AI coding agents
(Claude Code, Codex, Copilot, Gemini, etc.).

The workspace is **not a product repo** — it is a coordination layer that
ties together multiple product repos, shared documentation, reusable agent
skills, project work, and prompt templates. Use this as a starting template
when you need to bring several related repos under a single agent-aware roof.

## Contents

- [Why a Workspace?](#why-a-workspace)
- [Design Principles](#design-principles)
- [Top-Level Layout](#top-level-layout)
- [Agent Entrypoints](#agent-entrypoints)
- [IDE and Agent Configuration](#ide-and-agent-configuration)
- [`docs/` — Workspace Documentation](#docs--workspace-documentation)
- [`skills/` — Agent Skills](#skills--agent-skills)
- [`work/` — Active Project Work](#work--active-project-work)
- [`prompt-library/` — Prompt Contracts](#prompt-library--prompt-contracts)
- [`references/` — External References](#references--external-references)
- [`repos/` — Product Repositories](#repos--product-repositories)
- [`scripts/` — Bootstrap and Utility Scripts](#scripts--bootstrap-and-utility-scripts)
- [Environment Parameterization](#environment-parameterization)
- [Service Access Pattern](#service-access-pattern)
- [Gitignored vs. Checked In](#gitignored-vs-checked-in)
- [Recommended `CONTEXT.md` Sections](#recommended-contextmd-sections)
- [Bootstrapping Your Own Workspace](#bootstrapping-your-own-workspace)
- [Agent Bootstrap Instructions](#agent-bootstrap-instructions)

---

## Agent Bootstrap Instructions

**If you are an AI agent reading this file, follow these steps to scaffold
a new workspace from scratch.** A human invoked you with something like
"set up a dev-ai workspace for project X using this template." Treat the
rest of this document as the *specification* for what you are building.

### Preconditions to confirm with the user

Before creating any files, ask the user for:

1. **Workspace name** — typically `<project>-dev-ai-workspace`.
2. **Workspace location** — absolute path on disk where the workspace
   directory should be created.
3. **Product repos** — name, clone URL, host, default branch, and one-line
   purpose for each. Mark each as **primary** (auto-cloned) or **optional**.
4. **Editor(s) and agent runtime(s)** in use — VS Code, JetBrains, Neovim;
   Claude Code, Codex, Copilot, Gemini. Determines which IDE/agent config
   files to scaffold.
5. **External services** the workspace will integrate with (Jira,
   Confluence, GitHub, Postgres, cloud CLIs, etc.). Determines `.env`
   variables and `service-access.md` entries.
6. **Whether to clone repos now** or only scaffold the registry.

If any answer is unclear, stop and ask — do not guess. Do not invent repo
names or clone URLs.

### Execution rules

- **Create empty, instruction-bearing stub files** for everything listed in
  the structure below. Each stub must contain a short header comment
  explaining what the file is for, what to fill in, and a link back to the
  section of this template that describes it (e.g.,
  `See docs/workspace-structure.md → "skills/ — Agent Skills"`).
- **`CONTEXT.md` is *not* a bare stub.** Populate it with a working
  starting skeleton:
  1. Workspace name and one-paragraph purpose (from preconditions).
  2. A "Repository layout" pointer: `repos/` for clones,
     `docs/repos-registry.md` for the canonical registry.
  3. A "Workspace structure" pointer to `docs/workspace-structure.md`.
  4. An empty "Workspace Skills" section with a TODO note.
  5. The two sections from
     [Recommended `CONTEXT.md` Sections](#recommended-contextmd-sections),
     copied verbatim ("Agent Coding Principles" and "Agent Context
     Discipline").
     This ensures day-1 agents in the new workspace have real behavioral
     guidance instead of an empty file.
- **Do not fabricate content** for repo context docs or skills beyond the
  stub header. Those require human input or a separate generation pass.
- **Copy this template's contents verbatim** to
  `<workspace-root>/docs/workspace-structure.md`. Do not paraphrase or
  trim. The destination file (named `workspace-structure.md`, *not*
  `workspace-structure-template.md`) becomes the authoritative map for the
  new workspace; the original template can be discarded by the user.
- **Use symlinks** for agent entrypoints (`CLAUDE.md`, `AGENTS.md` →
  `CONTEXT.md`). Verify each symlink resolves after creation.
- **Make `scripts/setup.sh` and `scripts/check-workspace-structure.sh`
  executable** (`chmod +x`).
- **`skills/` starts empty.** This bootstrap does *not* install any
  generic skills (`handoff`, `diagnosing-bugs`, etc.). Mention in the final
  summary that the user should add skills as separate next steps.
- **`.env.example` gets seeded placeholders.** For each service named in
  preconditions, add a commented placeholder line (e.g., `# DB_HOST=`,
  `# AWS_PROFILE=`, `# ATLASSIAN_USER=`). Do not invent variables for
  services the user didn't name.
- **Do not commit anything.** Initialize the git repo (`git init`) and
  leave staging to the user.
- **Print a summary** at the end listing every file created, every symlink
  established, and the next manual steps the user must take (add skills,
  fill in repo context docs, set up MCP, clone repos if deferred, etc.).

### Files and directories to create

Create the following tree. Files marked **(stub)** should be created with
the header comment described above; files marked **(template copy)** are
copied from this template's content; files marked **(symlink)** are
symlinks; directories are created with a `.gitkeep` if otherwise empty.

```
<workspace-root>/
├── CONTEXT.md                              (populated — see "Execution rules")
├── CLAUDE.md                               (symlink → CONTEXT.md)
├── AGENTS.md                               (symlink → CONTEXT.md)
├── .gitignore                              (working file — see content below)
├── .env.example                            (stub with seeded service placeholders)
├── README.md                               (stub — one-line pitch + pointer to CONTEXT.md)
│
├── docs/
│   ├── workspace-structure.md              (template copy — this file)
│   ├── workspace-setup.md                  (stub)
│   ├── repos-registry.md                   (stub — pre-populate with repos from preconditions)
│   ├── system-design.md                    (stub)
│   ├── operational-knowledge.md            (stub)
│   ├── service-access.md                   (stub — one section per service from preconditions)
│   ├── mcp-setup.md                        (stub, only if MCP is in use)
│   └── repo-context/
│       ├── README.md                       (stub — index of covered repos)
│       └── <repo>/                         (one folder per covered repo)
│           ├── code-structure.md           (stub)
│           └── design.md                   (stub)
│
├── skills/
│   └── .gitkeep                            (skills are added later by the user)
│
├── work/
│   └── .gitkeep
│
├── prompt-library/
│   └── .gitkeep
│
├── references/
│   └── README.md                           (stub — registry of external repos; keeps dir tracked)
│
├── repos/
│   └── README.md                           (symlink → ../docs/repos-registry.md)
│
└── scripts/
    ├── setup.sh                            (stub, executable)
    ├── check-workspace-structure.sh        (stub, executable)
    └── check-service-access.sh             (stub, executable; only if services exist)
```

Add editor/agent-specific scaffolding **only** for tools the user named in
preconditions:

```
.vscode/
├── settings.json                           (stub — shared IDE settings)
├── mcp.json.example                        (stub — MCP server template)
└── (mcp.json is user-specific, do NOT create)

.claude/
└── (settings.json is user-specific, do NOT create; mention in README)

<Project>.code-workspace                    (stub — multi-root workspace, only if VS Code)
```

### Stub header template

Every stub file must begin with a comment block in the file's native
comment syntax. Example for Markdown:

```markdown
<!--
File: <path-from-workspace-root>
Purpose: <one-line description>
Fill in: <what the human or a follow-up agent should put here>
See: docs/workspace-structure.md → "<section name>"
-->
```

For shell scripts:

```bash
#!/usr/bin/env bash
# File: scripts/setup.sh
# Purpose: Bootstrap the workspace (create .env, symlinks, optional repo clones).
# Fill in: implementation. Must support --clone-repos flag.
# See: docs/workspace-structure.md → "scripts/ — Bootstrap and Utility Scripts"
set -euo pipefail

echo "TODO: implement workspace setup" >&2
exit 1
```

For `.gitignore`, write a working file (not a stub) with at minimum:

```gitignore
# Cloned product repos (registry symlink kept)
repos/*
!repos/README.md

# Cloned external references
references/*
!references/README.md

# Environment and credentials
.env
.service-access.local.json

# User-specific agent / IDE config
.vscode/mcp.json
.claude/settings.json

# Scratch
temp/
tmp/

# OS cruft
.DS_Store

# Stack-specific — include only the entries that apply to your workspace
# .venv/           # Python virtualenv
# node_modules/    # Node deps
# .idea/           # JetBrains IDE files
```

### Post-scaffold verification

After creating everything, run these checks and report results:

1. Every symlink resolves (`readlink` each one; the targets exist).
2. Every script in `scripts/` is executable (`test -x`).
3. `git status` shows every scaffolded file as untracked, `repos/README.md`
   appears tracked (it's a symlink to a tracked target), and no scaffolded
   file is unexpectedly ignored. Confirm with
   `git check-ignore -v <path>` for any file you're unsure about.
4. The `.gitignore` correctly excludes `repos/*` while keeping
   `repos/README.md` visible to git (`git check-ignore -v repos/README.md`
   returns nothing).

If any check fails, fix it before declaring the bootstrap complete.

---

## Why a Workspace?

When a project spans multiple repos, agents and humans repeatedly waste
effort:

- Re-discovering where things live each session.
- Re-deriving system architecture from scratch.
- Losing context when conversations get compacted.
- Stepping on each other's machine-specific config.
- Re-prompting the same skills/workflows in every session.

A workspace solves this by giving every agent (and every human) a single
known place to find context, skills, and active work — without polluting
the underlying product repos.

## Design Principles

1. **Repos are separate.** Product code lives under `repos/`, each with its
   own git history. The workspace repo never commits product source.
2. **Docs live at the workspace level.** Architecture docs, repo navigation
   files, operational knowledge, and setup guides are workspace artifacts —
   not embedded in individual repos.
3. **Skills are reusable.** Agent skills under `skills/` are shared
   instructions that any agent runtime can discover via `CLAUDE.md`,
   `AGENTS.md`, or equivalent.
4. **Work is tracked in files.** Active project state, runbooks, bug
   registries, and session handoffs live under `work/` so agents and humans
   can resume without re-discovering context.
5. **Environment is parameterized.** Machine-specific paths, credentials,
   and infra identifiers are set via environment variables, not hardcoded
   into tracked files.
6. **Agent-vendor neutral.** Anything checked in must work for any agent
   runtime. Tool-specific config (Claude memory, Codex config) lives in
   user-level locations outside the workspace.

---

## Top-Level Layout

```
<your-project>-dev-ai-workspace/
├── CONTEXT.md                  # Master workspace context (agent instructions,
│                               #   repo index, skills, conventions, constraints)
├── CLAUDE.md -> CONTEXT.md     # Symlink — Claude Code entrypoint
├── AGENTS.md -> CONTEXT.md     # Symlink — Codex / generic agent entrypoint
├── README.md                   # Workspace one-pager — short pitch + pointer to CONTEXT.md
├── .gitignore                  # See "Gitignored vs. Checked In" + Agent Bootstrap section
├── <Project>.code-workspace    # VS Code multi-root workspace definition (if using VS Code)
│
├── docs/                       # Workspace-level documentation
├── prompt-library/             # Prompt contracts for repeated outputs
├── references/                 # External/third-party repos (cloned, gitignored)
├── repos/                      # Product repositories (cloned separately, gitignored)
├── scripts/                    # Workspace bootstrap and utility scripts
├── skills/                     # Agent skill definitions (reusable instructions)
├── work/                       # Active project work (in-flight initiatives)
│
├── .claude/                    # Claude Code local state (gitignored)
├── .vscode/                    # VS Code settings and MCP config
│   ├── settings.json           #   Shared IDE settings (checked in)
│   ├── mcp.json.example        #   MCP server config template (checked in)
│   └── mcp.json                #   MCP server config (gitignored, user-specific)
├── .env.example                # Template for required env vars (checked in)
├── .env                        # Local env vars (gitignored)
├── context-budget.env          # Context-budget thresholds (checked in, non-secret)
├── .context-budget/            # Context-budget runtime state (gitignored)
└── temp/, tmp/                 # Scratch files (gitignored, created as needed)
```

The root `README.md` is a one-pager for new humans landing in the
workspace: a one-line description of what the workspace coordinates, plus
a "Start here →" pointer to `CONTEXT.md`. Keep it under 20 lines; agents
read `CONTEXT.md`, not `README.md`.

Optional, depending on stack and tooling:

- `.venv/` — Python virtual environment (gitignored) if any tooling is Python.
- `node_modules/` — Node deps (gitignored) if any tooling is JS/TS.
- `.idea/` — JetBrains IDE files (gitignored) if anyone uses IntelliJ/PyCharm.
- `<Project>.code-workspace` — VS Code multi-root workspace file. Substitute
  the equivalent for your editor (JetBrains `.idea/.iml` modules, Neovim
  project file, etc.), or skip if your team uses single-repo editor windows.

---

## Agent Entrypoints

Every supported agent runtime has its own conventional discovery file. To
avoid forking content, use **one master file with symlinks**:

| File | Purpose | How discovered |
|---|---|---|
| `CONTEXT.md` | Master context — repo index, skills, conventions, constraints | Directly |
| `CLAUDE.md` | Symlink → `CONTEXT.md` | Claude Code reads `CLAUDE.md` automatically |
| `AGENTS.md` | Symlink → `CONTEXT.md` | Codex and most other agents read `AGENTS.md` |

When a new agent runtime appears with a different discovery file, **add a
symlink** — don't fork the content.

### What `CONTEXT.md` Should Contain

Treat `CONTEXT.md` as the front door for any new agent session. Keep it
concise (it loads into every conversation) and link out for detail:

- **Workspace purpose** — one-paragraph description of what this workspace
  coordinates.
- **Repository layout** — pointer to `repos/` and `docs/repos-registry.md`.
- **Covered repos list** — which repos have context docs under
  `docs/repo-context/`.
- **Workspace skills index** — one-line description of each skill in
  `skills/` and when to invoke it.
- **Work directory convention** — naming pattern (e.g.,
  `work/<project-name>/`).
- **Operational constraints** — distilled rules that prevent silent failures
  (shell portability, DB quirks, tool gotchas).
- **Agent coding principles** — behavioral guidance (simplicity, surgical
  changes, ask before assuming).
- **Agent context discipline** — rules for managing the LLM context window
  (disk is source of truth, demand-load, persist intermediate state).
- **Service access** — pointer to credential framework.

---

## IDE and Agent Configuration

The examples below use VS Code and Claude Code. Substitute the equivalents
for your editor and agent runtime — the *pattern* (shared settings checked
in, user-specific config gitignored, templates for new users) applies
regardless of the specific tool.

### `.vscode/` — VS Code

```
.vscode/
├── settings.json               # Shared IDE settings (checked in)
├── mcp.json.example            # MCP server config template (checked in)
└── mcp.json                    # MCP server config (gitignored, user-specific)
```

- **`settings.json`** (checked in) — language/IDE settings that everyone
  benefits from (formatters, language server config, etc.).
- **`mcp.json`** (gitignored) — MCP server definitions for tools like Jira,
  Confluence, GitHub, YouTube transcripts, etc. Points to user-local or
  workspace-local wrapper scripts.
- **`mcp.json.example`** (checked in) — template so new users can copy and
  customize.
- **`<Project>.code-workspace`** (checked in) — VS Code multi-root
  workspace file. Registers each product repo as a workspace root for
  IntelliSense, search, and debugging.

### `.claude/` — Claude Code (Project-Level)

```
.claude/
└── settings.json               # Bash and MCP tool permission allowlist
```

User-specific permission allowlist controlling which Bash commands and MCP
tools Claude Code can run without prompting. Gitignored — permissions are a
personal trust decision. Provide a starter template (`settings.json.example`)
for new users. The template's example also carries the `hooks` block wiring
the context-budget WARN/STOP hook (`docs/context-budget.md`) — copy it into
your `settings.json` to get in-band context warnings.

### User-Level Files (Outside the Workspace)

These live under the user's home directory and are never checked in:

| Path | Tool | Purpose |
|---|---|---|
| `~/.claude.json` | Claude Code | Global settings and project registry |
| `~/.claude/projects/<id>/memory/` | Claude Code | Persistent per-project memory |
| `~/.codex/config.toml` | Codex | Global config including MCP server registrations |
| `~/.mcp-scripts/` | Codex / Claude | User-local wrapper scripts that launch MCP servers |
| `~/.pgpass`, `~/.aws/`, etc. | Various (Postgres, AWS CLI, …) | Credential files for external services — examples only; use whatever your stack needs |

**Important:** persist *project state* (decisions, design notes, in-flight
work) in `work/`, not in agent-specific memory stores. Memory stores are
fine for personal preferences ("I'm a data scientist") but not for shared
project context.

---

## `docs/` — Workspace Documentation

```
docs/
├── workspace-structure.md      # This file — the workspace organization map
├── workspace-setup.md          # How to recreate this workspace from scratch
├── repos-registry.md           # Product repo registry (symlinked from repos/README.md)
├── system-design.md            # Multi-repo system architecture overview
├── operational-knowledge.md    # Distilled rules that prevent silent failures
├── service-access.md           # Credential framework: vault backends, verify commands
├── mcp-setup.md                # MCP server configuration guide
├── context-budget.md           # Context measurement, dumb-zone thresholds, rollover
│
└── repo-context/               # Per-repo architecture and navigation docs
    ├── README.md               #   Index of covered repos
    ├── _templates/             #   Skeletons copied into each repo folder
    └── <repo>/                 #   One folder per covered repo
        ├── code-structure.md   #   Factual navigation ("where is it?")
        ├── design.md           #   Architecture and design ("how does it fit?")
        └── api.md              #   Public surface (service / library / CLI)
```

### Why Per-Repo Context Docs?

When agents work inside a repo, they need orientation faster than
"read every file." Three short docs per repo answer the common questions:

- **`code-structure.md`** — a factual map: where modules live, what each
  directory does, how to find specific functionality.
- **`design.md`** — architecture and component boundaries: how the pieces
  fit together, what's a separate process vs. a library, why.
- **`api.md`** — the repo's public surface (service endpoints, library
  exports, or CLI commands — whichever applies).

Generate them with the **`onboard-repo`** workflow (`/onboard-repo <repo-name>`,
backed by `scripts/onboard-repo.sh` and the skeletons in
`docs/repo-context/_templates/`); each doc carries a provenance block (date +
source commit) and `scripts/check-repo-context.sh` flags when the code has moved
past it. Refresh with `scripts/onboard-repo.sh <repo> --refresh`. They are
workspace artifacts, not committed back to the product repos.

---

## `skills/` — Agent Skills

Reusable workflow definitions any agent runtime can read. Each skill is a
folder with at least a `SKILL.md` describing:

- **When to use** the skill (trigger conditions, examples).
- **Inputs and prerequisites.**
- **Step-by-step workflow.**
- **Outputs and where they land** (typically a `work/<project>/` folder).
- **State and resumption** — where intermediate state is persisted.

```
skills/
├── checkpoint/                 # Session-boundary wrap-up + hand-off doc
├── decision-log/               # Capture the why (commit trailer → note → ADR)
├── onboard-repo/               # Onboard a repo: registry + index + context docs
├── rlm/                        # Recursive Language Model loop for huge contexts
├── session-rollover/           # Deliberate handoff when the context budget hits WARN/STOP
└── <your-domain-skills>/       # Project-specific workflows
```

The template ships with `checkpoint`, `decision-log`, `onboard-repo`, `rlm`, and
`session-rollover`; add your own alongside them. `decision-log` captures decision provenance — the
*why* code can't record — as ephemeral notes under `work/<project>/decisions.md`,
promoted to committed ADRs under `docs/adr/` for lasting-weight decisions.

Skills are agent-vendor-neutral — write them in plain Markdown with no
runtime-specific syntax. List each skill in the `CONTEXT.md` "Workspace
Skills" section with a one-line description so agents can discover them.

### Generic vs. Domain-Specific Skills

- **Generic** (`checkpoint`, `decision-log`, `onboard-repo`, `rlm`) — useful in any project.
- **Domain-specific** — workflows particular to your problem domain
  (testing methodology, bug triage pipeline, deployment runbooks). These
  carry the project's institutional knowledge.

---

## `work/` — Active Project Work

```
work/
├── <project-name>/             # One folder per project
│   ├── README.md               #   Project intent and current state
│   └── <project-specific files>
```

**Naming convention:** `work/<project-name>/`, with hyphens separating
words within the project name.

**Content boundary:** work directories are scoped to the project and owned
by the relevant skill. `CONTEXT.md` may *name* a work directory as a
location pointer but must not list its internal files. File-level structure
belongs in the skill's `SKILL.md`.

**Why this matters for agents:** work directories are where intermediate
state survives context compaction. After producing or consuming any state
that future sessions need, persist it to a file in the relevant work
directory.

---

## `prompt-library/` — Prompt Contracts

Reusable prompt templates that define the output contract for repeated
generation tasks (e.g., per-repo context docs).

```
prompt-library/
└── <output-type>/
    ├── README.md               # Guidance for producing this output
    └── base.prompt.md          # The base prompt contract
```

Skills reference these contracts so the output format stays consistent
across generations and agents.

---

## `references/` — External References

```
references/
├── README.md                   # Registry of external repos (checked in)
└── <cloned-repo>/              # Gitignored
```

A registry of third-party repos (research code, reference implementations,
training material) that the team finds useful. The registry is checked in;
the clones are gitignored.

---

## `repos/` — Product Repositories

Each product repo is cloned here as a separate git repository. The `repos/`
folder itself is gitignored except for a single `README.md` symlink to
`docs/repos-registry.md`. This requires an explicit exception in
`.gitignore`:

```gitignore
repos/*
!repos/README.md
```

Use `repos/*` (the contents) rather than `repos/` (the directory). The
directory-form negation is unreliable across git versions; the
contents-form negation always works.

### Repo Registry Pattern

Keep one canonical registry at `docs/repos-registry.md` listing:

- Repo name and host (GitHub, GitLab, Bitbucket, etc.)
- Clone URL (SSH preferred)
- Default branch
- One-line purpose
- Network requirements (VPN, SSH key, etc.)
- Whether covered by context docs

`scripts/setup.sh` symlinks `repos/README.md` → `docs/repos-registry.md` so
the registry is discoverable from inside `repos/`.

### Primary vs. Optional Repos

Split repos into two tiers:

- **Primary** — required for the workspace to be useful, cloned by
  `setup.sh --clone-repos`.
- **Optional** — listed in the registry, cloned only when a developer needs
  them.

### Handling Mixed Hosts and Restricted-Network Repos

Real projects often have repos on different hosts, or one repo behind a VPN
or corporate firewall. Two patterns work well:

1. **Document network requirements in the registry.** Add a `Network`
   column noting "VPN required", "SSH key X", or "GitHub PAT scope Y".
   `setup.sh` can skip restricted repos by default and emit instructions.
2. **Use a mirror when one exists.** If a VPN-only repo is mirrored to a
   reachable host (e.g., a GitLab repo mirrored to Bitbucket/GitHub), list
   both in the registry under distinct local directory names
   (`repos/foo/`, `repos/foo_mirror/`) so developers can pick whichever
   matches their network access. Note in the registry which is canonical.

---

## `scripts/` — Bootstrap and Utility Scripts

```
scripts/
├── setup.sh                       # Workspace bootstrap (env, symlinks, optional cloning)
├── check-dependencies.sh          # Required/recommended tool preflight
├── check-workspace-structure.sh   # Structural validation against this doc
├── check-service-access.sh        # Credential/service access preflight checker
├── check-repo-context.sh          # Warn-only repo context freshness check
├── onboard-repo.sh                # Mechanical half of repo onboarding
├── build-guide-html.sh            # Regenerate docs/workspace-structure.html
├── context-budget.sh              # Measure agent-session context usage vs threshold
├── hooks/                         # Agent-runtime hook scripts
│   └── context-budget-claude-hook.sh  # Claude Code in-band WARN/STOP hook
├── mcp/                           # Workspace-local MCP servers
│   ├── youtube-transcript.sh      #   YouTube MCP launcher
│   └── youtube_transcript_mcp.py  #   YouTube metadata/caption server
└── tests/                         # Automated workspace validation suite
    ├── validate-workspace.sh      #   Test runner
    ├── test-helpers.sh            #   Shared pass/fail/skip utilities
    ├── test-workspace-integrity.sh
    ├── test-content-consistency.sh
    ├── test-parameterization.sh
    └── test-cross-platform.sh
```

**Required scripts** (start with these):

- `setup.sh` — creates `.env` from `.env.example`, creates required
  symlinks (`CLAUDE.md`, `AGENTS.md`, `repos/README.md`), optionally clones
  repos.
- `check-dependencies.sh` — verifies core tools and warns about optional
  tools such as `yt-dlp` for the YouTube MCP server.
- `check-workspace-structure.sh` — validates that documented directories
  exist, symlinks resolve, and the registry matches the on-disk repos.

**Recommended scripts** (add as the workspace matures):

- `check-service-access.sh` — verifies all required credentials are
  reachable (database, cloud CLI, Atlassian, etc.).
- `scripts/mcp/` — checked-in, credential-free local MCP servers or launchers
  that are safe to share across runtimes. The template ships a YouTube
  transcript server backed by `yt-dlp`.
- A test suite under `scripts/tests/` for catching parameterization
  regressions (no hardcoded secrets, no machine-specific paths in tracked
  files, etc.).

---

## Environment Parameterization

A `.env` file at the workspace root holds machine-specific values. It is
**gitignored**; a tracked `.env.example` template lists every required
variable with placeholder values.

### What Goes in `.env`

- Tool paths (especially for keg-only Homebrew packages, JDK versions, etc.)
- Database hosts, ports, and DB names
- Cloud identifiers (account IDs, subscription GUIDs, project IDs)
- Credential file locations (e.g., `PGPASSFILE`)

### What Does *Not* Go in `.env`

- **Credentials themselves** — passwords, API keys, tokens. These belong in
  the OS keychain / vault, retrieved on demand by scripts.

### What Tracked Files May Contain

- **Infrastructure identifiers** — account IDs, resource group names, DB
  usernames. Safe to include in tracked docs and runbooks; they are useless
  without credentials and provide operational context.
- **Never:** passwords, API keys, tokens, connection strings with embedded
  passwords.

Enforce this with a parameterization test in `scripts/tests/`.

---

## Service Access Pattern

When the workspace integrates with external services (Atlassian, cloud
providers, internal databases), use a **vault-backed credential
framework**:

1. Credentials live in the OS keychain or equivalent vault (macOS Keychain,
   Linux `secret-tool`/`pass`, Windows Credential Manager).
2. A registry file (`docs/service-access.md`) documents each service with:
   - Vault key name
   - Username/account
   - Retrieve command (e.g., `security find-generic-password ...`)
   - Verify command (a low-impact API call to confirm access)
3. A local cache file (`.service-access.local.json`, gitignored) records
   the resolved retrieve commands so agents don't re-discover them.
4. `scripts/check-service-access.sh` performs preflight checks and
   regenerates the cache.

### Minimum Registry Entry Shape

A `docs/service-access.md` entry should give an agent or human everything
needed to authenticate and verify access without guessing:

```markdown
### Atlassian (Jira / Confluence)

- **Vault key**: `atlassian-api-token`
- **Username**: `you@example.com`
- **Retrieve cmd** (macOS): `security find-generic-password -s atlassian-api-token -w`
- **Verify cmd**: `curl -su "$USER:$TOKEN" https://your-org.atlassian.net/rest/api/3/myself`
- **Used by**: MCP `atlassian-*` servers; `scripts/file-bug.sh`
- **Rotation**: every 90 days; rotate at id.atlassian.com → Account → Security
```

This keeps credentials out of `.env`, out of tracked files, and out of
agent conversation history.

---

## Gitignored vs. Checked In

| Path | Checked in? | Why |
|---|---|---|
| `CONTEXT.md`, `CLAUDE.md`, `AGENTS.md`, `GEMINI.md` | Yes | Agent entrypoints (the last three are symlinks → `CONTEXT.md`) |
| `<Project>.code-workspace` | Yes | Shared VS Code workspace definition (VS Code only — create per project if used; not shipped in the template) |
| `docs/`, `skills/`, `prompt-library/` | Yes | Shared documentation and skills |
| `work/` | Yes | Project work and persisted state |
| `references/README.md` | Yes | Registry of external repos |
| `repos/README.md` | Yes (symlink) | Registry of product repos |
| `scripts/` | Yes | Bootstrap and utility scripts |
| `.vscode/settings.json` | Yes | Shared IDE settings |
| `opencode.json`, `.opencode/` | Yes | Shared OpenCode config and plugins |
| `.gemini/settings.json` | Yes | Shared Gemini CLI config (e.g. hooks) |
| `.env.example` | Yes | Template for required env vars |
| `context-budget.env` | Yes | Non-secret context-budget thresholds (a count is never a credential) |
| `.mcp.json.example` | Yes | Template for project-level MCP config |
| `.vscode/mcp.json.example` | Yes | Template for VS Code MCP config |
| `.claude/settings.json.example` | Yes | Template for the Claude Code permission allowlist |
| `.mcp.json` | **No** | User-specific project MCP config (copied from `.mcp.json.example`) |
| `.vscode/mcp.json` | **No** | User-specific MCP paths |
| `.claude/settings.json`, `.claude/settings.local.json` | **No** | User-specific permission allowlist |
| `repos/` (except `README.md`) | **No** | Separate git repos, cloned on setup |
| `references/*/` | **No** | Cloned external repos |
| `graphify-out/` | **No** | Locally regenerated knowledge-graph output |
| `.venv/`, `.idea/`, `temp/`, `tmp/`, `.DS_Store` | **No** | Local-only |
| `.env` | **No** | Environment values |
| `.context-budget/` | **No** | Context-budget runtime state (session registrations, hook stamps) |
| `.service-access.local.json` | **No** | Machine-specific credential cache |

---

## Recommended `CONTEXT.md` Sections

The sections below are not part of the workspace *structure*, but they are
behavioral guidance that every workspace benefits from. Copy them verbatim
(or tailor them) into your `CONTEXT.md` so every agent session starts with
the same expectations.

### Agent Coding Principles

Behavioral guidance that reduces common AI coding mistakes:

1. **Think before coding.** Before answering, say what you'd need to know to
   answer well and name any assumptions you'd otherwise make silently; ask when
   uncertain; surface tradeoffs instead of quietly picking. For trivial changes
   (a typo, an obvious one-liner), use judgement rather than full ceremony.
2. **Simplicity first.** Minimum code that solves the problem. No
   speculative features, no abstractions for single-use code.
3. **Surgical changes.** Touch only what's required. Don't refactor
   adjacent code or "improve" formatting outside the task scope.
4. **Goal-driven execution.** Define verifiable success criteria; loop
   until verified.

### Agent Context Discipline

Rules for keeping the LLM context window healthy across long sessions:

1. **Disk is the source of truth.** Always re-read files before asserting
   facts about them; conversation memory may be compacted.
2. **Demand-load, don't pre-load.** Skills list reads for orientation but
   load files only when the workflow reaches a step that needs them.
3. **Use targeted reads.** `Grep` for specific lines or `Read` with
   `offset`/`limit` rather than full file reads when checking a single
   fact.
4. **Persist intermediate state to disk.** Anything that must survive
   compaction belongs in a file under `work/`, not in conversation memory.
5. **Persist project state in `work/`, not agent-specific stores.** Memory
   systems are for personal preferences, not shared project context.
6. **Sub-agent summaries are hints, not facts.** Verify on disk.

---

## Bootstrapping Your Own Workspace

The authoritative bootstrap procedure is the
[Agent Bootstrap Instructions](#agent-bootstrap-instructions) section above.
Whether you delegate to an AI agent or perform the steps manually, follow
that section — it lists every file and symlink to create, the stub header
format, and the post-scaffold verification checks.

After the initial scaffold, iterate by:

- Generating per-repo context docs (`code-structure.md` + `design.md`) for
  each covered repo using a prompt contract under `prompt-library/`.
- Adding domain-specific skills under `skills/` as workflows stabilize.
- Adding `docs/service-access.md` entries as you integrate new external
  services.
- Refreshing repo context docs when repos change significantly.
