---
id: 07-antigravity-runtime
title: Antigravity: add as a runtime (node 6)
status: todo
kind: work
wave: 2
blocked_by: [02-reconcile-w1]
sessions: []
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

- [ ] Suite case: a `PreInvocation` payload writes `antigravity-<id>.json` pointing at its transcript
- [ ] Suite case: `register` with only `ANTIGRAVITY_CONVERSATION_ID` set picks `antigravity`
- [ ] Existing suites pass

## Log
