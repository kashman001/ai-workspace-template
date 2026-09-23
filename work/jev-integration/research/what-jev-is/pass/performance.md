# Jev — performance pass (Q6: latency, throughput, benchmarks)

Subject: what-jev-is · cluster: performance · date checked: 2026-09-23 · agent: research-wave pass
Model under study: `jev-1.13.0` (aliases `jev-latest`, `jev-preview`); cookbooks mostly ran `jev-1.12`.
Method: curl of raw HTML + Mintlify `.md` variants; tables read from `<table>` markup; every quote below was
grep-confirmed against the saved page text (95 vendor quotes checked programmatically, 0 missing; third-party
quotes copied from the fetched text). No accounts, no API calls, one WebSearch.

## A. Every number found

| # | Number | What it measures | Configuration (or "undisclosed") | Model version | Page | Verbatim quote |
|---|---|---|---|---|---|---|
| 1 | 250,000 tokens/s; 1,200 req/min | Rate limits, per account (meter: TPS and RPM; over either → 429) | "adjusting dynamically", can change without notice | jev-1.13.0 | https://docs.typesafe.ai/models | "250,000 tokens per second / 1,200 requests per minute" |
| 2 | 64k / 32k tokens | Context length: 64k per request (state + all questions); 32k for state + longest single question | — | jev-1.13.0 | https://docs.typesafe.ai/models | "64k tokens per request; 32k tokens for `state` plus the longest question" |
| 3 | 255 options | Max options per Choice question | — | API-level | https://docs.typesafe.ai/api | "You can have a maximum of 255 options per Choice." |
| 4 | 2–10 levels | Score levels | — | API-level | https://docs.typesafe.ai/api | "A Score should have at least two levels; the API accepts up to 10." |
| 5 | ~240 options | Practical Choice reliability ceiling (cookbook claim, lower than the 255 hard limit) | undisclosed basis | jev-1.12 | https://docs.typesafe.ai/cookbooks/classification_using_confidence | "a Choice works reliably up to roughly 240 options" |
| 6 | "about 100 ms" | Typical query completion time | undisclosed (no percentile, region, payload size) | unstated | https://docs.typesafe.ai/concepts/how-to-build-with-system-one | "Most queries complete in about 100 ms. System One is fast enough for real-time request paths and user interfaces." |
| 7 | 150ms | "real-time speeds" | undisclosed | unstated | https://docs.typesafe.ai/concepts/use-case-map | "Frontier intelligence at real-time speeds (150ms) means AI can make decisions faster than human perception." |
| 8 | 70ms–500ms | End-to-end response time, TypeSafe | vendor-run; "generally run from our laptops on the West Coast" | unstated (launch = jev-1.13) | https://typesafe.ai/blog/introducing-system-one-models-and-jev | "End-to-end response time is 70ms-500ms for TypeSafe." |
| 9 | 3 to 329 seconds | End-to-end response time, "frontier models" (comparator) | links to third-party site llm-benchmarks.diegoromero.es; no model list on page | n/a | same blog | "End-to-end response time is 3 to 329 seconds for frontier models." |
| 10 | 40x–200x | Speed vs frontier for "System One shaped queries" | undisclosed beyond the two ranges above | unstated | same blog | "This can range from 40x-200x faster for the same levels of frontier intelligence for System One shaped queries." |
| 11 | "two orders of magnitude" | Faster and more efficient vs existing LLMs | undisclosed | unstated | same blog | "Jev achieves similar levels of intelligence on System One tasks compared to existing LLMs, while being two orders of magnitude faster and more efficient." |
| 12 | 100ms | Real-time use-case framing | undisclosed | unstated | same blog | "100ms speeds means you can use AI in your applications where UX is critical." |
| 13 | 193.6x faster, 444.6x cheaper | Homepage headline | "*based on workflows for System One tasks"; blog says it comes from the workflow evals, reference = avg of GPT-6 Astra + Fable 5.1; comparator model NOT named | unstated | https://typesafe.ai (+ blog) | "193.6x Faster, 444.6x Cheaper." / "*based on workflows for System One tasks" / "This is where the claims of 193.6x faster, 444.6x cheaper on our home page comes from, and we expect that these are on the higher end of real world gains." |
| 14 | $0.000081 & 0.114s vs $0.013880 & 8.566s | Homepage side-by-side demo widget (Jev vs "LLMs") | blog: side-by-side used GPT-5.6 Terra default reasoning, "short, dense" state; "The relatively shorter input paints our model in an advantageous light." | unstated | https://typesafe.ai | "TypeSafe AI Cost $0.000081 Completed in 0.114s LLMs Cost $0.013880 Completed in 8.566s" |
| 15 | 238x | Input price vs Claude Fable 5.1 (0.042 × 238 ≈ $10/Mtok implied) | list-price comparison, input only | jev-1.13.0 | https://typesafe.ai | "238x Lower input price than Claude Fable 5.1" |
| 16 | 10 queries/s ≈ ~$7/hour | Doom demo throughput/cost anecdote | undisclosed payload | unstated | blog | "making 10 queries a second (which ends up costing ~$7/hour)" |
| 17 | 67.8% · $0.0004 · 0.4 s | Workflow evals overview: Jev mean accuracy / cost per case / seconds per case, averaged over 4 workflows | reference labels = avg GPT-6 Astra + Claude Fable 5.1 "both at high thinking"; other models at provider default reasoning; timing method/region/date undisclosed on site | undisclosed (site names no Jev version) | https://evals.typesafe.ai/ | "Jev · workflow · 67.8% · $0.0004 · 0.4 s" |
| 18 | 61.7% · $0.0001 · 0.3 s (n_cases=240) | Security Incidents workflow, Jev | as row 17 | undisclosed | https://evals.typesafe.ai/security_incidents.html | "Jev · workflow · 61.7% · $0.0001 · 0.3 s" |
| 19 | 71.6% · $0.0003 · 0.5 s (n_cases=117) | Agent Trace Observability, Jev | as row 17 | undisclosed | https://evals.typesafe.ai/agent_trace_observability.html | "Jev · workflow · 71.6% · $0.0003 · 0.5 s" |
| 20 | 61.8% · $0.0011 · 0.5 s (n_cases=150) | Invoice Processing, Jev | as row 17 | undisclosed | https://evals.typesafe.ai/invoice_processing.html | "Jev · workflow · 61.8% · $0.0011 · 0.5 s" |
| 21 | 76.0% · $0.0001 · 0.4 s (n_cases=204) | Customer Service, Jev | as row 17 | undisclosed | https://evals.typesafe.ai/customer_service.html | "Jev · workflow · 76.0% · $0.0001 · 0.4 s" |
| 22 | 12.2x cheaper, 10.0x faster | Batching 13 questions in one call vs 13 single calls | GDPR Wikipedia article (~54,000 chars), 8 Noul + 2 Choice + 3 Score, 5 runs each; "speed" SUMS the 13 sequential single-call latencies | jev-1.12 (`TYPESAFE_MODEL = "jev-1.12"`) | https://docs.typesafe.ai/cookbooks/parallel_questions | "one call, all 13 1 $0.000497 0.27s" / "13 calls, one each 13 $0.006090 2.71s" / "batching: 12.2x cheaper, 10.0x faster" |
| 23 | 0.27 s | One batched 13-question call over a ~54k-char state (≈ the only per-request latency with a stated payload on docs.typesafe.ai) | as row 22; region/hardware undisclosed | jev-1.12 | same | "one call, all 13 1 $0.000497 0.27s" |
| 24 | Top-1 5%→18%, Top-5 15%→35%, Top-10 38%→62% | Re-ranking accuracy vs BM25 alone | CLERC, 3,565 passages, 40 queries × 30 candidates = 1,200 calls | jev-1.12 | https://docs.typesafe.ai/cookbooks/rerank_typesafe | "**Top 1** — 5% → 18%" / "**Top 10** — 38% → 62%" / "1200 TypeSafe calls used 1,536,002 input and 25,200 output tokens, costing $0.0645." |
| 25 | 90% / 40% / 70% | SIC classification: accuracy of confident half (≥0.9) / uncertain half / uncertain half when reported one level up | 60 SEC 10-K filings, 75-option Choice, self-reported SIC as label | jev-1.12, 2026-08-12 | https://docs.typesafe.ai/cookbooks/classification_using_confidence | "Across 60 filings, a confidence cutoff of 0.9 splits them in half. The confident half is right 90% of the time; the other half, 40%. Reported one level up, that 40% becomes 70%." |
| 26 | ≈0.81 quality @ ≈$0.10/extraction (gpt-5.5-reasoning only) | SDE cascade chart anchor; cascade's own numbers are chart-only | 100 scrapegraphai prompts; "historical snapshot" | verifier jev-1.12 | https://docs.typesafe.ai/cookbooks/sde_cascade | "sits top-right at ≈0.81 quality for ≈$0.10/extraction" |
| 27 | 4 of 4 vs 2 of 4 | Beam (K=3) vs greedy leaf accuracy | 4 hierarchies, ONE example each | unstated model (snapshot 2026-08-06 in code) | https://docs.typesafe.ai/cookbooks/hierarchical_classification | "Beam search matched 4 of 4 expected leaves; greedy search matched 2 of 4." |
| 28 | 16.0x–125.0x faster; 42.2x–805.1x cheaper | Consistency (Noul) cookbook: LLM time/cost per call ÷ TypeSafe's (14 Nouls, 15 repeats) | production API 2026-09-11; LLM calls under 16-way thread contention, TypeSafe measured separately | jev-1.13.0 | https://docs.typesafe.ai/cookbooks/consistency_noul_cookbook | "claude-haiku-4-5 t=0 15 1780ms $0.001798 16.0x 42.2x" / "gpt-5.5-reasoning 15 11125ms $0.033157 100.2x 778.9x" |
| 29 | 7.2x–113.7x faster; 20.3x–897.4x cheaper | Consistency (Choice) cookbook, 8 Choices, 15 repeats | as row 28 | jev-1.13.0 | https://docs.typesafe.ai/cookbooks/consistency_choice_cookbook | "claude-haiku-4-5 t=0 15 3853ms $0.003498 33.8x 76.1x" / "gpt-5.5-reasoning 15 12978ms $0.041255 113.7x 897.4x" |
| 30 | 0.0102 std dev; 90.8% plurality repeat | Run-to-run consistency | 15 repeats | jev-1.13.0 | consistency cookbooks | "probability standard deviation is `0.0102`, below all LLM probability conditions here." / "compared with TypeSafe's 90.8%" |
| 31 | 0.8s, 10,211 tokens, $0.0015 | Autoformat: two round trips end-to-end | one memo; region undisclosed | unstated | https://docs.typesafe.ai/cookbooks/autoformat | "Two round trips, 10,211 tokens, 0.8s, $0.0015." |
| 32 | 10.0 s (Py) / 10000 ms (JS) per attempt; 2 retries; 30.0 s Py total budget | SDK default timeouts/retries | SDK defaults | SDK | https://docs.typesafe.ai/sdk/python/api/constants, .../javascript/api/interfaces/TypeSafeClientConfig | "DEFAULT_TIMEOUT = 10.0" / "Timeout per attempt in milliseconds, without a total retry budget. Default: 10000." |
| 33 | 0.33 s median, 0.44 s p95, max 1.42 s | THIRD-PARTY: ayautomate, 791 decisions | via OpenRouter, one laptop, 4 parallel; 2026-09-19 | jev-1.13 (`typesafe/jev-1.13-20260917`) | https://www.ayautomate.com/blog/jev-vs-llm-benchmark | "Jev 1.13 0.33 s 0.44 s" / "One laptop through OpenRouter, 4 parallel requests per system." |
| 34 | p50 126.81 ms, p95 231.16 ms, max 401.26 ms (vs Haiku 4.5 688.40 / 896.94 / 1,914.98) | THIRD-PARTY: LiteLLM router classifier | 80 cases × 3 = 240 calls; 2026-09-18 UTC; gateway path unstated | jev-1.13.0 | https://docs.litellm.ai/blog/jev-auto-router-benchmark | "p50 classifier latency 126.81 ms 688.40 ms p95 classifier latency 231.16 ms 896.94 ms" |
| 35 | 0.32 s median, 1.3 s slowest | THIRD-PARTY: lindfors.no, 24 Norwegian documents, 11 questions | via OpenRouter; 2026-09-18 | jev-1.13.0 | https://lindfors.no/blog/a-first-look-at-typesafes-jev/ | "Median latency 0.32 s 2.7 s 26 s Slowest request 1.3 s 17.9 s 250 s" (cols: Jev 1.13 / DeepSeek V4.1 Flash reasoning off / on) |
| 36 | ~430 ms floor; 800 judgements in one call 985 ms | THIRD-PARTY: PriorBench, 5,721 calls | via OpenRouter from Western Europe, 2026-09-20; "cannot separate model latency from gateway latency" | typesafe/jev-1.13-20260917 | https://github.com/priorbench/jev | "~430 ms floor. **800 typed judgements in one call: 985 ms, $0.00075.**" |

