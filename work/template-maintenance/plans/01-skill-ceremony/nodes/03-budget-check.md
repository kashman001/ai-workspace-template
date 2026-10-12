---
id: 03-budget-check
title: check-skill-descriptions.sh: model-invoked description budget, test fails first
status: doing
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
- [ ] `scripts/tests/test-check-skill-descriptions.sh` passes; Log shows it failing on a bad case first
- [ ] `scripts/run-checks.sh --list` includes both files

## Log
- s24 · started, tier standard
