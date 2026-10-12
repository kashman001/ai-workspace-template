---
id: 09-docs-shared
title: Shared docs (orchestrator): vendored-skills.md, workspace-structure.md, CONTEXT.md
status: doing
kind: work
wave: 3
blocked_by: [01-ceremony-guide, 06-apply-trigger-verdicts]
sessions: [24]
---

## Goal

Orchestrator-only. `skills/vendored-skills.md`: patched/user-invoked status
per the review, `unslop` line, `ask-matt` line if patched, the `/build auto`
→ `implement-spec` mapping. `docs/workspace-structure.md`: the new check and
the guide in the skills/scripts sections. `CONTEXT.md` Workspace Skills: one
lean pointer to the guide; stays under `CONTEXT_MAX_BYTES` (16000).

## Acceptance

- [ ] The three shared files updated; `scripts/check-drift.sh` passes (CONTEXT budget)
- [ ] `skills/vendored-skills.md` classes match the directories (`workspace.patch` present ⇔ *(patched)*)

## Log
- s24 · started, tier standard
