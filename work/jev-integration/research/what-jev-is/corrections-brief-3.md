# Corrections brief 3 — `what-jev-is` (jev-integration wave 1, 2026-09-23, third round: post-sweep)

Working directory: `/Users/kashif/Developer/experiments/ai-workspace-template`.
Item directory (the ONLY place you write): `work/jev-integration/research/what-jev-is/`.
You may READ the sibling item directories (`../terms/`, `../integration-paths/`) and `../sweep.md`, `../schema.md` — never write there.

You apply the orchestrator's post-sweep rulings. Read first:
`skills/research-wave/references/method-rules.md`; this item's
`corrections-brief.md` (gen 1 — its **Hard rules** section applies to you
unchanged) and `corrections-brief-2.md`; `corrections.md` (gens 1–2: what
already changed; its `## New findings needing a ruling (round 2)` item 1 is
the wording R18 adopts); `../schema.md` § "Verification scale"; then
`../sweep.md` rows SW1-1, SW1-4, SW1-5, SW1-7, SW3-1, SW3-2, SW3-3, SW4-4,
SW4-5 (grep the ids). Grep `record.md`, `verification.md`, `profile.md`,
`open-verification.md` for the claim ids and line ranges named below rather
than reading whole files.

Hard rules are gen 1's: re-derive every number by re-fetching (public
sources only; `curl`) or re-counting; rule-7 grep of the whole item
directory per corrected claim (`profile.md` prose and the appendix
included); mark every change in place with
`(corrected 2026-09-23; previously: "<old text>")`; leave `pass/*.md`,
`fact-check.md`, `brief.md`, `fc-targets.md`, `fact-check-brief.md`
untouched; do not touch gen 1's or gen 2's markers or entries; refuse any
ruling the evidence contradicts; no accounts/keys/API calls/spend, no
Chrome/logins. Table rows: the cell count must not change on any edited row
(escape a literal `|` inside a code span as `\|`).

## Rulings (orchestrator, 2026-09-23, from `research/rulings.md` R24–R38)

