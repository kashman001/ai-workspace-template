---
id: 04-reconcile-w2
title: Join wave 2
status: todo
kind: reconcile
wave: 2
blocked_by: [03-approve-decision]
sessions: []
---

## Goal

Join wave 2: confirm 03 was marked done by a person (`scripts/plan.sh show
03-approve-decision --project jev-integration` — the Log line carries the
person's `--by`); re-read `decisions.md` for amendments and reflect any that
change the seam or the gating rule in `plan.md` → Goal. If the note now says
no-go, this is the stop door: log it here, `done` this node, and close the
plan (`docs/plans.md` → closing) instead of continuing. Replan within authority.

## Acceptance

- [ ] Verified on disk — 03 done by a person; amendments (if any) read and reflected in `plan.md` → Goal
- [ ] Decisions recorded — forks as Tier-2 notes, discoveries as `plan.sh note`
- [ ] Replan applied within authority; `scripts/plan.sh check` silent

## Log
