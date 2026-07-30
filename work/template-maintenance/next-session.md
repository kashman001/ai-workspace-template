> **This file is the LAUNCHER (catch-up prompt).** Forward-only, and REPLACED
> at each rollover: it holds what to do next, still-binding constraints, and
> pointers — never session history. Past-tense provenance lives in `handoff.md`
> (the append-only ledger). Convention: docs/work-directory-conventions.md.

## Mission

Maintain the ai-workspace-template: work backlog items, keep the upstream
skill docs in sync, and finish verifying the newly landed **wayfinder**
integration. Wayfinder (vendored `skills/wayfinder/`, tracker wiring in
`docs/agents/issue-tracker.md`) is committed but has not yet been exercised
end-to-end.

## Read these, in order

1. `work/template-maintenance/handoff.md` — top block only (what just shipped).
2. `docs/template-workspace-backlog.html` — "Maintaining this backlog" + the
   2026-07-30 changelog row (the issue tracker for this effort).
3. Only if working on wayfinder: `skills/wayfinder/SKILL.md` +
   `docs/agents/issue-tracker.md` → "Wayfinding operations".

## Do NOT reload

- The design spec (`docs/superpowers/specs/2026-07-30-wayfinder-integration-design.md`)
  — implemented and verified; load only if re-litigating the design.
- Upstream `mattpocock/skills` inventory — synced at `2ab9580`; nothing new
  released outside `in-progress/`.
- `in-progress/` skill linking (`to-questionnaire`, `wizard`) — user
  explicitly deferred; don't re-raise unprompted.
- `docs/recommended-tooling.md` in full — only the §3 notes changed; the
  handoff block summarizes them.

## State snapshot

- Branch `main`, clean tree, all work committed (`3b86e3c`, `eb3bd4d`,
  `a079b85` + this rollover commit). Nothing running, no open backlog items
  (scorecard 0 open).

## First actions

1. `scripts/context-budget.sh register`
2. Suggested next unit (confirm with user): smoke-test wayfinder — invoke
   `/wayfinder` with a small real effort and verify the map + tickets land
   under `work/<effort>/` per `docs/agents/issue-tracker.md`; record any
   friction as a new backlog finding.
