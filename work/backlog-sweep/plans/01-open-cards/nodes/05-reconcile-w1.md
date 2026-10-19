---
id: 05-reconcile-w1
title: Join wave 1: merge branches, verify, move L85/L95/L96 cards
status: todo
kind: reconcile
wave: 1
blocked_by: [01-l85-skip-template-only-suites, 02-l95-dispatch-contract, 03-l96-usage-limit-watchdog, 04-l98-pilot-design]
sessions: []
---

## Goal
Join wave 1. Merge each isolated branch (01–03) into main, then verify. For each verified card (L85, L95, L96), move it to `docs/template-workspace-backlog-archive.html` with a `Fixed:` line, update the scorecard and add a changelog row — re-read both files right before writing (other sessions share the checkout). Run `scripts/run-checks.sh`.

## Acceptance
- [ ] every node this joins verified on disk (files opened, commands run, `plan.sh verify`)
- [ ] decisions recorded (Tier-2 notes / `plan.sh note`)
- [ ] replan applied, `plan.sh check` silent

## Log
