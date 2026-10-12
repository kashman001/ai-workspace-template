---
id: 02-trigger-review
title: Trigger review: every model-invoked skill — keep / tighten / user-invoke; unslop narrowed
status: done
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

- [x] `work/template-maintenance/trigger-review.md`: one row per model-invoked skill — verdict, reason, new description text where it changes, byte counts before/after
- [x] `unslop` description narrowed in its frontmatter (adapted class); `scripts/sync-vendored-skills.sh` round trip not required here but the file keeps its provenance comment
- [x] Any other vendored change made via the adapted frontmatter or a `workspace.patch` that `patch --dry-run` accepts
- [x] Tier-2 note texts included in the review file (one per non-obvious call)

## Log
- s24 · started, tier standard
- s24-b · verdicts for all 32 model-invoked skills: keep 23, tighten 6, user-invoke 3 (checkpoint, session-rollover, design-for-testability); table, paste-ready descriptions, openai.yaml lines and five Tier-2 notes in work/template-maintenance/trigger-review.md
- s24-b · applied vendored edits: skills/unslop/SKILL.md and skills/technical-writing/SKILL.md frontmatter (adapted class, provenance comments intact); skills/constraint-driven-development/workspace.patch and skills/doubt-driven-development/workspace.patch regenerated with a description hunk, `patch -p1 -R -F0 --dry-run` passes and a forward apply onto the reconstructed upstream file reproduces SKILL.md; check-skill-descriptions.sh now 9508 bytes over 32 (was 10174)
- s24-b · not on disk: the five workspace-skill rows (decision-log, jev tighten; checkpoint, session-rollover, design-for-testability user-invoke) and the budget value, both for node 06; projected 7303 bytes over 29 skills, recommended SKILL_DESC_MAX_BYTES=7500; nothing committed
- s24 · done
