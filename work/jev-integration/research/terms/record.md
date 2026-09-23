# Record — `terms` (jev-integration research wave 1, 2026-09-23)

Subject: commercial and operational terms of **Jev** (TypeSafe AI). Public sources only; no accounts, keys, API calls, or spend. Claim format per `research/schema.md`. Raw cluster findings with full quote proofs: `pass/pricing.md`, `pass/limits-and-auth.md`, `pass/data-and-privacy.md`, `pass/legal.md`, `pass/support-and-status.md`. Adversarial re-check: `verification.md`. Unsettled items: `open-verification.md`.

**Tally:** 66 claims — 51 `documented` (10 of them split with an `unknown`/`implied` half: 1.10, 2.6, 2.9, 3.6, 4.5, 4.6, 4.8, 5.2, 6.2, 7.4), 4 `implied`, 9 `unknown`, 2 `contradicted` (1.6 the S4 qualifier; 3.7 minor MCA wording).

**Standing claims:** S4 figure ("$42 per billion input tokens") **confirmed**; S4 qualifier ("production prices") **contradicted** — appears on no first-party page. S5 confirmed (docs at docs.typesafe.ai; console at console.typesafe.ai → `/login`). S3's "no human in the loop" is tempered in contract: the MCA says output "MAY PRODUCE INACCURATE OR ERRONEOUS OUTPUT" and the customer "IS RESPONSIBLE FOR INDEPENDENTLY EVALUATING THE OUTPUT" (claim 5.10).

Key page facts: `typesafe.ai/pricing` and `docs.typesafe.ai/pricing` are **404**; the price lives on `docs.typesafe.ai/models`. `typesafe.ai/sitemap.xml` lists exactly four legal pages (`/legal/terms`, `/legal/mca`, `/legal/privacy-policy`, `/legal/data-processing`). Live OpenAPI: `https://api.typesafe.ai/openapi.json` (v0.2.0).

## Q1 — Price per token, unit, qualifier

| # | Claim (one sentence) | Verdict | Source URL | Date checked | How verified | Documented vs. implied |
|---|---|---|---|---|---|---|
| 1.1 | Jev 1.13 (`jev-1.13.0`) is priced at "$42 / $0.042" under the row "Price (per Btok / per Mtok)" — $42 per billion input tokens = $0.042 per million. | documented | https://docs.typesafe.ai/models | 2026-09-23 | raw served HTML row parsed (order Btok→Mtok confirmed); `.md` twin 1 hit; lead re-verified | documented (docs reference page) |
| 1.2 | The meter is input tokens only: "Charged per input token. Output tokens are free." | documented | https://docs.typesafe.ai/models | 2026-09-23 | grep 1 (md) / 2 (HTML); lead re-verified | documented |
| 1.3 | No per-request, per-decision, batch, or cached-token meter is disclosed; the API `usage` object reports only `input_tokens` and `output_tokens`. | documented (absence by reference) | https://docs.typesafe.ai/api ; https://docs.typesafe.ai/models | 2026-09-23 | llms-full grep for `per request|per decision|cached|batch` → cookbook prose only; `usage` fields read from API reference | absence rests on the reference (rule 2) |
| 1.4 | The homepage shows "$42" / "Per Billion input tokens." and "238x" / "Lower input price than Claude Fable 5.1" with no pricing page behind it (`/pricing` 404 on both hosts). | documented (via 1.1) | https://typesafe.ai | 2026-09-23 | raw HTML grep 1/1/2/2; 404s re-checked by lead | homepage alone would be `implied`; the docs Models page makes the figure documented |
| 1.5 | The launch post states "Input tokens: $0.042 / MTok ($42 per billion tokens)." and "Output tokens: FREE (too cheap to meter)." against an LLM comparison column ("from $0.20 to $10 / MTok", "Output tokens: ~5x more expensive"). | documented (blog) | https://typesafe.ai/blog/introducing-system-one-models-and-jev | 2026-09-23 | grep 2 each; lead re-verified | marketing, consistent with docs |
| 1.6 | The qualifier "production prices" does not appear on any first-party page (homepage, launch post, docs corpus, Models page, four legal pages). | contradicted (S4 attribution) | https://typesafe.ai ; https://docs.typesafe.ai/llms-full.txt | 2026-09-23 | `production price` = 0 across all fetched first-party files (lead + pricing cluster independently) | the wording is the launcher's, not the site's |
| 1.7 | The price qualifiers that do exist: blog "We make our pricing transparent. We can’t prove it isn’t subsidized; we’ll need the long-term to prove the sustainability of our pricing (which we expect to go down, not up)."; homepage FAQ heading "Are these prices temporary or subsidized?" whose answer is not in the served HTML; cookbook comments "Historical TypeSafe rate, as of 2026-08" / "not verified `jev-latest` prices or current billing amounts". | documented | https://typesafe.ai/blog/introducing-system-one-models-and-jev ; https://typesafe.ai ; https://docs.typesafe.ai/llms-full.txt | 2026-09-23 | grep 2 / 1 / 2 / 2 | documented; FAQ answer body needs a browser (open O1) |
| 1.8 | Enterprise / custom-plan pricing is undisclosed ("Higher limits are available on custom and enterprise plans. Contact sales@typesafe.ai"). | unknown | https://docs.typesafe.ai/models | 2026-09-23 | grep 1; no price anywhere | — |
| 1.9 | Jev is also listed on OpenRouter (`~typesafe/jev-latest`) at "$0.042 per million input tokens, $0 per million output tokens." | documented (third-party) | https://openrouter.ai/~typesafe/jev-latest | 2026-09-23 | fresh fetch grep 6; page linked from a docs cookbook | third-party |
| 1.10 | Only one priced model exists; aliases `jev-latest` and `jev-preview` both resolve to `jev-1.13.0`; cookbooks also mention a `speed_latest` rate label not on the Models page. | documented / unknown (`speed_latest`) | https://docs.typesafe.ai/models | 2026-09-23 | Models table read; `speed_latest` 2 hits in cookbook prose only | — |
| 1.11 | Homepage demo cards show "Cost $0.000081" (TypeSafe) vs "Cost $0.013880" (LLMs), "444.6x Cheaper." — workflow demo costs, no method given. | implied | https://typesafe.ai | 2026-09-23 | grep 1 each | marketing |

