# Pricing — raw pass findings

- **Cluster:** `terms` / subject `pricing` (commercial terms of Jev / TypeSafe)
- **Date checked:** 2026-09-23
- **Scope:** public, logged-out pages only; `curl -sL -A "Mozilla/5.0"`; raw HTML saved to scratchpad and grepped (no markdown conversion). No accounts, keys, API calls, or spend. Zero web searches used: every question was answerable from first-party pages plus the OpenRouter listing the docs themselves link to.

## URLs fetched (HTTP status)

| URL | Status | Note |
|---|---|---|
| https://typesafe.ai | 200 (→ `/`) | Framer marketing page, 590 KB |
| https://typesafe.ai/pricing | **404** | no pricing page |
| https://typesafe.ai/pricing/ | **404** | |
| https://typesafe.ai/sitemap.xml | 200 | 13 URLs; no `/pricing` entry |
| https://typesafe.ai/robots.txt | 200 | `Allow: /` |
| https://typesafe.ai/llms.txt | **404** | |
| https://typesafe.ai/blog/introducing-system-one-models-and-jev | 200 | launch post |
| https://typesafe.ai/legal/terms | 200 | site Terms of Use (no fee terms) |
| https://typesafe.ai/legal/mca | 200 | Master Customer Agreement, "Last updated Sep 19, 2026" — carries the billing model |
| https://docs.typesafe.ai/ | 200 (→ `/introduction`) | Mintlify |
| https://docs.typesafe.ai/pricing | **404** | |
| https://docs.typesafe.ai/billing | **404** | |
| https://docs.typesafe.ai/sitemap.xml | 200 | 118 URLs; no pricing/billing page; `/models` is the price-bearing page |
| https://docs.typesafe.ai/robots.txt | 200 | |
| https://docs.typesafe.ai/llms.txt | 200 | nav index |
| https://docs.typesafe.ai/llms-full.txt | 200 | 910 KB full docs text |
| https://docs.typesafe.ai/models | 200 | **the price table** (raw HTML grepped) |
| https://docs.typesafe.ai/introduction/quickstart | 200 | key acquisition steps |
| https://docs.typesafe.ai/legal | 200 | index of legal docs; no fee wording |
| https://console.typesafe.ai | 200 (→ `/login`) | logged-out login page only |
| https://console.typesafe.ai/login | 200 | |
| https://console.typesafe.ai/signup | 200 (→ `/login?returnTo=%2Fsignup`) | no public signup page; redirects to login |
| https://console.typesafe.ai/_next/static/chunks/*.js (18 chunks) | 200 | public JS bundle; strings grepped |
| https://openrouter.ai/~typesafe/jev-latest | 200 | third-party listing linked from docs (`/cookbooks/rerank_typesafe`) |
| https://openrouter.ai/api/v1/models | 200 | fetched; not parsed (not needed) |

## Q1 — Price per token; meters; qualifier

