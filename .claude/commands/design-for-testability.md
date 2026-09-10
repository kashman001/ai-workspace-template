---
description: Advisory design-time interrogation — how will we test this, how does it fail, what is observable, what is the cheapest proving check
argument-hint: "[effort slug, spec/ADR path, or the design to interrogate]"
---

Design to interrogate: **$ARGUMENTS**

Execute the **design-for-testability** skill defined in
`skills/design-for-testability/SKILL.md`.

- Ask its six questions in order (working looks like / cheapest check / how it
  fails / what is observable / design change to make checks cheap / accepted
  untested risk); sharpen vague answers before writing anything down.
- Land the answers where the design lives: a `## Testability` section in
  `work/<effort>/spec.md` (default), the ADR's Consequences section, or `V<n>`
  items in `work/<effort>/verification.md` for concrete checks.

Advisory, not a gate — it never blocks a design. Skip it for trivial changes.