## Q2 — Rate limits, quotas, concurrency

| # | Claim | Verdict | Source URL | Date checked | How verified | Documented vs. implied |
|---|---|---|---|---|---|---|
| 2.1 | Published limits for `jev-1.13.0`: "250,000 tokens per second / 1,200 requests per minute"; a request over either returns `429 Too Many Requests`. | documented | https://docs.typesafe.ai/models | 2026-09-23 | served HTML `<tr>` parsed (2-col, no transposition); md 1; lead re-verified | documented; scope (per key/account/global) undisclosed |
| 2.2 | Limits are declared dynamic: "Rate limits are adjusting dynamically." / "can change without notice … as upcoming large GPU deals land and we let in more users"; higher limits only on custom/enterprise plans via sales@. | documented | https://docs.typesafe.ai/models | 2026-09-23 | grep 1 each (md), 2 (HTML) | documented |
| 2.3 | Whether limits apply per API key, per account/org, or globally is not stated; the only hint is cookbook prose "Eight is already enough to hit a rate limit on a shared key." | unknown | https://docs.typesafe.ai/llms-full.txt ; https://api.typesafe.ai/openapi.json | 2026-09-23 | `per-key`/`per account`/`per organization` = 0 (control `TYPESAFE_API_KEY` 49); OpenAPI `limit` = 0 | — |
| 2.4 | No concurrency cap is documented; a jev-1.12-era cookbook comment says "the public endpoint rate-limits above roughly eight" workers. | unknown | https://docs.typesafe.ai/llms-full.txt | 2026-09-23 | `concurrency limit`/`concurrent request` = 0; anecdote 1 hit | — |
| 2.5 | No tier ladder (free/pro/enterprise limits) is published. | unknown | https://docs.typesafe.ai/llms-full.txt ; https://typesafe.ai/pricing (404) | 2026-09-23 | `tier` hits are all "frontier"; no pricing page | — |
| 2.6 | On 429 ("You have exceeded your rate limit. Back off and retry after a short delay.") and 529 Overloaded the API page prescribes exponential backoff; official SDKs retry by default (2 retries, 0.5 s→5 s, jitter 0.25, on 408/429/500–599) and honor `retry-after` / `retry-after-ms` "when the response carries one". | documented (guidance, SDK) / implied (server emits `retry-after`) | https://docs.typesafe.ai/api ; https://docs.typesafe.ai/sdk/python/api/retries ; https://docs.typesafe.ai/sdk/javascript/api/interfaces/RetryPolicy | 2026-09-23 | error table rows 401/422/429/529 read; SDK defaults read; Python constants confirmed | server emission not guaranteed |
| 2.7 | No `x-ratelimit-*` headers are documented; the OpenAPI spec declares no response headers and no 429/401 (each operation lists only 200 and 422); `x-typesafe-request-id` is documented on SDK pages only, not in the HTTP reference. | documented (absence) | https://api.typesafe.ai/openapi.json ; https://docs.typesafe.ai/api | 2026-09-23 | fresh spec parsed (v0.2.0); `x-ratelimit` = 0 in llms-full; `x-typesafe-request-id` 0 on api.md, 12 on SDK pages | downgraded from cluster wording (see verification V17) |
| 2.8 | Request-size limits: 64k tokens per request; 32k tokens for `state` plus the longest question; max 255 Choice options; up to 10 Score levels. | documented | https://docs.typesafe.ai/models ; https://docs.typesafe.ai/api | 2026-09-23 | grep 1 each | documented |
| 2.9 | Contractually, usage is bounded by "Usage Limits" set in the Order; exceeding them is a licence restriction and an immediate-suspension trigger; no numbers are public. | documented (mechanism) / unknown (numbers) | https://typesafe.ai/legal/mca | 2026-09-23 | §2.1, §2.3(j), §6 quotes grep 2 | Order not public |

