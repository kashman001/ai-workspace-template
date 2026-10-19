---
id: 05-reconcile-w1
title: Join wave 1: merge branches, verify, move L85/L95/L96 cards
status: done
kind: reconcile
wave: 1
blocked_by: [01-l85-skip-template-only-suites, 02-l95-dispatch-contract, 03-l96-usage-limit-watchdog, 04-l98-pilot-design]
sessions: [3]
---

## Goal
Join wave 1. Merge each isolated branch (01–03) into main, then verify. For each verified card (L85, L95, L96), move it to `docs/template-workspace-backlog-archive.html` with a `Fixed:` line, update the scorecard and add a changelog row — re-read both files right before writing (other sessions share the checkout). Run `scripts/run-checks.sh`.

## Acceptance
- [x] every node this joins verified on disk (files opened, commands run, `plan.sh verify`)
- [x] decisions recorded (Tier-2 notes / `plan.sh note`)
- [x] replan applied, `plan.sh check` silent

## Log
- s3 · started, tier frontier
- s3 · verdict: wave 1 verified. Branches 01–03 merged (2aff7a9, merge of c0ccb48, merge of 12c79bb), worktrees removed. Re-ran: plan.sh verify 01/02/03/04 pass; L85 in a git-archive instance copy (3×rc 77 + doc-consistency 17/0); fleet dispatch-contract suite 30/0; read the L96 file:line claims (launch-next-session.sh:397, session-loop.sh:268-270, context-budget.env:101) — they hold. Fixed probe-twins WORKSPACE_ROOT leak found by verify. Cards L85/L95/L96 moved to archive, scorecard 3/150/5/0/6. scripts/run-checks.sh 45/0/0. Two Tier-2 notes in decisions.md. No replan needed; node 06 note: run.sh scratch default now $TMPDIR, judge script still to write.
- s3 · done
