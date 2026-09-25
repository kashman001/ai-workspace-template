---
plan: 01-gated-integration
status: open
replan: structural
default_tier: standard
---

# Plan 01 — Gated Jev integration: fit note → approval → spec + tickets → (replanned) implementation

## Goal

Take `jev-integration` from "research closed, fit decision open" to a shipped,
gated integration. Direction from the user (2026-09-25, answering the `plans`
item's ticket 11): integrate — but Jev is active **only where a person has Jev
access** (a key in the OS keychain as `jev-api-key`); without one every seam
behaves exactly as today — session 6's grill question Q4, answered (a); its
Q1, Q2 and Q5 are proposed by node 01 and confirmed in node 03. Proposed seam: the `rlm` leaf classifier first
(`research/synthesis.md` §5's strongest fit; `research/spike.md` measured
0.64s vs 4.83s on five records). Wave 1 drafts the Tier-2 fit note, wave 2 a
person approves or amends it, wave 3 writes the spec and tickets; the wave-3
reconcile node replans structurally, adding the implementation waves from
those tickets (`skills/plans/SKILL.md` → "Create a plan", steps 2–4). This
plan is also the `plans` item's dogfood (`work/plans/issues/11-dogfood.md`):
what breaks, what is slow, and the L48 question go to
`work/plans/decisions.md` as they appear.

## Not yet specified

## Out of scope

- Seams other than `rlm` in the first implementation (research-wave verdicts,
  triage, doc-review, decision-log, checkpoint routing) — a later plan.
- Anything ADR-0011 rules out: session-loop verdicts, budget gates, ledger checks.
- Pushing `main`; changing `plan.sh`, `session-loop.sh`, or the plans skill
  from this item (a dogfood bug is a note in `work/plans/decisions.md` first,
  a fix under the plans item second).

## Replans

<!-- plan:begin board -->
| Wave | Node | Kind | Tier | Status |
|---|---|---|---|---|
| 1 | 01-decision-note | work | auto | todo |
| 1 | 02-reconcile-w1 | reconcile | frontier | todo |
| 2 | 03-approve-decision | hitl | frontier | todo |
| 2 | 04-reconcile-w2 | reconcile | frontier | todo |
| 3 | 05-spec-and-tickets | work | auto | todo |
| 3 | 06-reconcile-w3 | reconcile | frontier | todo |
Frontier: 01-decision-note. Remaining: 6 of 6. Sessions used: 0.
<!-- plan:end board -->
