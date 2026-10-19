---
id: 03-authoring-draft
title: AUTHORING.md: small gaps, render-check step, steer to SVG
status: done
kind: work
wave: 1
blocked_by: []
sessions: [5]
---

## Goal

Edit `prototype/AUTHORING.md` only. Add: caption for a non-diagram figure
(table/code in `<figure>`), code blocks (`<pre><code>`), steps that hold code,
footer, table of contents, relative links from a page that moved; a
render-check step in "Check before handing back" (run
`render-check.sh`, look at every shot: labels readable, nothing clipped or
overlapping, sized in proportion); and steer harder toward hand-drawn SVG when
readability is at stake (Mermaid only for a short chain that stays readable).
Class names for steps/footer/toc/code-caption come from node 01's Log; write
your draft with placeholder names `steps`, `toc`, `<footer>` and the
reconcile aligns them. Keep the file short — it is read by every authoring
agent.

## Acceptance

- [x] every gap above has a short entry with an example
- [x] render-check step in the checklist
- [x] SVG steer sharpened
- [x] file size reported in the Log (bytes)

## Log
- s5 · started, tier standard
- s5-c · added entries with examples to work/html-kit/prototype/AUTHORING.md: figure caption for table/code, code block (`<pre><code>`), steps holding code (`<ol class="steps">`), contents (`<nav class="toc">` + section ids), `<footer>` after `<main>` in the skeleton, relative links from a moved page
- s5-c · checklist in work/html-kit/prototype/AUTHORING.md gains the render-check step (`render-check.sh page.html`, 4 shots/figure, 1280/390 light/dark, readable/unclipped/proportional); "Choosing" now defaults to hand-drawn SVG, Mermaid only for a short chain seen readable
- s5-c · on disk: work/html-kit/prototype/AUTHORING.md at 8,661 B (was 6,786). Not on disk: class-name alignment with node 01 (placeholders `steps`, `toc`, `<footer>`, `<pre><code>` left for reconcile); render-check.sh invocation unverified against node 02's script; nothing committed
- s5 · done
