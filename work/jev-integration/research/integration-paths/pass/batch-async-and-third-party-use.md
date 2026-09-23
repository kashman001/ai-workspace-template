# integration-paths — cluster `batch-async-and-third-party-use` (Q6, Q7)

Subject: Jev (TypeSafe, typesafe.ai). Pass agent raw findings. Date checked: 2026-09-23.
Method: `curl -sL` raw HTML/Markdown into a scratchpad, `grep -c` every quote (rule 4);
absence claims rest on the API reference (`docs.typesafe.ai/api.md`), the full docs corpus
(`llms-full.txt`, 910 KB), the sitemap (117 URLs), and the official SDK source (rule 2).
Every search tool has a control query in `## Queries run` (rule 1).

Reference pages checked for Q6 absence claims (all HTTP 200 as `.md`):
`/api`, `/models`, `/introduction/quickstart`, `/sdk`, `/sdk/python`, `/sdk/python/usage`,
`/sdk/python/api/clients/sync`, `/sdk/python/api/clients/async`, `/sdk/python/api/constants`,
`/sdk/python/api/exceptions`, `/sdk/python/api/retries`, `/sdk/python/changelog`,
`/sdk/javascript`, `/sdk/javascript/api/classes/TypeSafeClient`,
`/sdk/javascript/api/interfaces/TypeSafeClientConfig`, `/sdk/javascript/api/interfaces/RequestOptions`,
`/sdk/javascript/api/interfaces/RetryPolicy`, `/sdk/javascript/api/interfaces/SystemOneRequestPayload`,
`/sdk/javascript/changelog`, `/patterns/fan-out`, `/cookbooks/parallel_questions`,
`/introduction/coding-agents`; plus SDK source `typesafe-sdk-python/src/typesafe_sdk/_core/{constants,endpoints,retry,transport,config}.py`
and `typesafe-sdk-js/src/{client,retry,types}.ts`. No `openapi.json` exists (404).

## Claims

### Q6 — batch / streaming / async / webhooks / idempotency / timeouts / retries

