---
id: 04-l98-pilot-design
title: L98 — design the skill-earns-its-place pilot (skills, tasks, runner, cap)
status: doing
kind: work
wave: 1
blocked_by: []
tier: standard
check: test -s pilot/design.md && test -x pilot/run.sh
sessions: [3]
---

## Goal
Card: `docs/template-workspace-backlog.html` → L98 (grep the ID; read only that card). Do not edit the backlog files — the reconcile node moves cards.
The test is in `docs/stakes-to-ceremony.md` → "Make a skill earn its place". In `work/backlog-sweep/pilot/`: `design.md` names 3–5 skills that mostly restate default model behaviour (say why each), 3 tasks per skill with a pass/fail rubric, how each arm loads (no skill / same-length dummy / the skill) in a fresh headless run (e.g. `claude -p` in a temp dir, fixed model), the cost estimate, and the cap: at most 45 headless runs (spend authorized, `decisions.md`). `run.sh <skill> <task> <arm>` runs one arm and saves output under `pilot/runs/`. Smoke-test it on ONE arm only.

## Acceptance
- [ ] `design.md` complete: skills, tasks, rubric, arm mechanics, estimate, cap
- [ ] `run.sh` executable; one smoke run saved under `pilot/runs/`

## Log
- s3 · started, tier standard
