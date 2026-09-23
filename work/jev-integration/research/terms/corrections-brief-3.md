# Corrections brief 3 — `terms` (jev-integration wave 1, 2026-09-23, third round: post-sweep)

Working directory: `/Users/kashif/Developer/experiments/ai-workspace-template`.
Item directory (the ONLY place you write): `work/jev-integration/research/terms/`.
You may READ the sibling item directories (`../what-jev-is/`, `../integration-paths/`) and `../sweep.md`, `../schema.md` — never write there.

You apply the orchestrator's post-sweep rulings. Read first:
`skills/research-wave/references/method-rules.md`; this item's
`corrections-brief.md` (its **Hard rules** section applies to you unchanged;
it carried both earlier rounds, R1–R9); `corrections.md` (what already
changed); `../schema.md` § "Verification scale"; then `../sweep.md` rows
SW1-6, SW2-1, SW3-2, SW3-4, SW4-1, SW4-6, SW4-7, SW4-8 (grep the ids). Grep
`record.md`, `verification.md`, `profile.md`, `open-verification.md` for the
claim ids and line ranges named below rather than reading whole files.

Hard rules are the earlier brief's: re-derive every number by re-fetching
(public sources only; `curl`) or re-counting; rule-7 grep of the whole item
directory per corrected claim (`profile.md` prose and the appendix included);
mark every change in place with
`(corrected 2026-09-23; previously: "<old text>")`; leave `pass/*.md`,
`fact-check.md`, `brief.md`, `fc-targets.md`, `fact-check-brief.md`
untouched; do not touch earlier rounds' markers or entries; refuse any ruling
the evidence contradicts; no accounts/keys/API calls/spend, no Chrome/logins.
Table rows: the cell count must not change on any edited row (escape a
literal `|` inside a code span as `\|`).

## Rulings (orchestrator, 2026-09-23, from `research/rulings.md` R21, R29–R38)

- **R21 — billing-analytics chunk counts 2 → 1: APPLY as a relabel.**
  `record.md:97` claim 6.6 "fresh grep 2 each" and `verification.md:23` V10
  "`billing topup started` 2; `billing auto reload toggled` 2" contradict the
  appendix (`record.md:186`): 1 each across the 18 public JS chunks referenced
  from `/login`. The sweep confirmed the appendix figure stands (SW4-7). The
  chunks are public (logged-out `/login` references them): re-fetch and
  re-count if you can; if a count differs from 1, record the spread with the
  as-of date rather than picking. Relabel both sites to 1 each, markers.
- **R29 + R31 — re-score `verification.md` on the unified scale and restate
  the scorecard: APPLY.** Use `../schema.md` § "Verification scale" (seven
  levels). For every row (V1–V43 and the S4 table) the outcome cell's first
  word must be one of the seven; change a word only where it differs (marker
  with the old word): "survived, with a downgrade in precision" (V40),
  "survived, downgraded" (V41) → `downgraded`; V7/V8 "survived — rule-8 miss …
  not re-ratified" → decide on the scale (`survived` only if the lead
  re-checked them; else `not re-checked`) and say which. Then restate the
  scorecard sentence (`verification.md:3–4`, "43 checks … 37 survived, 3
  downgraded, 2 overturned" — it sums to 42 and matches no reading of the
  column) as one count per level summing to the row count, and say
  explicitly whether the S4 table's two rows are in the total. The sweep's
  reading: 39 of 43 survived (V17/V40/V41 down, V23 overturned) or 40 of 45
  with the S4 table (its extra row overturned). If your count differs, report
  yours; do not force. Rule-7 grep `37 survived`.
- **R30 — literal `|` in a code span: APPLY (escape only, no content
  change).** `record.md:17` (claim 1.3) has `per request|per decision|cached|batch`
  in a code span → the row renders 10 cells vs 7. Escape each pipe as `\|`.
  Verify with a code-span-aware cell count before and after. No marker; one
  line in your round-3 report.
- **R33 — stale figures: MARK HISTORICAL, do not rewrite.** `record.md:212`
  (the "37 survived" echo) and `record.md:213` "28 open items" (today 30
  rows, 2 closed — O1, O7 — 28 open, right only by coincidence): append
  `(historical, pre-correction figure; see verification.md scorecard /
  open-verification.md)` to each.
- **R36 + R38(e) — drift note: APPLY (note only, no quote edited).** The MCA
  "Last updated Sep 19, 2026" and Privacy "Last updated Nov 19, 2025"
  appendix lines match 0× contiguous in raw HTML and 1× after tag-stripping.
  Re-check (re-fetch both pages); where only the tag-stripped match holds add
  a one-line how-verified note on that appendix line: "(verbatim after
  tag-stripping; not contiguous in raw HTML)". No marker needed for a note
  that changes no claim.
- **R37 — not checked, record as open: APPLY.** Add rows to
  `open-verification.md`: (a) the console JS chunk counts (6.6, appendix
  `record.md:186`) were not re-fetched by the sweep — login-gated beyond the
  `/login` references; tag `browser`/`account` as the earlier rows do; (b) the
  header tally's "11 split" list (`record.md:5`) was not re-counted by the
  sweep (split halves are prose inside the verdict cell) — re-count it
  yourself now from the verdict column (it is a count, so rule 3 applies): if
  it is 11, close the row on creation with the count shown; if not, restate
  the tally line with a marker.

## Report

Append to `corrections.md` (do not rewrite the earlier sections): `## Third
round (gen 3, 2026-09-23)` with one entry per ruling above — applied /
applied-reworded / refused / could-not-apply — with what changed and where
(file + claim id + the re-derived figure) — then `## Not applied (round 3)`
and `## New findings needing a ruling (round 3)` (either may be empty).
Progress blocks labeled `[gen 3]` under `## Progress`.

Return at most 12 lines: status line first (DONE | DONE_WITH_CONCERNS |
BLOCKED | NEEDS_CONTEXT | ROLLOVER_NEEDED); rulings applied / reworded /
refused counts; the restated scorecard line; any refusal and why; any new
finding needing a ruling. Detail in `corrections.md`.