| # | Claim (one sentence) | Verdict | Source URL (the page, not the site) | Date checked | How verified | Documented vs. implied |
|---|---|---|---|---|---|---|
| 6.1 | The API reference documents exactly one evaluation endpoint, `POST https://api.typesafe.ai/v1/systemone`, and the SDK source adds only `GET /v1/models`; there is no batch, jobs, or async-submission endpoint in the reference, the sitemap, the docs corpus, or the SDK code. | documented (absence rests on the reference + SDK source) | https://docs.typesafe.ai/api.md ; https://docs.typesafe.ai/models.md ; https://raw.githubusercontent.com/typesafe-ai/typesafe-sdk-python/main/src/typesafe_sdk/_core/constants.py | 2026-09-23 | `grep -c "POST https://api.typesafe.ai/v1/systemone" api.md` = 1; models.md: "Every model on this page is served by the same endpoint, `POST /v1/systemone`." (count 1); constants.py has only `SYSTEM_ONE_PATH = "/v1/systemone"` and `MODELS_PATH = "/v1/models"`; `grep -ci batch` = 0 on api.md, models.md, quickstart, all SDK pages; probes `/batch`, `/batches`, `/jobs`, `/async`, `/api/batch`, `/v1/batch` all 404. | Documented: single endpoint. Absence of batch endpoint is an inference from a complete reference. |
| 6.2 | "Batching" in TypeSafe's docs means packing many typed questions into ONE request against one `state` (the "speculative fan-out" pattern), which the model evaluates in parallel — not a bulk/offline batch API. | documented | https://docs.typesafe.ai/patterns/fan-out.md ; https://docs.typesafe.ai/models.md ; https://docs.typesafe.ai/cookbooks/parallel_questions.md | 2026-09-23 | fan-out.md: "Send many questions in a single call, including speculative ones, and let your code decide what's relevant." (count 1); models.md: "Jev ingests the `state` once and evaluates every question against it in parallel." (count 1); parallel_questions.md: "batching every question into one TypeSafe call is 12.2x cheaper and 10.0x faster with no change in answers" (count 1). | Documented. |
| 6.3 | Per-request batching has documented hard limits: 64k tokens per request (state plus all questions), 32k for state plus the longest question, at most 255 options per Choice, and 2–10 levels per Score. | documented | https://docs.typesafe.ai/models.md ; https://docs.typesafe.ai/api.md | 2026-09-23 | models.md table row "Context length \| 64k tokens per request; 32k tokens for `state` plus the longest question" (raw table fetched as .md, not converted); api.md: "You can have a maximum of 255 options per Choice." and "A Score should have at least two levels; the API accepts up to 10." (each count 1). | Documented, configuration: jev-1.13.0 row of the models table. |
| 6.4 | Streaming is not offered: the API returns one JSON body per request, the docs say Jev "does none of" the streaming an LLM does, and the word "stream" never appears in the API reference (the single hit on models.md is "downstream"). | documented (absence rests on reference + explicit statement) | https://docs.typesafe.ai/api.md ; https://docs.typesafe.ai/introduction/coding-agents.md ; https://docs.typesafe.ai/models.md | 2026-09-23 | `grep -ci stream api.md` = 0; models.md hit is the word "downstream" (`grep -o`); coding-agents.md: "Coding agents rely on an LLM that streams text, calls tools, and edits files based on natural-language instructions. Jev does none of that." (count 1); llms-full.txt 12 "stream" hits are all "downstream", HF `streaming=True` dataset loads, or the coding-agents sentence; SDK source: 0 hits for `stream`/`event-stream`/`SSE`. | Documented (explicit sentence) + reference absence. |
| 6.5 | "Async" in TypeSafe's docs means client-side concurrency (Python `AsyncTypeSafeClient` on httpx2/asyncio, JS promise-returning `APIPromise`), not server-side async jobs; there is no job-submit/poll flow anywhere in the reference. | documented (client async) / absence rests on reference (server async) | https://docs.typesafe.ai/sdk/python/api/clients/async.md ; https://docs.typesafe.ai/sdk/python.md ; https://docs.typesafe.ai/api.md | 2026-09-23 | async.md: "Use AsyncTypeSafeClient to ask questions, list models, and configure asynchronous TypeSafe API requests."; sdk/python.md: "get started with asynchronous or synchronous API calls"; `grep -ci "poll"` = 0 and `grep -ci "job"` = 0 on every reference page listed above; llms-full.txt "polling" = 0, "job" hits are all English usage (e.g. "job-related criteria"). | Documented for SDK async; server-side async absence is inference from complete reference. |
| 6.6 | Webhooks are not documented anywhere: zero occurrences of "webhook" across the API reference, the entire docs corpus (`llms-full.txt`), the homepage, the launch post, and both official SDK sources. | implied absent (0 hits on the complete reference; no page says "we do not offer webhooks") | https://docs.typesafe.ai/api.md ; https://docs.typesafe.ai/llms-full.txt | 2026-09-23 | `grep -ci webhook`: api.md 0, llms-full.txt 0, typesafe.ai homepage 0, launch post 0, SDK `*.ts`/`*.py` 0. | Implied absence; no explicit denial. |
| 6.7 | No idempotency key or replay-safety mechanism is documented: zero hits for "idempot"/"Idempotency-Key" in the docs corpus and SDK source; the SDK does send a retry counter header (`X-TypeSafe-Retry-Count`) and reads a server request id (`x-typesafe-request-id`), and the default retry policy re-POSTs on 408/429/5xx without any dedupe token. | implied absent | https://raw.githubusercontent.com/typesafe-ai/typesafe-sdk-python/main/src/typesafe_sdk/_core/constants.py ; https://docs.typesafe.ai/sdk/javascript/api/interfaces/RetryPolicy.md ; https://docs.typesafe.ai/llms-full.txt | 2026-09-23 | `grep -ci idempot` = 0 on llms-full.txt, api.md, all SDK pages, SDK source; constants.py lines: `RETRY_COUNT_HEADER = "X-TypeSafe-Retry-Count"`, `REQUEST_ID_HEADER = "x-typesafe-request-id"`; llms-full.txt has 12 hits for `x-typesafe-request-id` ("Request ID from `x-typesafe-request-id`, or `undefined` when absent.") and 0 for `retry-count`. | Implied absence. The evaluation call is read-only by design (state in, probabilities out), which is presumably why no key is needed, but no page says so. |
| 6.8 | Client-side timeouts are documented with defaults: the JS SDK default is 10000 ms per attempt "without a total retry budget", and the Python SDK default is 10.0 s "for each HTTP operation"; both are overridable per client and per call. | documented | https://docs.typesafe.ai/sdk/javascript/api/interfaces/TypeSafeClientConfig.md ; https://docs.typesafe.ai/sdk/javascript/api/interfaces/RequestOptions.md ; https://docs.typesafe.ai/sdk/python/api/constants.md ; https://docs.typesafe.ai/sdk/python/api/clients/sync.md | 2026-09-23 | TypeSafeClientConfig.md: "Timeout per attempt in milliseconds, without a total retry budget. Default: 10000." (count 1); RequestOptions.md: "Timeout per attempt in milliseconds; there is no total retry budget." (count 1); constants.md: `DEFAULT_TIMEOUT = 10.0` + "Default timeout in seconds for each HTTP operation." (count 1); sync.md documents `timeout` on the client and per `system_one` call ("to override the client-level value for this call only, in seconds"). | Documented. |
| 6.9 | The Python SDK's RetryPolicy carries a total retry budget (`timeout` default 30.0 s "per SDK call, including the initial attempt and delays") while the JS SDK docs state there is "no total retry budget" — a documented asymmetry between the two official SDKs. | documented (both sides) | https://docs.typesafe.ai/sdk/python/api/retries.md ; https://docs.typesafe.ai/sdk/javascript/api/interfaces/RequestOptions.md ; https://raw.githubusercontent.com/typesafe-ai/typesafe-sdk-python/main/src/typesafe_sdk/_core/retry.py | 2026-09-23 | retries.md line 428: "Total retry budget in seconds per SDK call, including the initial attempt and delays; `None` disables the limit." (count 1); retry.py line 82 `timeout: float \| None = 30.0` and `_stop()` uses `stop_before_delay(self.timeout)`; RequestOptions.md quote as in 6.8. | Documented. |
| 6.10 | Server-side request timeout (how long api.typesafe.ai will hold a request) is not published anywhere. | unknown | https://docs.typesafe.ai/api.md ; https://docs.typesafe.ai/models.md | 2026-09-23 | `grep -ci timeout api.md` = 0, models.md = 0; all 75 "timeout" hits in llms-full.txt are SDK client options or cookbook `timeout=120.0`/`30.0` client settings. | Unknown. Cookbooks passing `timeout=120.0` imply long requests are tolerated, but that is client config, not a server guarantee. |
| 6.11 | Retry guidance is documented in the HTTP reference: on `429 Too Many Requests` or `529 Overloaded`, "retry the request with exponential backoff instead of retrying immediately"; the SDKs do this by default. | documented | https://docs.typesafe.ai/api.md | 2026-09-23 | api.md errors table rows "`429 Too Many Requests` \| You have exceeded your rate limit. Back off and retry after a short delay." and "`529 Overloaded` \| TypeSafe is temporarily overloaded. Retry after a short delay." (each count 1); "Handling rate limits" paragraph (count 1). Table fetched as raw .md. | Documented. |
| 6.12 | The documented default SDK retry policy is: 2 retries after the initial attempt; backoff 500 ms doubling to a 5000 ms cap with 0.25 jitter; retried statuses 408, 429, and 500–599; connection errors and timeouts retried; `Retry-After`/`retry-after-ms` honoured up to 60000 ms (JS) — the Python defaults in source are identical (0.5 s / 5.0 s / 0.25 / {408, 429, 500–599}). | documented | https://docs.typesafe.ai/sdk/javascript/api/interfaces/RetryPolicy.md ; https://docs.typesafe.ai/sdk/python/api/retries.md ; https://raw.githubusercontent.com/typesafe-ai/typesafe-sdk-js/main/src/retry.ts ; https://raw.githubusercontent.com/typesafe-ai/typesafe-sdk-python/main/src/typesafe_sdk/_core/retry.py | 2026-09-23 | RetryPolicy.md: "Maximum retries after the initial attempt; `0` disables retries. Default: 2.", "First backoff delay in milliseconds, doubled up to `backoffMaxMs`. Default: 500.", "Maximum backoff delay in milliseconds. Default: 5000.", "HTTP status codes to retry. Default: 408, 429, and 500–599.", "Honor `Retry-After` and `retry-after-ms` up to `maxRetryAfterMs`. Default: true." (each count 1); retry.ts `DEFAULT_RETRY_POLICY` lines 11–17; retry.py lines 52–73. Note: the Python docs page states the field semantics but the numeric defaults are only in source. | Documented (JS numbers on docs page; Python numbers in source). |
| 6.13 | Rate limits for `jev-1.13.0` are published as 250,000 tokens per second / 1,200 requests per minute, over-limit requests return 429, and TypeSafe warns the limits "are adjusting dynamically" and "can change without notice". | documented | https://docs.typesafe.ai/models.md | 2026-09-23 | "250,000 tokens per second / 1,200 requests per minute" (count 1); "Rate limits are adjusting dynamically." (count 1); "retry with backoff by default and honor the `retry-after` header when the response carries one" (count 1). Configuration: the models-table row for Jev 1.13 (`jev-1.13.0`); scope of the limit (per key / per org) is not stated. | Documented; per-key vs per-org scope undisclosed. |
| 6.14 | The documented error surface is four HTTP statuses — 401, 422, 429, 529 — with JSON bodies; the SDKs add typed exception classes (e.g. `APITimeoutError`, `RateLimitError`, `InternalServerError`) for the same plus 5xx/connection cases. | documented | https://docs.typesafe.ai/api.md ; https://docs.typesafe.ai/sdk/javascript/api/classes/APITimeoutError.md ; https://docs.typesafe.ai/sdk/python/api/exceptions.md | 2026-09-23 | api.md "Errors" table (raw .md) lists exactly `401 Unauthorized`, `422 Unprocessable Entity`, `429 Too Many Requests`, `529 Overloaded`; llms.txt nav lists the JS error classes; exceptions.md description "Handle TypeSafe API errors, rate limits, connection failures, and timeouts." | Documented. |
| 6.15 | Concurrency guidance for high-volume use is implied only by cookbook code (thread pools of 8 workers "gentle on rate limits"), not by a dedicated page. | implied | https://docs.typesafe.ai/llms-full.txt (cookbook `hierarchical_classification` / `sde_cascade` code cells) | 2026-09-23 | `grep -c "WORKERS = 8  # small pool: enough to keep a live run to minutes, gentle on rate limits"` = 1; 10 cookbooks import `ThreadPoolExecutor`; `grep -ci concurren` on api.md/models.md = 0. | Implied (code comment). |
| 6.16 | Request cancellation is documented for the JS SDK (`signal?: AbortSignal` cancels "the request and pending retries"); no equivalent is documented for the Python SDK beyond closing the client. | documented (JS) / unknown (Python) | https://docs.typesafe.ai/sdk/javascript/api/interfaces/RequestOptions.md | 2026-09-23 | "Cancellation signal for the request and pending retries." (count 1); sync.md/async.md: 0 hits for "cancel". | Documented (JS). |

