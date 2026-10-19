---
id: 11-review-plan-02
title: Review the work since 816a7d9^ (standards + spec)
status: done
kind: work
wave: 4
blocked_by: [09-reconcile-w3]
sessions: [14]
---

## Goal

Review the plan-02 work since `816a7d9^` with the `code-review` skill (standards + spec against the two decided notes). Findings become follow-up nodes or are fixed in this node.

## Acceptance

- [x] Review run; findings listed in the Log
- [x] Each finding fixed (suite seen red first) or turned into a node

## Log
- s14 · started, tier standard
- s14 · code-review (standards + spec sub-agents) on plan-02 commits 3928a86, 34c76b4, 6c5ae3a, plan-02 paths only (05cf58b and the others in `816a7d9^..HEAD` are other items). No hard standards violations.
- s14 · F1 FIXED — the node-08 guard also fired on `COPILOT_AGENT_SESSION_ID` alone, so a leaked var re-filed a VS Code Local `chatSessions` transcript as copilot-cli (both reviewers; contradicts the node-02 note "env vars leak into nested launches"). Registry H5 seen red (`runtime=copilot-cli` for a chatSessions artifact), then green: the guard now keys on the session-state path only (discovery already maps the var to that path). Doc paragraph updated. Suites: registry 284/0, vendor hooks 171/0, statusline 20/0, attach-session 27/0, doc-consistency 17/0.
- s14 · F2 accepted, no node — the rename runs after the registry lookup, so `--runtime copilot-vscode` on the CLI runtime with no id var never reads its copilot-cli record and dies rc 3. This is the side gap the node-03 note already records; with the id var set, discovery resolves it.
- s14 · F3 accepted, no node — the session-state pattern appears in 5 places (context-budget.sh x2, the hook dispatcher x2, settings.json x2). The settings.json copies are inline commands and cannot share. Judgement call (Shotgun Surgery); no change.
- s14 · F4 accepted risk, no node — `prompt_tokens` takes the last match on the line, and the `*Metrics` cut assumes those keys come after it. Holds on every real checkpoint seen (only `main` listed). Revisit if sub-conversation entries appear.
- s14 · F5 accepted risk, no node — `sed … 2>/dev/null` would hide a BSD "illegal byte sequence" error and fall back to the size estimate. events.jsonl is UTF-8 JSON; not observed.
- s14 · F6 accepted — the Copilot CLI overcount fix in 3928a86 is outside node 01's Acceptance, but node 01's Log justifies it and test Q3c covers it.
- s14 · F7 FIXED — the doc row's "Copilot CLI ≥1.0.12 sets CLAUDE_PROJECT_DIR" now cites its source (CLI changelog, per the node-02 note).
- s14 · done
