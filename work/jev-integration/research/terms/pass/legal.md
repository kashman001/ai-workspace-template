# Pass: `legal` (cluster `terms`) — Jev / TypeSafe commercial & licence terms (Q5)

- **Cluster:** terms / legal
- **Date checked:** 2026-09-23
- **Method:** `curl -sL` of first-party pages only (no account, no key, no API calls, no web search — first-party pages settled every sub-topic, so the shared search budget was not spent). Raw HTML saved to scratchpad; text extracted with a tag-stripping parser; every quote below re-grepped (`grep -c -F`) against the **raw fetched HTML** of its cited page.
- **Headline:** there is no single "Terms of Service" for Jev. The service is governed by a **Master Customer Agreement (MCA)** at `https://typesafe.ai/legal/mca` (last updated **Sep 19, 2026**); `https://typesafe.ai/legal/terms` is a **website Terms of Use** for typesafe.ai that expressly defers product use to a separate agreement. There is **no standalone acceptable-use policy page**; the MCA's §2.3 "License Restrictions" is the operative use-restriction list.

## URLs fetched (HTTP status, 2026-09-23)

| URL requested | Status | Resolved to / note |
|---|---|---|
| https://typesafe.ai/ | 200 | homepage; footer links `./legal/terms`, `./legal/privacy-policy` only |
| https://typesafe.ai/blog/introducing-system-one-models-and-jev | 200 | launch post; no legal content |
| https://typesafe.ai/sitemap.xml | 200 | lists 4 legal pages: `/legal/data-processing`, `/legal/mca`, `/legal/privacy-policy`, `/legal/terms` |
| https://typesafe.ai/robots.txt | 200 | `Allow: /` |
| https://typesafe.ai/llms.txt, /llms-full.txt | 404 | — |
| https://typesafe.ai/terms | 200 | 301→ `https://typesafe.ai/legal/terms` (website Terms of Use) |
| https://typesafe.ai/terms-of-service | 200 | 301→ `/legal/terms` (same page) |
| https://typesafe.ai/legal/terms | 200 | Terms of Use, "Last updated Sep 19, 2026" |
| https://typesafe.ai/legal/mca | 200 | Master Customer Agreement, "Last updated Sep 19, 2026" |
| https://typesafe.ai/legal/data-processing | 200 | Data Processing Addendum, "Last updated Apr 24, 2026" |
| https://typesafe.ai/legal/privacy-policy | 200 | Privacy Policy, "Last updated Nov 19, 2025" |
| https://typesafe.ai/data-processing (URL cited inside the MCA §4.4) | 200 | 301→ `/legal/data-processing` |
| https://typesafe.ai/privacy-policy (URL cited inside the ToU §13(a)) | 200 | 301→ `/legal/privacy-policy` |
| https://typesafe.ai/tos | 404 | — |
| https://typesafe.ai/legal | 404 | (no index page; the four `/legal/*` pages exist) |
| https://typesafe.ai/aup | 404 | — |
| https://typesafe.ai/acceptable-use | 404 | — |
| https://docs.typesafe.ai/ | 200 | 302→ `/introduction` |
| https://docs.typesafe.ai/llms.txt | 200 | full docs nav; includes `[Legal](https://docs.typesafe.ai/legal.md)` |
| https://docs.typesafe.ai/llms-full.txt | 200 | 910 KB; 0 hits for "acceptable use"/"usage policy"; "high-risk" hits are use-case copy only |
| https://docs.typesafe.ai/sitemap.xml, /robots.txt | 200 | robots carries `Content-Signal: ai-train=yes, search=yes, ai-input=yes` |
| https://docs.typesafe.ai/legal (and `/legal.md`) | 200 | index page linking DPA, MCA, Privacy Policy (not the ToU); mentions ZDR for enterprise |
| https://docs.typesafe.ai/terms | 404 | — |
| https://docs.typesafe.ai/sdk.md, /sdk/python.md, /sdk/javascript.md, /agent-skill.md, /api.md, /models.md | 200 | SDK pages link the GitHub repos below |
| https://console.typesafe.ai/ , /login , /signup | 200 | all resolve to `/login` (logged-out page); links `https://typesafe.ai/legal/terms` and `/legal/privacy-policy`; text "By continuing, you agree to the terms of use and the privacy policy" |
| https://api.github.com/repos/typesafe-ai/typesafe-sdk-js | 200 | `license.spdx_id: MIT`, public, pushed 2026-09-15 |
| https://raw.githubusercontent.com/typesafe-ai/typesafe-sdk-js/main/LICENSE | 200 | MIT, "Copyright (c) 2026 TypeSafe" |
| https://api.github.com/repos/typesafe-ai/typesafe-sdk-python | 200 | `license.spdx_id: MIT`, public, pushed 2026-09-21 |
| https://raw.githubusercontent.com/typesafe-ai/typesafe-sdk-python/main/LICENSE | 200 | MIT, but copyright line is the unfilled template `Copyright (c) [year] [fullname]` |
| https://api.github.com/repos/typesafe-ai/skills | 200 | `license.spdx_id: MIT`, public, pushed 2026-09-12 |
| https://raw.githubusercontent.com/typesafe-ai/skills/main/LICENSE | 200 | MIT, "Copyright (c) 2026 TypeSafe AI" |
| https://registry.npmjs.org/@typesafe-ai/sdk | 200 | latest 0.6.0 (2026-09-15), `"license":"MIT"`, repo typesafe-sdk-js |
| https://pypi.org/pypi/typesafe-sdk/json | 200 | version 0.7.1, `license_expression: MIT`, classifier `License :: OSI Approved :: MIT License` |
| https://trust.typesafe.ai/ , /subprocessors | 200 | Trust Center referenced by the DPA (not read in depth; out of Q5 scope) |
| LICENSE.md / LICENSE.txt variants on all three repos | 404 | only `LICENSE` exists |

