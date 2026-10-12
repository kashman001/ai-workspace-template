---
id: 07-antigravity-runtime
title: Antigravity: add as a runtime (node 6)
status: doing
kind: work
wave: 2
blocked_by: [02-reconcile-w1]
sessions: [6]
---

## Goal

Findings: `work/runtime-session-identity/findings.md` → "Gaps", node 6. Evidence: `probes/antigravity-cli.md`.

New `antigravity` adapter row with `register=hook`; a committed `.agents/hooks.json` whose
`PreInvocation` handler registers on `invocationNum == 0` from the payload's
`conversationId` + `transcriptPath`; discover/measure over
`~/.gemini/antigravity-cli/brain/<id>/.system_generated/logs/transcript_full.jsonl` (last
`PLANNER_RESPONSE` `input_tokens` + `cache_read_tokens`); a `detect_runtime` case on
`ANTIGRAVITY_CONVERSATION_ID`.

## Acceptance

- [x] Suite case: a `PreInvocation` payload writes `antigravity-<id>.json` pointing at its transcript
- [x] Suite case: `register` with only `ANTIGRAVITY_CONVERSATION_ID` set picks `antigravity`
- [x] Existing suites pass

## Log
- s6 · started, tier standard
- s6-e · RED: L1a–L3b added to scripts/tests/test-context-budget-registry.sh (hook register, env-only register, APP_DATA_DIR root, PLANNER_RESPONSE measure); all 7 fail before the fix (passed=211 failed=7)
- s6-e · GREEN: antigravity adapter in scripts/context-budget.sh (antigravity_discover over ${ANTIGRAVITY_APP_DATA_DIR:-~/.gemini/antigravity-cli}/brain/<id>/.system_generated/logs/transcript_full.jsonl; antigravity_measure = last PLANNER_RESPONSE input_tokens + cache_read_tokens via jq; session_id_for + artifact-derived id); row `antigravity` (register=hook, pin ANTIGRAVITY_CONVERSATION_ID=sid, PreInvocation:inject-json-only) in scripts/hooks/context-budget-adapters.conf; shim scripts/hooks/context-budget-antigravity-hook.sh; .agents/hooks.json. Registry suite L1a–L3b pass (218/0); hooks suite L4a–L4d added, seen failing against the c82505f dispatcher (3 fail), now 154/0
- s6-e · all 18 context-budget suites + check-workspace-structure, agent-entrypoints, run-checks suites pass; the real probe transcript c2d716d4 measures tokens=24065 cache=90%
