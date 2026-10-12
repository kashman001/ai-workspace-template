---
id: 09-phantom-records
title: Ignore phantom records with a never-written artifact (node 8c)
status: doing
kind: work
wave: 3
blocked_by: [08-reconcile-w2]
sessions: [7]
---

## Goal

Findings: `work/runtime-session-identity/findings.md` → "Gaps", node 8c. Evidence: `probes/codex-vscode.md` → "Side observation".

Claude Code's VS Code extension pre-spawns idle sessions that register records for
transcripts that never get written. Ignore (or prune) records whose artifact is still
missing after a grace period, so they never shadow a real session. Codex in VS Code has
`pid: null`, so pruning must not depend on the pid.

## Acceptance

- [x] Suite case: a record whose artifact is missing past the grace period is ignored by `record`/`status`
- [x] Suite case: a fresh record (inside the grace period, artifact not yet flushed) is kept
- [x] Existing suites pass

## Log
- s7 · started, tier standard
- s7-a · red: suite cases A1a-A1d/A2a-A2d added at the end of scripts/tests/test-context-budget-registry.sh; A1b, A1c, A1d failed (242/3) before the fix
- s7-a · green: prune_phantoms() in scripts/context-budget.sh, called by register and record, drops sessions/*.json whose artifact (recorded path or claude id-keyed glob) is missing and whose record file is >60 min old; never consults the pid; skips the caller's own record. Registry suite 245/0
- s7-a · existing suites pass: statusline 20/0, vendor-budget-hooks 165/0, attach-session 27/0, fleet-children 29/0, fleet-dispatch-records 55/0, fleet-dispatch-contract 24/0, session-numbering 18/0, launch-next-session 188/0, doc-consistency 17/0
- s7-a · on disk: commit 79c5a6a + merge of main (conflict in the suite tail resolved by keeping both Q and A blocks; registry 248/0 after merge) on branch worktree-agent-a308de322c7557523; not on disk: no doc update in docs/context-budget.md, no pruning in read-only `check`/`--session-id` paths or in attach-session.sh/fleet.sh readers, not pushed
