<!--
File: docs/mcp-setup.md
Purpose: MCP server configuration guide for this workspace.
Fill in: confirm/extend per-runtime config; keep the token out of tracked files.
See: docs/workspace-structure.md → "IDE and Agent Configuration"
-->

# MCP Setup

This workspace uses the **GitHub MCP server**. Its personal access token is
read from the `GITHUB_PERSONAL_ACCESS_TOKEN` environment variable, sourced
from `gh auth token` (see `docs/service-access.md`) — never hardcode it.

A checked-in template lives at `.mcp.json.example`. Copy it to `.mcp.json`
(gitignored) for runtimes that read a project-level `.mcp.json`.

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

We default to the **hosted remote server** (`https://api.githubcopilot.com/mcp/`):
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

## Per-runtime configuration

### Claude Code — configured
Reads the project-level `.mcp.json` (created here, gitignored). Uses the
remote server with `type: "http"`, expanding `${GITHUB_PERSONAL_ACCESS_TOKEN}`
into the `Authorization` header from the environment at launch. Verify:
```bash
claude mcp list
```

### OpenCode — pre-staged
OpenCode reads **two** files in this workspace, by design:
- `opencode.json` (repo root) — the GitHub MCP server (`mcp.github`, `type: local`).
- `.opencode/opencode.json` — the plugin list (the graphify plugin).

`{env:...}` substitution works for local servers. Verify after installing OpenCode:
```bash
opencode mcp list
```
Note: OpenCode does not currently interpolate `{env:...}` inside *remote*
server `headers`, so the local Docker server is preferred here.

### Codex
Add to `~/.codex/config.toml`:
```toml
[mcp_servers.github]
command = "docker"
args = ["run", "-i", "--rm", "-e", "GITHUB_PERSONAL_ACCESS_TOKEN", "ghcr.io/github/github-mcp-server"]
env = { GITHUB_PERSONAL_ACCESS_TOKEN = "${GITHUB_PERSONAL_ACCESS_TOKEN}" }
```
<!-- TODO: verify against your Codex version's MCP schema -->

### Gemini CLI
Add to `~/.gemini/settings.json` under `mcpServers`:
```json
{
  "mcpServers": {
    "github": {
      "command": "docker",
      "args": ["run", "-i", "--rm", "-e", "GITHUB_PERSONAL_ACCESS_TOKEN", "ghcr.io/github/github-mcp-server"],
      "env": { "GITHUB_PERSONAL_ACCESS_TOKEN": "$GITHUB_PERSONAL_ACCESS_TOKEN" }
    }
  }
}
```
<!-- TODO: verify against your Gemini CLI version -->

### graphify — code knowledge graph (optional)

The `graphify-mcp` stdio server (from `uv tool install graphifyy`) serves a repo's
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
Any runtime not listed above can use the same server: point it at the hosted
remote URL (`https://api.githubcopilot.com/mcp/` with the bearer header) or the
local Docker command. Consult the runtime's own MCP docs for where its config lives.

> After configuring a runtime, restart it and confirm the GitHub tools appear.
