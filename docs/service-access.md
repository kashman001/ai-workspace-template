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

### GitHub — repo-scoped access (one repository)

Optional. Reach for it when **one machine holds two GitHub identities** (work
and personal, say) and the generic `github.com` helper — Git Credential Manager,
`osxkeychain` — therefore prompts for *which* identity, or silently picks the
wrong one, on every push to one particular repo.

- **Scope**: personal (machine-level: set up once, every workspace on that
  machine inherits it)
- **Applies to**: `<owner>/<repo>` **only**. Nothing else on github.com is
  affected; all other repos keep the `gh` login above.
- **Auth type**: fine-grained personal access token, scoped to that one repository
- **Vault entry**: generic-password `github-<owner>-<repo>-token`, account = the
  GitHub **username** (not an email). Override with `--key-service` if the
  machine already holds the key under another name.
- **Retrieve cmd**: `security find-generic-password -s github-<owner>-<repo>-token -a <user> -w`
- **Verify cmd**: `scripts/setup-github-repo-access.sh --owner <owner> --repo <repo> --verify-only`
  (or `scripts/check-service-access.sh`, which asserts the same push right)
- **Rotation**: `scripts/setup-github-repo-access.sh --owner <owner> --repo <repo> --rotate`
  (fine-grained PATs expire — 90 days is the convention here)
- **Platform**: **macOS only.** The script stores the key in the login Keychain
  and refuses to run elsewhere. On Linux/WSL the same design works with
  `secret-tool` or `pass` in place of `security`, in both the script and the
  generated helper — that port has not been written.

**Why a dedicated key rather than the `gh` login.** When `gh` is authenticated
with more than one account, and with account-wide `repo` scope, the credential
manager has no way to know which identity a given push wants. A fine-grained
token wired path-scoped to one repo removes the prompt and caps the blast
radius: the key cannot touch any other repository even if it leaks.

**How git uses it — path-scoped, one repo.** There is exactly **one** copy of
the key (the vault entry above). Git does not get its own; it reads that same
entry through `~/.local/bin/git-credential-<owner>-<repo>`, a helper that
answers only `get` (`store`/`erase` are deliberate no-ops, so git can never
overwrite the canonical entry behind your back). The helper is registered in
`~/.gitconfig` against the repo URL, not against `github.com`:

```gitconfig
[credential "https://github.com/<owner>/<repo>.git"]
	useHttpPath = true
	helper =                     # reset the inherited list (drops the generic helper for this URL)
	helper = /Users/<you>/.local/bin/git-credential-<owner>-<repo>
```

Git matches `credential.<url>` sections by **exact path**, so the script
registers both the bare and the `.git` URL forms — a clone whose remote omits
`.git` would otherwise silently fall back to the generic helper. Confirm the
isolation still holds:

```bash
git config --get-urlmatch credential https://github.com/<owner>/<repo>.git
# → the repo-scoped helper only
git config --get-urlmatch credential https://github.com/<owner>/any-other-repo.git
# → whatever you used before (unchanged)
```

**A plain `git fetch` proves nothing here: against a public repo it succeeds
with no key at all, and it never exercises push rights.** The verify command
instead checks the vault entry exists, the token is live (HTTP 200), it carries
**push** rights (`permissions.push == true`), and git resolves the credential
under `GIT_TERMINAL_PROMPT=0` — no prompt.

**Setup / rotate (macOS):**

1. Create a fine-grained token at
   <https://github.com/settings/personal-access-tokens/new> — resource owner
   `<owner>`, **Only select repositories** → `<repo>`, permissions
   **Contents: Read and write** + **Pull requests: Read and write**
   (Metadata: Read-only is added automatically), expiration **90 days**.
   Minting the token is a human step — an agent must ask, never mint.
2. Run `scripts/setup-github-repo-access.sh --owner <owner> --repo <repo>`
   (add `--user <username>` if it differs from the owner). It prompts for the
   token silently — never as a command-line argument, which keeps it out of
   shell history and off disk — stores it, installs the helper, **proves the
   token against the API**, and only then wires git. If the wiring then fails
   its own probe, both `credential.<url>` sections are removed again: a failed
   run never leaves git pointing at a credential that does not work. The vault
   entry is kept either way, since the token may be fine and the wiring at fault.
3. Rotating later (expired, revoked, mistyped): add `--rotate`. Without it the
   script sees the entry as present and skips the prompt, so a bad key cannot be
   replaced. Nothing else needs touching — helper and git config are unchanged.
4. Optionally pin a clone (commit identity is separate from auth):
   `--repo-path <path>` normalizes that clone's `origin` URL, and `--email <addr>`
   pins its commit address. Omit `--email` to leave the clone's identity alone.

`scripts/check-service-access.sh` picks these up with no configuration: it
discovers every repo wired this way from `~/.gitconfig` and asserts each token
is live with push rights. A workspace that never ran the script reports nothing.

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
