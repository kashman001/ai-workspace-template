---
id: 08-canonical-copilot-registry-name
title: One registry name per Copilot session: copilot-vscode on a session-state artifact files as copilot-cli
status: done
kind: work
wave: 3
blocked_by: []
sessions: [13]
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

- [x] New registry case: `register --runtime copilot-vscode` on a session-state artifact then the auto copilot-cli `register` → one record, no `owner_live` — seen red before the fix
- [x] H2 updated to expect `copilot-cli-<sid>`; a chatSessions-artifact case still files as `copilot-vscode`
- [x] `probe-env.sh` updated; `docs/context-budget.md` says the name is canonicalised
- [x] Suites green: registry, vendor hooks, statusline, attach-session, doc-consistency

## Log
- s13 · started, tier standard
- s13 · red first: new registry case H4 (register --runtime copilot-vscode, then the auto register, one session-state chat) failed 3 asserts incl. `reason=owner_live owner=copilot-vscode-vs-h4`; H2b/H2c failed on the old key. Fix: one guard at the end of `resolve_session` (`scripts/context-budget.sh`): copilot-vscode with `COPILOT_AGENT_SESSION_ID` or a `*/session-state/*/events.jsonl` artifact becomes copilot-cli. H1a, Q1a re-keyed to `copilot-cli-<sid>`; H1d (chatSessions) still files as copilot-vscode. Suites: registry 283/0, vendor hooks 171/0, statusline 20/0, attach-session 27/0, doc-consistency 17/0.
- s13 · accepted side effect: `--runtime copilot-vscode --session-id <sid>` on the CLI runtime finds no `copilot-vscode-<sid>` record (the pinned path returns before the guard). `--session-id` with auto runtime reads the record's own runtime and is unaffected.
- s13 · done
