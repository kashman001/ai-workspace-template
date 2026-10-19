---
id: 01-copilot-test
title: Copilot CLI rebuilds setup guide from the rules (cross-runtime test)
status: done
kind: work
wave: 1
blocked_by: []
check: test -f prototype/xrt/copilot/setup-guide.html
sessions: [9]
---

## Goal

Run the session-8 cross-runtime test on Copilot CLI: same brief `prototype/xrt/brief.md`, RT=copilot, output `prototype/xrt/copilot/`. Sandboxed / approval-limited launch only; if Claude Code auto mode denies the launch, mark the node blocked and leave the question for the user. Two rounds: the main session runs render-check and views every shot (contact sheet), then hands the shots back for round 2.

## Acceptance

- [x] `prototype/xrt/copilot/setup-guide.html` exists (or node blocked with the denial recorded)
- [x] every shot viewed by the main session, both rounds
- [x] Copilot column / section added to `prototype/RESULTS.md`

## Log
- s9 · started, tier standard
- s9 · launched sandboxed with scoped --allow-tool (no --allow-all); auto mode allowed it
- s9 · r1 4/5 unaided, r2 5/5; 40 shots viewed via contact sheets; RESULTS.md "Session 9" written; files prototype/xrt/copilot/
- s9 · check passed → done
