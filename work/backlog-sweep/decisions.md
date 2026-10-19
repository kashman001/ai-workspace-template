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

## 2026-10-18 — L96: document the usage-limit/watchdog interaction, no code fix

- **Decision:** a paragraph in `docs/context-budget.md` (raise or zero `SESSION_LOOP_KILL_AFTER` per work item) instead of teaching the watchdog to recognise the wait.
- **Why:** whether Claude Code writes to the transcript during the wait is unverified, so there is no signal a test could assert on (`l96-findings.md`).
- **Rejected:** a watchdog change guessed without a real limit-hit transcript.

## 2026-10-18 — L85: test-doc-consistency keeps running in instances

- **Decision:** in an instance, `test-doc-consistency.sh` drops only the `work/plans/` pins and exits 0; the other three suites exit 77.
- **Why:** the card's fix says to skip only the template-work pins for that suite; node 01's Acceptance box 2 ("each exits 77") over-read it.
- **Rejected:** skipping the whole suite — it would hide instance-valid doc checks.
