---
id: 13-docs
title: Docs: hook trust, support matrix, adapter table (nodes 7 + 8d)
status: done
kind: work
wave: 4
blocked_by: [12-reconcile-w3]
sessions: [7]
---

## Goal

Findings: `work/runtime-session-identity/findings.md` → "Gaps", node 7 and 8d.

Document in `docs/context-budget.md`: hook trust is required (Codex and Copilot skip
untrusted hooks silently; the Codex VS Code extension asks only after the turn, and then
applies to open chats), the updated support matrix (Codex/Copilot CLI and VS Code,
Antigravity), and the adapter table.

## Acceptance

- [x] Hook-trust section covers Codex CLI, the Codex VS Code extension and Copilot
- [x] Support matrix and adapter table match the shipped adapter rows
- [x] Doc-link checks pass

## Log
- s7 · started, tier standard
- s7-d · docs/context-budget.md: adapter table gains the Antigravity row and Copilot VS Code CLI-runtime/inputTokens; new "Which runtime, and which pid" paragraph (detect_runtime order, pid:null); vendor table gains Antigravity (.agents/hooks.json, cd .., inject-json-only), Claude transcript_path, Copilot CLI registers; "One Copilot config acts per event"; support matrix + new "### Hook trust" (Codex CLI, Codex VS Code extension, Copilot); Session registration gains ambiguous_artifact and phantom-record paragraphs; reason-code row, ledger cache source, known-limitations auto-detect bullet updated
- s7-d · checks: scripts/tests/test-doc-consistency.sh 17/0, scripts/check-workspace-structure.sh all passed, scripts/tests/test-check-workspace-structure.sh 10/0; no dedicated doc-link checker exists under scripts/, so every path the new text names was checked to exist by hand
- s7-d · on disk: commit 3c7b555 on main (docs/context-budget.md + this node's log/ticks), not pushed; not on disk: plan.sh status write (orchestrator's), no live probe of codex SessionStart / copilot sessionStart / agy PreInvocation (doc says fixture-tested only), findings.md untouched
- s7 · done
