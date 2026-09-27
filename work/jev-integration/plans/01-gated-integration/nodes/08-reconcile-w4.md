---
id: 08-reconcile-w4
title: Join wave 4
status: done
kind: reconcile
wave: 4
blocked_by: [07-gate-cli-test]
sessions: [9]
---

## Goal

Join wave 4: verify every work node of the wave on disk, record decisions, replan within authority (`replan: structural`), `check` silent, `sync`. Procedure: skills/plans/SKILL.md → "Run a reconcile node".

## Acceptance

- [x] Verified on disk — every ticked box of the wave's work nodes held (open the file, run the check, read the test output)
- [x] Decisions recorded — forks as Tier-2 notes, discoveries as `plan.sh note`
- [x] Replan applied within authority (`## Replans` lines), `check` silent, board and Position synced

## Log
- s9 · started, tier frontier
- s9 · verified: `verify 07-gate-cli-test` green (34/34), the three files on disk, no key writes in `jev.sh`; Tier-2 note (stdin/JSON-lines CLI shape) appended; live-call finding as `note`; no replan needed (ticket 04 owns S7; exit 4 already in the CLI, its test is ticket 04's). Wave 4 joined.
- s9 · done