## Q3 — Authentication

| # | Claim | Verdict | Source URL | Date checked | How verified | Documented vs. implied |
|---|---|---|---|---|---|---|
| 3.1 | Auth is an API key sent as `Authorization: Bearer <API_KEY>`; OpenAPI security scheme `HTTPBearer` (`type: http, scheme: bearer`) on both operations; both SDKs build that header. | documented | https://api.typesafe.ai/openapi.json ; https://docs.typesafe.ai/api | 2026-09-23 | spec parsed; description sentence 1 hit; SDK sources read | documented |
| 3.2 | There is no `x-api-key` scheme and no OAuth flow. | documented (absence) | https://api.typesafe.ai/openapi.json ; https://docs.typesafe.ai/llms-full.txt | 2026-09-23 | spec `apiKey`/`oauth`/`x-api-key` = 0 (control `HTTPBearer` 3); llms-full `OAuth` 0 | absence by reference |
| 3.3 | Keys are issued in the console dashboard (`console.typesafe.ai/keys`, login-gated); env var `TYPESAFE_API_KEY` in both SDKs. | documented | https://docs.typesafe.ai/introduction/quickstart ; https://docs.typesafe.ai/sdk/javascript/api/variables/ENV | 2026-09-23 | quickstart 1 hit; ENV page read | documented |
| 3.4 | The logged-out console offers "Continue with Google" or "Email me a code instead"; no password field; no SSO/SAML/GitHub option visible. | documented (logged-out UI) | https://console.typesafe.ai/login | 2026-09-23 | raw HTML grep 1/1; `password`/`saml`/`oidc` = 0 | documented |
| 3.5 | Org/project/workspace scoping, key scopes, rotation/expiry, service accounts, and SSO are undocumented; the spec speaks only of "the authenticated account". | unknown | https://api.typesafe.ai/openapi.json ; https://docs.typesafe.ai/llms-full.txt | 2026-09-23 | `organization`/`project`/`scope` = 0 in spec; `service account`/`single sign` = 0 in llms-full | console-gated |
| 3.6 | API key format/prefix is undocumented; the Python SDK only requires printable ASCII without whitespace. | unknown (format) / documented (validation) | https://docs.typesafe.ai/sdk/python/usage | 2026-09-23 | usage.md sentence 1 hit; no prefix example anywhere | — |
| 3.7 | The MCA describes Web Interface access as "a username and password", which does not match the passwordless login UI. | contradicted (minor wording) | https://typesafe.ai/legal/mca vs https://console.typesafe.ai/login | 2026-09-23 | MCA quote 2; login `password` 0 | generic contract language; do not over-read |
| 3.8 | Contract: Access Credentials must be kept confidential and not shared; customer liable for all use; console access limited to employees/contractors. | documented | https://typesafe.ai/legal/mca §2.4 | 2026-09-23 | grep 2 each | documented |
| 3.9 | An open third-party issue on TypeSafe's own `skills` repo (2026-09-21) reports every console login path returning HTTP 500 for two days. | implied (unverified report) | https://github.com/typesafe-ai/skills/issues/10 | 2026-09-23 | GitHub API: `state: open`, created 2026-09-21T23:15:01Z; no login attempted (scope) | not first-party confirmed |
| 3.10 | Alternate credentials: docs show calling via OpenRouter or Vercel AI Gateway by changing `base_url`/`baseURL`, using the gateway's own key. | documented | https://docs.typesafe.ai/sdk/python/usage ; https://vercel.com/docs/ai-gateway/sdks-and-apis/typesafe | 2026-09-23 | usage.md lines read; Vercel page grep 1 | gateway auth is the gateway's |

## Q4 — Data retention, training, privacy, hosting, compliance

