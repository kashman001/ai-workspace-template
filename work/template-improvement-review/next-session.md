# Next Session — template-improvement-review (user decides D1–D3 → Stage 4 plan on go)

> **This file is the LAUNCHER (catch-up prompt).** Forward-only, REPLACED at
> each rollover. Past-tense provenance lives in `handoff.md`.
> Convention: docs/work-directory-conventions.md.

## Mission

**Get the user's three decisions on design v2 and their go for Stage 4, then
plan the implementation (Part 4).** Do not start Stage 4 unasked. Answer
questions about v2 from the files (grep; never guess). Record each decision
as a Tier-2 note (`/decision`) and edit v2 in place (dated) where it changes
the design.

Four-stage process (user, 2026-09-14): (1) research ✔ → (2) design ✔ →
(3) evaluate design ✔ (Part 3, session 8) → (4) plan ← after the user's go.

**Readability rule (user, session 8, binding for every doc they read):**
short; plain language; self-contained without the workspace (pointers only
as footnotes); each concept introduced by a diagram or a two-sentence
explanation. Memory `review-docs-plain-language` has the detail.

**No-human-in-the-loop clause:** if nobody answers, present the page and the
three decisions (First actions step 3), stop, and wait.

## Read these, in order

1. `work/template-improvement-review/evaluation/stage3-design-v2.md` — the
   design (158 lines; read whole, it is the user-facing text).
2. `work/template-improvement-review/session-management-review-findings.md`
   Part 3 only (from line 688, 76 lines): amendments, cut list, decisions.
3. `work/template-improvement-review/handoff.md` — top block only.
4. For Stage 4 only: `evaluation/stage3-developer-review.md` §4 (migration
   order, first vertical slice) and §8; Part 3 "What Stage 4 needs".

## Do NOT reload

Part 2 (superseded), Part 1/1b, the stage1-* and stage3 architect/scenario
reports (Part 3 has the synthesis), `review.md`, `decisions.md` (append
only), backlog HTML whole, big scripts whole.

## State snapshot

- `main` = 2dc0d6e + this rollover's commit; clean; ahead of origin locally
  (do not push).
- Supervisor pid 72900 still live on pre-a213b3d `session-loop.sh` (hazard).
  No edit to that file before decision 12 (end the chain at an interactive
  pause). No code changes yet; F10 small defects wait for Stage 4 phase 1.
- Design v2 page (private): https://claude.ai/artifact/2VMbASSbqw1JN4JTeC9jrb. Part 2 page (superseded):
  https://claude.ai/artifact/4KeTb5seRPdSS8AtEKQmmV

## First actions

1. `scripts/context-budget.sh register --project template-improvement-review`
2. Read inputs 1–3.
3. Present to the user, verbatim: the v2 page URL, the source path, and the
   three decisions from v2 § "Decisions needed" with the recommendations
   (D1 drop the unknowable logout code; D2 occupation rule, no number spent;
   D3 accept the identity heuristic). Then STOP and wait.
4. On each decision: `/decision`, edit v2 in place (dated), and if it changes
   the support matrix or a gate, say so. Every ~10 exchanges:
   `scripts/context-budget.sh record --label "v2 review Q&A"`.

## Stage 4 recipe (only on the user's explicit go)

Write **Part 4 — implementation plan** (≤ ~120 lines, same readability
rule) from v2 + Part 3 + developer review §4: ordered phases, each a
vertical slice with its test; phase 0 = decision 12 (end pid 72900), root
`ROLLOVER_RELAUNCH=manual` + this item's committed `auto` override, `jq` as
hard `req`; phase 1 = record helper + its test; then fleet extraction (pure
move), context-budget verbs, launcher, supervisor (`main "$@"` first),
dispatcher, docs/skill/env; F10 defects folded into the phase that touches
each file. Delegate the draft to one Plan agent (give it v2, Part 3, dev §4/§8,
`docs/context-budget.md` headings, `tests/` listing); parent reads the
summary + the plan. Append as Part 4, update the status header, `record
--label "Stage 4 plan drafted"`, commit, STOP for the user's review. Then
`/to-tickets` on the user's acceptance.
