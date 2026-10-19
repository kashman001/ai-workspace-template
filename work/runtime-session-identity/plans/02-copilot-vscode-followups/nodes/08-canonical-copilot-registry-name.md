---
id: 08-canonical-copilot-registry-name
title: One registry name per Copilot session: copilot-vscode on a session-state artifact files as copilot-cli
status: todo
kind: work
wave: 3
blocked_by: []
sessions: []
---

## Goal

Decided s12 (node 05, Q2 = (b); `decisions.md` node-03 note). Test-first. In
`scripts/context-budget.sh`, a `copilot-vscode` resolution whose artifact is
`*/session-state/<sid>/events.jsonl` (or with `COPILOT_AGENT_SESSION_ID` set) becomes `copilot-cli`, so
every path keys one `copilot-cli-<sid>.json` record and the same chat cannot lock itself out of its
work item (`owner_live`). One guard in one place. Update `work/runtime-session-identity/probes/probe-env.sh`
and registry test H2 (`scripts/tests/test-context-budget-registry.sh` ~:763) to expect `copilot-cli-<sid>`.
VS Code's Local harness (workspaceStorage `chatSessions`) keeps `copilot-vscode`.

## Acceptance

- [ ] New registry case: `register --runtime copilot-vscode` on a session-state artifact then the auto copilot-cli `register` → one record, no `owner_live` — seen red before the fix
- [ ] H2 updated to expect `copilot-cli-<sid>`; a chatSessions-artifact case still files as `copilot-vscode`
- [ ] `probe-env.sh` updated; `docs/context-budget.md` says the name is canonicalised
- [ ] Suites green: registry, vendor hooks, statusline, attach-session, doc-consistency

## Log