### Q7 — third-party use (marketing testimonials excluded)

| # | Claim (one sentence) | Verdict | Source URL (the page, not the site) | Date checked | How verified | Documented vs. implied |
|---|---|---|---|---|---|---|
| 7.1 | The launch post is dated Sep 15, 2026, bylined "Diogo Almeida, founder, TypeSafe", says Jev is "available today in early access", and links to neither Hacker News nor Product Hunt (its only external links are x.com/typesafeai, a Kahneman book page, and llm-benchmarks.diegoromero.es). | documented | https://typesafe.ai/blog/introducing-system-one-models-and-jev | 2026-09-23 | `grep -c "Sep 15, 2026"` = 2; "Diogo Almeida, founder, TypeSafe" = 2; "available today in early access" = 2; `grep -oE 'href="https?://[^"]+"'` external-link list contains no news.ycombinator.com or producthunt.com; "Hacker News"/"Product Hunt" text count 0. | Documented. |
| 7.2 | The Hacker News launch thread (item 49717558, submitted 2026-09-15T19:25Z by `albelfio`) reached 1976 points and ~512 comments, and the HN Algolia index holds 65 stories/comments matching `typesafe.ai`, 146 matching `"typesafe" jev`, and 960 stories matching `jev` since the launch date. | documented | https://hn.algolia.com/api/v1/items/49717558 ; https://news.ycombinator.com/item?id=49717558 | 2026-09-23 | Algolia item JSON: `created_at 2026-09-15T19:25:03Z`, `points 1976`; search hit `num_comments 512`; my recursive count of the item tree = 510 nodes (record both figures, adopt neither — rule 6); HN HTML page: "1976 points" count 1, "albelfio" count 2. | Documented. |
| 7.3 | Dated third-party press coverage exists from 2026-09-17 onward: Forkast (2026-09-17), TechCrunch (2026-09-18, Tim Fernholz), MarkTechPost (2026-09-19), StartupFortune (2026-09-20), and a Latent Space podcast episode (2026-09-21, YouTube upload 2026-09-21, 114,283 views at check). | documented | see inventory items I-4, I-8, I-14, I-17, I-19 | 2026-09-23 | Each page fetched (HTTP 200); dates from `datePublished`/`published_time`/`<time>` metadata; quotes grep-checked in `## Evidence quotes`. | Documented. |
| 7.4 | Independent engineering write-ups with hands-on tests exist from 2026-09-16 onward (earliest: nearhere.events event-validation comparison, 2026-09-16), including lindfors.no, seangoedecke.com, backnotprop.com, stackness.dev, southbridge.ai, flaviocopes.com, sameernanda.com, unzip.dev, nobodywho.ai, arcturus-labs.com. | documented | see inventory items I-2, I-3, I-7, I-9, I-10, I-11, I-16, I-18, I-20, I-21, I-22 | 2026-09-23 | All fetched 200 with dates in page metadata; one verbatim line per item grep-checked. | Documented. |
| 7.5 | Platform vendors published their own Jev integrations within days of launch: Vercel ships `@ai-sdk/typesafe-ai` (first npm publish 2026-09-16, maintainer `vercel-release-bot`, source `vercel/ai/packages/typesafe-ai`) and a blog post titled "Jev is the fastest-adopted model in AI Gateway history"; Cloudflare lists `typesafe/jev` in its AI model catalog as "Third-party"; LiteLLM documents a TypeSafe pass-through endpoint; LangChain published a guide dated 2026-09-18. | documented | https://registry.npmjs.org/@ai-sdk/typesafe-ai ; https://api.github.com/repos/vercel/ai/contents/packages/typesafe-ai ; https://vercel.com/blog/ai-gateway-jev-model-launch ; https://developers.cloudflare.com/ai/models/typesafe/jev/ ; https://docs.litellm.ai/docs/pass_through/typesafe ; https://www.langchain.com/blog/building-a-harness-with-jev | 2026-09-23 | npm registry JSON: `repository.directory = packages/typesafe-ai`, first version times 2026-09-16, maintainers `['vercel-release-bot']`; GitHub contents API lists `packages/typesafe-ai/{README.md,package.json,src,...}`; Vercel blog `<title>` string count 3; Cloudflare page "Jev is TypeSafe's structured evaluation model" count 1; LiteLLM "Pass-through endpoint for the TypeSafe AI System One API" count 1; LangChain `<time dateTime="2026-09-18...">`. Vercel blog date not extractable from HTML (no `datePublished`); StartupFortune (2026-09-20) already cites the claim, so it is ≤ 2026-09-20. | Documented. Note these are vendor-authored integration pages, not typesafe.ai testimonials. |
| 7.6 | GitHub holds hundreds of third-party repositories referencing Jev/TypeSafe (search `typesafe jev` = 2,374 repos; `"typesafe.ai"` = 580), with the earliest created 2026-09-16T00:07Z (`jexp/neo4jev`) and the largest at 4,033 stars (`TheoLeeCJ/SemIf-OpenJev`, created 2026-09-16, an open re-implementation "not affiliated with Jev or TypeSafe"). | documented | https://api.github.com/search/repositories?q=typesafe+jev ; https://api.github.com/search/repositories?q=%22typesafe.ai%22 | 2026-09-23 | `total_count` fields 2374 / 580 (control `q=anthropic-sdk-python` = 216); per-repo `created_at`/`stargazers_count` from the same JSON. Counts include non-matches (see inventory "Non-matches"). | Documented (API counts). Repo counts are search hits, not verified usage — several are "awesome-jev" lists and re-implementations rather than callers. |
| 7.7 | Third-party client/adaptor packages exist on npm and PyPI: `n8n-nodes-typesafe-ai` (2026-09-17), `jev` on PyPI (decorator package, 2026-09-18), `jev-lint`, `pi-typesafe`, `@mlola/decision-jev`, plus community SDKs for Ruby (`joshmn/typesafe-sdk`), Rust (`Twister915/typesafe-ai`), Java/Spring (`spring-ai-community/spring-ai-typesafe`, 2026-09-20), and MCP servers (`jkudish/jev-mcp`, created 2026-09-17, 309 stars; `itsmostafa/typesafe-mcp`). | documented | https://registry.npmjs.org/-/v1/search?text=typesafe.ai&size=20 ; https://registry.npmjs.org/n8n-nodes-typesafe-ai ; https://pypi.org/pypi/jev/json ; https://api.github.com/search/repositories?q=%22typesafe.ai%22 ; https://raw.githubusercontent.com/jkudish/jev-mcp/main/README.md | 2026-09-23 | npm search `total` 183; registry `time` fields for first publish; PyPI `releases` upload_time; GitHub JSON `created_at`; jev-mcp README first line "Fast, cheap, typed judgments from TypeSafe's Jev model, as MCP tools." (count 1). | Documented. |
| 7.8 | Product Hunt has a listing "Jev by Typesafe: System One model for typed decisions, not chat" (page metadata 2026-09-17, "Launched this week", 12 points) and a second auto-generated product page "Jev: Introducing System One Models & Jev - TypeSafe AI Blog" (2026-09-18); who submitted either is not visible logged-out. | documented (existence) / unknown (submitter) | https://www.producthunt.com/products/jev-by-typesafe ; https://www.producthunt.com/products/jev | 2026-09-23 | Both 200; `<title>` strings; "12 points" count 1; "Launched this week" present; no maker/hunter name in served HTML. | Documented existence; submitter unknown. |
| 7.9 | Reddit could not be searched from this environment: `www.reddit.com/search.json` returned 403 ("blocked by network security"), `old.reddit.com/search.json` returned an HTML wall, and pushshift returned 403 "Not authenticated"; the control query (`q=anthropic`) failed the same way, so this is a blocked tool, not an empty result. | unknown | https://www.reddit.com/search.json?q=typesafe.ai | 2026-09-23 | Exact commands and statuses in `## Fetch log`. | Unknown (tool blocked). |
| 7.10 | X/Twitter: the official account `@typesafeai` (logged-out profile: "An AI lab building intelligence beyond chat", 64 posts, 148.6K followers, joined January 2026) is visible, but third-party X threads could not be fetched logged-out; HN-indexed X links about Jev exist (e.g. `twitter.com/lafalcemateo/status/2101414901365248059`, HN 2026-09-19; `twitter.com/trycua/status/2101014004927729737`, HN 2026-09-18) and are recorded unfetched. | documented (official account) / unknown (third-party threads) | https://x.com/typesafeai ; https://hn.algolia.com/api/v1/search?query=%22system%20one%20model%22 | 2026-09-23 | x.com profile HTML: "An AI lab building intelligence beyond chat" count 2, "148.6K" count 1; X status URLs taken from Algolia `url` fields. | Documented (profile) / unknown (threads). |
| 7.11 | Wikipedia has an article "Jev (AI model)" (metadata 2026-09-19) stating Jev "was released in limited early access on 15 September 2026" alongside a US$40 million seed round led by DCVC — a secondary source; the funding figure was not verified against a primary source in this cluster. | documented (article exists) / unknown (funding, out of scope) | https://en.wikipedia.org/wiki/Jev_(AI_model) | 2026-09-23 | "released in limited early access on 15 September 2026" count 1 (the seed-round sentence has link markup mid-string; visible text extracted, not grep-matched). | Documented existence; funding unverified here. |
| 7.12 | Marketing testimonials on typesafe.ai: none found — the homepage and the launch post contain no named customer quotes (0 hits for "customer", "partner", "said"); the homepage's only social-proof items are self-authored benchmark claims ("193.6x Faster, 444.6x Cheaper", "Zero Hallucinations", "238x Lower input price than Claude Fable 5.1"). | documented | https://typesafe.ai/ ; https://typesafe.ai/blog/introducing-system-one-models-and-jev | 2026-09-23 | Visible-text extraction of both pages; "Zero Hallucinations" count 1 on homepage; launch post text counts: customer 0, partner 0, said 0. | Documented (absence of testimonials on these two pages; other typesafe.ai pages such as /team, /manifesto not checked). |
| 7.13 | Two official TypeSafe GitHub repos predate the public launch — `typesafe-ai/system-one-adapter-python` (created 2026-08-08) and `typesafe-ai/skills` (created 2026-08-24, 1,981 stars) — and the official SDKs were on PyPI from 2026-09-09 (`typesafe-sdk` 0.0.1a0) and npm from 2026-09-12 (`@typesafe-ai/sdk` 0.5.7); these are official, not third-party, but bound the early-access window. | documented | https://api.github.com/search/repositories?q=org:typesafe-ai ; https://pypi.org/pypi/typesafe-sdk/json ; https://registry.npmjs.org/@typesafe-ai/sdk | 2026-09-23 | GitHub JSON `created_at`; PyPI `releases` upload_time list; npm `time` map. | Documented. |

