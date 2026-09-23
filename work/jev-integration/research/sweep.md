# Cross-subject sweep — jev-integration wave 1 (2026-09-23, Phase 4)

Brief: `research/sweep-brief.md`. Subjects: `what-jev-is` (WJI), `terms`,
`integration-paths` (IP). The orchestrator rules; this file recommends.
Nothing here has been applied to any deliverable. Every source cited under
"evidence" was re-fetched today (2026-09-23) with `curl -sL`; byte sizes of
the six pages the corrections agents sized match theirs exactly (home
590,563; launch 258,883; openapi.json 14,158; api.md 11,772;
primitives/advanced.md 19,060; SKILL.md 10,040; llms-full.txt 910,292).

## Summary

- Worst finding: **SW3-1 (high, R17 settled)** — the choice cookbook's
  "clean round trip" comment (L557–558) describes the **TypeSafe** samples,
  and the gpt-5.4-mini single-pick row is appended to `CONDITIONS` (L512–519)
  and run in the same 16-worker pool as every LLM condition (L537–551;
  L590–591 "The LLMs run in a 16-way pool"). Gen 2's reading is right; gen
  1's R15 premise is wrong; R18's denominator caveat should be adopted.
- No appendix quote was **not found**. Of 100+ strings re-checked, all
  load-bearing ones are verbatim today; five carry explainable drift
  (contiguous only after tag-stripping, curly-apostrophe entity, wrapped
  lines) — SW3-2.
- Sweep 1 (consistency): 7 findings — S2/Noul scored two ways (SW1-2),
  R20's two elements missing from IP 5.12 (SW1-3), WJI profile presents a
  stale `<meta>` "in early access" as current (SW1-4), WJI still calls the
  price-qualifier FAQ "unanswered" after `terms` recovered the answer
  (SW1-5), three verification scales (SW1-6, scale defined below).
- Sweep 2 (formatting): 3 broken rows, all the same defect — a literal `|`
  inside a code span (GFM splits on it): terms record L17, IP record L64,
  IP corrections L18. No split rows; no unbalanced correction markers.
- Sweep 3 (evidence): 1 high (SW3-1) + drift notes (SW3-2) + one page
  attribution wrong in C55's count spread (SW3-3).
- Sweep 4 (stale counts): 6 findings — worst is terms verification's
  "37 survived, 3 downgraded, 2 overturned" (sums to 42 of 43; no reading
  of its own column yields 37) — SW4-1.

## Findings

### Sweep 1 — consistency of standard

