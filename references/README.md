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
| Matt Pocock skills | `github.com/mattpocock/skills` | Engineering skills (tdd, triage, to-tickets, …) |
| Addy Osmani agent-skills | `github.com/addyosmani/agent-skills` | Lifecycle skills (security, observability, launch, …) |
| pstack | `github.com/cursor/plugins` → `pstack/` | unslop, why, blast-radius, verification-skill generator |
| Karpathy skills | `github.com/ForrestChang/andrej-karpathy-skills` | Coding-principles examples |
| graphify | `graphify.net` · `uv tool install graphifyy` | Per-repo knowledge graph |

The skill repos are managed via the **agent-context** system: cloned under
`~/Developer/references/` and symlinked into `~/.config/agent-context/skills`
(which `~/.claude/skills` points to), linked with `agent-context-sync`. See
`../docs/recommended-tooling.md` → "Skill management — the agent-context system".

## Vendored checklists (the `*.md` files beside this README)

Six checklists from `addyosmani/agent-skills` (`references/` in that repo,
MIT, pinned in each file's opening comment), tracked here because the
vendored skills link to them as `../../references/<file>.md`:
`security-checklist.md`, `performance-checklist.md`,
`observability-checklist.md`, `accessibility-checklist.md`,
`definition-of-done.md`, `orchestration-patterns.md`. Keep them unmodified;
`scripts/sync-vendored-skills.sh addyosmani` refreshes them with the skills.

## Project references

> None yet.