| # | Claim | Verdict | Source URL | Date checked | How verified | Documented vs. implied |
|---|---|---|---|---|---|---|
| 4.1 | A Privacy Policy exists, "Last updated Nov 19, 2025", covering the website, Playground and APIs; `/privacy` and `/privacy-policy` redirect to it. | documented | https://typesafe.ai/legal/privacy-policy | 2026-09-23 | 200; grep 2; lead re-verified | policy |
| 4.2 | Inputs are not trained on, in three places: Privacy Policy "We will not train or fine tune any artificial intelligence or machine learning models on your prompts or other Input."; MCA §4.1 "will not, include Customer Data in a dataset used to train … without Customer’s prior consent"; docs "Jev is not trained on customer requests or responses." | documented | https://typesafe.ai/legal/privacy-policy ; https://typesafe.ai/legal/mca ; https://docs.typesafe.ai/models | 2026-09-23 | grep 2 / 2 / 1; lead re-verified | documented (note the MCA prior-consent carve-out) |
| 4.3 | Caveat: the MCA grants a perpetual licence over Customer Data "to derive and generate Telemetry" (logs, hashes, summary statistics, classifications, learnings), and "TypeSafe may Process Telemetry without restriction, including to improve the Services". | documented | https://typesafe.ai/legal/mca §4.1, §4.3 | 2026-09-23 | grep 2 each | documented — the genuine limit on the no-training stance |
| 4.4 | Retention has no numeric window: personal data kept "for as long as reasonably necessary to provide you with the Services, or otherwise in support of our business or commercial purposes"; MCA: "TypeSafe will be under no obligation to store or retain Customer Data and may delete Customer Data at any time in its sole discretion"; confidential info "may be retained in TypeSafe’s standard backups". | documented (open-ended) | https://typesafe.ai/legal/privacy-policy ; https://typesafe.ai/legal/mca | 2026-09-23 | grep 2 each; no `N days` retention figure on any first-party page | no deletion SLA |
| 4.5 | Zero data retention: "We also offer zero data retention (ZDR) for enterprise customers. Contact privacy@typesafe.ai to learn more." No API header/option or self-serve toggle exists. | documented (offer) / unknown (terms) | https://docs.typesafe.ai/legal ; https://api.typesafe.ai/openapi.json | 2026-09-23 | sentence 1 hit; spec has no retention parameter | enterprise, contact-us |
| 4.6 | Hosting: "The Services are hosted in the United States"; EEA/UK users transfer data to the U.S.; no EU option; cloud provider not named anywhere readable. | documented (region) / unknown (provider) | https://typesafe.ai/legal/privacy-policy | 2026-09-23 | grep 2; `AWS`/`Google Cloud`/`Azure` = 0 across first-party pages | — |
| 4.7 | A public DPA ("Last updated Apr 24, 2026") is incorporated into the MCA: TypeSafe as processor; CCPA no-sell/no-share; breach notice "within 72 hours after becoming aware"; audit "no more than once every 12 months"; subprocessor change notice with objection window; EU SCCs Module 2 (and 3) + UK Addendum. | documented | https://typesafe.ai/legal/data-processing ; https://typesafe.ai/legal/mca §4.4 | 2026-09-23 | grep 2 / 2 / 2 / 2 / 6 | transfer mechanism, not a certification |
| 4.8 | The subprocessor list and security measures are deferred to https://trust.typesafe.ai (Vanta), which serves only a ~6.9 KB JavaScript shell to curl/WebFetch — contents unread. | documented (pointer) / unknown (contents) | https://typesafe.ai/legal/data-processing → https://trust.typesafe.ai/ | 2026-09-23 | DPA URL grep 2; fresh trust fetch 200, 6,914 B, `vanta` 26 | needs a browser (O14) |
| 4.9 | SOC 2, ISO 27001, HIPAA/BAA, and encryption statements appear on no readable first-party page. | unknown | (all first-party pages) | 2026-09-23 | word-boundary greps = 0 across home, blog, docs corpus, MCA, ToU, DPA, Privacy, console login; trust center unreadable | not claimed in readable text; not proof of absence (rule 1) |
| 4.10 | Privacy Policy: "We do not “sell” personal data nor “share” personal data for cross-contextual behavioral advertising."; also "we can make no guarantees as to the security or privacy of your data". | documented | https://typesafe.ai/legal/privacy-policy | 2026-09-23 | grep 2 each | policy |

## Q5 — Terms of service and licence

