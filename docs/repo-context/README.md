<!--
File: docs/repo-context/README.md
Purpose: Index of repos that have per-repo context docs.
Fill in: list each covered repo with a link to its folder.
See: docs/workspace-structure.md → "docs/ — Workspace Documentation"
-->

# Repo Context — Index

Per-repo navigation (`code-structure.md`), architecture (`design.md`), and API
surface (`api.md`) docs. None are populated yet.

Add one folder per covered repo via the onboarding workflow — run
`/onboard-repo <repo-name>` (or `scripts/onboard-repo.sh <repo-name> [repo-path]`),
then fill the three docs following `skills/onboard-repo/SKILL.md`. The skeletons in
`docs/repo-context/_templates/` keep the output format consistent. Each doc carries
a provenance block (generation date + source commit); `scripts/check-repo-context.sh`
flags when a repo's code has moved past that commit.

## These docs vs. the graphify graph

Both describe a repo, but they are different kinds of artifact — keep them in
their own homes:

- **This directory is the library**: committed, human-reviewed distillation
  (navigation, architecture, API surface). It survives machine changes, diffs
  cleanly, and exists precisely because the graph may not be present on a
  given machine.
- **The graphify graph is the index at the back of the book it indexes**:
  machine-generated, regenerated locally per machine, never committed. It
  lives at the root of the repo it describes (root `graphify-out/` for a
  single-repo workspace; `repos/<name>/graphify-out/` for multi-repo, kept out
  of a cloned repo's git via its `.git/info/exclude`) — that placement is what
  makes `graphify update .` and the live/fallback check in
  `scripts/onboard-repo.sh` work. Do **not** move it under `docs/`.

## Covered repos

> None yet.