| id | subject | file:line | what | evidence (re-derived today) | recommended fix | severity |
|---|---|---|---|---|---|---|
| SW1-1 | all three | WJI `record.md:25`; IP `record.md:18`; terms `record.md:7`, `record.md:132` | (a) S3: the three verdict sentences are mutually consistent (hallucination half = schema guarantee; human-in-the-loop half `implied`, conditioned on caller-side confidence gating), but each subject cites a different first-party temper and none cites all: WJI = use-case-map + confidence page + homepage "acts autonomously … asks for review"; IP = launch-post comparison table + confidence page + jaggedness + SKILL.md; terms = FAQ "guarantees the shape of its answers" + MCA. The R22 string is **already in WJI's S3 row** (L25) but absent from WJI's appendix. | Homepage served HTML today: "Set the thresholds for when it acts autonomously and when it asks for review." 1×; FAQ module: "Yes. Jev guarantees the shape of its answers, not that every decision is correct." 2× (variants "acts automatically" 1× / "acts autonomously" 1×); use-case-map.md "without a human co-pilot" 1×; confidence.md "Low confidence: Do not act. Route to a human…" 1×, "High confidence: Act automatically…" 1×; SKILL.md "Typed output guarantees the interface, not truth." 1×; launch "Human-in-the-loop tasks … off the rails." 1× after tag-strip (0× contiguous raw). | R22: only the appendix addition is still needed in WJI (header already carries the sentence). Post-sweep pass: one-clause cross-pointer in WJI S3 and IP S3 to terms 5.10 / FAQ temper so the synthesis has all three tempers in one place. | low |
| SW1-2 | WJI vs IP | WJI `record.md:24`; IP `record.md:17` | (b) Same fact, two verdict labels: WJI S2 = "documented for Choice and Score; **contradicted** for Noul"; IP S2 = "documented, **with one nuance**". terms does not score S2. Sources differ but agree: WJI C19 cites `/api`, `/primitives/noul`, openapi.json; IP 5.5 cites `/primitives/noul`; IP appendix 10 cites `/confidence`. | openapi.json today: `NoulAnswer.required = ['noul','type']`, `ChoiceAnswer.required = ['choice','confidence','probabilities','type']`, `ScoreAnswer.required = ['score','confidence','legend','probabilities','type']`; noul.md "There is no separate `confidence` value for a Noul…" 1×; confidence.md "(Noul answers don't carry one.)" 1×; homepage "Every decision includes an estimate of how confident the model is." 2×. | Orchestrator picks one S2 label for the synthesis. The spec's `required` arrays (only WJI cites them, C19/V5) are the decisive evidence; recommend "documented for Choice/Score; contradicted for Noul (marketing 'every decision' vs `NoulAnswer.required`)" in both, and R11's T3 (launch "Always communicates confidence and uncertainty with every output", 2× today) as the S2 nuance in IP. | med |
| SW1-3 | IP (vs WJI C14) | IP `record.md:94` (5.12-spec-spread), `profile.md:51`; WJI `record.md:54`, `open-verification.md:26` | (c) R20 mirror check. WJI C14 carries all three docs-side facts (api.md `required`; api.md type list omits `null`; `/primitives/advanced` "`string`, `object`, `array`, or `null`") plus the SDKs. IP 5.12 carries api.md `required` (ParamField quoted 3×) and the spec side, but **not** the `/primitives/advanced` element and does **not** name api.md's missing `null` (the ParamField quote shows it, unnamed). Keyword: IP says "`instructions` is optional" (5.12) / "makes `instructions` optional" (profile L51); the spec has no `optional` keyword — R14 made WJI say "omits it from every `required` list" for exactly this reason. | api.md today: `<ParamField body="instructions" type="string \| object \| array" required>` 3×; openapi.json: `instructions` absent from all three `required` lists, `anyOf` types `['string','object','array','null']`, no `default`; advanced.md: "`string`, `object`, `array`, or `null`" 4×, "optional" 1× (elsewhere); WJI C14 verdict `contradicted`, IP 5.12 verdict `contradicted (docs vs. spec)` — consistent. | Post-sweep pass on IP: add the advanced.md element and the "api.md's type list omits `null`" element to 5.12 and O16-equivalent; replace "is optional" with "is absent from every `required` list (typed `anyOf` string/object/array/null, no default)". | med |
| SW1-4 | WJI (vs terms R1) | WJI `profile.md:10-11` | (d) "Jev is still marked 'in early access' on the homepage as of today." Today the string exists **only inside three `<meta>` description attributes** (`description`, `og:description`, `twitter:description`: "Try our first System One Model, Jev, in early access."), 0× in visible copy after tag-stripping. terms 6.3 records access as open since 2026-09-20. WJI presents a stale meta description as current state; no other WJI/IP row does (C61 and IP 7.1 quote the dated launch post). | home.html: `in early access` 3× raw, 0× tag-stripped; FAQ module: "NO MORE WAITLIST" 1×, "TypeSafe is now open to everyone. Let the Jevolution begin." 1×, "Sept 20, 2026 • TypeSafe News" 1×, stale FAQ "Join the waitlist! Jev is in its early days" 2×; X 2101786156572823624 (2026-09-20 21:30:43 UTC, `typesafeai`): "Jev is now available to everyone. No waitlist." | Reword profile L10–11: "the homepage's `<meta>` description still says 'in early access' (stale — access opened 2026-09-20, see `terms` 6.3)". | med |
| SW1-5 | WJI (vs terms O1/1.7) | WJI `record.md:26` (S4), `profile.md:77-78`, `open-verification.md:19` (O9) | (e) The $42 figure, wording and source are identical across all three subjects ("$42 / $0.042" per Btok / Mtok, docs `/models`, "Charged per input token. Output tokens are free."). The **qualifier** diverges: WJI S4 says the FAQ heading "Are these prices temporary or subsidized?" "has no answer in served HTML (C25)", profile calls it "an unanswered FAQ heading", O9 keeps it open — while terms O1 is closed with the answer recovered from the Framer module (terms 1.7). WJI's "(C25)" pointer is also wrong: C25 is the models-page row and says nothing about the FAQ; O9 is the right pointer. | models.md today: `\$42 / \$0.042` 1×, "Charged per input token. Output tokens are free." 1×; FAQ module: "We can serve Jev profitably at our current prices. Our goal is to make intelligence more affordable over time as we improve the technology." 1×; "production price" 0× on homepage and module. | Post-sweep pass on WJI: S4 row and profile adopt terms 1.7's recovered answer with the module URL; O9's pricing sub-item closed with a pointer to terms O1; fix "(C25)" → "(O9)". | med |
| SW1-6 | all three | WJI `verification.md:11`; terms `verification.md:4`; IP `verification.md:46` | (f) Three vocabularies, one wave: WJI uses `survived` / `reversed` / `Survives` / `downgraded` / `overturned` + N-rows "cluster-verified"; terms uses `survived` (incl. "survived, with a downgrade in precision", "survived — rule-8 miss") / `downgraded` / `overturned`; IP uses `Overturned` / `Downgraded` / `Recorded as a spread` / `Survived with a caveat` / `settled` / `strengthened`. Two summaries do not match their own column (SW4-1, SW4-3). | Column re-counts under `## Method`. | Adopt the scale under `## Scale definition`; re-score all three verification files together in one pass (not done here, per brief). | med |
| SW1-7 | IP (R11), WJI (R16) | IP `corrections.md:28`; WJI `corrections.md:98`, `record.md:253` | Deferred strengthenings. R11 (eleven): three are verified present today and bear on S2 (T1(i) `NoulAnswer.noul` "values near 0.5 indicate uncertainty"; T1(ii) `SystemOneResponse.model` "May differ from the alias supplied in the request."; T3 launch "Always communicates confidence and uncertainty with every output" 2×); the other eight are not fit-decision-bearing. R16: TNS page today renders `doesn&#8217;t` (curly-apostrophe entity); the appendix transcribes `doesn't` (straight). N1: the two N-rows are "kept at cluster verdict, flagged" and the fact-check confirmed N1's three third-party rows (verification L74). | openapi.json descriptions quoted verbatim today; launch.html 2×; tns.html `doesn&#8217;t` 1×, straight `doesn't` 0× raw / 1× after entity-decode. | R11: apply T1(i), T1(ii), T3 in the post-sweep pass (they close the S2 nuance); leave the remaining eight as strengthenings, not applied. R16 apostrophe: apply (rule 4, verbatim) — trivial. R16 N1: do not promote to `survived` (the lead did not check it); under the unified scale it maps to level 2 "confirmed by independent check" — re-label only when SW1-6's re-score runs. | low |

### Sweep 2 — formatting integrity

| id | subject | file:line | what | evidence (re-derived today) | recommended fix | severity |
|---|---|---|---|---|---|---|
| SW2-1 | terms | `record.md:17` (claim 1.3) | Literal `\|` inside a code span in the "How verified" cell: `per request\|per decision\|cached\|batch`. GFM splits table cells on unescaped pipes even inside code spans, so the row renders as **10 cells vs 7** expected; the verdict and source columns shift. | `tablecheck.py`: header=7 raw=10 code-span-aware=7. | Escape as `per request\|per decision\|cached\|batch` (`\|`) — the form 5.12-spec-spread already uses. | med |
| SW2-2 | IP | `record.md:64` (claim 3.8) | Same defect, twice in one cell: `"type": "choice\|score\|noul"` appears in two code spans → **9 cells vs 7**. This is the corrected R6 row (evals "full queries"); it is the row whose correction marker my balance check flagged, but the imbalance is an artefact of the pipe split, not of the marker. | header=7 raw=9 code-span-aware=7. | Escape both pipes. | med |
| SW2-3 | IP | `corrections.md:18` (R6 entry) | Same string in the corrections table → **6 cells vs 4**. | header=4 raw=6 code-span-aware=4. | Escape. | low |
| SW2-4 | all three | — | No row split by a stray newline (every table row ends in `\|`; no non-pipe line sits between rows); all 45 tables detected; no pipe-leading line outside a detected table; all 68 `(corrected …; previously: …)` markers balance on quotes, backticks and parentheses (the one flag was SW2-2's pipe artefact). Rule 7: N = 3 is a lower bound only for pipes inside constructs my code-span-aware splitter does not model (none seen). | scripts under `## Method`. | none | info |