## Third-party use inventory

Format: URL — date — author/venue — what it says about Jev (verbatim, grep-checked) — class.

**I-1** https://news.ycombinator.com/item?id=49717558 — 2026-09-15T19:25Z — HN, submitter `albelfio` — page: "1976 points" (count 1); first comment 19:26 by albelfio: "The doom demo is quite cool"; 19:49 `jrickert`: "Signed up for the beta! :) would love to put this through some real-world shootouts against traditional LLMs" (from Algolia item JSON). — third-party (community thread).

**I-2** https://nearhere.events/blog/typesafe-jev-mistral-gemini-event-validation — 2026-09-16 (`datePublished`) — Near Here (events site engineering blog) — "On the main set, Jev matched 48 of 50 expected decisions and rejected none of the 13 expected-valid events." (count 1) — third-party, hands-on test.

**I-3** https://backnotprop.com/blog/jev-poker/ — 2026-09-17 (`<time datetime>`) — backnotprop — "It said it was ahead and shoved 89.5 into a 22.5 pot, five runs out of five." (substring count 1) — third-party, critical hands-on test (HN 49745212, 2 pts).

**I-4** https://forkast.news/typesafe-ais-jev-is-not-an-llm-and-that-may-be-the-point/ — 2026-09-17T20:55Z (`published_time`) — Forkast — "Alongside co-founders Erik Gafni and Sasha Sheng, Almeida has built Jev on a parallel sampling architecture." (substring "co-founders Erik Gafni and Sasha Sheng" count 1) — third-party press.

**I-5** https://dev.to/valyuai/how-to-use-jev-a-practical-guide-to-typesafes-system-one-model-g5e — 2026-09-17 (page: "Posted on Sep 17") — Prosper Otemuyiwa for Valyu AI, DEV Community — "Jev is a frontier AI model from TypeSafe AI that returns typed, probabilistic decisions instead of generated text." — third-party tutorial (vendor-adjacent: Valyu AI).

**I-6** https://www.producthunt.com/products/jev-by-typesafe — 2026-09-17 (metadata) — Product Hunt — title "Jev by Typesafe: System One model for typed decisions, not chat" (count 2), "12 points" (count 1), "Launched this week" — venue listing; submitter unknown (could be TypeSafe).

**I-7** https://flaviocopes.com/jev/ — published 2026-09-17T21:00 (`datePublished`), "Updated Sep 23, 2026" — Flavio Copes — "A deep dive into Jev, TypeSafe's System One model ... Learn how Jev turns text into typed choices, scores, and probabilities, with JavaScript examples, practical patterns, limits, and real use cases." — third-party tutorial (HN 49774157, 2 pts).

**I-8** https://techcrunch.com/2026/09/18/a-new-kind-of-ai-model-from-a-chatgpt-inventor-is-thrilling-developers/ — 2026-09-18T11:49 PDT — TechCrunch, Tim Fernholz — "ChatGPT broke Diogo Almeida" (count 1; the full sentence "ChatGPT broke Diogo Almeida's heart." has an HTML-entity apostrophe) — third-party press (HN 49763045, 5 pts).

**I-9** https://lindfors.no/blog/a-first-look-at-typesafes-jev/ — 2026-09-18 (`datePublished`) — lindfors.no — "An early-access test of TypeSafe's Jev, a model that answers typed questions with probabilities and writes no text." / title "calibrated judgments for half a cent" (count 10) — third-party, hands-on early-access test (HN 49752426).

**I-10** https://www.seangoedecke.com/two-techniques-for-working-with-system-one-models/ — "September 18, 2026" (count 1) — Sean Goedecke — "I recently wrote about Jev, a new "System One" language model that only outputs decisions" (substring "language model that only outputs decisions" count 1) — third-party engineering essay (HN 49755005, 3 pts).

