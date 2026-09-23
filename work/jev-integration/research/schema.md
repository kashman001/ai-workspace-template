# Research-wave schema — jev-integration, wave 1 (2026-09-23)

Every subject is filled against this file. Same claim format for all
subjects; the question list differs per subject and is fixed here.

## Subjects (priority order — trim from the bottom if budget tightens)

1. `what-jev-is` — model class, API surface, request/response schema,
   how a decision and its confidence come back, SDKs, latency, versions.
2. `terms` — pricing, rate limits, auth, data retention/privacy,
   licence/ToS, free or evaluation tier.
3. `integration-paths` — how TypeSafe intends Jev to be called (SDK, HTTP,
   MCP, CLI), what examples exist, behaviour on inputs outside the schema.

## Claim format (identical for every subject)

Each claim is one row / one block carrying ALL of:

| # | Claim (one sentence) | Verdict | Source URL (the page, not the site) | Date checked | How verified | Documented vs. implied |

Verdicts: `documented` (the page states it), `implied` (the page suggests
it; say what the wording is), `unknown` (public sources do not say),
`contradicted` (a source says otherwise — cite both). Numbers carry their
full configuration or say "configuration undisclosed".

Close the primary record with a verbatim-quote appendix for anything
load-bearing or surprising (pricing, "no hallucination", schema shapes).

## Questions per subject

### what-jev-is
- Q1 What does TypeSafe call the model class ("System One Model") and how do they define it, in their own words? Is Jev the only one?
- Q2 What is the API surface: base URL, endpoints, methods, request schema, response schema?
- Q3 How does a *decision* come back — enum/label? structured JSON? and how does *confidence* come back — number, calibrated probability, bucket?
- Q4 What input does a call take: a decision schema + free text? examples? context window / max input?
- Q5 Which SDKs exist (languages, package names, versions, repo URLs)?
- Q6 Latency, throughput, and any published benchmarks — with configuration.
- Q7 Model versions / naming, deprecation policy, changelog.
- Q8 Who is TypeSafe (company, founders, funding, launch date of Jev) — one paragraph, sourced.

### terms
- Q1 Price per input token / output token (exact wording and unit); is "$42 per billion input tokens" what the pricing page says today, and what qualifies it ("production prices")?
- Q2 Rate limits, quotas, concurrency.
- Q3 Authentication: console API keys? OAuth? org/project scoping?
- Q4 Data retention, training-on-inputs policy, privacy policy, region/hosting, compliance claims (SOC2 etc.).
- Q5 Terms of service and licence: what may outputs be used for; any restrictions on automation, resale, or agents.
- Q6 Free tier, credits, evaluation access, waitlist, or self-serve signup; billing model (prepaid, invoice).
- Q7 Support/SLA/status page.

### integration-paths
- Q1 The canonical call path per TypeSafe's docs (quickstart): HTTP? SDK? which language first?
- Q2 Is there an MCP server, CLI, OpenAI-compatible endpoint, or framework adapters (LangChain, Vercel AI SDK, etc.)?
- Q3 What worked examples / cookbooks / sample repos exist, and what tasks do they show (classification, routing, extraction, guard decisions)?
- Q4 How is a decision schema declared (enums, JSON schema, natural-language options)? Multi-label? Free-text extraction or strictly closed choice?
- Q5 What happens on inputs outside the schema: abstain / low confidence / error / "none of the above"? Any documented threshold guidance?
- Q6 Batch, streaming, async, webhooks; idempotency; timeouts.
- Q7 Evidence of third-party use (GitHub, blog posts, HN/Reddit threads) — dated and cited, marketing testimonials excluded.

## What counts as verified

- Admissible: `typesafe.ai`, `docs.typesafe.ai`, the launch post
  (`typesafe.ai/blog/introducing-system-one-models-and-jev`), public
  SDK repos/packages (GitHub, npm, PyPI), public status/terms/privacy
  pages, and dated third-party writing. The console
  (`console.typesafe.ai`) is admissible only for what its public
  (logged-out) pages show.
- **Off-limits:** creating accounts, generating API keys, calling the
  API, any spend. No Chrome logins.
- "Unknown" is the expected answer when public pages do not say.

## Standing claims this wave may contradict (from work/jev-integration/README.md and the launcher)

- S1 Jev is TypeSafe's "first public System One Model, optimized for automation".
- S2 It returns typed decisions with confidence estimates instead of text.
- S3 It is "sold on not hallucinating and needing no human in the loop".
- S4 Price "$42 per billion input tokens" / "production prices".
- S5 Docs at docs.typesafe.ai; console at console.typesafe.ai.
- S6 Nothing on the homepage says how it is called (SDK/HTTP/MCP).

## Landmines (put in every brief)

- The site is marketing copy — every number traces to docs or the console or is `unknown`.
- "No hallucinations" is a claim, not a finding.
- Do not confuse Jev with other things named jev/JEV (Japanese encephalitis virus, unrelated packages/users).
- Tool budget: WebFetch/WebSearch/curl only; search is shared across three concurrent subjects — start from the docs index, search only for what an index cannot answer.

## Budget

Three subjects; roughly five to eight agents each (lead + ~5 cluster
sub-agents, one fact-checker, one corrections agent). Nothing beyond four
subjects.

## Verification scale (adopted from `sweep.md` § "Scale definition" under R29, session 4, 2026-09-23)

One scale for a verification row's outcome (one word first, qualifiers after a dash). Every `verification.md` in this wave is scored on it; the next wave's briefs carry it from Phase 1.

1. **`survived`** — the lead re-checked the row against an independent copy of the source and the claim stands as worded. (No "with a caveat" here: a caveat that changes the wording is level 3.)
2. **`confirmed`** — not re-checked by the lead; confirmed by an independent later stage (the fact-check).
3. **`downgraded`** — the claim stands with weaker wording, scope or precision.
4. **`spread`** — neither figure adopted, both recorded (rule 6).
5. **`overturned`** — the claim as worded is wrong; the record row was rewritten or re-verdicted.
6. **`reversed`** — a lead outcome later undone by the fact-check; keep the original word struck through and this word after it.
7. **`not re-checked`** — declared, per rule 7.

A scorecard line counts each level once, sums to the row count, and names the table(s) it counts (a subject with more than one verification table says which are in the total).
