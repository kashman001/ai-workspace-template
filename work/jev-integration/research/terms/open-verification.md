# Open verification — `terms` (2026-09-23)

What public sources could not settle, each tagged with the access that would settle it. Items marked **browser** need only a JS-rendering browser (no account); the pass was restricted to curl/WebFetch.

## Pricing (Q1, Q6)
| # | Open item | Access that settles it |
|---|---|---|
| O1 | ~~Whether the homepage FAQ answer to "Are these prices temporary or subsidized?" contains any qualifier such as "production prices" (answer body is not in the served HTML).~~ **Closed 2026-09-23:** the answer body is in the homepage's Framer module script (`https://framerusercontent.com/sites/43bTeC8cU9jZO20XvdK79t/1bDVrPYMWEZ6eWmJvyMH7WadCbl21tfR2JXCIVJyZRA.BkrK7V15.mjs`): "We can serve Jev profitably at our current prices. Our goal is to make intelligence more affordable over time as we improve the technology." — no "production" qualifier (`production price` 0 in all 21 modules). | — (settled by curl; no browser needed) |
| O2 | Enterprise / custom-plan pricing and limit numbers. | email sales@typesafe.ai |
| O3 | Minimum top-up, accepted payment methods, whether card top-up/auto-reload is live. (Narrowed 2026-09-23; previously also "Promotional (free) credit amount for new accounts" — settled: "$5 in credit (~120 million tokens)" per TypeSafe's X post of 2026-09-20, record 6.1.) | account (console billing page) |
| O4 | Whether the OpenRouter listing is TypeSafe-operated or a reseller markup. | OpenRouter provider page (browser) |
| O5 | Whether `speed_latest` (a rate label in two cookbooks) is a retired alias; what `GET /v1/models` lists today. | key (API call) |
| O6 | Whether console login currently works for an existing account (open GitHub issue typesafe-ai/skills#10 reports HTTP 500s on all auth actions, Sep 21–22). (Narrowed 2026-09-23; previously also "whether a new Google login is admitted self-serve or hits the `SELF_SERVE_DISABLED` / invite-only branch" — self-serve is announced as of 2026-09-20 and the JS strings are error-handling branches, record 6.3; the sign-up half is now O29.) | account attempt |
| O7 | ~~How to join the waitlist named in the launch post (no form found; homepage "Join Waitlist" goes to the jobs board).~~ **Closed 2026-09-23:** the waitlist ended on 2026-09-20 — X `@typesafeai`: "Jev is now available to everyone. No waitlist."; homepage module banner "NO MORE WAITLIST" ("Sept 20, 2026 • TypeSafe News") with a "Sign up" button to the console. The "Join Waitlist" string was a Framer layer name; the visible button is "Open roles" (jobs board). | — (settled) |
| O29 | Whether console sign-up succeeds today: self-serve is announced (2026-09-20), but typesafe-ai/skills#10 reports sign-in/sign-up returning HTTP 500 on Sep 21–22 ("still reproducible" 2026-09-22 12:10 UTC on a newer deployment; no vendor reply). (Added 2026-09-23.) | account attempt (sign-up) |
| O31 | The console JS chunk counts behind 6.3 / 6.6 and the appendix (18 chunks referenced from logged-out `/login`; `SELF_SERVE_DISABLED` 6, `signups_disabled` 6, `Email signup is disabled` 1, invite string 1, `billing topup started` 1, `billing auto reload toggled` 1) are the corrections agents' own counts (gen 2, gen 3); the sweep did not re-fetch them, and chunks loaded only after login are out of reach. Whether the logged-in bundle carries more or different strings, and whether the billing events are wired to a live top-up flow. (Added 2026-09-23, R37.) | browser (logged-in console) / account |

## Limits and auth (Q2, Q3)
| # | Open item | Access that settles it |
|---|---|---|
| O8 | Scope of the 250,000 tok/s + 1,200 rpm limits (per key / per account / global); any concurrency cap. | account (console usage page) or email sales@ |
| O9 | Whether the server emits `retry-after` / `retry-after-ms` on 429/529, and any undocumented `x-ratelimit-*` headers. | key (observe a 429) |
| O10 | Tier ladder, Order contents ("Usage Limits", term, credit rate table). | email sales@ (Order Form) |
| O11 | API key format/prefix, multiple keys per account, rotation/revocation/expiry. | account (console `/keys`) |
| O12 | Org/project/workspace model, key scopes, service accounts, SSO/SAML. | account, or email sales@ (enterprise) |
| O13 | When the server returns 403 (SDKs model `PermissionDeniedError`, docs never say). | key or email support@ |
| O30 | The docs' error table says a missing/invalid API key returns `401 Unauthorized` ("Missing or invalid API key. Check the `Authorization` header."); issue typesafe-ai/skills#10 reports a keyless `POST /v1/systemone` returning `403 {"error_type":"authentication_error","message":"Must supply an API key!"}` (third-party, 2026-09-21). Which status does the server send? (Added 2026-09-23.) | one keyless API request (no account or key needed) |

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

## Record bookkeeping (added 2026-09-23, R37)
| # | Open item | Access that settles it |
|---|---|---|
| O32 | ~~The record header's "11 split" list (`record.md` tally line) was not re-counted by the sweep (split halves are prose inside the verdict cell).~~ **Closed on creation 2026-09-23:** re-counted from the verdict column — 11 rows carry two halves (1.10, 2.6, 2.9, 3.6, 4.5, 4.6, 4.8, 5.2, 6.3, 6.7, 7.4), matching the list. Note: 3.6 reads `unknown (format) / documented (validation)` and is counted under `unknown` in the 54/3/7/2 tally (first word), so 10 of the 11 split rows are among the 54 `documented`; the count 11 is right, the phrase "11 of them" is off by 3.6. | — (settled by re-count) |
