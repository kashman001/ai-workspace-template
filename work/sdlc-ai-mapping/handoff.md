<!--
PURPOSE: This is the LEDGER (provenance log). Append-only, newest block on
TOP. Each "# Session Handoff" block records what happened in one session.
Read the TOP block only; older blocks are in handoff-archive.md. Forward
"what to do next" belongs in next-session.md, NOT here.
Convention: docs/work-directory-conventions.md.
-->

# Session Handoff — 2026-08-13 (session 10 rollover close: everything merged via PR #16, item back to CLOSED)

Rollover at context-budget WARN (~143K). Closing state:

- All session-10 work is on main via **PR #16** (merge `90d32d3`):
  `sdlc-map-standalone.md`, three-view reframe of both maps, README/
  ledger/launcher updates. Local main == origin/main, tree clean apart
  from this rollover bookkeeping.
- The `b1eebdc` leftover flagged in the block below **resolved itself**:
  a concurrent session merged the s9-close branch (landed alongside the
  new `doc-review` skill, PRs #14/#15) — no worktree cleanup pending.
- Standalone-map artifact for the AI-in-SDLC discussion:
  https://claude.ai/code/artifact/f86be94e-2362-4342-bddf-0105f395a204
- Item returns to CLOSED — no follow-on work queued here; the discussion
  can continue any time from the artifact + `sdlc-map-standalone.md`.

Suggested skills next session: none required (item closed); `doc-review`
if the user wants the standalone map formally reviewed.

# Session Handoff — 2026-08-13 (session 10: item briefly reopened — standalone map built, published, both maps reframed to three views)

Interactive session, user-driven. Shipped:

- **`sdlc-map-standalone.md` (new):** workspace-independent version of the
  map for discussing AI in the SDLC outside this workspace — template
  overlay, gap register, and template glossary terms stripped; evidence
  sources (DORA, TestGen-LLM, OSS-Fuzz) named inline so tiers stand alone.
- **Both maps reframed to three views** (user decision): legend hoisted to
  the top, "Two views" → "Three views", View 1 renamed "the phases", the
  artifacts appendix promoted to View 3 right after the graph, all
  per-node "Appendix → Nx rows" pointers → "View 3 → Nx rows".
  `sdlc-map.md` keeps all template content unchanged, just reordered.
- **Standalone published as a NEW artifact** (separate from the deck):
  https://claude.ai/code/artifact/f86be94e-2362-4342-bddf-0105f395a204
- Consistency-checked both docs (no stale refs, equal row/pointer counts,
  companions nested under View 2 in both). README files list updated.

Leftover from before this session: the s9-close worktree still holds
unmerged commit `b1eebdc` (launcher cleanup note) — unrelated to this
session's changes.