### Sweep 3 — evidence-appendix spot-check

| id | subject | file:line | what | evidence (re-derived today) | recommended fix | severity |
|---|---|---|---|---|---|---|
| SW3-1 | WJI | `record.md:115` (C50); `corrections.md:95-97`, `:105-107` | **R17 settled — gen 2's reading is right.** The "clean round trip" comment describes the TypeSafe samples (the denominator). The gpt-5.4-mini single-pick row is one of the `CONDITIONS` and is measured inside the same 16-worker pool as every other LLM condition. So the 7.2x / 20.3x minima **were** measured under contention on the LLM side; the asymmetry (contended LLM ÷ uncontended TypeSafe) applies to every ratio, not to the low end. Gen 1's R15 premise is contradicted by the source. | `consistency_choice_cookbook.md` today (49,891 B) — L512–519: `CONDITIONS.append({"label": f"{model} single-pick t=0", "model": model, "temp": 0, "mode": "single"})`; L537: `with ThreadPoolExecutor(max_workers=16) as pool:`; L538–551 submit `for condition in CONDITIONS`; **L557–558: `# TypeSafe samples are drawn sequentially, after the LLM pool has closed, so each call's latency is a` / `# clean round trip rather than one measured under the 16-way LLM thread contention.`**; L559–562 `_call_typesafe(...) for sample_index in range(NUM_SAMPLES)`; L589–591: "`time/call` and `cost/call` average the 15 calls, and the `vs ts_choice` columns divide by the TypeSafe figures. The LLMs run in a 16-way pool." Noul cookbook L443–444 carries the same design: `# TypeSafe samples are drawn sequentially after the LLM calls.` C50's figures today: choice page `7.2x` 2×, `20.3x` 1×, `897.4x` 1×, `125.0x` 0×; noul page `125.0x` 1× — the 125.0x maximum comes from the **noul** cookbook, the other three from the **choice** cookbook (C50 says "consistency cookbooks" without saying which). | Rule R18 as "adopt": apply gen 2's C50 denominator wording (`what-jev-is/corrections.md` round 2, finding 1) in the post-sweep pass; also name which cookbook each of the four bound figures comes from. Close R15/R17. | high |
| SW3-2 | all three | WJI `record.md:22`, `:234`, `:253`; IP `record.md:18`, `:172`; terms `record.md:154`, `:171`, `:189` | Every load-bearing quote sampled is present today; none is fabricated or missing. **Drift (quote → what the page has):** (i) launch post "Human-in-the-loop tasks (chatbots, copilots, coding agents). General and powerful, but requires human oversight because their freedom also means they might go off the rails." — 0× contiguous in raw HTML, 1× after tag-stripping (IP S3 quotes it contiguous with no caveat, unlike its appendix 21 which does caveat "can't hallucinate"); (ii) launch post "Our first public model is Jev" (WJI S1 row) — 0× raw, 1× tag-stripped; (iii) TNS "The model doesn't write. It decides." — page has `doesn&#8217;t` (R16); (iv) MCA "Last updated Sep 19, 2026" / Privacy "Last updated Nov 19, 2025" — 0× raw, 1× tag-stripped each; (v) Vercel README caps sentence wraps lines 49–51 (already stated in 5.12/A26). | Verbatim 1× or more today: `$42 / $0.042` + "Charged per input token. Output tokens are free." (models.md); "Zero Hallucinations" 2×, "Every Jev decision comes with a confidence estimate, so your software can act when confidence is high and escalate when it is not." 1×, "…can act automatically when confidence is high…" 1× (home); "Our number is not empirical. Schema matching is guaranteed, thus we can confidently add 0% into the plots." 2×, "available today in early access" 2×, "bringing developers off the waitlist as quickly as we can" 2×, "Input tokens: $0.042 / MTok ($42 per billion tokens)." 2×, "Output tokens: FREE (too cheap to meter)." 2×, "Sep 15, 2026" 3× (launch); OpenAPI `required` arrays as in SW1-2, `HTTPValidationError` "Request validation failures returned with HTTP status 422.", `ScoreQuestion.criteria.minItems = 1`, no `maxItems`, `ChoiceQuestion.criteria` no size limit, probabilities "values sum to approximately 1" 2×; api.md "You can have a maximum of 255 options per Choice." 1×, "A Score should have at least two levels; the API accepts up to 10." 1×, "floats that sum to 1" 2×, error rows 401/422/429/529 present, "exponential backoff" 1×; choice.md "Add an `other` or `none of the above` option…" 1×; noul.md "Use 0.5 when yes and no are equally easy to act on" 1×; MCA "TypeSafe will not, include Customer Data in a dataset used to train (i.e., to modify the model weights of) any artificial intelligence or machine learning models without Customer’s prior consent." 2×, "TypeSafe may Process Telemetry without restriction, including to improve the Services or TypeSafe’s other products and services." 2×, "THE SERVICES MAY PRODUCE INACCURATE OR ERRONEOUS OUTPUT" 2×, "IS RESPONSIBLE FOR INDEPENDENTLY EVALUATING THE OUTPUT" 2×, the (a)/(b) restrictions clause 2×, "will perform materially as described in its Documentation" 2×; Privacy "We will not train or fine tune any artificial intelligence or machine learning models on your prompts or other Input." 2×; X 2101786156572823624 "Jev is now available to everyone. No waitlist." + "Start using it here: https://console.typesafe.ai" (2026-09-20 21:30:43 UTC) and 2101786280946499671 "All users start with $5 in credit (~120 million tokens)." (21:31:13 UTC), both via `api.fxtwitter.com` (mirror; x.com is logged-out-blocked); HN 49785707 `preommr` 2026-09-21T11:12:03Z story 49784706, text "kind of useless, and just a convenience step from the probabilities" 1×; HN 49717558 "Introducing System One Models and Jev" 1976 pts 2026-09-15T19:25:03Z `albelfio`; primitives.md "11.5x cheaper and 9.6x faster than 13 separate calls" 1× vs parallel_questions.md "12.2x cheaper, 10.0x faster" 1×; rerank "40 queries"/"30 candidates"/"$0.0645"/`jev-1.12`; classification "60 filings" 3×, "75 industry groups" 2×, "2026-08-12" 1×; SKILL.md all four strings 1× each; agent-skill.md "Drop-in skill for Claude Code, Codex, and other agent environments." 1×; TNS "backed by $40 million in seed funding led by DCVC" 1×. | (i)/(ii): add the same "contiguous after tag-stripping" caveat IP appendix 21 uses (or cite the `.md`/text rendering). (iii) R16. (iv)/(v) none. | low |
| SW3-3 | WJI | `record.md:125` (C55) | C55's count spread re-derived on a byte-identical corpus (910,292 B): `jev-1.13.0` ×20 ✓, `jev-1.12` ×27 on exactly the 16 listed cookbook pages ✓, `jev-latest` ×34 ✓, `jev-preview` ×2 ✓, bare `jev-1.13` ×17 ✓ — but the 17 sit on `model-jaggedness/jev-1.13` (16) and `/models` (1), **not** "jaggedness, primitives, two cookbooks" as C55 says. | Script under `## Method` (`jev-1\.13(?![\.\d])` per `Source:` page). | Correct the page attribution in C55's parenthetical. | low |
| SW3-4 | IP, terms | IP `record.md:57` (3.1); terms `record.md:94`, `:186` | Counts confirmed: 18 cookbooks (18 unique `/cookbooks/` URLs in llms.txt; 18 cookbook pages in llms-full) ✓. terms' access strings (SW1-4 evidence) ✓. Console JS chunk counts not re-fetched (console is login-gated; the 18/6/6/1/1 figures are gen 2's). | as stated | none | info |

