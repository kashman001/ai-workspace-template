# Third-party descriptions of Jev / TypeSafe / "System One models"

Cluster: `third-party-descriptions`. Date checked: **2026-09-23**. Public sources only; no logins, no API calls.

**Headline:** the absence hypothesis is refuted. Jev launched publicly on **2026-09-15** and by 2026-09-23 has a large, dated, independently-authored footprint: a 1,976-point Hacker News launch thread, TechCrunch / The New Stack / Forkast coverage, at least five hands-on blog evaluations that called the API, official SDKs on npm and PyPI, third-party integrations (Vercel AI Gateway, Pydantic AI, Spring AI, n8n), and ~15 competing `awesome-jev` catalogs on GitHub. Every quote below was confirmed by `grep -F` against the served HTML of its page (rule 4); where a candidate quote did NOT occur verbatim, that is recorded.

---

## Queries run

| # | Query / endpoint | Tool | Hits | Relevant hits |
|---|---|---|---|---|
| 1 | `https://hn.algolia.com/api/v1/search?query=typesafe.ai` | curl | 64 | ~60 (all about typesafe.ai; earliest 2026-09-15) |
| 2 | `https://hn.algolia.com/api/v1/search?query=%22system%20one%22%20jev` | curl | 67 | ~65 |
| 3 | `https://hn.algolia.com/api/v1/search?query=typesafe%20jev` | curl | 358 | ~350 |
| 4 | `https://hn.algolia.com/api/v1/search_by_date?query=jev%20typesafe&tags=story` | curl | 37 stories | 37; earliest 2026-09-15T19:25:03Z (item 49717558) |
| 5 | `https://hn.algolia.com/api/v1/items/{49717558,49729945,49718261,49785707,49813546,49722252,49767192,49814660,49718432}` | curl | 9 items | 9 (full text retrieved) |
| 6 | `https://api.github.com/search/repositories?q=typesafe-ai` | curl | total_count 1009 | ~18 of top 20 about TypeSafe/Jev (2 collisions: yournextstore, hippo-memory) |
| 7 | `https://api.github.com/search/repositories?q=typesafe+jev` | curl | total_count 2374 | 20 of top 20 |
| 8 | `https://api.github.com/search/repositories?q=typesafe.ai` | curl | total_count 793 | ~18 of 20 |
| 9 | `https://api.github.com/search/repositories?q=jev+model+typesafe` | curl | total_count 660 | 20 of 20 |
| 10 | `https://api.github.com/orgs/typesafe-ai/repos` | curl | 10 repos | 10 (official org; see pointers) |
| 11 | `https://registry.npmjs.org/-/v1/search?text=typesafe-ai&size=15` | curl | total 158191 (fuzzy) | 12 of top 15 about TypeSafe AI |
| 12 | `https://registry.npmjs.org/-/v1/search?text=jev%20typesafe&size=15` | curl | total 4068 (fuzzy) | 10 of 15 |
| 13 | `https://registry.npmjs.org/@typesafe-ai/sdk` | curl | 1 | latest 0.6.0, created 2026-09-12 |
| 14 | `https://pypi.org/pypi/typesafe-sdk/json`, `.../typesafe-ai/json`, `.../typesafe/json` | curl | 3 | `typesafe-sdk` 0.7.1 (author "TypeSafe AI"); `typesafe-ai` 0.1.0 is a redirect shim; `typesafe` 0.9.1 is a collision |
| 15 | `https://www.reddit.com/search.json?q=typesafe.ai+jev` | curl | HTTP 403 | bot-walled |
| 16 | `https://api.pullpush.io/reddit/search/submission/?q=typesafe%20jev` | curl | HTTP 429 | rate-limited |
| 17 | `https://old.reddit.com/search?q=typesafe+jev&sort=new` | curl | HTTP 200, 0 `search-result` nodes | served a shell page, no results parsed |
| 18 | `https://lobste.rs/search?q=typesafe+jev` | curl | 0 parsed | no `u-url` anchors matched |
| 19 | `https://openrouter.ai/api/v1/models` | curl | 458 models | 0 ids containing `typesafe` or `jev` |
| 20 | WebSearch `"typesafe.ai" jev "System One" model` | WebSearch | 9 | 9 (datacamp, mindstudio, flaviocopes, langchain blog, vercel, you.com, dev.to, + 2 first-party) |
| 21 | WebSearch `TypeSafe AI Jev launch Diogo Almeida funding news` | WebSearch | 10 | 10 (Morningstar/BusinessWire, Forbes, KuCoin, runtimewire, stackfutures, techflowpost, biggo, doomers.ai, winzheng, betterthanrandom) |
| 22 | WebSearch `"jev-1.13" typesafe` | WebSearch | 10 | 10 (openrouter, docs.typesafe.ai jaggedness, cloudprice, opper, dev.to, pydantic, flaviocopes, thenewstack, defapi) |
| 23 | WebSearch `typesafe.ai jev site:reddit.com` | WebSearch | 9 | **0** (returned unrelated Wikipedia/arxiv/TypeScript pages; no reddit.com result) |
| 24 | WebSearch `typesafe jev "system one" model` with `allowed_domains=[reddit.com]` | WebSearch | error | `reddit.com` is not accessible to the search user agent |
| 25 | Direct fetches for quote verification (curl + `grep -F`): techcrunch, lindfors.no, flaviocopes, latent.space, forkast, unzip.dev, sameernanda, mikulskibartosz, vercel.com/i/jev-vs-gpt-6-astra, vercel changelog, pydantic.dev, nearhere.events, thenewstack, morningstar, docs.typesafe.ai/confidence | curl | all HTTP 200 | see per-source blocks |
| 26 | `https://www.forbes.com/sites/the-prompt/2026/09/15/...` | WebFetch + curl | HTTP 403 both | bot-walled; title only from search snippet |
| 27 | `https://www.businesswire.com/news/home/20260915525333/en/` | curl | HTTP 403 | bot-walled; release read via Morningstar mirror instead |
| 28 | `https://openrouter.ai/typesafe/jev-1.13` | WebFetch | HTTP 404 | see "What could not be found" |

