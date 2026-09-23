# Verification — `integration-paths` (adversarial re-check, 2026-09-23)

Method rule 8 is the bar: a skeptic stage that only moves toward confidence has
ratified, not verified. Every uncertain positive claim from the five clusters
was re-checked by the lead against its cited source (local copies of the
`.md` renderings and raw HTML in the lead's scratchpad, plus fresh registry /
GitHub / vendor fetches). Moves are listed **downward first**.

## Moved down (overturned or downgraded)

| # | Cluster claim | What the source actually says | Outcome |
|---|---|---|---|
| D1 | schema 5.12: "the Python default retry set is `{429, 500, 502, 503, 504}`" | `https://docs.typesafe.ai/sdk/python/api/retries` shows the `RetryPolicy` signature with `http_statuses … default_factory=lambda: {408, 429, *range(500, 600)}`; the `{429, 500, 502, 503, 504}` set appears only in a usage example (`RetryPolicy(max_retries=3, timeout=10.0, http_statuses={…})`). | **Overturned.** The Python default is `{408, 429, 500–599}`, identical to the JS default (batch 6.12 was right). Record claim 6.7 carries the corrected value. |
| D2 | schema cluster, unsettled #3 and fetch log: "no OpenAPI spec (none published at the paths tried)" | `https://api.typesafe.ai/openapi.json` → 200, `application/json`, 14,158 bytes, `openapi: 3.1.0`, title "TypeSafe", version 0.2.0; linked from `sdk/python/usage` as "TypeSafe OpenAPI spec" (`api.typesafe.ai/docs/`, a Swagger UI). | **Overturned (rule 1: failed lookup ≠ absence).** The spec exists and strengthens every absence claim (2 paths only). It also adds a **spread**: the spec's `responses` list only `200` and `422`; the docs' errors table lists 401/422/429/529; the SDKs model 400/403/404/500. Recorded in record 5.9, not resolved. |
| D3 | mcp claim 1: "the docs index (`llms.txt`, **124** pages)" | `grep -c '^- \[' llms.txt` = 111; sitemap `<loc>` count = 111; quickstart claim 23's `comm` showed the two lists identical. | **Downgraded (wrong count).** 111 pages. The absence conclusion (0 hits for MCP) is unaffected. |
| D4 | examples claim 6: verdict `contradicted` — "the cookbooks say the files ship; the only named location 404s" | The docs sentence is "Every API call is cached in `json_cache.json`, which ships with the cookbook" (7 occurrences corpus-wide; the claim text's "ship with" is a paraphrase). The cooksafe PyPI README links `https://github.com/typesafe-ai/CookSafe/tree/main/cookbooks`, which returns "Not Found" on the GitHub API. | **Downgraded from `contradicted` to `documented (statement) / unknown (location)`.** No source says the files do *not* ship; a broken link to a possibly-private repo is not a contradicting source. This was an over-correction against the subject (method-rules corollary). |
| D5 | quickstart claim 14 / mcp claim 18: Python v0.5.7 "2026-09-14 … initial public release" (docs changelog) | PyPI `releases["0.5.7"][0].upload_time` = 2026-09-11. | **spread (rule 6; recorded as a date spread)** (corrected 2026-09-23, ruling R29; previously: "Recorded as a date spread (rule 6)"), neither figure adopted: changelog date 09-14 vs registry upload 09-11. Record 1.8. |
| D6 | schema 5.16 quote: homepage "…so your software can act when confidence is high and escalate when it is not." | Raw homepage HTML carries **two** variants: "…can act automatically when confidence is high…" and "…can act when confidence is high…". | **downgraded (precision: both variants now quoted)** (corrected 2026-09-23, ruling R29; previously: "Survived with a caveat"): both strings exist (responsive duplicates); appendix quote 22 shows both. |

## Moved up (settled or strengthened)

| # | Item | Evidence | Outcome |
|---|---|---|---|
| U1 | batch unsettled #7: Vercel blog date "≤ 2026-09-20 by citation" | `https://vercel.com/blog/ai-gateway-jev-model-launch` → `<time dateTime="2026-09-18T00:00-07:00">18 Sep 2026</time>`; title string "fastest-adopted model in AI Gateway history" 3×. | **survived — settled: 2026-09-18.** (corrected 2026-09-23, ruling R29; previously: "Settled: 2026-09-18.") |
| U2 | mcp unsettled #1 (partial): OpenRouter "Access 2 Typesafe models" — which two? | `https://openrouter.ai/typesafe` → "Access 2 Typesafe models through the OpenRouter unified API including Jev Latest and Jev 1.13." Slugs `/~typesafe/jev-latest` (8×) and `/typesafe/jev-1.13` (4×). | **survived — settled (which two).** (corrected 2026-09-23, ruling R29; previously: "Settled (which two).") Whether either is reachable over `chat/completions` remains unknown (record 2.6). |
| U3 | batch 6.1: single endpoint (from docs + SDK constants) | OpenAPI spec paths = `POST /v1/systemone`, `GET /v1/models`; 0 hits for stream/batch/webhook/idempot/async/callback in the spec. | **survived — strengthened** (corrected 2026-09-23, ruling R29; previously: "Strengthened") to an absence-from-schema claim (rule 2). |
| U4 | LangChain blog date (batch inventory) | `datePublished: 2026-09-18T00:15:00.000Z` in page JSON-LD (the cluster's `<time dateTime>` grep did not match on re-fetch; the JSON-LD does). | **Survived, evidence path corrected.** |

## Survived unchanged (spot-checked by the lead)

- Quotes grep-matched 1× on the cited `.md` copy: coding-agents "Jev does none of that." and "not **a** drop-in replacement…" and "There is no `model: "jev-latest"` setting…"; noul "Use 0.5 when yes and no are equally easy to act on"; choice "Add an `other` or `none of the above` option…"; jaggedness "explicit "not stated" option"; models "honor the `retry-after` header".
- SKILL.md (raw, 10,040 bytes): "Typed output guarantees the interface, not truth" 1×; "use one per label when several may apply" 1×; "Include a no-match outcome when nothing may fit" 1×; "The live TypeSafe docs are the source of truth" 1×; "Treat cookbook thresholds and demo results as examples to evaluate, not universal rules" — **initially 0 hits** because the sentence is hard-wrapped after "universal"; line 148 confirms it. Not a fabrication. `migrating-to-v1` 1× (the broken link examples claim 24 reports).
- Launch post: "While Jev gives up string generation, it's optimized for structured outputs and can't hallucinate." exists with `<em>` tags splitting "can't hallucinate" (0 contiguous hits for "can't hallucinate" in raw HTML; the schema cluster had already flagged the markup-broken rendering). Date "Sep 15, 2026" 2×.
- Corpus zero-counts re-run by lead on `llms-full.txt`: `webhook` 0, `idempot` 0, `polling` 0, `Idempotency` 0; `abstain` 3 (cookbook client code).
- HN Algolia item 49717558: "Introducing System One Models and Jev", 1976 pts, 2026-09-15T19:25:03Z, `albelfio`.
- GitHub REST: `typesafe-ai/skills` 1,981★ created 2026-08-24 MIT; `typesafe-sdk-python` 210★ 2026-09-04 MIT; `typesafe-sdk-js` 229★ 2026-09-04 MIT; `system-one-adapter-python` 277★ 2026-08-08 MIT; `CookSafe` Not Found.
- Registries: PyPI `typesafe-sdk` 0.7.1 (author "TypeSafe AI", `>=3.10`, uploads 09-09/09-11/09-15/09-18/09-21); npm `@typesafe-ai/sdk` 0.6.0, `bin: None`, `engines.node >=20`; `@ai-sdk/typesafe-ai` 3.0.5, created 2026-09-16, maintainer `vercel-release-bot`, repo `vercel/ai` dir `packages/typesafe-ai`; PyPI `langchain-typesafe` 0.0.1a3 → `langchain-ai/langchain`; npm `@langchain/typesafe` 0.0.1 maintainers `lc-oss-admin`, `langchain-security`; `cooksafe` 0.2.0.
- Vercel provider README (raw): `boolean` 1×, `noul` 0× case-sensitively but "Boolean maps to TypeSafe's Noul" 1× — the 0× was a case artefact, not a missing mapping (corrected 2026-09-23; previously: "`noul` 0×"), `experimental_evaluate` 2×, "Evaluation is experimental" 1×.
- Vendor pages all 200 with expected titles: Vercel blog, Cloudflare "Jev (typesafe)" (third-party 1×; "Jev is TypeSafe's structured evaluation model" 1×), LiteLLM ("Pass-through endpoint for the TypeSafe AI System One API" 1×), ai-sdk.dev "AI SDK Providers: TypeSafe", LangChain docs "TypeSafe integrations", Wikipedia "Jev (AI model)" (release sentence 1×), Product Hunt listing, evals.typesafe.ai "Workflow evals".
- Third-party inventory: 25 non-typesafe.ai URLs from `pass/batch-async-and-third-party-use.md` re-fetched — 25/25 HTTP 200.
- `docs.typesafe.ai/mcp`: 200 `application/json`, server "TypeSafe AI" 1.0.0, tools `search_type_safe_ai`, `query_docs_filesystem_type_safe_ai`, `submit_feedback` (docs search, not Jev).
- Python SDK `constants.py`: `RETRY_COUNT_HEADER = "X-TypeSafe-Retry-Count"`, `REQUEST_ID_HEADER = "x-typesafe-request-id"`, paths `/v1/systemone` and `/v1/models` only.

## Direction check

Scorecard (D-table D1–D6 + U-table U1–U4, 10 rows; the bullet sections "Survived unchanged" and "Not re-checked" are not scored rows): 2 `overturned` (D1, D2), 3 `downgraded` (D3, D4, D6), 1 `spread` (D5), 4 `survived` (U1–U4) = 10 (corrected 2026-09-23, ruling R29; previously: "Six moves down (two overturned, two downgraded, two spreads recorded), four up"). Both directions moved; the largest defects were a misread default (D1) and a missed reference document (D2) — the second of which, once found, made the subject's absence claims *stronger*, so "moved down" here means the cluster's evidence was wrong, not that Jev has more surface than reported.

## Not re-checked (declared, per rule 7 the count is a lower bound)

- Ecosystem search totals (2,374 / 580 / 167 / 161 / 12 repos; npm 183) — point-in-time numbers, drifting daily; recorded as order-of-magnitude only.
- Per-cookbook `Numbers below came from` dates, awesome-list self-counts, star counts of third-party repos.
- Reddit / X (blocked logged-out; see `open-verification.md`).

## Patterns from the independent check

Appended verbatim from `fact-check.md` § "Patterns (what transfers to the rest of the wave)" on 2026-09-23 (orchestrator ruling R8).

1. **The pass cited the docs and the OpenAPI spec as if they agreed; they do not.** The spec is looser than the docs on `instructions` (optional/nullable vs required), Score levels (`minItems: 1`, no max vs 2–10), Choice options (unbounded vs ≤255) and probability sums ("approximately 1" vs "sum to 1"). None of this is recorded, even though the sibling pattern was in the brief. The same spec also *answers* two things the record calls unknown (the 422 body shape; the O2 open item). Lesson: when a subject has a machine-readable reference, diff it against the prose reference and record the diff as a spread — it is the highest-yield check in this item.

2. **Absence claims here were built from the reference and survived — every one.** Two paths in the spec, ten repos in the org, 404s on the guessed package names, zero word-hits in a 910 KB corpus. This is the method-rules "start from the schema" pattern working; propagate the technique, not just the result.

3. **Paraphrases inside quotation marks.** Two instances: 'planned' (4.6; 0× on the page) and the verification.md "`noul` 0×" count that is true only case-sensitively while the same README says "Boolean maps to TypeSafe's Noul". Neither changes a verdict, but both are the rule-4 failure shape in miniature.

4. **Over-correction against the subject is present but small.** (a) "no human in the loop" was declared absent from first-party pages; the launch post's comparison table carries the contrast in nearly those words. (b) The jaggedness quote is presented without the vendor's "We expect to improve on this in the future." and the page's "Last reviewed 2026-09-17" scope note. (c) T8's pin recommendation is conditional; the profile states it as general. (d) 3.8 leaves "unknown" what four public pages settle.

5. **"Unknown" used where a public fetch answers.** 3.8 (evals pages, two "unfetched — budget") and 5.9/O2 (error body) both had the answer one public fetch away. The pass's own open-verification file even names the fetch for O14. When an open item lists a public URL as the settling step, the check should run it.

6. **Marketing-vs-reference tension is the subject's signature, and it cuts against the vendor's own launch copy, not only the README.** "Always communicates confidence and uncertainty with every output" (launch post) vs `NoulAnswer` without `confidence` (spec); "full queries" (launch post) vs prose-only evals pages. The S-row treatment ("marketing claim; the docs qualify it") is the right frame; apply it to the launch post's table as well as to the homepage.

7. **Drift is real but harmless:** star counts moved by 1–3 between the pass and this check; date-stamp everything and never adopt a single figure across pages (the Python and JS 0.5.7 dates are a three-way spread: two changelogs, two registries).
