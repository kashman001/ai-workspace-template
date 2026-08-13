# sdlc-ai-mapping — session 12 launcher

> **This file is the LAUNCHER** (forward-looking, replaced each rollover).
> Provenance: `handoff.md` top block (session 11).

## Mission

Close out the diagram work: get PR #18 (three-zoom interactive map)
merged, and get the user's decision on editing the drafted mermaid
diagrams into the two map documents — then execute it if approved.

## Read these, in order

1. `handoff.md` — top block only (session 11: what shipped, what's open).
2. `decisions.md` — last note (mermaid-recreation decision + rejected
   alternatives). Only if touching the diagrams.
3. `sdlc-map-standalone.md` View 2 (lines ~97–200) — only when actually
   editing; `sdlc-map.md` View 2 is line-for-line identical.

## Do NOT reload

- The session-11 trade-off analysis — settled; conclusion is in
  `decisions.md`. Re-litigate only with a fresh reason.
- `research-modern-qa.md`, review history, round-2 Minors — settled
  (user won't-do); unchanged from prior sessions.
- `handoff-archive.md` — sessions 1–10 provenance.
- The deck HTML (`slides/where-ai-actually-helps.html`) — only its two
  SVG figures matter for diagram work, and the mermaid drafts already
  encode them.

## State snapshot

- **PR #18 open, unmerged**: branch `worktree-sdlc-three-zooms-html`
  (adds `slides/sdlc-three-zooms.html` + this rollover bookkeeping).
  Merging is the user's call.
- Published artifacts (republish only **with the URL as `url`**):
  - three-zoom map: https://claude.ai/code/artifact/181a3593-985f-427e-a889-0fb71776ff7d
  - mermaid drafts: https://claude.ai/code/artifact/abd83fc6-eaa0-4b57-97fd-b43b09bfeabc
  - standalone map: https://claude.ai/code/artifact/f86be94e-2362-4342-bddf-0105f395a204
  - deck v3: https://claude.ai/code/artifact/6989c82f-fec3-4302-b757-506a1d225d5f
- Draft mermaid source + three-zoom HTML source also live in job
  7a776e24's tmp dir (ephemeral; committed copy of the HTML is in PR #18).
- Open user decisions: (1) merge PR #18; (2) approve/decline the mermaid
  diagram edit to both maps (incl. whether to keep the demoted full-census
  diagram — recommended: yes, label-free, beside the edge table);
  (3) any zoom-3 chip-overlap fixes the user reports.

## First actions

1. `scripts/context-budget.sh register --project sdlc-ai-mapping`
2. Read `handoff.md` top block.
3. Ask the user for the pending decisions above (or take direction);
   if the map edit is approved: apply the drafts to both View 2 sections
   identically, keep the edge table untouched, republish the standalone
   artifact with its URL, and open a PR.
