---
id: 01-refuse-instead-of-guess
title: Refuse instead of guess in discovery fallbacks (findings node 4)
status: done
kind: work
wave: 1
blocked_by: []
sessions: [5]
---

## Goal

Findings: `work/runtime-session-identity/findings.md` → "Gaps", node 4.

In the discovery fallback (codex, copilot-cli, copilot-vscode, and auto-detect): when more
than one candidate transcript is live (recent mtime, matching cwd), refuse with a reason
code instead of taking the newest. `detect_runtime` must rank a nested runtime's own id var
(`ANTIGRAVITY_CONVERSATION_ID`, `COPILOT_AGENT_SESSION_ID`, `CODEX_THREAD_ID`) above
inherited outer-runtime vars (`CLAUDECODE`).

## Acceptance

- [x] Suite case: two concurrent fixture transcripts with the id var unset → `register` exits non-zero with a reason code, no record written (seen to fail before the fix)
- [x] Suite case: `CLAUDECODE=1` plus a nested runtime's id var → detects the nested runtime
- [x] Existing context-budget suites pass

## Log
- s5 · started, tier standard

- s5 · D1a–D1d and D2a–D2c added to `scripts/tests/test-context-budget-registry.sh`. Seen failing first: 12 FAIL, including D1d, which showed the old copilot-vscode guard was dead (its flag was set in a subshell).
- s5 · fix in `scripts/context-budget.sh`. `pick_unambiguous` handles the codex and copilot-cli fallback; copilot-vscode returns rc 2; `resolve_session` refuses with `reason=ambiguous_artifact` (exit 4) before any record is written; `detect_runtime` checks ANTIGRAVITY/COPILOT_AGENT/CODEX_THREAD ids before CLAUDECODE. The code is listed in `docs/context-budget.md` → Reason codes. Decision in `decisions.md`.
- s5 · verified: registry suite 211/0, and the other 17 context-budget suites pass (doc-consistency 17/0 after the doc row). Antigravity now detects as `antigravity` but has no adapter until node 07, so it dies "no session artifact" instead of binding the outer Claude transcript.
- s5 · done