| # | Claim (one sentence) | Verdict | Source URL | Date checked | How verified | Documented vs. implied |
|---|---|---|---|---|---|---|
| 1.1 | The docs Models page lists Jev 1.13 (`jev-1.13.0`) at "$42 / $0.042" under the row label "Price (per Btok / per Mtok)", i.e. $42 per billion input tokens = $0.042 per million input tokens. | documented | https://docs.typesafe.ai/models | 2026-09-23 | raw HTML grep, 2 hits each for `Price (per Btok / per Mtok)` and `$42 / $0.042` | documented (docs reference page) |
| 1.2 | The meter is **input tokens only**: "Charged per input token. Output tokens are free." | documented | https://docs.typesafe.ai/models | 2026-09-23 | raw HTML grep, 2 hits | documented |
| 1.3 | There is **no output-token price** (output is free), and no per-request, per-decision/question, batch, or cached-token meter is disclosed anywhere on the docs, homepage, or blog. | documented (output free) / unknown (other meters: absence rests on the Models page + API reference `usage` object, which reports only `input_tokens` and `output_tokens`) | https://docs.typesafe.ai/models ; https://docs.typesafe.ai/api | 2026-09-23 | grep of llms-full.txt for `per request|per decision|per question|cached|batch` yields only cookbook prose; API `usage` fields are `input_tokens`, `output_tokens` | documented for output; absence-of-other-meters is by reference (rule 2) |
| 1.4 | The homepage shows "$42" with the caption "Per Billion input tokens." and "238x" "Lower input price than Claude Fable 5.1" — but with no pricing page behind it (`/pricing` 404). | documented (figure matches docs) — the homepage alone would be `implied`, the docs Models page makes it documented | https://typesafe.ai | 2026-09-23 | raw HTML grep: `$42` 1 hit, `Per Billion input tokens.` 1 hit | homepage number; backed by docs |
| 1.5 | The launch blog states "Input tokens: $0.042 / MTok ($42 per billion tokens)." and "Output tokens: FREE (too cheap to meter)." in a comparison block against LLMs ("Input tokens: from $0.20 to $10 / MTok." / "Output tokens: ~5x more expensive than input tokens."). | documented (blog) | https://typesafe.ai/blog/introducing-system-one-models-and-jev | 2026-09-23 | raw HTML grep, 2 hits each | blog = marketing; consistent with docs |
| 1.6 | **The qualifier "production prices" does not appear on any fetched page.** `production price` = 0 hits on homepage, blog, docs full text, and Models page. The only price qualifiers present are: (a) the blog's "We make our pricing transparent. We can’t prove it isn’t subsidized; we’ll need the long-term to prove the sustainability of our pricing (which we expect to go down, not up)."; (b) a homepage FAQ heading "Are these prices temporary or subsidized?" whose answer body is NOT in the served HTML (collapsed/JS); (c) cookbook code comments labelling the rate "Historical" and "not verified `jev-latest` prices or current billing amounts". | contradicted (as a quote attribution) — the figure is right, the "production prices" wording is not on the site | homepage, blog, docs | 2026-09-23 | `grep -aic 'production price'` = 0 on all four files; homepage has 1 `production` hit and it is inside a JS `typeof document` string, not copy | — |
| 1.7 | Spread (rule 6): the same $42/Btok = $0.042/MTok figure appears on 4 pages with 4 wordings and 3 version tags: docs Models page (jev-1.13, current); blog (unversioned, launch); cookbooks `PRICE = (0.042, 0.00)  # ... TypeSafe jev-1.12 as of 2026-09` and `TYPESAFE_PRICE = (0.042, 0.00)  # Historical TypeSafe rate, as of 2026-08`; OpenRouter "$0.042 per million input tokens, $0 per million output tokens." No contradictory figure was found. | documented (consistent) | see quotes | 2026-09-23 | grep counts below | one figure, several tags |
| 1.8 | Homepage demo cards show per-call costs "Cost $0.000081" (TypeSafe) vs "Cost $0.013880" (LLMs) and "444.6x Cheaper." "*based on workflows for System One tasks" — these are demo workflow costs, not a rate. | implied (demo, no method on page) | https://typesafe.ai | 2026-09-23 | raw HTML grep, 1 hit each | marketing |
| 1.9 | Rate limits published beside the price: "250,000 tokens per second / 1,200 requests per minute", with a warning that "Rate limits are adjusting dynamically." and "Higher limits are available on custom and enterprise plans." (contact sales@typesafe.ai). No enterprise price is disclosed. | documented (limits) / unknown (enterprise price) | https://docs.typesafe.ai/models | 2026-09-23 | raw HTML grep, 2 hits each | documented |
| 1.10 | Only one priced model exists: the Models page "Current models" table has a single column, Jev 1.13; aliases `jev-latest` and `jev-preview` both point to `jev-1.13.0`. Cookbooks reference a `speed_latest` rate label, which is not on the Models page. | documented (one model) / unknown (`speed_latest`) | https://docs.typesafe.ai/models | 2026-09-23 | table read from llms-full.txt lines 13000-13030; `speed_latest` 2 hits in cookbook prose only | — |

