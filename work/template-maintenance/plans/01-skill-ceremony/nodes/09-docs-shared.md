---
id: 09-docs-shared
title: Shared docs (orchestrator): vendored-skills.md, workspace-structure.md, CONTEXT.md
status: done
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

- [x] The three shared files updated; `scripts/check-drift.sh` passes (CONTEXT budget)
- [x] `skills/vendored-skills.md` classes match the directories (`workspace.patch` present ⇔ *(patched)*)

## Log
- s24 · started, tier standard
- s24 · on disk: CONTEXT.md "Stakes first" bullet (14,260 bytes, under 16,000); skills/vendored-skills.md — budget sentence, Addy "two tightened via patch", `/build auto` → `implement-spec`, unslop/technical-writing/constraint/doubt lines; docs/workspace-structure.md — check in tree, bullet list, checks table, authoring note, skills-section pointer; docs/README.md row for the guide. `scripts/check-drift.sh`: no DRIFT (one pre-existing ADR WARN). Patched dirs (7) match the *(patched)* marks (7).
- s24 · done