**I-11** https://stackness.dev/blog/what-is-a-system-one-model-and-where-does-it-go-in-your-stack — 2026-09-18T16:26Z (`datePublished`) — Stackness — "On 15 September 2026" (count 1) opens the "Key numbers" section; page asks "What has TypeSafe demonstrated, and what has it only asserted?" — third-party analysis (HN 49760138, 3 pts).

**I-12** https://www.langchain.com/blog/building-a-harness-with-jev — 2026-09-18 (`<time dateTime="2026-09-18T00:00-07:00">18 Sep 2026`) — LangChain blog — "Jev is a new model" (count 1; full sentence "Jev is a new model released from TypeSafe AI." has link markup) — third-party vendor guide.

**I-13** https://registry.npmjs.org/@ai-sdk/typesafe-ai — first publish 2026-09-16 (versions 0.0.0, 3.0.0, 3.0.1 all 2026-09-16; 3.0.5 on 2026-09-23) — Vercel (`vercel-release-bot`; repo `vercel/ai`, directory `packages/typesafe-ai`, confirmed via GitHub contents API) — description "AI SDK integration for Typesafe AI" (npm search) — third-party vendor integration.

**I-14** https://www.marktechpost.com/2026/09/19/typesafe-ai-releases-jev/ — "September 19, 2026" (count 1) — MarkTechPost, Asif Razzaq — "TypeSafe AI Releases Jev: A System One Model That Returns Typed, Calibrated Decisions Instead of Text" — third-party press.

**I-15** https://en.wikipedia.org/wiki/Jev_(AI_model) — metadata 2026-09-19 — Wikipedia — "released in limited early access on 15 September 2026" (count 1); visible text continues "alongside the announcement of a US$40 million seed round led by DCVC" — secondary source.

**I-16** https://www.southbridge.ai/blog/jev-entity-resolution — "September 20, 2026" (count 2) — Southbridge.AI, Hrishi Olickel — "is a quantum leap forward for data processing pipelines, if harnessed correctly" (count 2) — third-party, production-pipeline write-up (HN 49771931, 3 pts).

**I-17** https://startupfortune.com/typesafe-ais-decision-model-jev-becomes-vercels-fastest-adopted-launch/ — 2026-09-20 (page: "Sep 20, 2026"), Elroy Fernandes — "Vercel, Cloudflare, LangChain, and Langfuse integrated it within three days" (count 2) — third-party press (secondary; cites Vercel).

**I-18** https://arcturus-labs.com/blog/2026/09/21/will-openai-eat-jevs-lunch/ — 2026-09-21 (`<time>`) — Arcturus Labs — "According to Vercel, "Jev was adopted faster than any other model in AI Gateway history." (substring count 1; links https://vercel.com/blog/ai-gateway-jev-model-launch) — third-party analysis (HN 49802383/49805793).

**I-19** https://www.latent.space/p/jev — 2026-09-21T22:13Z (`published_time`) — Latent Space podcast (episode with Diogo Almeida, CEO) — title "Jev: System One models for Prod, not God" (count 4); video https://www.youtube.com/watch?v=cFx9Z3ZXca0 uploadDate 2026-09-21T15:10-07:00, viewCount 114283 — third-party venue, subject interview (HN 49794590, 4 pts).

**I-20** https://sameernanda.com/system-one-models-jev/ — 2026-09-21 — Sameer Nanda — "Jev returns typed decisions instead of p[rose]" (substring count 4) — third-party essay (HN 49791563, 2 pts).

**I-21** https://unzip.dev/0x025-system-one-models/ — 2026-09-22 (`datePublished`) — UNZIP.dev newsletter, issue 0x025 — "a fast, cheap if-statement that knows how sure it is" (count 1) — third-party newsletter (HN 49797664).

**I-22** https://www.nobodywho.ai/posts/jev-in-25-lines/ — 2026-09-22 — NobodyWho — "Everyone on Twitter is all over Jev" (count 1) — third-party, sceptical re-implementation post (HN 49813546).

**I-23** https://vercel.com/blog/ai-gateway-jev-model-launch — date not in served HTML (≤ 2026-09-20 by I-17 citation) — Vercel — `<title>` "Jev is the fastest-adopted model in AI Gateway history" (count 3) — third-party vendor blog. Also https://vercel.com/i/jev-use-cases ("7 practical Jev use cases for AI applications", undated; HN 49797360, 2026-09-22).

**I-24** https://developers.cloudflare.com/ai/models/typesafe/jev/ — undated — Cloudflare AI docs model catalog — "typesafe/jev Third-party Jev is TypeSafe's structured evaluation model." (substring count 1) — third-party vendor catalog entry.

**I-25** https://docs.litellm.ai/docs/pass_through/typesafe — undated — LiteLLM docs — "Pass-through endpoint for the TypeSafe AI System One API." (count 1); "Jev returns typed decisions (a choice, a score, or a yes/no probability) instead of text, so it is called through its own evaluate endpoint rather than /chat/completions." — third-party vendor docs.

**I-26** GitHub (from `api.github.com/search/repositories`, JSON `created_at` / stars at check): `jexp/neo4jev` 2026-09-16T00:07Z (110★); `TheoLeeCJ/SemIf-OpenJev` 2026-09-16 (4,033★, "Independent; not affiliated with Jev or TypeSafe"); `ellipsis-dev/blink` 2026-09-16 (68★); `joshmn/typesafe-sdk` Ruby 2026-09-16; `Twister915/typesafe-ai` Rust 2026-09-16; `devagrawal09/jev-review` 2026-09-16 (572★); `jkudish/jev-mcp` 2026-09-17 (309★); `itsmostafa/typesafe-mcp` 2026-09-17 (275★); `Dicklesworthstone/skillranker` 2026-09-17; `dbreunig/building-with-jev-skill` 2026-09-17; `wfzyx/von` 2026-09-18 (550★, open alternative); `razorback16/openjev` 2026-09-18; `spring-ai-community/spring-ai-typesafe` 2026-09-20; `jaredpalmer/kev` (HN 2026-09-21, "Tiny Jev-like family of decision models built on top of Qwen3.5"); `Futureppo/typesafe_register` 2026-09-21 ("typesafe.ai注册机，极致优化，无限jev" — an account-registration bot, note for the terms subject); at least 12 `awesome-jev*` curation lists (yibie 1,438★, Anil-matcha 816★, heyjunpenn 723★ claiming "834 open-source projects built with Jev", v-modal 680★, AbdelStark 490★). — third-party.

**I-27** npm / PyPI third-party packages (registry `time`/`upload_time`): `n8n-nodes-typesafe-ai` 0.1.0 2026-09-17; PyPI `jev` 0.1.0–0.3.0 all 2026-09-18 ("Decorator that compiles Python function definitions into Jev (TypeSafe System One) queries"); PyPI `typesafe-ai` 0.1.0 2026-09-17 ("Redirect shim ... published as 'typesafe-sdk'" — ownership unclear, possibly official); npm `jev-lint`, `jev-use`, `pi-typesafe`, `pi-jev-model-router`, `@mlola/decision-jev`, `@riskaverse/toolgate`, `@elyracode/jev-tools`, `ctxjev-core`, `jevprune` (all 2026-09-20..23). — third-party.

