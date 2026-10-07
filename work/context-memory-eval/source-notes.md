# Source notes — "Unifying Context Engineering and Memory Engineering"

Source: https://x.com/marfinxx/status/2088234998654472340 (X Article by
@marfinxx, 2026-08-14). Fetched via Chrome on 2026-10-07; WebFetch gets
HTTP 402. These notes paraphrase the article. They don't quote it.

**Caveat:** the article is a practitioner opinion piece. Its numbers
("up to 60% token savings", "90%+ cache hit rates", "100+ files in <3K
tokens") have no sources. Read them as claims, not benchmarks.

## Core thesis

- **Context is RAM, memory is SSD.** The context window is volatile working
  memory for the current turn. It is not a place to store things. Durable
  knowledge belongs in external storage that lasts across sessions.
- Dumping everything into a huge window fails in two ways. Rules buried in
  the middle get ignored, and cost and latency go up. Starting each session
  with no memory fails too, because you re-explain everything and drift by
  turn ~15–30.

## Concepts (the IDs are used in eval.md)

| ID | Concept | Gist |
|---|---|---|
| C1 | Context/memory separation | Two disciplines. Context engineering decides what is in the window now. Memory engineering decides what survives across sessions. |
| C2 | Cache-friendly prompt layout | Three layers: (1) an immutable prefix (identity, rules, tool defs, kept byte-stable), (2) a semi-static slice of relevant memory and repo map, (3) an append-only dynamic tail. Reordering anything breaks the prefix cache. |
| C3 | Compress before injection | Parse code into signatures with an AST (Tree-sitter), drop function bodies, rank files over the dependency graph with PageRank. Load a full file only on request. |
| C4 | Budget allocation | Decide on purpose how many tokens each layer gets before injecting it. |
| C5 | Four-tier memory hierarchy | Working (one turn) → short-term episodic (session log) → long-term semantic (consolidated facts, preferences) → procedural (validated workflows/skills, versioned in git). |
| C6 | Atomic notes + CRUD | Store self-contained facts, not transcripts. Every incoming item gets ADD / UPDATE / DELETE (contradicted) / NOOP (noise) so the store never piles up duplicates or stale facts. |
| C7 | Controlled forgetting | A retention score from relevance, access frequency, and recency (Ebbinghaus-style decay). Below a threshold, archive or evict. |
| C8 | Hybrid retrieval + MMR | Pull candidates from vector, keyword (FTS/BM25), and graph search, then use MMR to drop near-duplicates before injection. |
| C9 | Dual-loop architecture | A fast inner loop (retrieve → prompt → infer → tool) and a slow, asynchronous outer loop (extract facts → link entities → decay → consolidate) that runs while idle. Execution is kept separate from maintenance. |
| C10 | Structured post-session extraction | At session end, one cheap structured-output call distills durable facts into the atomic store. |
| C11 | Curation beats volume | A curated index of ~50 atomic facts beats an unmanaged store of 50K fragments. |
