---
id: 09-phantom-records
title: Ignore phantom records with a never-written artifact (node 8c)
status: todo
kind: work
wave: 3
blocked_by: [08-reconcile-w2]
sessions: []
---

## Goal

Findings: `work/runtime-session-identity/findings.md` → "Gaps", node 8c. Evidence: `probes/codex-vscode.md` → "Side observation".

Claude Code's VS Code extension pre-spawns idle sessions that register records for
transcripts that never get written. Ignore (or prune) records whose artifact is still
missing after a grace period, so they never shadow a real session. Codex in VS Code has
`pid: null`, so pruning must not depend on the pid.

## Acceptance

- [ ] Suite case: a record whose artifact is missing past the grace period is ignored by `record`/`status`
- [ ] Suite case: a fresh record (inside the grace period, artifact not yet flushed) is kept
- [ ] Existing suites pass

## Log
