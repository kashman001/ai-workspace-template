---
id: 11-code-review-pass
title: Run code-review on the work since 8e16d66; fix the findings
status: done
kind: work
wave: 4
blocked_by: [10-reconcile-w3]
sessions: [24]
---

## Goal

Run `skills/code-review/SKILL.md` on the diff since `8e16d66` against the
workspace standards (`CONTEXT.md` coding principles,
`skills/writing-for-agents/SKILL.md`) and the spec
(`skill-ceremony-brief.md`). Fix every blocker; fix or log each suggestion.

## Acceptance

- [x] Review run (findings in the Log)
- [x] Every blocker fixed; each suggestion fixed or logged
- [x] `scripts/run-checks.sh` passes in full; sync round trip leaves an empty diff

## Log
- s24 · started, tier standard
- s24-g · review done: Standards 0 blockers / 7 suggestions, Spec 0 blockers / 3 suggestions; findings in work/template-maintenance/skill-ceremony-review.md
- s24 · review read (skill-ceremony-review.md): 0 blockers, 10 suggestions. Fixed: unused run() deleted; CRLF fixture added and folded fixture switched to `>-` (seen red with the CR strip removed: P1 and P4 crlf failed; 12/12 after restore); `disable-model-invocation: true` anchored to end of line; 7,500 no longer restated outside the check's bullet in workspace-structure.md; duplicate stakes pointer and duplicate `/build auto` mapping removed; addendum names the decision-log/jev tightenings. Logged, not changed: CONTEXT.md "user-invoked only" labels (reviewer: leave); unslop narrowed in frontmatter not patch (decisions.md; reported). M51 numbers corrected in its Fixed: note.
- s24 · verification: sync round trip for all three upstreams against clones at the pinned commits (mattpocock ~/Developer/references; addyosmani 1be8e34 and cursor/plugins 978ca6e cloned into the scratchpad) → git status empty; full run-checks re-run below after the fixes
- s24 · done