## Findings

| # | Claim (one sentence) | Verdict | Source URL | Date checked | How verified | Documented vs. implied |
|---|---|---|---|---|---|---|
| 1 | The Jev service (console + API) is governed by a public **Master Customer Agreement**, last updated **Sep 19, 2026**, accepted by clicking a box, executing an Order, or "USING (OR MAKING ANY PAYMENT FOR) ANY SERVICES"; a separate signed agreement, if one exists, supersedes it. | documented | https://typesafe.ai/legal/mca | 2026-09-23 | curl 200; grep "Sep 19, 2026" = 2; §1 defines Services as console.typesafe.ai + API | Documented |
| 2 | `typesafe.ai/legal/terms` is a **website Terms of Use** (also "Last updated Sep 19, 2026") covering the Site only; it states that a separate agreement governs use of TypeSafe products/services, so it is **not** the service ToS. | documented | https://typesafe.ai/legal/terms | 2026-09-23 | curl 200 (`/terms` and `/terms-of-service` both 301 here); grep of the deferral sentence = 2 | Documented |
| 3 | The console's logged-out login page binds sign-ups to "the terms of use and the privacy policy", linking the **website ToU** (`/legal/terms`) rather than the MCA; the MCA nonetheless binds on first use by its own acceptance clause. | documented (link target) / implied (which document a signup click "accepts") | https://console.typesafe.ai/login | 2026-09-23 | curl 200; href grep shows only `/legal/terms` and `/legal/privacy-policy`; sentence present in page text | Link targets documented; the legal effect is my inference — flag for the fact-checker |
| 4 | **Output ownership:** TypeSafe "disclaims ownership of Output" and "hereby assigns to Customer all of its right, title, and interest, if any, in the Output"; Customer retains IP in Input. | documented | https://typesafe.ai/legal/mca §4.2, §11 | 2026-09-23 | grep of the §4.2 sentence = 2 | Documented (note the "if any" hedge and §9.3: Output "MAY NOT BE UNIQUE" and other users may receive identical Output) |
| 5 | **Licence grant:** a limited, non-exclusive, non-transferable, non-sublicensable licence for the Term to use the Services per the Documentation and to "integrate the API with one or more Customer Applications" operated by Customer for its End Users. | documented | https://typesafe.ai/legal/mca §2.1–2.2 | 2026-09-23 | grep §2.1(b) = 2; §2.2 sub-quote = 2 | Documented |
| 6 | **Automation / agents:** the MCA contains **no** restriction on automated, programmatic, or AI-agent use of the API; the only "agent" hits are "agents or contractors" (legal sense). The ToU's anti-bot clause (§3(b)(vi): "robots," "spiders," "scrapers") applies to the **website**, not the API. Console (Web Interface) access is limited to Customer's employees/contractors. | documented (absence rests on the full MCA text, not a product page) | https://typesafe.ai/legal/mca §2.3, §2.4; https://typesafe.ai/legal/terms §3(b)(vi) | 2026-09-23 | full MCA read; grep -ic "automat" mca.txt = 1 (§8.2 "automatic Purchased Credit refills" only); "acceptable use" = 0 across all legal pages | Documented — do **not** report an API automation ban; do report the ToU's site-scraping clause with its Site scope |
| 7 | **Resale:** Customer may not "sell, lease, loan, distribute, sublicense, disclose, or otherwise offer or make the Services available as a standalone service"; embedding the API inside a Customer Application for End Users is expressly licensed. | documented | https://typesafe.ai/legal/mca §2.3(a), §2.2 | 2026-09-23 | grep §2.3(a) = 2 | Documented (a *standalone* resale ban, not a ban on white-labelled/embedded use) |
| 8 | **Competing-model / distillation:** Customer may not "use the Services or any Output ... to perform model distillation, train a model to imitate the output of the Services, or develop (or to facilitate the development of) a similar or competing product or service." | documented | https://typesafe.ai/legal/mca §2.3(b) | 2026-09-23 | grep = 2 | Documented |
| 9 | **Reverse engineering & security testing:** prohibited to "reverse engineer, decompile, disassemble, or attempt to access or derive the source code or underlying data", to circumvent access controls, or to "conduct any security or vulnerability test" against the Services. | documented | https://typesafe.ai/legal/mca §2.3(c), (g) | 2026-09-23 | grep = 2 each | Documented (the no-pentest clause is easy to miss) |
| 10 | **High-risk uses:** neither the MCA, ToU, DPA, nor Privacy Policy names any prohibited high-risk domain (medical, legal, weapons, etc.); the only limits are lawful use, third-party rights, export/ITAR (§16.12), and the Usage Limits in the Order. | documented (absence) | https://typesafe.ai/legal/mca §2.3(l), §16.12 | 2026-09-23 | grep -ic "high[- ]risk" = 0 on all four legal pages; docs hits are use-case copy ("Escalate high-risk or uncertain findings to counsel") | Documented absence; do not accuse the terms of a high-risk ban they lack |
| 11 | **Acceptable-use policy:** no AUP page exists (`/aup`, `/acceptable-use`, `/legal` 404; 0 hits for "acceptable use"/"usage policy" in legal pages and the full docs dump); §2.3 of the MCA is the operative restriction list. | documented (absence; searched sitemap, docs nav, footer, console links) | https://typesafe.ai/sitemap.xml ; https://docs.typesafe.ai/llms.txt | 2026-09-23 | sitemap lists exactly four `/legal/*` pages; docs legal index lists DPA/MCA/Privacy only | Documented absence (rule 1: showed the sitemap query that *does* return the legal pages) |
| 12 | **Governing law (service):** California law; courts of the City and County of San Francisco; disputes go to **binding JAMS arbitration** (consumer rules for individuals, Comprehensive Rules for businesses), class-action waiver, Federal Arbitration Act; the MCA's §15 has **no opt-out** clause (the ToU's §12(c) does offer a 30-day opt-out). | documented | https://typesafe.ai/legal/mca §15, §16.2 | 2026-09-23 | grep = 2 each; §15.1–15.8 read in full, no "Opt-Out" heading | Documented |
| 13 | **Governing law (website ToU):** Delaware law and courts; JAMS consumer-rules arbitration with a 30-day mail opt-out; "The Site is intended for visitors located within the United States." | documented | https://typesafe.ai/legal/terms §12–13 | 2026-09-23 | grep = 2 each | Documented (note the Delaware-vs-California split between the two documents) |
| 14 | **Liability cap (service):** each party's aggregate liability capped at the greater of fees paid/payable in the prior 12 months or **$50 USD**, with a consequential-damages waiver; Customer's breaches of §2.3/§2.4/§5, non-payment, and indemnity payments are uncapped "Excluded Claims". | documented | https://typesafe.ai/legal/mca §12 | 2026-09-23 | grep of cap sentence = 2 | Documented |
| 15 | **Liability cap (website ToU):** aggregate liability "IS LIMITED TO $100 USD". | documented | https://typesafe.ai/legal/terms §11(b) | 2026-09-23 | grep = 2 | Documented |
| 16 | **Warranty / output accuracy:** the only warranty is that Services "perform materially as described in its Documentation"; Customer acknowledges "THE SERVICES MAY PRODUCE INACCURATE OR ERRONEOUS OUTPUT" and "IS RESPONSIBLE FOR INDEPENDENTLY EVALUATING THE OUTPUT". TypeSafe's IP indemnity expressly excludes Output (§13.5(e)). | documented | https://typesafe.ai/legal/mca §9.1, §9.3, §13.5 | 2026-09-23 | grep = 2 each | Documented (contradicts nothing, but tempers the marketing "no hallucinations" claim in contract terms) |
| 17 | **Termination:** either party may terminate for uncured material breach after 30 days' notice; TypeSafe may **suspend immediately** for §2.3/§2.4/§5 breaches, 30-day-overdue payment, legal change, or risk to the platform; on termination no refund of unconsumed prepaid amounts; TypeSafe may delete Customer Data at any time; Purchased Credits expire at the earlier of end of Term or 12 months. | documented | https://typesafe.ai/legal/mca §6, §8.2(a), §10 | 2026-09-23 | grep = 2 each | Documented |
| 18 | **Unilateral amendment:** TypeSafe may update the MCA on notice, effective "at least 60 days after" notice; Customer purchase-order terms are "expressly rejected". | documented | https://typesafe.ai/legal/mca §16.7 | 2026-09-23 | grep = 2 | Documented |
| 19 | **Training on customer data:** MCA — TypeSafe "will not, include Customer Data in a dataset used to train (i.e., to modify the model weights of) any artificial intelligence or machine learning models without Customer's prior consent"; Privacy Policy — "We will not train or fine tune any artificial intelligence or machine learning models on your prompts or other Input." Telemetry (logs, hashes, statistics, "learnings") may be processed "without restriction". | documented | https://typesafe.ai/legal/mca §4.1, §4.3 ; https://typesafe.ai/legal/privacy-policy | 2026-09-23 | grep = 2 (MCA); privacy text lines 21 and 42 | Documented (the Telemetry carve-out is the caveat) |
| 20 | **Publicity:** TypeSafe may use Customer's name/logo as a customer reference on its website/PR until Customer requests otherwise in writing. | documented | https://typesafe.ai/legal/mca §16.4 | 2026-09-23 | grep = 2 | Documented |
| 21 | **SDK licence:** the official SDKs are **MIT-licensed** and public — `@typesafe-ai/sdk` 0.6.0 on npm (`"license":"MIT"`, repo `typesafe-ai/typesafe-sdk-js`, LICENSE "Copyright (c) 2026 TypeSafe"), `typesafe-sdk` 0.7.1 on PyPI (`license_expression: MIT`, repo `typesafe-ai/typesafe-sdk-python`), and the `typesafe-ai/skills` agent-skill repo (MIT, "Copyright (c) 2026 TypeSafe AI"). The service itself is not open source; MIT covers client code only. | documented | https://github.com/typesafe-ai/typesafe-sdk-js ; https://github.com/typesafe-ai/typesafe-sdk-python ; https://github.com/typesafe-ai/skills ; https://registry.npmjs.org/@typesafe-ai/sdk ; https://pypi.org/pypi/typesafe-sdk/json | 2026-09-23 | GitHub API `license.spdx_id` = MIT on all three; raw LICENSE files fetched (200); npm/PyPI JSON fields grepped | Documented |
| 22 | The Python SDK's `LICENSE` file still carries the unfilled GitHub template line `Copyright (c) [year] [fullname]` (the MIT grant text is otherwise intact; PyPI metadata says MIT). | documented | https://raw.githubusercontent.com/typesafe-ai/typesafe-sdk-python/main/LICENSE | 2026-09-23 | grep -c -F "Copyright (c) [year] [fullname]" = 1 | Documented (cosmetic defect; does not change the MIT grant, but a compliance reviewer may flag it) |
| 23 | **DPA:** a public Data Processing Addendum (last updated Apr 24, 2026) is incorporated into the MCA by reference; Customer is controller, TypeSafe processor; EU SCCs Module 2/3 + UK Addendum; 72-hour breach notice; annual audit right; subprocessor list at trust.typesafe.ai/subprocessors. Docs say zero data retention is offered to enterprise customers via privacy@typesafe.ai. | documented | https://typesafe.ai/legal/data-processing ; https://docs.typesafe.ai/legal | 2026-09-23 | curl 200; text read in full; docs quote grep = 1 | Documented (retention *period* is "as long as necessary" — no fixed number is published) |
| 24 | **Effective dates:** ToU and MCA "Last updated Sep 19, 2026"; DPA "Apr 24, 2026"; Privacy Policy "Nov 19, 2025". No version history or changelog for legal documents is published. | documented / unknown (history) | the four `/legal/*` pages | 2026-09-23 | "Last updated" grep on each page | Documented dates; prior versions unknown |

