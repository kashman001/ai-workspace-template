# Verification — `terms` (adversarial re-check, 2026-09-23)

Lead re-fetched or re-grepped every uncertain or load-bearing claim against its cited source using **independent copies** (the lead's own `curl -sL` of each page, saved before the clusters reported, plus fresh fetches for live pages). Counts are `LC_ALL=C grep -aoF` on raw HTML/markdown (rules 3/4). Method rule 8 is the bar: the table below records moves in **both** directions. Summary, on the unified scale (`schema.md` § "Verification scale"), counted from the Result column: **V1–V43, 43 rows — 37 `survived`, 3 `downgraded` (V17, V40, V41), 1 `overturned` (V23 — *against the pass*, i.e. in the subject's favour), 2 `reversed` (V7, V8 — lead outcome undone by the independent check), 0 `confirmed`, 0 `spread`, 0 `not re-checked`.** The S4 table's two rows are **not** in that total; with them, 45 rows — 38 survived, 3 downgraded, 2 overturned (S4 qualifier, V23), 2 reversed. (corrected 2026-09-23; previously: "43 checked — 37 survived, 3 downgraded, 2 overturned (one overturn is *against the pass*, i.e. in the subject's favour)" — summed to 42 and matched no reading of the column; V7/V8 had been counted as survived.) Two of the lead's own first greps were false misses and are recorded so nobody repeats them. **Post-check note (2026-09-23, corrections pass):** the independent fact-check found that V7 and V8 ratified rather than tested their rows (rule-8 misses, annotated in place, not re-scored); the resulting corrections are in `record.md` 6.1–6.3, 6.7, and the check's patterns are appended at the end of this file.

