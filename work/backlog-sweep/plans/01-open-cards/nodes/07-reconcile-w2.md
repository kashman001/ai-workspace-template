---
id: 07-reconcile-w2
title: Join wave 2: verify pilot results, move L98, file prune cards
status: todo
kind: reconcile
wave: 2
blocked_by: [06-l98-pilot-run]
sessions: []
---

## Goal
Join wave 2. Spot-check `pilot/results.md` against `pilot/runs/`. Move L98 to the archive with a `Fixed:` line; file one Low card per prune candidate (the user decides). Run `scripts/run-checks.sh`.

## Acceptance
- [ ] every node this joins verified on disk (files opened, commands run, `plan.sh verify`)
- [ ] decisions recorded (Tier-2 notes / `plan.sh note`)
- [ ] replan applied, `plan.sh check` silent

## Log
