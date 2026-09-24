---
description: Drive a work item's plan — create it from a spec or tickets, run a reconcile node, or replan (plan.sh owns the state writes)
argument-hint: "<create|reconcile|replan> [args]   (create <slug> [from issues/|spec.md] · reconcile <node-id> · replan <what + why>)"
---

Plan action: **$ARGUMENTS**

Execute the **plans** skill defined in `skills/plans/SKILL.md` — the procedure
named by the first word:

- `create` — "Create a plan": `plan.sh new`, waves from the blocking edges,
  `add` in wave order with a reconcile node closing each wave, ticket bodies
  into Goal/Acceptance, `done --force --by import` for finished tickets, then
  `check` silent and `sync`.
- `reconcile` — "Run a reconcile node": `start`, verify every joined node on
  disk (claims are hints), record decisions (`decision-log`), replan within the
  plan's `replan:` authority, tick the boxes, `check`, `done`.
- `replan` — "Replan": the change within authority, a `## Replans` line in
  `plan.md`, `check`, `sync`; above authority, a `hitl` node carrying the
  proposal.

Read `docs/plans.md` once before the first procedure. Every state write is a
`plan.sh` verb — `status` is never hand-edited. Pass `--project <item>` when
the session is bound to another item.
