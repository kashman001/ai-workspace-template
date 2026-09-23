# Corrections brief 3 — `integration-paths` (jev-integration wave 1, 2026-09-23, third round: post-sweep)

Working directory: `/Users/kashif/Developer/experiments/ai-workspace-template`.
Item directory (the ONLY place you write): `work/jev-integration/research/integration-paths/`.
You may READ the sibling item directories (`../what-jev-is/`, `../terms/`) and `../sweep.md`, `../schema.md` — never write there.

You apply the orchestrator's post-sweep rulings. Read first:
`skills/research-wave/references/method-rules.md`; this item's
`corrections-brief.md` (gen 1 — its **Hard rules** section applies to you
unchanged) and `corrections-brief-2.md`; `corrections.md` (gens 1–2: what
already changed; its R11 entry lists the eleven deferred strengthenings);
`../schema.md` § "Verification scale"; then `../sweep.md` rows SW1-1, SW1-2,
SW1-3, SW1-7, SW2-2, SW2-3, SW3-2, SW4-2, SW4-3 (grep the ids). Grep
`record.md`, `verification.md`, `profile.md`, `open-verification.md` for the
claim ids and line ranges named below rather than reading whole files.

Hard rules are gen 1's: re-derive every number by re-fetching (public
sources only; `curl`) or re-counting; rule-7 grep of the whole item
directory per corrected claim (`profile.md` prose and the appendix
included); mark every change in place with
`(corrected 2026-09-23; previously: "<old text>")`; leave `pass/*.md`,
`fact-check.md`, `brief.md`, `fc-targets.md`, `fact-check-brief.md`
untouched; do not touch gen 1's or gen 2's markers or entries except where
R30 names one; refuse any ruling the evidence contradicts; no accounts/keys/
API calls/spend, no Chrome/logins. Table rows: the cell count must not change
on any edited row (escape a literal `|` inside a code span as `\|`).

## Rulings (orchestrator, 2026-09-23, from `research/rulings.md` R24–R38)

- **R25 + R35(T3) — S2 verdict wording: APPLY.** `record.md:17` S2 reads
  "documented, with one nuance"; `what-jev-is` scores the same evidence
  "documented for Choice and Score; contradicted for Noul". One scale: adopt
  the `what-jev-is` wording in the S2 row and wherever `profile.md` states S2,
  citing the decisive evidence — re-fetch `https://api.typesafe.ai/openapi.json`
  and quote `NoulAnswer.required` (sweep: `['noul','type']`) vs
  `ChoiceAnswer.required` / `ScoreAnswer.required` (which include
  `confidence`), plus the homepage's "Every decision includes an estimate of
  how confident the model is." (re-fetch `https://typesafe.ai`, sweep: 2×).
  Record the nuance as R11's T3: launch post "Always communicates confidence
  and uncertainty with every output" (re-fetch the launch post; sweep: 2×).
  Markers.
- **R26 + R20 + R38(a) — 5.12-spec-spread mirror of C14: APPLY.**
  `record.md:94` 5.12-spec-spread lacks two elements `what-jev-is` C14 carries:
  (1) `/primitives/advanced` says "`string`, `object`, `array`, or `null`"
  (re-fetch `https://docs.typesafe.ai/primitives/advanced.md`; sweep: 4×);
  (2) api.md's `ParamField` type list `string | object | array` omits `null`
  (already quoted in the row, but unnamed as a divergence). Add both. Then
  replace every "optional" applied to `instructions` — 5.12 "is optional",
  `profile.md:51` "makes `instructions` optional", O21 (`open-verification.md:30`)
  "optional/nullable" — with the spec's literal facts: absent from every
  `required` list, `anyOf` includes `{type: null}`, no `default` (re-fetch
  `openapi.json` and confirm). The spec has no "optional" keyword. Markers.
