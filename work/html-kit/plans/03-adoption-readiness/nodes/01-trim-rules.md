---
id: 01-trim-rules
title: Split AUTHORING.md into a core + DIAGRAMS.md; measure tokens
status: todo
kind: work
wave: 1
blocked_by: []
check: test -f prototype/DIAGRAMS.md
sessions: []
---

## Goal

Cut the up-front rules cost. AUTHORING.md keeps skeleton, hard rules, text roles, components, checklist; hand-drawn SVG + Mermaid + choosing + render-check detail move to prototype/DIAGRAMS.md, read only when a page has a figure. AUTHORING.md says so in one line.

## Acceptance

Token counts measured with tiktoken o200k (`uvx --with tiktoken python -I -`), before/after, for AUTHORING.md alone and AUTHORING+DIAGRAMS. No rule lost: every class and rule in the old file appears in one of the two.

## Log