## Verbatim evidence quotes

Each quote was verified with `grep -c -F -- '<quote>' <raw-html-file>` against the raw HTML fetched from the cited URL on 2026-09-23 (the site is Framer-rendered and inlines every legal page twice, hence counts of 2). Where a sentence straddles an HTML tag (defined terms are wrapped in `<strong>`; the DPA URL is an `<a>`), the tag-free sub-sentence is quoted and its own count given.

**https://typesafe.ai/legal/terms (website Terms of Use)**
- "Sep 19, 2026" — count 2 (preceded by "Last updated", count 1)
- "If you enter into a separate agreement with TypeSafe for the use of any TypeSafe products or services, including products or services offered through the Site, the terms of that separate agreement will govern your access to and use of those products and service." — count 2
- "(vi) use, or permit or facilitate others to use, the Site by automated electronic processes, “robots,” “spiders,” “scrapers,” “webcrawlers,” or other computer programs that monitor, copy, or download data or other content found on or accessed through the Site, whether current or archival." — count 2
- "IS LIMITED TO $100 USD." — count 2 (must be single-quoted in the shell; my first double-quoted grep expanded `$1` and returned 0 — a false miss, corrected)
- "will be administered by the JAMS under the rules applicable to consumer disputes" — count 2
- "These Terms are governed by the laws of the state of Delaware without regard to conflict of law principles" — count 2
- "The Site is intended for visitors located within the United States." — count 2

