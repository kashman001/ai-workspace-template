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

Everything here is **optional** — the workspace works without it. Set up what
matches how you work.

| Tool | What it gives you | Scope |
|---|---|---|
| Claude Code status line | Two-line status bar (model · context% · cost · clock · git branch) | Global |
| superpowers plugin | Process skills: brainstorming, TDD, systematic debugging, plan execution, code review | Global |
| Matt Pocock engineering skills | `tdd`, `grill-with-docs`, `domain-modeling`, `codebase-design`, `implement`, `code-review`, `diagnosing-bugs`, `to-spec`/`to-tickets`, `triage`, `improve-codebase-architecture`, `handoff`, `teach` | Global skills + **per-repo** config |
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

1. Prereqs: Node.js (for `npx`), Claude Code, git on `PATH`.
2. Layout config — create `~/.config/ccstatusline/settings.json` with your
   widget layout (model, context-percentage, session-cost, session-clock,
   git-branch, git-worktree). Run `npx -y ccstatusline@latest` for the
   interactive editor.
3. Wire Claude Code — merge this into `~/.claude/settings.json` (merge the
   key; don't overwrite the file):
   ```json
   "statusLine": {
     "type": "command",
     "command": "npx -y ccstatusline@latest",
     "padding": 0,
     "refreshInterval": 10
   }
   ```
4. Restart Claude Code; the bar appears. Quick check: `echo '{}' | npx -y ccstatusline@latest`.

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
# GitHub MCP: NOT installed as a plugin by default — a plugin adds ~95 standing
# tools to every session in every project, defeating the lean-loading model
# (CONTEXT.md -> "Tool & Context Loading"). Prefer the gh CLI, or load
# mcp-fragments/github.json per session (see docs/mcp-setup.md).
```

Verify: `claude plugin list` (or `/plugin` in a session), then restart.

---

## 3. Matt Pocock engineering skills

A suite of repeatable engineering workflows from
[`github.com/mattpocock/skills`](https://github.com/mattpocock/skills):

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
| `wayfinder` | Plan work bigger than one session as a map of decision tickets, resolved one at a time — **also vendored in this repo** (see below) |
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

**Install (global, via agent-context):** clone the repo into the references
dir, then let `agent-context-sync` link the skills (it offers each new one):

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

> **"Skill not found" on another machine?** Upstream adds skills over time
> (`implement`, `wayfinder`, `teach`, `ask-matt` all arrived after launch). A
> machine whose reference clone predates a skill — or where a new upstream
> skill was never linked — won't have it. Run `agent-context-sync` (pulls the
> clone and offers any new skills), or `git pull` the clone and add the symlink
> by hand as above. Mind the buckets when linking manually: e.g. `teach` lives
> under `skills/productivity/`, not `engineering/`.

> **Two skills are vendored into this repo** — `wayfinder` at `skills/wayfinder/`
> (with this workspace's tracker wiring in `docs/agents/issue-tracker.md`) and
> `writing-for-agents` at `skills/writing-for-agents/` (incl. its
> `SKILL-MECHANICS.md` reference) — each pinned to an upstream commit in its
> provenance comment, so Copilot users and template downloaders get them with
> zero global setup. On a machine that *also* has the global symlink install,
> Claude Code sees both copies of each — same content; prefer the project copy
> here (for `wayfinder`, the `/wayfinder` command loads the workspace tracker
> conventions). The other skills stay global-only.

> **Newer upstream skills worth watching** (under `skills/in-progress/`
> upstream — expect churn; note `agent-context-sync` scans only the
> `engineering`/`productivity`/`misc` buckets, so link these manually with
> `ln -sfn` as above if wanted). Formerly-watched skills have graduated:
> `wizard`, `to-questionnaire`, `wait-what`, and `writing-for-agents` (renamed
> from `writing-great-skills`) are now released and in the table above, and
> `batch-grill-me` was folded into the `grilling` engine (round-by-round
> frontier interview). Still in progress:
> - `claude-handoff` — hands a conversation to a fresh background agent. **Not**
>   recommended in this workspace: it competes with the `session-rollover` /
>   `handoff` conventions here.
> - `loop-me`, `setup-ts-deep-modules`, `writing-*` (and misc
>   `migrate-to-shoehorn`, `scaffold-exercises`) — TypeScript-course/writing
>   specific; skip unless that's your domain.

> **Claude Code-only alternative — the upstream plugin.** The repo also ships
> as a native Claude Code plugin (`claude plugin marketplace add mattpocock/skills`,
> then `claude plugin install mattpocock-skills@mattpocock`): a read-only bundle
> that auto-updates with no clone to maintain. Only use it if you work
> exclusively in Claude Code *and* don't run the agent-context system — other
> runtimes (Codex, Gemini, OpenCode) can't read Claude Code plugins, and
> combining the plugin with the symlink install gives Claude Code two copies of
> every skill (duplicate/ambiguous triggering). With agent-context,
> `agent-context-sync` already updates every runtime at once, so the plugin
> adds nothing there.

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

(If you don't use graphify, remove those graphify pieces — see the note at the bottom of `CONTEXT.md` for exactly what to delete.)

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
