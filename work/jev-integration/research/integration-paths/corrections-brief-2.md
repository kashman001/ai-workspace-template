# Corrections brief 2 — `integration-paths` (jev-integration wave 1, 2026-09-23, second round)

Working directory: `/Users/kashif/Developer/experiments/ai-workspace-template`.
Item directory (the ONLY place you write): `work/jev-integration/research/integration-paths/`.

You apply the orchestrator's second-round rulings to the item's deliverables.
Read first: `skills/research-wave/references/method-rules.md`, then this
item's `corrections-brief.md` (gen 1's brief — its **Hard rules** section
applies to you unchanged) and `corrections.md` (gen 1's report; the
`## New findings needing a ruling` these rulings answer). Then grep
`record.md` for `5.12-spec-spread`, `2.7`, `4.2`, and `O21` in
`open-verification.md`; read whole files only if the greps are not enough.

Hard rules are gen 1's: re-derive every number by re-fetching or re-counting;
rule-7 grep of the whole item directory per corrected claim (`profile.md`
prose and the appendix included); mark every change in place with
`(corrected 2026-09-23; previously: "<old text>")` — for a pure addition,
`(added 2026-09-23, ruling R10)`; leave `pass/*.md`, `fact-check.md`,
`brief.md`, `fc-targets.md`, `fact-check-brief.md` untouched; refuse any
ruling the evidence contradicts; public sources only, no accounts/keys/API
calls/spend. Do not touch gen 1's markers or entries.

## Rulings (orchestrator, 2026-09-23, from `research/rulings.md`)

- **R9 — ValidationError example hint: NO EDIT.** It stays a hint inside O21,
  not a claim; gen 1 already did this. Confirm in your report.
- **R10 — Vercel provider README restating the docs' caps: APPLY (addition).**
  Re-fetch the README of `vercel/ai` `packages/typesafe-ai` (raw GitHub, main
  branch; fall back to the npm page for `@ai-sdk/typesafe-ai` if the path moved)
  and locate the line gen 1 quoted as line 50: "255 options; Score supports 2–10
  ordered levels; Boolean maps to TypeSafe's Noul". Record its exact line number
  and text today. Add it to the notes of claim `5.12-spec-spread` in `record.md`
  as a **third source on the docs side** of the spread (it adopted the docs'
  figures, not the spec's; it does not resolve the spread either way). Add the
  quote to the verbatim appendix with its URL and date. If 2.7 or 4.2 name the
  README's caps without pointing at 5.12-spec-spread, add a cross-reference (an
  addition, not a rewording).
- **R11 — the fact-check's optional strengthenings: DEFERRED, DO NOT APPLY.**
  They go to the Phase 4 sweep.

## Report

Append to `corrections.md` (do not rewrite gen 1's sections): a
`## Second round (gen 2, 2026-09-23)` section with one entry per ruling
R9–R11 — applied / applied-reworded / refused / could-not-apply / deferred,
with what changed and where (file + claim id + the re-derived line/text) — then
`## Not applied (round 2)` and `## New findings needing a ruling (round 2)`
(either may be empty). Progress blocks labeled `[gen 2]` under `## Progress`.

Return at most 12 lines: status line first (DONE | DONE_WITH_CONCERNS |
BLOCKED | NEEDS_CONTEXT | ROLLOVER_NEEDED); rulings applied / reworded /
refused / deferred counts; any refusal and why; any new finding needing a
ruling. Detail in `corrections.md`.
