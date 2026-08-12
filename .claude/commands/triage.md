---
description: Move issues through the triage state machine — categorise, verify, and write agent-ready briefs
argument-hint: "[what to triage, e.g. 'what needs attention' or an issue path]"
---

Triage: **$ARGUMENTS**

Execute the **triage** workflow defined in `skills/triage/SKILL.md` — move
issues through the triage state machine.

Tracker conventions for this workspace are in `docs/agents/issue-tracker.md`:
issues are files under `work/<effort>/issues/`, and the canonical role names
(`needs-triage`, `needs-info`, `ready-for-agent`, `ready-for-human`,
`wontfix`; `bug`/`enhancement`) are used verbatim as `Status:`/category
lines — no label mapping. If the optional `grilling`/`domain-modeling`
skills aren't installed, skip the grilling step.
