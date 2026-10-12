---
id: 05-copilot-vscode-cli-runtime
title: Copilot VS Code on the CLI runtime (node 8a)
status: done
kind: work
wave: 2
blocked_by: [02-reconcile-w1]
sessions: [6]
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

- [x] Suite case: a VS Code `Stop` payload with a `session-state/<sid>/events.jsonl` transcript registers that existing file (not `~/.copilot/chatSessions/…`)
- [x] Suite case: agent `register --runtime copilot-vscode` with only `COPILOT_AGENT_SESSION_ID` set binds `session-state/<sid>/events.jsonl`
- [x] Old workspaceStorage cases still pass

## Log
- s6 · started, tier standard
- s6-c · red: added H1–H3 to scripts/tests/test-context-budget-registry.sh (real hook + real context-budget.sh); before the fix H1a failed (record bound `~/.copilot/chatSessions/vs-h1.jsonl`, the probe's bug), H1c failed (hook never measured), H2a/H2b failed (register exit 3, no record); 215 passed / 4 failed
- s6-c · found: fixing only the hook derivation would key the hook's record on `events` — the hook pins VSCODE_TARGET_SESSION_LOG=<transcript> and session_id_for took its basename; H1b guards this (seen to fail with session_id_for reverted: 217/2)
- s6-c · green: scripts/hooks/context-budget-hook.sh `chat-sessions` uses a `*/session-state/*/events.jsonl` transcript_path as is; scripts/context-budget.sh copilot_vscode_discover returns `${COPILOT_HOME:-$HOME/.copilot}/session-state/$COPILOT_AGENT_SESSION_ID/events.jsonl` first, session_id_for/…_artifact_only derive the sid from COPILOT_AGENT_SESSION_ID or the session-state dir; registry suite 219/0
- s6-c · Copilot-CLI-in-VS-Code-terminal check (H3): COPILOT_AGENT_SESSION_ID + TERM_PROGRAM=vscode + a leaked VSCODE_TARGET_SESSION_LOG auto-detects copilot-cli and binds its own session-state events.jsonl — passed before and after the fix, so the s5 detect_runtime order holds; H1d (old workspaceStorage → chatSessions/<sid>.jsonl) and hooks-suite T11/vscode-* cases still pass
- s6-c · side finding for other nodes: in a VS Code agent shell (AI_AGENT=github_copilot_vscode_agent) auto-detect still says copilot-cli, so agent `register` writes copilot-cli-<sid> while the VS Code hook writes copilot-vscode-<sid> for the same events.jsonl (two records, one session; node 06/8b territory). Also neither copilot measure fn reads the real events.jsonl token key (`prompt_tokens`, seen in a live probe transcript), so both fall back to a size estimate (node 04's adapter row)
- s6-c · done: on disk (branch worktree-agent-a8ce3513b31e7ca21, merged with main — already up to date) the hook + discovery fix and H1–H3; all 18 context-budget/hook suites pass (registry 219/0, hooks 150/0). Not on disk: no docs/context-budget.md update, no copilot-vscode measure change, no live re-probe in VS Code
- s6 · done
