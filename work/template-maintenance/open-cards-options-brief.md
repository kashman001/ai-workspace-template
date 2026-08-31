# Open-Cards Options Brief — the 5 remaining backlog cards (2026-08-31, session 15)

All five open cards (M27, M28, M29, L38, L39) are convention/doc *design*
gaps, not defects. Per the session-15 mission, this brief proposes a shape
per card and names the open questions — **no card should be built until the
user picks a direction.** Card bodies: `docs/template-workspace-backlog.html`
(grep the ID). Source gaps: `work/sdlc-ai-mapping/sdlc-map.md` gap register.

---

## M27 — Testability / failure-mode prompt at design time (gap G4)

**Proposed shape:** a native companion skill (`design-for-testability` or a
checklist section) invoked alongside design work — a short interrogation:
"how will we test this; how does it fail; what's observable when it does."
**Where it lands:** `skills/<name>/SKILL.md` + a pointer from CONTEXT.md's
skills table; referenced next to `grill-with-docs` in the workflow table.
**Constraint:** `grill-with-docs` is *vendored* (Matt Pocock set, refreshed by
`scripts/sync-vendored-skills.sh`) — we cannot edit it without losing the
change on sync, so a wrapper/companion is the viable route.
**Open questions:** (1) skill vs. plain doc checklist? (2) advisory prompt or
a gate (e.g. required section in ADRs)? (3) does it also belong in `to-spec`
output (a "testability" heading in specs)?

## M28 — UAT/beta coordination convention (gap G5)

**Proposed shape:** a lightweight convention doc section — who tests, against
which success criteria (pulled from `work/<effort>/spec.md`), where results
land (`work/<effort>/uat.md` alongside `verification.md`), and how a no-go is
recorded (a Tier-2 decision note).
**Where it lands:** extend `docs/work-directory-conventions.md` (which already
defines the per-effort `verification.md` slot) rather than a new doc; a
`/uat-plan` skill is a possible second step, not the first.
**Open questions:** (1) does the adopter context even have external
testers/beta users, or is "UAT" a second human on the team? (2) convention
only, or also a skill that drafts the UAT plan from the spec? (3) is
recording a no-go a decision note or a spec status change?

## M29 — Postmortem convention (gap G6)

**Proposed shape:** a blameless postmortem template (timeline, contributing
factors, actions — no blame lines) plus a defined landing place. AI drafting
from timelines is [established] per the map's evidence tiers, so the
convention can say "agent drafts, human review."
**Where it lands — the real open choice:** (a) committed `docs/postmortems/`
directory (durable, greppable, feeds graphify); (b) `work/<incident>/` work
items (consistent with existing conventions but pruned over time); or
(c) template + convention paragraph in `docs/operational-knowledge.md`.
**Dependency:** action-item routing should point at the feedback-intake
convention — but `work/feedback-intake/` (G1) is still open, so ship with a
forward pointer or wait?
**Open questions:** (1) which landing place? (2) severity threshold — every
incident or only user-visible ones? (3) block on feedback-intake or not?

## L38 — Dependency upgrades & test-suite health (gap G8)

**Proposed shape:** the card itself flags the overlap: "Overlaps
`work/quality-gates/` flake policy — resolve there or here, not both."
Quality-gates (G2+G3, High severity, already an open work item) owns test
infra, gate policy, and flaky-test policy — suite health belongs there
naturally, and a dependency-upgrade policy (cadence, automation such as
Renovate/Dependabot, review bar for AI-generated upgrade PRs) fits the same
maintenance-cadence doc.
**Recommendation:** route L38 into `work/quality-gates/` scope and resolve
the card as "routed", rather than designing a separate convention here.
**Open questions:** (1) agree to fold into quality-gates? (2) if not, is a
standalone maintenance-cadence section in `docs/operational-knowledge.md`
acceptable?

## L39 — Generic backlog convention (gap G9)

**Proposed shape — two honest postures, pick one:**
(a) **Extract**: turn the template repo's own backlog practice (severity-
scoped IDs, status badges, archive rotation, scorecard) into a shipped
scaffold — e.g. a `create-backlog` skill or a documented pattern + starter
file — that survives instantiation; or
(b) **Declare**: document "bring your own tracker" as the decided posture in
`docs/agents/issue-tracker.md` (which already covers tickets/specs) and close
the card with that decision recorded.
**Cost note:** (a) is real ongoing surface (HTML backlog maintenance rules
are fiddly — sessions already need "grep the ID; never load whole" defenses);
(b) is one paragraph.
**Open questions:** (1) have adopters actually asked for a standing findings
backlog? (2) if extracting, keep the HTML format or simplify to markdown?

---

**Suggested order if the user just says "proceed":** L38 (routing decision,
cheapest), L39 (posture decision), M29, M28, M27 (largest design surface).
But each still needs its open questions answered first.
