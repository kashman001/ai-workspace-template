---
id: 02-trigger-review
title: Trigger review: every model-invoked skill — keep / tighten / user-invoke; unslop narrowed
status: doing
kind: work
wave: 1
blocked_by: []
sessions: [24]
---

## Goal

Brief item 2 (review half). Read every `skills/*/SKILL.md` frontmatter. For
each model-invoked skill (no `disable-model-invocation: true`) decide: keep
as is, tighten the description (shorter, trigger-specific, no "always"), or
make user-invoked. Write the verdict table with the exact new description
text to `work/template-maintenance/trigger-review.md`. Apply the vendored
changes yourself: `unslop` (adapted class — edit its frontmatter description
directly, see decisions.md), and any Addy/pstack skill whose verdict needs a
frontmatter change (adapted class) or a body change (patch). Do NOT edit
workspace-authored skills (`checkpoint`, `session-rollover`, `decision-log`,
`create-work-item`, `plans`, `design-for-testability`, `jev`, `rlm`, `why`,
`doc-review`, `onboard-repo`, `research-wave`): node 06 applies those from
your table. Each non-obvious call becomes a Tier-2 note (text in the review
file, orchestrator copies it to decisions.md).

## Acceptance

- [ ] `work/template-maintenance/trigger-review.md`: one row per model-invoked skill — verdict, reason, new description text where it changes, byte counts before/after
- [ ] `unslop` description narrowed in its frontmatter (adapted class); `scripts/sync-vendored-skills.sh` round trip not required here but the file keeps its provenance comment
- [ ] Any other vendored change made via the adapted frontmatter or a `workspace.patch` that `patch --dry-run` accepts
- [ ] Tier-2 note texts included in the review file (one per non-obvious call)

## Log
- s24 · started, tier standard
