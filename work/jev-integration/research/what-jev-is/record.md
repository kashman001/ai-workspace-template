# Research record — `what-jev-is` (jev-integration wave 1, 2026-09-23)

Subject 1 of 3. Questions Q1–Q8 from `research/schema.md`, answered as claims
in the schema's format. Raw cluster findings: `pass/*.md`. Adversarial
re-check: `verification.md`. Narrative: `profile.md`. Unsettled:
`open-verification.md`. All dates checked 2026-09-23. Abbreviations in "How
verified": **md** = Mintlify `.md` variant fetched with curl and grep-checked;
**html** = raw served HTML fetched with curl and grep-checked; **api** =
public JSON endpoint (OpenAPI, npm, PyPI, GitHub, HN Algolia); **lead** =
re-checked by the lead against its own pre-fan-out snapshot or a live fetch
(see `verification.md`).

**Totals:** 62 claims. By primary verdict: 49 `documented`, 2 `implied`,
7 `unknown`, 4 `contradicted` (corrected 2026-09-23; previously: "48 `documented`, 1 `implied`, 7 `unknown`, 5 `contradicted`" — C34 moved `contradicted` → `implied` per the fact-check, and a re-count of the 62 C-rows gives 49 `documented`, not 48; the old line summed to 61). Eight `documented` rows carry a secondary
`unknown` or `contradicted` (configuration undisclosed, enforcement unverified,
or a count spread): C15, C21, C23, C44, C45, C46, C47, C49 (corrected 2026-09-23; previously: "Nine ... C47, C49, C61" — C61's secondary `unknown` is closed, see C61). Standing
claims S2 and S3 are the ones that move (see the table below).

## Standing claims S1–S6 (say this first)

| S | Standing claim | Verdict | Finding |
|---|---|---|---|
| S1 | Jev is TypeSafe's "first public System One Model, optimized for automation" | **documented** | Verbatim homepage FAQ sentence (C1). Docs say "flagship model and the first System One model"; launch post "Our first public model is Jev" (verbatim after tag-stripping; not contiguous in raw HTML — a `<strong>` tag wraps "Jev"). |
| S2 | It returns typed decisions with confidence estimates instead of text | **documented for Choice and Score; contradicted for Noul** | Choice/Score answers carry `probabilities` + `confidence` (0–1). Noul returns one probability `noul` and no `confidence` field (C17–C20). Marketing's "Every decision includes an estimate ..." over-reaches the schema. "Instead of text": documented. |
| S3 | It is "sold on not hallucinating and needing no human in the loop" | **hallucination half documented (as a schema guarantee); human-in-the-loop half implied, conditioned on confidence** | "Zero Hallucinations" (homepage) and "can’t hallucinate" (launch post) exist — but the launch post defines the 0% as schema-level ("Our number is not empirical. Schema matching is guaranteed") and the docs list nine failure modes. Autonomous operation is implied, conditioned on confidence gating that the caller implements: the literal phrase "no human in the loop" is absent, but the docs say "run it a million times in the background without a human co-pilot" (https://docs.typesafe.ai/concepts/use-case-map) and "**High confidence:** Act automatically. The model has a clear read and you can proceed without human involvement." (https://docs.typesafe.ai/confidence), and the homepage says "Set the thresholds for when it acts autonomously and when it asks for review" (https://typesafe.ai); the same confidence page prescribes "Low confidence: Do not act. Route to a human" (C31–C34). The third first-party temper — the homepage FAQ answer "Jev guarantees the shape of its answers, not that every decision is correct" (Framer module script, 2 hits) — is recorded in `terms` claim 5.10 (corrected 2026-09-23; previously: "… (C31–C34)." — the row ended there; cross-pointer to `terms` 5.10 added per R22). (corrected 2026-09-23; previously: "**half documented, half contradicted** ... 'Needing no human in the loop' appears **nowhere**; the only 'humans-in-the-loop' wording is a critique of LLMs, and the docs prescribe 'Low confidence: Do not act. Route to a human' (C31–C34).") |
| S4 | Price "$42 per billion input tokens" / "production prices" | **documented (number); "production prices" wording not on the models page** | models.md: "$42 / $0.042" per Btok / Mtok, "Charged per input token. Output tokens are free." The homepage FAQ heading "Are these prices temporary or subsidized?" (1 hit in served HTML) is answered in the homepage's Framer module script (`https://framerusercontent.com/sites/43bTeC8cU9jZO20XvdK79t/1bDVrPYMWEZ6eWmJvyMH7WadCbl21tfR2JXCIVJyZRA.BkrK7V15.mjs`, 1 hit): "We can serve Jev profitably at our current prices. Our goal is to make intelligence more affordable over time as we improve the technology." (recovered by `terms` 1.7; O9). Qualifiers are the `terms` subject's job. (corrected 2026-09-23; previously: "has no answer in served HTML (C25)." — the answer body sits in the Framer module, not the served HTML; C25 is the models-page row and says nothing about the FAQ, O9 is the right pointer). |
| S5 | Docs at docs.typesafe.ai; console at console.typesafe.ai | **documented** | Docs nav links `https://console.typesafe.ai` ("TypeSafe console"); sdk/python.md: "Set `TYPESAFE_API_KEY` in your environment (create it [here](https://console.typesafe.ai/))". |
| S6 | Nothing on the homepage says how it is called (SDK/HTTP/MCP) | **documented** | Raw homepage HTML (590,563 bytes) has 0 hits for `sdk`, `SDK`, `pip install`, `npm install`, `Python`, `TypeScript`, `JavaScript`, `curl`, `MCP` (C47). The docs answer it: SDK or `POST /v1/systemone`. |

## Claims

### Q1 — Model class name, definition, is Jev the only one

| # | Claim (one sentence) | Verdict | Source URL | Date checked | How verified | Documented vs. implied |
|---|---|---|---|---|---|---|
| C1 | The homepage FAQ states verbatim: "Jev is TypeSafe’s first public System One Model, optimized for automation." | documented | https://typesafe.ai | 2026-09-23 | html, lead [1 hit] | documented (exact wording; curly apostrophe) |
| C2 | TypeSafe defines the class as "a class of AI models built to make fast, structured decisions that software can use directly" that "evaluates a state and returns typed answers and probabilities". | documented | https://docs.typesafe.ai/concepts/system-one | 2026-09-23 | md, lead | documented |
| C3 | The docs call Jev "TypeSafe's flagship model and the first System One model"; the class name is credited to Kahneman's *Thinking, Fast and Slow*. | documented | https://docs.typesafe.ai/concepts/system-one ; https://docs.typesafe.ai/introduction | 2026-09-23 | md | documented |
| C4 | Jev is the only model in the public catalog: the Models page has one "Current models" row (`Jev 1.13` / `jev-1.13.0`) and both aliases resolve to it. | documented | https://docs.typesafe.ai/models | 2026-09-23 | md + html table, lead | documented |
| C5 | Whether a second, non-public System One model exists. | unknown | — (launch post hedges with "first public"; no page names another) | 2026-09-23 | md/html grep of docs corpus | n/a |
| C6 | "System One Model" is written in Title Case on marketing pages and "System One model" in the docs; the launch post also calls them "a new class of frontier models". | documented | https://typesafe.ai ; https://typesafe.ai/blog/introducing-system-one-models-and-jev | 2026-09-23 | html | documented (wording spread only) |

### Q2 — API surface

| # | Claim | Verdict | Source URL | Date checked | How verified | Documented vs. implied |
|---|---|---|---|---|---|---|
| C7 | Base URL is `https://api.typesafe.ai`; the evaluation endpoint is `POST /v1/systemone`; auth is `Authorization: Bearer <API_KEY>`; body is `application/json`. | documented | https://docs.typesafe.ai/api | 2026-09-23 | md, lead | documented |
| C8 | The only other endpoint is `GET /v1/models` (lists names/aliases with `description` and `release_date`); the OpenAPI spec's `paths` contains exactly these two operations — no streaming, batch, or async endpoints. | documented | https://api.typesafe.ai/openapi.json (OpenAPI 3.1.0, `info.version` 0.2.0) ; https://docs.typesafe.ai/models | 2026-09-23 | api, lead | documented (absence rests on the schema, rule 2) |
| C9 | The OpenAPI spec is public but not linked from the docs site (docs `/api` page has `openApiReferenceData: $undefined`; `docs.typesafe.ai/openapi.json` 404s). | documented | https://api.typesafe.ai/openapi.json | 2026-09-23 | api + html | documented (found by probing) |
| C10 | Request body is `{state: string\|object\|array, model: string, questions: map<string, Question>}`, all three required; `questions` has `minProperties: 1`; question keys are chosen by the caller and "not sent to the underlying model". | documented | https://docs.typesafe.ai/api ; openapi.json | 2026-09-23 | md + api, lead | documented |
| C11 | Response body is `{model: string, answers: map<string, Answer>, usage: {input_tokens, output_tokens}}`; `model` echoes the versioned ID that answered ("May differ from the alias supplied in the request"). | documented | https://docs.typesafe.ai/api ; openapi.json | 2026-09-23 | md + api, lead | documented |
| C12 | Documented error statuses are 401, 422 (body `{detail:[{loc,msg,type,...}]}`), 429 (honour `retry-after`), 529 Overloaded; SDK exception classes additionally imply 400/403/404/5xx. | documented (4 statuses); implied (others) | https://docs.typesafe.ai/api ; https://docs.typesafe.ai/sdk/python/api/exceptions | 2026-09-23 | md + html table | documented / implied |
| C13 | A response header `x-typesafe-request-id` exists (exposed as `request_id` in the Python SDK). | documented | https://docs.typesafe.ai/sdk/python/api/types/responses | 2026-09-23 | md | documented |
| C14 | api.md marks `instructions` **required** on all three question types (`ParamField body="instructions" … required`, type `string`/`object`/`array` with no `null`, L79/L120/L158), but the OpenAPI schema omits it from every `required` list (`NoulQuestion` = `['type']`, `ChoiceQuestion` and `ScoreQuestion` = `['criteria','type']`) and types it `anyOf` `string` / `object` / `array` / `null`; both SDKs type it optional-or-None; advanced.md (`/primitives/advanced`, L246) lists it as "`string`, `object`, `array`, or `null`" — `null` in its type list, without the word "optional" (corrected 2026-09-23; previously: "but the OpenAPI schema (`required` = `['type']` / `['criteria','type']`), both SDKs and advanced.md make it optional and nullable" — re-fetched 2026-09-23: openapi.json 14,158 B, api.md 11,772 B, primitives/advanced.md 19,060 B; `docs.typesafe.ai/advanced.md` returns 404). | contradicted | https://docs.typesafe.ai/api vs https://api.typesafe.ai/openapi.json ; https://docs.typesafe.ai/primitives/advanced | 2026-09-23 | md + api, lead | both cited; docs contradict their own schema |
| C15 | The 255-option cap (Choice) and 2–10-level range (Score) are prose-only: OpenAPI has `minItems: 1`, no `maxItems`, no `maxProperties`. | documented (prose) / unknown (enforcement) | https://docs.typesafe.ai/api ; openapi.json | 2026-09-23 | md + api, lead | documented in prose; schema silent |
| C16 | The JS SDK's `state` type admits `null`; OpenAPI and the Python SDK do not. | contradicted | https://docs.typesafe.ai/sdk/javascript/api/interfaces/SystemOneRequestPayload vs openapi.json | 2026-09-23 | md + api | both cited (spread recorded, not resolved) |

### Q3 — How a decision and its confidence come back (load-bearing)

| # | Claim | Verdict | Source URL | Date checked | How verified | Documented vs. implied |
|---|---|---|---|---|---|---|
| C17 | A **Choice** answer is `{type:"choice", choice: string, probabilities: map<label, number>, confidence: number}`, all required; `choice` is "The highest-probability option"; probabilities are "floats that sum to 1" (OpenAPI: "approximately 1"). | documented | https://docs.typesafe.ai/api ; openapi.json | 2026-09-23 | md + api, lead | documented |
| C18 | A **Score** answer is `{type:"score", score: number, legend: map, probabilities: map<level, number>, confidence: number}`; `score` is "The probability-weighted answer across the levels; can land between levels" (e.g. 0×0.0 + 1×0.95 + 2×0.05 = 1.05). | documented | https://docs.typesafe.ai/api ; https://docs.typesafe.ai/primitives/score | 2026-09-23 | md + api, lead | documented |
| C19 | A **Noul** answer is `{type:"noul", noul: number}` — one float, "The yes/no answer on a scale from 0 (no) to 1 (yes)" — and carries **no** `confidence` field. | documented | https://docs.typesafe.ai/api ; https://docs.typesafe.ai/primitives/noul ; openapi.json | 2026-09-23 | md + api, lead | documented ("There is no separate `confidence` value for a Noul") |
| C20 | `confidence` is a number from 0 to 1 that TypeSafe defines as "a statistic computed from the probability distribution the answer already gives you" — a shape/peakedness measure returned "on every Choice and Score answer", not an independent probability of correctness. | documented | https://docs.typesafe.ai/confidence | 2026-09-23 | md, lead | documented |
| C21 | The exact production formula for `confidence` is not published; the docs' interactive demo uses `(3 × largest probability − 1) / 2` and calls it an approximation. | unknown (formula) / documented (approximation label) | https://docs.typesafe.ai/confidence | 2026-09-23 | md, lead; grep `entropy\|formula\|Math.log` across confidence/choice/score/noul pages → demo only | n/a |
| C22 | The demo approximation reproduces every documented 3-option example within 0.01 (peak 0.88 → 0.82 vs published 0.81; 0.95 → 0.925 vs 0.92; 0.85 → 0.775 vs 0.78; 1.0 → 1.0). | implied | https://docs.typesafe.ai/api ; https://docs.typesafe.ai/introduction/quickstart | 2026-09-23 | lead arithmetic on documented examples | implied — suggestive, not a disclosure |
| C23 | Calibration is claimed for the *probabilities*, as a group property: "Calibration is measured across groups of predictions; it does not guarantee that an individual answer is correct." No calibration measurement (ECE, reliability plot) is published. | documented (claim) / unknown (measurement) | https://docs.typesafe.ai/concepts/system-one ; https://docs.typesafe.ai/introduction/machine-learning-primer | 2026-09-23 | md, lead | documented / n/a |
| C24 | The docs recommend three confidence bands (high: act; medium: confirm/flag; low: "Do not act. Route to a human") with thresholds that "scale with risk" and must be tuned per domain; the example uses 0.5 as a floor and 0.9 for a destructive action. | documented | https://docs.typesafe.ai/confidence | 2026-09-23 | md, lead | documented (guidance, not a guarantee) |

### Q4 — Input, examples, limits

| # | Claim | Verdict | Source URL | Date checked | How verified | Documented vs. implied |
|---|---|---|---|---|---|---|
| C25 | For `jev-1.13.0`: price "$42 / $0.042" per Btok / Mtok, input only, "Output tokens are free"; rate limits "250,000 tokens per second / 1,200 requests per minute" (429 over either), explicitly "adjusting dynamically ... can change without notice"; context "64k tokens per request; 32k tokens for `state` plus the longest question"; input "Text only. String, JSON object, or array of text values. No image, audio, or video input." | documented | https://docs.typesafe.ai/models | 2026-09-23 | md + html table (rule 3), lead | documented (configuration: the one listed model; rate limits stated unstable) |
| C26 | A call takes one `state` (string, object, or array) and one or more named questions of type `noul` / `choice` / `score`, each with `instructions` (string, object, or array) and type-specific `criteria`; all questions see the same state and are evaluated independently and in parallel. | documented | https://docs.typesafe.ai/concepts/state ; https://docs.typesafe.ai/primitives | 2026-09-23 | md | documented |
| C27 | Choice `criteria` is a map of option → description (null allowed), max 255 options; Score `criteria` is an ordered array of 2–10 level descriptions (level number = array index); Noul `criteria` is optional `{true, false}` descriptions. | documented | https://docs.typesafe.ai/api ; https://docs.typesafe.ai/primitives/choice ; https://docs.typesafe.ai/primitives/score | 2026-09-23 | md, lead | documented |
| C28 | Instructions and criteria accept JSON structure; questions can reference nested state by backticked dot-and-index paths (e.g. `` `ticket.messages[0].text` ``). | documented | https://docs.typesafe.ai/primitives/advanced ; https://docs.typesafe.ai/api ; example verbatim on https://docs.typesafe.ai/primitives ("Does `ticket.messages[0].text` request a refund?", 2 hits in llms-full.txt, both on that page) (corrected 2026-09-23; previously: "https://docs.typesafe.ai/primitives/advanced ; https://docs.typesafe.ai/api" — the example string is on neither of those two pages) | 2026-09-23 | md | documented |
| C29 | Full worked request/response examples exist (three-question support-ticket example in the quickstart; one-question examples per type in the API reference) — reproduced in the appendix. | documented | https://docs.typesafe.ai/introduction/quickstart ; https://docs.typesafe.ai/api | 2026-09-23 | md, lead | documented |
| C30 | Maximum number of questions per request, behaviour on exceeding 32k/64k tokens, and server-side timeout are not documented (OpenAPI: `minProperties: 1`, no max; api.md lists no size-related status). | unknown | https://docs.typesafe.ai/api ; https://docs.typesafe.ai/models ; openapi.json | 2026-09-23 | md + api grep `maximum\|up to\|limit\|timeout` | n/a |

### S2/S3 wording checks (subject-specific risk)

| # | Claim | Verdict | Source URL | Date checked | How verified | Documented vs. implied |
|---|---|---|---|---|---|---|
| C31 | The homepage says "Every decision includes an estimate of how confident the model is." and "Every Jev decision comes with a confidence estimate"; this is broader than the schema (Noul has none). | contradicted (marketing vs docs) | https://typesafe.ai vs https://docs.typesafe.ai/confidence | 2026-09-23 | html + md, lead | both cited |
| C32 | The homepage has a "Zero Hallucinations" panel and the launch post says Jev "can’t hallucinate"; the launch post defines this as a schema guarantee: "Our number is not empirical. Schema matching is guaranteed, thus we can confidently add 0% into the plots." | documented (wording) | https://typesafe.ai ; https://typesafe.ai/blog/introducing-system-one-models-and-jev | 2026-09-23 | html, lead | documented — "no hallucination" is a claim about type/schema, not correctness |
| C33 | The docs disclose wrong-answer modes: score.md "not a guarantee that the answer is correct"; the jaggedness page lists nine failure-mode sections and says "Jev suffers from context rot". | documented | https://docs.typesafe.ai/primitives/score ; https://docs.typesafe.ai/model-jaggedness/jev-1.13 | 2026-09-23 | md, lead | documented |
| C34 | No TypeSafe page uses the literal phrase "no human in the loop" (0 hits on homepage, launch post and the 910 KB docs corpus), but TypeSafe says the same thing in its own words, conditioned on confidence: "run it a million times in the background without a human co-pilot" (docs use-case-map), "**High confidence:** Act automatically ... you can proceed without human involvement" (docs confidence), "Set the thresholds for when it acts autonomously and when it asks for review" (homepage); the launch post's comparison table places "Human-in-the-loop tasks (chatbots, copilots, coding agents)" in the LLM column [2 hits], and "These flaws mean that LLMs require humans-in-the-loop" (3× homepage, 1× launch post) is a critique of LLMs. The docs prescribe routing low-confidence answers to a human ("Low confidence: Do not act. Route to a human"). | implied (autonomy, conditioned on confidence gating the caller implements) / documented (low-confidence routing to a human) (corrected 2026-09-23; previously: "contradicted (the README paraphrase)") | https://typesafe.ai ; https://typesafe.ai/blog/introducing-system-one-models-and-jev ; https://docs.typesafe.ai/confidence ; https://docs.typesafe.ai/concepts/use-case-map | 2026-09-23 | html + md grep, corrections re-check: "without a human co-pilot" [1], "without human involvement" [1], "acts autonomously" [1], "Human-in-the-loop tasks" [2]; literal "human in the loop" [0], "no human" [0] | implied in equivalent wording; absence of the literal phrase checked on both marketing pages and the docs |

### Q5 — SDKs

| # | Claim | Verdict | Source URL | Date checked | How verified | Documented vs. implied |
|---|---|---|---|---|---|---|
| C35 | Python SDK `typesafe-sdk` (import `typesafe_sdk`): latest 0.7.1 (2026-09-21), MIT, Python ≥3.10, sync `TypeSafeClient` + async `AsyncTypeSafeClient`, deps httpx2/pydantic/tenacity; repo public at github.com/typesafe-ai/typesafe-sdk-python (210 stars). | documented | https://docs.typesafe.ai/sdk/python ; https://pypi.org/pypi/typesafe-sdk/json ; https://api.github.com/repos/typesafe-ai/typesafe-sdk-python | 2026-09-23 | md + api, lead (PyPI) | documented |
| C36 | JavaScript/TypeScript SDK `@typesafe-ai/sdk`: latest 0.6.0 (2026-09-15), MIT, Node ≥20, ESM+CJS+d.ts, zero runtime deps, single promise client `TypeSafeClient.systemOne()`; repo public at github.com/typesafe-ai/typesafe-sdk-js (229 stars); not on JSR. | documented | https://docs.typesafe.ai/sdk/javascript ; https://registry.npmjs.org/@typesafe-ai%2Fsdk ; https://api.github.com/repos/typesafe-ai/typesafe-sdk-js | 2026-09-23 | md + api, lead (npm) | documented |
| C37 | Both SDKs read the same four env vars (`TYPESAFE_API_KEY`, `TYPESAFE_BASE_URL`, `TYPESAFE_DEFAULT_MODEL`, `TYPESAFE_LOG_LEVEL`), default to `jev-latest` and `https://api.typesafe.ai`, use a 10 s per-attempt timeout with 2 retries and backoff, and honour `retry-after`. | documented | https://docs.typesafe.ai/sdk/python/api/constants ; https://docs.typesafe.ai/sdk/javascript/api/variables/ENV | 2026-09-23 | md | documented |
| C38 | No other-language SDK exists: the SDK index has exactly two cards and says "You can also call the HTTP API directly from any language"; grep of all 111 docs pages for Go/Rust/Java/Ruby/PHP/C#/Swift/Kotlin yields only example-data hits. | documented (absence, on the reference) | https://docs.typesafe.ai/sdk | 2026-09-23 | md grep over llms.txt corpus | documented |
| C39 | Initial-public-release dates disagree across sources for the Python SDK only, all in UTC: docs changelog "v0.5.7 (2026-09-14)" vs PyPI upload 2026-09-11T23:05:50Z vs GitHub release title "v0.5.7 (2026-09-12)" (`published_at` 2026-09-11T23:06:00Z). The JS SDK's dates are one instant: npm 2026-09-12T04:13:21Z = GitHub `published_at` 2026-09-12T04:13:23Z = 2026-09-11 21:13 PDT, which is the docs changelog's and GitHub title's "2026-09-11" — a timezone rendering, not a spread. | contradicted (Python date spread only) (corrected 2026-09-23; previously: "Initial-public-release dates disagree across sources: Python docs changelog 2026-09-14 vs PyPI upload 2026-09-11T23:05Z vs GitHub release title 2026-09-12; JS docs 2026-09-11 vs npm 2026-09-12T04:13Z." / "contradicted (date spread)") | https://docs.typesafe.ai/sdk/python/changelog ; https://pypi.org/pypi/typesafe-sdk/json ; https://docs.typesafe.ai/sdk/javascript/changelog ; npm | 2026-09-23 | md + api, lead | both cited (rule 6) |
| C40 | The Python repo's LICENSE file at `main` is the unfilled MIT template ("Copyright (c) [year] [fullname]"), though pyproject/PyPI/GitHub all declare MIT. | documented | https://raw.githubusercontent.com/typesafe-ai/typesafe-sdk-python/main/LICENSE | 2026-09-23 | api (raw), lead | documented (defect) |
| C41 | A first-party "agent skill" (github.com/typesafe-ai/skills, 1,981 stars, MIT, plugin v0.5.7) is a Markdown docs-context skill for Claude Code/Codex, not an SDK; its SKILL.md links a migration guide that returns 404, and the docs page's "reference files" do not exist in the repo tree. | documented | https://docs.typesafe.ai/agent-skill ; https://api.github.com/repos/typesafe-ai/skills ; https://docs.typesafe.ai/migrating-to-v1.md (404) | 2026-09-23 | md + api, lead (404) | documented |
| C42 | TypeSafe ships **no first-party MCP server or CLI** (0 hits for `MCP`/`Model Context Protocol` in the 910 KB llms-full.txt; none of the org's 10 repos); **third-party** MCP servers exist on npm — `@jkudish/jev-mcp` 0.5.0 (author Joey Kudish, MIT, created 2026-09-17, repo github.com/jkudish/jev-mcp), `jevcore-mcp` 0.4.1 (maintainer perrylink, Apache-2.0, created 2026-09-20, repo github.com/PerryLink/jevcore), and at least five more MCP-tagged Jev packages returned by the npm registry search `text=jev mcp` (size 50) on 2026-09-23: `jev-mcp` 0.5.0 (rashed.parvez), `ctxjev-mcp` 0.5.0, `@jkudish/jev-browser` 0.4.1, `@jev-harness/mcp` 0.2.2, `jev-flash-router` 1.0.3 (ravinder82) — a lower bound, none vetted — as do third-party CLIs and adapters (Pydantic AI, Vercel AI Gateway, Spring AI, n8n, LiteLLM) (corrected 2026-09-23; previously: "**third-party** MCP servers exist on npm (`@jkudish/jev-mcp` 0.5.0, 2026-09-17; `jevcore-mcp` 0.4.1, 2026-09-20)"). | documented | https://docs.typesafe.ai/llms-full.txt ; https://api.github.com/orgs/typesafe-ai/repos ; https://registry.npmjs.org/@jkudish%2Fjev-mcp ; https://registry.npmjs.org/jevcore-mcp | 2026-09-23 | api, lead | documented (restated from the cluster's "no MCP anywhere" — see verification D1) |
| C43 | The docs show the Python SDK working through OpenRouter (`~typesafe/jev-latest`) and Vercel AI Gateway (`typesafe-ai/jev`) via `base_url`; a companion `system-one-adapter` (PyPI 0.2.1, MIT) runs the same question API against OpenAI/Anthropic/Gemini for comparison. | documented | https://docs.typesafe.ai/sdk/python/usage ; https://pypi.org/pypi/system-one-adapter/json | 2026-09-23 | md + api | documented |

### Q6 — Latency, throughput, benchmarks

| # | Claim | Verdict | Source URL | Date checked | How verified | Documented vs. implied |
|---|---|---|---|---|---|---|
| C44 | The vendor publishes no percentile latency, region, or hardware; three loose figures coexist: "Most queries complete in about 100 ms" (docs), "real-time speeds (150ms)" (docs), "End-to-end response time is 70ms-500ms for TypeSafe" (launch post, "generally run from our laptops on the West Coast"). | documented (wording) / unknown (configuration) | https://docs.typesafe.ai/concepts/how-to-build-with-system-one ; https://docs.typesafe.ai/concepts/use-case-map ; launch post | 2026-09-23 | md + html, lead | documented; configuration undisclosed |
| C45 | The only docs latency with a stated payload: 0.27 s for one 13-question call over the ~54,000-character GDPR article, `jev-1.12`, 5 runs; batching vs 13 single calls is "12.2x cheaper, 10.0x faster" on the cookbook page but "11.5x cheaper and 9.6x faster" on primitives.md. | documented (number) / contradicted (multiple) | https://docs.typesafe.ai/cookbooks/parallel_questions ; https://docs.typesafe.ai/primitives | 2026-09-23 | md, lead | documented; count spread recorded (rule 6) |
| C46 | Throughput is documented only as rate limits (250,000 tok/s; 1,200 req/min; unstable); no concurrency limit or served tokens-per-second figure exists. | documented / unknown | https://docs.typesafe.ai/models | 2026-09-23 | md, lead | documented |
| C47 | Homepage headline "193.6x Faster, 444.6x Cheaper" is "*based on workflows for System One tasks"; the launch post attributes it to the workflow evals with an undisclosed comparator; the homepage's own side-by-side demo widget (Jev "Cost $0.000081" / "Completed in 0.114s" vs the LLM "Cost $0.013880" / "Completed in 8.566s", 1 hit each on the live page) implies 8.566 / 0.114 = 75.1x faster and 0.013880 / 0.000081 = 171.4x cheaper (arithmetic first recorded in `pass/performance.md` L88–L89) (corrected 2026-09-23; previously: "the homepage's own widget implies 75x/171x" — figure given without its inputs); "238x Lower input price than Claude Fable 5.1" is a list-price ratio. No docs page backs any multiple with a configuration. | documented (wording) / unknown (configuration) | https://typesafe.ai ; launch post | 2026-09-23 | html, lead | documented; configuration undisclosed; spread recorded |
| C48 | TypeSafe "deliberately chose *not* to publish performance against *public* benchmarks" (launch FAQ); an antibenchmaxxing post says evals will be dated snapshots. | documented | https://typesafe.ai/blog/introducing-system-one-models-and-jev (inlined FAQ JSON) | 2026-09-23 | html, lead | documented |
| C49 | The vendor evals site shows Jev at 67.8% mean accuracy / $0.0004 / 0.4 s per case across four workflows (n = 240/117/150/204 for security_incidents / agent_trace_observability / invoice_processing / customer_service, read from each sub-page's linked data file: the `data-cases` attribute points to `https://evals.typesafe.ai/<workflow>-cases.js`, whose `eval.n_cases` is 240 / 117 / 150 / 204; the counts are not rendered as page text) (corrected 2026-09-23; previously: "(n = 240/117/150/204)" with the source given only as "the site's data files"), reference labels = average of GPT-6 Astra and Claude Fable 5.1 "both at high thinking"; Jev is below the page's own best LLM rows (74.1%, 73.1%) on accuracy; the site carries no date or Jev version. | documented (numbers) / unknown (date, version, timing method) | https://evals.typesafe.ai/ and four sub-pages ; n-counts: https://evals.typesafe.ai/security_incidents-cases.js , agent_trace_observability-cases.js , invoice_processing-cases.js , customer_service-cases.js | 2026-09-23 | html, lead ("67.8%" [5], "74.1%" [2], "73.1%" [2]); n-counts re-derived by the corrections agent from the four `-cases.js` files (`eval.n_cases`) | documented; configuration partly undisclosed |
| C50 | Cookbook results with configuration: re-ranking on CLERC (40 queries × 30 candidates, `jev-1.12`) top-1 5%→18%, top-10 38%→62%, $0.0645; SIC classification (60 filings, "75 industry groups" as Choice options, `jev-1.12`, 2026-08-12) confident half 90% right vs 40% for the rest; consistency cookbooks (`jev-1.13.0`, 2026-09-11) 7.2x–125.0x faster and 20.3x–897.4x cheaper than LLMs measured under 16-way contention (TypeSafe's own calls measured sequentially after the pool closed — the cookbook's stated caveat, so the speed ratios compare contended LLM latency with uncontended TypeSafe latency; cost ratios are unaffected) (page tables: speed "7.2x" gpt-5.4-mini single-pick [choice cookbook] / "125.0x" claude-opus-4-8-reasoning [noul cookbook]; cost "20.3x" gpt-5.4-mini single-pick [choice cookbook] / "897.4x" gpt-5.5-reasoning [choice cookbook]; neither page prints "125x"/"897x" unrounded) (corrected 2026-09-23; previously: "than LLMs measured under 16-way contention (page tables: speed "7.2x" gpt-5.4-mini single-pick / "125.0x" claude-opus-4-8-reasoning; cost "20.3x" gpt-5.4-mini single-pick / "897.4x" gpt-5.5-reasoning; the page never prints "125x"/"897x" unrounded)" — R18: choice cookbook L537 `ThreadPoolExecutor(max_workers=16)`, L557–558 "TypeSafe samples are drawn sequentially, after the LLM pool has closed, so each call's latency is a clean round trip rather than one measured under the 16-way LLM thread contention", L590–591 "The LLMs run in a 16-way pool"; noul cookbook L423 / L443–444 same design; per-page counts 2026-09-23: choice `7.2x` 2, `20.3x` 1, `897.4x` 1, `125.0x` 0; noul `125.0x` 1, the other three 0) (corrected 2026-09-23; previously: "75 options" and "7x–125x faster and 20x–897x cheaper" — rounded figures not on the pages as written). | documented | https://docs.typesafe.ai/cookbooks/rerank_typesafe ; https://docs.typesafe.ai/cookbooks/classification_using_confidence ; https://docs.typesafe.ai/cookbooks/consistency_noul_cookbook ; https://docs.typesafe.ai/cookbooks/consistency_choice_cookbook | 2026-09-23 | md (cluster), configurations as stated | documented; vendor-run |
| C51 | Third-party hands-on latency (all via OpenRouter or unstated gateway, jev-1.13, 2026-09-16..20): 0.59 s avg (nearhere, 50 listings), 0.33 s median / 0.44 s p95 (ayautomate, 791 calls), 0.32 s median (lindfors, 24 docs), p50 126.81 ms (LiteLLM, 240 calls), ~430 ms floor from W. Europe (PriorBench, 5,721 calls). | documented (third-party) | https://nearhere.events/blog/typesafe-jev-mistral-gemini-event-validation ; https://www.ayautomate.com/blog/jev-vs-llm-benchmark ; https://lindfors.no/blog/a-first-look-at-typesafes-jev/ ; https://docs.litellm.ai/blog/jev-auto-router-benchmark ; https://github.com/priorbench/jev | 2026-09-23 | html; lead re-checked nearhere and lindfors, others cluster-only (verification N1) | documented; gateway latency inseparable |
| C52 | Known weaknesses for `jev-1.13` ("Last reviewed 2026-09-17"), verbatim section headings: Literal reading; Math and Numbers (Counting, Numeric representations, Math using score); Date and time comparison; Indirection; Large state full of irrelevant detail; Adversarial content; Contradictory instructions and criteria; Common-sense structural invariants; Generation. | documented | https://docs.typesafe.ai/model-jaggedness/jev-1.13 | 2026-09-23 | md, lead | documented |
| C53 | No calibration metric (ECE, reliability diagram) is published anywhere on the docs, evals site, or launch post. | unknown | (checked: confidence, primer, system-one, jaggedness, evals.typesafe.ai) | 2026-09-23 | md + html grep `calibrat` | n/a |

### Q7 — Versions, naming, deprecation, changelog

| # | Claim | Verdict | Source URL | Date checked | How verified | Documented vs. implied |
|---|---|---|---|---|---|---|
| C54 | Naming is `jev-<major>.<minor>.<patch>` (only `jev-1.13.0` catalogued) plus aliases `jev-latest` (stable, SDK default) and `jev-preview` (may move ahead; "currently points to the same model"); aliases move on release "so the answers behind it can change without a change on your side", and the docs advise pinning the versioned ID when thresholds are tuned. | documented | https://docs.typesafe.ai/models | 2026-09-23 | md + html table, lead | documented |
| C55 | Model-id count spread across the docs corpus: `jev-1.13.0` ×20 (models, api, quickstart), `jev-1.13` ×17 (16 on `model-jaggedness/jev-1.13`, 1 on `/models`) (corrected 2026-09-23; previously: "(jaggedness, primitives, two cookbooks)" — re-counted 2026-09-23 on llms-full.txt 910,292 B, regex `jev-1\.13(?![\.\d])` split per `Source:` page: 16 + 1 = 17, no other page), `jev-1.12` ×27 (16 cookbook pages, runs dated 2026-07-31..2026-09) (corrected 2026-09-23; previously: "14 cookbooks" — re-counted by splitting llms-full.txt on its `Source:` lines: 16 of the 111 pages contain `jev-1.12` (not followed by a digit), all under /cookbooks/: autoformat, autoresearch_feature_discovery, citation_check, classification_using_confidence, classifying_rag_passages, date_extraction_cookbook, entity_alignment, function_calling, hierarchical_classification, llm_guardrails, parallel_questions, pre_parsed_value_extraction_cookbook, rerank_typesafe, sde_cascade, semantic_find, skill_suggestion), `jev-latest` ×34, `jev-preview` ×2. | documented (spread) | https://docs.typesafe.ai/llms-full.txt | 2026-09-23 | api grep, lead (27 / 20 confirmed) | documented (rule 6: recorded, not resolved) |
| C56 | Whether `jev-1.12` is still callable. | unknown | https://docs.typesafe.ai/models ("Versioned IDs such as `jev-1.13.0` are accepted ... whether or not they appear in the list") | 2026-09-23 | md | n/a |
| C57 | There is no model deprecation / sunset / support-window policy on any public page. | unknown (absence on the full corpus) | https://docs.typesafe.ai/llms-full.txt ; https://docs.typesafe.ai/api | 2026-09-23 | grep `deprecat\|sunset\|retire\|end-of-life` → no model-related hit | n/a |
| C58 | There is no model changelog; the only changelogs are the two SDK changelogs, which contain no model-version entries; per-model `release_date` is exposed only via `GET /v1/models` (key required). | documented (absence) | https://docs.typesafe.ai/sdk/python/changelog ; https://docs.typesafe.ai/sdk/javascript/changelog ; https://docs.typesafe.ai/models | 2026-09-23 | md, lead | documented |

### Q8 — Who is TypeSafe

| # | Claim | Verdict | Source URL | Date checked | How verified | Documented vs. implied |
|---|---|---|---|---|---|---|
| C59 | TypeSafe AI is a San Francisco AI lab ("Made in SF." — homepage; office "near the Embarcadero station" — team page) that describes itself as "building machine-native intelligence infrastructure for automation" (homepage, launch post and team page); founders per the team page are Diogo Almeida (CEO; "co-invented RLHF and InstructGPT"; "Previously, he was at Google Brain" — team page; ex-OpenAI per the launch post's first-person "At OpenAI, I helped build the methods..."), Sasha Sheng (COO; ex-Meta/FAIR) and Erik Gafni (CTO; repeat founder) (corrected 2026-09-23; previously: "("Made in SF."; office "near the Embarcadero station")" and "ex-Google Brain, ex-OpenAI per the launch post" — page-level attribution: "Google Brain" has 0 hits on the launch post and 4 on the team page; "Embarcadero" 0 on the homepage and 1 on the team page). | documented | https://typesafe.ai ; https://typesafe.ai/team ; launch post | 2026-09-23 | html, lead (team page live) | documented |
| C60 | Funding: $40M seed led by DCVC — "backed by $40 million in seed funding led by DCVC" (The New Stack, 2026-09-21); the site itself says only "backed by top-tier investors". FinSMEs (2026-09-16, "TypeSafe AI Raises $40M in Seed Funding": "$40M" [13], "DCVC" [3]) carries the same figures and is a secondary citation; it returns HTTP 403 to curl's default user-agent but 200 to a browser user-agent (`curl -A "Mozilla/5.0 ..."`, re-checked 2026-09-23). The Business Wire release (2026-09-15) remains bot-walled at lead re-check (corrected 2026-09-23; previously: "FinSMEs (2026-09-16) and the Business Wire release (2026-09-15) carry the same figures but were bot-walled at lead re-check."). | documented (dated third-party press) | https://thenewstack.io/typesafe-jev-system-one/ (primary) ; https://www.finsmes.com/2026/09/typesafe-ai-raises-40m-in-seed-funding.html (secondary; browser UA required) (corrected 2026-09-23; previously: "(cluster-only) https://www.finsmes.com/...") | 2026-09-23 | html, lead [1 hit on TNS]; see verification D2 | documented |
| C61 | Jev launched 2026-09-15: launch post rendered date "Sep 15, 2026", "available today in early access"; HN submission 2026-09-15T19:25:03Z (1,976 points by 2026-09-23); the launch-post HTML's line 3 is the comment `<!-- Published Sep 22, 2026, 4:54 AM UTC -->`, Framer's site-publish stamp (matching `data-framer-page-optimized-at="2026-09-22T04:54:27.064Z"`), i.e. when the site was last rebuilt, not an article date; the inlined CMS field is `"date","2026-09-15T00:00:00.000Z"`. | documented (date) (corrected 2026-09-23; previously: "the launch-post HTML also carries an unrendered 'Published Sep 22, 2026' string of unknown meaning" / "documented (date) / unknown (09-22 string)") | https://typesafe.ai/blog/introducing-system-one-models-and-jev ; https://hn.algolia.com/api/v1/items/49717558 | 2026-09-23 | html + api, lead; corrections re-check of the raw HTML head | documented (corrected 2026-09-23; previously: "documented; spread recorded") |
| C62 | Founding year, investors other than DCVC, and the "$200M valuation" (Forbes headline, 403; Forkast restatement; absent from the press release). | unknown | — | 2026-09-23 | html (403), search snippets only | n/a |

### Third-party descriptions (context for the fit decision; not a schema question)

Fifteen dated, independent sources between 2026-09-15 and 2026-09-23 describe
Jev consistently as "typed decisions and probabilities rather than ... a chat
response" (nearhere), "It does not write text" (Pydantic AI), "The model
doesn’t write. It decides." (The New Stack) (corrected 2026-09-23; previously: "doesn't" — the page renders `doesn&#8217;t`, curly). The community reads confidence the
same way the docs do: "just a convenience step from the probabilities" (HN comment 49785707 by
`preommr`, 2026-09-21T11:12:03Z, in story 49784706 "Jev-Leftpad" — not the
launch thread; corrected 2026-09-23, previously: "(HN, 2026-09-21)"), "It is a margin, not a probability that the answer is right."
(Pydantic AI docs). Skepticism is on record too: launch language "seemed like a
parody/con/shady at first" and "I had used versions of bert to achieve the same
functionality years ago" (both HN comment 49767192 by `prometheus1992`,
2026-09-19T15:10:29Z, in story 49765348 "I built non-autoregressive decision
models with RL a year ago" — not the launch thread; the second sentence is quoted
back in comment 49767752; corrected 2026-09-23, previously: "(HN, 2026-09-19)"). Full list, queries and collisions:
`pass/third-party-descriptions.md`.

---

## Appendix — verbatim quotes (load-bearing or surprising)

Each quote was grep-confirmed on its page on 2026-09-23 (hit counts in
`verification.md`).

**Class and product**
- https://typesafe.ai (FAQ): "System One Models are a new class of AI model built for decisions inside software. Jev is TypeSafe’s first public System One Model, optimized for automation. Send Jev structured questions and get typed decisions with probabilities and confidence that your software can act on."
- https://docs.typesafe.ai/concepts/system-one: "System One models are a class of AI models built to make fast, structured decisions that software can use directly. A System One model evaluates a [state](/concepts/state) and returns typed answers and probabilities."
- https://docs.typesafe.ai/concepts/system-one: "Jev is TypeSafe's flagship model and the first System One model."
- https://docs.typesafe.ai/introduction/coding-agents: "Jev is a [System One model](/concepts/system-one). It does not generate text, write code, or hold a conversation."
- https://typesafe.ai/blog/introducing-system-one-models-and-jev: "Think of Jev as a frontier-intelligence function call: unstructured state in, typed probabilistic decisions out."

**API shape** (https://docs.typesafe.ai/api)
```
POST https://api.typesafe.ai/v1/systemone
Authorization: Bearer <API_KEY>
Content-Type: application/json
```
Request (quickstart, three question types):
```json
{
  "state": "Hi, I've been trying to connect my Stripe account for 3 days and the integration keeps failing. I'm losing sales. Please help ASAP.",
  "model": "jev-latest",
  "questions": {
    "department": { "type": "choice", "instructions": "Which team should handle this",
      "criteria": { "billing": "Payment or subscription issues", "technical": "Bugs or integration problems", "sales": "Pricing or account questions" } },
    "frustration": { "type": "score", "instructions": "How frustrated the customer appears",
      "criteria": [ "Calm, just stating facts", "Frustrated but civil", "Very angry, strong language" ] },
    "is_urgent": { "type": "noul", "instructions": "The message conveys urgency or time-sensitivity" }
  }
}
```
Response (quickstart):
```json
{
  "model": "jev-1.13.0",
  "answers": {
    "department": { "type": "choice", "choice": "technical", "confidence": 0.78,
      "probabilities": { "technical": 0.85, "sales": 0.0, "billing": 0.15 } },
    "frustration": { "type": "score", "score": 1.0, "confidence": 1.0,
      "legend": { "0": "Calm, just stating facts", "1": "Frustrated but civil", "2": "Very angry, strong language" },
      "probabilities": { "0": 0.0, "1": 1.0, "2": 0.0 } },
    "is_urgent": { "type": "noul", "noul": 1.0 }
  },
  "usage": { "input_tokens": 392, "output_tokens": 65 }
}
```
(Whitespace compacted; field names, values and order as published.)

- api.md: "Every answer carries a `type` matching its question. Choice and Score answers also carry a `confidence` between 0 to 1, derived from the answer's probability distribution."
- api.md: "You can have a maximum of 255 options per Choice." / "A Score should have at least two levels; the API accepts up to 10."
- openapi.json ChoiceAnswer.confidence: "Confidence in the selected choice, from 0 to 1. Higher values indicate greater certainty; use lower values to flag uncertain selections for review."
- openapi.json NoulAnswer.noul: "Probability of a yes answer or a true statement, from 0 to 1. Values near 1 favor yes or true, values near 0 favor no or false, and values near 0.5 indicate uncertainty."

**Confidence** (https://docs.typesafe.ai/confidence unless noted)
- "The answer's `confidence` property collapses that shape into a single number from 0 to 1, so you can threshold on it without doing the math yourself. (Noul answers don't carry one.)"
- "`confidence` is a statistic computed from the probability distribution the answer already gives you. TypeSafe computes it for you and returns it on every Choice and Score answer, so the common case needs no extra work on your side."
- "We provide `confidence` as a convenient measure that fits most use-cases, but you are never locked into our definition."
- Demo caption: "This demo uses (3 × largest probability − 1) / 2 to approximate confidence for three options."
- "**Low confidence:** Do not act. Route to a human, request clarification, or fall back to a different system."
- https://docs.typesafe.ai/primitives/noul: "There is no separate `confidence` value for a Noul, unlike a [Choice](/primitives/choice) or a [Score](/primitives/score). A Noul's probability distribution has only two outcomes, yes and no, so the single `noul` value describes it completely."
- https://docs.typesafe.ai/primitives/score: "In these examples, confidence 1.0 means the returned distribution puts all its probability on one level. This describes the model's answer, not a guarantee that the answer is correct."
- https://docs.typesafe.ai/concepts/system-one: "System One models are trained for calibrated decisions: their probabilities are optimized against outcomes to reflect uncertainty. Calibration is measured across groups of predictions; it does not guarantee that an individual answer is correct."

**Models page** (https://docs.typesafe.ai/models)
- "| Price (per Btok / per Mtok) | \$42 / \$0.042 |" / "**Price:** Charged per input token. Output tokens are free."
- "| Rate limits | 250,000 tokens per second / 1,200 requests per minute |"
- "| Context length | 64k tokens per request; 32k tokens for `state` plus the longest question |"
- "| Input | Text only. String, JSON object, or array of text values. No image, audio, or video input. |"
- "**Rate limits are adjusting dynamically.** We are serving a very large volume of demand, and the limits above can change without notice while we do"
- "`jev-preview` currently points to the same model as `jev-latest`. There is no preview build available right now."
- "Jev is not fine-tuned or LoRA-adapted with customer data." / "Jev is not trained on customer requests or responses."

**Hallucination and humans** 
- https://typesafe.ai: "Zero Hallucinations" (panel heading); "Every Jev decision comes with a confidence estimate, so your software can act when confidence is high and escalate when it is not."
- https://typesafe.ai: "These flaws mean that LLMs require humans-in-the-loop." (about RLHF LLMs)
- https://typesafe.ai: "Set the thresholds for when it acts autonomously and when it asks for review." (served HTML, 1 hit; `documented`, first-party; added 2026-09-23 per R22)
- Launch post: "While Jev gives up string generation, it’s optimized for structured outputs and *can’t* hallucinate." (verbatim after tag-stripping; not contiguous in raw HTML — `<em>` wraps "can’t", shown here as *can’t*)
- Launch post: "Our number is not empirical. Schema matching is guaranteed, thus we can confidently add 0% into the plots."
- Launch post FAQ (inlined JSON): "We deliberately chose *not* to publish performance against *public* benchmarks."
- https://docs.typesafe.ai/model-jaggedness/jev-1.13: "Jev isn't perfect. Here are some jagged edges we are aware of with jev-1.13. Many of these will be fixed in later versions." / "Jev suffers from context rot"

**Performance wording**
- https://docs.typesafe.ai/concepts/how-to-build-with-system-one: "Most queries complete in about 100 ms. System One is fast enough for real-time request paths and user interfaces."
- https://docs.typesafe.ai/concepts/use-case-map: "Frontier intelligence at real-time speeds (150ms) means AI can make decisions faster than human perception."
- Launch post: "End-to-end response time is 70ms-500ms for TypeSafe." (verbatim after tag-stripping; not contiguous in raw HTML — `</strong>` closes after "500ms") / "This can range from 40x-200x faster for the same levels of frontier intelligence for System One shaped queries."
- https://typesafe.ai: "193.6x Faster, 444.6x Cheaper." / "*based on workflows for System One tasks"
- https://docs.typesafe.ai/primitives: "11.5x cheaper and 9.6x faster than 13 separate calls" vs https://docs.typesafe.ai/cookbooks/parallel_questions: "batching: 12.2x cheaper, 10.0x faster"

**SDKs**
- https://docs.typesafe.ai/sdk: "Our client SDKs provide typed questions and answers for the TypeSafe API and handle retries automatically with their default retry policy." / "You can also call the [HTTP API](/api) directly from any language."
- https://docs.typesafe.ai/sdk/python/api/constants: `API_KEY_ENV = 'TYPESAFE_API_KEY'` / `DEFAULT_BASE_URL = 'https://api.typesafe.ai'` / `DEFAULT_MODEL = 'jev-latest'` / `DEFAULT_TIMEOUT = 10.0`
- Python LICENSE at `main`: "MIT License" / "Copyright (c) [year] [fullname]"

**Third-party**
- https://pydantic.dev/docs/ai/models/typesafe/: "Confidence in each answer is on the response, in provider_details['confidence'] : 0 to 1, one number per field, so one threshold reads the same way across an output type. It is a margin, not a probability that the answer is right."
- https://thenewstack.io/typesafe-jev-system-one/ (2026-09-21): "When TypeSafe emerged last week after two years in stealth, backed by $40 million in seed funding led by DCVC, to launch its first model, Jev, ... The model doesn’t write. It decides." (corrected 2026-09-23; previously: "doesn't" — the page renders `doesn&#8217;t` (curly apostrophe entity), 1×; straight `doesn't write` 0× in raw HTML)
- https://nearhere.events/blog/typesafe-jev-mistral-gemini-event-validation (2026-09-16): "We requested jev-latest ; responses identified jev-1.13.0 ." / "Average response time 2.90s 3.40s 0.59s"
- HN comment 49785707 (`preommr`, 2026-09-21T11:12:03Z, story 49784706 "Jev-Leftpad", https://news.ycombinator.com/item?id=49785707): "the "confidence" score is... maybe not what people think it is - kind of useless, and just a convenience step from the probabilities." (corrected 2026-09-23; previously: "HN 49717558 (2026-09-21, `preommr`)" — the comment is not in the 49717558 launch thread; id verified via https://hn.algolia.com/api/v1/items/49785707)

---

## Progress

### [gen 1] 2026-09-23 — start
- Read brief, method-rules.md, schema.md, rulings.md, item README.
- Docs reconnaissance: docs.typesafe.ai is Mintlify; every page has a `.md` variant and `https://docs.typesafe.ai/llms.txt` lists all ~110 pages (API reference at `/api`, `/models`, `/confidence`, `/primitives/*`, `/sdk/python`, `/sdk/javascript`, `/model-jaggedness/jev-1.13`, `/agent-skill`, `/legal`). Jev model id seen in index: `jev-1.13`.
- Next: fan out five clusters (product-and-class, api-reference, sdks, performance, third-party-descriptions) into `pass/<cluster>.md`.

### [gen 1] 2026-09-23 — fan-out launched; lead's independent read of load-bearing pages
- Five cluster sub-agents launched in one message (product-and-class, api-reference, sdks, performance, third-party-descriptions) → `pass/<cluster>.md`.
- Snapshotted 27 public pages (docs `.md` variants + homepage/launch raw HTML) to the session scratchpad for grep-based quote checks at verification.
- Lead read `api.md`, `confidence.md`, `models.md` directly (independent of the clusters, so verification is not ratification). Noted: `POST https://api.typesafe.ai/v1/systemone`, `Authorization: Bearer`; three question types noul/choice/score; Choice/Score answers carry `probabilities` + `confidence` (0–1, "derived from probabilities"); Noul answers carry `noul` 0–1 and no confidence; models page table: `jev-1.13.0`, $42/Btok, 250,000 tok/s + 1,200 rpm, 64k/32k context, text only; aliases `jev-latest` and `jev-preview` both → `jev-1.13.0`.
- Next: wait for clusters, then verify (rule 8: record moves in both directions), then synthesize.

### [gen 1] 2026-09-23 — cluster `sdks` returned
- `pass/sdks.md` written (192 lines). Headline: two SDKs (Python `typesafe-sdk` 0.7.1 MIT, JS `@typesafe-ai/sdk` 0.6.0 MIT), both repos public under github.com/typesafe-ai; no MCP server found; agent skill repo is docs-context only; several date discrepancies between docs changelog and registries flagged for verification. Waiting on the other four clusters.

### [gen 1] 2026-09-23 — cluster `product-and-class` returned
- `pass/product-and-class.md` written (231 lines). Headline: S1 wording found verbatim in homepage FAQ; S2 holds for Choice/Score only (Noul has no confidence field); S3 half-contradicted (launch post defines "can't hallucinate" as schema-level; "no human in the loop" appears nowhere, docs prescribe routing low confidence to a human). Version spread jev-1.13.0 / jev-1.13 / jev-1.12 across docs; $40M seed (FinSMEs 2026-09-16); launch post 2026-09-15. Waiting on api-reference, performance, third-party.

### [gen 1] 2026-09-23 — cluster `third-party-descriptions` returned
- `pass/third-party-descriptions.md` written (28 queries logged, 16 source blocks). Headline: ~15 dated third-party sources; earliest HN 2026-09-15; hands-on reports 09-16..09-21 (one reports 0.59s avg latency, jev-1.13.0); community reads confidence as derived from probabilities ("a margin, not a probability that the answer is right" — Pydantic docs). Forbes "$200M valuation" and OpenRouter numbers flagged as unusable.
- Cross-cluster tension to verify: `sdks` says "No MCP server anywhere"; `third-party` lists "MCP integrations" — likely first-party absence vs third-party presence; must be stated precisely. Waiting on api-reference, performance.

### [gen 1] 2026-09-23 — cluster `api-reference` returned
- `pass/api-reference.md` written (94 quotes grep-verified + 11 OpenAPI strings). Headline: two endpoints (`POST /v1/systemone`, `GET /v1/models`); public OpenAPI 3.1 at `https://api.typesafe.ai/openapi.json` (unlinked, found by probing — verification target); docs-vs-OpenAPI discrepancies (instructions required vs optional; 255-option / 10-level caps are prose-only); batching speedup spread 12.2x/10.0x vs 11.5x/9.6x. Waiting on performance.

### [gen 1] 2026-09-23 — verification and synthesis complete
- All five clusters returned (pass/ = 1,169 lines). Lead verification: 41 checks — 34 survived, 4 downgraded, 1 overturned as worded (the `sdks` "no MCP server anywhere" → no *first-party* MCP server; third-party MCP packages exist on npm), 2 not re-checkable by lead and flagged (historical, pre-correction figure; see verification.md scorecard). Funding sources FinSMEs/Morningstar bot-walled at re-check; claim re-sourced to The New Stack (verbatim hit). One new implied claim: the docs' demo confidence approximation reproduces all four documented examples within 0.01.
- Deliverables written: `record.md` (62 claims, S1–S6 table, verbatim appendix), `profile.md`, `verification.md`, `open-verification.md` (18 items, access-tagged) (historical, pre-correction figure; see open-verification.md — 18 rows, of which O11 closed 2026-09-23 → 17 open).
- Rule-7 grep of the item directory for the two moved claims: deliverables consistent; the earlier progress blocks above record the pre-verification wording as history.
- Item complete for the lead; hand-off to the wave's fact-checker.
