<!--
PURPOSE: This is the LEDGER (provenance log). Append-only, newest block on
TOP. Each "# Session Handoff" block records what happened in one session.
Read the TOP block only; older blocks are in handoff-archive.md. Forward
"what to do next" belongs in next-session.md, NOT here.
Convention: docs/work-directory-conventions.md.
-->

# Session Handoff — 2026-08-13 (session 11: item reopened — diagram evaluation, drafts, three-zoom interactive map; PR #18 open)

Rollover at context-budget WARN (~146K). User-driven session; three units:

- **Diagram evaluation (analysis only, docs untouched):** user finds the
  deck's diagrams far clearer than the docs' 19-edge mermaid View 2.
  Verdict: incorporate as *mermaid recreations* (only format rendering on
  GitHub + artifacts); the edge table already carries the full census, so
  curation loses nothing. Full trade-off analysis is in this session's
  conversation; the durable decision is in `decisions.md` (last note).
- **Drafts published** for user judgment (loop, curated graph, demoted
  label-free full census + captions + placement plan):
  https://claude.ai/code/artifact/abd83fc6-eaa0-4b57-97fd-b43b09bfeabc
  Source only in job-tmp — recreate from artifact if needed.
  **User has NOT yet approved editing the diagrams into the two maps.**
- **Three-zoom interactive map built & shipped** (user idea): semantic
  zoom — L1 steady-state loop, L2 full graph on radial geometry (hover
  edge labels), L3 all 30 View-3 artifacts as tier-tagged chips with
  detail cards. Committed `slides/sdlc-three-zooms.html` on branch
  `worktree-sdlc-three-zooms-html`, **PR #18 open, unmerged**.
  Artifact: https://claude.ai/code/artifact/181a3593-985f-427e-a889-0fb71776ff7d
  Zoom-3 chip layout is unverified visually — user may report overlaps.

Learnings:
- GitHub strips inline SVG in markdown; artifacts are self-contained (no
  repo-file refs; data-URI images also fail on GitHub) → mermaid is the
  only both-contexts diagram format. (Also in decisions.md.)
- This session ran as auxiliary (another session held the work-item lock
  at start); no collisions observed.

Suggested skills next session: none required; `doc-review` only if the
map edits land and the user wants them reviewed.

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

