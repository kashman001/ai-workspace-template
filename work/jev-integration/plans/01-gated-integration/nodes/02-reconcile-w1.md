---
id: 02-reconcile-w1
title: Join wave 1
status: done
kind: reconcile
wave: 1
blocked_by: [01-decision-note]
sessions: [7]
---

## Goal

Join wave 1 (`skills/plans/SKILL.md` → "Run a reconcile node"): verify node 01
on disk — open `decisions.md`, run
`scripts/plan.sh verify 01-decision-note --project jev-integration`, grep each
cited claim id under `research/`; record any fork the drafting settled; replan
within authority. Once this node is `done` the frontier is the `hitl` node 03,
so the supervisor stages the next session interactive — make sure the
launcher's prose above the Position block tells the person what node 03 asks.

## Acceptance

- [x] Verified on disk — every ticked box of 01 held (or a follow-up node was added and the finding logged here)
- [x] Decisions recorded — forks as Tier-2 notes, discoveries as `plan.sh note`
- [x] Replan applied within authority; `scripts/plan.sh check` silent

## Log
- s7 · started, tier frontier
- s7 · verified on disk: decisions.md note present (heading + five fields + pointer line), plan.sh verify 01 passed, 14/14 claim ids resolve in research/*/record.md, research/ unchanged (git diff touches decisions.md and node files only). One fork this wave (the fit note itself) — already the Tier-2 note; one discovery → plan.sh note. No replan: wave 2 (03 hitl, 04 reconcile) stands as created; check silent. Verdict: wave 1 joined; frontier is 03 (hitl) — a person approves or amends the note.
- s7 · done
