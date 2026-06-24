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

- **Primary token source**: `gh auth token` (reuses the `gh` CLI login; no separate secret to store)
- **Username**: `<your-github-username>`
- **Export for MCP**: `export GITHUB_PERSONAL_ACCESS_TOKEN="$(gh auth token)"`
- **Verify cmd**: `gh auth status`
- **Alt (Keychain)**: store a PAT, retrieve with `security find-generic-password -s github-pat -w`
- **Used by**: GitHub MCP server (see `docs/mcp-setup.md`); the `gh` CLI
- **Rotation**: managed via `gh auth` / PAT settings

<!-- Add one section per additional service (cloud CLI, database, Atlassian, …).
See docs/workspace-structure.md → "Service Access Pattern" for the entry shape. -->
