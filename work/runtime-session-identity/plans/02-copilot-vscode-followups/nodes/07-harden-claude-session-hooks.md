---
id: 07-harden-claude-session-hooks
title: Claude SessionStart/End hooks refuse Copilot payloads; PostToolUse suite case; doc fix
status: done
kind: work
wave: 3
blocked_by: []
sessions: [12]
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

- [x] New suite case: Claude `SessionStart` command with a Copilot session-state `transcript_path` writes no `claude-*` record — seen red before the fix
- [x] Same for `SessionEnd` (no `release` of a claude record) — seen red before the fix
- [x] Claude `PostToolUse` + Copilot payload case added (green before: guard exists); a real Claude transcript still registers/records
- [x] `docs/context-budget.md` `CLAUDE_PROJECT_DIR` sentence corrected
- [x] Suites green: vendor hooks, registry, precompact, doc-consistency

## Log
- s12 · started, tier standard

- s12 · tests `scripts/tests/test-vendor-budget-hooks.sh` K1i (SessionStart + Copilot session-state `transcript_path`, red: `register --runtime claude --transcript …/session-state/cp-k1/events.jsonl`), K1j (SessionEnd, red: `release --runtime claude …`), K1k/K1l (Claude PostToolUse + Copilot payload: no measure, no stamp; green before — dispatcher guard). Fix: the two inline commands in `.claude/settings.json` filter the path in their `jq` (`select(test("/session-state/[^/]+/events\\.jsonl$") | not)`, the dispatcher's pattern); controls K1e/K1h still register/release. Doc: `docs/context-budget.md` Claude row (skip) + Copilot VS Code row (`CLAUDE_PROJECT_DIR` claim corrected). Suites: vendor hooks 171/0, registry 279/0, precompact 11/0, doc-consistency 17/0.
- s12 · done
