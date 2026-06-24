---
description: Wrap up the current chunk of work and emit a post-/compact catch-up prompt
argument-hint: "[next-focus, e.g. 'Phase 3 Trends'] (optional — inferred from the backlog/active work if omitted)"
---

Next focus (optional): **$ARGUMENTS**

Execute the **checkpoint** workflow defined in `skills/checkpoint/SKILL.md` — follow its four
steps in order (reconcile the record → write a hand-off doc via the `handoff` skill → confirm
clean branch state → emit a catch-up prompt), using the next-focus argument above.

After step 4, tell the user: run `/compact`, then paste the catch-up prompt to continue. Keep
the whole response tight — this is a transition, not a status essay.