### Sweep 4 — stale summary counts

| id | subject | file:line | what | evidence (re-derived today) | recommended fix | severity |
|---|---|---|---|---|---|---|
| SW4-1 | terms | `verification.md:4`; echoed `record.md:212` | Printed: "43 checked — 37 survived, 3 downgraded, 2 overturned" (sums to 42). Counted from the Result column: V1–V43 = 43 rows → 41 whose Result begins `survived` (this includes V40 "survived, with a downgrade in precision", V41 "survived, downgraded", V7/V8 "survived — rule-8 miss … not re-ratified"), V17 `downgraded`, V23 `overturned`; the S4 table adds 2 rows (1 survived, 1 overturned). Under the lead's own classification in "Net movement" (V17/V40/V41 down; V23 + S4 qualifier overturned) the survived figure is 39 of 43 (or 40 of 45 with the S4 table) — no reading yields 37. Neither site is marked historical. | `verdictcount`-style last-cell count, `## Method`. | Restate as the column reads under the unified scale (SW1-6); mark record.md:212 historical. | med |
| SW4-2 | IP | `record.md:185-186` | Progress block figures read as current: "63 consolidated claims" / "63 claims" (today **64** rows — 5.12-spec-spread added), "25-quote appendix" (today **26** — A26 added), "20 items" (today **21** rows, 19 open after O2/O14 closed). Not marked historical. IP's record has **no header tally line** at all — the only totals live in this progress block. | `verdictcount.py`: 64 rows = 56 `documented` / 2 `implied` / 5 `unknown` / 1 `contradicted` (first verdict word; split verdicts fall under their first word). Appendix numbered 1–26. `grep -c '^\| O'` = 21, 2 closed. | Add a `**Tally:**` line to IP record.md (64 / 56 / 2 / 5 / 1, with the split-verdict caveat) and mark the progress figures historical. | med |
| SW4-3 | IP | `verification.md:46`; `record.md:186` | "Six moves down (two overturned, two downgraded, two spreads recorded)" / "6 down / 4 up". Column D1–D6: 2 `Overturned`, 2 `Downgraded`, 1 `Recorded as a date spread` (D5), 1 **`Survived with a caveat`** (D6). One of the six "moves down" survived. | last-cell count, `## Method`. | Reword to "five moves down + one survived-with-caveat (D6)" or move D6 to the survived section; fix the record.md echo. | low |
| SW4-4 | WJI | `verification.md:72` | "Moves away from confidence: 5 (D1–D5)" — D4's outcome is now `Survives` (R7), so 4; L74 explains the adjustment but L72 is not marked historical. The scorecard at L11 itself matches its column with R19's parenthetical (no finding). | D-table: 1 overturned, 3 downgraded, 1 survives. | Mark L72 historical or restate "4 (D1–D3, D5)". | low |
| SW4-5 | WJI | `record.md:287` | "open-verification.md (18 items, access-tagged)" — 18 rows today, O11 closed → 17 open. L285 carries a historical marker; L287 does not. | `grep -c '^\| O'` = 18; 1 closed. | Mark historical. | low |
| SW4-6 | terms | `record.md:213` | "28 open items" — today 30 rows, 2 closed (O1, O7), 28 open: the printed figure is right only by coincidence (it meant 28 total when written; O29/O30 were added later). Not marked. | 30 rows, 2 closed. | Mark historical or restate "30 items, 28 open". | low |
| SW4-7 | terms | `record.md:97` (6.6), `verification.md:23` (V10) | R21 confirmation: the doubled billing-analytics counts ("fresh grep 2 each"; "billing topup started 2; billing auto reload toggled 2") still stand against the appendix's 1 each on 18 chunks (L186). Already ruled (R21); listed so the post-sweep pass does not miss the second site. | grep as shown. | Apply R21 at both sites. | low |
| SW4-8 | WJI, terms | WJI `record.md:13`; terms `record.md:5` | Header tallies **match** their columns: WJI 49 / 2 / 7 / 4 = 62 ✓; terms 54 / 3 / 7 / 2 = 66 ✓. terms' "11 split" list not re-counted (split halves are prose inside the verdict cell). | `verdictcount.py`. | none | info |

