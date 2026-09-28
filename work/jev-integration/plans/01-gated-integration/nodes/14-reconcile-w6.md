---
id: 14-reconcile-w6
title: Join wave 6
status: done
kind: reconcile
wave: 6
blocked_by: [13-uat-gated, 13b-uat-fixes]
sessions: [14]
---

## Goal

Join wave 6: verify every work node of the wave on disk, record decisions, replan within authority (`replan: structural`), `check` silent, `sync`. Procedure: skills/plans/SKILL.md → "Run a reconcile node".

## Acceptance

- [x] Verified on disk — every ticked box of the wave's work nodes held (open the file, run the check, read the test output)
- [x] Decisions recorded — forks as Tier-2 notes, discoveries as `plan.sh note`
- [x] Replan applied within authority (`## Replans` lines), `check` silent, board and Position synced

## Log
- s14 · started, tier frontier
- s14 · verified: 13b's four boxes hold (test-jev.sh 128/128; `--help` 0 lines > 80 cols, the ten sections in order; no `python ` invocation left in skills/rlm/SKILL.md; `verify 13b-uat-fixes` passes). 13 is hitl, marked done by the user; its boxes are unticked by design and its third box (observed fallback rate recorded) is the sixth note in decisions.md — 90/100 below 0.9. No claim failed. Recorded: Tier-2 note (hitl gate for node 15's paid calls) in decisions.md; dogfood finding in work/plans/decisions.md. Replan: 15a-authorize-live-runs (hitl) added ahead of 15 — see plan.md Replans. `check` silent → done.
- s14 · done
