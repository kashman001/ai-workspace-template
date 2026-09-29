<!--
PURPOSE: This is the LEDGER (provenance log). Append-only, newest block on
TOP. Each "# Session Handoff" block records what happened in one session.
Read the TOP block only; older blocks are in handoff-archive.md. Forward
"what to do next" belongs in next-session.md, NOT here.
Convention: docs/work-directory-conventions.md.
-->

# Session Handoff — 18 (2026-09-28): hands-off — plan `02-follow-on` wave 1: node 01 (threshold confirmation) done in-session — pre-registered 2× rule fails at 0.5 *and* at 0.25, verdict **keep 0.5 (rule inconclusive)**, no code touched, S22 note; node 02 (`score()`/`check()`) done by a standard-tier subagent test-first, test-jev.sh 182/182, `llm_query` untouched; node 03 + reconcile 04 left for session 19; WARN at 124 K mid-node, rolled over hands-off at ~135 K

## What happened

- Registered seq 18 by the SessionStart hook (supervised chain, `handsoff`). Found the launcher's Position block re-rendered to plan 01's closed line by the supervisor's `sync` (see Learnings); restored with `plan.sh sync --plan 02-follow-on`.
- **Node 02** dispatched to a `sonnet` subagent (tier standard) with the skill's prompt template, actor `s18-a`. It added T21–T25 (42 assertions, fixtures `score-batch.json`, `noul-batch.json`) red first, then `score()`/`check()` + `DEFAULT_JEV_NOUL_MARGIN` (`RLM_JEV_NOUL_MARGIN`, 0.25) in `skills/rlm/scripts/rlm_repl.py`, generalising classify's private helpers into `_jev_run`/`_jev_batch`/`_leaf_numbered`; docs in both skills. Suite 182/182 (was 140/140); `done` ran the node's check (suite + both `def` greps) — passed. Its ticks are subagent claims until reconcile 04 re-verifies on disk.
- **Node 01** in-session: corpus `git log --format=%s -n 100`; keyed `classify()` at `threshold=0.0` (2 requests, 100/100 `jev`, confidence 0.15 / 0.54 / 1.0); leaf leg with a pass-through `security` stub (fails only `jev-api-key`) 100/100 `leaf`, 78 s, no mention of Jev. Buckets: `[0,0.25)` 8/15 · `[0.25,0.5)` 16/20 · `[0.5,1]` 49/65 · overall 73/100. Rule fails at both boundaries → no destination → keep, flagged for the goal-level close (0.25 would type 85 vs 65 at the same 0.75 agreement). Cost ≈ $0.0007 (~17.5k est. input tokens). Note appended to `decisions.md` (S22). The s13 category *descriptions* were never recorded; s18 wrote its own (in the note).
- Dogfood bullet (second strike) in `work/plans/decisions.md`: supervisor bound to the stale closed plan.

## Decisions

- S22 verdict: keep 0.5, rule inconclusive — `decisions.md` last note (2026-09-28, node 01). Wave-2 nodes 05/06 keep their "≥ 0.5" wording; no replan needed.

## Current state

- Plan `02-follow-on` open, wave 1 of 2, done 2/7 (01, 02), todo 03 → 04-reconcile-w1 → wave 2. Frontier: `03-relevance-experiment`.
- Working tree committed at this rollover (helpers, tests, fixtures, skills, notes, plan files, ledger, launcher). `main` ahead of origin — the user pushes.
- **Chain risk:** the live supervisor (`session-loop.sh`, started 23:36 local) is bound to plan `01-gated-integration` (closed, reconcile 16 done). After this session it will record `plan_closed` and exit without running the staged successor. Recovery, one line: `scripts/session-loop.sh jev-integration --plan 02-follow-on --reopen`.

## Open questions

- None for wave 1. For the goal-level close: lower the threshold to 0.25 on the crisp-corpus evidence, or keep 0.5 (S22 note has the table).

## Next steps

- Session 19: node 03 (paid Noul batch; `check(rows, condition, margin=0.0)` now exists and returns every raw probability), reconcile 04 (re-verify 01/02 on disk, flip tickets 08–10 `resolved`, sum costs), then wave 2.

