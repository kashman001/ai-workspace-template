---
id: 08-reconcile-2
title: View every cross-runtime shot; RESULTS cross-runtime section; verdict question ready
status: done
kind: reconcile
wave: 2
blocked_by: [07-cross-runtime-test]
check: grep -qi 'cross-runtime' prototype/RESULTS.md
sessions: [8]
---

## Goal

Main session views every cross-runtime shot itself; writes the RESULTS 'Cross-runtime' section (pass/fail per figure per runtime, rule violations, tokens of each output measured).

## Acceptance

Then the verdict question goes to the user: adopt (docs/kit/ plain files) or drop.

## Log
- s8 · started, tier frontier
- s8 · check passed → done
