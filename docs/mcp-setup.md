<!--
File: docs/mcp-setup.md
Purpose: MCP server configuration guide for this workspace.
Fill in: confirm/extend per-runtime config; keep the token out of tracked files.
See: docs/workspace-structure.md → "IDE and Agent Configuration"
-->

# MCP Setup

This workspace pre-stages three MCP server patterns:

- **graphify MCP** (core — wired by default) — stdio server for querying a
  generated code graph.
- **GitHub MCP** (opt-in fragment) — authenticated, hosted by default, token
  read from `GITHUB_PERSONAL_ACCESS_TOKEN` sourced from `gh auth token`
  (see `docs/service-access.md`).
- **YouTube transcript MCP** (opt-in fragment) — workspace-local stdio server
  backed by `scripts/mcp/youtube-transcript.sh`, Python 3, and `yt-dlp`; no
  credentials.

## Core vs. fragments — lean by default

Every wired MCP server adds standing tool surface (and context cost) to every
session, so servers are split by default-need (rationale: `CONTEXT.md` →
"Tool & Context Loading"):

- **Core** (`.mcp.json`, template at `.mcp.json.example`): only the
  always-useful, cheap set — currently **graphify** (10 tools). Copy the
  example to `.mcp.json` (gitignored) for runtimes that read a project-level
  `.mcp.json`.
- **Fragments** (`mcp-fragments/*.json`): task-specific servers — **github**
  (~95 tools) and **youtube-transcript** — loaded per session when the task
  needs them. Each fragment is a complete `mcpServers` config; loading recipes
  per runtime are in `mcp-fragments/README.md`. Quick version:
  - Claude Code: `claude --mcp-config mcp-fragments/github.json` (adds to the
    session alongside `.mcp.json`); scoped child worker:
    `claude -p "<task>" --mcp-config mcp-fragments/github.json`.
  - Durable opt-in: merge the fragment's entry into your local `.mcp.json`.
  - OpenCode: flip the matching server's `"enabled"` to `true` in
    `opencode.json` locally.
- **CLI-first fallback:** the fragments' capabilities are also available with
  zero context cost via CLIs — `gh` for GitHub, `scripts/mcp/`'s `yt-dlp`
  wrapper for transcripts. Prefer those unless you need the structured MCP
  tools.

> **Migrating an existing setup?** If your `.mcp.json` predates the split,
> remove its `github` and `youtube-transcript` entries (they moved to
> `mcp-fragments/`), and make sure `enabledMcpjsonServers` in
> `.claude/settings.local.json` includes `"graphify"`. Likewise avoid
> installing the GitHub MCP *plugin* — it re-creates the always-on surface
> this split removes (see `docs/recommended-tooling.md` §2).

## Export the token

The server reads `GITHUB_PERSONAL_ACCESS_TOKEN` (sent as a bearer header for
the remote server, or passed as an env var to the Docker server). Reuse the
token the `gh` CLI already holds — no separate secret to manage. Add to your
shell profile (`~/.zshrc`) or run before launching an agent:
```bash
export GITHUB_PERSONAL_ACCESS_TOKEN="$(gh auth token)"
```
(Alternative: source a PAT from the macOS Keychain — see `docs/service-access.md`.)

## Server type

For GitHub, we default to the **hosted remote server**
(`https://api.githubcopilot.com/mcp/`):
no Docker dependency, and the token is sent as an `Authorization: Bearer`
header expanded from the environment at launch. This is what `.mcp.json` /
`.mcp.json.example` configure.

The **local Docker server** (`ghcr.io/github/github-mcp-server`) is the
alternative when you'd rather run the server yourself: the token stays in an
env var and it behaves consistently across runtimes, but it requires Docker
running:
```json
{
  "mcpServers": {
    "github": {
      "command": "docker",
      "args": ["run", "-i", "--rm", "-e", "GITHUB_PERSONAL_ACCESS_TOKEN", "ghcr.io/github/github-mcp-server"],
      "env": { "GITHUB_PERSONAL_ACCESS_TOKEN": "${GITHUB_PERSONAL_ACCESS_TOKEN}" }
    }
  }
}
```

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
`--mcp-config mcp-fragments/<name>.json`; the GitHub fragment uses the remote
server with `type: "http"`, expanding `${GITHUB_PERSONAL_ACCESS_TOKEN}` into
the `Authorization` header from the environment at launch. Claude Code defers
MCP tool schemas (loaded via tool search on first use), so wired servers cost
little until actually used. Verify:
```bash
claude mcp list
```

### OpenCode — pre-staged
OpenCode reads **two** files in this workspace, by design:
- `opencode.json` (repo root) — MCP servers (`mcp.github`,
  `mcp.youtube-transcript`), declared with `"enabled": false` per the lean
  default — flip a server to `true` locally when a task needs it.
- `.opencode/opencode.json` — the plugin list (the graphify plugin).

`{env:...}` substitution works for local servers. Verify after installing OpenCode:
```bash
opencode mcp list
```
Note: OpenCode does not currently interpolate `{env:...}` inside *remote*
server `headers`, so the local Docker server is preferred here.

### Codex
Opt-in, task-driven: `~/.codex/config.toml` is **global**, so anything
registered there is always-on for every project on the machine — add a server
when a stretch of work needs it and remove it after (or rely on the `gh` CLI
instead). Add to `~/.codex/config.toml`:
```toml
[mcp_servers.github]
command = "docker"
args = ["run", "-i", "--rm", "-e", "GITHUB_PERSONAL_ACCESS_TOKEN", "ghcr.io/github/github-mcp-server"]
env = { GITHUB_PERSONAL_ACCESS_TOKEN = "${GITHUB_PERSONAL_ACCESS_TOKEN}" }

[mcp_servers.youtube-transcript]
command = "/absolute/path/to/workspace/scripts/mcp/youtube-transcript.sh"
args = []
```
<!-- TODO: verify against your Codex version's MCP schema -->

### Gemini CLI
Opt-in, task-driven: `~/.gemini/settings.json` is **global** (same always-on
caveat as Codex above) — add per task, remove after, or use the `gh` CLI.
Add to `~/.gemini/settings.json` under `mcpServers`:
```json
{
  "mcpServers": {
    "github": {
      "command": "docker",
      "args": ["run", "-i", "--rm", "-e", "GITHUB_PERSONAL_ACCESS_TOKEN", "ghcr.io/github/github-mcp-server"],
      "env": { "GITHUB_PERSONAL_ACCESS_TOKEN": "$GITHUB_PERSONAL_ACCESS_TOKEN" }
    },
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

- GitHub: point it at the hosted remote URL
  (`https://api.githubcopilot.com/mcp/` with the bearer header) or the local
  Docker command.
- YouTube: add a stdio server command pointing at
  `/absolute/path/to/workspace/scripts/mcp/youtube-transcript.sh`.
- graphify: add the `graphify-mcp` stdio command if you want live code-graph
  queries.

Consult the runtime's own MCP docs for where its config lives.

> After configuring a runtime, restart it and confirm the expected tools appear.
