# 02 — Phase 1: the record helper (read, filter, atomic write, lock, compare-and-set)

**What to build:** one shared shell library that every writer of the per-item state record uses. It reads the record, applies a filter, writes a temp file in the same directory and renames it over the original, all under a directory (`mkdir`) lock. Each caller passes a precondition: a false precondition is a silent no-op, an empty result is a refusal. It introduces the `schema_mismatch` and `record_unreadable` reason codes. Block names and the sanctioned cross-block writes come verbatim from the design's record table. It has no callers yet.

**Blocked by:** 01 (Phase 0).

**Status:** ready-for-agent

- [ ] Two writers racing on one record produce exactly one valid record (deliberate race in the test)
- [ ] A failing precondition leaves the record file byte-identical
- [ ] A record with the wrong schema exits 4 with `reason=schema_mismatch`; an unreadable record reports `record_unreadable`
- [ ] Unit suite for the helper is green; all existing suites still green
