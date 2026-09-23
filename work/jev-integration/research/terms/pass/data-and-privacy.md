# Q4 — Data retention, training on inputs, privacy, hosting, compliance (raw pass)

- Cluster: `terms` / `data-and-privacy` — subject: Jev / TypeSafe AI (typesafe.ai)
- Date checked: 2026-09-23
- Method: `curl -sL` (UA `Mozilla/5.0 (research)`), raw HTML saved to scratchpad; text extracted with an HTML parser; every quote below re-grepped on the raw fetched file (`grep -c -F`). Two web searches spent (of three). No accounts, logins, keys or API calls.
- Public sources only. The console was fetched only at its logged-out `/login` page.

## URLs fetched (HTTP status)

| URL | Status | Note |
|---|---|---|
| https://typesafe.ai/ | 200 | Footer links only `./legal/privacy-policy`, `./legal/terms` |
| https://typesafe.ai/blog/introducing-system-one-models-and-jev | 200 | No data/privacy/compliance wording |
| https://typesafe.ai/sitemap.xml | 200 | Lists `/legal/data-processing`, `/legal/mca`, `/legal/privacy-policy`, `/legal/terms` |
| https://typesafe.ai/robots.txt | 200 | `Allow: /` |
| https://typesafe.ai/llms.txt, /llms-full.txt | 404 | — |
| https://typesafe.ai/privacy → /legal/privacy-policy | 200 (redirect) | Privacy policy, "Last updated Nov 19, 2025" |
| https://typesafe.ai/privacy-policy → /legal/privacy-policy | 200 (redirect) | same |
| https://typesafe.ai/terms, /terms-of-service → /legal/terms | 200 (redirect) | Website Terms of Use, "Last updated Sep 19, 2026" |
| https://typesafe.ai/legal/data-processing | 200 | Data Processing Addendum, "Last updated Apr 24, 2026" |
| https://typesafe.ai/data-processing (URL cited inside the MCA) → /legal/data-processing | 200 (redirect) | resolves |
| https://typesafe.ai/legal/mca | 200 | Master Customer Agreement, "Last updated Sep 19, 2026" |
| https://typesafe.ai/security, /trust, /dpa, /legal | 404 | — |
| https://typesafe.ai/team, /manifesto | 200 | No data/privacy/compliance wording |
| https://docs.typesafe.ai/ → /introduction | 200 | — |
| https://docs.typesafe.ai/sitemap.xml, /robots.txt, /llms.txt, /llms-full.txt | 200 | robots carries `Content-Signal: ai-train=yes, search=yes, ai-input=yes` (about crawling the docs, not customer data) |
| https://docs.typesafe.ai/legal | 200 | Links DPA, MCA, Privacy Policy; ZDR sentence |
| https://docs.typesafe.ai/models | 200 | "Data handling" section |
| https://docs.typesafe.ai/api | 200 | No retention/ZDR/region option or header in the reference (only `x-typesafe-request-id`) |
| https://docs.typesafe.ai/privacy, /security, /data-retention | 404 | — |
| https://console.typesafe.ai/ , /login, /signup → /login | 200 | Logged-out page; footer links only to typesafe.ai privacy-policy and terms |
| https://trust.typesafe.ai/ (also /subprocessors, /resources, /controls, /faq, /sitemap.xml, /robots.txt) | 200 | Vanta-hosted trust center; every path returns the same ~6.9 KB JavaScript shell (title "Typesafe.ai Trust Center"). Same result with a Googlebot UA and via WebFetch. Contents NOT readable without a browser. |
| https://security.typesafe.ai/ | 000 | DNS/connection failure — does not exist |

## Findings