## Scale definition

Sweep 1(f) found three vocabularies and two summaries that diverge from
their own columns. Proposed single scale for a verification row's outcome
(one word first, qualifiers after a dash):

1. **`survived`** — the lead re-checked the row against an independent copy
   of the source and the claim stands as worded. (No "with a caveat" here: a
   caveat that changes the wording is level 3.)
2. **`confirmed`** — not re-checked by the lead; confirmed by an independent
   later stage (the fact-check). WJI's N-rows belong here (R16 N1).
3. **`downgraded`** — the claim stands with weaker wording, scope or
   precision (terms V17/V40/V41; IP D3/D4; WJI D2/D3/D5; IP D6 "survived
   with a caveat" is here only if the caveat changed the record row —
   it did (both variants now quoted), so D6 is a downgrade of precision).
4. **`spread`** — neither figure adopted, both recorded (rule 6): IP D5.
5. **`overturned`** — the claim as worded is wrong; the record row was
   rewritten or re-verdicted (terms V23 + S4 qualifier; IP D1/D2; WJI D1).
6. **`reversed`** — a lead outcome later undone by the fact-check (WJI V15,
   D4); keep the original word struck through and this word after it.
7. **`not re-checked`** — declared, per rule 7.

A scorecard line then counts each level once, sums to the row count, and
names the table(s) it counts (terms must say whether the S4 table is in the
43). Re-scoring all three files against this scale is the orchestrator's
call and was not done here.

