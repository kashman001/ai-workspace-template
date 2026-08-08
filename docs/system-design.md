<!--
File: docs/system-design.md
Purpose: System architecture overview — the Z0 (product-level) "how it hangs together".
Fill in: from the Z0 product interview (docs/workspace-structure.md → "Z0 product interview"); source intent: SPEC.md.
See: docs/workspace-structure.md → "docs/ — Workspace Documentation"
-->

# System Design

Z0 architecture pane: the answer to "what are the parts and how do they
talk?" — each row links down to Z1 (per-repo context under
`docs/repo-context/`). Source of intent: `SPEC.md`.

## Components

> TODO: one row per major component/service. "Owning repo" links the
> component to `docs/repos-registry.md` (the Z0→Z1 index).

| Component | Owning repo | Responsibility | Talks to |
| --- | --- | --- | --- |
| <name> | <repo> | <one line> | <components / stores> |

## How they communicate

> TODO: the data flow between components — synchronous APIs, queues/topics,
> shared databases or caches. A short list or diagram; name protocols and
> where the contracts live.

## Build / run / debug entry points

> TODO: per component, the actual commands a developer (or agent) runs.
> Keep them copy-pasteable; details belong in each repo's
> `docs/repo-context/` docs.

| Component | Build | Run locally | Debug |
| --- | --- | --- | --- |
| <name> | <cmd> | <cmd> | <cmd or note> |

## Cross-cutting decisions

> TODO: the settled decisions that shape more than one component, each
> linking to its record in `docs/adr/`.
