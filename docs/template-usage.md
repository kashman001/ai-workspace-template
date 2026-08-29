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

First decide where the workspace itself will live — an explicit choice
point the rest of the docs depend on:

- **Local-only** — just you, one machine, no remote. Clone and re-init git:

  ```bash
  git clone https://github.com/<you>/ai-workspace-template.git <your-project>-workspace
  cd <your-project>-workspace
  rm -rf .git && git init
  ```

- **Shared repo** — a team, or you across machines. On GitHub use
  **"Use this template"** to create `<your-project>-workspace` under your
  account/org, then `git clone <your-repo-url>`. Every subsequent machine
  follows the fresh-clone path in `docs/workspace-setup.md`, which assumes
  this variant.

- **No-git ("private")** — the workspace holds content that must never reach
  a remote (personal, legal, financial). Clone, then remove git entirely and
  don't re-init:

  ```bash
  git clone https://github.com/<you>/ai-workspace-template.git <your-project>-workspace
  cd <your-project>-workspace
  rm -rf .git
  ```

  See "No-git mode" below for what changes.

Starting local-only and publishing later is fine
(`git remote add origin <url> && git push -u origin main`).

### No-git mode

The core loop — launcher/ledger under `work/`, `decisions.md`, the context
budget — is git-free and works unchanged. What changes:

**Paste a privacy posture into `CONTEXT.md`** (top-level section), so every
agent session inherits it:

```markdown
## Privacy Posture

This workspace deliberately has NO git repository. Do not run `git init`,
do not commit, never push or upload the contents of this workspace
(especially `work/` and documents) to any external service.
```

**Decision capture starts at Tier 2.** There are no commits, so the Tier-1
`Decision:` trailer is N/A. Capture every decision as a dated line in
`work/<project>/decisions.md`; promotion to an ADR still works (ADRs are
just files).

**Git-dependent machinery is N/A** — skip it; nothing else breaks:

- `checkpoint`'s confirm-branch-state step and `git status` verification.
- `session-rollover`'s commit-per-convention flush; note file state in the
  handoff instead. The `launch-next-session.sh` freshness guard passes
  automatically (the launcher is untracked), and worktree-invoked relaunch
  doesn't apply.
- Worktree isolation, `scripts/diff-review.sh`, and git-guardrails hooks.
- §5's prune command: use `rm -r work/*/` instead of `git rm`.

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
- The copy wires the **core** server set only (graphify). YouTube transcript
  MCP is an opt-in fragment under `mcp-fragments/`, loaded per session;
  per-runtime notes (Claude/Codex/Gemini/OpenCode) are in `docs/mcp-setup.md`.
  GitHub goes through the required `gh` CLI — no MCP server, no token export.

## 4. Decide on the optional bits

- **graphify** — wired by default (`.gemini/settings.json`,
  `.opencode/plugins/graphify.js`, the `CONTEXT.md` graphify section). If you
  don't use it, delete those and the `.opencode/opencode.json` plugin entry.
- **Skills** — `skills/` ships with reusable workflows (authoritative list:
  `CONTEXT.md` → "Workspace Skills"), among them **checkpoint**
  (session-boundary wrap-up), **onboard-repo** (bring a repo into the workspace),
  **rlm** (Recursive Language Model loop for querying contexts too large to
  read into chat), **decision-log** (capture the *why* behind a decision as a
  commit trailer + an ephemeral note in `work/<proj>/decisions.md`, promoted to a
  committed ADR under `docs/adr/` for lasting-weight calls), and
  **session-rollover** (deliberate pruned handoff to a fresh session when the
  context budget hits WARN/STOP — see `docs/context-budget.md`). Add your own as needed
  and list each in `CONTEXT.md` → "Workspace Skills". Drop any you don't want (e.g.
  `rlm`'s leaf sub-LM is a nested `claude -p`, so it's most useful with Claude Code).
- **Scripts** — `scripts/setup.sh` (symlinks, config copies, `--clone-repos`),
  `check-dependencies.sh`, `check-workspace-structure.sh`, and
  `check-service-access.sh` are functional out of the box; extend them as the
  workspace grows.
- **Agent toolchain** — optional global tools (Claude Code status line,
  superpowers plugin, Matt Pocock engineering skills, Karpathy principles,
  graphify) are documented in `docs/recommended-tooling.md`, including the
  per-repo setup for graphify graphs and Matt Pocock config.

## 5. Prune the template-development artifacts

The box ships with residue from developing the template itself. Prune it on
day 1 — instances that skip this carry the template's own issue tracker and
engineering history around indefinitely.

**The maintainer's `work/` history.** `work/` ships with the template
maintainer's own work directories (`context-decay`,
`automatic-session-rollover`, `usage-scenarios`, …). They are
research/session history, kept as a live worked example of the
work-directory conventions — **not** template machinery. Nothing the scripts
or skills depend on lives there: runtime state (the context-budget measurement
ledger, session registrations) lives in the gitignored `.context-budget/`, and
the doc-worthy conclusions were promoted to `docs/archive/`. Keep a `work/`
dir only if you want its worked example.

**Template-only files** — these document the template, not your project:

- `docs/template-workspace-backlog.html` + `…-backlog-archive.html` — the
  template's own issue tracker. Also delete the "Template Backlog" section
  of `CONTEXT.md` that maintains it.
- `docs/template-usage.md` — this file; it has done its job once you finish
  this checklist. (`docs/workspace-structure.md` stays — it describes your
  workspace, not the template.)
- `mcp-fragments/*.json` you don't use.
- `LICENSE` — the template's license; swap in your project's own (or delete
  it in a private workspace).
- After pruning, drop the deleted files' rows from `docs/README.md`'s index.
- `prompt-library/` and `references/` are near-zero-cost empty scaffolding —
  keep them when in doubt; `scripts/check-workspace-structure.sh` expects
  both, so deleting them means removing them from that script's dir list too.
- Non-code instance? Also trim the build/CI sections of
  `docs/operational-knowledge.md`.

The wholesale part in one commit (no-git mode: `rm -r`, no commit):

```bash
git rm -r work/*/ docs/template-workspace-backlog*.html
git commit -m "prune template-development artifacts"
```

(`work/.gitkeep` keeps the directory; delete `docs/template-usage.md` last,
once you're done with it.) Two kinds of pointers into the deleted `work/`
dirs remain by design and are safe to leave dangling: ADR `Promoted from:` /
`Refs:` provenance lines, and history rows in the template backlog — both
record where a decision came from, not content you need.

`scripts/setup.sh` reminds you about this section while the backlog pair is
still present.

## 6. Reference

`docs/workspace-structure.md` is the authoritative map of the whole layout
and includes step-by-step **Agent Bootstrap Instructions** — point an agent
at that section to scaffold or extend a workspace.
