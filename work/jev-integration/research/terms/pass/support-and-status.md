# Q7 — Support / SLA / status page (cluster: terms → support-and-status)

- **Cluster:** `terms` / `support-and-status`
- **Date checked:** 2026-09-23
- **Method:** public pages only via `curl -sL` (UA Mozilla/5.0) + `dig`; raw HTML saved to scratchpad `q7/`; visible text extracted with a Python HTMLParser (scripts/styles stripped). One WebSearch spent. No accounts, keys or API calls. Console opened only at its logged-out `/login` page.
- **Rule-1 evidence of a working query:** the same `curl` harness returned 200 + full HTML for typesafe.ai, docs.typesafe.ai and status.typesafe.ai, so 404/NXDOMAIN results below are real outcomes, not tooling failures.

## URLs fetched (HTTP status / DNS)

| URL | Result |
|---|---|
| https://typesafe.ai/ | 200 (590 KB) |
| https://typesafe.ai/blog/introducing-system-one-models-and-jev | 200 |
| https://typesafe.ai/sitemap.xml | 200 — 13 URLs: /, /team, /manifesto, /blog, 5 posts, /legal/{data-processing,mca,privacy-policy,terms}. **No /status, /support, /contact, /sla, /changelog, /pricing entries.** |
| https://typesafe.ai/robots.txt | 200 (Allow: /) |
| https://typesafe.ai/llms.txt, /llms-full.txt | 404 |
| https://typesafe.ai/status, /support, /contact, /sla, /changelog, /pricing, /security, /enterprise, /legal, /legal/sla, /.well-known/security.txt, /security.txt | all 404 |
| https://typesafe.ai/legal/terms, /legal/mca, /legal/data-processing, /legal/privacy-policy, /team, /blog, /manifesto | all 200 |
| https://docs.typesafe.ai/ | 200 → redirects to /introduction |
| https://docs.typesafe.ai/sitemap.xml | 200 — 118 URLs; **no status/support/contact/sla page**; changelogs at /sdk/python/changelog and /sdk/javascript/changelog |
| https://docs.typesafe.ai/robots.txt, /llms.txt (16 KB), /llms-full.txt (910 KB) | 200 |
| https://docs.typesafe.ai/status, /support, /changelog, /contact, /sla, /pricing, /rate-limits, /security, /.well-known/security.txt | all 404 |
| https://docs.typesafe.ai/legal.md, /api.md, /models.md, /introduction.md, /sdk/python/changelog.md, /sdk/javascript/changelog.md, /model-jaggedness/jev-1.13.md, /agent-skill.md | all 200 |
| **https://status.typesafe.ai/** | **DNS CNAME → `statuspage.betteruptime.com.`; HTTP 200** (Better Stack hosted status page) |
| https://status.typesafe.ai/incidents, /maintenance | 200; /history → redirects to / |
| https://typesafe.statuspage.io, https://typesafeai.statuspage.io | 200 but redirect to atlassian.com/software/statuspage (no such page) |
| https://typesafe.instatus.com, typesafe-ai.instatus.com, typesafeai.instatus.com | 200 but redirect to instatus.com (no such page) |
| https://typesafe.betteruptime.com, typesafeai.betteruptime.com | 200 but redirect to betterstack.com/uptime (no such page) |
| https://typesafe.betterstack.com, status.typesafe.io, uptime.typesafe.ai, health.typesafe.ai, support.typesafe.ai, help.typesafe.ai, community.typesafe.ai, app.typesafe.ai | NXDOMAIN (no A/CNAME) |
| https://api.typesafe.ai/ , /status | 404; /health → 405 |
| https://console.typesafe.ai (→ /login), /login, /signup (→ /login?returnTo=%2Fsignup) | 200; logged-out page links only to typesafe.ai/legal/privacy-policy and /legal/terms (Stytch auth) — no help/support/status link |
| https://github.com/typesafe-ai | 200; org profile links website https://typesafe.ai/, @typesafeai on X, linkedin.com/company/typesafe-ai — confirmed first-party org |
| https://github.com/typesafe-ai/{typesafe-sdk-python,typesafe-sdk-js,skills,system-one-adapter-python} and their /issues | 200; Issues tab enabled with counts 7 / 12 / 12 / 1 |
| https://github.com/typesafeai | 200 — "TypeSafe Community" org; relation to typesafe.ai not established (not linked from any first-party page) |
| https://discord.gg/typesafe → discord.com/invite/typesafe | 200, og:title "Join the TypeSafe AI Discord Server!" |
| https://discord.com/invite/WUujKYBp8s | 200, same server; og:description "The home of Jev, the first public System One model \| 106844 members" |
| https://piehost.com/status/typesafe.ai (third-party mirror surfaced by search) | 200; served HTML carries no uptime figure (JS-rendered); not adopted |