## Patterns

New (not in `rulings.md`):

1. **"Verbatim" needs a rendering qualifier.** Quotes that span inline tags
   (`<em>`, `<a>`, table cells) are 0× in raw HTML and 1× after
   tag-stripping; one subject caveats this (IP appendix 21) while sibling
   rows quote the same page contiguous without a caveat (SW3-2 i/ii). Record
   "contiguous after tag-strip" or cite the `.md` twin.
2. **`<meta>` descriptions are not copy.** The homepage's
   description/og/twitter tags still say "in early access" while the visible
   module carries "NO MORE WAITLIST" (SW1-4). State claims must not be built
   from meta tags — the access/state pattern in `rulings.md`, one layer
   deeper.
3. **Pipes inside code spans break GFM tables.** Three rows, all enums
   (`a|b|c`); one row (5.12) already escapes them (SW2-1..3). Make `\|` a
   brief rule for enums/regexes/JSON in cells.
4. **Progress blocks are unmarked history.** Every stale figure in sweep 4
   except SW4-1 lives in a progress block or a direction-check paragraph;
   only the figures that carry a "(historical …)" marker survived the
   corrections rounds. Brief rule: a corrections pass marks the progress
   figures it supersedes.
5. **Verdict labels for standing claims need a shared table.** S2 scored
   two ways on identical evidence (SW1-2) because each subject scored the
   standing claims independently.

