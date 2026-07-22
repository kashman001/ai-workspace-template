---
description: Roll work over to a fresh session via a deliberate, pruned handoff (context-budget WARN/STOP)
argument-hint: "[reason, e.g. 'hook STOP at 152K'] (optional)"
---

Rollover reason (optional): **$ARGUMENTS**

Execute the **session-rollover** workflow defined in `skills/session-rollover/SKILL.md` —
follow its seven steps in order (record trigger → reflect → flush → handoff.md →
next-session.md → bootstrap prompt → record completion).

Keep the whole response tight — this is a transition, not a status essay. End with the
paste-ready bootstrap prompt in a fenced block.
