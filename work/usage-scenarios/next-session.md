# usage-scenarios — MAINTENANCE MODE (no next session planned)

> **This file is the LAUNCHER.** The work item's mission is complete
> (2026-08-09); there is no queued work. This note exists so a future
> session that lands here knows what the directory is for and what could
> reactivate it. History: `handoff.md` (ledger, top block).

## If you're here to update the catalog

`scenarios.md` §3 is the canonical external-scenario catalog — committed
docs link into it, so keep it accurate when the template's workflows
change. Edit with targeted reads; no launcher/ledger ceremony needed for
small catalog corrections (a `Decision:` commit trailer suffices).

## Deferred-by-design residuals (build only when the trigger is real)

- **Gap 4 vault tooling** — trigger: a second (shared) service exists.
  The interface is already documented in `docs/service-access.md`
  (team-vault fetch/bootstrap/rotation).
- **Gap 1 phases 2–3** (shared liveness ADR, collision-proof numbering,
  team-workspace doc) — trigger: a second person joins. Breakage points:
  `docs/workspace-structure.md` → "Before You Add a Teammate".

Reactivating either: start a fresh ledger block in `handoff.md` and
replace this launcher with a real one.

## Still-binding constraints

- Simplicity guardrails (user, 2026-08-08): prefer documenting over
  building; no speculative machinery.
- The E-catalog (scenarios.md §3) is canonical; the retired HTML in
  `docs/archive/` must never be resurrected.
- Nine test suites must stay green; `test-template-instantiation.sh`
  clones COMMITTED state — commit before running it.
