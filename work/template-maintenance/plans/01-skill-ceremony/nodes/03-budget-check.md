---
id: 03-budget-check
title: check-skill-descriptions.sh: model-invoked description budget, test fails first
status: done
kind: work
wave: 1
blocked_by: []
sessions: [24]
---

## Goal

Brief item 2 (check half). Add `scripts/check-skill-descriptions.sh`: sum the
bytes of the `description:` field of every `skills/*/SKILL.md` that is
model-invoked (no `disable-model-invocation: true` in the frontmatter), print
a per-skill table sorted largest first plus the total and the budget, and
exit 1 when the total exceeds `SKILL_DESC_MAX_BYTES` (a constant near the top
with the rationale comment, in the style of `CONTEXT_MAX_BYTES` in
`scripts/check-drift.sh`; env override `SKILL_DESC_MAX_BYTES` for tests).
Initial budget 9000 (node 06 lowers it after trimming). `run-checks.sh` picks
up `scripts/check-*` automatically. Add
`scripts/tests/test-check-skill-descriptions.sh` in the style of
`test-check-plans.sh` (fixture dir, P1 under budget exits 0, P2 over budget
exits 1 naming the largest skill, P3 user-invoked skills are not counted).
Run the test against a deliberately broken check first and record the
failing output in the Log, then fix.

## Acceptance

- [ ] `scripts/check-skill-descriptions.sh` exists, header comment in the house style, exits 0 on the current tree
- [x] `scripts/tests/test-check-skill-descriptions.sh` passes; Log shows it failing on a bad case first
- [x] `scripts/run-checks.sh --list` includes both files

## Log
- s24 · started, tier standard
- s24-c · failing first: against a deliberately wrong check (ignores disable-model-invocation, `-lt` compare) the test ended `check-skill-descriptions: 3 passed, 8 failed`
- s24-c · fixed check; test green `check-skill-descriptions: 11 passed, 0 failed`; `run-checks.sh --list` shows both files; live tree prints `total: 10174 bytes over 32 model-invoked skills (budget 9000)` and exits 1 (OVER BUDGET, largest decision-log) -- expected until the trim nodes land, so Acceptance box 1 (exit 0 on current tree) stays unticked
- s24-c · on disk: scripts/check-skill-descriptions.sh, scripts/tests/test-check-skill-descriptions.sh (both chmod +x, uncommitted); not done: nothing committed, budget not lowered, live tree not under 9000
- s24 · done
