# <workspace-name> — Workspace Context

Master context file and front door for any agent session in this workspace.
Keep it concise (it loads into every conversation); link out for detail.

`CLAUDE.md`, `AGENTS.md`, and `GEMINI.md` are symlinks to this file, so
Claude Code, Codex, OpenCode, and Gemini all read the same context.

> **This is a template.** Replace the `<…>` placeholders below for your
> project, prune sections you don't need, and delete this note. See
> `docs/workspace-structure.md` for the full rationale behind every
> directory and file.

## Workspace Purpose

<!-- TODO: One paragraph — what does this workspace coordinate? Is the
workspace root itself a product repo (single-repo), or a coordination layer
over repos cloned under repos/ (multi-repo)? If there's a product spec,
point to it (e.g. SPEC.md). -->

<one-paragraph description of the project this workspace coordinates>

## Repository Layout

- `repos/` holds cloned product repos (if multi-repo); `docs/repos-registry.md`
  is the canonical registry.
- For a single-repo workspace, product code lives at the workspace root and
  `repos/` stays empty.

## Covered Repos

Per-repo context docs live under `docs/repo-context/` — see
`docs/repo-context/README.md` for the index. None are documented yet;
generate them once a codebase has structure.

## Workspace Structure

See `docs/workspace-structure.md` for the authoritative map of how this
workspace is organized (directories, entrypoints, conventions).

## Work Directory Convention

Active project work lives under `work/<username>_<project-name>/`. Persist
any intermediate state that must survive context compaction to a file in
the relevant work directory.

## Workspace Skills

<!-- TODO: List each skill under skills/ with a one-line description and
when to invoke it. skills/ is currently empty — add skills as next steps. -->

_None yet._

## Service Access

External services are documented in `docs/service-access.md`. MCP setup is
documented in `docs/mcp-setup.md`. Credentials live in the OS keychain —
never in tracked files or `.env`.

## Recommended Tooling

The external agent toolchain this workflow assumes (status line, superpowers
plugin, Matt Pocock engineering skills, Karpathy principles, graphify) is
documented in `docs/recommended-tooling.md` — global/per-user setup plus the
per-repo steps for Matt Pocock config and graphify graphs. All optional.

## Agent Coding Principles

Behavioral guidance that reduces common AI coding mistakes:

1. **Think before coding.** State assumptions; ask when uncertain; surface
   tradeoffs instead of silently picking.
2. **Simplicity first.** Minimum code that solves the problem. No
   speculative features, no abstractions for single-use code.
3. **Surgical changes.** Touch only what's required. Don't refactor
   adjacent code or "improve" formatting outside the task scope.
4. **Goal-driven execution.** Define verifiable success criteria; loop
   until verified.

## Agent Context Discipline

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

## graphify

This workspace ships with [graphify](https://graphify.net) wiring (a
knowledge-graph tool): a Gemini `BeforeTool` hook (`.gemini/settings.json`)
and an OpenCode plugin (`.opencode/plugins/graphify.js`). They activate only
once a graph exists at `graphify-out/`.

Rules (apply once `graphify-out/graph.json` exists):
- For codebase questions, first run `graphify query "<question>"`. Use
  `graphify path "<A>" "<B>"` for relationships and `graphify explain "<concept>"`
  for focused concepts. These return a scoped subgraph, usually much smaller
  than GRAPH_REPORT.md or raw grep output.
- If `graphify-out/wiki/index.md` exists, use it for broad navigation instead
  of raw source browsing.
- Read `graphify-out/GRAPH_REPORT.md` only for broad architecture review or
  when query/path/explain do not surface enough context.
- After modifying code, run `graphify update .` to keep the graph current
  (AST-only, no API cost).

If you don't use graphify, delete this section, `.gemini/settings.json`,
`.opencode/plugins/graphify.js`, and the `.opencode/opencode.json` plugin
entry.