| # | Claim (one sentence) | Verdict | Source URL | Date checked | How verified | Documented vs. implied |
|---|---|---|---|---|---|---|
| 1 | A privacy policy exists at typesafe.ai/legal/privacy-policy, "Last updated Nov 19, 2025", covering the website, the Playground and the APIs. | documented | https://typesafe.ai/legal/privacy-policy | 2026-09-23 | curl 200; grep `Nov 19, 2025` = 2 | Documented (policy) |
| 2 | Training on inputs: the privacy policy states TypeSafe "will not train or fine tune any artificial intelligence or machine learning models on your prompts or other Input" and will not disclose Input to third parties other than service providers. | documented | https://typesafe.ai/legal/privacy-policy | 2026-09-23 | grep quote = 2 (Q2, Q3) | Documented (policy) |
| 3 | Training on inputs (contract): the MCA says TypeSafe "will not, include Customer Data in a dataset used to train (i.e., to modify the model weights of) any artificial intelligence or machine learning models without Customer's prior consent" — note the carve-out "without Customer's prior consent". | documented | https://typesafe.ai/legal/mca | 2026-09-23 | grep quote = 2 (Q12) | Documented (contract) |
| 4 | Training on inputs (docs): the models page says "Jev is not trained on customer requests or responses." | documented | https://docs.typesafe.ai/models | 2026-09-23 | grep on served page and llms-full.txt (Q17) | Documented (docs statement, consistent with #2/#3) |
| 5 | Telemetry carve-out: the MCA grants a perpetual licence over Customer Data "to derive and generate Telemetry" (logs, hashes, summary statistics, classifications, metrics, learnings), which TypeSafe "may Process ... without restriction, including to improve the Services". | documented | https://typesafe.ai/legal/mca | 2026-09-23 | grep quotes = 2 (Q13, Q14) | Documented (contract) — a genuine limit on the "no training" stance: derived telemetry is unrestricted, raw Customer Data is not used to modify weights |
| 6 | Retention (personal data): "for as long as reasonably necessary to provide you with the Services, or otherwise in support of our business or commercial purposes"; deletion on request unless law requires longer. No fixed day count anywhere. | documented | https://typesafe.ai/legal/privacy-policy | 2026-09-23 | grep quote = 2 (Q4); no `[0-9]+ days` retention figure on any first-party page | Documented, but open-ended (no numeric window) |
| 7 | Retention (customer data, contract): TypeSafe "will be under no obligation to store or retain Customer Data and may delete Customer Data at any time in its sole discretion"; Confidential Information "may be retained in TypeSafe's standard backups". DPA Schedule I: retained "for as long as necessary taking into account the purpose of the Processing". | documented | https://typesafe.ai/legal/mca ; https://typesafe.ai/legal/data-processing | 2026-09-23 | grep quotes = 2 each (Q15, Q16, Q8) | Documented (contract) — no retention window, no deletion SLA |
| 8 | Zero data retention: "We also offer zero data retention (ZDR) for enterprise customers. Contact privacy@typesafe.ai to learn more." No self-serve toggle, header, or API option exists in the API reference or SDK docs. | documented (offer) / unknown (terms) | https://docs.typesafe.ai/legal | 2026-09-23 | grep = 1 (Q9); API reference grep for `zero`/`ZDR`/`retention` headers = none besides this sentence | Documented as an enterprise, contact-us offer; mechanics and eligibility undisclosed |
| 9 | Hosting region: "The Services are hosted in the United States"; EEA/UK users transfer data to the U.S. No EU/other-region hosting option is mentioned on any first-party page. | documented | https://typesafe.ai/legal/privacy-policy | 2026-09-23 | grep quote = 2 (Q5) | Documented (policy) |
| 10 | Cloud provider (AWS/GCP/Azure): not named on any first-party page fetched. | unknown | (all pages grepped) | 2026-09-23 | word-boundary grep for AWS / Amazon Web Services / Google Cloud / GCP / Azure = 0 hits | Undisclosed outside the (unreadable) trust center |
| 11 | DPA availability: a public Data Processing Addendum exists (Apr 24, 2026), incorporated by reference into the MCA §4.4; processor role, CCPA no-sell/no-share, 72-hour breach notice, once-per-12-months customer audit right, subprocessor change notice with 15-day objection window. | documented | https://typesafe.ai/legal/data-processing ; https://typesafe.ai/legal/mca | 2026-09-23 | grep quotes = 2 (Q7, Q8, Q10, Q11) | Documented (contract) |
| 12 | GDPR/UK: the DPA concludes EU SCCs Module 2 (and Module 3 where applicable), Irish law/Dublin courts, and the UK Addendum (ICO Version B1.0); supervisory authorities named for EEA (Ireland), UK, Switzerland. | documented | https://typesafe.ai/legal/data-processing | 2026-09-23 | grep `Module 2 (controller-to-processor) of the EU SCCs` = 2, `UK Addendum` = 2 | Documented (contract) — transfer mechanism, not a "GDPR certified" claim |
| 13 | Subprocessors: the DPA points to https://trust.typesafe.ai/subprocessors for the list. That page returns a JS shell to curl/WebFetch, so the list is unread. | documented (pointer) / unknown (contents) | https://typesafe.ai/legal/data-processing → https://trust.typesafe.ai/subprocessors | 2026-09-23 | grep URL = 2 (Q7); trust page fetched 3 ways, all 6.9 KB shell | Pointer documented; list contents need a browser |
| 14 | SOC 2: no SOC 2 claim appears on any first-party page fetched (home, blog, docs, legal, console login). A Vanta trust center exists, which is where such attestations are normally listed. | unknown | https://trust.typesafe.ai/ | 2026-09-23 | grep `SOC 2`/`SOC2` = 0 across 14 first-party files; web search returned only the trust-center landing page | Not claimed in readable text; trust center unreadable |
| 15 | ISO 27001: no mention on any first-party page fetched. | unknown | (all pages grepped) | 2026-09-23 | grep `ISO 27001`/`ISO27001` = 0 | Not claimed in readable text |
| 16 | HIPAA / BAA: no mention on any first-party page fetched; DPA Schedule I lists sensitive data as "N/A". | unknown (no claim found) | (all pages grepped); https://typesafe.ai/legal/data-processing | 2026-09-23 | grep `HIPAA` = 0; `\bBAA\b` = 0 | Not claimed |
| 17 | Security measures: the DPA defers technical/organisational measures to "Typesafe's Trust Center at https://trust.typesafe.ai/"; the privacy policy says "we can make no guarantees as to the security or privacy of your data". No encryption-at-rest/in-transit statement appears in readable first-party text. | documented (deferral) / unknown (measures) | https://typesafe.ai/legal/data-processing ; https://typesafe.ai/legal/privacy-policy | 2026-09-23 | grep `Trust Center at` = 2 (Q18); grep Q6 = 2; grep `encrypt` = 0 on legal/marketing pages | Measures live behind the JS trust center |
| 18 | Data selling / advertising: privacy policy — "We do not "sell" personal data nor "share" personal data for cross-contextual behavioral advertising"; uses Google Analytics. | documented | https://typesafe.ai/legal/privacy-policy | 2026-09-23 | grep quote = 2 (Q19) | Documented (policy) |
| 19 | Website Terms of Use (Sep 19, 2026) state "The Site is intended for visitors located within the United States." | documented | https://typesafe.ai/legal/terms | 2026-09-23 | grep = 2 (Q20) | Documented (site terms; separate from the MCA) |
| 20 | Marketing pages (home, launch post, team, manifesto) make NO data-retention, privacy, hosting or compliance claims at all — every statement above comes from legal or docs pages. | documented (absence in marketing copy) | https://typesafe.ai/ ; launch post | 2026-09-23 | keyword grep on extracted text: only "training"/"RLHF" in the ML sense | n/a |

