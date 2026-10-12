---
id: 10-record-without-env-id
title: Agent-run record finds its own session without the env var (node 5)
status: todo
kind: work
wave: 3
blocked_by: [08-reconcile-w2]
sessions: []
---

## Goal

Findings: `work/runtime-session-identity/findings.md` → "Gaps", node 5.

`record` from an agent shell with no id var must find its own registry record. A pid walk
is out (Copilot's `copilot-runtime` serves every chat; Codex's sandbox blocks `ps`). Use the
env id where the runtime sets one; otherwise have the hook's context message carry the id
for `--session-id`.

## Acceptance

- [ ] Suite case: `record` with the runtime's env id set and no `--session-id` updates that session's record, with a sibling record present
- [ ] Suite case: with no id var and two live records, `record` refuses (no guess) and names `--session-id`
- [ ] Existing suites pass

## Log
