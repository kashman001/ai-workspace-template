---
id: 06-l98-pilot-run
title: L98 — run the three arms within the cap; score; recommend
status: todo
kind: work
wave: 2
blocked_by: [05-reconcile-w1]
tier: standard
parallel: 3
check: test -s pilot/results.md
sessions: []
---

## Goal
Card: L98. Run the arms in `pilot/design.md` with `pilot/run.sh`, up to 3 in parallel, stopping at the cap. Score each run against the rubric; write `pilot/results.md`: a table per skill (task × arm, pass/fail), the verdict per skill (keep / candidate to prune / inconclusive) and the runs and spend actually used. Recommend only; delete nothing.

## Acceptance
- [ ] runs ≤ cap, count logged
- [ ] `results.md` has a table and verdict per skill (node check)

## Log
