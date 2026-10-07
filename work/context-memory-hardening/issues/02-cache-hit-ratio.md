# 02 — Report prompt-cache share in the context-budget ledger (L50)

**What to build:** `claude_measure()` in `scripts/context-budget.sh`
(~line 264) already reads `cache_read_input_tokens` and
`cache_creation_input_tokens` but only sums them. Carry the cache-read
share (`cache_read / total`) through to the ledger row written at ~line 896
(`.context-budget/context-ledger.jsonl`) as a new optional field, and show
it in the human output of `record` / `status`. Fill it in for every runtime
whose transcript exposes a cached-input count: Claude for sure, Codex
`cached_input_tokens` if present, and check the others. Use `null` where
the runtime doesn't expose it. Never estimate. Existing ledger readers must
not break (grep for the ledger's consumers, including the statusline and
`docs/archive` analysis notes, which are history and not in scope).

Background: `work/context-memory-eval/eval.md` → C2, recommendation 2. It
backs the rule from ticket 01 with a measurement.

**Blocked by:** nothing (lands after 01 by order only).

**Status:** todo

- [ ] Failing test first (a fixture transcript with known cache numbers →
      the expected share in the ledger row; a runtime without cache data →
      `null`) in the matching `scripts/tests/` suite
- [ ] Implementation green; ledger schema change described in
      `docs/context-budget.md` (grep for the ledger section)
- [ ] Backlog card resolved in the same commit: badge → Resolved, `Fixed:`
      line with the commit, card moved to the matching section of
      `docs/template-workspace-backlog-archive.html`, scorecard and "Last
      updated" changed, change-log row added
- [ ] All `scripts/tests/test-*` suites green; `scripts/check-workspace-structure.sh` exit 0
- [ ] One commit, `Fix <ID>: …`, with a `Decision:` trailer
