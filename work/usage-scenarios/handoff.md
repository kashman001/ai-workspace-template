<!--
PURPOSE: This is the LEDGER (provenance log). Append-only, newest block on
TOP. Each "# Session Handoff" block records what happened in one session.
Read the TOP block only; older blocks are in handoff-archive.md. Forward
"what to do next" belongs in next-session.md, NOT here.
Convention: docs/work-directory-conventions.md.
-->

# Session Handoff — 2026-08-08 (session 1: scaffold + ground-truth mining + catalog §1–3; rolled at WARN 139K)

What got done:
- Scaffolded the work item; committed per-item `context-budget.env` with
  `ROLLOVER_RELAUNCH=auto` (user directive: hands-free rollover).
- Captured user requirements in `brief.md` (multi-repo products, multi-user,
  per-user settings/secrets/tooling with non-negotiable baseline, three
  onboardings, concurrent work items, root product docs, context budget,
  zoom-level abstraction). Mid-session user additions: (1) zoom = product
  information specifically (architecture → source file), (2) keep the
  operational hierarchy as a second orthogonal dimension, (3) agents per
  zoom level as profiles — all incorporated into `scenarios.md` §1/§1b/§1c.
- Ran 4 parallel read-only subagents over the repo; distilled ALL findings
  into `ground-truth.md` (backlog state, settings/secrets/tooling, external
  lifecycle docs, internal machinery + full test-coverage map). That file is
  the successor's evidence base — the raw reports are gone with this session.
- Drafted `scenarios.md`: §1 zoom model (Z0–Z3 + budgets), §1b operational
  hierarchy (O0–O4), §1c agents-per-zoom-level principle, §2 harness-vs-
  template table, §3 external catalog E1–E17 with support verdicts.

State: all files in `work/usage-scenarios/`; committed at rollover (see git
log). Tasks #1–2 done, #3 half done (§4 internal catalog pending), #4–5 not
started.

Suggested skills for next session: none beyond conventions; `decision-log`
when recommendations settle into decisions.

Learnings: (parked) 4-way subagent fan-out for doc mining worked well but
each report is ~80K child tokens — distill-to-disk immediately, reports are
the bulk of what pushed this session to WARN.
