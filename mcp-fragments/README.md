<!--
File: mcp-fragments/README.md
Purpose: Opt-in MCP server definitions, loaded per session/task instead of by default.
See: docs/mcp-setup.md → "Core vs. fragments"; CONTEXT.md → "Tool & Context Loading"
-->

# MCP Fragments — Opt-in Servers

The default `.mcp.json` carries only the **core** server set (graphify).
Everything else lives here as one fragment per server, loaded only when a
session's task actually needs it. This keeps the standing tool surface —
and therefore every session's context cost — minimal, in line with the
CLI-first rule in `CONTEXT.md` → "Tool & Context Loading".

Each fragment is a complete `mcpServers` config, safe to check in (no
secrets — credentials come from the environment at launch).

| Fragment | Server | Default alternative (no MCP needed) |
|---|---|---|
| `youtube-transcript.json` | Workspace transcript server | `yt-dlp` via `scripts/mcp/youtube-transcript.sh` |

Removed servers: GitHub MCP was dropped 2026-08-07 — the `gh` CLI (a required
dependency) is the workspace's GitHub path. If a task ever genuinely needs the
structured tools, recreate the fragment: hosted server at
`{"type":"http","url":"https://api.githubcopilot.com/mcp/","headers":{"Authorization":"Bearer ${GITHUB_PERSONAL_ACCESS_TOKEN}"}}`.

## Loading a fragment

- **Claude Code (interactive):** `claude --mcp-config mcp-fragments/youtube-transcript.json`
  — adds the fragment's servers to the session alongside `.mcp.json`.
- **Claude Code (scoped child session):** from any runtime, spawn a headless
  worker that carries the extra server only for one task:
  `claude -p "<task>" --mcp-config mcp-fragments/youtube-transcript.json`.
- **Durable opt-in (any runtime reading `.mcp.json`):** merge the fragment's
  server entry into your local `.mcp.json` (gitignored).
- **OpenCode:** servers are pre-declared in root `opencode.json` with
  `"enabled": false` — flip to `true` locally when needed.
- **Gemini CLI / Codex / others:** copy the server definition into that
  runtime's MCP config (see `docs/mcp-setup.md` for per-runtime syntax).

Adding a new capability? Prefer a CLI on `PATH` first; add a fragment here
only when MCP genuinely beats the CLI. Add heavy servers as fragments, not
to the `.mcp.json` core.
