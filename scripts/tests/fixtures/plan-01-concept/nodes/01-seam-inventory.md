---
id: 01-seam-inventory
title: Inventory existing mechanisms against the plan concept
status: done
kind: work
wave: 1
blocked_by: []
tier: standard
parallel: 2          # two Explore subagents, one per half of the list
loop: 1
check: test -s seams.md && grep -q '^## What is genuinely missing' seams.md
sessions: [1]
isolated: no
---

## Goal
For each of ten mechanisms: what part of a plan it covers, what it lacks,
wrap / replace / leave alone.

## Acceptance
- [x] `seams.md` has a coverage table with one row per mechanism.
- [x] A "What is genuinely missing" section names what no mechanism covers.

## Log
- s1 · dispatched two Explore subagents (standard tier), five mechanisms each.
- s1 · check passed; verified on disk → done.
