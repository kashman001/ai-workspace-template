---
id: 01-refuse-instead-of-guess
title: Refuse instead of guess in discovery fallbacks (findings node 4)
status: todo
kind: work
wave: 1
blocked_by: []
sessions: []
---

## Goal

Findings: `work/runtime-session-identity/findings.md` → "Gaps", node 4.

In the discovery fallback (codex, copilot-cli, copilot-vscode, and auto-detect): when more
than one candidate transcript is live (recent mtime, matching cwd), refuse with a reason
code instead of taking the newest. `detect_runtime` must rank a nested runtime's own id var
(`ANTIGRAVITY_CONVERSATION_ID`, `COPILOT_AGENT_SESSION_ID`, `CODEX_THREAD_ID`) above
inherited outer-runtime vars (`CLAUDECODE`).

## Acceptance

- [ ] Suite case: two concurrent fixture transcripts with the id var unset → `register` exits non-zero with a reason code, no record written (seen to fail before the fix)
- [ ] Suite case: `CLAUDECODE=1` plus a nested runtime's id var → detects the nested runtime
- [ ] Existing context-budget suites pass

## Log