**https://typesafe.ai/legal/mca (Master Customer Agreement)**
- "Sep 19, 2026" — count 2
- "the TypeSafe-hosted application programming interface made available by TypeSafe to Customer" — count 2 (§1; the full sentence straddles `<strong>` tags around "Web Interface"/"API"/"Services")
- "(b) integrate the API with one or more Customer Applications in accordance with Section 2.2 (Customer Applications)." — count 2
- "includes the right to include the API into one or more software applications developed and operated by Customer for the benefit of Customer" — count 2 (§2.2; continues "’s end users (“End Users”)" across a `<strong>` tag)
- "(a) sell, lease, loan, distribute, sublicense, disclose, or otherwise offer or make the Services available as a standalone service; (b) use the Services or any Output (defined below) to perform model distillation, train a model to imitate the output of the Services, or develop (or to facilitate the development of) a similar or competing product or service; (c) reverse engineer, decompile, disassemble, or attempt to access or derive the source code or underlying data with respect to the Services" — count 2
- "or conduct any security or vulnerability test with respect to any of the foregoing" — count 2
- "(j) exceed any Usage Limits" — count 2
- "Customer will not authorize or enable any person or entity who is not an employee or independent contractor of Customer" — count 2 (§2.4; continues "(“Customer User”) to access or use the Web Interface." across `<strong>` tags)
- "The foregoing license does not grant TypeSafe the right to, and TypeSafe will not, include Customer Data in a dataset used to train (i.e., to modify the model weights of) any artificial intelligence or machine learning models without Customer’s prior consent." — count 2
- "As between Customer and TypeSafe and to the extent permitted by Laws, TypeSafe does not claim ownership of Input and TypeSafe disclaims ownership of Output. TypeSafe hereby assigns to Customer all of its right, title, and interest, if any, in the Output." — count 2
- "TypeSafe may Process Telemetry without restriction, including to improve the Services or TypeSafe’s other products and services." — count 2
- "The terms of the Data Processing Agreement currently available at" — count 2 (§4.4; the URL `https://typesafe.ai/data-processing` follows inside an `<a>` tag; that URL 301s to `/legal/data-processing`, 200)
- "(I) THE SERVICES MAY PRODUCE INACCURATE OR ERRONEOUS OUTPUT; (II) CUSTOMER IS RESPONSIBLE FOR INDEPENDENTLY EVALUATING THE OUTPUT" — count 2
- "Either Party may terminate this Agreement and the Order if the other Party: (a) fails to cure a material breach of this Agreement (including a failure to pay Fees, or any violation of Section 2.3 (License Restrictions) or Section 2.4 (Access Credentials; Customer Users)) within 30 days after notice" — count 2
- "TypeSafe will have no obligation to provide any compensation or refund for any prepaid amounts not consumed as of the effective date of such termination or expiration" — count 2
- "Purchased Credits expire on the earlier of (y) the end of the Term and (z) the date that is 12 months after the purchase date" — count 2
- "Late Fees are subject to a service charge of 1.5% per month" — count 2
- "THE GREATER OF (A) THE AMOUNTS PAID OR PAYABLE BY CUSTOMER TO TYPESAFE PURSUANT TO THIS AGREEMENT DURING THE 12 MONTHS PRIOR TO THE DATE ON WHICH THE APPLICABLE CLAIM GIVING RISE TO THE LIABILITY AROSE UNDER THIS AGREEMENT AND (B) $50 USD." — count 2 (single-quoted grep)
- "TypeSafe’s obligations in this Section 13 (Indemnification) do not apply:" — count 2; "or (e) Output." — count 2
- "(b) if Customer is a business, then under the JAMS Comprehensive Arbitration Rules and Procedures" — count 2
- "This Agreement is governed by the laws of the State of California and the United States without regard to conflicts of laws provisions" — count 2
- "will be the state and United States federal courts located in The City and County of San Francisco, California" — count 2
- "such updated version of this Agreement will become effective on a going forward basis on the date that is at least 60 days after the date on which TypeSafe provided such notice to Customer." — count 2
- "TypeSafe may use the name, brand, or logo of Customer (or Customer’s parent company) for the purpose of identifying Customer as a licensee or customer on TypeSafe’s website" — count 2
- "(c) will not submit to the Services any information controlled under the U.S. International Traffic in Arms Regulations." — count 2

