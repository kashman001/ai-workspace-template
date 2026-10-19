---
id: 04-l98-pilot-design
title: L98 — design the skill-earns-its-place pilot (skills, tasks, runner, cap)
status: done
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
- [x] `design.md` complete: skills, tasks, rubric, arm mechanics, estimate, cap
- [x] `run.sh` executable; one smoke run saved under `pilot/runs/`

## Log
- s3 · started, tier standard
- s3-d · wrote work/backlog-sweep/pilot/design.md (3 skills + 1 reserve, 9 tasks in pilot/tasks/, rubric, arm mechanics, estimate 36 runs ~$1.10, cap 45), pilot/run.sh (executable), pilot/dummy.txt
- s3-d · smoke: `run.sh unslop t1 dummy` ok, 3s, $0.018; output work/backlog-sweep/pilot/runs/unslop-t1-dummy.{txt,json,err}. This counts as 1 of the 45-run cap. Note CLI has no --max-turns; single turn enforced via --tools "".
- s3-d · on disk: design.md, run.sh, dummy.txt, tasks/*, one smoke run. Not on disk: any other arm/judge run, judge script (node 06 does grading).
- s3 · check passed → done
