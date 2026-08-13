<!--
PURPOSE: This is the LEDGER (provenance log). Append-only, newest block on
TOP. Each "# Session Handoff" block records what happened in one session.
Read the TOP block only; older blocks are in handoff-archive.md. Forward
"what to do next" belongs in next-session.md, NOT here.
Convention: docs/work-directory-conventions.md.
-->

# Session Handoff — 2026-08-13 (session 1 close: map complete, gap dispositions settled, rollover at WARN)

Continuation of the 2026-08-12 block below (same session, rolled at WARN).
What shipped since that block:

- `sdlc-map.md` completed: test-plan lifecycle note on the N1⇢N5 edge;
  "Artifacts by node" table (~30 artifacts × key contents × per-artifact
  AI overlay with evidence tiers); Glossary (28 terms, DORA fuller entry);
  gap register now carries settled dispositions.
- Gap dispositions agreed with user (Tier-2 notes in `decisions.md`):
  G1 → new work item `work/feedback-intake/`; G2+G3 merged → new work item
  `work/quality-gates/`; G4/G5/G6/G8 → template-backlog cards;
  G7 → out of scope, deliberately (runbooks + wizard escape hatch).
- Research base: `research-modern-qa.md` (session start, all five threads,
  primary-source citations).

State: none of the successor tasks (scaffolding, backlog cards) started —
deliberately left for a fresh session. Map is user-reviewed through the
gap pass.

Suggested skills next session: `create-work-item` (×2), decision-log for
any scoping forks; backlog edits per CONTEXT.md "Template Backlog" rules
(targeted reads, never load the HTML whole).

# Session Handoff — 2026-08-12 (session 1: research + map structure settled + nodes filled)

Scaffolded the work directory via `create-work-item`. QA research completed
→ `research-modern-qa.md`. Map built at `sdlc-map.md`: graph structure
(8 nodes, feedback edges, mermaid + numbered-list dual view), quality as a
cross-cutting lane, three structural questions settled with the user (N5
node, N8 node, per-node overlay — Tier-2 notes in `decisions.md`), and all
8 per-node entries filled (activities / quality V&V tags / AI-with-evidence-
tier / template-native-vs-toolchain-vs-GAP). Gap register G1–G8 drafted.
Immediate next step: user review of the filled-in nodes and gap register;
then decide which gaps become backlog/work items.