- **R18 (active via R24; settles R15/R17) — C50 denominator caveat: APPLY.**
  The sweep re-read the choice cookbook: L557–558 "clean round trip" describes
  the **TypeSafe** samples (the denominator); the gpt-5.4-mini single-pick row
  is in `CONDITIONS` (L512–519) and runs in the 16-worker pool (L537–551,
  L590–591). Gen 2's reading holds. Re-fetch
  `https://docs.typesafe.ai/cookbooks/consistency_choice_cookbook.md` and
  `…/consistency_noul_cookbook.md` (the `.md` variants gen 2 used) and confirm
  those lines and noul L443–444. Then apply gen 2's proposed C50 wording
  (`corrections.md` round-2 finding 1) to `record.md:115` C50 ("… than LLMs
  measured under 16-way contention …"). ALSO name the cookbook per figure:
  **125.0x from the noul cookbook; 7.2x / 20.3x / 897.4x from the choice
  cookbook** (C50 today says only "consistency cookbooks"). Rule-7 grep `7.2x`,
  `20.3x`, `125.0x`, `897.4x`, `16-way`, `contention` across the item incl.
  `profile.md`. In your report, record R15/R17 as closed by this edit.
- **R20 — C14 third element: CONFIRM.** The sweep (SW1-3) says C14
  (`record.md:54`) already carries all three docs-side facts (api.md
  `required`; api.md's type list `string`/`object`/`array` omits `null`;
  `/primitives/advanced` "`string`, `object`, `array`, or `null`"). Verify by
  reading C14 and O16 (`open-verification.md:26`). If all three are named, NO
  EDIT — say so. If one is missing, add it with a marker.
- **R22 + R38(d) — S3 appendix row and cross-pointer: APPLY.** The served
  homepage HTML carries "Set the thresholds for when it acts autonomously and
  when it asks for review." (1×; re-fetch `https://typesafe.ai` raw HTML and
  count). It is already in the S3 row (`record.md:25`) — confirm, no edit
  there for the sentence. Add it to the verbatim appendix as a `documented`
  first-party quote (homepage, served HTML, count shown). Then add ONE clause
  to the S3 row pointing at `terms` claim 5.10 (the FAQ temper "Jev guarantees
  the shape of its answers, not that every decision is correct") so all three
  first-party tempers are reachable from this subject's S3. Marker on the row.
- **R27 — profile "in early access": APPLY-REWORDED.** `profile.md:10–11`
  presents "in early access" as current. Today the string exists only inside
  three `<meta>` description attributes of the homepage (`description`,
  `og:description`, `twitter:description`; 0× in tag-stripped visible copy),
  and `terms` 6.3 records access open self-serve since 2026-09-20 (X post
  2101786156572823624 "Jev is now available to everyone. No waitlist."). Re-fetch
  and count. Reword to: the homepage's `<meta>` description still says "in
  early access" (stale — access opened 2026-09-20, see `terms` 6.3). Marker.
  Rule-7 grep `early access` across the item.
- **R28 + R38(b) — price-qualifier FAQ answer: APPLY.** `record.md:26` S4,
  `profile.md:77–78` and O9 (`open-verification.md:19`) still call "Are these
  prices temporary or subsidized?" unanswered. `terms` 1.7 recovered the
  answer from the homepage's Framer FAQ module: "We can serve Jev profitably at
  our current prices. Our goal is to make intelligence more affordable over
  time as we improve the technology." Find the module URL in
  `../terms/record.md` (grep `1.7` / `framer`), re-fetch it, count the string
  (sweep: 1×). Then: S4 quotes the answer with the module URL and cites
  `terms` 1.7; replace S4's "(C25)" pointer with "(O9)"; profile L77–78 drops
  "unanswered"; O9's pricing sub-item is closed with a pointer to `terms` O1
  (keep O9's other sub-items open). Markers on each.
- **R29 — re-score `verification.md` on the unified scale: APPLY.** Use
  `../schema.md` § "Verification scale" (seven levels). For every V/D/N row,
  the outcome cell's first word must be one of the seven; change a word only
  where it differs (marker with the old word). N1 and N2 ("kept at cluster
  verdict, flagged"; the fact-check confirmed N1's three third-party rows,
  `verification.md:74`) → `confirmed` (level 2) — this closes R16's N1 half.
  V15 and D4 → `reversed` (original word struck through, per level 6). Then
  restate the scorecard (`verification.md:11`) as one count per level summing
  to the row count, naming the table(s) counted; keep the R13/R19 history
  inside a marker. If your count contradicts the sweep's (WJI D-table: 1
  overturned, 3 downgraded, 1 survives→reversed), report yours; do not force.
- **R33 — stale figures: MARK HISTORICAL, do not rewrite.**
  `record.md:287` "(18 items, access-tagged)" — 18 rows, O11 closed → 17 open;
  `verification.md:72` "Moves away from confidence: 5 (D1–D5)" — D4 now
  survives/reversed → 4. Append `(historical, pre-correction figure; see …)`
  to each; no other change.
- **R34 — C55 page attribution: APPLY-REWORDED.** `record.md:125` C55 says
  bare `jev-1.13` ×17 sits on "jaggedness, primitives, two cookbooks". The
  sweep's re-count on the byte-identical `llms-full.txt` (910,292 B; regex
  `jev-1\.13(?![\.\d])` per `Source:` page): 17 = **16 on
  `model-jaggedness/jev-1.13` + 1 on `/models`**. Re-derive, then correct the
  parenthetical (count unchanged). Marker.
- **R35 (R16 half) — TNS apostrophe: APPLY.** Appendix `record.md:253`
  transcribes `doesn't`; the page renders `doesn&#8217;t` (curly). Re-fetch
  `https://thenewstack.io/typesafe-jev-system-one/` and confirm (raw `doesn't`
  0×, entity 1×). Make the quote verbatim (`doesn’t`). Marker.
- **R36 + R38(e) — drift note: APPLY (note only, no quote edited).** The S1
  row's launch-post quote "Our first public model is Jev" (`record.md:23`) and
  the appendix launch-post lines around `record.md:234` match 0× contiguous in
  raw HTML and 1× after tag-stripping. Re-check each; where only the
  tag-stripped match holds, add a one-line how-verified note on that row:
  "(verbatim after tag-stripping; not contiguous in raw HTML)". No marker
  needed for a note that changes no claim.

## Report

Append to `corrections.md` (do not rewrite gens 1–2): `## Third round
(gen 3, 2026-09-23)` with one entry per ruling above — applied /
applied-reworded / confirmed-no-edit / refused / could-not-apply — with what
changed and where (file + claim id + the re-derived figure) — then `## Not
applied (round 3)` and `## New findings needing a ruling (round 3)` (either
may be empty). Progress blocks labeled `[gen 3]` under `## Progress`.

Return at most 12 lines: status line first (DONE | DONE_WITH_CONCERNS |
BLOCKED | NEEDS_CONTEXT | ROLLOVER_NEEDED); rulings applied / reworded /
confirmed / refused counts; the restated scorecard line; any refusal and
why; any new finding needing a ruling. Detail in `corrections.md`.