## Q6 — Free tier, credits, evaluation access, waitlist, signup, billing model

| # | Claim (one sentence) | Verdict | Source URL | Date checked | How verified | Documented vs. implied |
|---|---|---|---|---|---|---|
| 6.1 | No free tier, free-credit amount, or trial is published anywhere on the site or docs. | unknown (no page states one; absence rests on docs sitemap crawl + MCA) | docs sitemap, homepage, MCA | 2026-09-23 | grep `free tier|free credit|trial|credits` across all fetched pages: only MCA "Promotional Credits" (see 6.4) | — |
| 6.2 | Access is described as **early access with a waitlist**: the blog says Jev is "available today in early access" and TypeSafe is "bringing developers off the waitlist as quickly as we can". No waitlist form was found — the only "Join Waitlist" element on the homepage links to `https://jobs.ashbyhq.com/typesafe-ai` (a jobs board, in the "Come Build With Us / Open roles" section). | documented (blog wording) / unknown (how to join the waitlist) | https://typesafe.ai/blog/introducing-system-one-models-and-jev ; https://typesafe.ai | 2026-09-23 | blog grep 2 hits each; homepage: `Join Waitlist` 2 hits, `jobs.ashbyhq.com/typesafe-ai` 2 hits, same anchor | — |
| 6.3 | Self-serve signup: the docs quickstart says "Open the Playground and log in" and "Get your API key from the dashboard (console.typesafe.ai/keys)" with no signup or approval step described. The logged-out console shows "Welcome to TypeSafe", "Continue with Google", "Email me a code instead"; `/signup` redirects to `/login?returnTo=%2Fsignup`. The public JS bundle contains an invite flow ("You've been invited to join TypeSafe!") and gating strings ("Email signup is disabled. Continue with Google to create your account.", error reasons `SELF_SERVE_DISABLED` / `signups_disabled`). Whether a new Google login is admitted or gated cannot be settled without an account. | implied (self-serve path exists in code; gating flags exist too) | https://docs.typesafe.ai/introduction/quickstart ; https://console.typesafe.ai/login ; console JS chunk `1s6naw2rmxnam.js` | 2026-09-23 | grep counts below | docs imply; console code shows both self-serve and gated branches |
| 6.4 | Billing model per the MCA: usage is paid with **prepaid credits** — "Customer must obtain TypeSafe-managed credits that are consumed by each Input submitted to the Services through Customer’s account"; credits are "Purchased Credits" or "Promotional Credits" TypeSafe "issues to Customer at no cost to Customer" at its sole discretion; Purchased Credits "expire on the earlier of (y) the end of the Term and (z) the date that is 12 months after the purchase date"; optional "automatic Purchased Credit refills"; one account per customer for promo credits. | documented (legal) | https://typesafe.ai/legal/mca | 2026-09-23 | raw HTML grep, 2 hits each (page renders text twice) | documented |
| 6.5 | Invoice terms also exist: Fees "will be paid in US dollars" and "all Fees are due within 30 days after the invoice date"; late fees "1.5% per month"; an "Order" can be an executed order, "the checkout page on TypeSafe’s website", or a confirmation email — so both self-serve checkout and invoiced orders are contemplated. | documented (legal) | https://typesafe.ai/legal/mca | 2026-09-23 | raw HTML grep, 2 hits each | documented |
| 6.6 | Card / top-up mechanics: the console's public JS bundle has analytics event names "billing topup started", "billing topup succeeded", "billing payment method attach succeeded", "billing auto reload toggled" — consistent with card-on-file prepaid top-ups with auto-reload. | implied (UI code strings, not documentation) | console JS chunk `/_next/static/chunks/1s6naw2rmxnam.js` | 2026-09-23 | grep -aoF, 1 hit each | implied |
| 6.7 | Promotional-credit amount, whether new accounts receive any, and minimum top-up are not published. | unknown | — | 2026-09-23 | no page states them | needs account |
| 6.8 | Jev is also resold via OpenRouter (`~typesafe/jev-latest`) at "$0.042 per million input tokens, $0 per million output tokens." — a second, third-party, pay-as-you-go route to the model. | documented (third-party page; linked from docs cookbook) | https://openrouter.ai/~typesafe/jev-latest | 2026-09-23 | raw HTML grep, 6 hits | third-party |