| # | Claim | Verdict | Source URL | Date checked | How verified | Documented vs. implied |
|---|---|---|---|---|---|---|
| 5.1 | There is no single "Terms of Service": the service (console + API) is governed by the Master Customer Agreement, "Last updated Sep 19, 2026", accepted by click, Order, or use; `typesafe.ai/legal/terms` (same date) is a website Terms of Use that defers product use to a separate agreement; no standalone AUP exists (`/aup`, `/acceptable-use`, `/legal` 404; "acceptable use" 0 hits). | documented | https://typesafe.ai/legal/mca ; https://typesafe.ai/legal/terms ; https://typesafe.ai/sitemap.xml | 2026-09-23 | grep 2 each; sitemap lists exactly four legal pages; 404s re-checked | documented |
| 5.2 | The console login page binds sign-ups to "the terms of use and the privacy policy", linking the website ToU and Privacy Policy — not the MCA. | documented (link targets) / implied (legal effect) | https://console.typesafe.ai/login | 2026-09-23 | href grep: `/legal/terms` 2, `/legal/mca` 0 | flag for a legal reviewer (O20) |
| 5.3 | Output ownership: "TypeSafe disclaims ownership of Output. TypeSafe hereby assigns to Customer all of its right, title, and interest, if any, in the Output."; customer retains Input IP; §9.3 warns Output "MAY NOT BE UNIQUE"; IP indemnity excludes Output. | documented | https://typesafe.ai/legal/mca §4.2, §9.3, §13.5 | 2026-09-23 | grep 2 each | documented (quote the "if any" hedge) |
| 5.4 | Licence: limited, non-exclusive, non-transferable licence for the Term to use the Services and "integrate the API with one or more Customer Applications" for Customer's End Users. | documented | https://typesafe.ai/legal/mca §2.1–2.2 | 2026-09-23 | grep 2 | documented |
| 5.5 | The MCA contains no restriction on automated, programmatic or AI-agent use of the API; the ToU's anti-bot clause ("robots," "spiders," "scrapers") is scoped to the website. | documented (absence in the full MCA text) | https://typesafe.ai/legal/mca ; https://typesafe.ai/legal/terms §3(b)(vi) | 2026-09-23 | full MCA read; `automat` hits = auto-refill only | do not roll the ToU clause up as an API ban |
| 5.6 | Prohibited: making the Services available "as a standalone service"; "model distillation, train a model to imitate the output of the Services, or develop … a similar or competing product or service"; reverse engineering; "conduct any security or vulnerability test"; exceeding Usage Limits; submitting ITAR-controlled data. | documented | https://typesafe.ai/legal/mca §2.3, §16.12 | 2026-09-23 | grep 2 each | embedding for end users is licensed; resale ban is *standalone* only |
| 5.7 | No high-risk-use restriction (medical, legal, weapons, etc.) appears in the MCA, ToU, DPA, or Privacy Policy. | documented (absence) | the four `/legal/*` pages | 2026-09-23 | `high-risk` = 0 across the four pages | — |
| 5.8 | Governing law (service): California, San Francisco courts, binding JAMS arbitration with class-action waiver and no opt-out clause; website ToU: Delaware, JAMS with a 30-day opt-out. | documented | https://typesafe.ai/legal/mca §15–16 ; https://typesafe.ai/legal/terms §12 | 2026-09-23 | grep 2 each | two documents, two regimes |
| 5.9 | Liability: MCA cap is the greater of fees paid in the prior 12 months or "$50 USD", with excluded uncapped claims; ToU cap "IS LIMITED TO $100 USD." | documented | https://typesafe.ai/legal/mca §12 ; https://typesafe.ai/legal/terms §11 | 2026-09-23 | grep 2 each (single-quoted) | do not merge the two caps |
| 5.10 | Warranty: Services "will perform materially as described in its Documentation"; "THE SERVICES MAY PRODUCE INACCURATE OR ERRONEOUS OUTPUT" and customer "IS RESPONSIBLE FOR INDEPENDENTLY EVALUATING THE OUTPUT"; no uninterrupted/error-free warranty. | documented | https://typesafe.ai/legal/mca §9 | 2026-09-23 | grep 2 each | tempers S3 in contract terms |
| 5.11 | Termination on uncured 30-day breach; immediate suspension for §2.3/§2.4/§5 breaches or overdue payment; no refund of unconsumed prepaid amounts; unilateral amendments effective "at least 60 days after" notice; TypeSafe may use Customer's name/logo as a reference until asked to stop. | documented | https://typesafe.ai/legal/mca §6, §10, §16.4, §16.7 | 2026-09-23 | grep 2 each | documented |
| 5.12 | Official SDKs are MIT: npm `@typesafe-ai/sdk` 0.6.0 (2026-09-15), PyPI `typesafe-sdk` 0.7.1, GitHub `typesafe-ai/typesafe-sdk-js`, `typesafe-sdk-python`, `skills`; the Python repo's LICENSE still reads "Copyright (c) [year] [fullname]". The service itself is not open source. | documented | https://registry.npmjs.org/@typesafe-ai/sdk ; https://pypi.org/pypi/typesafe-sdk/json ; https://raw.githubusercontent.com/typesafe-ai/typesafe-sdk-python/main/LICENSE | 2026-09-23 | registry JSON fields; raw LICENSE grep 1; lead re-verified | cosmetic defect, MIT grant intact |

## Q6 — Free tier, evaluation access, signup, billing model

