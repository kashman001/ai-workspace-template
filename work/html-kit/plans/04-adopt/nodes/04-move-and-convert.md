---
id: 04-move-and-convert
title: Move kit to docs/kit/; convert docs/setup-guide.html
status: done
kind: work
wave: 2
blocked_by: [03-reconcile-w1]
check: test -f "$WORKSPACE_ROOT/docs/kit/kit.css" && grep -q 'kit/kit.css' "$WORKSPACE_ROOT/docs/setup-guide.html"
sessions: [10]
---

## Goal

Move `kit/kit.css`, `kit/kit.js`, `AUTHORING.md`, `DIAGRAMS.md`, `check-links.sh`, `render-check.sh`, `kit-sample.html` from `prototype/` to `docs/kit/` and fix paths inside them (render-check default out-dir, sample's kit path). Convert `docs/setup-guide.html` from `prototype/setup-guide.html` (kit path `kit/`, links re-pointed).

## Acceptance

- [x] files in `docs/kit/`, internal paths fixed, sample renders
- [x] `docs/setup-guide.html` converted: greps clean, check-links OK
- [x] render-check run on it and every shot viewed

## Log
- s10 · started, tier standard
- s10 · git mv of 7 files to docs/kit/ (kit.css/kit.js flat in docs/kit); render-check default out-dir now ${TMPDIR:-/tmp}/render-check/<stem> (shots not committed); AUTHORING/DIAGRAMS/sample paths re-pointed; docs/setup-guide.html = prototype with ../../../docs/ stripped (word diff vs old page: content identical). Greps 0/0, check-links OK on both pages, render-check 48 shots (setup-guide 5 figs, sample 7) all viewed via 4 contact sheets: pass.
- s10 · check passed → done
- s10 · 8 prototype/xrt/subagent pages re-pointed at docs/kit/ so they still render; check-links OK on all 8 (transcripts untouched).
