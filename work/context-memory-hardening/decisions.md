# Decisions — context-memory-hardening

Tier-2 notes (see `skills/decision-log/SKILL.md`). Newest last.

## 2026-10-07 — L49 date rule warns, it doesn't fail

`check-workspace-structure.sh` warns on a date-like line in `CONTEXT.md`.
A static date doesn't break the prompt cache; only changing text does.
Rejected: a hard fail, which would block legitimate dated references in
downstream workspaces. Commit `9996954`.

## 2026-10-07 — L49 Claude register line left as is

The `SessionStart` status line carries a per-session `artifact=` path, but it
lands after the first message's git status and prompt, which already vary per
session. Rejected: quieting it, which buys no cache hit and drops a
registration confirmation. Commit `9996954`.

## 2026-10-07 — L50 share denominator is the measured context total

`cache_read_share` = cache-read tokens / the context total the budget already
measures, for every runtime. Rejected: per-runtime input-only ratios, which
would make rows from different runtimes incomparable. Commit `0e489b5`.

## 2026-10-07 — Where the ADD/UPDATE/SUPERSEDE/NOOP rule lives, and no stale-list script
**Chose:** one canonical "Classify before you write" section in `skills/checkpoint/SKILL.md`; `decision-log` and `operational-knowledge.md` point to it. Stale list is an inline `awk` one-liner in the checkpoint step. Retirement is a `**Retired:** date — superseded by "<heading>"` line under the old heading.
**Because:** two stores share one rule; a single copy can't drift. The listing is one line of awk over a fixed `**Last confirmed:**` format, so a script plus test would cost more than it saves.
**Rejected:** copying the rule into both skills — drift; a `scripts/stale-knowledge.sh` with a suite — speculative for a one-liner; a per-entry `Status:` field for retirement — heavier than one added line.
**Blast radius:** skills/checkpoint, skills/decision-log, docs/operational-knowledge.md
**Promote?:** no

## 2026-10-07 — Which CONTEXT.md sections to cut for L51
**Chose:** compress five sections (Workspace Skills, Service Access, Tool & Context Loading, Context Budget, graphify) to pointers plus the rules an agent must act on unprompted; leave every other section byte-identical.
**Because:** those five held most of the detail that already had a home doc, and the cut reached 15.2 KB without touching the must-keep list.
**Rejected:** trimming the Language/plan glossary — the ticket names it as must-keep; dropping the skill list entirely for a pointer to `skills/` — an agent picks skills from the list without being prompted, so it stays as one-liners.
**Blast radius:** CONTEXT.md (all four entrypoint symlinks)
**Promote?:** no

## 2026-10-07 — No vector store, no MMR re-ranking, no numeric decay scoring (D5)
**Chose:** the template won't adopt hybrid vector retrieval, MMR re-ranking, or Ebbinghaus-style numeric decay scores for its knowledge stores.
**Because:** each needs a database or embedding service, which breaks the plain-files, any-runtime property; curated indexes ("summaries up, pointers down", `MEMORY.md`, `docs/README.md`) meet the need at this scale; M43's `Last confirmed` date plus checkpoint review sweep is the lightweight substitute for decay.
**Rejected:** adopting them — breaks plain files and agent-agnostic access; shipping them as an optional add-on — maintenance cost for unproven value.
**Blast radius:** memory/retrieval design; docs/operational-knowledge.md, skills/checkpoint, skills/decision-log
**Promote?:** done → ADR-0013