| # | Claim | Verdict | Source URL | Date checked | How verified | Documented vs. implied |
|---|---|---|---|---|---|---|
| 6.1 | No free tier, trial, or free-credit amount is published anywhere. | unknown | docs sitemap; homepage; MCA | 2026-09-23 | `free tier`/`free credit` = 0 in llms-full; only MCA "Promotional Credits" (6.4) | — |
| 6.2 | Access is "early access" with a waitlist per the launch post ("available today in early access"; "bringing developers off the waitlist as quickly as we can"); no waitlist form exists — the homepage's only "Join Waitlist" element links to the Ashby jobs board. | documented (wording) / unknown (how to join) | https://typesafe.ai/blog/introducing-system-one-models-and-jev ; https://typesafe.ai | 2026-09-23 | grep 2 / 2; homepage anchor `jobs.ashbyhq.com/typesafe-ai` 2 | the waitlist word is first-party (launch post), absent from docs |
| 6.3 | Self-serve signup is implied by the quickstart ("Open the Playground and log in", key from `console.typesafe.ai/keys`) and the Google/email-code login, but `/signup` redirects to login and the public console JS carries `SELF_SERVE_DISABLED`, `signups_disabled`, "Email signup is disabled. Continue with Google to create your account." and an invite flow. | implied | https://docs.typesafe.ai/introduction/quickstart ; https://console.typesafe.ai/login ; console `/_next/static/chunks/*.js` | 2026-09-23 | quickstart grep 1; 26 chunks fetched fresh: 12/12/2/2 hits | both self-serve and gated branches exist in code |
| 6.4 | Billing is prepaid credits: "Customer must obtain TypeSafe-managed credits that are consumed by each Input"; Purchased Credits "expire on the earlier of (y) the end of the Term and (z) the date that is 12 months after the purchase date"; optional "automatic Purchased Credit refills"; discretionary Promotional Credits (one account per customer). | documented | https://typesafe.ai/legal/mca §8.2 | 2026-09-23 | grep 2 each; lead re-verified | documented |
| 6.5 | Invoiced orders also exist: fees "will be paid in US dollars", "due within 30 days after the invoice date", late fee "1.5% per month"; an Order may be "the checkout page on TypeSafe’s website" or an executed order form. | documented | https://typesafe.ai/legal/mca §8 | 2026-09-23 | grep 2 each | self-serve checkout and invoicing both contemplated |
| 6.6 | Card top-up with auto-reload is suggested by console JS analytics names ("billing topup started", "billing payment method attach succeeded", "billing auto reload toggled"). | implied | console `/_next/static/chunks/*.js` | 2026-09-23 | fresh grep 2 each | UI code, not documentation |
| 6.7 | Promotional-credit amount, minimum top-up, and accepted payment methods are not published. | unknown | — | 2026-09-23 | no page states them | needs account (O3) |

## Q7 — Support, SLA, status page

| # | Claim | Verdict | Source URL | Date checked | How verified | Documented vs. implied |
|---|---|---|---|---|---|---|
| 7.1 | A public status page exists at https://status.typesafe.ai (Better Stack; CNAME `statuspage.betteruptime.com`) with two monitors, "TypeSafe API Availability" and "TypeSafe developer console"; it is linked from no first-party page. | documented | https://status.typesafe.ai/ | 2026-09-23 | dig + fresh 200; `status.typesafe` = 0 on homepage, docs corpus, legal pages, console login | discoverable only by guessing/search |
| 7.2 | As of 2026-09-23 the page shows 99.839% (API) and 99.988% (console) 90-day uptime, "All services are online", and 23 day-cells marked "Down for N minutes" (2–59 min). | documented (observational, live values) | https://status.typesafe.ai/ | 2026-09-23 | fresh fetch grep 1 / 1 / 1 / 23 | measured history, not a commitment; will drift |
| 7.3 | No uptime SLA or service credits are published; the MCA gives only a warranty to "perform materially as described in its Documentation", remedied by a fix within 30 days or termination with refund of pre-paid unused fees, and disclaims uninterrupted or error-free service. | documented (absence + contract) | https://typesafe.ai/legal/mca §9 | 2026-09-23 | `SLA`/`uptime`/`service credit` = 0 across all first-party pages; quotes grep 2 | enterprise Order SLA unknown (O24) |
| 7.4 | Support is "commercially reasonable efforts … in accordance with its standard support policies" via support@typesafe.ai (policies unpublished); postal address 255 California St, Suite 1300, San Francisco; no response-time commitment or support tiers are published; the docs assistant deflects to support@. | documented / unknown (policies, times) | https://typesafe.ai/legal/mca §3 ; https://typesafe.ai/legal/terms ; https://docs.typesafe.ai/ | 2026-09-23 | grep 2 / 6 / 1; `respond within`/`business day` = 0 | the only timed commitment is the DPA's 72-hour breach notice |
| 7.5 | Community: TypeSafe AI Discord (docs navbar `discord.gg/typesafe`; jaggedness page "Reach us on Discord"; invite metadata ~106.8k members, live counter), GitHub org `typesafe-ai` with Issues enabled, X `@typesafeai`, LinkedIn; no Slack, forum, or in-console chat found. | documented | https://docs.typesafe.ai/ ; https://docs.typesafe.ai/model-jaggedness/jev-1.13 ; https://github.com/typesafe-ai | 2026-09-23 | href greps 1 each; og:description fresh | whether Discord is staffed support is unstated |
| 7.6 | Published addresses: support@, sales@, privacy@, hello@typesafe.ai; no security@ and no `security.txt` on either host (404). | documented | https://typesafe.ai/legal/mca ; https://docs.typesafe.ai/models ; https://typesafe.ai/legal/privacy-policy ; https://typesafe.ai | 2026-09-23 | mailto greps 2 / 2 / 4 / 1; 404s re-checked | — |
| 7.7 | Only SDK changelogs exist (Python v0.5.7 2026-09-14 → v0.7.1 2026-09-21; JS v0.5.7 2026-09-11 → v0.6.0 2026-09-15); no product/API/model changelog (`/changelog` 404 on both hosts); incident history is on the status page — two resolved incidents (Sep 20 "Console is unavailable.", Sep 21 "API issues") while July and August read "No incidents reported" despite down-cells on the strip (spread, rule 6). | documented | https://docs.typesafe.ai/sdk/python/changelog ; https://docs.typesafe.ai/sdk/javascript/changelog ; https://status.typesafe.ai/incidents | 2026-09-23 | changelog md read; incidents grep 1 / 1 / 2 | monitor downtime not written up as incidents |