## Verbatim evidence quotes

Scratchpad files are raw `curl -sL` output. `p()` = `/usr/bin/grep -aoF -- "<quote>" <file> | wc -l` (LC_ALL=C).

**https://typesafe.ai** (`typesafe_ai.html`)
- `$42` — 1 hit. `Per Billion input tokens.` — 1 hit. (Adjacent text order in the DOM: "Jev.Cost" / "$42" / "Per Billion input tokens." / "238x" / "Lower input price than Claude Fable 5.1".)
- `Lower input price than Claude Fable 5.1` — 2 hits. `238x` — 2 hits. `Jev.Cost` — 2 hits.
- `Are these prices temporary or subsidized?` — 1 hit (FAQ heading only; no answer text in served HTML).
- `Cost $0.000081` — 1 hit. `Cost $0.013880` — 1 hit. `444.6x Cheaper.` — 1 hit.
- `Join Waitlist` — 2 hits; `jobs.ashbyhq.com/typesafe-ai` — 2 hits (anchor: `<a class="framer-1ur8e9e framer-1zrops" href="https://jobs.ashbyhq.com/typesafe-ai?utm_source=QLrx0vq4BW">`).
- `production price` — 0 hits (`grep -aic`).

**https://typesafe.ai/blog/introducing-system-one-models-and-jev** (`typesafe_ai_blog_introducing-system-one-models-and-jev.html`)
- `Input tokens: $0.042 / MTok ($42 per billion tokens).` — 2 hits.
- `Output tokens: FREE (too cheap to meter).` — 2 hits.
- `Input tokens: from $0.20 to $10 / MTok.` — 2 hits. `Output tokens: ~5x more expensive than input tokens.` — 2 hits (LLM column of the same comparison).
- `available today in early access` — 2 hits.
- `We make our pricing transparent. We can’t prove it isn’t subsidized; we’ll need the long-term to prove the sustainability of our pricing (which we expect to go down, not up).` — 2 hits.
- `bringing developers off the waitlist as quickly as we can` — 2 hits.
- `which ends up costing ~$7/hour` — 2 hits (Doom demo at ~10 queries/s).
- `production price` — 0 hits.

**https://docs.typesafe.ai/models** (`docs_typesafe_ai_models.html`, raw Next.js HTML)
- `Price (per Btok / per Mtok)` — 2 hits. `$42 / $0.042` — 2 hits.
- `Charged per input token. Output tokens are free. A Btok is a billion tokens and an Mtok is a million tokens.` — 2 hits.
- `250,000 tokens per second / 1,200 requests per minute` — 2 hits.
- `Rate limits are adjusting dynamically.` — 2 hits. `Higher limits are available on custom and enterprise plans.` — 2 hits.
- `production price` — 0 hits.

