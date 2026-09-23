# Profile — how Jev is meant to be called (`integration-paths`, 2026-09-23)

**One line.** Jev is called through a single synchronous HTTP endpoint,
`POST https://api.typesafe.ai/v1/systemone`, with a Bearer key; TypeSafe wraps
it in two official SDKs (Python first, then JavaScript/TypeScript) and one
agent skill for coding agents — and nothing else: no MCP server, no CLI, no
OpenAI-compatible endpoint, no batch/stream/webhook surface.

**The homepage is silent; the docs are complete.** Standing claim S6 holds on
the raw homepage and launch-post HTML (zero hits for curl, pip, npm, SDK, MCP,
the endpoint) — but `docs.typesafe.ai` is a full Mintlify site with ~111
pages, an `llms.txt`, a 910 KB `llms-full.txt`, an HTTP reference, and an
OpenAPI 3.1 spec at `api.typesafe.ai/openapi.json` (two paths, one security
scheme). The quickstart orders the paths: Playground (login) → raw HTTP with a
cURL sample → Python SDK (`pip install typesafe-sdk`, Python ≥ 3.10) → agent
skill (`claude plugin install typesafe@typesafe-ai` or `npx skills add
typesafe-ai/skills`). No page calls any path "recommended"; order is the only
signal.

**Integration surface.** MCP: none from TypeSafe (`docs.typesafe.ai/mcp` is the
docs host's site-search MCP, not a Jev endpoint); 167 community MCP repos.
CLI: none from TypeSafe; the SDK packages have no `bin`/scripts. OpenAI
compatibility: explicitly no — "Jev is **not** a drop-in replacement for the
LLM behind Claude Code, Cursor, …"; the only official OpenAI-related package
runs the other way (`system-one-adapter-python`, LLMs standing in for Jev).
Gateways: TypeSafe documents OpenRouter (`~typesafe/jev-latest`) and Vercel AI
Gateway (`typesafe-ai/jev`) as TypeSafe-shaped routes reached by re-pointing
the official SDK's `base_url`. Framework adapters exist but are vendor-side and
unmentioned by TypeSafe: Vercel AI SDK `@ai-sdk/typesafe-ai` (experimental,
uses `boolean`, which its README maps explicitly to Noul — corrected 2026-09-23;
previously: "uses `boolean` where the API says `noul`"), LangChain `langchain-typesafe` /
`@langchain/typesafe` (alpha). LlamaIndex / Haystack / DSPy / Instructor:
unknown.

**Examples.** 18 inline Python cookbooks (classification, routing /
function-calling, extraction via closed candidate sets, LLM guardrails,
citation checking, re-ranking / RAG gating, entity alignment, structure
recovery, skill selection, ML features), four pattern snippets, one demo whose
source is promised "at release" but not published, one runnable TS sample in
the JS repo. The cookbooks' cached `json_cache.json` "ships with the cookbook",
but the only named repo for the cookbook files 404s. Third-party volume is
large and days old (GitHub `typesafe jev` ≈ 2,374 repos; HN launch thread 1976
points on 2026-09-15; Vercel, Cloudflare, LiteLLM, LangChain integrations by
2026-09-18) — metadata only; no third-party code was read.

**Schema.** Declared per request as a `questions` map of
`{type: choice|score|noul, instructions, criteria}` — plain JSON, not JSON
Schema / enums / Pydantic on the wire. Choice: option → description map, max
255, single-label (`choice` = highest-probability option). Score: 2–10 ordered
levels (255 and 2–10 are the docs' figures; the OpenAPI spec sets no Choice cap
and Score `minItems: 1` with no max, and makes `instructions` optional where the
docs mark it required — record 5.12-spec-spread; note added 2026-09-23), `score` is a probability-weighted value that can land between levels.
Noul: yes/no → `noul` in 0–1. Choice and Score answers carry `probabilities`
("sum to 1" per the docs, "approximately 1" per the spec — corrected 2026-09-23;
previously: "(sum to 1)") and a derived `confidence` in 0–1; **Noul answers carry no
confidence**. The confidence formula is not published (the docs' demo uses
`(n·peak − 1)/(n − 1)` as an approximation). Limits: 64k tokens per request,
32k for state plus the longest question, text only.

**Out-of-schema behaviour — the finding that matters for automation seams.**
The API never abstains, nulls, or errors because an input does not fit: it
always returns one of *your* options with a distribution. The docs give three
caller-side mechanisms, all of which live in your code, not the API:
(1) declare the escape hatch yourself — "Add an `other` or `none of the above`
option when the list might not cover every input"; (2) gate on `confidence`
with three bands (act / proceed with caution / "Do not act. Route to a human")
— the 0.5 / 0.6 / 0.85 numbers in the docs are worked examples with an
explicit "depends on your domain" caveat; aliases move on release, and the
docs' pinning advice is conditional — `jev-latest` is "The default in our client
SDKs, and the name the examples in these docs use", and pinning applies "If you
have tuned confidence thresholds against a specific version" (corrected
2026-09-23; previously: "thresholds should be pinned to a model version because
aliases move"); (3) pair a relative Choice with absolute
Nouls to decide whether to act at all. Malformed schemas fail with `422`.
Adversarial or irrelevant *state* degrades accuracy rather than erroring
("State is data … can move the answer"). "Zero Hallucinations" therefore
reads, against the reference, as type safety — the answer is always in-schema
— not correctness; the vendor's own SKILL.md says "Typed output guarantees the
interface, not truth."

**Operational.** One request, one JSON body; "batching" means many questions
per request. Retries: on 429/529 back off exponentially; both SDKs default to 2
retries, 0.5 s → 5 s backoff, statuses `{408, 429, 500–599}`, `Retry-After`
honoured. Client timeouts 10 s per attempt (JS: no total budget; Python: a 30 s
total budget as well). No webhooks, no idempotency key (retries re-POST; billing
on retry undisclosed), no server-side timeout published. Rate limits 250k
tok/s / 1,200 rpm, "adjusting dynamically".

**Standing claims.** S1, S2 (minus Noul), S4, S5 confirmed on the docs. S6
holds for the homepage but the docs answer it. **S3 is the one to re-read:**
the product is *marketed* — by contrast, never verbatim — as running without a
human in the loop: the launch post's comparison table files "Human-in-the-loop
tasks … requires human oversight" under LLMs and "AI-Powered Workflows / smart
if-statements" under System One (corrected 2026-09-23; previously: "the
product is *marketed* as needing no human in the loop"), but the docs'
prescribed design routes low-confidence decisions to a human and the
jaggedness page lists nine failure modes for `jev-1.13`. Anything the template
builds on top of Jev must own the escape-hatch option, the thresholds, and —
once thresholds are tuned — the version pin (corrected 2026-09-23; previously:
"and the version pin itself").