Confirmed from `rulings.md`:

- **Absence over-correction** — WJI S4 "has no answer in served HTML" was
  true of the HTML and false of the site (SW1-5), exactly the JS-rendered
  pattern the terms check named.
- **Access/state from stale first-party copy** — SW1-4.
- **Machine-readable spec vs. prose docs** — both C14 and 5.12 hold today
  on a byte-identical spec and api.md; the spread is real and stable.
- **Quotes are real; citations drift** (WJI verification pattern 2) — no
  fabricated quote across 100+ strings; the defects are attribution
  (SW3-3) and rendering (SW3-2).

## Method

All paths relative to the workspace root; scratchpad `S=/private/tmp/claude-501/-Users-kashif-Developer-experiments-ai-workspace-template/0da0d0bf-5192-4e33-aaee-9a527e45e9cf/scratchpad`.

Sweep 2 — `$S/tablecheck.py` (Python 3, stdlib): for every Markdown table
(a `|` line followed by a `---` separator line) count cells per row two
ways — raw split on unescaped `|` (how GFM renders) and a code-span-aware
split — and print rows where either count differs from the header or a
backtick is unbalanced; also flag a non-pipe line sitting between table
rows. Run:
`for s in what-jev-is terms integration-paths; do for f in record profile verification open-verification corrections; do python3 $S/tablecheck.py work/jev-integration/research/$s/$f.md; done; done`
Correction-marker balance: for each table line containing `previously`,
split on raw pipes and check `"`/backtick parity and `(`/`)` balance in the
cell holding the marker (inline Python; the one hit was SW2-2's pipe
artefact). Pipe lines outside detected tables: none (checked by comparing
line numbers to the detected table ranges).

Sweep 4 — `$S/verdictcount.py`: for each 7-column table whose third header
cell starts with "Verdict", tally the third cell by its first word
(`documented|implied|unknown|contradicted|split`), per table and total.
Verification outcome columns: same splitter on the **last** cell of every
table row in `*/verification.md`, keyed by the first word after stripping
`*` and backticks. Open items: `grep -c '^| O' */open-verification.md`
and `grep '^| O' … | grep -ci 'closed\|~~'`. Tally sentences located with
`grep -nE '[0-9]+ ?/ ?[0-9]+ ?/ ?[0-9]+|[0-9]+ (documented|survived|…)'`.

Sweep 1 — greps across the five deliverables per subject:
`guarantees the shape|without a human co-pilot|acts autonomously|acts automatically|asks for review|no human in the loop|Human-in-the-loop tasks`;
`noul[^|]{0,80}confidence|confidence[^|]{0,80}noul` (-i);
`^| C14 `, `^| O16 `, `^| 5.12`, `instructions` in profiles;
`waitlist|early access|invite-only|gated` (-i); `\$42`; per-file counts of
`survived|downgraded|overturned|cluster-verified|confirmed|settled`.

