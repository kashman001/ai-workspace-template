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

Write an ADR when the decision:

- shapes architecture, a public contract, or a cross-cutting convention, **and**
- had a real alternative you rejected (if there was no fork, there's no decision), **and**
- someone would plausibly ask "why is it this way?" in six months.

Otherwise leave it as a Tier-2 note in `work/…/decisions.md`. "Every decision gets an
ADR" is the scheme that dies in a month — don't.

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