Searches used: 5 of the 6-8 budget (one errored on domain block).

---

## Sources (genuine third-party, dated)

Verdict key: **documented** = independent author, dated page, quote confirmed in served HTML; **implied** = the page exists and is dated but body could not be read or is partner/interview content; **unknown** = could not be verified.

### S-01 — Hacker News launch thread (community) — 2026-09-15 onward
- **Verdict:** documented
- **URL:** https://news.ycombinator.com/item?id=49717558 (Algolia item API used; no login)
- **Date of source:** submitted 2026-09-15T19:25:03Z by `albelfio`; 1,976 points, 173 top-level children as of 2026-09-23
- **How verified:** `hn.algolia.com/api/v1/items/49717558` and child items; text below is the API's `text` field with HTML tags stripped
- **Earliest dated third-party mention of Jev found anywhere:** this submission (title "Introducing System One Models and Jev", linking TypeSafe's blog). Two other same-day submissions: 49718261 (2026-09-15T20:16:02Z, "Typesafe.ai's System One Model", links docs.typesafe.ai/concepts/system-one) and a comment 49718432 (2026-09-15T20:26:32Z, `CompleteSkeptic`: "it's our output tokens that are free (under the system one / jev column)").
- **Verbatim community quotes (dated):**
  - 2026-09-16T04:54:58Z, `hmartin`: "Am I the only one struggling to parse the distinction System One (the system/harness?) and Jev (the model?)?"
  - 2026-09-19T15:10:29Z, `prometheus1992`: "I think the main gripe that people had with Jev and Typesafe was the language used when they launched. To me personally it seemed like a parody/con/shady at first. "Breakthrough", "our research went in another direction" , "Two years in stealth", "System One thinking model", "Jev can't hallucinate", "RLCD","We are doing very cool stuff, but we will have to hire you to tell you" - these are some of the things that they said on their website on the launch blog. I had used versions of bert to achieve the same functionality years ago."
  - 2026-09-21T11:12:03Z, `preommr` (**confidence shape**): "important to note that the "confidence" score is... maybe not what people think it is - kind of useless, and just a convenience step from the probabilities. from the docs: "confidence is a statistic computed from the probability distribution the answer already gives you.""
  - 2026-09-23T09:29:11Z, `wongarsu` (**confidence shape**): "Their docs at https://docs.typesafe.ai/confidence state "confidence is a statistic computed from the probability distribution the answer already gives you. TypeSafe computes it for you" And further down "TypeSafe computes confidence from how the probability is spread across the options. All of it on one option gives 1.0; the more evenly it spreads, the lower the confidence. This demo uses (3 × largest probability − 1) / 2 to approximate confidence for three options." So while we don't know the exact formula they use, it is just a function over the probabilities"
    - Cross-check on the docs page: `curl https://docs.typesafe.ai/confidence` (HTTP 200) contains, in the served HTML, "is a statistic computed from the probability distribution the answer already gives you. TypeSafe computes it for you and returns it on every Choice" and "(3 × largest probability − 1) / 2". The community quote is faithful to the docs.
  - 2026-09-23T11:49:26Z, `alun`: "The one thing I can't wrap my head around with Jev is why they're trying to create that "System One" narrative. In real life, a human doesn't do classification tasks with the System One part of their brain, they use System Two."
- **Hands-on?** Mixed; thread contains both hands-on reports and marketing restatement. Numbers: none authoritative beyond docs quotes.

### S-02 — Near Here (nearhere.events), Jon Reed — 2026-09-16 — HANDS-ON
- **Verdict:** documented. **Earliest dated third-party hands-on evaluation found.**
- **URL:** https://nearhere.events/blog/typesafe-jev-mistral-gemini-event-validation
- **Date of source:** `datePublished: 2026-09-16`; page text "By Jon Reed · Published 16 September 2026"; "tested on 16 September 2026"
- **How verified:** curl HTTP 200, text extracted from served HTML
- **Verbatim:** "TypeSafe's Jev looked particularly relevant. It returns typed decisions and probabilities rather than writing a chat response. We compared it with Mistral Small 4 and Gemini 3.5 Flash-Lite using individually tuned prompts and retained event listings."
- **Verbatim (model version):** "We requested jev-latest ; responses identified jev-1.13.0 . Prices were checked on 16 September 2026."
- **Numbers (their table, columns Mistral Small 4 | Gemini 3.5 Flash-Lite | TypeSafe Jev):** "Main test set (50 listings) 42 / 50 43 / 50 48 / 50"; "All prompt-selection tests (132) 121 / 132 125 / 132 129 / 132"; "Average response time 2.90s 3.40s 0.59s"; "Cost per 1,000 decisions $0.370 $2.496 $0.043"; "USD per 1M input / output tokens $0.15 / $0.60 $0.30 / $2.50 $0.042 / free"; Jev response mode "Native Choice + probabilities". Author's caveat: "Findings apply to our specific task and datasets".
- **Hands-on?** Yes (API calls, retained inputs/hashes, downloadable PDF).

### S-03 — Forkast News, Lena Park — 2026-09-17
- **Verdict:** documented (restates company claims; cites one independent test by Every)
- **URL:** https://forkast.news/typesafe-ais-jev-is-not-an-llm-and-that-may-be-the-point/
- **Date of source:** `datePublished: 2026-09-17T20:55:10+00:00`
- **How verified:** curl HTTP 200; `grep -F` confirmed strings
- **Verbatim:** "TypeSafe AI is challenging the industry's reliance on large language models for every stage of the agentic stack with the launch of Jev, a specialized 'System One Model' designed exclusively for structured decision-making."; "The output is strictly type-safe, preventing hallucinations or malformed data, and includes calibrated confidence scores that allow developers to set precise thresholds for autonomous action."
- **Numbers (attributed to company unless noted):** "$40 million" seed; "193.6"x faster and "444.6"x cheaper (company claim); "$0.042" per million input tokens; "approximately 67.8% on its internal four-workflow production benchmark, which it claims is comparable to GPT-5.6 Terra. Latency ranges from 70 to 500 milliseconds end-to-end, compared to 3 to 329 seconds for frontier models."; "Independent testing from Every corroborated the directional claims, finding Jev roughly 25x faster and 580x cheaper than Claude Fable 5.1 on extraction tasks: 0.35 seconds versus 8.83 seconds per passage."; "remains in early access with no named production customers or revenue disclosed."
- **Note:** WebFetch summary rendered "70-500" and "Every.to"; the page actually says "70 to 500 milliseconds" and "Every" (no ".to"). Both corrected above.
- **Hands-on?** No.

### S-04 — TechCrunch, Tim Fernholz — 2026-09-18
- **Verdict:** documented (press; restates company plus two named developer testimonials)
- **URL:** https://techcrunch.com/2026/09/18/a-new-kind-of-ai-model-from-a-chatgpt-inventor-is-thrilling-developers/
- **Date of source:** `datePublished: 2026-09-18T18:49:30+00:00`; author meta "Tim Fernholz"
- **How verified:** curl HTTP 200; `grep -F` confirmed every string below
- **Verbatim fragments confirmed:** "produces probabilities"; "calibrated decisions"; "output tokens are free"; "metered by the billion"; "System One model"; developer testimonials "five to 18 times" (Vercel engineer, faster than an OpenAI model on his task) and "10 to 20 times" (Bryo AI CTO, more expensive than Gemini on his task). WebFetch's sentence-level composites ("It doesn't output text, but instead produces probabilities, or what the company calls 'calibrated decisions.'") were NOT independently grep-confirmed as whole sentences — treat only the fragments above as verbatim.
- **Numbers:** none of the company's price/latency figures appear as numbers in this article beyond the two testimonial multiples.
- **Hands-on?** No (reports others' use).

### S-05 — Emil Lindfors (lindfors.no) — 2026-09-18 — HANDS-ON
- **Verdict:** documented
- **URL:** https://lindfors.no/blog/a-first-look-at-typesafes-jev/
- **Date of source:** `datePublished: 2026-09-18` (a `datetime="2026-09-22"` also present — likely an update stamp)
- **How verified:** curl HTTP 200; `grep -F` confirmed
- **Verbatim:** `first "System One" model` (straight quotes on page); "$42 per billion input tokens"; "0.042 per million"; "jev-1.13.0"; "should occur about 80% of the time"; "24 Norwegian" documents
- **Numbers (author's test, Jev vs DeepSeek V4.1 Flash):** median latency 0.32 s for Jev (WebFetch report; "0.32" confirmed on page); cost per 1,000 documents $0.22 (Jev) vs $1.31 / $3.08 (DeepSeek reasoning off/on) — these three dollar figures are from the WebFetch summary and were NOT individually grep-confirmed.
- **Confidence shape:** article evaluates calibration by probability bins ("Outcomes assigned a probability of 0.8 should occur about 80% of the time").
- **Hands-on?** Yes (early-access API, 24 documents, model `jev-1.13.0`).

### S-06 — Flavio Copes (flaviocopes.com) — published 2026-09-17, updated 2026-09-23 — HANDS-ON
- **Verdict:** documented
- **URL:** https://flaviocopes.com/jev/
- **Date of source:** `datePublished: 2026-09-17T21:00:00.000Z`; `datetime="2026-09-23"` shown as "Updated"
- **How verified:** curl HTTP 200; `grep -F` confirmed
- **Verbatim:** "Jev is not a chatbot like ChatGPT, and it is not a coding model."; "You send it data and a list of typed questions"; "Jev is a small component inside a regular application"; "70 to 500 milliseconds"; "0.042 per million"
- **Response shape (per WebFetch reading of his raw curl responses; strings "confidence" and "noul" confirmed present):** Choice answers carry `choice`, `probabilities`, `confidence`; Score answers carry `score`, `legend`, `probabilities`, `confidence`; yes/no ("noul") answers carry a single 0–1 probability. Copes describes confidence as high (act) / medium (review) / low (escalate).
- **Hands-on?** Yes (raw curl, JS SDK, Python SDK examples with response JSON).

### S-07 — Bartosz Mikulski (mikulskibartosz.name) — 2026-09-19 — HANDS-ON
- **Verdict:** documented
- **URL:** https://mikulskibartosz.name/typesafe-jev-guess-what-i-drew
- **Date of source:** `datePublished: 2026-09-19T00:00:00+00:00`
- **How verified:** curl HTTP 200; `grep -F` confirmed
- **Verbatim:** "Jev reads text and nothing else, at least for now"; "after the fast, intuitive System 1 that Daniel Kahneman popularized"; "Confidence stayed out of every test"; "an LLM can write down any number"
- **Numbers (author's experiment, per WebFetch):** Jev ~35% accuracy on SVG-encoded drawings, ~9% (chance) on base64; Claude Sonnet 5 ~57% on SVG, ~91% on images — not individually grep-confirmed.
- **Confidence shape:** author deliberately excluded the confidence field from scoring.
- **Hands-on?** Yes (conceptual description of the experiment; no code shown).

### S-08 — Sameer Nanda (sameernanda.com) — 2026-09-21 — light hands-on
- **Verdict:** documented
- **URL:** https://sameernanda.com/system-one-models-jev/
- **Date of source:** `datePublished: 2026-09-21T16:38:13.000Z`
- **How verified:** curl HTTP 200; `grep -F` confirmed
- **Verbatim:** "It takes text or structured state as input and returns structured answers."; "Jev costs $0.042 per million input tokens, with no output charge."; "TypeSafe reports response times of 70"[–500 milliseconds]; "ordinary building block of software"
- **Numbers:** $0.042/M input (restated from TypeSafe); author's own observed 200–300 ms (per WebFetch; "200" present on page).
- **Hands-on?** Partly (used it in a personal job-search pipeline).

### S-09 — Latent Space podcast, host swyx, guest Diogo Almeida (CEO, TypeSafe AI) — 2026-09-21
- **Verdict:** implied (independent venue, but content is the company speaking)
- **URL:** https://www.latent.space/p/jev (video mirror https://www.youtube.com/watch?v=cFx9Z3ZXca0 per HN 49805642)
- **Date of source:** `datePublished: 2026-09-21T22:13:49+00:00`
- **How verified:** curl HTTP 200; fragments "System 1 models", "large programmable", "Reinforcement Learning for Calibrated Decisions", "Jevons", "trillion tokens", "100,000", "1.13" confirmed
- **Company-stated numbers (not independent):** launch video "~40M" views; Discord "100,000" people; "a trillion tokens per day"; model "Jev 1.13.0" — all per WebFetch summary of the transcript; only the fragments above were grep-confirmed.
- **Hands-on?** No.

### S-10 — The New Stack, Adrian Bridgwater — 2026-09-21
- **Verdict:** documented
- **URL:** https://thenewstack.io/typesafe-jev-system-one/
- **Date of source:** `datePublished: 2026-09-21T19:36:29+00:00`; page text "Sep 21st, 2026 3:36pm by Adrian Bridgwater"
- **How verified:** curl HTTP 200; text extracted (WebFetch had returned only the site shell)
- **Verbatim:** "TypeSafe launches Jev, a "System One" model built for machine decisions, not chat — faster, cheaper, and immune to hallucination, its makers claim."; "When TypeSafe emerged last week after two years in stealth, backed by $40 million in seed funding led by DCVC, to launch its first model, Jev, it claimed something that counters just about everything the industry has built since ChatGPT: The model doesn't write. It decides."; "Developers can send Jev structured questions and get typed decisions with calibrated probabilities, meaning software can account for uncertainty."
- **Hands-on?** No.

### S-11 — Vercel (AI Gateway partner content) — 2026-09-21 and undated
- **Verdict:** documented (integration exists) / implied (partner marketing)
- **URLs:** https://vercel.com/changelog/ai-gateway-now-supports-typesafe-clients-and-http-api-for-jev (`datePublished: 2026-09-21`); https://vercel.com/i/jev-vs-gpt-6-astra (undated); https://vercel.com/i/jev-use-cases and https://vercel.com/i/what-is-jev (from HN/search; not fetched)
- **How verified:** curl HTTP 200 on both fetched pages
- **Verbatim (jev-vs-gpt-6-astra):** "Jev evaluates supplied state against typed questions. Its System One interface returns choices, rubric scores, or yes-or-no probabilities. It accepts text-based state, including structured records, and doesn't generate standard replies, explanations of its reasoning, or media."
- **Numbers:** none.
- **Hands-on?** No (partner documentation).

### S-12 — unzip.dev newsletter 0x025, Agam More — 2026-09-22
- **Verdict:** documented (critical/skeptical secondary analysis)
- **URL:** https://unzip.dev/0x025-system-one-models/
- **Date of source:** `datePublished: 2026-09-22T05:59:42.000Z`
- **How verified:** curl HTTP 200; `grep -F` confirmed
- **Verbatim:** "Given a state and a typed question, you get back JSON with a probability for each possible answer"; "if-statement that knows how sure it is"; "444.6" (headline multiple, with the founder conceding it sits at the high end per WebFetch); "zero-shot classifier" (HN pushback quoted); calibration is "the hard part"
- **Hands-on?** No.

### S-13 — Pydantic AI docs, "TypeSafe (Jev)" model page — undated — INTEGRATION (confidence shape)
- **Verdict:** documented (third-party SDK integration; **load-bearing for the confidence finding**)
- **URL:** https://pydantic.dev/docs/ai/models/typesafe/
- **Date of source:** undated
- **How verified:** curl HTTP 200; text extracted; `grep -F` confirmed `provider_details['confidence']`, "0 to 1, one number per field", "jev-1.13.0", "jev-latest"
- **Verbatim:** "Jev is not a language model. You give it a text and typed questions, and it answers each one with a confidence. It does not write text." (the first sentence did not match `grep -F` because of a tag boundary in the raw HTML; it is present in the stripped text)
- **Verbatim (confidence):** "Confidence in each answer is on the response, in provider_details['confidence'] : 0 to 1, one number per field, so one threshold reads the same way across an output type. It is a margin, not a probability that the answer is right."
- **Install / model ids:** `pydantic-ai-slim[typesafe]`; model strings `typesafe:jev-latest`, `jev-preview`, `jev-1.13.0`; `provider_details['probabilities']` and `provider_details['scores']` also exposed (per WebFetch).

### S-14 — Business Wire press release (mirrored on Morningstar) — 2026-09-15 — NOT third-party
- **Verdict:** documented as a dated first-party release; recorded because it is the earliest dated public artefact and gives the funding numbers press outlets repeat
- **URL:** https://www.morningstar.com/news/business-wire/20260915525333/typesafe-ai-emerges-from-stealth-with-40m-in-funding-with-new-model-for-composable-ai (businesswire.com itself returned 403)
- **How verified:** curl HTTP 200 (Morningstar); text extracted
- **Verbatim:** "today emerged from stealth with $40 million in seed funding led by DCVC. Founded by former OpenAI researcher and co-inventor of RLHF/ChatGPT, Diogo Almeida, with Erik Gafni and Sasha Sheng, TypeSafe is building a new class of intelligence designed to give developers reliable, efficient intelligence they can integrate directly into software systems."
- **Numbers:** $40M seed, lead DCVC. The "$200 million valuation" reported by Forkast and in the Forbes headline does **not** appear in this release (grep for "valuation": not found).

### S-15 — GitHub ecosystem and package registries (third-party) — 2026-09-16 onward
- **Verdict:** documented
- **Official SDKs (first-party, pointers):** npm `@typesafe-ai/sdk` 0.6.0 (package created 2026-09-12, latest published 2026-09-15T18:17Z; README: `npm install @typesafe-ai/sdk`, `client.systemOne({state, questions})`, reads `response.answers.category.choice`); PyPI `typesafe-sdk` 0.7.1 (author "TypeSafe AI"; README: `uv add typesafe-sdk`, `client.system_one(state=..., questions={...: Choice(...)})`, reads `response.choices["category"].choice`). PyPI `typesafe-ai` 0.1.0 is a "Redirect shim: the TypeSafe AI Python SDK is published as 'typesafe-sdk'". npm `typesafe-ai` does not exist.
- **Third-party integrations on npm (dated by registry):** `@ai-sdk/typesafe-ai` 3.0.5 (2026-09-23, "AI SDK integration for Typesafe AI"); `@effect-agent/ai-typesafe` 0.1.0-beta.100 (2026-09-17); `n8n-nodes-typesafe-ai` 0.1.1 (2026-09-21); `pi-typesafe` 0.7.1; `@jkudish/jev-mcp` 0.5.0 (2026-09-19, "MCP server exposing TypeSafe Jev as purpose-built judgment tools"); `jevcore-mcp` 0.4.1 (2026-09-20, "typed judgments (ask, rank, check) that return calibra[ted...]"); `@mhingston5/jev-cli`, `@andrueandersoncs/jev-cli`, `jev-repl`, `jev-use`, `jev-gateway`, `jev-dev-harness`, `discoprint`, `jev-chess`, `@mlola/decision-jev`, `pi-jev-permit`, `gg-friggin-ez`.
- **Third-party GitHub repos (created dates from API):** `spring-ai-community/spring-ai-typesafe` (2026-09-20, "A Java SDK for the TypeSafe AI JEV API"); `Twister915/typesafe-ai` (2026-09-16, Rust clients); `joshmn/typesafe-sdk` (2026-09-16, Ruby); `jexp/neo4jev` (2026-09-16); `ellipsis-dev/blink` (2026-09-16); open re-implementations `wfzyx/von` ("Sub-15ms, non-autoregressive, local drop-in alternative to TypeSafe Jev"), `r-ms/mini-jev`, `ikermoel/open-alternative-jev`, `TheoLeeCJ/SemIf-OpenJev`, `khimaros/verdict`, `rcarmo/go-system-one`, `1Panel-dev/laya-server` ("compatible with the TypeSafe Jev API format").
- **Count spread (rule 6, record, do not resolve):** `heyjunpenn/awesome-jev` README states "832 verified open-source projects" (badge) while its GitHub description says "834"; `walidboulanouar/awesome-jev-use-cases` description says "74 demos ranked by likes, 150+ GitHub repos"; GitHub search `typesafe+jev` returns total_count 2374 (includes collisions). None adopted.
- **Hands-on?** Yes by construction (working integrations), but no numbers verified here.

### S-16 — Other dated press/blog URLs seen in HN/search but not fetched (pointers only)
- 2026-09-15 Forbes, "This $200 million startup wants to fix AI's overconfidence problem" — https://www.forbes.com/sites/the-prompt/2026/09/15/this-200-million-startup-wants-to-fix-ais-overconfidence-problem/ — **HTTP 403 to both WebFetch and curl**; title from search snippet only; verdict unknown.
- 2026-09-17 theframenews.org "AI Startup launches a faster and cheaper alternative to LLMs" (HN 49740121); 2026-09-17 thefinancialengineer.substack.com (HN 49747584); 2026-09-17 backnotprop.com/blog/jev-poker (HN 49745212); 2026-09-20 southbridge.ai/blog/jev-entity-resolution (HN 49771931); 2026-09-22 vercel.com/i/jev-use-cases; datacamp.com/blog/system-one-models-jev; mindstudio.ai/blog/jev-system-one-model-launch; langchain.com/blog/building-a-harness-with-jev; dev.to/valyuai/how-to-use-jev-...; runtimewire.com; stackfutures.com; kucoin.com news flash; doomers.ai case study ("How Doomers launched TypeSafe AI and Jev out of stealth on X" — a launch-agency page, i.e. vendor to TypeSafe, not independent). Not fetched; verdict unknown for each.

---

## TypeSafe's own surfaces (pointers only; not logged in)
- https://x.com/typesafeai (linked from typesafe.ai, blog, docs)
- https://www.linkedin.com/company/typesafe-ai/ (linked from typesafe.ai)
- https://discord.gg/typesafe (linked from docs.typesafe.ai)
- https://github.com/typesafe-ai — org id 171090879; 10 public repos: `typesafe-sdk-python` (2026-09-04), `typesafe-sdk-js` (2026-09-04), `skills` (2026-08-24, "Agent skills for building with TypeSafe's System One API"), `system-one-adapter-python` (2026-08-08, "Drop-in TypeSafeClient replacement backed by LLM APIs"), `Overwatch` (2026-08-31), plus forks/infra (`vllm`, `LLaDA`, `daggerverse`, `pulumi-clickhouse`, `typesafe-ai.github.io`)
- https://jobs.ashbyhq.com/typesafe-ai (linked from typesafe.ai)
- Launch blog date spread: the rendered blog page shows "Sep 15, 2026" (3 occurrences in served HTML) and HN submitted it 2026-09-15T19:25Z; the raw HTML also contains the string "Published Sep 22, 2026, 4:54 AM UTC" (not in rendered text; likely a CMS/last-modified field — unknown).

---

## Collisions excluded
- **Japanese encephalitis virus (JEV):** none surfaced in HN Algolia, GitHub, or npm results for the queries above (all queries paired `jev` with `typesafe`/`system one`); nothing needed excluding, but a bare `jev` query would hit it — do not run one.
- **Typesafe Inc. / Lightbend (Scala company):** not surfaced by these queries; the WebSearch `site:reddit.com` fallback returned `github.com/larsw/awesome-typesafe` (TypeScript type-safety list) — excluded.
- **TypeScript "typesafe" packages on npm:** `typesafe-actions` (2019), `typesafe-i18n`, `typesafe-path`, `typesafe-decorators`, `nestjs-typesafe-decorators`, `typesafe` (2015) — excluded by description/date.
- **PyPI `typesafe` 0.9.1** ("formal type asserting decorators", Krister Hedfors) — excluded.
- **GitHub `yournextstore/yournextstore`** ("typesafe Commerce SDK") and `kitfunso/hippo-memory` — matched on the word "typesafe" only; excluded.
- **`Futureppo/typesafe_register`** ("typesafe.ai注册机，极致优化，无限jev" — an account-farming tool) — about TypeSafe but not a description; excluded from sources.
- **Vercel `jev-vs-gpt-6-astra`** mentions "GPT-6 Astra" — that is OpenAI's model, not a Jev variant.

---

## What could not be found
- **Reddit:** every route failed — reddit.com search JSON HTTP 403; pullpush.io HTTP 429; old.reddit.com served a page with 0 result nodes; WebSearch `site:reddit.com` returned no reddit URLs; WebSearch with `allowed_domains=[reddit.com]` errored "not accessible to our user agent". **No claim either way about Reddit discussion.**
- **Forbes 2026-09-15 article body** (403). The "$200 million valuation" figure therefore rests only on the Forbes headline (search snippet) and Forkast's restatement; it is absent from the Business Wire release.
- **OpenRouter listing:** search snippet claimed `openrouter.ai/typesafe/jev-1.13` with "32,000 token context window", "released on September 18, 2026", "250,000 tokens/second and 1,200 requests/minute"; the page returned 404 and the public `/api/v1/models` (458 rows) contains no `typesafe`/`jev` id. Those numbers are **unknown** and must not be attributed to OpenRouter; check docs.typesafe.ai for rate limits and context window instead (`docs.typesafe.ai/model-jaggedness/jev-1.13` exists, HTTP 200, title "Jev 1.13 jaggedness").
- **Every's independent test** (cited by Forkast: "roughly 25x faster and 580x cheaper than Claude Fable 5.1 ... 0.35 seconds versus 8.83 seconds") — URL not located; not fetched.
- **Any third-party source giving the exact confidence formula.** Best available: docs say it is "a statistic computed from the probability distribution" with a demo approximation "(3 × largest probability − 1) / 2"; Pydantic says "It is a margin, not a probability that the answer is right."
- **Lobste.rs / other aggregators:** 0 parsed results (parser may have missed; not evidence of absence).
- **Discord content** — not entered (login).