- **R29 + R38(c) — re-score `verification.md` on the unified scale: APPLY.**
  Use `../schema.md` § "Verification scale" (seven levels). For every row the
  outcome cell's first word must be one of the seven; change a word only where
  it differs (marker with the old word): `Recorded as a date spread` (D5) →
  `spread`; `Survived with a caveat` (D6) → `downgraded` (the caveat changed
  the record row — both variants now quoted — so it is a precision downgrade);
  `settled` / `strengthened` rows → `survived` or `confirmed` per their
  substance. Then restate `verification.md:46` "Six moves down (two
  overturned, two downgraded, two spreads recorded), four up" as one count per
  level summing to the row count, naming the table(s) counted — the sweep
  reads the D-table as 2 overturned, 2 downgraded, 1 spread, 1 downgraded
  (D6). If your count differs, report yours.
- **R30 — literal `|` in code spans: APPLY (escape only, no content change).**
  `record.md:64` (claim 3.8) has `"type": "choice|score|noul"` in two code
  spans → the row renders 9 cells vs 7; `corrections.md:18` (gen 1's R6 entry)
  has the same string → 6 cells vs 4. Escape each pipe as `\|` (the form
  5.12-spec-spread already uses). Verify with a code-span-aware cell count
  before and after. No marker; one line in your round-3 report.
- **R32 — header tally and historical progress figures: APPLY.** `record.md`
  has no header tally. Count the claim table's verdict column today (sweep:
  64 rows = 56 `documented` / 2 `implied` / 5 `unknown` / 1 `contradicted`,
  first verdict word; split verdicts under their first word — say so), the
  appendix (sweep: 26), and `open-verification.md` (sweep: 21 rows, 2 closed).
  Add a `**Tally:**` line under the record's title in the form
  `what-jev-is/record.md:13` uses. Then mark `record.md:185–186` ("63
  consolidated claims", "25-quote appendix", "20 items", "6 down / 4 up") with
  `(historical, pre-correction figures; see the header tally and
  verification.md scorecard)` — do not rewrite them.
- **R35 (R11 half) — three strengthenings: APPLY; eight: DO NOT.** From
  `corrections.md`'s R11 list apply only T1(i) `NoulAnswer.noul` description
  "values near 0.5 indicate uncertainty", T1(ii) `SystemOneResponse.model`
  "May differ from the alias supplied in the request." (both in `openapi.json`;
  quote verbatim after re-fetch) and T3 (the launch-post sentence in R25) —
  each into the claim row R11 named for it, marker. The other eight stay
  unapplied.
- **R36 + R38(e) — drift note: APPLY (note only).** S3 (`record.md:18`)
  quotes the launch post's "Human-in-the-loop tasks (chatbots, copilots,
  coding agents). General and powerful, but requires human oversight …"
  contiguous; the raw HTML has it 0× contiguous, 1× after tag-stripping
  (appendix 21 already says so). Re-check; add the same caveat clause on the
  S3 row. No marker needed for a note that changes no claim.
- **R38(d) — S3 cross-pointer: APPLY.** Add ONE clause to the S3 row pointing
  at `terms` claim 5.10 (the FAQ temper "Jev guarantees the shape of its
  answers, not that every decision is correct") and at `what-jev-is` S3, so
  all three first-party tempers are reachable from this subject's S3. Marker.
- **R37 — not checked, record as open: APPLY.** Add one row to
  `open-verification.md`: the eight R11 strengthenings not applied (name them
  by R11's labels) were not re-verified by the sweep and are not fit-bearing;
  tag `time`. No fetching for them.

## Report

Append to `corrections.md` (do not rewrite gens 1–2): `## Third round
(gen 3, 2026-09-23)` with one entry per ruling above — applied /
applied-reworded / refused / could-not-apply — with what changed and where
(file + claim id + the re-derived figure) — then `## Not applied (round 3)`
and `## New findings needing a ruling (round 3)` (either may be empty).
Progress blocks labeled `[gen 3]` under `## Progress`.

Return at most 12 lines: status line first (DONE | DONE_WITH_CONCERNS |
BLOCKED | NEEDS_CONTEXT | ROLLOVER_NEEDED); rulings applied / reworded /
refused counts; the new tally line and the restated scorecard line; any
refusal and why; any new finding needing a ruling. Detail in `corrections.md`.