**Testimonials, excluded:** none found. typesafe.ai homepage and the launch post carry no named customer or partner quotes (visible-text scan; "customer"/"partner"/"said" = 0). Self-authored claims present on the homepage ("193.6x Faster, 444.6x Cheaper", "Zero Hallucinations", "$42 Per Billion input tokens", "238x Lower input price than Claude Fable 5.1") are marketing, not third-party evidence. The Vercel/Cloudflare/LangChain/LiteLLM pages are vendor-published integrations and are counted as third-party, not testimonials.

**Official (not third-party), recorded for context:** `x.com/typesafeai` (64 posts, 148.6K followers, joined January 2026); `github.com/typesafe-ai` org (7 repos: `skills` 1,981★ created 2026-08-24; `system-one-adapter-python` 277★ created 2026-08-08; `typesafe-sdk-js` 229★ 2026-09-04; `typesafe-sdk-python` 210★ 2026-09-04; `daggerverse`, `Overwatch`, `typesafe-ai.github.io`); the separate `github.com/TypeSafeAI` org (7 small community-style repos, e.g. `typesafe-playground` 20★ — naming suggests community, ownership unverified).

**Non-matches (reason):** HN `typesafe` stories pre-Nov-2023 = 1,932 hits, all generic "type-safe" (typeid, gRPC-Web, Gleam, tRPC, Prisma) or Lightbend/Typesafe Inc. — excluded by date and topic; HN `jev` stories pre-launch = 247,210 hits dominated by "Jevons paradox" and "Jevko" — excluded; npm `jev` (created 2021-06-16, last modified 2022-05-06, no description) and npm `typesafe` (2015-10-19) predate the company — unrelated; GitHub `yournextstore/yournextstore` ("typesafe Commerce SDK", 2024) and `kitfunso/hippo-memory` (2026-03) match the string "typesafe-ai" incidentally — unrelated; `Anil-matcha/awesome-jev-by-typesafe` shows `created_at 2023-05-17` — a renamed/repurposed repo, so its creation date is not evidence of pre-launch use; `OpenByteInc/QuantDinger` (created 2025-12-28) added "Jev System One integration" post-launch per its description. No Japanese-encephalitis-virus results surfaced in any query used (all queries were qualified with "typesafe").

## Evidence quotes

Format: quote — URL — `grep -c` count on the saved raw page (`-F` fixed string; `-a` where the page is binary-flagged).

- "POST https://api.typesafe.ai/v1/systemone" — https://docs.typesafe.ai/api.md — 1
- "Evaluate a `state` against a map of typed `questions` and get back structured `answers`, one per question." — https://docs.typesafe.ai/api.md — 1
- "You have exceeded your rate limit. Back off and retry after a short delay." — https://docs.typesafe.ai/api.md — 1
- "TypeSafe is temporarily overloaded. Retry after a short delay." — https://docs.typesafe.ai/api.md — 1
- "retry the request with exponential backoff instead of retrying immediately. Our client SDKs handle this automatically, so no extra handling is needed if you use one of our SDKs with its default retry policy." — https://docs.typesafe.ai/api.md — 1
- "Every model on this page is served by the same endpoint, `POST /v1/systemone`." — https://docs.typesafe.ai/models.md — 1
- "250,000 tokens per second / 1,200 requests per minute" — https://docs.typesafe.ai/models.md — 1
- "Jev ingests the `state` once and evaluates every question against it in parallel." — https://docs.typesafe.ai/models.md — 1
- "retry with backoff by default and honor the `retry-after` header when the response carries one" — https://docs.typesafe.ai/models.md — 1
- "Rate limits are adjusting dynamically." — https://docs.typesafe.ai/models.md — 1
- "Send many questions in a single call, including speculative ones, and let your code decide what's relevant." — https://docs.typesafe.ai/patterns/fan-out.md — 1
- "batching every question into one TypeSafe call is 12.2x cheaper and 10.0x faster with no change in answers" — https://docs.typesafe.ai/cookbooks/parallel_questions.md — 1
- "Coding agents rely on an LLM that streams text, calls tools, and edits files based on natural-language instructions. Jev does none of that." — https://docs.typesafe.ai/introduction/coding-agents.md — 1 (also 1 in llms-full.txt)
- "Timeout per attempt in milliseconds, without a total retry budget. Default: 10000." — https://docs.typesafe.ai/sdk/javascript/api/interfaces/TypeSafeClientConfig.md — 1
- "Timeout per attempt in milliseconds; there is no total retry budget." — https://docs.typesafe.ai/sdk/javascript/api/interfaces/RequestOptions.md — 1
- "Cancellation signal for the request and pending retries." — https://docs.typesafe.ai/sdk/javascript/api/interfaces/RequestOptions.md — 1
- "Maximum retries after the initial attempt; `0` disables retries. Default: 2." — https://docs.typesafe.ai/sdk/javascript/api/interfaces/RetryPolicy.md — 1
- "First backoff delay in milliseconds, doubled up to `backoffMaxMs`. Default: 500." — same page — 1
- "Maximum backoff delay in milliseconds. Default: 5000." — same page — 1
- "HTTP status codes to retry. Default: 408, 429, and 500–599." — same page — 1
- "Honor `Retry-After` and `retry-after-ms` up to `maxRetryAfterMs`. Default: true." — same page — 1
- "Default timeout in seconds for each HTTP operation." (`DEFAULT_TIMEOUT = 10.0`) — https://docs.typesafe.ai/sdk/python/api/constants.md — 1
- "Total retry budget in seconds per SDK call, including the initial attempt and delays; `None` disables the limit." — https://docs.typesafe.ai/sdk/python/api/retries.md — 1 (and 1 in `retry.py`, where the default is `timeout: float | None = 30.0`)
- "Whether to honor `Retry-After` and `retry-after-ms` response headers." — https://docs.typesafe.ai/sdk/python/api/retries.md — 1
- "raised when the request exceeds its timeout" — https://docs.typesafe.ai/sdk/python/api/retries.md — 1
- "WORKERS = 8  # small pool: enough to keep a live run to minutes, gentle on rate limits" — https://docs.typesafe.ai/llms-full.txt — 1
- "Request ID from `x-typesafe-request-id`, or `undefined` when absent." — https://docs.typesafe.ai/llms-full.txt — 12 hits for `request-id`
- `RETRY_COUNT_HEADER = "X-TypeSafe-Retry-Count"` / `REQUEST_ID_HEADER = "x-typesafe-request-id"` / `SYSTEM_ONE_PATH = "/v1/systemone"` / `MODELS_PATH = "/v1/models"` — https://raw.githubusercontent.com/typesafe-ai/typesafe-sdk-python/main/src/typesafe_sdk/_core/constants.py — file printed in full (21 lines)
- `DEFAULT_TIMEOUT_MS = 10_000; DEFAULT_RETRY_POLICY = { maxRetries: 2, backoffInitialMs: 500, backoffMaxMs: 5_000, backoffJitter: 0.25, httpStatuses: new Set([408, 429, ...range(500, 600)]) ... }` — https://raw.githubusercontent.com/typesafe-ai/typesafe-sdk-js/main/src/retry.ts — lines 5–17
- "Sep 15, 2026" — https://typesafe.ai/blog/introducing-system-one-models-and-jev — 2; "Diogo Almeida, founder, TypeSafe" — 2; "available today in early access" — 2; "Our first public model is" — 2 (the word "Jev" follows in a separate element)
- "Zero Hallucinations" — https://typesafe.ai/ — 1
- "1976 points" — https://news.ycombinator.com/item?id=49717558 — 1; "albelfio" — 2
- "ChatGPT broke Diogo Almeida" — TechCrunch (I-8) — 1
- "is a quantum leap forward for data processing pipelines, if harnessed correctly" — Southbridge (I-16) — 2
- "language model that only outputs decisions" — seangoedecke (I-10) — 1
- "shoved 89.5 into a 22.5 pot, five runs out of five" — backnotprop (I-3) — 1
- "On 15 September 2026" — stackness (I-11) — 1
- "System One models for Prod, not God" — latent.space (I-19) — 4
- "a fast, cheap if-statement that knows how sure it is" — unzip.dev (I-21) — 1
- "calibrated judgments for half a cent" — lindfors.no (I-9) — 10
- "Jev matched 48 of 50 expected decisions" — nearhere.events (I-2) — 1
- "co-founders Erik Gafni and Sasha Sheng" — Forkast (I-4) — 1
- "Everyone on Twitter is all over Jev" — nobodywho (I-22) — 1
- "Jev was adopted faster than any other model in AI Gateway history" — Arcturus (I-18) — 1
- "Jev is the fastest-adopted model in AI Gateway history" — Vercel blog (I-23) — 3
- "Jev is TypeSafe's structured evaluation model" — Cloudflare (I-24) — 1
- "Pass-through endpoint for the TypeSafe AI System One API" — LiteLLM (I-25) — 1
- "Jev is a new model" — LangChain (I-12) — 1; "2026-09-18" — 1
- "September 19, 2026" — MarkTechPost (I-14) — 1
- "Vercel, Cloudflare, LangChain, and Langfuse integrated it within three days" — StartupFortune (I-17) — 2
- "released in limited early access on 15 September 2026" — Wikipedia (I-15) — 1
- "System One model for typed decisions, not chat" — Product Hunt (I-6) — 2; "12 points" — 1
- "An AI lab building intelligence beyond chat" — x.com/typesafeai — 2 (`grep -a`); "148.6K" — 1
- "Fast, cheap, typed judgments from TypeSafe's Jev model, as MCP tools." — jev-mcp README — 1

