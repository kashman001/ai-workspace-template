<!--
File: docs/recommended-tooling.md
Purpose: The external agent toolchain this workspace assumes — what each tool is,
         how to install it (global/per-machine), and any per-repo setup.
See: docs/workspace-structure.md → "User-Level Files (Outside the Workspace)"
-->

# Recommended Agent Toolchain

These are the external tools and skill sets the workflow in this workspace
assumes. They are **global / per-user** — installed once per machine under
your home directory (`~/.claude/`, `~/.config/`, `uv tool`, Claude Code
plugins), **not** committed to this repo. That keeps the workspace
agent-vendor-neutral (see `docs/workspace-structure.md` → "User-Level Files
(Outside the Workspace)").

## Required for everyone

Not everything is optional. The workspace's workflow hard-requires a small
set; `scripts/check-dependencies.sh` (`req` lines) and
`scripts/check-service-access.sh` (required block) are the machine-readable
manifest — they exit 1 while anything below is missing:

| Requirement | Why it's non-negotiable |
|---|---|
| `git` | Clone, symlinks, registry — nothing works without it |
| `gh`, authenticated | The workspace's only GitHub path (auth, PRs, API) |
| `jq` | `scripts/context-budget.sh` — every session start/record runs it |
| context-budget hook wiring | The in-band WARN/STOP push (`docs/context-budget.md`); ships committed in `.claude/settings.json` for Claude Code |

Teams add their own non-negotiables the same way: a `req` line per binary, a
required block per service (see `docs/workspace-structure.md` → "Authoring a
Team Capability").

Everything **below** is optional — the workspace works without it. Set up
what matches how you work.

| Tool | What it gives you | Scope |
|---|---|---|
| Claude Code status line | Two-line status bar (model · context% · cost · clock · git branch) | Global |
| superpowers plugin | Process skills: brainstorming, TDD, systematic debugging, plan execution, code review | Global |
| Matt Pocock engineering skills | `tdd`, `grill-with-docs`, `domain-modeling`, `codebase-design`, `implement`, `code-review`, `diagnosing-bugs`, `to-spec`/`to-tickets`, `triage`, `improve-codebase-architecture`, `handoff`, `teach` | **Vendored in-repo** (`skills/vendored-skills.md`) + **per-repo** config |
| Karpathy coding principles | The four always-on principles + `karpathy-examples` calibration skill | Global (principles already in `CONTEXT.md`) |
| graphify | Codebase → queryable knowledge graph (`graphify-out/`) | Global CLI + **per-repo** graph |

---

## Skill management — the agent-context system

The skill sets (tools 3–4, and graphify's skill) are managed through
**agent-context**: one canonical home at `~/.config/agent-context/` that every
agent and project reads via symlinks, so editing once propagates everywhere.
Its `README.md` is the authority; the essentials:

- **Canonical dir** `~/.config/agent-context/` holds `global.md` (always-on
  principles + skills index) and `skills/` (one dir/symlink per skill).
- **Home symlinks** make it reach each agent:
  `~/.claude/CLAUDE.md`, `~/.codex/AGENTS.md`, `~/.gemini/GEMINI.md` → `global.md`;
  `~/.claude/skills` → `~/.config/agent-context/skills`.
- **Reference repos** are cloned under `~/Developer/references/` and their
  skill folders are *symlinked* (not copied) into `skills/`, so a `git pull`
  updates every project at once.
- **Two helpers on `PATH`** (`~/.local/bin/`):
  - `init-project-ai-infra [--full]` — wires a project: writes `CONTEXT.md`
    from the template and symlinks `CLAUDE.md`/`AGENTS.md`/`GEMINI.md` → it
    (`--full` also scaffolds `docs/adr/` + `docs/agents/`).
  - `agent-context-sync` — pulls the reference repos, links any new upstream
    skills, and flags broken symlinks.
- **Overridable** via `AGENT_CONTEXT_DIR` and `AGENT_REFERENCES_DIR`.

> **Prerequisite.** The commands below assume the agent-context system is
> already bootstrapped on the machine — see `~/.config/agent-context/README.md`.
> Don't have it? Use the **fallback** below instead.
>
> **Note for template-cloned workspaces:** a workspace created from this
> template already ships `CONTEXT.md` + the `CLAUDE.md`/`AGENTS.md`/`GEMINI.md`
> symlinks, so `init-project-ai-infra` won't need to create them. It's still
> worth running **`init-project-ai-infra --full`** in the workspace to scaffold
> `docs/adr/` and `docs/agents/` (which the Matt Pocock skills expect) — it's
> idempotent and never overwrites your existing `CONTEXT.md`. (The four
> principles also live in `global.md`; this template copies them into
> `CONTEXT.md` too so the workspace is self-contained even without agent-context.)

### Without agent-context (fallback)

If you don't run the agent-context system, you can still use any of these
skills directly — clone the repo and symlink the skill folders straight into
Claude Code's skills dir:

```sh
mkdir -p ~/.claude/skills
git clone https://github.com/mattpocock/skills.git ~/Developer/references/mattpocock-skills
ln -sfn ~/Developer/references/mattpocock-skills/skills/engineering/tdd ~/.claude/skills/tdd
# …repeat per skill; or copy the folders if you'd rather not symlink.
```

The per-skill descriptions still drive Claude Code triggering; you just lose
the centralized `global.md` + `agent-context-sync` convenience.

---

## 1. Claude Code status line

A two-line status bar rendered by [ccstatusline](https://www.npmjs.com/package/ccstatusline):

```
<model> · <context%> | $<session-cost> · <session-clock>
<git-branch> · <git-worktree>
```

**Setup (global):**

1. Prereqs: Node.js/npm, Claude Code, git on `PATH`. Install the renderer
   once — `npm install -g ccstatusline` — and point the status line at the
   installed binary, **not** `npx ... @latest`, which re-resolves the package
   over the network on every refresh. Refresh it deliberately with
   `npm update -g ccstatusline`. Note `npm install -g` follows your npm
   prefix, so check `command -v ccstatusline` matches what you wire in
   below — a second copy under another prefix will not get your updates.
2. Layout config — create `~/.config/ccstatusline/settings.json` with your
   widget layout (model, context-percentage, session-cost, session-clock,
   git-branch, git-worktree). Run `ccstatusline` for the interactive editor.
3. Wire Claude Code — merge this into `~/.claude/settings.json` (merge the
   key; don't overwrite the file):
   ```json
   "statusLine": {
     "type": "command",
     "command": "ccstatusline",
     "padding": 0,
     "refreshInterval": 60
   }
   ```
4. Restart Claude Code; the bar appears. Quick check: `echo '{}' | ccstatusline`.

> **On `refreshInterval`.** Claude Code blocks on the status-line command
> every refresh, so the interval has to clear the render time. Warm, the
> installed binary renders in ~1s (0.76–2.58s over five runs, macOS 26 /
> Node 26), which 10 would clear — 60 is simply headroom for a loaded
> machine. Measure on a *quiet* box before tuning this: renders timed while
> npm installs were running came out at 4.6–11.7s, which reflects contention,
> not the tool. ccstatusline does carry a `checkForUpdates` path that queries
> the npm registry, but its only call site is in the interactive TUI, not the
> render path, and forcing fetches to fail fast via a dead proxy changed the
> render time not at all.

> Customize later via `/statusline` in Claude Code, or re-run the ccstatusline
> editor. Changes land in `~/.config/ccstatusline/settings.json`.

---

## 2. superpowers (Claude Code plugin)

Process skills that decide *how* to approach work — brainstorming,
test-driven-development, systematic-debugging, executing-plans,
requesting/receiving-code-review, writing-plans, and more. Invoked
automatically or via the `Skill` tool.

**Setup (global):** the `claude-plugins-official` marketplace is built in.

```sh
claude plugin install superpowers@claude-plugins-official
```

The companion plugin set used alongside it (install the ones you want):

```sh
claude plugin install code-simplifier@claude-plugins-official
claude plugin install code-review@claude-plugins-official
claude plugin install claude-md-management@claude-plugins-official
claude plugin install skill-creator@claude-plugins-official
claude plugin install frontend-design@claude-plugins-official
claude plugin install context7@claude-plugins-official
# GitHub MCP: none — GitHub goes through the required gh CLI (removed
# 2026-08-07; re-add recipe in mcp-fragments/README.md if ever needed).
```

Verify: `claude plugin list` (or `/plugin` in a session), then restart.

---

## 3. Matt Pocock engineering skills

A suite of repeatable engineering workflows from
[`github.com/mattpocock/skills`](https://github.com/mattpocock/skills).
**The full curated set is vendored into this repo** (see below) — downloaders
get every skill in this table with zero setup:

| Skill | Use when |
|---|---|
| `grill-with-docs` / `grill-me` | Stress-test a plan before building |
| `research` | Investigate a question against high-trust primary sources → cited Markdown (background agent) |
| `domain-modeling` | Build/sharpen the domain model — challenge terms, update `CONTEXT.md` + `docs/adr/` inline |
| `codebase-design` | Design deep modules — small interfaces, clean seams, testable through the interface |
| `prototype` | Throwaway prototype to answer a design question — runnable terminal logic or toggleable UI variants |
| `tdd` | Red-green-refactor a feature or bugfix, one vertical slice at a time |
| `implement` | Build from a spec/tickets — drives `tdd` at agreed seams, closes with `code-review` |
| `code-review` | Two-axis review of the diff (Standards + Spec) as parallel sub-agents |
| `diagnosing-bugs` | Reproduce → minimise → fix a hard bug or perf regression |
| `resolving-merge-conflicts` | Work an in-progress merge/rebase conflict hunk-by-hunk by intent (never `--abort`) |
| `improve-codebase-architecture` | Find consolidation/deepening opportunities |
| `to-spec` / `to-tickets` | Turn discussion into a spec / tracer-bullet tickets with blocking edges |
| `wayfinder` | Plan work bigger than one session as a map of decision tickets, resolved one at a time |
| `wizard` | Generate an interactive bash wizard walking a human through steps only they can do (credentials, dashboards, one-off migrations) — pairs with `docs/runbooks/` |
| `to-questionnaire` | Turn a decision you can't fully answer into a questionnaire for someone else — pairs with wayfinder's HITL decision tickets |
| `wait-what` | Stop — that last message didn't land; re-pitch it |
| `triage` | Move incoming issues through a triage state machine |
| `handoff` | Compact a session into a pickup doc |
| `teach` | Teach a concept over multiple sessions, using the directory as a stateful workspace |
| `writing-for-agents` | Reference for writing any document an agent consumes — skills, `AGENTS.md`/`CLAUDE.md`, pointed-to docs (formerly `writing-great-skills`) |
| `git-guardrails-claude-code` | Block dangerous git commands (`push`, `reset --hard`, `clean`, `branch -D`, …) via hooks — **Claude Code-only** (writes Claude Code hook config) |
| `setup-pre-commit` | Set up Husky pre-commit hooks (lint-staged/Prettier, typecheck, tests) in the current repo |

> `grill-me` / `grill-with-docs` are built on the model-invoked `grilling`
> engine; `ask-matt` is a router — describe your situation and it points you at
> the skill that fits. Both come with the same clone.

> `domain-modeling` and `grill-with-docs` both write to `CONTEXT.md` and
> `docs/adr/`, so they pair directly with this workspace's **decision-log**
> scheme (see `CONTEXT.md` → *Decision Records*): grill/model a decision, then
> promote the durable ones to an ADR.

**Vendored in this repo (the default path).** Every skill in the table above
ships at `skills/<name>/`, pinned to an upstream commit in each `SKILL.md`'s
provenance comment — readable by every runtime (each directory also carries
upstream's `agents/openai.yaml`), with Claude Code slash-command wrappers
under `.claude/commands/` for the user-invoked ones. The per-skill index,
pristine-vs-adapted classes, slash map, and upstream MIT license live in
`skills/vendored-skills.md`. Refresh the whole set with
`scripts/sync-vendored-skills.sh` (needs a local clone of the upstream repo —
the script prints clone instructions if it's missing; pull the clone first).

Not vendored: upstream's `skills/in-progress/` bucket — expect churn there,
and note `claude-handoff` competes with this workspace's `session-rollover`/
`handoff` conventions — plus the TypeScript-course misc skills
(`scaffold-exercises`, `migrate-to-shoehorn`). Link those manually (below) if
you want them.

**Global install (optional — for repos outside this workspace, or the
maintainer keeping the reference clone fresh):** clone the repo into the
references dir, then let `agent-context-sync` link the skills (it offers each
new one):

```sh
git clone https://github.com/mattpocock/skills.git ~/Developer/references/mattpocock-skills
agent-context-sync          # pulls reference repos, links new skills, flags broken links
```

To link a single skill by hand (skills are bucketed under
`skills/{engineering,productivity,misc,in-progress}/`, but link them *flat* —
Claude Code doesn't recurse):

```sh
ln -sfn ~/Developer/references/mattpocock-skills/skills/engineering/tdd ~/.config/agent-context/skills/tdd
```

> Permanently skip an upstream skill by adding its name to
> `~/.config/agent-context/skills/.syncignore`.

> **Duplicate copies in this workspace.** On a machine that *also* has the
> global symlink install, Claude Code sees two copies of each skill — same
> content; prefer the project copy here (its `/`-commands load the workspace
> tracker conventions). To silence the duplicates, add the vendored names to
> `~/.config/agent-context/skills/.syncignore` and remove those symlinks.

> **Claude Code-only alternative — the upstream plugin.** The repo also ships
> as a native Claude Code plugin (`claude plugin marketplace add mattpocock/skills`,
> then `claude plugin install mattpocock-skills@mattpocock`): a read-only bundle
> that auto-updates with no clone to maintain. In this workspace it adds
> nothing (the skills are vendored, and the plugin would give Claude Code a
> second copy of each with duplicate/ambiguous triggering) — and other
> runtimes (Codex, Gemini, OpenCode) can't read Claude Code plugins. Only use
> it in repos outside this workspace where you work exclusively in Claude Code.

**Per-repo setup (required before `to-tickets` / `to-spec` / `triage` /
`improve-codebase-architecture` work):** run the `setup-matt-pocock-skills`
skill once in the repo. It interviews you and scaffolds:

- An `## Agent skills` block in `CLAUDE.md` (or `AGENTS.md`) describing the repo's:
  - **Issue tracker** — GitHub (`gh`), GitLab (`glab`), local markdown under `.scratch/`, or freeform
  - **Triage labels** — the five canonical roles (`needs-triage`, `needs-info`, `ready-for-agent`, `ready-for-human`, `wontfix`) mapped to your repo's actual labels
  - **Domain docs** — single-context (`CONTEXT.md` + `docs/adr/`) vs. multi-context (`CONTEXT-MAP.md`)
- `docs/agents/issue-tracker.md`, `docs/agents/triage-labels.md`, `docs/agents/domain.md`

> In this workspace, `CONTEXT.md` is the symlink target — the `## Agent
> skills` block lands there and all agents read it.

> **This template already ships the tracker config** —
> `docs/agents/issue-tracker.md` (local markdown under `work/`, labels
> verbatim) — so the vendored `to-spec`/`to-tickets`/`triage`/`wayfinder`
> work out of the box. Run `setup-matt-pocock-skills` only to switch to a
> real tracker (GitHub/GitLab) or before `improve-codebase-architecture`.

---

## 4. Karpathy coding principles

The four always-on behavioural principles — **Think before coding**,
**Simplicity first**, **Surgical changes**, **Goal-driven execution** — are
already adapted into [`../CONTEXT.md`](../CONTEXT.md) under "Agent
Coding Principles" (the wording is tuned for this template and may diverge
slightly from `global.md`), so every agent session in a workspace cloned from
this template starts with them.

The optional `karpathy-examples` skill adds side-by-side ❌/✅ worked examples
to calibrate borderline judgement calls (is this over-engineered? is this diff
surgical?). It comes from the
[`ForrestChang/andrej-karpathy-skills`](https://github.com/ForrestChang/andrej-karpathy-skills)
repo (the "karpathy-claude-md" reference). Clone it into the references dir —
agent-context already carries an authored `karpathy-examples/SKILL.md` whose
`EXAMPLES.md` symlinks into this clone:

```sh
git clone https://github.com/ForrestChang/andrej-karpathy-skills.git ~/Developer/references/karpathy-claude-md
```

This repo's `CLAUDE.md` is the source of the four principles — hand-distilled
into `global.md` and copied into this template's `CONTEXT.md`. (Because that
distillation isn't a symlink, `agent-context-sync` only *reminds* you to review
`global.md` when the upstream principles change.) The examples are a
calibration reference — don't paste them into project code.

---

## 5. graphify — per-repo knowledge graph

[graphify](https://graphify.net) turns a codebase into a queryable knowledge
graph under `graphify-out/` (gitignored), with `query` / `path` / `explain`
tools that return a scoped subgraph instead of raw grep output.

This template **already ships the wiring** so agents prefer the graph once it
exists:
- `.gemini/settings.json` — a `BeforeTool` hook that nudges Gemini toward `graphify query`
  (the file's `telemetry` block belongs to the context-budget system, not graphify)
- `.opencode/plugins/graphify.js` + `.opencode/opencode.json` — the OpenCode plugin
- `CONTEXT.md` → "graphify" section — the usage rules for all agents

(If you don't use graphify, delete: the `hooks` block in `.gemini/settings.json`
— keep the file, its `telemetry` block feeds the context-budget system —
`.opencode/plugins/graphify.js`, the plugin entry in `.opencode/opencode.json`,
and the `CONTEXT.md` → "graphify" section.)

**Setup (global, once per machine):**

```sh
uv tool install "graphifyy[mcp]"            # provides the `graphify` and `graphify-mcp` CLIs
graphify --version
```

Install the graphify skill for the agent runtimes you use (Claude Code shown):

```sh
graphify install --platform claude   # also: gemini, opencode, codex, cursor, …
```

**Per-repo setup (once per repo you want graphed):** from the repo root, build
the graph. In Claude Code use the skill; from a shell use the CLI:

```sh
/graphify                            # (in Claude Code) full pipeline on the current repo
# or, for a specific repo / a clone-from-URL:
/graphify <path-or-github-url>
```

This writes `graphify-out/` (graph.json, GRAPH_REPORT.md, interactive
graph.html, and optionally a `wiki/`). For a **multi-repo** workspace, run it
in each repo under `repos/<name>/`, or build one cross-repo graph by passing
several paths/URLs at once.

**Keep it current** after code changes (AST-only, no LLM cost):

```sh
graphify update .
```

**Use it** (these return a small scoped subgraph — prefer them over grep):

```sh
graphify query "how does auth work?"
graphify path "AuthModule" "Database"
graphify explain "SessionStore"
```

**Query it from an MCP-capable agent (optional):** the package ships a
`graphify-mcp` stdio server that exposes the graph as MCP tools. This template
pre-wires it in `.mcp.json.example` and `.vscode/mcp.json.example` (see
`docs/mcp-setup.md`); the `onboard-repo` workflow copies `.mcp.json` for you.
For a multi-repo workspace, point the server at a specific graph via
`"args": ["repos/<name>/graphify-out/graph.json"]`. The Gemini/OpenCode hooks
remain the query path for those runtimes.

`graphify-out/` is already in this template's `.gitignore` — the graph is
regenerated locally per machine, never committed. Cloned repos under
`repos/<name>/` have their own git and don't inherit this `.gitignore`: add
`graphify-out/` to each repo's `.git/info/exclude` so the graph never dirties
the product repo's working tree (its tracked `.gitignore` stays untouched).

---

## Where this fits

- These are the **global** layer of `docs/workspace-setup.md` → "Global —
  once per machine". The **per-repo** steps (Matt Pocock config, graphify
  graph) run inside each product repo.
- None of these tools store secrets in the repo; credentials stay in the OS
  keychain (`docs/service-access.md`).
