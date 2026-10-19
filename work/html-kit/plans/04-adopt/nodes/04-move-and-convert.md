---
id: 04-move-and-convert
title: Move kit to docs/kit/; convert docs/setup-guide.html
status: todo
kind: work
wave: 2
blocked_by: [03-reconcile-w1]
check: test -f "$WORKSPACE_ROOT/docs/kit/kit.css" && grep -q 'kit/kit.css' "$WORKSPACE_ROOT/docs/setup-guide.html"
sessions: []
---

## Goal

Move `kit/kit.css`, `kit/kit.js`, `AUTHORING.md`, `DIAGRAMS.md`, `check-links.sh`, `render-check.sh`, `kit-sample.html` from `prototype/` to `docs/kit/` and fix paths inside them (render-check default out-dir, sample's kit path). Convert `docs/setup-guide.html` from `prototype/setup-guide.html` (kit path `kit/`, links re-pointed).

## Acceptance

- [ ] files in `docs/kit/`, internal paths fixed, sample renders
- [ ] `docs/setup-guide.html` converted: greps clean, check-links OK
- [ ] render-check run on it and every shot viewed

## Log