Quotes that did NOT grep as a single string (markup or entities mid-sentence), reported per rule 4: "ChatGPT broke Diogo Almeida's heart" (apostrophe is an HTML entity; prefix matched), "1976 points by albelfio" (markup between; parts matched), "Our first public model is Jev" (span break; prefix matched), "Jev is a new model released from TypeSafe AI" (link markup; prefix matched), "seed round led by DCVC" (0 as a string; sentence visible in extracted text only).

## Queries run

HN Algolia (`https://hn.algolia.com/api/v1/search?query=...`):
- control `anthropic` → nbHits 128,722 (tool works)
- `typesafe.ai` → 65
- `"system one model"` → 8
- `jev typesafe` → 95
- `"typesafe" jev` → 146
- `"system one models"` → 19 (includes the launch thread, 1976 pts / 512 comments)
- `docs.typesafe.ai` → 28
- disambiguation control `typesafe`, tags=story, created_at_i<1700000000 → 1,932 (all generic type-safe / Lightbend era; none about TypeSafe AI)
- disambiguation control `jev`, tags=story, created_at_i<1789000000 → 247,210 (Jevons paradox etc.)
- `jev`, tags=story, created_at_i>=1789000000 → 960
- item fetch `https://hn.algolia.com/api/v1/items/49717558` → 200

GitHub search API (`https://api.github.com/search/repositories?q=...`, unauthenticated):
- control `anthropic-sdk-python` → total_count 216
- `typesafe jev` → 2,374; `"typesafe.ai"` → 580; `typesafe-ai` → 1,009; `jev "system one"` → 759; `org:typesafe-ai` → 7; `user:typesafeai` → 7
- `GET /orgs/typesafe-ai` 200, `/orgs/typesafeai` 200, `/orgs/TypeSafeAI` 200, `/orgs/typesafe` 404
- `GET /repos/vercel/ai/contents/packages/typesafe-ai` → 200 (directory exists)
- `GET /repos/typesafe-ai/{typesafe-sdk-python,typesafe-sdk-js,skills,system-one-adapter-python}` and `/git/trees/main?recursive=1` → 200

npm registry: search `text=typesafe.ai` → total 183; `GET /@typesafe-ai/sdk` 200; `/@ai-sdk/typesafe-ai` 200; `/n8n-nodes-typesafe-ai` 200; `/jev` 200 (2021, unrelated); `/typesafe` 200 (2015, unrelated); `/@typesafe/sdk` 404; `/typesafe-ai` 404; `/@typesafeai/sdk` 404.

PyPI JSON: `typesafe-sdk` 200 (official; 0.0.1a0 2026-09-09 … 0.7.1 2026-09-21); `typesafe-ai` 200 (shim, 2026-09-17); `typesafe_ai` 200 (same); `jev` 200 (2026-09-18); `typesafe` 200 (not inspected — pre-existing name); `typesafeai` 404.

Reddit: `https://www.reddit.com/search.json?q=typesafe.ai` → 403 (HTML "blocked by network security"); with `&raw_json=1` → 403; `https://old.reddit.com/search.json?q=typesafe.ai` → 200 but HTML "Welcome to Reddit" wall, not JSON; control `old.reddit.com/search.json?q=anthropic&limit=2` → not JSON either (tool blocked, not empty); `https://api.pushshift.io/reddit/search/submission/?q=typesafe.ai` → 403 `{"detail":"Not authenticated"}`.

Product Hunt: `https://www.producthunt.com/search?q=typesafe` → 200 (JS shell, no results in HTML); `/products/jev-by-typesafe` 200; `/products/jev` 200; `/products/typesafe-ai` 404; `/products/typesafe` 404.

WebSearch (3 calls, budget-limited): `"typesafe.ai" jev` → 9 links (Wikipedia, MindStudio, docs, LangChain, flaviocopes, typesafe.ai, launch post, Cloudflare, StartupFortune); `"system one model" typesafe jev` → 9 links (docs, DataCamp [403 on fetch], flaviocopes, LangChain, you.com, MindStudio, dev.to, launch post, MarkTechPost); `"docs.typesafe.ai"` → 9 links (six docs pages, a GitHub gist by pjburnhill, LiteLLM, launch post).

## Fetch log

All `curl -sL` with a desktop UA unless noted; status = final HTTP status.

