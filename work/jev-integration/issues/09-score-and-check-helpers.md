# 09 — `score()` and `check()` helpers beside `classify()`, with offline tests

**What to build:** Two new helpers in `skills/rlm/scripts/rlm_repl.py`, siblings of `classify()` (same CLI batching via `scripts/jev.sh`, same per-record fallback, same result shape with `source`). `score(records, levels, threshold=None, question=...)`: Jev Score with 2–10 ordered level descriptions; result `{level, confidence, source}`; falls back below the 0.5 confidence threshold; docstring carries the reliability caveat (Score least reliable in the one report). `check(records, condition, margin=None, question=...)`: Jev Noul, one yes/no per record; result `{value: bool, probability, source}`; falls back when `|p − 0.5| < DEFAULT_JEV_NOUL_MARGIN` (0.25, env `RLM_JEV_NOUL_MARGIN`). No-key path: leaf prompts in the `N: level` / `N: yes|no` pattern via `llm_query_map`. `llm_query`/`llm_query_map` and the T14 golden untouched. Test-first: T21+ in `scripts/tests/test-jev.sh` with Score/Noul fixture answers; `skills/rlm/SKILL.md` gains the two helpers and the margin knob; `skills/jev/SKILL.md` step 3 points at them.

**Read first:** `skills/rlm/SKILL.md`, `skills/jev/SKILL.md` (type table, step 3), `decisions.md` (fifth note: classify signature; eighth: threshold), `scripts/tests/test-jev.sh` (grep `T8`, `T9` for the classify pattern).

**Blocked by:** None.

**Status:** open

**Spec:** S23, S24, S25

- [ ] `score()`: keyed → Score request shape against the stub (criteria = ordered level array), answers parsed to `{level, confidence, source: jev}`, fallback below 0.5; no key → leaf prompt byte-identical to the documented `N: level` pattern
- [ ] `check()`: keyed → Noul request shape, `{value, probability, source: jev}`, fallback when `|p − 0.5| < 0.25`, margin env-overridable; no key → leaf `N: yes|no` prompt
- [ ] `test-jev.sh` T21+ cover both helpers on both paths and the margin boundary; suite passes; T14 golden unchanged
- [ ] `skills/rlm/SKILL.md` documents both helpers, the margin knob, and the Score caveat; `skills/jev/SKILL.md` step 3 names the helpers
- [ ] `llm_query` byte-for-byte untouched (`git diff` shows no hunk in it)

**Check:** `bash "$WORKSPACE_ROOT/scripts/tests/test-jev.sh" >/dev/null && grep -q '^def score' "$WORKSPACE_ROOT/skills/rlm/scripts/rlm_repl.py" && grep -q '^def check' "$WORKSPACE_ROOT/skills/rlm/scripts/rlm_repl.py"`
