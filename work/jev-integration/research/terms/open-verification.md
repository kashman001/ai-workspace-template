# Open verification — `terms` (2026-09-23)

What public sources could not settle, each tagged with the access that would settle it. Items marked **browser** need only a JS-rendering browser (no account); the pass was restricted to curl/WebFetch.

## Pricing (Q1, Q6)
| # | Open item | Access that settles it |
|---|---|---|
| O1 | Whether the homepage FAQ answer to "Are these prices temporary or subsidized?" contains any qualifier such as "production prices" (answer body is not in the served HTML). | browser (render homepage FAQ) |
| O2 | Enterprise / custom-plan pricing and limit numbers. | email sales@typesafe.ai |
| O3 | Promotional (free) credit amount for new accounts, minimum top-up, accepted payment methods, whether card top-up/auto-reload is live. | account (console billing page) |
| O4 | Whether the OpenRouter listing is TypeSafe-operated or a reseller markup. | OpenRouter provider page (browser) |
| O5 | Whether `speed_latest` (a rate label in two cookbooks) is a retired alias; what `GET /v1/models` lists today. | key (API call) |
| O6 | Whether a new Google login is admitted self-serve or hits the `SELF_SERVE_DISABLED` / invite-only branch; whether console login currently works (open GitHub issue typesafe-ai/skills#10 reports HTTP 500s). | account attempt |
| O7 | How to join the waitlist named in the launch post (no form found; homepage "Join Waitlist" goes to the jobs board). | email hello@/sales@typesafe.ai |

## Limits and auth (Q2, Q3)
| # | Open item | Access that settles it |
|---|---|---|
| O8 | Scope of the 250,000 tok/s + 1,200 rpm limits (per key / per account / global); any concurrency cap. | account (console usage page) or email sales@ |
| O9 | Whether the server emits `retry-after` / `retry-after-ms` on 429/529, and any undocumented `x-ratelimit-*` headers. | key (observe a 429) |
| O10 | Tier ladder, Order contents ("Usage Limits", term, credit rate table). | email sales@ (Order Form) |
| O11 | API key format/prefix, multiple keys per account, rotation/revocation/expiry. | account (console `/keys`) |
| O12 | Org/project/workspace model, key scopes, service accounts, SSO/SAML. | account, or email sales@ (enterprise) |
| O13 | When the server returns 403 (SDKs model `PermissionDeniedError`, docs never say). | key or email support@ |

## Data and privacy (Q4)
| # | Open item | Access that settles it |
|---|---|---|
| O14 | Trust-center contents at trust.typesafe.ai (SOC 2 / ISO 27001 / pen-test / encryption / subprocessor list / FAQ) — Vanta JS shell to curl and WebFetch. | browser (possibly an access request for report PDFs) |
| O15 | ZDR terms: eligibility, price, whether it also stops Telemetry derivation and covers logs/backups. | email privacy@typesafe.ai |
| O16 | Numeric retention window for request/response payloads and logs on the standard tier. | email privacy@ or trust-center FAQ (browser) |
| O17 | Cloud provider / physical region beyond "hosted in the United States". | browser (trust center) or email |
| O18 | Whether "prior consent" to training (MCA §4.1) is ever solicited in the console (opt-in checkbox). | account |
| O19 | HIPAA / BAA availability. | email privacy@ or sales@ |

## Legal (Q5)
| # | Open item | Access that settles it |
|---|---|---|
| O20 | Whether the in-console click-through/checkout presents the MCA or only the website ToU. | account (signup/checkout flow) |
| O21 | Promotional-credit terms "made available at the time of issuance". | account |
| O22 | Prior versions of the legal documents (only "Last updated" dates are shown). | email support@ or Wayback Machine (not fetched) |
| O23 | Terms of any "separate agreement" / enterprise paper. | email sales@ |

## Support and status (Q7)
| # | Open item | Access that settles it |
|---|---|---|
| O24 | Enterprise/Order-level SLA and support tiers; the "standard support policies" the MCA references. | email sales@ or support@ |
| O25 | Support response times and hours for support@typesafe.ai. | email support@ |
| O26 | Whether the logged-in console has a help/chat widget or status banner. | account |
| O27 | Whether Discord is staffed as an official support channel. | join the server (Discord login) |
| O28 | Relationship of github.com/typesafeai ("TypeSafe Community") to typesafe.ai. | email hello@ |
