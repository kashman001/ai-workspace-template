---
id: 05-sample-page
title: kit-sample.html uses every class; render-checked
status: todo
kind: work
wave: 1
blocked_by: [02-phone-scroll-svg]
check: test -f prototype/kit-sample.html && test -d prototype/shots/s7/sample
sessions: []
---

## Goal

prototype/kit-sample.html: one doc page using every class in AUTHORING.md + DIAGRAMS.md (text roles, tags, points, stats, grid/small, figure-wrapped grid, rows, table, code, steps, toc, footer, div.callout, link list, SVG incl. a wide one, a short Mermaid). It is the regression page to re-check whenever the kit changes.

## Acceptance

Rule greps print 0; check-links passes; render-check to prototype/shots/s7/sample; every class in the rules appears on the page (grep each).

## Log