## Verbatim-quote appendix (load-bearing or surprising; each re-grepped by the lead on an independent copy)

Counts are `LC_ALL=C grep -aoF` hits on the raw fetched page (Framer pages inline body text twice, hence 2).

**https://docs.typesafe.ai/models** (`.md` twin; served HTML counts double)
- `Price (per Btok / per Mtok) | \$42 / \$0.042` — 1
- `Charged per input token. Output tokens are free. A Btok is a billion tokens and an Mtok is a million tokens.` — 1
- `250,000 tokens per second / 1,200 requests per minute` — 1
- `Rate limits are adjusting dynamically.` — 1; `Higher limits are available on custom and enterprise plans.` — 1
- `Jev is not trained on customer requests or responses.` — 1

**https://typesafe.ai** (homepage)
- `$42` — 1; `Per Billion input tokens.` — 1; `Lower input price than Claude Fable 5.1` — 2; `238x` — 2
- `Are these prices temporary or subsidized?` — 1 (heading only; no answer body served)
- `Join Waitlist` — 2 (anchor href `https://jobs.ashbyhq.com/typesafe-ai?utm_source=QLrx0vq4BW`)
- `production price` — 0

**https://typesafe.ai/blog/introducing-system-one-models-and-jev**
- `Input tokens: $0.042 / MTok ($42 per billion tokens).` — 2; `Output tokens: FREE (too cheap to meter).` — 2
- `We make our pricing transparent. We can’t prove it isn’t subsidized; we’ll need the long-term to prove the sustainability of our pricing (which we expect to go down, not up).` — 2
- `available today in early access` — 2; `bringing developers off the waitlist as quickly as we can` — 2
- `production price` — 0

**https://api.typesafe.ai/openapi.json** (v0.2.0)
- `Send your API key in the Authorization header as \`Bearer <API_KEY>\`.` — 1; `securitySchemes` = `{"HTTPBearer": {"type": "http", "scheme": "bearer"}}`; responses per operation = `200`, `422` only

**https://docs.typesafe.ai/api**
- `You have exceeded your rate limit. Back off and retry after a short delay.` — 1; `Missing or invalid API key. Check the \`Authorization\` header.` — 1; `TypeSafe is temporarily overloaded. Retry after a short delay.` — 1

**https://typesafe.ai/legal/mca** (Master Customer Agreement, "Last updated Sep 19, 2026")
- `TypeSafe will not, include Customer Data in a dataset used to train (i.e., to modify the model weights of) any artificial intelligence or machine learning models without Customer’s prior consent.` — 2
- `TypeSafe may Process Telemetry without restriction, including to improve the Services or TypeSafe’s other products and services.` — 2
- `TypeSafe disclaims ownership of Output. TypeSafe hereby assigns to Customer all of its right, title, and interest, if any, in the Output.` — 2
- `(a) sell, lease, loan, distribute, sublicense, disclose, or otherwise offer or make the Services available as a standalone service; (b) use the Services or any Output (defined below) to perform model distillation, train a model to imitate the output of the Services, or develop (or to facilitate the development of) a similar or competing product or service` — 2
- `or conduct any security or vulnerability test with respect to any of the foregoing` — 2
- `THE SERVICES MAY PRODUCE INACCURATE OR ERRONEOUS OUTPUT` — 2
- `TYPESAFE DOES NOT WARRANT THAT CUSTOMER’S USE OF THE SERVICES WILL BE UNINTERRUPTED OR ERROR-FREE` — 2
- `Customer must obtain TypeSafe-managed credits that are consumed by each Input submitted to the Services through Customer’s account` — 2
- `Purchased Credits expire on the earlier of (y) the end of the Term and (z) the date that is 12 months after the purchase date` — 2
- `all Fees are due within 30 days after the invoice date.` — 2; `Late Fees are subject to a service charge of 1.5% per month` — 2; `the checkout page on TypeSafe’s website` — 2
- `AND (B) $50 USD.` — 2
- `TypeSafe will use commercially reasonable efforts to support the Services in accordance with its standard support policies` — 2
- `TypeSafe will be under no obligation to store or retain Customer Data and may delete Customer Data at any time in its sole discretion.` — 2
- `a username and password (in the case of the Web Interface)` — 2
- `This Agreement is governed by the laws of the State of California` — 2; `at least 60 days after` — 2

