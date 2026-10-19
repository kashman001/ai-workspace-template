---
id: 03-l96-usage-limit-watchdog
title: L96 — can the usage-limit wait trip SESSION_LOOP_KILL_AFTER?
status: doing
kind: work
wave: 1
blocked_by: []
tier: standard
check: test -s l96-findings.md && bash "$WORKSPACE_ROOT/scripts/tests/test-session-loop.sh" >/dev/null 2>&1
sessions: [3]
isolated: yes
---

## Goal
Card: `docs/template-workspace-backlog.html` → L96 (grep the ID; read only that card). Do not edit the backlog files — the reconcile node moves cards.
Synthesis R21. Read how `scripts/session-loop.sh` / `scripts/launch-next-session.sh` start chain children: interactive or `-p`? Claude Code's usage-limit auto-wait runs only interactively. If children can hit it, trace the `SESSION_LOOP_KILL_AFTER` watchdog path and decide: document the interaction (one line in `docs/context-budget.md` → supervisor section) or teach the watchdog to recognise the wait, test-first in `scripts/tests/test-session-loop.sh`. Write the reasoning, with file:line pointers, to `work/backlog-sweep/l96-findings.md`.

## Acceptance
- [x] `l96-findings.md` answers: interactive or not, can the watchdog kill a waiting session, what was done
- [x] the doc line or fix is in (a fix: suite case seen failing first)
- [x] `test-session-loop.sh` passes (node check)

## Log
- s3 · started, tier standard
- s3-c · L96 answered: children interactive, watchdog can kill a waiting session (transcript-write during wait unverified); doc paragraph added in docs/context-budget.md, findings at work/backlog-sweep/l96-findings.md; no code fix, suite 160/0. Not on disk: backlog card move (reconcile).
