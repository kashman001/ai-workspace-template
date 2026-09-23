# Corrections brief 2 — `what-jev-is` (jev-integration wave 1, 2026-09-23, second round)

Working directory: `/Users/kashif/Developer/experiments/ai-workspace-template`.
Item directory (the ONLY place you write): `work/jev-integration/research/what-jev-is/`.

You apply the orchestrator's second-round rulings to the item's deliverables.
Read first: `skills/research-wave/references/method-rules.md`, then this
item's `corrections-brief.md` (gen 1's brief — its **Hard rules** section
applies to you unchanged) and `corrections.md` (gen 1's report: what was
already changed, and the `## New findings needing a ruling` these rulings
answer). Then `record.md`, `verification.md`, `profile.md`,
`open-verification.md` — grep for the claim ids named below rather than
reading whole files where you can.

Hard rules are gen 1's: re-derive every number by re-fetching or re-counting;
rule-7 grep of the whole item directory per corrected claim (`profile.md`
prose and the appendix included); mark every change in place with
`(corrected 2026-09-23; previously: "<old text>")`; leave `pass/*.md`,
`fact-check.md`, `brief.md`, `fc-targets.md`, `fact-check-brief.md`
untouched; refuse any ruling the evidence contradicts; public sources only,
no accounts/keys/API calls/spend. Do not touch gen 1's markers or entries.

## Rulings (orchestrator, 2026-09-23, from `research/rulings.md`)

- **R12 — fact-check premise errors: NO EDIT.** `fact-check.md` stays as it is
  (provenance); the note gen 1 left in `verification.md` is the record. Confirm
  in your report that nothing was changed for R12.
- **R13 — lead verification scorecard: APPLY.** V15's reversal means the lead's
  "34 survived" is 33 with one lead-introduced defect. Re-count the status column
  of the verification table yourself (survived / downgraded / overturned / other)
  and restate the scorecard line (`verification.md` line ~11 "Scorecard: 41
  checks — **34 survived, …") and the "Moves toward confidence: 34 survived"
  line (~72), and any echo of "34 survived" elsewhere in the item (rule-7 grep
  `34 survived`, `survived,`, and the scorecard figures in `record.md`'s
  progress/summary lines — mark those as historical rather than rewriting
  history: `(historical, pre-correction figure; see verification.md scorecard)`).
  If your count is not 33, do not apply — report your count.
- **R14 — C14 wording: APPLY-REWORDED.** C14 says advanced.md makes
  `instructions` "optional and nullable". Re-fetch
  `https://api.typesafe.ai/openapi.json` and `https://docs.typesafe.ai/advanced`
  (try the `.md` variant the item used) and record, side by side, the spec's
  exact keyword(s) for `instructions` (e.g. its `anyOf`/`type` with `null`, and
  whether it is in `required`) and the docs' exact word(s). Reword C14 to state
  what each literally says; keep the verdict `contradicted` only if api.md still
  marks it required (re-fetch `https://docs.typesafe.ai/api` to check).
- **R15 — C50 low-end minima: APPLY.** The 7.2x/20.3x minima come from the choice
  cookbook's "gpt-5.4-mini single-pick" row, which the cookbook itself flags as a
  "clean round trip rather than one measured under the 16-way LLM thread
  contention" (gen 1 cites `consistency_choice_cookbook.md` L558 — re-fetch and
  confirm the line). Qualify C50 so "measured under 16-way contention" applies to
  the high end only, and name the source row of the low end. Rule-7 grep `7.2x`,
  `20.3x`, `16-way` across the item (including `profile.md`).
- **R16 — deferred, DO NOT APPLY:** the cosmetic apostrophe (fact-check T6/T3)
  and the N1 promotion (fact-check C51) go to the Phase 4 sweep.

## Report

Append to `corrections.md` (do not rewrite gen 1's sections): a
`## Second round (gen 2, 2026-09-23)` section with one entry per ruling
R12–R16 — applied / applied-reworded / refused / could-not-apply / deferred,
with what changed and where (file + claim id + the re-derived figure) — then
`## Not applied (round 2)` and `## New findings needing a ruling (round 2)`
(either may be empty). Progress blocks labeled `[gen 2]` under `## Progress`.

Return at most 12 lines: status line first (DONE | DONE_WITH_CONCERNS |
BLOCKED | NEEDS_CONTEXT | ROLLOVER_NEEDED); rulings applied / reworded /
refused / deferred counts; any refusal and why; any new finding needing a
ruling. Detail in `corrections.md`.
