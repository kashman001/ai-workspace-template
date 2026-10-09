# ADR-0014: Keep the project glossary in a root `GLOSSARY.md`, not in `CONTEXT.md`

- Status: accepted
- Date: 2026-10-09
- Deciders: Kashif + Claude Code session 22 of `template-maintenance`

## Context

The workspace's domain glossary (resolved terms, aliases to avoid, the plan
vocabulary) used to live as a `## Language` section inside `CONTEXT.md`, the
front-door file every agent loads. The vendored Matt Pocock skills that read
and write the glossary — `domain-modeling`, `grill-with-docs`,
`improve-codebase-architecture` and others — followed the same layout until
upstream renamed it (mattpocock/skills #876): from 49dd158 on, those skills
look for the glossary in a root `GLOSSARY.md`, with the format in
`GLOSSARY-FORMAT.md`.

The template syncs those skills from upstream. Keeping the old layout would
put the template at odds with about 15 vendored files on every refresh.
`CONTEXT.md` also has a size budget of about 16K (it loads into every
conversation), and the glossary was one of its larger sections.

## Decision

The glossary lives in a root `GLOSSARY.md`. `CONTEXT.md` keeps a short
`## Language` section that points to it. The vendored skills sync without a
patch for this.

## Alternatives considered

- **Keep the glossary in `CONTEXT.md` and patch the vendored skills back** —
  rejected: about 15 files would need a `GLOSSARY.md` → `CONTEXT.md` patch,
  and any upstream edit near those lines would break it on the next sync.
- **Pin the affected skills at 068b6e0** (the last version with the old
  layout) — rejected: they would go stale and miss upstream fixes.

## Consequences

- Refreshes from upstream stay clean, and `CONTEXT.md` gets smaller.
- An agent needs one more read to see the glossary. The pointer in
  `CONTEXT.md` says when: before naming a domain concept.
- Projects made with the older layout (or the old `init-project-ai-infra`)
  still keep their glossary in `CONTEXT.md`. The vendored skills miss it there
  and may start a second one in `GLOSSARY.md`. Those projects need a one-time
  move — backlog M49 ships the migration script and runbook.
- Text outside this repo that still says the glossary lives in `CONTEXT.md`
  (the `init-project-ai-infra` skill, the global `~/.claude/CLAUDE.md`) needs
  updating by hand.

## Provenance

- Promoted from: `work/template-maintenance/decisions.md#2026-10-09--adopt-upstreams-glossarymd-glossary-leaves-contextmd`
- Commits: 08eeee3
- Refs: mattpocock/skills #876; backlog L72, M49