## Standing claim S4 first
| Claim | Source says | Result |
|---|---|---|
| S4 "$42 per billion input tokens" | docs `/models` served HTML row: `Price (per Btok / per Mtok)` → `$42 / $0.042` (order confirmed, not transposed); homepage `$42` + `Per Billion input tokens.` (1 hit each); launch post `Input tokens: $0.042 / MTok ($42 per billion tokens).` (2 hits) | **survived** — documented; meter = input tokens; output free |
| S4 qualifier "production prices" | `production price` = 0 hits on homepage (590 KB), launch post, docs `/models`, the 910 KB docs corpus (`llms-full.txt`), MCA, ToU, DPA, Privacy Policy. Only price qualifiers on the site: blog "We can’t prove it isn’t subsidized … (which we expect to go down, not up)" (2 hits); homepage FAQ heading "Are these prices temporary or subsidized?" (1 hit in the served HTML; no answer body served — text extraction shows the FAQ headings back-to-back; corrected 2026-09-23: the answer body is in the page's Framer module script, quoted in the Result cell); cookbook "Historical TypeSafe rate, as of 2026-08". | **overturned** — the wording is the launcher's, not the site's. Recorded as `contradicted` (attribution); figure intact. Corrections 2026-09-23: the FAQ answer body is recoverable from the homepage's Framer module script (`https://framerusercontent.com/sites/43bTeC8cU9jZO20XvdK79t/1bDVrPYMWEZ6eWmJvyMH7WadCbl21tfR2JXCIVJyZRA.BkrK7V15.mjs`): "We can serve Jev profitably at our current prices. Our goal is to make intelligence more affordable over time as we improve the technology." — `production price` 0 there too (all 21 modules); the vendor's own qualifier now stands beside the figure (record header, 1.7). |

## Pricing cluster
| # | Claim (pass row) | What the source actually says (lead check) | Result |
|---|---|---|---|
| V1 | 1.1/1.2 `$42 / $0.042`; "Charged per input token. Output tokens are free." | `md_models.md` 1 hit each; served HTML 2 hits; row order Btok→Mtok = $42→$0.042 | survived |
| V2 | 1.4 homepage figure `documented` because the docs page backs it | `/pricing` 404 on both hosts (re-checked); docs Models page carries the figure | survived, with the note that the homepage **alone** is `implied` per the brief |
| V3 | 1.5 blog quotes incl. "Output tokens: FREE (too cheap to meter)." | 2 hits each on lead's copy | survived |
| V4 | 1.7 spread — same figure, three version tags (jev-1.13 page; jev-1.12 cookbooks "as of 2026-09" / "as of 2026-08") | `jev-1.12` = 27 hits in llms-full; historical-rate comments present | survived (spread recorded, none adopted) |
| V5 | 1.9 OpenRouter "$0.042 per million input tokens, $0 per million output tokens." | fresh fetch: 6 hits | survived |
| V6 | 1.10 `speed_latest` unknown | llms-full: 2 hits, cookbook prose only | survived (unknown) |
| V7 | 6.2 "early access" + "waitlist" documented in the launch post; homepage "Join Waitlist" → Ashby jobs board | `available today in early access` 2; `bringing developers off the waitlist as quickly as we can` 2; homepage `Join Waitlist` 2, `jobs.ashbyhq.com/typesafe-ai` 2 | ~~survived~~ reversed — (re-scored 2026-09-23 on the unified scale, R29: the lead's outcome was undone by the independent check and row 6.2 rewritten; previously: "survived") **rule-8 miss (annotated 2026-09-23 from the independent check; not re-ratified):** this check re-ran the same attribute grep instead of reading the visible text — the 2 `Join Waitlist` hits are `data-framer-name` values and the visible label is "Open roles" (2 hits). The "early access + waitlist" reading is also superseded by TypeSafe's X post of 2026-09-20 ("Jev is now available to everyone. No waitlist.") and the homepage module's dated "NO MORE WAITLIST" banner, which the check did not look for. Row 6.2 corrected in `record.md`. |
| V8 | 6.3 self-serve `implied`; console JS carries gating strings | fresh fetch of all 26 console JS chunks (as of the pass's fetch): `SELF_SERVE_DISABLED` 12, `signups_disabled` 12, `Email signup is disabled` 2, `You've been invited to join TypeSafe!` 2 | ~~survived~~ reversed — (re-scored 2026-09-23 on the unified scale, R29: the lead's outcome was undone by the independent check and row 6.3 re-verdicted; previously: "survived (`implied`; both branches present)") **rule-8 miss (annotated 2026-09-23 from the independent check; not re-ratified):** the check certified doubled counts (re-count 2026-09-23: 18 chunks; 6 / 6 / 1 / 1 — exactly half) and read error-handling branches (a client-side map from a server 403 reason to a redirect page) as "gated branches". Self-serve signup is first-party `documented` as of 2026-09-20; row 6.3 corrected in `record.md`. |
| V9 | 6.4/6.5 MCA billing: credits per Input, 12-month expiry, USD, 30-day invoices, 1.5%/mo, checkout page as Order | 2 hits each on lead's MCA copy | survived |
| V10 | 6.6 card top-up `implied` from JS event names | `billing topup started` 1; `billing auto reload toggled` 1 (18 public JS chunks referenced from `/login`, re-counted 2026-09-23) (corrected 2026-09-23; previously: "`billing topup started` 2; `billing auto reload toggled` 2") | survived (`implied`) |

## Limits-and-auth cluster
| # | Claim | What the source actually says | Result |
|---|---|---|---|
| V11 | Q2-1/2 250,000 tok/s + 1,200 rpm; 429 on either | md 1 hit; served HTML 2 hits (`A request over either limit returns` 2) | survived |
| V12 | Q2-6 dynamic limits; enterprise via sales@ | `Rate limits are adjusting dynamically.` 1; `Higher limits are available on custom and enterprise plans.` 1 | survived |
| V13 | Q2-4 per-key scope unknown; cookbook hint "a rate limit on a shared key" | llms-full: 1 hit; `rate-limits above roughly eight` 1 hit (jev-1.12 context) | survived (unknown; hints are cookbook prose) |
| V14 | Q2-8 backoff guidance 429/529; exponential backoff | `md_api.md` error table rows 401/422/429/529 present; `exponential backoff` 1 | survived |
| V15 | Q2-9 OpenAPI declares only 200/422; no 429/401 | fresh `openapi.json` (v0.2.0): paths `/v1/systemone`, `/v1/models`; responses `['200','422']` each; `securitySchemes` = `HTTPBearer` only | survived |
| V16 | Q2-10 SDKs honor `retry-after`/`retry-after-ms`; server emission "when the response carries one" | Python `_core/constants.py` has both header names; models page `honor the` 2 hits | survived (server side stays `implied`) |
| V17 | Q2-12 "the only documented response header is `x-typesafe-request-id`" | `x-typesafe-request-id` = **0** on the HTTP API reference (`api.md`); 1 on JS `RateLimitError` page, 1 on Python exceptions page, 12 in llms-full (all SDK pages); `REQUEST_ID_HEADER` in Python source | **downgraded** — documented in the SDK references only; the HTTP API reference documents no response headers at all |
| V18 | Q3-1/2 Bearer key; no `x-api-key`, no OAuth | openapi.json: `Send your API key in the Authorization header as \`Bearer <API_KEY>\`.` 1; schemes = HTTPBearer only | survived |
| V19 | Q3-3 keys from console `/keys`; quickstart "log in" | `md_introduction_quickstart.md`: `console.typesafe.ai/keys` 1; `Open the [Playground](…)** and log in.` 1 | survived |
| V20 | Q3-4 Google / email code; no password | lead's login copy: `Continue with Google` 1, `Email me a code instead` 1, `password` 0 | survived |
| V21 | Q3-5 MCA "username and password" vs passwordless UI | MCA quote 2 hits; login page `password` 0 | survived (`contradicted`, minor wording) |
| V22 | Q3-16 GitHub issue typesafe-ai/skills#10 open, 2026-09-21, console 500s | fresh GitHub API: `state: open`, `created_at 2026-09-21T23:15:01Z`, title matches | survived (`implied`; unverified third-party report) |
| V23 | Q3-17 "the word 'waitlist' is not first-party (`waitlist`=0 in llms-full)" | llms-full `waitlist` = 0 is true, **but the launch post (first-party) has `waitlist` 2 hits** ("bringing developers off the waitlist") | **overturned** — waitlist wording *is* first-party (launch post); only the docs corpus lacks it. Over-correction against the subject (method-rules corollary). Note 2026-09-23: first-party but no longer current — superseded by the 2026-09-20 "No waitlist" announcement (record 6.2). |

## Data-and-privacy cluster
| # | Claim | What the source actually says | Result |
|---|---|---|---|
| V24 | #1 Privacy Policy "Nov 19, 2025" | 2 hits | survived |
| V25 | #2/#3/#4 no-training in Privacy Policy, MCA §4.1 (prior-consent carve-out), docs/models | Privacy 2; MCA 2; models md 1 | survived |
| V26 | #5 Telemetry "without restriction" | 2 hits | survived |
| V27 | #6/#7 retention open-ended; MCA delete-at-any-time | Privacy quote 2; MCA quote 2 | survived |
| V28 | #8 ZDR enterprise offer; no API option | docs `legal.md` sentence present; openapi.json has no retention/ZDR parameter or header | survived |
| V29 | #9 "hosted in the United States" | 2 hits | survived |
| V30 | #11/#12 DPA Apr 24, 2026; 72 h; annual audit; SCCs Module 2; UK Addendum; subprocessor URL | 2 / 2 / 2 / 2 / 6 / 2 hits | survived |
| V31 | #13/#14/#17 trust center unreadable; SOC 2 / ISO / HIPAA / encrypt = 0 | fresh trust.typesafe.ai: 200, 6,914 B, `<title>Typesafe.ai Trust Center`, `vanta` 26; negatives 0 across MCA+ToU+DPA+Privacy | survived (unknown, not "absent") |

## Legal cluster
| # | Claim | What the source actually says | Result |
|---|---|---|---|
| V32 | #1/#2 MCA and ToU both "Sep 19, 2026"; ToU defers to separate agreement | 2 hits each | survived |
| V33 | #3 console login links ToU + privacy, not MCA | `https://typesafe.ai/legal/terms` 2, `/legal/mca` 0 on login page | survived (link targets documented; legal effect `implied`) |
| V34 | #4 output disclaimer/assignment "if any" | 2 hits | survived |
| V35 | #7/#8/#9 §2.3 restrictions incl. "security or vulnerability test" | 2 hits each | survived |
| V36 | #12/#14 California law; cap greater of 12 months' fees or $50 | 2 hits each (`AND (B) $50 USD.` single-quoted) | survived |
| V37 | #13/#15 ToU Delaware; $100 cap; US-visitors sentence | 2 hits each | survived |
| V38 | #21/#22 SDKs MIT; Python LICENSE placeholder | npm 0.6.0 `MIT` (2026-09-15); PyPI 0.7.1 `MIT`; raw LICENSE `Copyright (c) [year] [fullname]` 1 | survived |

## Support-and-status cluster
| # | Claim | What the source actually says | Result |
|---|---|---|---|
| V39 | #1 status.typesafe.ai on Better Stack; not linked from any first-party page | `dig` CNAME `statuspage.betteruptime.com.`; 200; `status.typesafe` = 0 on homepage, llms-full (910 KB), docs legal, four legal pages, console login | survived |
| V40 | #2 99.839% / 99.988%; many "Down for N minutes" day-cells | fresh fetch: identical percentages; **lead's first grep for `Down for [0-9]+ minutes` returned 0 — a false miss; the page encodes the space as `&nbsp;`**; corrected grep: 23 day-cells, 2–59 minutes | downgraded — precision: the percentages are live values that drift; cite "as of 2026-09-23" only (corrected 2026-09-23; previously: "survived, with a downgrade in precision") |
| V41 | #5 Discord "106844 members" | fresh og:description "106852 members" | downgraded — to "~106.8k per invite metadata (live counter)" (corrected 2026-09-23; previously: "survived, downgraded") |
| V42 | #8 July/Aug "No incidents reported" vs down-days on the strip | `No incidents reported` 2 on incidents page; 23 down-cells on the strip | survived (spread recorded, rule 6) |
| V43 | #3 no SLA; MCA warranty/remedy/disclaimer | MCA: `SLA`/`uptime`/`service credit` 0; warranty and disclaimer quotes 2 hits each | survived |

## Lead's own false misses (recorded so they are not repeated)
- `grep 'Down for [0-9]+ minutes'` → 0 because the status page encodes the space as `&nbsp;`. Grep `Down for ` instead.
- `x-typesafe-request-id` on `api.md` → 0 is a **true** absence for the HTTP reference; the header is documented on SDK pages only (V17).
- Double-quoted greps for strings containing `$50` / `$100` expand shell variables and return 0 (the legal cluster hit this too). Single-quote them.

## Net movement
Down: S4 qualifier (overturned), V17 (downgraded), V40 (precision), V41 (precision). Up / in the subject's favour: V23 (overturned an over-correction — waitlist wording is first-party). Everything else survived on independent copies. The verification moved claims in both directions, so it is a check, not a ratification.

**After the independent check (2026-09-23):** two of the "survived" rows above (V7, V8) were ratifications, not checks — the rule-8 bar this file claims was not met for the access cluster. Both are annotated in place rather than re-scored; the corrected claims are in `record.md` 6.1–6.3, 6.7.

**Re-scored 2026-09-23 (R29, unified scale):** V7 and V8 now read `~~survived~~ reversed` (level 6 — the lead outcome was undone by the fact-check); V40 and V41 now read `downgraded` (level 3 — the claim stands with weaker precision); V4 and V42 stay `survived` because the claims they check are themselves recorded spreads that stood as worded. The summary line at the top of this file is restated on the same scale. (added 2026-09-23, R29/R31)

## Patterns from the independent check

(Appended verbatim from `fact-check.md` §Patterns under ruling R8, 2026-09-23.)

1. **Over-correction against the subject, concentrated on access.** Every WRONG/OVERSTATED verdict (6.1, 6.2, 6.3, 6.7, the profile's headline recommendation) understates something TypeSafe genuinely offers: open self-serve signup and a $5 starting credit, both announced by the vendor on 2026-09-20. The pass's own verification stage (V7, V8) ratified these rather than testing them. Legal, pricing, limits, privacy and support rows — where the pass started from the reference documents — are essentially flawless. The defect rate tracks the evidence class: reference pages → clean; inference from UI/marketing/minified code → wrong.
2. **Stale first-party source treated as current.** The Sep 15 launch post's "waitlist" wording was carried forward as the access story without checking for anything newer. The vendor's X account (`@typesafeai`) is linked from both the homepage and the docs navbar and was never consulted. Recommend: for any "current state" claim (access, availability, pricing changes), check the vendor's dated announcement channel (X/blog) for anything newer than the page being quoted, and record the date of the quoted page beside the claim.
3. **"JS-rendered" written off twice when the content was one curl away.** The homepage FAQ answers *and* the "NO MORE WAITLIST" news banner both sit in the Framer module scripts referenced from the served HTML (`framerusercontent.com/modules/*.mjs`). The pass logged O1 as browser-only. The method-rules corollary ("JS-rendered does not mean unverifiable") should be operationalised as: fetch the page's own module/chunk scripts and grep them before logging a browser-only item. The pass did exactly this for the console (Next.js chunks) but not for the marketing site.
4. **Component names counted as visible copy.** `data-framer-name="Join Waitlist"` (a designer's layer name; the component's default title prop) was reported as a button label and propagated to the record, profile, verification and open-verification. When quoting UI text, strip to rendered text (or confirm with WebFetch, which correctly saw only "Open roles") before counting.
5. **Absolute absence wording.** "Published anywhere", "no page states them" were written after searching docs + legal + homepage HTML. Absence claims should name the corpus searched ("on docs, legal and homepage pages") — rule 1 — because here the fact lived on a channel outside that corpus.
6. **Live counts drift; label them.** JS chunk count (26→18), gating-string counts (12→6 — exactly doubled), status day-cells (23→24), Discord members. None is a substantive error, but unlabelled live numbers in a "verified" appendix invite false "contradictions" on re-check.
7. **What transfers to the sibling items.** (a) The homepage FAQ text is recoverable and is the origin of S1's exact wording ("Jev is TypeSafe's first public System One Model, optimized for automation") and a first-party S3 temper ("Jev guarantees the shape of its answers, not that every decision is correct"). (b) Issue #10 reports a keyless call returning 403 `authentication_error` where the docs say 401 — the same docs-vs-live pattern `what-jev-is` found. (c) The Sep 20 "open to everyone" announcement and $5 credit should be reflected wherever `integration-paths` discusses getting started.

