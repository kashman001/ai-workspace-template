<!--
File: docs/repos-registry.md
Purpose: Canonical registry of product repositories for this workspace.
Fill in: add a section per repo using the fields below; delete the example.
See: docs/workspace-structure.md → "repos/ — Product Repositories"
-->

# Repos Registry

Canonical list of product repos this workspace coordinates. For a
**single-repo workspace**, the workspace root *is* the product repo and this
registry has one entry pointing at the root. For a **multi-repo workspace**,
each repo is cloned under `repos/` and listed here.

`scripts/setup.sh` symlinks `repos/README.md` → this file so the registry is
discoverable from inside `repos/`.

## <repo-name> (primary)

- **Host**: <GitHub / GitLab / Bitbucket / local>
- **Clone URL**: `<ssh-or-https-clone-url>` (n/a for local)
- **Default branch**: `main`
- **Visibility**: <public / private>
- **Purpose**: <one line>
- **Auth method**: <gh CLI / SSH key X / PAT in keychain> — see `docs/runbooks/authentication.md`
- **Language / stack**: <languages + frameworks>
- **Build / test / run**: `<build>` / `<test>` / `<run>`
- **Network**: <none special / VPN required / SSH key X>
- **Location**: `repos/<repo-name>/` (or "workspace root" for single-repo; a local path for a non-hosted repo)
- **Covered by context docs**: not yet — once onboarded, `docs/repo-context/<repo-name>/` holds `code-structure.md`, `design.md`, `api.md`
- **Tier**: <primary | optional>
