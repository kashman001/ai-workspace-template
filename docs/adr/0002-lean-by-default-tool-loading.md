# ADR-0002: Load tools lean-by-default — CLI-first, MCP split into core and opt-in fragments

- Status: accepted
- Date: 2026-08-01
- Deciders: Kashif, Claude (workspace-infra sessions)

## Context

Every always-on MCP server, tool schema, and doc taxes the context window of **every**
session in **every** runtime this workspace supports (Claude Code, Codex, Gemini,
OpenCode) — whether or not the session uses it. Usage evidence said the standing
surface wasn't earning its cost: a transcript scan found 14 GitHub-MCP calls (12 of
them `get_file_contents`) versus the `gh` CLI covering the same work, and a later
30-session scan found **zero** GitHub-plugin tool calls at all. Claude Code defers MCP
tool schemas automatically, but that mitigation is Claude-only — the other runtimes
pay full price, so the fix had to live in the workspace's own wiring.

## Decision

Capabilities enter the workspace **CLI-first** (a binary on `PATH`: zero standing
context, agent-agnostic); MCP is the exception, reserved for where it genuinely beats
the CLI. The MCP surface is split: core `.mcp.json` carries only graphify; heavier
task-specific servers live in `mcp-fragments/*.json` and are loaded per session
(`claude --mcp-config …`; OpenCode pre-declares them `"enabled": false`). Asymmetric
parent/child toolsets handle the rest: `.claude/agents/` subagent profiles narrow a
child's toolset, and `claude -p --mcp-config` workers give a child tools the parent
never loads.

## Alternatives considered

- **All servers in `.mcp.json`, relying on Claude Code's deferred tool loading** —
  rejected: Claude-only; Codex/Gemini/OpenCode still pay the full standing cost.
- **A portable tool-search shim for the other runtimes** — rejected: over-machinery
  for the problem size.
- **Keeping the GitHub MCP plugin (user-level, always-on in every project)** —
  rejected: zero recorded plugin tool calls across 30 transcripts; `gh` covers it.
  Uninstalled; `mcp-fragments/github.json` remains the sanctioned opt-in path.
  *(Amendment 2026-08-07: the github fragment was removed entirely — the `gh`
  CLI, now a required dependency, is the only GitHub path; re-add recipe in
  `mcp-fragments/README.md`. See backlog L30.)*

## Consequences

- Sessions start lean everywhere, not just under Claude Code.
- Task-specific capability now needs a deliberate opt-in step (load a fragment, flip
  an OpenCode flag) — small, intentional friction.
- Every new capability must justify MCP over a CLI at the door.
- The fragment set must be kept consistent across runtime configs
  (`mcp-fragments/`, `opencode.json`) — one more pairing to maintain.

## Provenance

- Promoted from: `work/workspace-infra/decisions.md` — "lean-by-default tool loading"
  and "GitHub MCP plugin uninstalled" notes (2026-08-01)
- Commits: workspace `9f840e9`, template `63a40b3`
- Refs: `CONTEXT.md` → "Tool & Context Loading — Lean by Default",
  `docs/mcp-setup.md`, `mcp-fragments/README.md`
