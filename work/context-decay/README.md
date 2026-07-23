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

Other files: `context-ledger.jsonl` (measurement ledger, append-only),
`context-decay-spec.md` + `design.html` (implemented spec/design — do not
reload), `ledger-analysis.md` (last analysis pass), `decisions.md` (Tier-2
decision notes), `research/` (session-pinning research with citations).