Sweep 3 — fetch: `curl -sL -A "Mozilla/5.0" -o $S/f/<name> -w "%{http_code}" <url>`
for: docs.typesafe.ai `/models.md`, `/api.md`, `/primitives/advanced.md`,
`/confidence.md`, `/primitives/noul.md`, `/primitives/choice.md`,
`/concepts/use-case-map.md`, `/agent-skill.md`, `/primitives.md`,
`/llms.txt`, `/llms-full.txt`, `/cookbooks/{consistency_choice_cookbook,consistency_noul_cookbook,rerank_typesafe,classification_using_confidence,parallel_questions}.md`;
`https://typesafe.ai/`, the launch post, `/legal/mca`, `/legal/privacy-policy`;
the Framer FAQ module `https://framerusercontent.com/sites/43bTeC8cU9jZO20XvdK79t/1bDVrPYMWEZ6eWmJvyMH7WadCbl21tfR2JXCIVJyZRA.BkrK7V15.mjs`;
`https://api.typesafe.ai/openapi.json`; raw GitHub `typesafe-ai/skills …/SKILL.md`
and `vercel/ai …/packages/typesafe-ai/README.md`;
`https://api.fxtwitter.com/typesafeai/status/{2101786156572823624,2101786280946499671}`
(mirror — x.com is blocked logged-out); `https://hn.algolia.com/api/v1/items/{49785707,49717558}`;
`https://thenewstack.io/typesafe-jev-system-one/`. All 29 returned 200.
Quote check: `$S/quotecheck.py` — for each (file, quote) print `raw` (exact
byte count) and `norm` (after `html.unescape`, curly→straight quotes,
`\$`→`$`, whitespace collapse); tag-stripped re-check for the raw-0 cases
with `re.sub(r'<[^>]+>',' ',…)`. OpenAPI: `json.load` → `required` arrays,
`instructions.anyOf` types, `criteria.minItems/maxItems`, `probabilities.description`.
Corpus counts: split llms-full.txt on `\n(?=Source: )`, count pages whose
text matches `jev-1\.12(?!\d)` / `jev-1\.13(?![\.\d])`; cookbooks =
`grep -oE 'https://docs\.typesafe\.ai/cookbooks/[a-z0-9_]+' llms.txt | sort -u | wc -l`.
R17: `sed -n '500,600p' $S/f/cc_choice.md | nl -ba -v500` and `sed -n '430,455p' $S/f/cc_noul.md`.

Not checked: console JS chunk counts (login-gated page; gen 2's figures
stand); the eight non-fit-bearing R11 strengthenings' sources (Score page,
jaggedness page, JS changelog); terms' "11 split" list. A
`research/synthesis-draft.md` exists (not a brief target; untouched, unread).

## Progress

- [gen 1] 2026-09-23 — started. Read the brief, method-rules, schema,
  rulings. Report file created.
- [gen 1] 2026-09-23 — sweep 2 (formatting) script done over all 15 deliverables: 45 tables, 3 rows with a literal `|` inside a code span (terms record L17; integration-paths record L64; integration-paths corrections L18); no split rows; no unbalanced correction markers. Sweep 4 (counts) re-counted: what-jev-is 49/2/7/4=62 OK; terms 54/3/7/2=66 OK; integration-paths 64 rows (56/2/5/1) vs progress "63 claims"/"25-quote"; terms verification summary 37/3/2 (=42) vs column; IP "six moves down" includes a survived row; open-verification 18/30/21 rows with 1/2/2 closed. Sweep 1 greps done (S3, Noul, instructions, access state, $42, vocabulary).
- [gen 1] 2026-09-23 — sweep 3 done: 29 sources re-fetched (all 200; sizes match the corrections agents'); 100+ quotes checked, none not-found, five drift notes; R17 settled for gen 2's reading (choice cookbook L512–519, L537–551, L557–558, L590–591 quoted in SW3-1). Report written: 7 + 4 + 4 + 8 findings, scale definition, 5 new patterns, method. Task complete; nothing applied. Open items for the orchestrator: rule on SW1-2 (S2 label), SW1-6 (scale + joint re-score), R18 adopt, R11 partial apply, R16 apply apostrophe / hold N1.
