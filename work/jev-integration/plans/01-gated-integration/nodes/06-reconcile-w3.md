---
id: 06-reconcile-w3
title: Join wave 3 — structural replan: implementation waves from the tickets
status: done
kind: reconcile
wave: 3
blocked_by: [05-spec-and-tickets]
sessions: [8]
---

## Goal

Join wave 3, then the structural replan this plan was opened for
(`replan: structural` in `plan.md` authorises it hands-off). Verify 05 on
disk: open `spec.md`, list `issues/`, confirm the `Blocked by:` graph is
acyclic and every ticket traces. Then add the implementation waves from the
tickets per `skills/plans/SKILL.md` → "Create a plan" steps 2–4: a ticket's
wave is 3 + (1 + the longest blocker chain behind it); one node per ticket
with a `Ticket:` pointer under `## Goal` and the ticket's checkboxes under
`## Acceptance`; `--check` from the ticket where a command exists (spec S-ids
by name); a reconcile node last in every new wave; a `hitl` node where a
person must judge — at least UAT of the gated behaviour on a machine with a
key and one without. Each addition is a line under `## Replans`.
`scripts/plan.sh check` silent, then `sync`.

## Acceptance

- [x] Verified on disk — spec and tickets exist and trace; every ticked box of 05 held
- [x] Decisions recorded — forks as Tier-2 notes, discoveries as `plan.sh note`
- [x] Replan applied — implementation waves added from the tickets (`## Replans` lines), `check` silent, board and Position synced

## Log
- s8 · started, tier frontier
- s8 · started, tier frontier
- s8 · verified on disk: spec.md (21 stories, Testability), issues/01–06 with Spec: ids and acyclic Blocked by (01 → 02,03,04 → 05 → 06); every 05 box held. Recorded: Tier-2 note (typed helper beside llm_query) in decisions.md; TypeSafe re-check as a plan note. Structural replan: nodes 07–16 added (waves 4–7, a reconcile last in each, 13 hitl for UAT), bodies from the tickets, five Replans lines; check silent; synced.
- s8 · check passed → done
- s8 · done
