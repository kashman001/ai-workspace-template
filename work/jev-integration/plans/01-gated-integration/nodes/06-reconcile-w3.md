---
id: 06-reconcile-w3
title: Join wave 3 — structural replan: implementation waves from the tickets
status: todo
kind: reconcile
wave: 3
blocked_by: [05-spec-and-tickets]
sessions: []
---

## Goal

Join wave 3, then the structural replan this plan was opened for
(`replan: structural` in `plan.md` authorises it hands-off). Verify 05 on
disk: open `spec.md`, list `issues/`, confirm the `Blocked by:` graph is
acyclic and every ticket traces. Then add the implementation waves from the
tickets per `skills/plans/SKILL.md` → "Create a plan" steps 2–4: a ticket's
wave is 3 + (1 + the longest blocker chain behind it); one node per ticket
with a `Ticket:` pointer under `## Goal` and the ticket's checkboxes under
`## Acceptance`; `--check` from the ticket where a command exists (spec S-ids
by name); a reconcile node last in every new wave; a `hitl` node where a
person must judge — at least UAT of the gated behaviour on a machine with a
key and one without. Each addition is a line under `## Replans`.
`scripts/plan.sh check` silent, then `sync`.

## Acceptance

- [ ] Verified on disk — spec and tickets exist and trace; every ticked box of 05 held
- [ ] Decisions recorded — forks as Tier-2 notes, discoveries as `plan.sh note`
- [ ] Replan applied — implementation waves added from the tickets (`## Replans` lines), `check` silent, board and Position synced

## Log
