---
id: 02-render-check-script
title: Render-check script: screenshot every figure at 1280/390, light/dark
status: doing
kind: work
wave: 1
blocked_by: []
sessions: [5]
---

## Goal

Write `prototype/render-check.sh <page.html> [out-dir]`: headless Chrome
(`/Applications/Google Chrome.app`), for each `figure` (and each
`svg.diagram` / `pre.mermaid` outside a figure) on the page, a screenshot at
1280 and 390 wide, light and dark, reduced motion. Flags from `handoff.md`
s3: `--blink-settings=preferredColorScheme=1` for light (default renders dark
on this Mac), `--force-prefers-reduced-motion`. No Pillow; use `sips` if
resizing. Approach is free — e.g. a temp copy of the page that hides everything but
one figure, shot with Chrome `--screenshot`, or a full-page shot cropped
with `sips`. For
decks, one screenshot per slide holding a figure. Output file names say page,
figure index, width, theme.

## Acceptance

- [ ] script exists, runs on `prototype/setup-guide.html` and `prototype/where-ai-actually-helps.html`
- [ ] each run writes 4 shots per figure (1280/390 × light/dark), names list them
- [ ] dark and light shots actually differ (checked by eye on one figure)
- [ ] usage documented in a header comment

## Log
- s5 · started, tier standard
