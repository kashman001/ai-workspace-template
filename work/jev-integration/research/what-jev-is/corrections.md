# Corrections — `what-jev-is` (jev-integration wave 1, 2026-09-23)

**Applied by:** corrections agent (gen 1, task `corr-what-jev-is`), per `corrections-brief.md` rulings R1–R11.
**Method:** every figure re-derived from a fresh fetch on 2026-09-23 (curl, browser UA where noted; 33 fetches, all HTTP 200, sizes matching the fact-check's), then applied with an in-place `(corrected 2026-09-23; previously: "…")` marker; the whole item directory was grepped for each corrected claim before closing it (method rule 7). Files changed: `record.md`, `profile.md`, `verification.md`, `open-verification.md`. Untouched: `pass/*.md`, `fact-check.md`, `brief.md`, `fc-targets.md`, `fact-check-brief.md`. Progress blocks in `record.md` are history and were left as written.

**Tally:** 11 rulings — 7 applied (R2, R3, R5, R6, R7, R9, R11), 3 applied-reworded (R1, R4, R10), 1 refused as worded with the fact-check's own alternative applied instead (R8). Markers written: record.md 19, verification.md 4, profile.md 2, open-verification.md 2.

## Rulings

### R1 — S3 / C34 / T2 / profile prose — applied-reworded
Re-derived: literal "human in the loop" 0 hits on homepage, launch post and the 910 KB docs corpus; equivalents present — use-case-map.md L15 "run it a million times in the background without a human co-pilot" [1]; confidence.md L169 "**High confidence:** Act automatically. The model has a clear read and you can proceed without human involvement." [1]; homepage "Set the thresholds for when it acts autonomously and when it asks for review" [1]; launch post "Human-in-the-loop tasks (chatbots, copilots, coding agents)" [2]; confidence.md L173 "Low confidence: Do not act. Route to a human" [1]. All match the ruling.
Changed: `record.md` S3 row (verdict → "hallucination half documented (as a schema guarantee); human-in-the-loop half implied, conditioned on confidence", with the three quotes + URLs); `record.md` C34 (verdict `contradicted` → `implied` (autonomy) / `documented` (low-confidence routing), quotes and hit counts added, use-case-map added to sources); `record.md` Totals line (5 → 4 `contradicted`, 1 → 2 `implied`); `profile.md` closing sentence of the performance paragraph; `verification.md` V15 outcome ("survived → contradicted" → "reversed by the fact-check → implied") plus a post-fact-check note under the direction check. The "reworded" part: I kept the ruling's net wording verbatim ("autonomous operation is implied, conditioned on confidence gating that the caller implements") and added "the literal phrase is absent" so the absence finding is not lost.

### R2 — appendix HN citations — applied
Re-derived via `https://hn.algolia.com/api/v1/items/<id>`: 49785707 = comment by `preommr`, 2026-09-21T11:12:03Z, `story_id` 49784706 (story "Jev-Leftpad", 233 points, github.com/f/jev-leftpad), text contains "just a convenience step"; 49767192 = comment by `prometheus1992`, 2026-09-19T15:10:29Z, `story_id` 49765348 (story "I built non-autoregressive decision models with RL a year ago", 1,346 points), text contains both "parody/con/shady" and "versions of bert"; 49767752 = `baobabKoodaa` quoting the bert sentence back, same story; 49717558 = the launch story (albelfio, 2026-09-15T19:25:03Z, 1,976 points). Quotes kept.
Changed: `record.md` third-party paragraph (both "(HN, date)" cites → comment id + story id + story title, marked); `record.md` appendix HN line (→ comment 49785707 / story 49784706 with the news.ycombinator.com link, marked). `pass/third-party-descriptions.md` S-01 still lists all three under the launch thread — provenance, left as is (the brief forbids touching `pass/`).

### R3 — C55 "14 cookbooks" — applied after re-count
Re-derived from llms-full.txt (910,292 B, 111 `Source:` lines): `jev-1.12` not followed by a digit = 27 occurrences (matches C55's ×27); split on `^Source: `, 16 pages contain it, all under `/cookbooks/` (list in the C55 marker). Method written into the marker.
Changed: `record.md` C55 ("14 cookbooks" → "16 cookbook pages"); `profile.md` versioning paragraph; `open-verification.md` O6.

### R4 — C47 "widget implies 75x/171x" — applied-reworded (derivation shown)
The ruling's premise — "No derivation exists in the item" — is contradicted: `pass/performance.md` L26 records the widget inputs ("$0.000081 & 0.114s vs $0.013880 & 8.566s", "Homepage side-by-side demo widget") and L88–L89 the arithmetic (8.566/0.114 = 75.1x; 0.013880/0.000081 = 171.4x). The fact-check grepped the pass for "75x"/"171x" and missed "75.1x"/"171.4x". Applied via the ruling's first option: inputs re-confirmed on the live homepage (each of "Cost $0.000081", "Completed in 0.114s", "Cost $0.013880", "Completed in 8.566s" = 1 hit), arithmetic re-done (75.14, 171.36), written into C47 with the pass reference. 193.6x/444.6x/238x untouched. Nothing marked `unknown`.
Changed: `record.md` C47; note appended under pattern 4 in `verification.md` § Patterns.

### R5 — C39 / T9 release-date spread — applied
Re-derived (UTC): Python — PyPI 0.5.7 upload 2026-09-11T23:05:50Z; GitHub release `v0.5.7` name "v0.5.7 (2026-09-12)", `published_at` 2026-09-11T23:06:00Z; docs changelog "v0.5.7 (2026-09-14)" → three different dates, spread survives. JS — npm 0.5.7 2026-09-12T04:13:21Z; GitHub `published_at` 2026-09-12T04:13:23Z, name "v0.5.7 (2026-09-11)"; docs changelog "v0.5.7 (2026-09-11)" → 04:13Z on 09-12 is 21:13 PDT on 09-11: one instant, spread removed.
Changed: `record.md` C39 (Python-only spread with the UTC values; JS half described as the same instant); `verification.md` D5.

### R6 — C59 founder attributions — applied
Re-derived hit counts (home / launch / team): "Google Brain" 0/0/4; "Embarcadero" 0/0/1; "co-invented RLHF" 0/0/2; "ex-research engineer from Meta" 0/0/2; "repeat founder" 0/0/2; "Made in SF" 6/0/0; "machine-native intelligence infrastructure" 3/3/3; "At OpenAI" 0/2/0 (first person). Only Google Brain and Embarcadero were misassigned; the remaining C59 facts were already correctly attributed (team page / homepage / launch post).
Changed: `record.md` C59 (each fact now carries its page; marked).

### R7 — C61 / O11 "Published Sep 22" — applied
Re-derived: launch HTML line 3 = `<!-- Published Sep 22, 2026, 4:54 AM UTC -->` [1]; `data-framer-page-optimized-at="2026-09-22T04:54:27.064Z"` [1]; CMS field `"date","2026-09-15T00:00:00.000Z"` [1]; rendered "Sep 15, 2026" [3]. Launch date stays 2026-09-15.
Changed: `record.md` C61 (secondary `unknown` removed; verdict `documented`); `record.md` Totals line (secondary-verdict list drops C61: nine → eight); `verification.md` D4; `open-verification.md` O11 closed with the explanation (struck heading, access "none needed").

### R8 — C49 n-counts, C50 "three tokens", C28 example path — refused as worded; fact-check's alternative applied
The ruling asks for a downgrade to "not discoverable from the public pages (no linked data file)" / `implied`, plus open-verification tags. Re-derivation contradicts the premise for all three (method rule 1: a failed lookup is not evidence of absence):
- **C28:** `ticket.messages[0].text` is verbatim in llms-full.txt, 2 hits, both on `https://docs.typesafe.ai/primitives` ("Does `ticket.messages[0].text` request a refund?"). It is on neither of C28's two cited pages, which is why the fact-check's grep of advanced.md/api.md missed it. Applied the fact-check's own first option ("Cite the page where the example literally appears"): source added, marked; verdict stays `documented`.
- **C50:** the three tokens exist with different characters — classification_using_confidence.md "75 industry groups" (the record wrote "75 options"); consistency_noul_cookbook.md table "125.0x" (claude-opus-4-8-reasoning, speed vs ts_noul); consistency_choice_cookbook.md table "897.4x" (gpt-5.5-reasoning, cost vs ts_choice). Range endpoints re-derived across both tables excluding the 1.0x baseline rows: speed 7.2x–125.0x, cost 20.3x–897.4x. Applied the fact-check's recommendation ("Re-quote those three from the page with exact characters"): C50 re-quoted, marked; verdict stays `documented`.
- **C49:** each evals sub-page carries `data-cases="<workflow>-cases.js?v=…"`, a public data file (`__VIEWER_DATA__({...})`, JSON) with `eval.n_cases`: security_incidents 240, agent_trace_observability 117, invoice_processing 150, customer_service 204 — exactly the record's 240/117/150/204. The fact-check looked for `.json` links and found none; the file is `.js`. Applied the fact-check's first option ("Cite the data-file URLs for the n-counts"): the four URLs and the attribute added to C49, marked; verification note strengthened rather than weakened.
No new `open-verification.md` items: all three are settled by public pages, so there is no access to tag.

### R9 — funding sources — applied
Re-derived: FinSMEs URL → HTTP 403 with curl's default user-agent, HTTP 200 (227,197 B) with `-A "Mozilla/5.0 (Macintosh; …) Chrome/128.0 Safari/537.36"`; title "TypeSafe AI Raises $40M in Seed Funding"; "$40M" [13], "DCVC" [3].
Changed: `record.md` C60 (FinSMEs restored as secondary citation with the UA requirement; The New Stack marked primary; Business Wire stays bot-walled); `verification.md` D2.

### R10 — T7 MCP packages — applied-reworded
Re-derived from the npm registry: `@jkudish/jev-mcp` 0.5.0, author Joey Kudish, maintainer jkudish, MIT, created 2026-09-17T21:10:53Z, repo github.com/jkudish/jev-mcp; `jevcore-mcp` 0.4.1, no author field, maintainer perrylink, Apache-2.0, created 2026-09-20T04:53:35Z, repo github.com/PerryLink/jevcore. Registry search `text=jev mcp` (size 50, 2026-09-23) also returns MCP-tagged Jev packages `jev-mcp` 0.5.0 (rashed.parvez), `ctxjev-mcp` 0.5.0, `@jkudish/jev-browser` 0.4.1, `@jev-harness/mcp` 0.2.2; `jev-flash-router` 1.0.3 (ravinder82, "decision router MCP server") confirmed by direct registry fetch. "Reworded" only in that the lower bound is written as "at least five more" (the search I ran returns five, the fact-check's four plus `@jev-harness/mcp`), with the search named. First-party absence unchanged.
Changed: `record.md` C42.

### R11 — patterns — applied
`fact-check.md` § Patterns copied verbatim to the end of `verification.md` under `## Patterns from the independent check`, with a one-line corrections-agent note after it about pattern 4 (the 75x/171x derivation does exist, in `pass/performance.md`).

## Other edits made while touching a ruled line
- `record.md` Totals: the old line "48 documented, 1 implied, 7 unknown, 5 contradicted" summed to 61 of 62 claims; a re-count of the 62 C-rows by first verdict word gives 49 documented (pre-R1: 49/1/7/5 = 62). Written as 49/2/7/4 with the previous text in the marker.
- `verification.md` direction-check paragraph: a dated post-fact-check note (V15 reversed, D2 partly reversed, D4/D5 spreads shrunk, N1 confirmed by the fact-check). Scorecard numbers left as the lead wrote them; the note states the adjustment.
- `record.md` C59: a stray Python-escaping artefact (`\"`) from my first write was removed in the same session; the cell now reads with plain quotes.

## Not applied
- **R8 as worded** (downgrade C49/C50/C28 and tag them in open-verification) — refused; see R8 above. The re-citations that the fact-check itself offered as the alternative were applied instead.
- **R4 "remove the figure and mark unknown"** — not needed; the derivation option applied.
- Fact-check T8 recommendation (soften C14's "advanced.md make[s] it optional" to "nullable") — no ruling issued; C14 untouched.
- Fact-check T6/T3 cosmetic (TNS "doesn't" curly apostrophe in the appendix) — no ruling issued; untouched.
- Fact-check C51 recommendation (promote N1 "cluster-verified" to verified) — no ruling issued; C51 and N1 untouched except the mention in the direction-check note.
- `pass/third-party-descriptions.md` S-01 (HN quotes under the wrong story) — provenance file, left as the brief requires; the corrected citations live in `record.md`.

## New findings needing a ruling
1. **Fact-check premise errors (two).** (a) "no pass file, verification row or appendix line mentions [75x/171x]" is wrong — `pass/performance.md` L26/L88–L89 has the inputs and arithmetic (the grep was for the rounded strings). (b) "none of the five evals HTML files links a `.json` data file" is true but misleading — they link `.js` data files via `data-cases`, which carry `n_cases`. Pattern 4 in the fact-check (and now in `verification.md`) is therefore half wrong about this item; a ruling on whether to annotate `fact-check.md` (provenance, untouched here) or leave the note in `verification.md` as the correction of record.
2. **Lead verification scorecard.** V15's reversal means the lead's "34 survived" is 33 with one lead-introduced defect (rule 8's failure mode). I added a dated note rather than rewriting the scorecard; ruling wanted on whether the scorecard line itself should be restated.
3. **C14 wording** ("advanced.md make[s] it optional and nullable"): the fact-check says advanced.md says nullable, not optional; unruled. Small, but it is the kind of over-statement pattern 1 warns about.
4. **Cookbook "16-way contention" / C50 minima** — the 7.2x/20.3x minima come from the *choice* table's "gpt-5.4-mini single-pick" row, which the choice cookbook itself flags as a "clean round trip rather than one measured under the 16-way LLM thread contention" (consistency_choice_cookbook.md L558). C50's "measured under 16-way contention" is therefore not true of the low end of the range. Not in any ruling; flagged, not changed.

## Progress

### [gen 1] 2026-09-23 — start
- Read corrections-brief.md (R1–R11), method-rules.md, fact-check.md, record.md, profile.md, verification.md, open-verification.md.
- Plan: fetch every source each ruling depends on into the scratchpad (docs .md pages, homepage + launch + team raw HTML, llms-full.txt, HN Algolia items, PyPI/npm/GitHub JSON, FinSMEs with browser UA, npm registry/search), re-derive each number, then apply R1–R11 with a rule-7 grep of the item directory per claim.

### [gen 1] 2026-09-23 — fetches and re-derivations complete
- 33 fetches (all 200; sizes match the fact-check's: home 590,563 B, launch 258,883 B, llms-full 910,292 B). Every ruling's figure re-derived: R1 quotes present (use-case-map L15, confidence.md, homepage 1 hit each); R2 ids resolve via Algolia to the stories the fact-check named; R3 = 16 cookbook pages / 27 occurrences; R5 JS collapses to one instant, Python spread survives; R6 Google Brain 0/0/4 (home/launch/team), Embarcadero 0/0/1; R7 line 3 of launch HTML is the Framer comment; R9 FinSMEs 403 default UA, 200 browser UA; R10 packages + five more MCP-tagged Jev packages.
- Two ruling premises contradicted by evidence: R4 ("no derivation exists in the item") — `pass/performance.md` L26/L88/L89 records the widget inputs and the arithmetic; R8 ("not discoverable from the public pages") — C28's example is verbatim on docs `/primitives`, C50's tokens exist as "75 industry groups" / "125.0x" / "897.4x", and C49's n-counts sit in each evals sub-page's linked `data-cases` file (`<workflow>-cases.js`, `eval.n_cases`). Handling recorded per ruling below.
- Next: apply edits to record.md, profile.md, verification.md, open-verification.md; rule-7 grep after each.

### [gen 1] 2026-09-23 — edits applied; item closed for gen 1
- record.md: Totals, S3, C28, C34, C39, C42, C47, C49, C50, C55, C59, C60, C61, third-party paragraph, appendix HN line (19 markers). profile.md: 2. verification.md: D2, D4, D5, V15, direction-check note, `## Patterns from the independent check` (4 markers). open-verification.md: O6, O11 (2 markers).
- Rule-7 residual grep: every old wording now appears only inside a `previously:` marker, the verbatim patterns block, or record.md progress history. Table pipe counts unchanged on every edited row. One self-introduced artefact (`\"` in C59) found and removed.
- Provenance untouched (mtimes 10:06–10:49, before this session): pass/*.md, fact-check.md, brief.md, fc-targets.md, fact-check-brief.md.
- Outcome: 7 applied, 3 applied-reworded, 1 refused as worded (R8 — evidence shows all three items are discoverable; fact-check's own re-cite alternative applied). Four new findings listed for a ruling.
