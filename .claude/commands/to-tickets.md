---
description: Break a plan, spec, or conversation into tracer-bullet tickets with blocking edges under work/<effort>/issues/
argument-hint: "[spec path, issue ref, or nothing to use the conversation]"
---

To-tickets: **$ARGUMENTS**

Execute the **to-tickets** workflow defined in `skills/to-tickets/SKILL.md` —
break the work into tracer-bullet vertical slices, each declaring its
blocking edges.

Tracker conventions for this workspace are in `docs/agents/issue-tracker.md`:
one file per ticket at `work/<effort>/issues/NN-<slug>.md` (not `.scratch/`),
`Status:` lines use the canonical role names verbatim, and tickets carry an
advisory `Spec: S<n>` line when the effort has a spec.
