---
id: 06-l98-pilot-run
title: L98 — run the three arms within the cap; score; recommend
status: done
kind: work
wave: 2
blocked_by: [05-reconcile-w1]
tier: standard
parallel: 3
check: test -s pilot/results.md
sessions: [3]
---

## Goal
Card: L98. Run the arms in `pilot/design.md` with `pilot/run.sh`, up to 3 in parallel, stopping at the cap. Score each run against the rubric; write `pilot/results.md`: a table per skill (task × arm, pass/fail), the verdict per skill (keep / candidate to prune / inconclusive) and the runs and spend actually used. Recommend only; delete nothing.

## Acceptance
- [x] runs ≤ cap, count logged
- [x] `results.md` has a table and verdict per skill (node check)

## Log
- s3 · started, tier standard
- s3-e · ran 26 new answer runs (smoke reused) + 9 blinded judge calls = 36 of 45 cap, ~$0.88; count in pilot/runs/COUNT; outputs in pilot/runs/, judge script pilot/judge.py
- s3-e · wrote pilot/results.md: tables + verdicts (unslop no earn/within noise; code-simplification prune candidate; technical-writing inconclusive). On disk: all of the above. Not on disk: reruns of close cells (none spent), reserve skill doubt-driven-development.
- s3 · check passed → done
