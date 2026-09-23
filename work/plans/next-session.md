# Catchup prompt — plans (paste into a new agent session)

We're resuming `plans`. Works in any runtime (Claude Code, Codex, Gemini,
OpenCode) — all read `CONTEXT.md` via their entrypoint.

> **This file is the LAUNCHER (catch-up prompt).** Forward-only, REPLACED at
> each rollover: what to do next, still-binding constraints, pointers — never
> session history. Past-tense provenance lives in `handoff.md` (the ledger).
> Convention: docs/work-directory-conventions.md.

## Mission

Turn the settled concept of a **plan** into `concept.md` (one-page
definition, glossary, one worked example in the proposed form) and record the
build/no-build verdict. Session 1 settled most of the concept in conversation
and wrote it to `decisions.md`; only the OPEN items remain to be grilled.

## Read these, in order

1. `work/plans/decisions.md` — the settled notes are binding; the two OPEN
   items at the bottom are the grill's agenda.
2. `work/plans/seams.md` — "Coverage at a glance" table and "What is
   genuinely missing"; read a mechanism's section only when a question
   touches it.
3. `work/plans/README.md` — success criteria.
4. `skills/grill-with-docs/SKILL.md` — when First actions reach step 3.

## Do NOT reload

- The nine **settled** decisions — agreed with the user; do not re-open them.
- A runner — rejected; `session-loop.sh` + an orchestrator reading the
  frontier is the runner.
- Parallel sessions on separate checkouts — out of scope for v1.
- The word "worktree" in plan vocabulary — use "work item".
- The sources behind `seams.md` — every claim there was verified on disk.

## State snapshot

Branch `main`, clean after this rollover's commit; nothing pushed. No
`concept.md`, `spec.md`, or `issues/`. README status line still says no
build verdict. Chain supervised by `session-loop.sh` (seq 1 → 2), staged
`interactive` because the grill needs the user.

## First actions

1. `scripts/context-budget.sh register --project plans` (expect `seq=2`).
2. Read `decisions.md`; list the OPEN items and the one **proposed** note.
3. Grill the user on exactly these, recommended answers first, one round:
   (a) build/no-build; (b) confirm node-file format + status set
   `todo|doing|done|blocked|dropped`; (c) `check` semantics for HITL nodes
   (proposal: HITL nodes have no `check`, acceptance is the human's tick);
   (d) marker convention for generated blocks (proposal:
   `<!-- plan:begin <name> -->` … `<!-- plan:end <name> -->`);
   (e) the integration proposal under OPEN. Record each answer with
   `/decision` in `decisions.md`; flip "proposed" to "settled".
   **If nobody is present:** write the recommended answers as proposed
   notes, write `concept.md` on those assumptions, and stop with the
   questions posed at the top of the ledger block.
4. Write `concept.md`: definition of a plan and its five properties;
   glossary (node, edge, wave, reconcile node, loop node, check, tier,
   orchestrator session, frontier, capture/replan) reusing the vocabulary
   in `seams.md` → "Vocabulary already in use"; one worked example: this
   very item as a plan (waves: ground → write → verdict) in node-file form.
5. If build: set the README status line, then `to-spec` → `spec.md`. If
   the spec is clear, `to-tickets` under `issues/`. If no-build: README
   status line + concept.md stand as the reference.
6. `scripts/context-budget.sh record --label "<unit done>"` at each step.
   At the end or at WARN/STOP: ledger block, rewrite this launcher, update
   the `work/README.md` row, commit. Do not push main; report how far
   ahead it is.