## Findings

| # | Claim (one sentence) | Verdict | Source URL | Date checked | How verified | Documented vs. implied |
|---|---|---|---|---|---|---|
| 1 | TypeSafe operates a public status page at https://status.typesafe.ai hosted on Better Stack ("Powered by" footer; CNAME statuspage.betteruptime.com), with two monitored services: "api.typesafe.ai — TypeSafe API Availability" and "console.typesafe.ai — TypeSafe developer console". | documented | https://status.typesafe.ai/ | 2026-09-23 | dig CNAME + curl 200; text extraction; quotes Q1–Q5 | Documented on the status page itself; **not linked from typesafe.ai, docs.typesafe.ai, the console login page, or the four legal pages** (grep `status.typesafe` = 0 hits in all of them), so discoverability is implied only via search. |
| 2 | The status page shows a 90-day availability figure of **99.839% uptime** for the API and **99.988%** for the console (as of Sep 23, 2026, "All services are online"), with the API showing many short "Down for N minutes" days in late Jun–Jul 2026 (2–20 min each). | documented (observational, not a commitment) | https://status.typesafe.ai/ | 2026-09-23 | quotes Q2–Q4, Q6; day-cells span Jun 26–Sep 20 2026; axis label "90 days ago" | Documented as measured history; it is **not** an SLA target. A third-party mirror's "100%" figure (search snippet for piehost.com) could not be verified in its served HTML and is not adopted. |
| 3 | There is **no published uptime SLA** (no percentage target, no service credits) anywhere on typesafe.ai, docs.typesafe.ai or the Master Customer Agreement; the MCA instead gives a "Service Warranty" (perform materially as described in Documentation) whose remedy is reasonable-efforts correction within 30 days, else termination + refund of pre-paid unused fees, and expressly disclaims uninterrupted/error-free service. | documented (absence rests on the MCA text, the sitemaps, and 404s on /sla, /legal/sla, docs /sla) | https://typesafe.ai/legal/mca | 2026-09-23 | word-boundary grep `\bSLAs?\b`, `uptime`, `service credit`, `Service Level` = 0 across home, launch, docs index, llms-full (910 KB), terms, MCA, DPA, privacy, team, manifesto, blog, console login; quotes Q8–Q10 | Documented: the MCA's warranty/disclaimer language is the operative commitment. Enterprise/custom plans exist ("Higher limits are available on custom and enterprise plans") but any SLA under an Order is unpublished → unknown. |
| 4 | Support channel: the MCA §3 "Support" clause commits to "commercially reasonable efforts … in accordance with its standard support policies" and names **support@typesafe.ai** as the way to request Support; the Terms of Use also give support@typesafe.ai plus a postal address (255 California St, Suite 1300, San Francisco, CA 94117). The docs site's Mintlify AI-assistant config sets a "deflection" email of support@typesafe.ai. | documented | https://typesafe.ai/legal/mca ; https://typesafe.ai/legal/terms ; https://docs.typesafe.ai/ | 2026-09-23 | quotes Q7, Q11, Q12, Q19 | Documented channel; the "standard support policies" themselves are not published anywhere found (grep "support polic" only in the MCA sentence). |
| 5 | Community channels: a TypeSafe AI Discord server (invite https://discord.gg/typesafe in the docs navbar; https://discord.com/invite/WUujKYBp8s on the jev-1.13 jaggedness page — "Reach us on Discord"), GitHub org https://github.com/typesafe-ai (SDK repos have Issues enabled: python 7, js 12, skills 12, adapter 1), X @typesafeai, LinkedIn company/typesafe-ai. No Slack community, no in-console chat, no community forum found (community.typesafe.ai NXDOMAIN; "slack" hits are only Better Stack asset names on the status page). | documented | https://docs.typesafe.ai/ ; https://docs.typesafe.ai/model-jaggedness/jev-1.13 ; https://github.com/typesafe-ai | 2026-09-23 | quotes Q13–Q17; GitHub issue-tab counters | Discord/GitHub/X documented as links; whether Discord is an *official support* channel (vs. community) is implied only — the jaggedness page invites failure reports there. |
| 6 | Contact addresses published: **support@typesafe.ai** (MCA, Terms), **sales@typesafe.ai** (MCA notices clause; docs/models for higher rate limits on custom/enterprise plans), **privacy@typesafe.ai** (Privacy Policy; docs Legal page for ZDR), **hello@typesafe.ai** (site footer on home/team/legal pages). **No security@typesafe.ai** and no security.txt (404 on both hosts). | documented | https://typesafe.ai/legal/mca ; https://docs.typesafe.ai/models ; https://typesafe.ai/legal/privacy-policy ; https://docs.typesafe.ai/legal ; https://typesafe.ai/ | 2026-09-23 | email regex across all 40+ saved pages; quotes Q11, Q12, Q18, Q20–Q23 | Documented. |
| 7 | **No support response-time commitment** is published (no "business day", "respond within", first-response or severity tiers in MCA/Terms/DPA/docs); the only timed commitment found is the DPA's security-incident notification "without undue delay and in any case within 72 hours". No enterprise support tiers (premium/priority support) are described anywhere. | documented absence (legal pages) / unknown for enterprise Orders | https://typesafe.ai/legal/data-processing ; https://typesafe.ai/legal/mca | 2026-09-23 | grep `business days?\|[0-9]+ hours\|respond within\|response within\|premium support\|priority support\|support tier` on mca/terms/dpa/docs_models; quote Q24 | Absence documented for public terms; enterprise Order terms unknown. |
| 8 | Changelog / incident history: the docs publish **SDK changelogs** only (Python SDK v0.5.7 2026-09-14 → v0.7.1 2026-09-21; JS SDK v0.5.7 2026-09-11 → v0.6.0 2026-09-15); there is **no product/API/model changelog** page (docs /changelog and typesafe.ai/changelog 404; the models page carries a "Jev 1.13 jaggedness" known-issues list instead). Incident history lives on the status page: two resolved incidents — Sep 20 2026 "Console is unavailable." and Sep 21 2026 "API issues" — with "No incidents reported" for July and August 2026 and no scheduled maintenance. | documented | https://docs.typesafe.ai/sdk/python/changelog ; https://docs.typesafe.ai/sdk/javascript/changelog ; https://status.typesafe.ai/incidents ; https://status.typesafe.ai/maintenance | 2026-09-23 | quotes Q25–Q28, Q29–Q32 | Documented. Note the count spread (rule 6): the status page's day-strip shows many "Down for N minutes" days in Jun–Jul 2026 while the incidents page says "No incidents reported" for July — i.e. monitor-detected downtime was not written up as incidents. |

## Verbatim evidence quotes

Each quote was confirmed with `/usr/bin/grep -cF '<quote>' <saved raw HTML>` (count shown). Saved files are in scratchpad `q7/`.

| ID | Quote (verbatim) | URL | grep count |
|---|---|---|---|
| Q1 | `Typesafe AI status` | https://status.typesafe.ai/ | 5 (status.html) |
| Q2 | `All services are online` | https://status.typesafe.ai/ | 1 |
| Q3 | `TypeSafe API Availability` / `99.839% uptime` | https://status.typesafe.ai/ | 1 / 1 |
| Q4 | `TypeSafe developer console` / `99.988% uptime` | https://status.typesafe.ai/ | 1 / 1 |
| Q5 | `Powered by` (Better Stack footer) — plus DNS: `dig +short status.typesafe.ai CNAME` → `statuspage.betteruptime.com.` | https://status.typesafe.ai/ | 1 |
| Q6 | `90 days ago` (time-axis label) | https://status.typesafe.ai/ | 2 |
| Q7 | `TypeSafe will use commercially reasonable efforts to support the Services in accordance with its standard support policies` | https://typesafe.ai/legal/mca | 2 (rendered + Framer JSON) |
| Q8 | `TypeSafe warrants to Customer that the Services will perform materially as described in its Documentation` | https://typesafe.ai/legal/mca | 2 |
| Q9 | `TYPESAFE DOES NOT WARRANT THAT CUSTOMER’S USE OF THE SERVICES WILL BE UNINTERRUPTED OR ERROR-FREE` | https://typesafe.ai/legal/mca | 2 |
| Q10 | (rendered §9.2) "If TypeSafe cannot do so within 30 days of receipt of Customer’s warranty claim, either Party may terminate the Agreement without penalty and TypeSafe will then refund to Customer any pre-paid, unused" — from extracted text mca.txt; raw check: `grep -cF 'within 30 days of receipt of Customer’s warranty claim' mca.html` → 2 | https://typesafe.ai/legal/mca | see left |
| Q11 | Rendered: "Customer may email TypeSafe at support@typesafe.ai to request Support." — the address is an `<a>`; raw fragment `Customer may email TypeSafe at <!--$--><a class="framer-text framer-styles-preset-1ju9u6a" href="mailto:support@typesafe.ai" rel>support@typesafe.ai</a><!--/$--> to request Support.` | https://typesafe.ai/legal/mca | 1 |
| Q12 | Rendered (Terms): "You may contact us by sending correspondence to that address or by emailing us at support@typesafe.ai." — raw fragment `by emailing us at <!--$--><a … href="mailto:support@typesafe.ai" rel>support@typesafe.ai</a>`; and `255 California St, Suite 1300, San Francisco, CA 94117` | https://typesafe.ai/legal/terms | 1 / 2 |
| Q13 | `href="https://discord.gg/typesafe"` (docs navbar) | https://docs.typesafe.ai/ | 1 |
| Q14 | `href="https://github.com/typesafe-ai"` (docs navbar) | https://docs.typesafe.ai/ | 1 |
| Q15 | `href="https://x.com/typesafeai"` (docs navbar) | https://docs.typesafe.ai/ | 1 |
| Q16 | `Found a failure mode that belongs on this list? We want to hear about it. Reach us on [Discord](https://discord.com/invite/WUujKYBp8s).` | https://docs.typesafe.ai/model-jaggedness/jev-1.13.md | 1 |
| Q17 | `Join the TypeSafe AI Discord Server!` (og:title) / `The home of Jev, the first public System One model \| 106844 members` (og:description) | https://discord.com/invite/typesafe ; https://discord.com/invite/WUujKYBp8s | 2 / 3 |
| Q18 | `Higher limits are available on custom and enterprise plans. Contact [sales@typesafe.ai](mailto:sales@typesafe.ai).` | https://docs.typesafe.ai/models.md | 1 |
| Q19 | `deflection\":{\"enabled\":true,\"email\":\"support@typesafe.ai\"}` (Mintlify assistantConfig) | https://docs.typesafe.ai/ | 1 |
| Q20 | Rendered (MCA §16 notices): "…sent to 255 California St, Suite 1300, San Francisco, CA 94117 or sales@typesafe.ai if to TypeSafe…" — raw fragment `San Francisco, CA 94117 or <!--$--><a … href="mailto:sales@typesafe.ai" rel>sales@typesafe.ai</a><!--/$--> if to TypeSafe` | https://typesafe.ai/legal/mca | 1 |
| Q21 | Rendered (Privacy): "If you have any questions, comments, or concerns about our processing activities, please email us at privacy@typesafe.ai." — raw fragment `please email us at <!--$--><a … href="mailto:privacy@typesafe.ai" target="_blank" rel>privacy@typesafe.ai</a>` | https://typesafe.ai/legal/privacy-policy | 1 |
| Q22 | `We also offer zero data retention (ZDR) for enterprise customers. Contact [privacy@typesafe.ai](mailto:privacy@typesafe.ai) to learn more.` | https://docs.typesafe.ai/legal.md | 1 |
| Q23 | `hello@typesafe.ai` (footer) | https://typesafe.ai/ | 1 (also 1 each on /team, /legal/terms, /legal/mca, /legal/data-processing, /legal/privacy-policy, /manifesto, launch post) |
| Q24 | `within 72 hours after becoming aware` (DPA §5.2 Security Incident) | https://typesafe.ai/legal/data-processing | 2 |
| Q25 | `v0.7.1 (2026-09-21)` | https://docs.typesafe.ai/sdk/python/changelog.md | 1 |
| Q26 | `This is the initial public release of TypeSafe Python SDK.` (under v0.5.7 (2026-09-14)) | https://docs.typesafe.ai/sdk/python/changelog.md | 1 |
| Q27 | `v0.6.0 (2026-09-15)` | https://docs.typesafe.ai/sdk/javascript/changelog.md | 1 |
| Q28 | `This is the initial public release of TypeSafe JavaScript and TypeScript SDK.` (under v0.5.7 (2026-09-11)) | https://docs.typesafe.ai/sdk/javascript/changelog.md | 1 |
| Q29 | `Console is unavailable.` (Sep 20, 2026 incident title) | https://status.typesafe.ai/incidents | 1 |
| Q30 | `Issues with TypeSafe console and API are fully resolved.` (resolved Sep 21, 2026 at 8:16am UTC) | https://status.typesafe.ai/incidents | 1 |
| Q31 | `We are seeing intermittent downtime and system instability. We are actively investigating.` ("API issues", resolved Sep 21, 2026 at 11:40pm UTC) | https://status.typesafe.ai/incidents | 1 |
| Q32 | `No incidents reported` (August 2026, July 2026) / `No maintenance scheduled` | https://status.typesafe.ai/incidents ; https://status.typesafe.ai/maintenance | 2 / 2 |
| Q33 | `Rate limits are adjusting dynamically.` | https://docs.typesafe.ai/models.md | 1 |

Absence checks (rule 2 — run against the full corpus, not just marketing pages): `\bSLAs?\b`=0, `\buptime\b`=0, `status page`=0, `status\.typesafe`=0 in home, launch, docs index, llms-full.txt (910 KB, the complete docs corpus), terms, MCA, DPA, privacy, team, manifesto, blog, console login. The five `99.x%` hits in llms-full are cookbook accuracy figures ("TypeSafe scored 99.2%"), not uptime. `security@`, `legal@`=0 everywhere. `slack` hits (6) are only Better Stack asset filenames on the status page.

Web search (1 of 3 budget): `"typesafe.ai" SLA OR "enterprise support" OR "status page" Jev TypeSafe` — returned status.typesafe.ai, docs/models, GitHub org, LinkedIn, a liteLLM pass-through doc, and two third-party status mirrors (piehost.com, statusfield.com); nothing about an SLA or support tiers beyond first-party pages.

## What I could not settle

- **Enterprise / custom-plan SLA and support tiers** — the MCA references "standard support policies" and docs reference "custom and enterprise plans", but neither the policies nor any Order-level SLA is published. *Settles with:* an email to sales@typesafe.ai or an enterprise Order Form.
- **Support response times** for support@typesafe.ai (first-response, hours of coverage). *Settles with:* email to support@typesafe.ai, or an account (the logged-in console may show a help/chat widget — not inspected per scope).
- **Whether the console has in-app support/chat or a status banner** — logged-out /login shows only Terms/Privacy links. *Settles with:* an account.
- **Discord as official support vs. community** — it is the docs' "reach us" channel for model failure reports; whether staff triage support there is unstated. *Settles with:* joining the server (no account restriction on the invite page, but joining requires a Discord login — out of scope here).
- **Uptime window semantics** — the 99.839%/99.988% figures sit on a strip labelled "90 days ago … Today"; Better Stack's exact averaging window is not stated on the page. *Settles with:* Better Stack docs or the page owner.
- **Relationship of github.com/typesafeai ("TypeSafe Community")** to typesafe.ai — not linked from any first-party page. *Settles with:* asking TypeSafe.
- **Third-party mirror's "100% uptime" snippet** (piehost) — served HTML had no figure; unverified, not adopted.
