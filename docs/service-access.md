<!--
File: docs/service-access.md
Purpose: Vault-backed credential framework — one section per external service.
Fill in: confirm vault key names, retrieve/verify commands, and rotation policy.
See: docs/workspace-structure.md → "Service Access Pattern"
-->

# Service Access

Credentials live in the OS keychain (macOS Keychain, Linux `secret-tool`/`pass`,
Windows Credential Manager) and are retrieved on demand. Never commit tokens.
`scripts/check-service-access.sh` performs the preflight check and regenerates
`.service-access.local.json` (gitignored).

### GitHub

- **Primary credential**: the `gh` CLI login (`gh auth login`; token managed in the OS keychain by `gh` — nothing to store or export)
- **Username**: `<your-github-username>`
- **Verify cmd**: `gh auth status`
- **Used by**: the `gh` CLI — the workspace's GitHub path for all runtimes
- **Rotation**: managed via `gh auth`

### YouTube transcript MCP

- **Credentials**: none
- **Verify cmd**: `yt-dlp --version`
- **Used by**: workspace-local `youtube-transcript` MCP server (see `docs/mcp-setup.md`)
- **Notes**: retrieves only public metadata/captions that YouTube exposes; availability depends on the video and YouTube access rules.

<!-- Add one section per additional service (cloud CLI, database, Atlassian, …).
See docs/workspace-structure.md → "Service Access Pattern" for the entry shape. -->
