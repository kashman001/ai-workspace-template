---
id: 03-approve-decision
title: A person approves or amends the fit decision
status: done
kind: hitl
wave: 2
blocked_by: [01-decision-note]
sessions: [7]
---

## Goal

A person reads the fit note in `work/jev-integration/decisions.md` (node 01's,
the second note) and confirms or amends the three proposals it carries from
the session-6 grill — Q1 (axis of "serves better"), Q2 (candidate scope),
Q5 (scope of the R0.4 lift) — alongside the already-given Q4 (gated on
access). Amend in place for a wording fix; a material change is a new note
appended (`skills/decision-log/SKILL.md`). Set `Promote?`. When satisfied:

    scripts/plan.sh done 03-approve-decision --by <your-name> --project jev-integration

then, if the supervisor is not running, restart the chain:
`scripts/session-loop.sh jev-integration --reopen --plan 01-gated-integration`.
"No-go" is also an answer: write it in the note, mark this node done, and the
wave-2 reconcile node closes the plan through the stop door.

## Acceptance

- [x] The note in `decisions.md` is the decision the person stands behind (amended if needed)
- [x] `Promote?` is set (yes / maybe / no)

## Log
- s7 · approved by the user in chat (2026-09-27: "go ahead and build the suggested integration, use the plan concept we have built"): Q1 (c), Q2 narrow to rlm, Q5 (a) confirmed as proposed; Promote? set to maybe in the note (the user named no value — the session took the note's own candidate; reversible). Follow-up slices from the same conversation (tier routing at subagent dispatch, relevance filter, jev CLI + context rule + demand-loaded skill) go to node 05 via the launcher.
- kashif · done (forced from todo)
