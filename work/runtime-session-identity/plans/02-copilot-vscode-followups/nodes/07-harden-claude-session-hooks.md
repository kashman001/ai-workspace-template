---
id: 07-harden-claude-session-hooks
title: Claude SessionStart/End hooks refuse Copilot payloads; PostToolUse suite case; doc fix
status: todo
kind: work
wave: 3
blocked_by: []
sessions: []
---

## Goal

Decided s12 (node 05, Q1 = A + both hardenings; `decisions.md` node-02 note). Test-first,
agent-agnostic. (1) The Claude `SessionStart`/`SessionEnd` inline commands in `.claude/settings.json`
(:9, :31) skip a payload whose `transcript_path` is a Copilot `*/session-state/<sid>/events.jsonl`,
the same test the dispatcher uses (`scripts/hooks/context-budget-hook.sh` ~:57-67) — so a future
Copilot that sends `transcript_path` there cannot write a `claude-*` record or bind the item as claude.
(2) A suite case: Claude `PostToolUse` (`context-budget-claude-hook.sh`) with a Copilot session-state
payload writes no stamp and no record. (3) `docs/context-budget.md` Copilot VS Code hook row (~:807):
`$CLAUDE_PROJECT_DIR` is set on the Copilot CLI runtime — correct the "unset" claim.

## Acceptance

- [ ] New suite case: Claude `SessionStart` command with a Copilot session-state `transcript_path` writes no `claude-*` record — seen red before the fix
- [ ] Same for `SessionEnd` (no `release` of a claude record) — seen red before the fix
- [ ] Claude `PostToolUse` + Copilot payload case added (green before: guard exists); a real Claude transcript still registers/records
- [ ] `docs/context-budget.md` `CLAUDE_PROJECT_DIR` sentence corrected
- [ ] Suites green: vendor hooks, registry, precompact, doc-consistency

## Log
