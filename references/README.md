<!--
File: references/README.md
Purpose: Registry of external/third-party repos cloned for reference.
Fill in: list each external repo (name, URL, why it's useful). Clones here are gitignored.
See: docs/workspace-structure.md → "references/ — External References"
-->

# External References

Registry of third-party repos (research code, reference implementations).
Clones under `references/` are gitignored; this registry is checked in.

## Agent toolchain

Setup for the external tools this workflow uses lives in
[`../docs/recommended-tooling.md`](../docs/recommended-tooling.md). The
sources behind them:

| Reference | Source | Used for |
|---|---|---|
| ccstatusline | npm `ccstatusline` | Claude Code status line |
| superpowers + plugins | `anthropics/claude-plugins-official` (Claude Code marketplace) | Process skills |
| Matt Pocock skills | `github.com/mattpocock/skills` | Engineering skills (tdd, triage, to-issues, …) |
| Karpathy skills | `github.com/ForrestChang/andrej-karpathy-skills` | Coding-principles examples |
| graphify | `graphify.net` · `uv tool install graphifyy` | Per-repo knowledge graph |

These reference repos are typically cloned outside the workspace (e.g.
`~/Developer/references/`) and their skill folders symlinked into your agent
skills directory — see `../docs/recommended-tooling.md`.

## Project references

> None yet.
