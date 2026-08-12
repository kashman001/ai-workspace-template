---
description: Turn the current conversation into an effort spec at work/<effort>/spec.md — synthesis, no interview
argument-hint: "[effort slug or spec path]"
---

To-spec: **$ARGUMENTS**

Execute the **to-spec** workflow defined in `skills/to-spec/SKILL.md` —
synthesize the current conversation into a spec, no interview.

Tracker + spec conventions for this workspace are in
`docs/agents/issue-tracker.md`: the spec lands at `work/<effort>/spec.md`
and keeps the "Spec conventions" skeleton — `Status:`/`Approved-by:` header
and stable `S<n>` requirement IDs (the upstream template's numbered user
stories are the `S<n>` items).
