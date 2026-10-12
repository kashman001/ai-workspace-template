---
id: 08-docs-worker
title: Docs: recommended-tooling, README, for-non-engineers, analysis addendum
status: todo
kind: work
wave: 3
blocked_by: [01-ceremony-guide, 06-apply-trigger-verdicts]
sessions: []
---

## Goal

Brief item 4, worker half. Update where they list or describe skills:
`docs/recommended-tooling.md`, `README.md`, `docs/for-non-engineers.md`
(pointer to `docs/stakes-to-ceremony.md`; user-invoked changes from
`trigger-review.md`; the adoption note's existence). Add a short "After the
video" addendum to `work/template-maintenance/skill-packs-analysis.md`
(what changed and why, pointing at the guide, the review file and the check).
Note in the addendum that Addy's `/build auto` maps to `implement-spec`.
`retro` is pristine vendored: no one-liner (say so in the Log). Surgical
edits only; do not touch `CONTEXT.md`, `skills/vendored-skills.md`,
`docs/workspace-structure.md`.

## Acceptance

- [ ] The three docs point at the guide where they list skills; no stale "model-invoked" claims for skills that changed
- [ ] Addendum present in `skill-packs-analysis.md`, under ~40 lines
- [ ] `scripts/tests/test-doc-consistency.sh` passes

## Log
