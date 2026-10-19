# Summary — copilot

## Check results
1. Forbidden-pattern grep: `0` (pass).
2. Non-`class="diagram"` svg grep: `0` (pass).
3. `check-links.sh`: OK, 24 href/src checked (pass).
4. `render-check.sh`: **not completed.** Headless Chrome aborted (`Abort trap: 6`),
   and launching Chrome directly was refused by the sandbox (no interactive approval).
   No PNGs were written and none were viewed. **The page is not done until someone who can
   run Chrome runs `render-check.sh` and looks at the shots.** Figures 2 and 3 are the ones
   at risk (SVG coordinates were sized by the DIAGRAMS.md character-width rule, not seen).

## Fixed after a check
Nothing: checks 1–3 passed on the first run. Nothing could be fixed from shots.

## Unclear rules and what I chose
- Figures 1, 4 and 5 were SVG inventories (a folder layout and two-column global/local
  lists). DIAGRAMS.md says a folder tree is a code block and a two-column inventory is a
  list or card grid, so: Fig 1 is a `<pre><code>` tree in a `<figure>`; Figs 4 and 5 are
  `<figure>` + `.grid` of two cards (`warn` = GLOBAL, `info` = LOCAL / per-repo). The
  "feeds" arrow of Fig 4 became a `.meta` line on each card. Figs 2 and 3 stay SVG.
- Fig 3 (five steps) won't fit one row in a ~600-wide viewBox, so it wraps 3 + 2, with a
  curved arrow from step 03 to step 04.
- Tag tones: GLOBAL = warn, LOCAL = info (as in the source's amber/cyan); Yes = ok,
  No = warn.
- The header pill row became grey `.tag` spans in a `<p>`; the hero `.badge` became `.eyebrow`.
- The source's "Deeper reference" and footer link lists became plain `<ul>`s, each link with
  a few words on what it covers. I wrote those descriptions; they are not in the source.
- Step 5's single long paragraph was split into three `<p>`s (same text).
- Step 4's bullet list sits inside the `<li>` of `ol.steps` as a plain `<ul>` with `<b>` lead-ins.
- The "ai" callout variant has no kit equivalent; both callouts are plain `div.callout`.
- Footer is a `<ul>` of links, which the rules don't explicitly allow.

## Elements/classes used that are not in the rule files
None beyond the sheet. Footer contains a `<ul>`; steps contain a `<ul>` and several `<p>`s.

## Round 2

I opened all 20 PNGs (5 figures × 1280/390 × light/dark) after the shots were supplied; `render-check.sh` was not run by me.

**What I saw**
- Fig 2 (SVG): three file boxes, arrows into the CONTEXT.md box, "symlink" label. Readable and uncut in both themes and at both widths. No change.
- Fig 3 (SVG): 3 + 2 wrapped steps with the curved 03 → 04 arrow, step 05 highlighted. Nothing cut or overlapping at either width; text is small at 390 but legible. No change.
- Fig 4 and Fig 5 (card grids): two columns at 1280, stacked at 390; both themes fine, text wraps cleanly, tone borders show. No change to the cards.
- Fig 1 (code tree): **cut off at 1280** — the comment column started at col 44, so "(read first)" and "registries)" were clipped by the block edge. At 390 the block scrolls, so the comments are off-screen until scrolled, and the last line also ran past the edge.

**What I changed**
- Fig 1: moved the comment column to col 36 and split the final line into `.claude/ · .gemini/ · .opencode/` and `opencode.json` (same comment on both), so the longest line is about 80 characters and fits the 1280 block. Same content, no new elements.

**Still open**
- The 390 Fig 4 PNGs (light and dark) are about 490px wide with an empty strip on the right, while the cards sit inside 390. It looks like something makes the page wider than the viewport there, but I could not find the cause from the shots or the markup. I changed nothing for it.
- At 390 Fig 1 still scrolls sideways inside its block (80 characters cannot fit); I accepted that for a code block.
- The Fig 1 edit has not been re-rendered, so it is unverified by shot.

**Re-run checks (not render-check.sh)**
1. Forbidden-pattern grep: `0`.
2. Non-diagram svg grep: `0`.
3. `check-links.sh`: OK, 24 href/src checked.
