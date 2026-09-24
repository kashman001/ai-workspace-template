---
id: 09-reconcile-verdict
title: Verify spec and tickets agree with the decisions; close the plan
status: todo
kind: reconcile
wave: 3
blocked_by: [07-spec, 08-tickets]
tier: frontier
loop: 2
check: scripts/plan.sh check --project plans --plan 01-concept && test -n "$(ls issues/*.md)"
sessions: []
---

## Goal
Read spec.md and every ticket against decisions.md; fix drift in place;
set the README status line; close the plan.

## Acceptance
- [ ] Every settled decision is reflected in spec.md or a ticket.
- [ ] `plan.md` frontmatter reads `status: closed`.

## Log
