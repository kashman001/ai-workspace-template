---
plan: 02-follow-on
status: open
replan: local
default_tier: standard
---

# Plan 02 — Jev follow-on: confirm 0.5, Score/Noul helpers, research-wave second reader, tier-routing evidence, relevance experiment

## Goal

Ship the five follow-on slices the user approved on 2026-09-28 (all of them,
spend pre-authorized), as amended into `spec.md` S22–S30 and re-approved in
session 17 after a nine-question grill (1a 2a 3a 4a 5a 6b 7a 8b 9a; the
questions and answers are in ledger block 17). Waves follow the blockers, not
the slice order: wave 1 = the three independent pieces (threshold
confirmation, `score()`/`check()`, relevance experiment); wave 2 = the two
that use the confirmed threshold (research-wave second reader, tier-routing
evidence + `plans` ticket 12). Every paid batch is run by the agent on the
keyed machine and its cost written into the node Log (S30). Tickets:
`issues/08-…` to `issues/12-…`.

## Not yet specified

## Out of scope

- Editing `plan.sh`, `plan-tiers.env`, `session-loop.sh`, or the `plans`
  skill (the tier-routing *code* is the `plans` item's; this plan hands it a
  ticket with evidence).
- A relevance filter as a feature — S29 is an experiment whose artefact is a
  decision note.
- Any fact-checker or ruling step that depends on a Jev answer; the second
  reader only flags.
- Touching `llm_query`, the T14 golden, `research/`, or pushing `main`.

## Replans

<!-- plan:begin board -->
| Wave | Node | Kind | Tier | Status |
|---|---|---|---|---|
| 1 | 01-confirm-threshold | work | standard | done |
| 1 | 02-score-check-helpers | work | standard | done |
| 1 | 03-relevance-experiment | work | cheap | todo |
| 1 | 04-reconcile-w1 | reconcile | frontier | todo |
| 2 | 05-research-wave-second-reader | work | standard | todo |
| 2 | 06-tier-routing-evidence | work | cheap | todo |
| 2 | 07-reconcile-w2 | reconcile | frontier | todo |
Frontier: 03-relevance-experiment. Remaining: 5 of 7. Sessions used: 1.
<!-- plan:end board -->
