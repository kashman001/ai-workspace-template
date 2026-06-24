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

- **Host**: <GitHub / GitLab / Bitbucket>
- **Clone URL**: `<ssh-or-https-clone-url>`
- **Default branch**: `main`
- **Visibility**: <public / private>
- **Purpose**: <one line>
- **Network**: <none special / VPN required / SSH key X>
- **Location**: `repos/<repo-name>/` (or "workspace root" for single-repo)
- **Covered by context docs**: not yet (see `docs/repo-context/`)
- **Tier**: <primary | optional>
