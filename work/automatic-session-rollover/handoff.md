<!--
PURPOSE: This is the LEDGER (provenance log). Append-only, newest block on
TOP. Each "# Session Handoff" block records what happened in one session.
Read the TOP block only; older blocks are in handoff-archive.md. Forward
"what to do next" belongs in next-session.md, NOT here.
Convention: docs/work-directory-conventions.md.
-->


# Session Handoff — 2026-08-06 (session 13: scenario catalog + parent positions + learnings rules; WARN rollover at ~125K)

**What shipped (committed on `main`, pushed):**

- **`967b3d2` — scenario catalog S11–S54:** new `rollover-scenarios.md`
  (authoritative; nine dimension groups, each scenario with pass criteria),
  mirrored as HTML §7. Answered the user's open question: five missing
  dimensions added (concurrency/contention, vendor heterogeneity,
  human-in-the-loop policy, observability/auditability,
  evolution/compatibility); cost folds into performance.
- **`5d2f75d` — root vs intermediate parent positions** (user review finding):
  HTML §2.2 + research-md §3 subsection — parent *role* is
  position-invariant; the node's own lifecycle differs by position (delta
  table: manager, rollover path, measurement, escalation, authority, lock,
  recovery owner). No parent-type field — `depth`/`parent_session_id`
  suffice. Scenarios S53 (BLOCKED bubbles L2→L1→root) and S54 (intermediate
  parent rolls itself: drain own children, then yield) added; HTML §2.3–2.9
  renumbered.
- **`536fd9c` — learnings-capture rules** (user retro discussion): rollover
  skill Reflect step now says capture at incident time + park uncertain
  observations as `Learnings:` ledger lines + second-strike promotion;
  checkpoint skill points the human retro at checkpoint/successor-start.
  Backlog changelog row added. Deliberately no learnings.md, no auto-retro.
- This rollover commit: decisions.md notes (catalog placement; parent
  positions as node position, not type enum), ledger restructure.

**Learnings:** *(parked; promote on second strike)*
- Blind sed renumbering of doc section numbers also matched CSS (`2.6em`)
  and version strings (`0.142.4`) — pattern-guard (`§`, `secno">`, TOC text)
  and a pre-grep of all `2.x` occurrences avoided corruption.
- A ~15-line python `html.parser` tag-balance + id-dedup + secno-order check
  before committing hand-edited HTML is cheap, reusable pre-commit insurance.

**Rollover:** WARN fired at 122K mid-edit; finished the parent-positions and
learnings units cleanly; user then asked to close the learnings thread and
roll over. First rollover of this work item triggered below STOP.

# Session Handoff — 2026-08-06 (session 12: HTML review rendition shipped; STOP rollover at 155K mid-turn)

**What shipped (committed on `main`, pushed):**

- **`subagent-rollover-research.html` — `d93daea`:** standalone, self-contained
  HTML review rendition of the research note, restructured per user direction:
  problem (with the stats evidence) → the model (§2: roles/policy, verb,
  protocol, files, lock hierarchy, state machines, drain mode, invariants
  I1–I8 — with 5 hand-authored inline-SVG diagrams: system model, resume-vs-
  successor, lock hierarchy, child lifecycle, parent budget modes) → machinery
  already in place (§3) → findings (§4) → proposal R1–R8 + inventory (§5) →
  evaluation model (§6) → next steps. Light/dark via CSS tokens; no external
  deps. Diagrams visually verified in Chrome (3 label-overlap fixes applied
  pre-commit). The markdown note remains the raw record (footer says so).
- Tier-2 decision note (HTML-vs-Artifact) in `decisions.md`; claude-in-chrome
  `file://` gotcha routed to `docs/operational-knowledge.md`.

**Mid-turn user request (binding, NOT started):** enumerate rollover
*scenarios* — mainline functional plus corner/edge cases for resilience,
recoverability, and performance — to (a) keep in mind while working through
the doc and (b) drive evaluation, *before* any implementation. User asked
whether their dimension list misses anything (candidates to consider:
concurrency/contention incl. human attach during drain, observability/
auditability, cost/token-economy, schema evolution of records, degradation on
opaque runtimes, human-in-the-loop policy edges). Seed material: S1–S10 +
P1–P5 + §13 fault model already in the research doc — the new catalog should
extend, not duplicate, those.

**Rollover:** WARN fired mid-diagram-verification (134K), STOP (155K) two
edits later; wrapped the atomic step (commit `d93daea` + this ledger) and
rolled. Second consecutive session terminated on schedule by its own subject
matter.
