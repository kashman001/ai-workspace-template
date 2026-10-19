---
id: 01-kit-fixes
title: Kit owner: code blocks, Mermaid min size, figure layout
status: doing
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

- [ ] `pre > code` styled; a long command line scrolls inside its box at 390 wide (page has no horizontal scroll)
- [ ] Mermaid on `body.doc` renders with readable labels (checked on `prototype/setup-guide.html`)
- [ ] table in `<figure>` not clipped; figcaption aligned with body text
- [ ] new class names (steps, footer, toc, code caption) listed in the Log

## Log
- s5 · started, tier standard