**https://typesafe.ai/legal/privacy-policy**
- "We will not train or fine tune any artificial intelligence or machine learning models on your prompts or other Input." — count 2 (raw HTML); "Nov 19, 2025" — count 2

**https://docs.typesafe.ai/legal.md**
- "Master Customer Agreement](https://typesafe.ai/legal/mca) — the general terms that apply to your TypeSafe account." — count 1
- "We also offer zero data retention (ZDR) for enterprise customers." — count 1

**https://console.typesafe.ai/login (logged-out page)**
- "By continuing, you agree to the" — count 1 in raw HTML, followed by `<a href="https://typesafe.ai/legal/terms">terms of use</a>` and `<a href="https://typesafe.ai/legal/privacy-policy">privacy policy</a>` (the sentence is split across two anchor tags, so the text-extracted form "By continuing, you agree to the terms of use and the privacy policy" is a reconstruction); `href` grep yields exactly those two legal URLs

**SDK licences**
- https://raw.githubusercontent.com/typesafe-ai/typesafe-sdk-js/main/LICENSE — "MIT License" count 1; "Copyright (c) 2026 TypeSafe" count 1
- https://raw.githubusercontent.com/typesafe-ai/typesafe-sdk-python/main/LICENSE — "MIT License" present; "Copyright (c) [year] [fullname]" count 1
- https://raw.githubusercontent.com/typesafe-ai/skills/main/LICENSE — "Copyright (c) 2026 TypeSafe AI" count 1
- https://registry.npmjs.org/@typesafe-ai/sdk — `"license":"MIT"` count 1 (version 0.6.0, published 2026-09-15T18:17:19Z)
- https://pypi.org/pypi/typesafe-sdk/json — `"license_expression":"MIT"` count 1; `License :: OSI Approved :: MIT License` count 1 (version 0.7.1)

