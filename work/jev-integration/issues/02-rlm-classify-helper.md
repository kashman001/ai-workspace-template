# 02 — `rlm` classification helper: batch-as-state with `other`, threshold fallback

**What to build:** The `rlm` root calls `classify(records, categories)` in the REPL and gets one label per record with a confidence and a source. With a key, each batch of up to 50 records is one Jev request through the CLI (`state` = the records, one Choice per record, the root's categories plus `other`), sized to stay under the 32k-token state limit, and any record below the confidence threshold is re-asked through the current sub-model leaf. Without a key the helper takes the current path — the same `N: label` prompt through `llm_query_map` — and nothing mentions Jev. `llm_query` itself is untouched. The `rlm` skill teaches the root to use it.

**Blocked by:** 01 — Gate, `jev.sh` CLI (Choice), and the offline test.

**Status:** resolved — plan 01-gated-integration node 09-rlm-classify (s10) done; marked at the wave 7 join (s15, 2026-09-27)

**Spec:** S1, S2, S9, S10, S11, S12, S13, S14, S19

- [ ] `classify(records, categories, threshold=None)` is a REPL helper beside `llm_query`; returns a list of `{label, confidence, source}` aligned with `records`, `source` one of `jev` or `leaf`
- [ ] With a key: batches of 50, split further when the estimated tokens of `state` plus the longest question would exceed 32k; each question's instructions reference `` `records[i]` ``; `other` is appended to the categories with a fixed description
- [ ] Records with `confidence` below the threshold are re-asked through the current leaf and reported with `source: leaf`; the threshold and the model id (`jev-latest`) are each one module constant, env-overridable like the other `RLM_*` knobs
- [ ] A CLI exit of 3 (no key) takes the current path with no output about Jev; an exit of 4 (429/401/other) or malformed answers falls back to the leaf for that batch with one warning line
- [ ] Without a key the leaf invocations and the returned labels are identical to what the current skill's `N: label` pattern produces — asserted by the test with a fake `claude` on `PATH` (`llm_query` is byte-for-byte unchanged, asserted by diff)
- [ ] `scripts/tests/test-jev.sh` covers the helper on both paths against the stub server from ticket 01
- [ ] `skills/rlm/SKILL.md` tells the root to use `classify`, to keep `other` in the list, how to choose a threshold, and how to read `source`
