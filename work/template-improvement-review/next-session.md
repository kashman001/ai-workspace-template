# Next Session — template-improvement-review (Stage 4: tickets, then phase 0)

> **This file is the LAUNCHER (catch-up prompt).** Forward-only, REPLACED at
> each rollover. Past-tense provenance lives in `handoff.md`.
> Convention: docs/work-directory-conventions.md.

## Mission

**Stage 4 is live.** Part 4 (the implementation plan) is accepted by the user
(2026-09-16). Cut tickets from it, then start phase 0. Position: phase 0 of 9
+ cutover, 0 done; see `stage4-tracker.md`.

**Readability rule (user, binding for every doc they read):** short; plain
language; self-contained; each concept introduced by a diagram or a
two-sentence explanation. Memory `review-docs-plain-language`.

**No-human-in-the-loop clause:** tickets and phase 0's plan file need no
user input. Ending the supervisor chain does: if nobody answers, finish the
tickets, write `plans/phase-0.md`, update the tracker, commit, and stop.

## Read these, in order

1. `work/template-improvement-review/stage4-tracker.md` (whole; ~40 lines).
2. `work/template-improvement-review/session-management-review-findings.md`
   from line 765 (Part 4, ~80 lines) — the plan.
3. `work/template-improvement-review/handoff.md` — top block only.
4. For phase 0 only: `evaluation/stage3-design-v2.md` record table (the
   `seq` block) and `scripts/tests/test-session-numbering.sh` header.

## Do NOT reload

Parts 1–3, the stage1-*/stage3-* reports, `review.md`, `decisions.md`
(append only), backlog HTML whole, the three big scripts whole (grep them).

## State snapshot

- `main` = 07a47bb + this rollover's commit; clean; ahead of origin (do not
  push).
- Supervisor pid 72900 live on the pre-a213b3d `session-loop.sh`. **This
  session (10) is its next interactive pause.** Do not edit `session-loop.sh`.
- Old counter `.session-seq` = 10 after this launch. Design v2 page:
  https://claude.ai/artifact/2VMbASSbqw1JN4JTeC9jrb

## First actions

1. `scripts/context-budget.sh register --project template-improvement-review`
2. Read inputs 1–3.
3. `/to-tickets` on Part 4: one ticket per phase (0–8 + cutover), blocking
   edges per "Order and gates", under `work/template-improvement-review/issues/`.
   Commit. `scripts/context-budget.sh record --label "Stage 4 tickets"`.
4. Phase 0, step 1 — **end the chain**: tell the user this session is the
   interactive pause; on their ok, do NOT stage a successor at the end of this
   session (a deliberate quit with nothing staged closes the chain correctly).
   Record it in the tracker (phase 0 `in progress`, Notes: "chain ended
   session 10") and the ledger.
5. Phase 0, step 2 — write `plans/phase-0.md` (task-level: env flip + per-item
   override commit; `jq` req test; `.session-seq` import script + test on a
   throwaway work item; `SESSION_LOOP_NOTIFY` ROOT fix). Execute what fits;
   every commit with `scripts/tests/*.sh` green.
6. At each boundary: update `stage4-tracker.md` ("Now" line, row, Used),
   `record --label "<phase> <step>"`. At WARN: `session-rollover` — but if the
   chain has been ended, **stage nothing**; write the files, commit, and tell
   the user to start session 11 by hand with the bootstrap prompt.
