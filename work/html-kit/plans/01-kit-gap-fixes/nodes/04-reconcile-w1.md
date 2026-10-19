---
id: 04-reconcile-w1
title: Join wave 1
status: done
kind: reconcile
wave: 1
blocked_by: [01-kit-fixes, 02-render-check-script, 03-authoring-draft, 02a-render-check-true-390]
sessions: [5]
---

## Goal

Join wave 1: verify kit fixes, script and AUTHORING.md on disk; align class names between kit and AUTHORING.md.

## Acceptance

- [x] verified on disk
- [x] decisions recorded
- [x] replan applied, `check` silent

## Log
- s5 · verified on disk: kit.css 14,468 B / kit.js 5,204 B; AUTHORING.md 8,749 B after aligning toc (`<ol>`) and steps (`<h3>` per step) with the kit CSS and naming where render-check.sh sits; render-check.sh run on setup-guide.html; probe confirmed no horizontal page scroll at real 390 (scrollWidth = clientWidth); table-in-figure unclipped and caption aligned (viewed); 390 shots viewed after the 02a fix. Finding for wave 2: setup-guide fig1 and fig2 Mermaid scroll sideways at 390, so part of each diagram is cut off in the shot. Decision note: render check via iframe. Commands: wc -c, render-check.sh, headless Chrome probe, plan.sh check.
- s5 · started, tier frontier
- s5 · done
