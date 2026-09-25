---
id: 05-spec-and-tickets
title: spec.md via to-spec, tracer-bullet tickets via to-tickets
status: todo
kind: work
wave: 3
blocked_by: [03-approve-decision]
leaf: design
tier: auto
check: test -s spec.md && ls issues/*.md >/dev/null
sessions: []
---

## Goal

Source: the approved note in `decisions.md`; `README.md` → Success criteria
("If go"); the template rules listed in `research/synthesis.md` §5
(agent-agnostic, CLI-first or `mcp-fragments/`, key in the keychain,
first-class documentation, a test that proves it without a live key).

1. `spec.md` via the `to-spec` skill (`skills/to-spec/SKILL.md`; conventions
   in `docs/agents/issue-tracker.md` → "Spec conventions"). Stories must cover:
   the gate (key present → Jev; absent → the current path, unchanged and
   silent); the `rlm` swap point (batch-as-state, `other`, confidence
   threshold, model alias, the 32k-token state limit); credentials and docs
   (`docs/service-access.md`, `docs/runbooks/authentication.md`,
   `scripts/check-service-access.sh`); the offline test (fixture-recorded
   responses, both paths); downloader-facing documentation. Include
   `## Testability` (`skills/design-for-testability/SKILL.md`) and numbered
   success criteria (S1…) the implementation nodes' checks can name.
2. Tickets via `to-tickets` (`skills/to-tickets/SKILL.md`) under `issues/`:
   tracer bullets with `Blocked by:` edges — the first ticket lands the gate
   plus the offline test end to end, thin; later tickets widen it.

## Acceptance

- [ ] `spec.md` exists with `## Testability` and numbered success criteria
- [ ] `issues/NN-*.md` exist, each with `Blocked by:` and checkbox acceptance; the edges form no cycle
- [ ] Every story traces to the note in `decisions.md` or to `README.md` → Success criteria

## Log
