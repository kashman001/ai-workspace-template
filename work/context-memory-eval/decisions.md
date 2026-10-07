# Decisions — context-memory-eval

Tier-2 decision notes (newest on top). Convention: `skills/decision-log/SKILL.md`.

## 2026-10-07 — Accept recommendations 1–4 and 6; defer 5 (async consolidation loop)

- **Decision:** carry recommendations 1–4 and 6 as backlog cards L49, L50,
  M43, L51, D5, built in `work/context-memory-hardening/`. Recommendation 5
  (a SessionEnd-triggered headless consolidation child) is not carried.
- **Why:** the user's pick. Recommendation 5 is the largest and riskiest
  item: it needs coverage across runtimes, and it writes to shared files
  without anyone watching. The other four are cheap doc and script changes.
- **Rejected alternative:** card recommendation 5 now as an exploratory spike.
  It's left open. It can come back as a new card if consolidation cost
  matters after L50 makes cache and context costs measurable.
