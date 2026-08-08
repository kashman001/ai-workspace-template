<!--
File: docs/service-access.md
Purpose: Vault-backed credential framework — one section per external service.
Fill in: confirm vault key names, retrieve/verify commands, and rotation policy.
See: docs/workspace-structure.md → "Service Access Pattern"
-->

# Service Access

Credentials live in the OS keychain and are retrieved on demand. Never
commit tokens. `scripts/check-service-access.sh` performs the preflight
check (required services unreachable → exit 1) and regenerates
`.service-access.local.json` (gitignored).

Every service entry carries a **Scope**:

- `personal` — each person holds their own credential in their OS keychain
  (the default; e.g. your GitHub login).
- `shared` — one team-owned credential (a service account, an API key)
  distributed through a team vault, not copied person-to-person. See
  "Shared credentials" below.

**OS keychain commands** (store/retrieve a personal secret by name):

| OS | Store | Retrieve |
|---|---|---|
| macOS | `security add-generic-password -a "$USER" -s <name> -w` | `security find-generic-password -s <name> -w` |
| Linux | `secret-tool store --label=<name> service <name>` | `secret-tool lookup service <name>` |
| Windows | `cmdkey /generic:<name> /user:$env:USERNAME /pass` | PowerShell `Get-StoredCredential -Target <name>` (third-party module: `Install-Module CredentialManager`) |

### GitHub

- **Scope**: personal
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

## Shared credentials — the team-vault interface

No vault product is prescribed; the template has no `shared` service yet.
When your team adds one, whatever vault you pick (1Password, HashiCorp
Vault, SOPS, a cloud secret manager) must provide three things — that
interface, not the product, is the contract:

1. **Fetch by name** — a non-interactive command that resolves a secret
   name to a value an agent can put in the OS keychain or an env var,
   recorded as the entry's **Retrieve cmd**.
2. **Bootstrap** — a step in `docs/runbooks/authentication.md` that gets a
   new team member from zero to fetch-works (vault login, team invite).
3. **Rotation** — a note per entry saying who rotates it and how consumers
   pick up the new value (re-run the retrieve command).

Worked example (1Password CLI) for a hypothetical shared entry:

```markdown
### Payments API (staging)
- **Scope**: shared
- **Retrieve cmd**: `op read "op://team-vault/payments-api-staging/credential"`
- **Verify cmd**: `curl -fsS -H "Authorization: Bearer $TOKEN" https://staging.example.com/health`
- **Bootstrap**: `op signin` after accepting the 1Password team invite
- **Rotation**: platform team rotates quarterly; re-run the retrieve cmd
```

Mark the service required in `scripts/check-service-access.sh` (its
required block) if the workflow can't run without it.
