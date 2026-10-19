---
id: 02-rule-fixes
title: Four rule fixes in AUTHORING.md/DIAGRAMS.md from RESULTS Session 8
status: done
kind: work
wave: 1
blocked_by: []
sessions: [9]
---

## Goal

Apply the four fixes listed in `prototype/RESULTS.md` → "Rule changes this suggests" to `prototype/AUTHORING.md` / `prototype/DIAGRAMS.md`: no copied coordinates; width guide (~9 units/mono char, ~8.5/default, wrap to two lines); folder trees and inventories are not SVG; checklist hand-back when render-check can't run.

## Acceptance

- [x] all four fixes present in the rule files
- [x] rule greps re-run on `prototype/kit-sample.html`, clean

## Log
- s9 · started, tier standard
- s9 · four fixes in prototype/DIAGRAMS.md (not-a-diagram para, no copied coords, width guide + two-line wrap) and prototype/AUTHORING.md (hand-back when render-check cannot run)
- s9 · kit-sample.html: grep 0, svg-class 0, 1 script, check-links OK (14)
- s9 · done
