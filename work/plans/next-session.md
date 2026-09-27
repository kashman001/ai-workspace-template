# Catchup prompt — plans (paste into a new agent session)

We're resuming `plans`. Works in any runtime (Claude Code, Codex, Gemini,
OpenCode) — all read `CONTEXT.md` via their entrypoint.

> **This file is the LAUNCHER (catch-up prompt).** Forward-only, REPLACED at
> each rollover: what to do next, still-binding constraints, pointers — never
> session history. Past-tense provenance lives in `handoff.md` (the ledger).
> Convention: docs/work-directory-conventions.md.

## Mission

Tickets 01–10 are `done`. Ticket **11** (dogfood) is **in progress on
another item**: `work/jev-integration/plans/01-gated-integration` (opened
2026-09-25, session 15) is the first real plan — fit note → a person approves
(`hitl`) → spec + tickets → structural replan adding the implementation waves.
That chain runs under jev-integration's supervisor, not this one. This item's
remaining job is to **collect the findings and close 11**: what broke, what
was slow, whether a rollover split happened or was shown unnecessary, and
the L48 verdict (wayfinder as a plan template — waves 1–2 of that plan *are*
a wayfinder).

## First actions

1. `scripts/context-budget.sh register --project plans` (manual restart;
   expect `seq=17`).
2. `scripts/plan.sh status --project jev-integration` and the "Dogfood
   findings" list at the tail of `decisions.md` here. If the plan is not yet
   closed (`plan_closed` not in `work/jev-integration/.session-loop.log`),
   there is nothing to close yet: add any new finding from that item's
   `handoff.md` top block to the list, commit, `checkpoint`. Sessions 15 and
   16 already did this; do not repeat their findings. The jev chain itself
   is closed (`quit_plain`) — it restarts only when a person runs
   `scripts/session-loop.sh jev-integration --reopen` (or `--plan`); the
   plans item never drives it.
3. When it *is* closed: tick 11's boxes against the evidence (the log's
   `plan_closed` line; a split or its absence in that plan's `## Replans`;
   the findings list), write the L48 verdict as a Tier-2 note in
   `decisions.md`, mark `issues/11-dogfood-first-real-plan.md` `done`, update
   this `README.md` status line and the `work/README.md` row, then fix the
   findings that are bugs under new tickets (12+) — note first, fix second,
   suite third. `checkpoint`, not rollover. Candidate 12 is already named in
   the findings: a ledger lint (header comment intact, `# Session Handoff`
   headers unique, first block right after `-->`), after s15 produced two
   ledger-write defects that s16 fixed by hand.

## Read these, in order (keep it lean)

1. `issues/11-dogfood-first-real-plan.md`; `decisions.md` tail (the findings).
2. `work/jev-integration/handoff.md` top block; `work/jev-integration/plans/01-gated-integration/plan.md` (`## Replans`, board).
3. `skills/plans/SKILL.md` only if a finding needs a fix.

## Do NOT reload

- `concept.md`, `seams.md`, the grill, `spec.md`, tickets 01–10, `handoff.md`
  beyond the top block.
- `plan.sh`, `session-loop.sh`, the skills, `docs/plans.md` — built and green;
  a fix comes only under a ticket that a finding opened.

## Still binding

- No concrete model name anywhere. Nothing pushed to origin — report how far
  ahead main is.
- `test-plan.sh` (238), `test-session-loop.sh` (140),
  `test-doc-consistency.sh` (17), `test-template-version.sh` (9) stay green.
- Plan vocabulary says "work item", never "worktree".
- `plan.sh` verbs need `--project jev-integration` from a session bound here.

## State snapshot

Branch `main`, clean after this session's commits; nothing pushed (main is
60+ commits ahead of `origin/main`). Tickets: 01–10 `done`; 11 in progress
(plan open in jev-integration, frontier `01-decision-note`, 0/6 done, jev
chain closed since 2026-09-25). Plans chain: seq 16, manual restarts.
`TEMPLATE_VERSION` = 2026-09-24. Ledger TOP block = session 16.
