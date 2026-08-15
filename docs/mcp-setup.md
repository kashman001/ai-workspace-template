<!--
File: docs/mcp-setup.md
Purpose: MCP server configuration guide for this workspace.
Fill in: confirm/extend per-runtime config; keep the token out of tracked files.
See: docs/workspace-structure.md → "IDE and Agent Configuration"
-->

# MCP Setup

This workspace pre-stages two MCP server patterns:

- **graphify MCP** (core — wired by default) — stdio server for querying a
  generated code graph.
- **YouTube transcript MCP** (opt-in fragment) — workspace-local stdio server
  backed by `scripts/mcp/youtube-transcript.sh`, Python 3, and `yt-dlp`; no
  credentials.

GitHub is deliberately **not** an MCP server here: the `gh` CLI (a required
dependency — `docs/runbooks/dependencies.md`) is the workspace's GitHub path
for every runtime. Re-add recipe, if a task ever needs the structured tools:
`mcp-fragments/README.md` → "Removed servers".

## Core vs. fragments — lean by default

Every wired MCP server adds standing tool surface (and context cost) to every
session, so servers are split by default-need (rationale: `CONTEXT.md` →
"Tool & Context Loading"). Only Claude Code defers tool schemas until first
use (names only until tool search — an idle wired server is cheap there);
other runtimes load FULL schemas up front, so keeping opt-in servers out of
their standing config matters most. **Not wired ≠ unavailable** — an agent
needing a capability finds it in the fragment table
(`mcp-fragments/README.md`) and brings it in for the session at hand:

- **Core** (`.mcp.json`, template at `.mcp.json.example`): only the
  always-useful, cheap set — currently **graphify** (10 tools). Copy the
  example to `.mcp.json` (gitignored) for runtimes that read a project-level
  `.mcp.json`.
- **Fragments** (`mcp-fragments/*.json`): task-specific servers — currently
  **youtube-transcript** — loaded per session when the task needs them. Each
  fragment is a complete `mcpServers` config; loading recipes per runtime are
  in `mcp-fragments/README.md`. Quick version:
  - Claude Code: `claude --mcp-config mcp-fragments/youtube-transcript.json`
    (adds to the session alongside `.mcp.json`); scoped child worker:
    `claude -p "<task>" --mcp-config mcp-fragments/youtube-transcript.json`.
  - Durable opt-in: merge the fragment's entry into your local `.mcp.json`.
  - OpenCode: flip the matching server's `"enabled"` to `true` in
    `opencode.json` locally.

  Bring-in mechanics (Claude Code):
  - **A running session cannot attach a new MCP server** — fragments and
    wiring apply at session start only (`/reload-plugins` covers
    plugin-provided servers, nothing else). Plan the fragment at launch, or
    spawn the scoped child worker above.
  - **Subagents** inherit the parent's MCP connections; a custom agent
    definition in `.claude/agents/*.md` can add servers via `mcpServers`
    frontmatter — the child carries the server, the parent stays lean.
  - **Rollover successors** inherit a fragment via
    `ROLLOVER_OPT_EXTRA="--mcp-config mcp-fragments/<name>.json"` in
    `work/<project>/.rollover-options` (`mcp-fragments/README.md`).
- **CLI-first:** capabilities ride CLIs wherever one exists — `gh` for GitHub
  (the only GitHub path), `scripts/mcp/`'s `yt-dlp` wrapper for transcripts.
  A fragment is only for structured MCP tools a CLI can't match.

> **Migrating an existing setup?** If your `.mcp.json` predates the split,
> remove its `github` and `youtube-transcript` entries (github was removed
> from the workspace entirely on 2026-08-07 — use `gh`; youtube-transcript
> moved to `mcp-fragments/`), and make sure `enabledMcpjsonServers` in
> `.claude/settings.local.json` includes `"graphify"`. Likewise avoid
> installing a GitHub MCP *plugin* — it re-creates the always-on surface
> this split removes (see `docs/recommended-tooling.md` §2).

## YouTube transcript server

The YouTube server is checked into the workspace:

