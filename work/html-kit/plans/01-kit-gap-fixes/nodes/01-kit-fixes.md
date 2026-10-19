---
id: 01-kit-fixes
title: Kit owner: code blocks, Mermaid min size, figure layout
status: done
kind: work
wave: 1
blocked_by: []
sessions: [5]
---

## Goal

Sole owner of `prototype/kit/kit.css` and `kit.js` this wave. Fix:
(1) code blocks — `<pre><code>` styled (monospace, background, padding,
horizontal scroll, no page overflow at 390 wide, dark-safe), plus an optional
`<figure>` caption for a code block; (2) Mermaid renders tiny on doc pages —
give doc-page Mermaid a minimum readable size (text at least ~14px rendered)
without blowing up small diagrams; (3) a `<table>` inside `<figure>` is
clipped on the left (doc figure bleed) and figcaptions sit offset from the body
text column — align both with the text column. Also add whatever small
classes AUTHORING.md will need for: a steps list whose steps hold code, a
page footer, a table of contents (coordinate via names listed in your Log
line; node 03 documents them).

## Acceptance

- [x] `pre > code` styled; a long command line scrolls inside its box at 390 wide (page has no horizontal scroll)
- [x] Mermaid on `body.doc` renders with readable labels (checked on `prototype/setup-guide.html`)
- [x] table in `<figure>` not clipped; figcaption aligned with body text
- [x] new class names (steps, footer, toc, code caption) listed in the Log

## Log
- s5 · started, tier standard
- s5-a · code blocks: `pre:not(.mermaid)` + `pre > code` styled in prototype/kit/kit.css (mono, raised bg, border, padding, overflow-x:auto); doc main/section/figure grids now `minmax(0,1fr)` so long lines scroll in their box. Probed at a true 390px viewport (iframe): scrollWidth == clientWidth (390), no page scroll; light + dark screenshots seen.
- s5-a · Mermaid on body.doc: prototype/kit/kit.js sets each rendered svg `min-width` = 0.875 × natural width (16px font → ≥14px labels) and the `pre.mermaid` box scrolls (kit.css); setup-guide.html probe: labels 16px at 1280, ≥14px at 390 (svg 447/511 and 722/825 px, box scrolls).
- s5-a · figure bleed: only `figure > :is(svg, pre.mermaid)` and `.table-wrap` bleed now (not the figure), so a table in a figure is bled once (no left clip) and figcaption sits in the text column; checked on a scratch test page at 1280 and 390, and setup-guide figcaptions align at 1280.
- s5-a · edited prototype/setup-guide.html minimally: its 6 fake code blocks (`<p><code>..<br>`) are now real `<pre><code>` (for testing). Deck where-ai-actually-helps.html slides 4 and backup 2 re-shot: unchanged.
- s5-a · new names for AUTHORING.md (node 03): `<nav class="toc"><ol><li><a href="#id">` (contents, 2 columns, 01. markers); `<ol class="steps"><li><h3>…</h3><p>…</p><pre><code>…</code></pre></li>` (numbered steps holding code); `<footer>` as a direct child of body.doc after </main> (page footer, no class); code caption = no class: `<figure><pre><code>…</code></pre><figcaption>`.
- s5-a · on disk: prototype/kit/kit.css (14468 B), prototype/kit/kit.js (5204 B), prototype/setup-guide.html (code blocks converted); not on disk: no commit, no AUTHORING.md changes (node 03), scratch test page only in session scratchpad.
- s5 · done