**https://docs.typesafe.ai/llms-full.txt** (`docs_typesafe_ai_llms-full_txt.html`)
- `Price (per Btok / per Mtok) | \$42 / \$0.042` — 1 hit (Models table row; `\$` is the file's escaping).
- `Charged per input token. Output tokens are free.` — 1 hit.
- `PRICE = (0.042, 0.00)  # $ per 1M tokens (input, output); TypeSafe jev-1.12 as of 2026-09` — 1 hit (cookbook code).
- `TYPESAFE_PRICE = (0.042, 0.00)  # Historical TypeSafe rate, as of 2026-08` — 2 hits (cookbook code).
- `They are not verified `jev-latest` prices or current billing amounts.` — 2 hits (cookbook prose).
- `verifier: TypeSafe `jev-1.12` at \$0.042 / \$0.00 (output tokens are free;` — 1 hit (SDE cascade cookbook; links the blog as "published Jev pricing").
- `Open the [Playground](https://console.typesafe.ai/playground)** and log in.` — 1 hit. `Get your API key** from the [dashboard](https://console.typesafe.ai/keys)` — 1 hit.
- `Contact [sales@typesafe.ai](mailto:sales@typesafe.ai)` — 1 hit.
- `production price` — 0 hits.

**https://typesafe.ai/legal/mca** (`typesafe_ai_legal_mca.html`; each string renders twice in the Framer HTML)
- `Sep 19, 2026` — 2 hits (after "Last updated").
- `will be paid in US dollars` — 2 hits. `all Fees are due within 30 days after the invoice date.` — 2 hits.
- `Customer must obtain TypeSafe-managed credits that are consumed by each Input submitted to the Services through Customer’s account` — 2 hits.
- `issues to Customer at no cost to Customer as described in Section 8.2(b)` — 2 hits. `TypeSafe may, but has no obligation to, issue Promotional Credits to Customer.` — 2 hits.
- `Purchased Credits expire on the earlier of (y) the end of the Term and (z) the date that is 12 months after the purchase date` — 2 hits.
- `if Customer has opted in to automatic Purchased Credit refills` — 2 hits.
- `create more than one account for the purpose of receiving additional Promotional Credits` — 2 hits.
- `the checkout page on TypeSafe’s website` — 2 hits. `Late Fees are subject to a service charge of 1.5% per month` — 2 hits.

**https://console.typesafe.ai/login** (`console_typesafe_ai_login.html`)
- `Welcome to TypeSafe` — 2 hits. `Continue with Google` — 1 hit. `Email me a code instead` — 1 hit.

**Console public JS** (`https://console.typesafe.ai/_next/static/chunks/1s6naw2rmxnam.js?dpl=621c9692cdeee1140b7683a3b712aa0ab4f56b6d`)
- `Email signup is disabled. Continue with Google to create your account.` — 1 hit.
- `You've been invited to join TypeSafe!` — 1 hit. `Sign in with the email where your invite was sent.` — 1 hit.
- `SELF_SERVE_DISABLED` — 6 hits. `signups_disabled` — 6 hits.
- `billing topup started` — 1. `billing topup succeeded` — 1. `billing payment method attach succeeded` — 1. `billing auto reload toggled` — 1.

**https://openrouter.ai/~typesafe/jev-latest** (`openrouter_jev.html`)
- `$0.042 per million input tokens, $0 per million output tokens.` — 6 hits. Title `Jev Latest - API Pricing &amp; Providers | OpenRouter` — 1 hit.

## What I could not settle

1. **The "production prices" qualifier** — not on any fetched page. If it exists, it is inside the homepage FAQ answer to "Are these prices temporary or subsidized?" (collapsed, JS-rendered; not in served HTML) — settle with a browser render of the homepage FAQ (no account needed, but outside this pass's tool scope).
2. **Whether a new Google login is admitted self-serve or gated** (`SELF_SERVE_DISABLED` branch) — needs an account attempt.
3. **Promotional/free credit amount for new accounts, minimum top-up, accepted payment methods** — needs an account (console billing page) or email to sales@typesafe.ai.
4. **Enterprise/custom-plan pricing and limits** — email sales@typesafe.ai.
5. **Whether the OpenRouter route is TypeSafe-operated or a reseller markup** — OpenRouter provider page (not fetched further; out of scope).
6. **`speed_latest` rate label in cookbooks** — not on the Models page; unknown whether it is a retired alias; needs `GET /v1/models` with a key.