## Key files

`work/jev-integration/decisions.md` (S22 note, last), `plans/02-follow-on/nodes/{01,02,03,04}-*.md`, `skills/rlm/scripts/rlm_repl.py` (`score`, `check`), `scripts/tests/test-jev.sh` (T21–T25), `scripts/tests/fixtures/jev/{score,noul}-batch.json`, `work/plans/decisions.md` (s18 bullet). Scratch (not committed): session scratchpad `jev-s18/n01/` and `jev-s18/nokey/security`.

## Suggested skills

`plans` (reconcile procedure for 04), `decision-log` (S29 note), `session-rollover`.

Learnings:
- A `plan.sh sync`/`status` without `--plan` resolves via `chain.plan`; with a stale binding it silently rewrites the launcher's Position block — always pass `--plan` while two plans exist.
- The reconcile-node ordinal in tickets ("tenth"/"eleventh" note) drifted after the s17 follow-on-shape note; name notes by S-number.
- `check()` with `margin=0.0` is the way to harvest raw Noul probabilities for an experiment (no leaf fallback).

# Session Handoff — 17 (2026-09-28): interactive — the approved Jev follow-on was grilled one question at a time (nine questions, plain-language framing at the user's request), `spec.md` amended with S22–S30 and **re-approved**, tickets 08–12 written, plan `02-follow-on` created (7 nodes, 2 waves), `check` silent, `sync` rendered; WARN at 128 K after the plan landed

## What happened

- Registered seq=17 (41 % at start — the system context alone is heavy).
- Grill (`grill-with-docs` → `grilling` + `domain-modeling`), one question
  per turn after the user asked for simple terms and options: **1a** keep 0.5
  by a pre-registered rule (`[0.5,1]` agreement ≥ 2× `[0.25,0.5)`, else move
  to the first boundary where it holds); **2a** two helpers `score()` and
  `check()` shaped like `classify()`; **3a** Noul fallback = probability
  within 0.25 of 0.5; **4a** research-wave: Jev is a *second reader* over
  the fact-check table, flags rows where ≥ 0.5 and disagrees, fact-checker
  and ruling unchanged; **5a** tier routing = evidence batch over both
  items' node files → `work/plans/issues/12-jev-tier-routing.md`, no edit to
  `plan.sh` (the "cheap-first + escalate" baseline was found not to exist);
  **6b** relevance filter = one experiment (docs/README.md rows × five task
  sentences, Noul per row), a note not a feature; **7a** one plan, agent runs
  the paid batches, cost in the node Log, no hitl gates; **8b**
  `scripts/jev-verdicts.sh` thin script + offline test; **9a** experiment
  truth = the tickets' "Read first" lists (weakness stated).
- `spec.md`: Status → in-review → **approved** again (re-approved by the
  user in chat, "approved"); S22–S30 appended under a "Follow-on" heading;
  Implementation and Testing each gained a follow-on bullet; Non-goals
  rewritten (research-wave and Score/Noul lifted; tier-routing *code* and a
  relevance *feature* stay out; "nothing in the ruling depends on Jev" added).
- Tickets `issues/08…12` in the item's format, each with a `Read first:`
  line (that line is S29's truth list). Plan: `plan.sh new follow-on`, seven
  `add`s (`--plan 02-follow-on` is required while plan 01 exists closed —
  without it `add` targets plan 01 and is refused), bodies filled from the
  tickets, `plan.md` Goal/Out of scope written, `check` silent, `sync` done.
  **Waves follow blockers, not the slice order agreed in Q7**: wave 1 =
  nodes 01–03 (independent), wave 2 = 05 and 06 (both need the confirmed
  threshold); two waves, not three — told to the user in the recap.
- Dogfood: `--project <item>` in a shell variable refused as predicted
  (constraint held); `add` without `--plan` picks the closed plan — noted for
  the `plans` item below.
- Budget: WARN (128 K) right after `sync`; wrap-up committed (05b8273), the
  user chose to roll over: launcher rewritten for wave 1 hands-off, staged
  with `--emit --loop-mode handsoff` (supervised chain).
