---
id: 02-score-check-helpers
title: Ticket 09 — score() and check() helpers with offline tests
status: done
kind: work
wave: 1
blocked_by: []
check: bash "$WORKSPACE_ROOT/scripts/tests/test-jev.sh" >/dev/null && grep -q '^def score' "$WORKSPACE_ROOT/skills/rlm/scripts/rlm_repl.py" && grep -q '^def check' "$WORKSPACE_ROOT/skills/rlm/scripts/rlm_repl.py"
sessions: [18]
---

## Goal

Ticket: issues/09-score-and-check-helpers.md
Spec: S23, S24, S25

Two new helpers in `skills/rlm/scripts/rlm_repl.py`, siblings of `classify()` (same CLI batching via `scripts/jev.sh`, same per-record fallback, same result shape with `source`). `score(records, levels, threshold=None, question=...)`: Jev Score with 2–10 ordered level descriptions; result `{level, confidence, source}`; falls back below the 0.5 confidence threshold; docstring carries the reliability caveat (Score least reliable in the one report). `check(records, condition, margin=None, question=...)`: Jev Noul, one yes/no per record; result `{value: bool, probability, source}`; falls back when `|p − 0.5| < DEFAULT_JEV_NOUL_MARGIN` (0.25, env `RLM_JEV_NOUL_MARGIN`). No-key path: leaf prompts in the `N: level` / `N: yes|no` pattern via `llm_query_map`. `llm_query`/`llm_query_map` and the T14 golden untouched. Test-first: T21+ in `scripts/tests/test-jev.sh` with Score/Noul fixture answers; `skills/rlm/SKILL.md` gains the two helpers and the margin knob; `skills/jev/SKILL.md` step 3 points at them.

Read first: `skills/rlm/SKILL.md`, `skills/jev/SKILL.md` (type table, step 3), `decisions.md` (fifth note: classify signature; eighth: threshold), `scripts/tests/test-jev.sh` (grep `T8`, `T9` for the classify pattern).

Test-first (`tdd`): T21+ red before the helpers land. `llm_query`/T14 golden untouched.

## Acceptance

- [x] `score()`: keyed → Score request shape against the stub (criteria = ordered level array), answers parsed to `{level, confidence, source: jev}`, fallback below 0.5; no key → leaf prompt byte-identical to the documented `N: level` pattern
- [x] `check()`: keyed → Noul request shape, `{value, probability, source: jev}`, fallback when `|p − 0.5| < 0.25`, margin env-overridable; no key → leaf `N: yes|no` prompt
- [x] `test-jev.sh` T21+ cover both helpers on both paths and the margin boundary; suite passes; T14 golden unchanged
- [x] `skills/rlm/SKILL.md` documents both helpers, the margin knob, and the Score caveat; `skills/jev/SKILL.md` step 3 names the helpers
- [x] `llm_query` byte-for-byte untouched (`git diff` shows no hunk in it)

## Log
- s18 · started, tier standard
- s18-a · tests first: T21-T25 (42 assertions) added to scripts/tests/test-jev.sh with fixtures scripts/tests/fixtures/jev/score-batch.json and noul-batch.json; suite red (32 fails) before the helpers
- s18-a · score() and check() added to skills/rlm/scripts/rlm_repl.py (registered in _make_helpers; DEFAULT_JEV_NOUL_MARGIN beside DEFAULT_JEV_THRESHOLD); classify's private helpers generalised into shared _jev_run/_jev_batch/_leaf_numbered; suite green 182/182 (was 140/140); no git-diff hunk in llm_query/llm_query_map, T14 golden unchanged
- s18-a · docs: skills/rlm/SKILL.md (helper rows, score-vs-check paragraph with Score caveat, RLM_JEV_NOUL_MARGIN knob) and skills/jev/SKILL.md step 3 pointer. On disk: all of the above, uncommitted. Not on disk: no commit, no live Jev run (stub only)
- s18 · check passed → done
