---
id: 01-decision-note
title: Fit decision — Tier-2 note in decisions.md: rlm leaf seam, gated on jev access
status: done
kind: work
wave: 1
blocked_by: []
leaf: design
tier: auto
check: grep -qE '^## .*[Ff]it decision' decisions.md
sessions: [7]
---

## Goal

Source: `README.md` → Success criteria ("Fit decision"); `research/synthesis.md`
§5–§6; `research/spike.md`; the user's direction in `plan.md` → Goal; the
session-6 grill round (`handoff.md`, block "6 (2026-09-24/25)"): four
questions, of which the user's direction answers **Q4 = (a)** — Jev as an
optional path with the current runtime as default and fallback.

`decisions.md` already holds the R0.4-lift note (2026-09-24). **Append** a
second Tier-2 note (format per `skills/decision-log/SKILL.md`: Chose /
Because / Rejected / Blast radius / Promote?) headed
`## 2026-09-<dd> — Fit decision: …`, as a **proposal for node 03's approver**,
and replace the trailing "Fit decision: STILL OPEN" line with a pointer to it:

- **Chose:** integrate Jev at the `rlm` leaf-classification seam
  (`skills/rlm/scripts/rlm_repl.py` — `RLM_SUB_MODEL`, the `claude -p`
  subprocess), **gated on access**: active only when
  `security find-generic-password -s jev-api-key -w` returns a key (macOS) or
  the documented equivalent elsewhere; with no key the current path runs
  unchanged and nothing is logged as an error (Q4 = a, the user's). Take the
  session-6 recommendations as the proposal for the open questions and say so:
  Q1 axis = (c) determinism + thresholdable `confidence`, latency second;
  Q2 scope = narrow to `rlm` (the research-wave verdict seam noted, the other
  four rejected in one line each); Q5 lift = (a) orchestrator fact-finding now,
  widened to dispatched agents by the spec if approved. Batch-as-state (one
  Choice per record), an explicit `other` option, a confidence threshold,
  alias `jev-latest`.
- **Because:** cite claim ids from `research/` (what-jev-is C28;
  integration-paths 5.1–5.7, 6.2; terms 1.1, 1.7, 2.1, 5.9, 7.3) and the spike
  rows (0.64s vs 4.83s; per-record confidence; O29 closed; the 255-option cap
  is server-enforced).
- **Rejected:** (a) always-on integration — template downloaders and other
  runtimes have no key, and the template ships credential-free; (b) the other
  five seams first — low volume, or a human confirms anyway (synthesis §5 fit
  hints); (c) no-go — the spike shows the shape fits end to end at negligible cost.
- **Blast radius:** `skills/rlm/`, `docs/service-access.md`,
  `docs/runbooks/authentication.md`, `scripts/check-service-access.sh`, a test
  that proves both paths without a live key.
- **Promote?:** left for the approver (node 03).

Do not touch `research/` (records, passes, fact-checks, briefs, the spike).
Do not re-run the spike; never print or write the key.

## Acceptance

- [x] `decisions.md` has the new note appended after the R0.4 note, with a dated `## … Fit decision` heading and the five fields; the "STILL OPEN" line now points at it; the node's check passes
- [x] Every claim id cited resolves (`grep -rn '<id>' research/` finds a row for each)
- [x] The note names Q1, Q2, Q4, Q5 and which of them is the user's answer (Q4) versus a proposal
- [x] The note says in one sentence what a user *without* a key experiences (nothing changes)

## Log
- s7 · started, tier frontier
- s7 · fit note appended to decisions.md (heading "## 2026-09-27 — Fit decision: …", five fields, Q4 = user, Q1/Q2/Q5 = proposals for node 03); "STILL OPEN" line replaced by a pointer; 14 claim ids resolve (grep of research/*/record.md); check passes; research/ untouched. On disk: decisions.md. Not on disk: nothing pending.
- s7 · check passed → done
