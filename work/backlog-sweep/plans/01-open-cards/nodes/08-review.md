---
id: 08-review
title: Run code-review on the work since BASE; fix the findings
status: todo
kind: work
wave: 3
blocked_by: [07-reconcile-w2]
tier: frontier
sessions: []
---

## Goal
Run `skills/code-review/SKILL.md` on the diff since BASE = the commit that opened this plan (`git log --format=%h --diff-filter=A -1 -- work/backlog-sweep/plans/01-open-cards/plan.md`), against the success criteria in `work/backlog-sweep/README.md`. Fix every blocker; fix or log each suggestion.

## Acceptance
- [ ] review run
- [ ] every blocker fixed, each suggestion fixed or logged
- [ ] `scripts/run-checks.sh` passes

## Log