## Verbatim evidence quotes

Each quote was checked with `grep -c -F '<quote>' <saved raw HTML>` on the file fetched 2026-09-23 (Framer pages render body text twice, hence counts of 2). Where link/strong markup splits a sentence in the raw HTML, the count on the parser-extracted text is also given.

- **Q1** https://typesafe.ai/legal/privacy-policy — `Last updated` / `Nov 19, 2025` — count 2.
- **Q2** https://typesafe.ai/legal/privacy-policy — "We will not train or fine tune any artificial intelligence or machine learning models on your prompts or other Input." — count 2.
- **Q3** https://typesafe.ai/legal/privacy-policy — "We (1) will not train or fine tune any artificial intelligence or machine learning models on Input, and (2) will not disclose any Input to a third party other than our service providers." — count 2.
- **Q4** https://typesafe.ai/legal/privacy-policy — "We retain personal data about you for as long as reasonably necessary to provide you with the Services, or otherwise in support of our business or commercial purposes." — count 2.
- **Q5** https://typesafe.ai/legal/privacy-policy — "The Services are hosted in the United States" — count 2. (Full sentence continues: "(“U.S.”). If you choose to use the Services from the EEA, the UK or other regions of the world with laws governing data collection and use that may differ from U.S. law, then please note that you are transferring your personal data outside of those regions to the U.S. for storage and processing.")
- **Q6** https://typesafe.ai/legal/privacy-policy — "we can make no guarantees as to the security or privacy of your data" — count 2.
- **Q7** https://typesafe.ai/legal/data-processing — "https://trust.typesafe.ai/subprocessors" — count 2. Sentence: "Customer provides general authorization for Typesafe to engage the following subprocessors as described in https://trust.typesafe.ai/subprocessors (“Subprocessors”)."
- **Q8** https://typesafe.ai/legal/data-processing — "Customer Personal Data will be retained for as long as necessary taking into account the purpose of the Processing" — count 2.
- **Q9** https://docs.typesafe.ai/legal — "We also offer zero data retention (ZDR) for enterprise customers." — raw count 1; full sentence with "Contact privacy@typesafe.ai to learn more." count 1 on extracted text (mailto link splits the raw HTML). Also present verbatim in https://docs.typesafe.ai/llms-full.txt (line 12837).
- **Q10** https://typesafe.ai/legal/data-processing — "Typesafe will notify Customer without undue delay and in any case within 72 hours after becoming aware" — count 2.
- **Q11** https://typesafe.ai/legal/data-processing — "no more than once every 12 months, Typesafe will permit Customer to audit" — count 2.
- **Q12** https://typesafe.ai/legal/mca — "TypeSafe will not, include Customer Data in a dataset used to train (i.e., to modify the model weights of) any artificial intelligence or machine learning models without Customer’s prior consent." — count 2.
- **Q13** https://typesafe.ai/legal/mca — "(c) in perpetuity, any Customer Data (i) to derive and generate Telemetry, (ii) to monitor for fraud and abuse of the Services, and (iii) as necessary to comply with applicable Laws." — count 2.
- **Q14** https://typesafe.ai/legal/mca — "TypeSafe may Process Telemetry without restriction, including to improve the Services or TypeSafe’s other products and services." — count 2.
- **Q15** https://typesafe.ai/legal/mca — "TypeSafe will be under no obligation to store or retain Customer Data and may delete Customer Data at any time in its sole discretion." — count 2.
- **Q16** https://typesafe.ai/legal/mca — "Customer Confidential Information may be retained in TypeSafe’s standard backups" — count 2.
- **Q17** https://docs.typesafe.ai/models — "Jev is not trained on customer requests or responses." (under heading "Data handling") — count 2 on the served page raw HTML, 1 on extracted text, 1 in https://docs.typesafe.ai/llms-full.txt (line 13049).
- **Q18** https://typesafe.ai/legal/data-processing — "Trust Center at" (raw count 2); full sentence on extracted text (count 1): "Typesafe will implement security safeguards designed to protect the security, confidentiality and integrity of Personal Data as described on Typesafe’s Trust Center at https://trust.typesafe.ai/."
- **Q19** https://typesafe.ai/legal/privacy-policy — "We do not “sell” personal data nor “share” personal data for cross-contextual behavioral advertising." — count 2.
- **Q20** https://typesafe.ai/legal/terms — "The Site is intended for visitors located within the United States." — count 2.
- **Q21** https://typesafe.ai/legal/mca — "The terms of the Data Processing Agreement currently available at" (raw count 2; full sentence with the URL `https://typesafe.ai/data-processing` count 1 on extracted text; that URL 301s to /legal/data-processing).
- **Q22** https://typesafe.ai/legal/data-processing — "Apr 24, 2026" — count 2. https://typesafe.ai/legal/mca and /legal/terms — "Sep 19, 2026" — count 2 each.
- **Q23** https://typesafe.ai/legal/data-processing — CCPA clause, extracted-text count 1 (raw HTML splits on `<strong>CCPA</strong>`): "Typesafe will not (a) “sell” or “share” (as such terms are defined in the California Consumer Privacy Act (“CCPA”)) Customer Personal Data, (b) retain, use, or disclose Customer Personal Data for any purpose other than in accordance with the Documented Instructions".
- **Q24** https://docs.typesafe.ai/robots.txt — "Content-Signal: ai-train=yes, search=yes, ai-input=yes" — count 1. (Crawler signal about the docs site; unrelated to customer-data training policy — recorded so nobody misreads it as one.)

