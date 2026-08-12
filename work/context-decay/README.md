# context-decay

The workspace's **context-budget system**: measure every agent session's live
context usage exactly from disk, warn before the ~150K "dumb zone", and roll
work over via deliberate handoffs instead of automatic compaction. This work
directory carries the project's research, specs, and session state; the
shipped system itself lives in `scripts/context-budget.sh`,
`docs/context-budget.md`, and `skills/session-rollover/SKILL.md`.

- **Governing skill:** `skills/session-rollover/SKILL.md` (rollover workflow);
  reference doc `docs/context-budget.md`.
- **Start here:** `next-session.md` (launcher), then the top block of
  `handoff.md` (ledger). Convention: `docs/work-directory-conventions.md`.
- **Status:** dormant — all backlog findings resolved; remaining items are
  externally gated (see the launcher).

Other files: `context-decay-spec.md` (implemented spec — do not reload),
`decisions.md` (Tier-2 decision notes), `research/` (session-pinning research
with citations). The measurement ledger now lives at
`.context-budget/context-ledger.jsonl` (moved out of this dir, backlog M19),
and the analysis passes were promoted to `docs/archive/`:
`ledger-analysis.md` (last local pass; its "rollover is cheap" finding is
superseded), `ledger-analysis-heavy-deployment-2026-08-11.md` (imported
cross-deployment evidence), `rollover-cost-analysis-2026-08-11.md` (where the
rollover's ~10–20K goes + optimization recommendations), and the design doc
as `context-budget-design.html`.
