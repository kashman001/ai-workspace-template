# Template Decision Records

The **why** behind the workspace machinery this template ships — session
rollover, the context budget, decision capture, tool loading. Each record is
labelled `TADR-NNNN` (template ADR) so that, in a workspace made from the
template, it never shares a number with that project's own ADRs in
[`docs/adr/`](../adr/README.md).

These records arrive with template syncs; an instance does not renumber or edit
them. A decision **about the machinery itself** belongs here, but the template
assigns the number: in an instance, keep it as a Tier-2 note and propose the
TADR upstream — a TADR written locally collides with the template's next one.
Every other decision goes in `docs/adr/`. When to write an ADR at all, the conventions, and the Provenance
block are the same for both namespaces: [`docs/adr/README.md`](../adr/README.md).
The one difference is the label — copy `0000-template.md` from this directory and
title the record `TADR-NNNN`.

## Index

<!-- Add a line per ADR: -->
<!-- - [TADR-NNNN: <title>](NNNN-slug.md) — accepted YYYY-MM-DD -->

- [TADR-0001: Capture decision provenance in three tiers, promoting notes to ADRs](0001-three-tier-decision-capture.md) — accepted 2026-07-14
- [TADR-0002: Load tools lean-by-default — CLI-first, MCP split into core and opt-in fragments](0002-lean-by-default-tool-loading.md) — accepted 2026-08-01
- [TADR-0003: Automate the rollover→relaunch handoff with a workspace script, not vendor prompt mechanisms](0003-automate-rollover-relaunch.md) — accepted 2026-08-05
- [TADR-0004: Operate rollover automation under a multi-session model — session-keyed budget state, per-project locks, hybrid trigger](0004-multi-session-rollover-model.md) — accepted 2026-08-05, amended by TADR-0010
- [TADR-0005: Session roles with the lock as primary marker, and a parent/child session registry](0005-session-roles-and-child-registry.md) — accepted 2026-08-06, superseded by TADR-0010 (roles; registry moved to fleet)
- [TADR-0006: Key coordination state to repository identity, never to a checkout](0006-repository-keyed-coordination-state.md) — accepted 2026-08-06, amended by TADR-0010
- [TADR-0007: Make `.session-seq` (via the bootstrap prompt) the single source of session numbers](0007-session-number-single-source.md) — accepted 2026-08-06, amended by TADR-0008, superseded by TADR-0010
- [TADR-0008: Rollover step 6 asserts the session counter rather than writing it](0008-session-counter-assertion-not-write.md) — accepted 2026-08-25, superseded by TADR-0010
- [TADR-0009: `/clear`-based rollover relaunch](0009-clear-based-rollover-relaunch.md) — accepted 2026-08-28, amended by TADR-0010
- [TADR-0010: One session-state record per work item, with three writers and process liveness as the only ownership test](0010-one-session-record-three-writers.md) — accepted 2026-09-21
- [TADR-0011: Every load-bearing session step is a script that refuses with a reason code](0011-mechanical-gates-and-reason-codes.md) — accepted 2026-09-21
- [TADR-0012: Runtime contract — one adapter table, a probe-gated support matrix, fleet machinery isolated](0012-runtime-contract-adapter-table.md) — accepted 2026-09-21
- [TADR-0013: No vector store, no MMR re-ranking, no numeric decay scoring](0013-no-vector-store-mmr-or-decay-scoring.md) — accepted 2026-10-07
- [TADR-0014: Keep the project glossary in a root `GLOSSARY.md`, not in `CONTEXT.md`](0014-glossary-in-its-own-file.md) — accepted 2026-10-09
- [TADR-0015: Write human-facing HTML pages as content on a shared kit (`docs/kit/`)](0015-html-kit-for-human-facing-pages.md) — accepted 2026-10-18