**https://typesafe.ai/legal/privacy-policy** ("Last updated Nov 19, 2025")
- `We will not train or fine tune any artificial intelligence or machine learning models on your prompts or other Input.` — 2
- `The Services are hosted in the United States` — 2
- `for as long as reasonably necessary to provide you with the Services, or otherwise in support of our business or commercial purposes` — 2

**https://typesafe.ai/legal/data-processing** ("Last updated Apr 24, 2026")
- `within 72 hours after becoming aware` — 2; `no more than once every 12 months` — 2; `Module 2 (controller-to-processor) of the EU SCCs` — 2; `UK Addendum` — 6; `https://trust.typesafe.ai/subprocessors` — 2

**https://typesafe.ai/legal/terms** (website Terms of Use, "Last updated Sep 19, 2026")
- `IS LIMITED TO $100 USD.` — 2; `the laws of the state of Delaware` — 2; `The Site is intended for visitors located within the United States.` — 2

**https://docs.typesafe.ai/legal**
- `We also offer zero data retention (ZDR) for enterprise customers.` — 1

**https://console.typesafe.ai/login** (logged-out)
- `Continue with Google` — 1; `Email me a code instead` — 1; `https://typesafe.ai/legal/terms` — 2; `https://typesafe.ai/legal/mca` — 0
- Public JS chunks (26, fetched fresh): `SELF_SERVE_DISABLED` — 12; `signups_disabled` — 12; `Email signup is disabled` — 2; `You've been invited to join TypeSafe!` — 2; `billing topup started` — 2; `billing auto reload toggled` — 2

**https://status.typesafe.ai/**
- `All services are online` — 1; `TypeSafe API Availability` — 1; `99.839% uptime` — 1; `TypeSafe developer console` — 1; `99.988% uptime` — 1; `Down for ` (`&nbsp;`-separated) day-cells — 23
- `/incidents`: `Console is unavailable.` — 1; `API issues` — 1; `No incidents reported` — 2

**Third-party**
- https://openrouter.ai/~typesafe/jev-latest — `$0.042 per million input tokens, $0 per million output tokens.` — 6
- https://raw.githubusercontent.com/typesafe-ai/typesafe-sdk-python/main/LICENSE — `Copyright (c) [year] [fullname]` — 1
- https://api.github.com/repos/typesafe-ai/skills/issues/10 — `state: open`, `created_at: 2026-09-21T23:15:01Z`

## Progress

### [gen 1] 2026-09-23 — brief, method rules, schema read; fanning out five clusters
- Clusters: pricing (Q1, Q6), limits-and-auth (Q2, Q3), data-and-privacy (Q4), legal (Q5), support-and-status (Q7).
- Raw findings land in `pass/<cluster>.md`.

### [gen 1] 2026-09-23 — five clusters running; lead cached first-party pages for verification
- Cached to scratchpad: homepage (200), `/pricing` (404), docs index (→ `/introduction`), docs sitemap + llms.txt, launch post, console (→ `/login`), docs `models.md`/`legal.md`/`api.md`, `typesafe.ai/legal/{terms,privacy-policy,mca,data-processing}` (all 200).
- Early lead observation (to be verified against cluster output): docs `/models` carries a price table (`$42 / $0.042` per Btok / Mtok, "Output tokens are free") and rate limits with a "adjusting dynamically" warning; homepage says "$42 Per Billion input tokens." with no pricing page (`/pricing` is 404).

### [gen 1] 2026-09-23 — all five pass files landed; four hand-backs received (pricing, data-and-privacy, legal, support-and-status)
- Headline from clusters: price is documented on docs `/models` ($42/Btok = $0.042/Mtok, input only, output free); "production prices" wording appears on no fetched page (S4 qualifier unsupported); no SLA published; status page exists at status.typesafe.ai (Better Stack); MCA (Sep 19, 2026) governs the service, no-training commitment with a Telemetry carve-out; SDKs MIT.
- Next: verification pass (method rule 8 — claims must be able to move down), then synthesis.

### [gen 1] 2026-09-23 — fifth hand-back (limits-and-auth) received; verification done; deliverables written
- Verification (`verification.md`): 43 checks on independent copies — 37 survived, 3 downgraded (V17 request-id header is SDK-only; V40/V41 live figures cited as-of-date), 2 overturned (S4 "production prices" qualifier; limits cluster's "waitlist is not first-party" over-correction).
- Written: `record.md` (66 claims + quote appendix; tally corrected after a rule-7 row count), `profile.md`, `verification.md`, `open-verification.md` (28 open items tagged account / key / email / browser).
- Scope kept: no accounts, keys, API calls, spend, or Chrome; console opened at `/login` only; ~5 web searches spent across the five clusters.
