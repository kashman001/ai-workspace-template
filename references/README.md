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

The skill repos are managed via the **agent-context** system: cloned under
`~/Developer/references/` and symlinked into `~/.config/agent-context/skills`
(which `~/.claude/skills` points to), linked with `agent-context-sync`. See
`../docs/recommended-tooling.md` → "Skill management — the agent-context system".

## Project references

> None yet.
