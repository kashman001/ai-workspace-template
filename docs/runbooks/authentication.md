<!--
File: docs/runbooks/authentication.md
Purpose: Agent-followable runbook to authenticate to services, per OS.
Paired check: scripts/check-service-access.sh
-->

# Runbook — Authentication

**Goal:** the `gh` CLI can authenticate, with **no secret ever written into
the repo**. Credentials live in the OS keychain / the `gh` login; `gh`
manages its own token.

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

That's the whole GitHub story: every runtime uses the `gh` CLI (see
`CONTEXT.md` → "Tool & Context Loading"); there is no MCP token to export.

## 2. Verify

```bash
./scripts/check-service-access.sh   # expect: "Status: ok"
gh auth status                      # authenticated as <your-github-username>
```

See also `../service-access.md` (the credential framework) and `../mcp-setup.md`
(per-runtime MCP config for the non-GitHub servers).
