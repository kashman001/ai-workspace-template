# Architecture Decision Records

Committed, permanent record of the **why** behind decisions with lasting weight —
the reasoning, the alternatives rejected, and the consequences. Code shows *what*
is there; an ADR captures *how it got there* so a future agent (or human) doesn't
have to reverse-engineer intent from `git blame`.

This is **Tier 3** of the workspace's decision-capture scheme. Most reasoning is
captured cheaply in `work/<project-name>/decisions.md` (Tier 2); only the
decisions worth keeping get **promoted** here. See `skills/decision-log/SKILL.md` for
the full three-tier scheme and the capture/promote workflow.

## When an ADR (vs. a decision note)

Write an ADR only when all three legs of the **AND test** hold (adopted from the
upstream `domain-modeling` skill):

- **hard to reverse** — undoing it later is costly: it shapes architecture, a public
  contract, or a cross-cutting convention, **and**
- **surprising** — someone would plausibly ask "why is it this way?" in six months;
  it isn't the obvious default, **and**
- **a real trade-off** — an alternative was rejected for a reason that still matters
  (if there was no fork, there's no decision).

If any leg is missing, leave it as a Tier-2 note in `work/…/decisions.md`. "Every
decision gets an ADR" is the scheme that dies in a month — don't.

## Where it lives (scope)

`docs/adr/` is the **workspace-scope** home — the default, and the right place for any
decision that spans more than one repo or governs the workspace itself (skills,
conventions, tooling). If this workspace grows product repos under `repos/` and a
decision is contained entirely within one of them, it may instead live in that repo's
own `repos/<repo>/docs/adr/`, numbered in its own independent sequence. When unsure,
keep it here.

## Conventions

- **Filename:** `NNNN-kebab-slug.md`, zero-padded 4-digit sequence (`0001-…`, `0002-…`).
  Numbers are stable and never reused, even after an ADR is superseded.
- **Template:** copy `0000-template.md`. It's `0000` so it sorts first and is never a
  real record.
- **Status:** `proposed` → `accepted` → (`deprecated` | `superseded by ADR-NNNN`).
  Never delete an ADR; supersede it and link forward.
- **Provenance block** (bottom of each ADR) is what makes the record a *graph node*:
  it links back to the Tier-2 note it was promoted from, the commits that implemented
  it, and any ADR it supersedes. graphify reads these edges — after adding an ADR run
  `graphify update .` (AST-only, no API cost) so `graphify query "why …"` can walk
  `code → commit → ADR → alternatives-rejected`.

## Index

<!-- Add a line per ADR: -->
<!-- - [ADR-NNNN: <title>](NNNN-slug.md) — accepted YYYY-MM-DD -->

- [ADR-0001: Capture decision provenance in three tiers, promoting notes to ADRs](0001-three-tier-decision-capture.md) — accepted 2026-07-14
- [ADR-0002: Load tools lean-by-default — CLI-first, MCP split into core and opt-in fragments](0002-lean-by-default-tool-loading.md) — accepted 2026-08-01
- [ADR-0003: Automate the rollover→relaunch handoff with a workspace script, not vendor prompt mechanisms](0003-automate-rollover-relaunch.md) — accepted 2026-08-05
- [ADR-0004: Operate rollover automation under a multi-session model — session-keyed budget state, per-project locks, hybrid trigger](0004-multi-session-rollover-model.md) — accepted 2026-08-05
- [ADR-0005: Session roles with the lock as primary marker, and a parent/child session registry](0005-session-roles-and-child-registry.md) — accepted 2026-08-06
- [ADR-0006: Key coordination state to repository identity, never to a checkout](0006-repository-keyed-coordination-state.md) — accepted 2026-08-06
- [ADR-0007: Make `.session-seq` (via the bootstrap prompt) the single source of session numbers](0007-session-number-single-source.md) — accepted 2026-08-06
