# Decisions — backlog-sweep

Tier-2 decision notes (`skills/decision-log/SKILL.md`), newest last.

## 2026-10-18 — One work item and one plan for L85, L95, L96, L98, L86

- **Decision:** run the remaining open cards as one plan in this item,
  wave 1 in parallel subagents, instead of a work item per card.
- **Why:** the user asked for one plan executed in parallel with fitting
  model tiers; the cards are small and independent, so one board and one
  reconcile per wave is the least overhead.
- **Rejected:** a separate `dispatch-contract-hardening` item for L95, as
  its card suggested — it would split the board for a one-node piece of work.
- **Rejected:** putting L97 in the plan — its card defers it until
  `work/concurrent-sessions/` settles R1.

## 2026-10-18 — L98 pilot spend is authorized, with a cap

- **Decision:** the L98 pilot's headless runs need no further approval: the
  user asked for the remaining work to be done ("accomplish it"). Node 04 sets
  a cap (target ≤ 45 headless runs) and states its estimate; node 06 stops at
  the cap.
- **Why:** a `hitl` gate before spend would stall the chain on a question the
  user has already answered.
- **Rejected:** a `hitl` approval node before the pilot run.
- **Promote?:** no.

## 2026-10-18 — Backlog files are written only by reconcile nodes

- **Decision:** child agents never edit `docs/template-workspace-backlog*.html`;
  each wave's reconcile node moves the cards it verified.
- **Why:** two other sessions share this checkout; isolated children merging
  scorecard edits would conflict, and only a verified claim should close a card.
