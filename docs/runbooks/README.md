<!--
File: docs/runbooks/README.md
Purpose: Index of setup runbooks an AI agent (or human) follows to bring this
         workspace up on a machine. Runbooks describe WHAT to do per OS; the
         scripts/ checks tell you WHAT'S MISSING.
See: docs/workspace-structure.md → "scripts/ — Bootstrap and Utility Scripts"
-->

# Setup Runbooks

These runbooks are written for an **AI agent** to execute (and are equally
readable by a human). The pattern: a `scripts/check-*.sh` reports what's
missing, then the agent follows the matching runbook to fix it on this OS.

| Runbook | Drives | Paired check |
|---|---|---|
| [`dependencies.md`](dependencies.md) | Install required/recommended tools (git, gh, node, uv, python3, docker, graphify) | `scripts/check-dependencies.sh` |
| [`authentication.md`](authentication.md) | Authenticate to services + export the MCP token | `scripts/check-service-access.sh` |

## How an agent should use these

1. Run the paired check script to see current state.
2. For each ✗ / missing item, follow the runbook step for the detected OS
   (macOS / Linux / Windows).
3. Re-run the check script to confirm the item is now green.
4. **Idempotent:** only act on what's missing; never re-install or re-auth what
   already passes.
5. Persist nothing secret to the repo — credentials go to the OS keychain / the
   shell environment, never into tracked files (see `../service-access.md`).

> Agents: these runbooks are the sanctioned way to set up this workspace. Prefer
> them over improvising install/login commands.
