---
id: 05-copilot-vscode-cli-runtime
title: Copilot VS Code on the CLI runtime (node 8a)
status: todo
kind: work
wave: 2
blocked_by: [02-reconcile-w1]
sessions: []
---

## Goal

Findings: `work/runtime-session-identity/findings.md` → "Gaps", node 8a. Evidence: `probes/copilot-vscode.md`.

Copilot agent mode in VS Code now runs on the Copilot CLI runtime: transcript
`~/.copilot/session-state/<sid>/events.jsonl`, `COPILOT_AGENT_SESSION_ID` in the agent shell,
no `VSCODE_TARGET_SESSION_LOG`. Fix the hook's `chat-sessions` derivation
(`scripts/hooks/context-budget-hook.sh`) to use a `session-state/<sid>/events.jsonl`
`transcript_path` as is (keep the workspaceStorage path for builds that still emit it), and
make `copilot_vscode_discover` (`scripts/context-budget.sh`) use `COPILOT_AGENT_SESSION_ID`
before `VSCODE_TARGET_SESSION_LOG`/newest-mtime.

## Acceptance

- [ ] Suite case: a VS Code `Stop` payload with a `session-state/<sid>/events.jsonl` transcript registers that existing file (not `~/.copilot/chatSessions/…`)
- [ ] Suite case: agent `register --runtime copilot-vscode` with only `COPILOT_AGENT_SESSION_ID` set binds `session-state/<sid>/events.jsonl`
- [ ] Old workspaceStorage cases still pass

## Log