| URL | Status | Bytes |
|---|---|---|
| https://docs.typesafe.ai/ | 200 | 276,036 |
| https://docs.typesafe.ai/sitemap.xml | 200 | 15,616 (117 URLs) |
| https://docs.typesafe.ai/llms.txt | 200 | 16,019 |
| https://docs.typesafe.ai/llms-full.txt | 200 | 910,292 |
| https://docs.typesafe.ai/openapi.json | 404 | — |
| https://docs.typesafe.ai/robots.txt | 200 | 172 |
| https://docs.typesafe.ai/{api,models,sdk,sdk/python,sdk/python/usage,sdk/python/changelog,sdk/python/api/retries,sdk/python/api/constants,sdk/python/api/exceptions,sdk/python/api/clients/sync,sdk/python/api/clients/async,sdk/javascript,sdk/javascript/changelog,sdk/javascript/api/interfaces/RetryPolicy,sdk/javascript/api/interfaces/RequestOptions,sdk/javascript/api/interfaces/TypeSafeClientConfig,sdk/javascript/api/interfaces/SystemOneRequestPayload,sdk/javascript/api/classes/APITimeoutError,sdk/javascript/api/classes/TypeSafeClient,patterns/fan-out,cookbooks/parallel_questions,introduction/quickstart,introduction/coding-agents}.md | 200 each | 508 – 48,484 |
| https://docs.typesafe.ai/{batch,batches,streaming,webhooks,rate-limits,errors,api-reference,api/batch,v1/batch,async,jobs} | 404 each | — |
| https://typesafe.ai/ | 200 | 590,563 |
| https://typesafe.ai/sitemap.xml | 200 | 935 (13 URLs) |
| https://typesafe.ai/robots.txt | 200 | 64 |
| https://typesafe.ai/blog/introducing-system-one-models-and-jev | 200 | 258,883 |
| https://raw.githubusercontent.com/typesafe-ai/typesafe-sdk-python/main/README.md | 200 | 880 |
| https://raw.githubusercontent.com/typesafe-ai/typesafe-sdk-js/main/README.md | 200 | 991 |
| https://raw.githubusercontent.com/typesafe-ai/skills/main/README.md | 200 | 1,336 |
| https://raw.githubusercontent.com/typesafe-ai/system-one-adapter-python/main/README.md | 200 | 6,125 |
| https://raw.githubusercontent.com/typesafe-ai/typesafe-sdk-js/main/src/{client,retry,types,resources/models}.ts | 200 | 489/83/248/28 lines |
| https://raw.githubusercontent.com/typesafe-ai/typesafe-sdk-python/main/src/typesafe_sdk/_core/{constants,endpoints,retry,transport,config}.py | 200 | 21/38/136/176/65 lines |
| https://raw.githubusercontent.com/jkudish/jev-mcp/main/README.md | 200 | 40,984 |
| https://techcrunch.com/2026/09/18/a-new-kind-of-ai-model-from-a-chatgpt-inventor-is-thrilling-developers/ | 200 | 238,218 |
| https://www.latent.space/p/jev | 200 | 785,362 |
| https://flaviocopes.com/jev/ | 200 | 162,659 |
| https://lindfors.no/blog/a-first-look-at-typesafes-jev/ | 200 | 51,581 |
| https://www.seangoedecke.com/two-techniques-for-working-with-system-one-models/ | 200 | 37,777 |
| https://www.southbridge.ai/blog/jev-entity-resolution | 200 | 295,573 |
| https://arcturus-labs.com/blog/2026/09/21/will-openai-eat-jevs-lunch/ | 200 | 49,740 |
| https://forkast.news/typesafe-ais-jev-is-not-an-llm-and-that-may-be-the-point/ | 200 | 72,233 |
| https://vercel.com/i/jev-use-cases | 200 | 740,816 |
| https://vercel.com/blog/ai-gateway-jev-model-launch | 200 | 527,446 |
| https://stackness.dev/blog/what-is-a-system-one-model-and-where-does-it-go-in-your-stack | 200 | 153,368 |
| https://backnotprop.com/blog/jev-poker/ | 200 | 961,925 |
| https://nearhere.events/blog/typesafe-jev-mistral-gemini-event-validation | 200 | 121,005 |
| https://unzip.dev/0x025-system-one-models/ | 200 | 29,939 |
| https://sameernanda.com/system-one-models-jev/ | 200 | 19,829 |
| https://www.nobodywho.ai/posts/jev-in-25-lines/ | 200 | 42,930 |
| https://en.wikipedia.org/wiki/Jev_(AI_model) | 200 | 129,603 |
| https://developers.cloudflare.com/ai/models/typesafe/jev/ | 200 | 199,468 |
| https://docs.litellm.ai/docs/pass_through/typesafe | 200 | 46,067 |
| https://www.langchain.com/blog/building-a-harness-with-jev | 200 | 170,528 |
| https://www.marktechpost.com/2026/09/19/typesafe-ai-releases-jev/ | 200 | 459,212 |
| https://www.datacamp.com/blog/system-one-models-jev | 403 | — (not used) |
| https://dev.to/valyuai/how-to-use-jev-a-practical-guide-to-typesafes-system-one-model-g5e | 200 | 315,376 |
| https://startupfortune.com/typesafe-ais-decision-model-jev-becomes-vercels-fastest-adopted-launch/ | 200 | 97,443 |
| https://github.com/jaredpalmer/kev | 200 | 456,824 (README not parsed — regex limit; HN title used) |
| https://github.com/typesafe-ai | 200 | 291,995 |
| https://www.youtube.com/watch?v=cFx9Z3ZXca0 | 200 | 1,553,355 |
| https://www.npmjs.com/package/@ai-sdk/typesafe-ai | 403 | — (registry JSON used instead) |
| https://registry.npmjs.org/@ai-sdk/typesafe-ai | 200 | 20,565 |
| https://registry.npmjs.org/n8n-nodes-typesafe-ai | 200 | 14,109 |
| https://registry.npmjs.org/@typesafe-ai/sdk | 200 | — |
| https://pypi.org/pypi/{typesafe-sdk,typesafe-ai,typesafe_ai,jev,typesafe}/json | 200 each | — |
| https://www.producthunt.com/products/jev-by-typesafe | 200 | 312,302 |
| https://www.producthunt.com/products/jev | 200 | 207,109 |
| https://www.producthunt.com/search?q=typesafe | 200 | JS shell |
| https://x.com/typesafeai | 200 | 276,536 (logged-out profile header only) |
| https://news.ycombinator.com/item?id=49717558 | 200 | 743,228 |
| https://www.reddit.com/search.json?q=typesafe.ai | 403 | blocked |
| https://old.reddit.com/search.json?q=typesafe.ai | 200 | HTML wall, not JSON |
| https://api.pushshift.io/reddit/search/submission/?q=typesafe.ai | 403 | Not authenticated |

Not opened: `console.typesafe.ai` (playground share links in the docs/launch post were not followed).

## Unsettled

1. **Server-side timeout and maximum request duration** — not published. Settled only by TypeSafe support, a status/SLA page (terms subject Q7), or an authenticated test call (off-limits).
2. **Idempotency / replay semantics** — no page states whether retried POSTs are billed twice or deduplicated by `x-typesafe-request-id`. The evaluation call has no side effects by design, but billing on retry is undisclosed. Settled by the terms/billing pages or support.
3. **Rate-limit scope** (per API key vs per org vs per model) and whether the 250k tok/s figure is per-request-burst or sustained — models.md does not say; the "adjusting dynamically" warning means any figure recorded today may be stale. Settled by the console's logged-in rate-limit page or support.
4. **Whether a batch/offline tier is planned** — nothing public; the only "batch" is many-questions-per-request.
5. **Reddit and X third-party discussion** — tools blocked logged-out. Settled by a logged-in Reddit/X session (outside this brief's scope) or a third-party search API with credentials.
6. **Product Hunt submitter** for "Jev by Typesafe" (official vs community) — not visible logged-out.
7. **Vercel blog publication date** — not in served HTML; bounded ≤ 2026-09-20 by a citing article. Settled by Vercel's RSS feed or the Wayback Machine.
8. **Funding figure ($40M seed, DCVC)** appears only in secondary sources here (Wikipedia, press); belongs to the what-jev-is subject (Q8) for primary verification.
9. **GitHub "usage" counts** — the 2,374 repos are search hits; a large share are `awesome-jev` lists, re-implementations ("SemIf-OpenJev", "von", "kev", "openjev"), and joke repos (`jev-leftpad`). A code-search (authenticated GitHub API) for `api.typesafe.ai/v1/systemone` would separate real callers from mentions.
