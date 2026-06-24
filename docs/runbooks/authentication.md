<!--
File: docs/runbooks/authentication.md
Purpose: Agent-followable runbook to authenticate to services and export the MCP token, per OS.
Paired check: scripts/check-service-access.sh
-->

# Runbook — Authentication

**Goal:** the GitHub MCP server and `gh` CLI can authenticate, with **no secret
ever written into the repo**. Credentials live in the OS keychain / the `gh`
login; the MCP token is read from the environment at launch.

> The scripts here are **verify + instruct only** — they never run a login or
> store a secret. The agent performs the steps below, then re-verifies.

## 0. Assess

```bash
./scripts/check-service-access.sh
```

Each ✗ line prints a fix command. Act only on what's missing; re-run to confirm.
Prereq: `gh` installed — if not, do [`dependencies.md`](dependencies.md) first.

## 1. Log in to GitHub (interactive — confirm with the user before running)

`gh auth login` is interactive (opens a browser / prompts for a code). An agent
should **ask the user to run it** (or run it only with explicit confirmation),
since it requires human interaction:

```bash
gh auth login          # choose GitHub.com → HTTPS → login with a browser
gh auth status         # verify
```

## 2. Export the MCP token

The GitHub MCP server reads `GITHUB_PERSONAL_ACCESS_TOKEN` from the environment.
Reuse the token `gh` already holds — no separate secret to manage.

```bash
# current shell:
export GITHUB_PERSONAL_ACCESS_TOKEN="$(gh auth token)"
# persist (zsh shown; use ~/.bashrc for bash):
echo 'export GITHUB_PERSONAL_ACCESS_TOKEN="$(gh auth token)"' >> ~/.zshrc
```

Windows (PowerShell, if not using Git Bash):
```powershell
setx GITHUB_PERSONAL_ACCESS_TOKEN (gh auth token)   # new shells pick it up
```

## 3. (Optional) store a standalone PAT in the OS keychain

Only if you want a PAT independent of the `gh` login. Generate it at
github.com → Settings → Developer settings → PATs.

| OS | Store | Retrieve |
|---|---|---|
| macOS | `security add-generic-password -a "$USER" -s github-pat -U -w` | `security find-generic-password -s github-pat -w` |
| Linux | `secret-tool store --label=github-pat service github-pat` | `secret-tool lookup service github-pat` |
| Windows | Credential Manager → Add a generic credential | `cmdkey` / `Get-StoredCredential` |

Then export from the keychain in your shell rc instead of `gh auth token`.

## 4. Verify

```bash
./scripts/check-service-access.sh   # expect: "Status: ok"
claude mcp list                     # GitHub tools visible to Claude Code
```

See also `../service-access.md` (the credential framework) and `../mcp-setup.md`
(per-runtime MCP config).
