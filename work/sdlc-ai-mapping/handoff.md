<!--
PURPOSE: This is the LEDGER (provenance log). Append-only, newest block on
TOP. Each "# Session Handoff" block records what happened in one session.
Read the TOP block only; older blocks are in handoff-archive.md. Forward
"what to do next" belongs in next-session.md, NOT here.
Convention: docs/work-directory-conventions.md.
-->

# Session Handoff — 2026-08-13 (session 12: mermaid diagrams into both maps, three-zoom fixes; merged via PR #19)

Rollover at context-budget STOP (~152K). Ran as auxiliary (another session
held the work-item lock). User decisions taken this session: apply the
mermaid drafts (keeping the demoted full census) and have the agent
review zoom 3 for overlaps. All executed:

- **PR #18 was already merged** at session start (`4193f89` on main).
- **View 2 diagram edits applied to both maps** (identical): steady-state
  loop + curated 4-edge graph replace the 19-edge mermaid; label-free
  full-census diagram sits after the edge table; edge table untouched.
  Commit `0c40da1`.
- **Standalone artifact republished** in place (f86be94e, label
  `view2-mermaid-diagrams`).
- **Zoom-3 review: NO overlaps** — measured programmatically on the
  rendered page (0 chip-chip, 0 chip-node, all chips in viewBox). Two
  real defects found and fixed instead (commit `10d7875`): missing
  `<meta charset>` (mojibake when served standalone) and the one-shot
  rAF chip layout (chips pile at origin if the load-time frame is
  deferred; layout now also runs on first entry to zoom 3). Verified in
  an rAF-dead tab. Three-zoom artifact republished (181a3593, label
  `chip-layout-guard`). NOTE: that artifact is link-shared and the share
  pin still points at the previous version — the user must move the pin
  for viewers to see the fix.
- All of the above **merged to main via PR #19** (`64de5fe`), on the
  user's instruction, from branch `worktree-sdlc-map-mermaid-diagrams`.

Learnings:
- Artifact republish from a new session requires WebFetch of the URL
  first ("hasn't viewed the latest version"); owned-artifact WebFetch
  dumps full raw HTML (memory: webfetch-recovers-artifact-source).
- Extension-driven Chrome tabs never fire requestAnimationFrame — pages
  relying on a load-time rAF render unpositioned there; the fix doubles
  as real-world prerender/hidden-tab hardening.

Suggested skills next session: `doc-review` if the user wants the edited
maps reviewed; otherwise none — PR merged, item can close.

