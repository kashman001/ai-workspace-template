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
Exit 1 means a **required** service (GitHub) is unreachable; optional services
only degrade the status.
Prereq: `gh` installed — if not, do [`dependencies.md`](dependencies.md) first.

## 1. Log in to GitHub (interactive — confirm with the user before running)

`gh auth login` is interactive (opens a browser / prompts for a code). An agent
should **ask the user to run it** (or run it only with explicit confirmation),
since it requires human interaction:

```bash
gh auth login          # choose GitHub.com → HTTPS → login with a browser
gh auth status         # verify
```

That is the GitHub story for every repo: each runtime uses the `gh` CLI (see
`CONTEXT.md` → "Tool & Context Loading"); there is no MCP token to export. Step 2
is the single, optional exception, and it changes nothing about this step.

## 2. Repo-scoped GitHub access (optional, macOS)

Skip this unless one machine holds **two GitHub identities** and the generic
`github.com` helper prompts for — or picks the wrong — identity when pushing to
one particular repo. The fix is a fine-grained token wired to that repo's URL
only; every other repo keeps the `gh` login above.

```bash
scripts/setup-github-repo-access.sh --owner <owner> --repo <repo>   # --user <u> if it differs
```

The script prints exactly which token to mint and where. **Minting it is a human
step — an agent must ask, never mint.** The script then reads the token silently
at a prompt (so it never reaches shell history or disk), proves it against the
GitHub API, and only then wires git; a wiring that fails its own probe is rolled
back. Rotate an expired key with the same command plus `--rotate`; check without
writing anything with `--verify-only`.

Full reference, including the isolation check and the Linux/WSL caveat:
`../service-access.md` → "GitHub — repo-scoped access (one repository)".

## 3. Verify

```bash
./scripts/check-service-access.sh   # expect: "Status: ok"
gh auth status                      # authenticated as <your-github-username>
```

`check-service-access.sh` also discovers any repo-scoped credentials from step 2
with no configuration of its own, and asserts each token is still live with push
rights — a workspace that skipped step 2 sees nothing extra.

See also `../service-access.md` (the credential framework) and `../mcp-setup.md`
(per-runtime MCP config for the non-GitHub servers).