## B. Latency — verdict: **implied by vendor, quantified only by third parties**

- Vendor docs give no p50/p95, no per-question latency, no region, and no payload size for any latency figure. Three loose vendor figures coexist: "about 100 ms" (how-to-build), "150ms" (use-case-map), "70ms-500ms" (launch post). The one docs number with a stated payload is the parallel-questions cookbook's **0.27 s for a single 13-question call over a ~54,000-character state** (jev-1.12, region undisclosed).
- The blog's measurement disclosure: "our published evals are generally run from our laptops on the West Coast (this is where our service is currently based)". No docs page backs "70ms-500ms" with a configuration.
- Adding questions is documented as ~free in time: "Adding questions barely changes the response time." (introduction) / "All questions are evaluated in parallel, so adding more questions usually has little effect on response time." (fan-out). Cookbook consistency runs (jev-1.13.0, 2026-09-11) imply ~110 ms/call (gpt-5.5-reasoning 11125ms = 100.2x TypeSafe) but the Jev absolute per-call ms is not printed.
- Third-party (all via OpenRouter, Sept 18–20 2026, jev-1.13): medians 0.33 s (ayautomate, 791 calls), 0.32 s (lindfors, 24 docs), ~430 ms floor (PriorBench, W. Europe); LiteLLM p50 126.81 ms / p95 231.16 ms (gateway path not stated). These are 2–5x faster than the small-LLM comparators they ran, not 40–200x. PriorBench: "Do not put it in a sub-300 ms hot loop from Europe."
- Generation-by-chaining is documented as slow: "While you can force it to by chaining choices, this will not work well and will be very slow."

