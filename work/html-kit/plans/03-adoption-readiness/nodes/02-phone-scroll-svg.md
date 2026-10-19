---
id: 02-phone-scroll-svg
title: Doc pages: wide SVG keeps a readable min size and scrolls on phones
status: done
kind: work
wave: 1
blocked_by: [01-trim-rules]
check: grep -q 'svg.diagram.*min-width' prototype/kit/kit.css
sessions: [7]
---

## Goal

On body.doc, an SVG whose viewBox is wider than ~600 keeps a minimum width (labels ≥ ~12px on a 390 phone) and scrolls sideways in its figure box, like doc Mermaid already does. Decks unchanged.

## Acceptance

kit.css rule (svg.diagram min-width / figure overflow) plus one line in DIAGRAMS.md. A 900-wide test SVG render-checked at 390: readable, scrolls, no page-level horizontal scroll.

## Log
- s7 · started, tier standard
- s7 · check passed → done
