---
id: 05-approve-decisions
title: User picks options for hook fan-out and duplicate records
status: todo
kind: hitl
wave: 2
blocked_by: [04-reconcile-w1]
sessions: []
---

## Goal

The user reads the two Tier-2 notes from nodes 02 and 03 and picks an option for each
(one question at a time, plain terms). Answer: `plan.sh done 05-approve-decisions --by human`
with the choices in the Log, or `drop` to stop after fix 1.

## Acceptance

- [ ] Hook fan-out option chosen
- [ ] Duplicate-records option chosen
- [ ] Live (moved from node 01): user opens a new Copilot VS Code chat in `~/Developer/experiments/ws-identity-probe-s9` (has the fix, d93e71a); its `check` reports `method=exact`

## Log
