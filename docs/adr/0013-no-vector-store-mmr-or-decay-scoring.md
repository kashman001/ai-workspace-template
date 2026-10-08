# ADR-0013: No vector store, no MMR re-ranking, no numeric decay scoring

- Status: accepted
- Date: 2026-10-07
- Deciders: Kashif + Claude Code sessions of `context-memory-eval` and `context-memory-hardening`

## Context

An outside context/memory-engineering framework was scored against this
workspace (`work/context-memory-eval/eval.md`). It recommends three
mechanisms for long-lived agent memory: hybrid vector + keyword + graph
retrieval, MMR (maximal marginal relevance) re-ranking of the results, and
Ebbinghaus-style numeric decay scores so stale entries fade out. The
workspace's knowledge lives in plain markdown — `docs/operational-knowledge.md`,
`work/*/decisions.md`, ADRs, the `MEMORY.md` index — read by any of six agent
runtimes. Without a written decision, each future review would propose these
again.

## Decision

The template does not adopt hybrid vector retrieval, MMR re-ranking, or
numeric decay scoring.

Retrieval stays curated indexes plus grep: "summaries up, pointers down"
(`docs/zoom-model.md`), the index-only `MEMORY.md`, `docs/README.md`,
`work/README.md`, the repos registry, and `graphify query` where a graph
exists. Matching by meaning is the agent's own job: a keyword grep misses
when the words differ, so before concluding an entry isn't recorded the agent
scans the store's `## ` headings (a few hundred tokens) and judges them by
meaning. Staleness is handled by M43's mechanism instead of a decay score:
every `docs/operational-knowledge.md` entry carries a `**Last confirmed:**`
date, `checkpoint` lists entries past the 6-month review age for a person,
and new entries are classified ADD / UPDATE / SUPERSEDE / NOOP before they
are written (`skills/checkpoint/SKILL.md` → "Classify before you write").
Nothing is auto-deleted.

## Alternatives considered

- **Adopt them** — rejected. Vector retrieval needs an embedding model (a
  ~100 MB+ local install or a paid API key), which breaks the stdlib-only,
  offline, any-runtime property. MMR and date-based decay could be done in
  stdlib over the plain files, but at tens of KB they add nothing: keyword
  search already puts the right entry first, the results are already varied,
  and an age-only decay score just repeats the `Last confirmed` review list.
  A decay score that rewards use would need a stored read counter, which
  nothing in the workspace records. (Checked with a stdlib BM25 + MMR
  prototype over these stores, 2026-10-07.)
- **Ship them as an optional add-on** — rejected: ongoing maintenance cost for
  value no one has shown at this scale. The stores are tens of KB, and
  curation (the framework's own C11 conclusion) already covers the need.

## Consequences

- Memory stays readable and editable by any runtime and by people, with no
  service to run.
- Staleness is a dated line and a human review, not a score. An entry can
  sit past its review age until someone looks. That's deliberate: nothing
  vanishes without a person deciding.
- If the stores grow past what curated indexes and grep can serve, reopen
  this with measurements (see "Revisit when" below).
- Related, but not part of this decision: the async consolidation loop
  (recommendation 5) is deferred, not rejected —
  `work/context-memory-eval/decisions.md`.

## Revisit when

A store outgrows grep plus its index: agents repeatedly miss an entry that
exists, or a curated index can no longer be kept current by hand.

## Provenance

- Promoted from: `work/context-memory-hardening/decisions.md` (2026-10-07,
  "No vector store, no MMR re-ranking, no numeric decay scoring (D5)").
- Commits: "Fix D5" (this ADR); "Fix M43" (the substitute mechanism).
- Refs: `work/context-memory-eval/eval.md` (C7, C8, C11; recommendation 6);
  backlog card D5.