## C. Throughput / concurrency — verdict: **documented as rate limits only**

- "250,000 tokens per second / 1,200 requests per minute" per account; 429 over either; SDKs retry with backoff and honor `retry-after`. Explicitly unstable: "**Rate limits are adjusting dynamically.** ... the limits above can change without notice ... Higher limits are available on custom and enterprise plans."
- No tokens-per-second generation figure exists (output tokens are near-nil by design; "Output tokens are free"). No concurrency limit documented. 529 Overloaded is a documented status.
- SDK defaults: Python `DEFAULT_TIMEOUT = 10.0` s per HTTP op, RetryPolicy max_retries=2, backoff 0.5→5.0 s, total budget 30.0 s; JS timeout 10000 ms per attempt, maxRetries 2, backoff 500→5000 ms.

## D. Context limits — verdict: **documented**

- "64k tokens per request; 32k tokens for `state` plus the longest question" — "Jev ingests the `state` once and evaluates every question against it in parallel. The 64k budget covers the `state` plus all questions combined; the 32k budget applies to the `state` plus the single longest question."
- Input: "Text only. String, JSON object, or array of text values. No image, audio, or video input."
- Choice ≤255 options (API); Score 2–10 levels; cookbook says reliable "up to roughly 240 options". Blog: "Jev supports a cardinality up to 255."
- Accuracy vs state size is a documented degradation, not a number: "Accuracy falls as the state grows with content unrelated to the decision." / "Jev suffers from context rot".