## Scope cautions for the fact-checker (errors in both directions)

- The ToU anti-automation clause is **Site-scoped**; do not let it be rolled up as "TypeSafe forbids automated/agent use of the API". The MCA licenses API integration into Customer Applications and contains no agent/automation restriction.
- "Resale prohibited" is accurate only as "as a standalone service"; embedding is licensed.
- "Customer owns Output" is what the MCA says, with the hedge "if any" and the §9.3 non-uniqueness caveat — quote both.
- The no-training commitment is real (MCA §4.1 + Privacy Policy) — do not understate it; the Telemetry carve-out is the accurate caveat.
- The `$50` floor / 12-month-fees cap and the `$100` ToU cap are two different documents; do not merge them.

## What I could not settle

1. **What the Order says** (Usage Limits, term length, credit rate table, any negotiated deviations) — the MCA defers all of these to the Order/checkout page. *Settled by:* an account (checkout page) or a sales quote (email sales@typesafe.ai).
2. **Whether the in-console click-through accepts the MCA or only the ToU** — the logged-out login page links only `/legal/terms`; the post-login checkout may present the MCA. *Settled by:* an account (view signup/checkout flow).
3. **Promotional-credit terms** ("subject to any additional terms made available … at the time of issuance") — not public. *Settled by:* an account.
4. **Zero-data-retention terms and default retention period** — docs say ZDR exists for enterprise; the DPA gives no fixed retention number. *Settled by:* email privacy@typesafe.ai.
5. **Prior versions of the legal documents** — only "Last updated" dates are shown; no changelog. *Settled by:* email support@typesafe.ai or the Wayback Machine (not fetched; outside the first-party scope I used).
6. **Enterprise / separate written agreements** — the MCA acknowledges a "SEPARATE AGREEMENT" path; its terms are unknown. *Settled by:* sales contact.