- Launcher: `scripts/mcp/youtube-transcript.sh`
- Implementation: `scripts/mcp/youtube_transcript_mcp.py`
- Tools: `youtube_get_video_info`, `youtube_get_transcript`
- Dependency: `yt-dlp` on `PATH`

It does not use workspace credentials. It shells out to `yt-dlp` to retrieve
public metadata and captions when YouTube makes them available. It is
best-effort: videos without captions, blocked videos, age or region
restrictions, and YouTube rate limits can prevent transcript access.

Manual smoke test:

```bash
printf '%s\n' \
  '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"capabilities":{}}}' \
  '{"jsonrpc":"2.0","method":"notifications/initialized","params":{}}' \
  '{"jsonrpc":"2.0","id":2,"method":"tools/list","params":{}}' \
  | scripts/mcp/youtube-transcript.sh
```

## Per-runtime configuration

### Claude Code — configured
Reads the project-level `.mcp.json` (created here, gitignored), which carries
the core set (graphify). Load fragments per session with
`--mcp-config mcp-fragments/<name>.json`. Claude Code defers
MCP tool schemas (loaded via tool search on first use), so wired servers cost
little until actually used. Verify:
```bash
claude mcp list
```

### OpenCode — pre-staged
OpenCode reads **two** files in this workspace, by design:
- `opencode.json` (repo root) — MCP servers (`mcp.youtube-transcript`),
  declared with `"enabled": false` per the lean default — flip a server to
  `true` locally when a task needs it.
- `.opencode/opencode.json` — the plugin list (the graphify plugin).

`{env:...}` substitution works for local servers. Verify after installing OpenCode:
```bash
opencode mcp list
```

### Codex
Opt-in, task-driven: `~/.codex/config.toml` is **global**, so anything
registered there is always-on for every project on the machine — add a server
when a stretch of work needs it and remove it after. GitHub work uses the
`gh` CLI, no server needed. Add to `~/.codex/config.toml`:
```toml
[mcp_servers.youtube-transcript]
command = "/absolute/path/to/workspace/scripts/mcp/youtube-transcript.sh"
args = []
```
<!-- TODO: verify against your Codex version's MCP schema -->

### Gemini CLI
Opt-in, task-driven: `~/.gemini/settings.json` is **global** (same always-on
caveat as Codex above) — add per task, remove after. GitHub work uses the
`gh` CLI, no server needed. Add to `~/.gemini/settings.json` under
`mcpServers`:
```json
{
  "mcpServers": {
    "youtube-transcript": {
      "command": "/absolute/path/to/workspace/scripts/mcp/youtube-transcript.sh",
      "args": []
    }
  }
}
```
<!-- TODO: verify against your Gemini CLI version -->

### graphify — code knowledge graph (optional)

The `graphify-mcp` stdio server (from `uv tool install "graphifyy[mcp]"`) serves a repo's
`graphify-out/graph.json` as MCP query tools. It's pre-staged in `.mcp.json.example`
and `.vscode/mcp.json.example` under their respective server keys
(`mcpServers` vs `servers`), so MCP-capable runtimes (Claude Code, VS Code) pick it
up once you copy the example to the live file.

- **Single-repo:** default args (`[]`) serve `graphify-out/graph.json` in the cwd.
- **Multi-repo:** set `"args": ["repos/<name>/graphify-out/graph.json"]` per repo.
- **Codex / Gemini / OpenCode:** not pre-wired — add the same `graphify-mcp` stdio
  command to that runtime's MCP config if desired; otherwise the existing graphify
  hooks (`.gemini/settings.json`, `.opencode/`) already provide the query nudge.

The graph must be built first (`/graphify` or the graphify CLI); see
`docs/recommended-tooling.md` → graphify.

### Other runtimes
Any runtime not listed above can use the same servers:

- YouTube: add a stdio server command pointing at
  `/absolute/path/to/workspace/scripts/mcp/youtube-transcript.sh`.
- graphify: add the `graphify-mcp` stdio command if you want live code-graph
  queries.

Consult the runtime's own MCP docs for where its config lives.

> After configuring a runtime, restart it and confirm the expected tools appear.
