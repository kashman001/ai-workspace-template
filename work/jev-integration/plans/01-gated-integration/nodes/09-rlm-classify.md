---
id: 09-rlm-classify
title: Ticket 02 — rlm classification helper: batch-as-state, other, threshold fallback
status: done
kind: work
wave: 5
blocked_by: [07-gate-cli-test]
check: bash "$WORKSPACE_ROOT/scripts/tests/test-jev.sh"
sessions: [10]
---

## Goal

Ticket: issues/02-rlm-classify-helper.md
Spec: S1, S2, S9, S10, S11, S12, S13, S14, S19

The `rlm` root calls `classify(records, categories)` in the REPL and gets one label per record with a confidence and a source. With a key, each batch of up to 50 records is one Jev request through the CLI (`state` = the records, one Choice per record, the root's categories plus `other`), sized to stay under the 32k-token state limit, and any record below the confidence threshold is re-asked through the current sub-model leaf. Without a key the helper takes the current path — the same `N: label` prompt through `llm_query_map` — and nothing mentions Jev. `llm_query` itself is untouched. The `rlm` skill teaches the root to use it.

## Acceptance

- [x] `classify(records, categories, threshold=None)` is a REPL helper beside `llm_query`; returns a list of `{label, confidence, source}` aligned with `records`, `source` one of `jev` or `leaf`
- [x] With a key: batches of 50, split further when the estimated tokens of `state` plus the longest question would exceed 32k; each question's instructions reference `` `records[i]` ``; `other` is appended to the categories with a fixed description
- [x] Records with `confidence` below the threshold are re-asked through the current leaf and reported with `source: leaf`; the threshold and the model id (`jev-latest`) are each one module constant, env-overridable like the other `RLM_*` knobs
- [x] A CLI exit of 3 (no key) takes the current path with no output about Jev; an exit of 4 (429/401/other) or malformed answers falls back to the leaf for that batch with one warning line
- [x] Without a key the leaf invocations and the returned labels are identical to what the current skill's `N: label` pattern produces — asserted by the test with a fake `claude` on `PATH` (`llm_query` is byte-for-byte unchanged, asserted by diff)
- [x] `scripts/tests/test-jev.sh` covers the helper on both paths against the stub server from ticket 01
- [x] `skills/rlm/SKILL.md` tells the root to use `classify`, to keep `other` in the list, how to choose a threshold, and how to read `source`

## Log
- s10 · started, tier standard
- s10 · built test-first: T8–T14 in `scripts/tests/test-jev.sh` (red on the missing helper), then `classify()` + `_jev_batches`/`_jev_question`/`_jev_classify_batch`/`_leaf_classify` in `skills/rlm/scripts/rlm_repl.py` (constants `DEFAULT_JEV_THRESHOLD`=0.9/`RLM_JEV_THRESHOLD`, `DEFAULT_JEV_MODEL`/`RLM_JEV_MODEL`, `JEV_BATCH`, `JEV_TOKEN_LIMIT`), registered in `_make_helpers`; `llm_query` byte-for-byte unchanged, asserted by diff against `scripts/tests/fixtures/jev/llm_query.golden.py` (T14). Green 92/92. Two small widenings beyond the ticket signature: `categories` may be a `{label: description}` dict (Choice criteria need descriptions) and an optional `question=` kwarg (the skill's pattern has one). SKILL.md: section 3 rewritten around `classify`, table row, guardrail, notes.
- s10 · check passed → done
