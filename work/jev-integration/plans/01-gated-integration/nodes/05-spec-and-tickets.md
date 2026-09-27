---
id: 05-spec-and-tickets
title: spec.md via to-spec, tracer-bullet tickets via to-tickets
status: done
kind: work
wave: 3
blocked_by: [03-approve-decision]
leaf: design
tier: auto
check: test -s spec.md && ls issues/*.md >/dev/null
sessions: [8]
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

- [x] `spec.md` exists with `## Testability` and numbered success criteria
- [x] `issues/NN-*.md` exist, each with `Blocked by:` and checkbox acceptance; the edges form no cycle
- [x] Every story traces to the note in `decisions.md` or to `README.md` → Success criteria

## Log
- s8 · started, tier frontier
- s8 · started, tier auto
- s8 · spec.md written (21 stories S1–S21, Testability, Implementation/Testing Decisions, Out of scope names tier routing + relevance filter); six tickets under issues/ (01 gate+CLI+offline test → 02 rlm helper, 03 docs+preflight, 04 CLI three types+skill+rule → 05 UAT hitl → 06 tune+pin), edges acyclic, each with Spec: S-ids; Tier-2 note "rlm swap is a new typed helper beside llm_query" appended to decisions.md; TypeSafe skills re-check: last push 2026-09-12 (65a39f3, v0.5.7), nothing newer than 2026-09-23. On disk: spec.md, issues/*.md, decisions.md.
- s8 · check passed → done
- s8 · check passed → done
