# Next Session — template-improvement-review (session-management review: STAGE 2 review → STAGE 3)

> **This file is the LAUNCHER (catch-up prompt).** Forward-only, REPLACED at
> each rollover. Past-tense provenance lives in `handoff.md`.
> Convention: docs/work-directory-conventions.md.

## Mission

**Part 2 (the design) is drafted and awaiting the user's review.** Do not start
Stage 3 unasked. On the user's go, run **Stage 3** = evaluate the design:
(1) a fresh architect agent reviewing Part 2 for soundness, hidden couplings
and simplicity; (2) a scenario/flow agent walking S1–S10 / E / I and the three
loops (measure / rollover / supervise) against Part 2, with per-scenario
verdicts. Synthesize both into **Part 3** appended to the findings file;
iterate the design (edit Part 2 in place, dated) until Stage 3 is clean; then
STOP for the user's go before Stage 4 (implementation plan).

Four-stage process (user, 2026-09-14): (1) research/evaluate ✔ → (2) design
✔ drafted → (3) evaluate design ← NEXT → (4) plan implementation.

## Binding inputs (read in this order)

1. `work/template-improvement-review/session-management-review-findings.md`
   — status header (lines 1–25), **Part 2 whole (lines ~371–679)**, Part 1b
   §1b.5 (the 17 accepted decisions) and §1b.7 (binding constraint). Part 1
   only by grep.
2. `work/template-improvement-review/evaluation/stage2-probes.md` — probe
   evidence Part 2 relies on (V2 ROTATES; `--bg` env replayed).
3. `evaluation/stage1-architect-review.md` §7(c)/(d) and
   `evaluation/stage1-scenario-evaluation.md` §B/§D — Stage 3 agents need
   these to check the design covers what Stage 1 raised.
4. `work/template-improvement-review/handoff.md` — top block only.

## Do NOT reload

`review.md`, `decisions.md` (append only), backlog HTML whole, the big scripts
whole (agents grep by cited line), `stage1-reevaluation-vs-main.md`.

## State snapshot

- `main` = session-7 commit on top of dfd2d58; clean; ahead of origin by local
  commits only (do not push).
- Supervisor pid 72900 live on pre-a213b3d `session-loop.sh` code (hazard).
  Do NOT edit `session-loop.sh`; decision 12 applies before any edit.
- No code changes yet. F10 small defects remain for Stage 4's first phase.

## First actions

1. `scripts/context-budget.sh register --project template-improvement-review`
2. Read inputs 1–4.
3. If the user has not yet reviewed Part 2, present its summary again
   (§(a) concepts, §(b) field owners, §(e) `--clear`/handshake verdicts,
   §(f) support matrix, §(m) open questions) and STOP.
4. On the user's go: dispatch the two Stage 3 agents in parallel (same shape
   as Stage 1: each returns a ≤600-word summary + a report under
   `evaluation/stage3-*.md`); parent reads summaries only. Give each agent
   Part 2 + inputs 2–3 + §1b.5/§1b.7 and the §(m) questions; ask the
   architect for AGREE/AMEND/REJECT per section with reasons, and the
   scenario agent for a per-scenario YES/PARTLY/NO table plus the loop walks.
5. Synthesize into **Part 3**, apply accepted amendments to Part 2 in place
   (mark edits with the date), `record --label "Stage 3 evaluation done"`,
   commit, STOP for the user's go on Stage 4.
