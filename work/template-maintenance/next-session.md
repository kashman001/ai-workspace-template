# Next Session — template-maintenance (session 13)

## Mission

Implement the approved exit-UX changes (session-end handling) exactly as
specified in `work/template-maintenance/exit-ux-plan.md`, test-first: (1)
lineage-gate diagnosis + auto-heal in `scripts/launch-next-session.sh`,
(2) notify-on-quit in `scripts/session-loop.sh`, (3) "two doors" docs.
The design is settled and user-approved — do not re-litigate it; build it.

## Read these, in order

1. `work/template-maintenance/exit-ux-plan.md` — the whole spec: change
   details, verified line anchors, test plan, gotchas. Sufficient on its own.
2. `scripts/launch-next-session.sh:295-318` (gate) and
   `scripts/tests/test-launch-next-session.sh:280-346` (T23 block) — only
   when the corresponding slice starts.
3. `scripts/session-loop.sh:290-305` + `scripts/tests/test-session-loop.sh`
   harness (top ~100 lines) — only at the notify-on-quit slice.

## Do NOT reload

- The scenario analysis conversation — its output IS exit-ux-plan.md.
- `docs/context-budget.md` / `skills/session-rollover/SKILL.md` wholesale —
  plan carries the needed excerpts; doc edits are targeted.
- Rejected approaches (SessionEnd warnings, forced rollover, statusline
  indicator): settled, see decisions.md 2026-08-31 entry.

## State snapshot

- main = d42bab7 pushed; only this rollover's bookkeeping commit on top.
- No worktrees for this effort; suites last known green (launcher 207/0,
  session-loop 68/68).
- Backlog card NOT yet filed — file one in
  `docs/template-workspace-backlog.html` when delivering (per CLAUDE.md
  "Template Backlog"; targeted edits, grep the ID scheme first).

## First actions

1. `scripts/context-budget.sh register --project template-maintenance`
2. Consider a worktree for the implementation (prior sessions' pattern:
   `tm-s13-exitux`); user's checkout should stay clean.
3. Work the plan's slices in order, red→green each:
   T24 heal tests → gate heal → evidence collection → T23e-j rework →
   git-evidence isolated test → session-loop N-series → docs → backlog card.
4. Run both suites + `scripts/check-workspace-structure.sh`; commit per
   convention (`Fix <card>: …` + Decision trailer), push, update backlog.
