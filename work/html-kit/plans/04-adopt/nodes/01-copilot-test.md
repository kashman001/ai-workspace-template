---
id: 01-copilot-test
title: Copilot CLI rebuilds setup guide from the rules (cross-runtime test)
status: doing
kind: work
wave: 1
blocked_by: []
check: test -f prototype/xrt/copilot/setup-guide.html
sessions: [9]
---

## Goal

Run the session-8 cross-runtime test on Copilot CLI: same brief `prototype/xrt/brief.md`, RT=copilot, output `prototype/xrt/copilot/`. Sandboxed / approval-limited launch only; if Claude Code auto mode denies the launch, mark the node blocked and leave the question for the user. Two rounds: the main session runs render-check and views every shot (contact sheet), then hands the shots back for round 2.

## Acceptance

- [ ] `prototype/xrt/copilot/setup-guide.html` exists (or node blocked with the denial recorded)
- [ ] every shot viewed by the main session, both rounds
- [ ] Copilot column / section added to `prototype/RESULTS.md`

## Log
- s9 · started, tier standard