## E. Benchmarks / calibration — verdict: **vendor workflow evals documented with partial config; public benchmarks deliberately not published; calibration numbers absent**

- Policy: blog FAQ "We deliberately chose *not* to publish performance against *public* benchmarks." Antibenchmaxxing post (2026-09-11): "no standard benchmark table in our model releases" and "New evals will be dated snapshots and immediately retired once posted rather than hill-climbed." The evals site carries no date and no Jev version string (only 2026-05-30 appears, in unrelated markup).
- evals.typesafe.ai (4 workflows; n_cases 240/117/150/204 from the site's data files): Jev overview 67.8% / $0.0004 / 0.4 s. Reference: "the reference labels are generated via an average of the responses of GPT-6 Astra and Claude Fable 5.1, both at high thinking"; "Every model runs at its provider's default reasoning setting." Blog caveats: "We use the average of GPT-6 Astra and Fable 5.1 as the reference answer" (biases toward OpenAI/Anthropic); workflows "were made by individuals on our model capabilities team, so some bias could exist"; "The LLMs use our System One LLM wrapper".
- Jev is NOT the most accurate on the site's own numbers: sol workflow 74.1%, opus 5 workflow 73.1% beat Jev's 67.8%; Jev ties sonnet 5 workflow (67.8%) and trails terra workflow (67.9%). Per-workflow Jev is below the best workflow-mode LLM on all four (security 61.7 vs opus 5 66.2; agent-trace 71.6 vs sol 76.6; invoice 61.8 vs sol 79.1; customer-service 76.0 vs sol 78.3 — quote: "sol · workflow · 78.3% · $0.0323 · 10.1 s").
- Hallucination "0%" is declared, not measured: "Our number is not empirical. Schema matching is guaranteed, thus we can confidently add 0% into the plots." Homepage "Zero Hallucinations" and blog "can't hallucinate" rest on this type-safety definition.
- Calibration: primer states the target ("Outcomes assigned a probability of `0.2` should occur about 20% of the time.") and the caveat ("These rates describe groups of predictions, not a guarantee about any single answer."); the confidence page has no ECE/reliability numbers. Only calibration-adjacent number: SIC cookbook 90%/40%/70% split at confidence 0.9 (60 filings, jev-1.12).
- Cookbook numbers and configs: rows 22–31 above. Note most cookbooks ran `jev-1.12` (Jul–Aug 2026); the two consistency cookbooks ran `jev-1.13.0` (2026-09-11); autoresearch used jev-1.12 (2026-08-03); skill-suggestion jev-1.12 (2026-07-31); citation-check jev-1.12 (2026-08-16); guardrails jev-1.12 (2026-08-15).

## F. Jev 1.13 jaggedness — verdict: **documented** (https://docs.typesafe.ai/model-jaggedness/jev-1.13, "Last reviewed 2026-09-17")

Verbatim headings, in page order: **Literal reading · Math and Numbers** (sub: Counting · Numeric representations · Math using score) **· Date and time comparison · Indirection · Large state full of irrelevant detail · Adversarial content · Contradictory instructions and criteria · Common-sense structural invariants · Generation.**
Summary line: "`jev-1.13` is fast, calibrated, and good at common-sense judgment but it is not perfect." / "It struggles with tasks that require numeric precision." Structural-invariant evidence tables (raw HTML confirmed): Noul 0.22 vs Choice yes 0.01 / no 0.99 / confidence 0.97; refund 0.72 + not_refund 0.47 = 1.19. Consistency claim on the same page: "`jev-1.13` is extremely consistent". Reminder box: "Jev suffers from context rot".

## G. Count / number spreads (recorded, not resolved)

1. Vendor latency: "about 100 ms" (docs) vs "150ms" (docs) vs "70ms-500ms" (blog) vs cookbook 0.27 s (13 Q, 54k chars) vs third-party medians 0.32–0.33 s / p50 127 ms / ~430 ms floor.
2. Speed multiple: "40x-200x" (blog table) vs "two orders of magnitude" vs "193.6x" (homepage/evals) vs homepage widget 8.566/0.114 = 75.1x vs third-party 2.0–5.4x. The evals rows do not reproduce 193.6x/444.6x for any single comparator (sonnet 5 workflow gives 195x time / 294x cost; opus 5 workflow 94x / 440x) — comparator undisclosed.
3. Cost multiple: "444.6x" vs widget 0.013880/0.000081 = 171.4x vs "238x" (Fable 5.1 input price) vs cookbook 20x–897x vs third-party 5x–40x.
4. Choice option ceiling: 255 (API, blog) vs "roughly 240" (cookbook).
5. Evals timing: vendor "0.4 s" per case vs blog "70ms-500ms" per call — consistent only if a case ≈ one call; case→call mapping undisclosed.
6. Comparator range "3 to 329 seconds" (blog) vs evals per-case LLM times 3.4 s–474.4 s.

## H. Things I could not find (pages checked)

- Any p50/p95/p99 latency, any region/hardware for vendor numbers (models, api, how-to-build, use-case-map, introduction, fan-out, primitives*, all 18 cookbooks, blog, homepage, evals.typesafe.ai + 4 sub-pages + cases JS).
- Any concurrency limit or tokens-per-second *served* figure beyond the 250k TPS rate limit (models, api, SDK retries/constants/config).
- Evals site date, Jev version, per-call timing method, number of calls per case (evals index + 4 pages + viewer.js + 4 cases.js).
- Calibration/ECE metrics (confidence.md/html, primer, system-one, jaggedness).
- Homepage FAQ answer bodies ("How can Jev be so fast", "Is Jev deterministic", "Where does it struggle") — only titles are in served HTML; answers are JS-loaded (typesafe.ai raw HTML). Blog FAQ answers were recoverable from inlined JSON.
- Public-benchmark scores: none exist by stated policy (blog FAQ, antibenchmaxxing post).
- Not opened: console.typesafe.ai playground share links (require login).
