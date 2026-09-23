# Profile — what Jev is (one page, 2026-09-23)

**Jev** is the only public model from **TypeSafe AI**, a San Francisco lab
that emerged from stealth on 2026-09-15 with a $40M seed round led by DCVC
(founders: Diogo Almeida, CEO, co-inventor of RLHF/InstructGPT; Erik Gafni,
CTO; Sasha Sheng, COO). TypeSafe calls its model class **"System One
models"**: "a class of AI models built to make fast, structured decisions that
software can use directly" — the name is borrowed from Kahneman. The homepage
FAQ carries the exact sentence the item README paraphrased: "Jev is TypeSafe’s
first public System One Model, optimized for automation." Jev is still marked
"in early access" on the homepage as of today.

**What a call is.** One HTTP endpoint, `POST https://api.typesafe.ai/v1/systemone`
(bearer API key), plus `GET /v1/models`. A request is `{state, model, questions}`:
`state` is text or JSON (text only — no images/audio), `model` is usually the
alias `jev-latest` (→ `jev-1.13.0`, the sole catalogued version), and
`questions` is a map you key yourself, each question one of three types —
**Noul** (yes/no), **Choice** (pick one of up to 255 labelled options), or
**Score** (rate against 2–10 ordered levels). All questions in a request are
evaluated against the same state in parallel; adding questions is documented as
nearly free in latency. Limits: 64k tokens per request, 32k for state plus the
longest question; rate limits 250,000 tokens/s and 1,200 requests/min, stated
to be changing without notice. Price: $42 per billion input tokens
($0.042/Mtok); output tokens free.

**How a decision comes back — the load-bearing fact.** Every answer is a small
typed JSON object discriminated by `type`. A **Choice** returns `choice` (the
label string), `probabilities` (label → float, summing to ~1) and
`confidence`. A **Score** returns `score` (a probability-weighted float that can
sit between levels), `legend`, `probabilities` (level → float) and `confidence`.
A **Noul** returns a single float `noul` (P(yes), 0–1) and **no confidence
field**. `confidence` is a 0–1 number that TypeSafe defines as "a statistic
computed from the probability distribution the answer already gives you" — a
peakedness measure, not an independent probability of being right. The exact
production formula is undocumented; the docs' interactive demo labels
`(3 × largest probability − 1) / 2` an approximation, and that approximation
reproduces every documented example within 0.01. Calibration is claimed for
the *probabilities*, as a group property ("it does not guarantee that an
individual answer is correct"); no calibration measurements are published.
This is exactly the shape the template's automation seams would consume: a
label plus a distribution plus a threshold-able scalar, with the caveat that
for yes/no questions the probability *is* the confidence.

**Two official SDKs**, both MIT and public on GitHub under `typesafe-ai`:
Python `typesafe-sdk` 0.7.1 (sync + async clients, Python ≥3.10, Pydantic
models, `response_model` typing) and JavaScript/TypeScript `@typesafe-ai/sdk`
0.6.0 (Node ≥20, zero runtime deps, inferred answer types). Both read
`TYPESAFE_API_KEY`, default to `jev-latest`, and retry 429/529 with backoff.
"Any other language" means call the HTTP API; a public OpenAPI 3.1 spec exists
at `api.typesafe.ai/openapi.json` though the docs don't link it. TypeSafe ships
no MCP server or CLI; third parties have already published MCP servers, CLIs,
and adapters for Pydantic AI, Vercel AI Gateway, Spring AI, n8n and others.
A first-party "agent skill" (a Markdown docs-context skill for Claude Code /
Codex) exists; it currently links a migration page that 404s.

**Performance is asserted, not specified.** The vendor gives three unreconciled
latency figures ("about 100 ms", "150ms", "70ms-500ms") with no percentile,
region or payload; the one docs number with a stated payload is 0.27 s for a
13-question call over a ~54k-character state on `jev-1.12`. Third-party
hands-on posts (Sept 16–21, all through gateways) report medians of roughly
0.3 s. TypeSafe deliberately publishes no public-benchmark scores; its own
evals site shows Jev at 67.8% mean accuracy across four workflows, *below*
two LLM rows on the same page, while being far cheaper and faster. The
"Zero Hallucinations" headline is, by TypeSafe's own admission, a schema
guarantee ("Our number is not empirical. Schema matching is guaranteed") — the
docs list nine known failure modes for `jev-1.13` (counting, dates,
indirection, adversarial state, context rot, no generation). No page uses the
literal phrase "no human in the loop", but autonomous operation is implied,
conditioned on confidence gating that the caller implements: the docs say
"without a human co-pilot" and "proceed without human involvement" (at high
confidence), the homepage says it "acts autonomously" when thresholds allow —
and the same docs prescribe routing low-confidence answers to a human (corrected 2026-09-23; previously: "Nothing anywhere says 'no human in the loop'; the docs prescribe the opposite at low confidence.").

**Versioning is thin.** IDs are `jev-<major>.<minor>.<patch>`; aliases move
without notice and the response echoes the versioned ID so you can pin. There is
no model changelog and no deprecation policy; 16 cookbook pages still cite
`jev-1.12` (corrected 2026-09-23; previously: "14 cookbooks"), whose availability is unknown. Rate limits, prices ("temporary or
subsidized?" is an unanswered FAQ heading) and the alias target are all things
an integration should read at runtime rather than hard-code.

Detail and evidence: `record.md`; what moved at re-check: `verification.md`;
what only an account could settle: `open-verification.md`.