Negative greps (word-boundary, across the 14 saved first-party files: home, launch post, docs intro, llms-full, privacy, terms, DPA, MCA, docs/legal, models, api, team, manifesto, console login): `HIPAA` 0, `SOC 2`/`SOC2` 0, `ISO 27001`/`ISO27001` 0, `\bBAA\b` 0, `\bAWS\b` 0, `Amazon Web Services` 0, `Google Cloud` 0, `Azure` 0, `encrypt` 0 on legal/marketing pages (only a cookbook feature name `pii_encryption` in the docs corpus).

## What I could not settle

- **Trust center contents (SOC 2 / ISO 27001 / pen-test / encryption / subprocessor list / any FAQ).** https://trust.typesafe.ai/ and its sub-paths serve a Vanta JavaScript shell; data loads client-side from app.vanta.com. Settled by: a browser visit (human eyeball or Chrome tool), no account needed. Possibly gated: Vanta trust centers often require an access request for the report PDFs themselves.
- **ZDR terms** (eligibility, pricing, whether it also removes Telemetry derivation, whether it applies to logs/backups). Settled by: email to privacy@typesafe.ai or sales.
- **Numeric retention window for API request/response payloads and logs** on the standard (non-ZDR) tier. No first-party page states one. Settled by: email or the trust-center FAQ (browser).
- **Cloud provider / physical region** beyond "hosted in the United States". Settled by: trust center (browser) or email.
- **Whether "prior consent" to training (MCA §4.1) is ever solicited in the console signup/settings** (e.g. an opt-in checkbox). Settled by: an account.
- **HIPAA/BAA availability** — no claim found, but absence on public pages is not proof (rule 1); settled by email.

