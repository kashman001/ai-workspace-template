---
id: 03-relevance-experiment
title: Ticket 10 — Relevance filter experiment (a number in a note)
status: todo
kind: work
wave: 1
blocked_by: []
tier: cheap
check: grep -q 'S29' decisions.md
sessions: []
---

## Goal

Ticket: issues/10-relevance-experiment.md
Spec: S29, S30

No feature. One paid batch (S29): `state` = the rows of `docs/README.md` (path + one-line description each); for each of the five follow-on task sentences (tickets 08–12's titles), one Noul per row: "would an agent need this doc to do this task?". Truth = the **Read first** line of the ticket that planned that slice, matched on `docs/…` paths only (skill and script pointers do not count and are said so). Report per-task precision and recall at `p ≥ 0.75` and at `p ≥ 0.5`, the cost, and the stated weakness: judge and planner are the same agent, so this measures agreement with an agent's reading, not correctness. Write it as the eleventh decision note (`S29`); recommend keep-as-experiment / drop / follow-up with a person's ticks (Q9b) in one line. `check()` from ticket 09 may be used if it has landed; otherwise a hand-built request through `scripts/jev.sh`.

Read first: `docs/README.md`, `docs/zoom-model.md`, `decisions.md` (gate rule reasoning in the fit note), `CONTEXT.md` (Jev always-on rule), `docs/plans.md`.

Paid batch: run by the agent on the keyed machine (spend pre-authorized 2026-09-28); cost goes in this Log (S30). Never a bare `scripts/jev.sh` run outside the batch intended; `JEV_DISABLED=1` for any dry run. Scratch under the session scratchpad, never checked in.

## Acceptance

- [ ] Item list built from `docs/README.md` rows; five task sentences taken verbatim from tickets 08–12
- [ ] One Noul per (task, row) sent through `scripts/jev.sh`; raw probabilities kept in the scratchpad, not checked in
- [ ] Truth lists = the five tickets' Read-first `docs/…` paths; precision/recall per task at two cut-offs in the note
- [ ] Weakness and recommendation stated in one line each; cost recorded in the note and the node Log

## Log
