# Corrections — `terms` (jev-integration wave 1, 2026-09-23)

Applied by: corrections agent (gen 1, task `corr-terms`), 2026-09-23. Rulings R1–R8 from `corrections-brief.md`; evidence in `fact-check.md`. Every number below re-derived by fresh fetch/count on 2026-09-23 before use.

## Progress

### [gen 1] 2026-09-23 — brief, method rules, fact-check, record, profile, verification, open-verification read
- Plan: re-fetch homepage + Framer modules, X posts (public mirrors), console login + chunks, issue #10, docs `/models` and `/api`, launch post; then apply R1–R8 with rule-7 greps; then write the entries.

### [gen 1] 2026-09-23 — evidence re-derived on fresh fetches (all numbers below are mine, not the ruling's); context-budget WARN hit, rolling over before the edit pass
Re-derivation results (curl, 2026-09-23, desktop UA; raw copies were in the gen-1 scratchpad and are NOT durable — gen 2 must re-fetch per the hard rules, using the exact URLs/greps here):
- **X posts (R1, R2)** — re-fetched successfully via two public mirrors, `https://api.fxtwitter.com/typesafeai/status/<id>` and `https://cdn.syndication.twimg.com/tweet-result?id=<id>&token=a` (both HTTP 200, author `typesafeai`): `2101786156572823624`, 2026-09-20 21:30:43 UTC, text "Jev is now available to everyone. No waitlist.\nStart using it here: https://console.typesafe.ai" (3,073,525 views); `2101786280946499671`, 21:31:13 UTC, reply to the first, text "All users start with $5 in credit (~120 million tokens)." (174,622 views). Because the re-fetch succeeded, the brief's "not re-fetched" marker is NOT needed — cite the X posts directly, mirrors named.
- **Homepage (R1, R3, R6)** — `https://typesafe.ai` 200, 590,563 B. Module scripts are referenced as `https://framerusercontent.com/sites/43bTeC8cU9jZO20XvdK79t/<name>.mjs` (21 site modules + `https://framer.com/edit/init.mjs` = 22 scripts; the fact-check's `m1.mjs`/`m6.mjs` names do not match today's build — use the names below). Grep: `grep -oE 'https://framerusercontent\.com/sites/[a-zA-Z0-9/._-]+\.mjs' home.html | sort -u`. All FAQ/banner text is in ONE module, `1bDVrPYMWEZ6eWmJvyMH7WadCbl21tfR2JXCIVJyZRA.BkrK7V15.mjs` (`grep -aoF` counts):
  - `NO MORE WAITLIST` 1; `Sept 20, 2026 • TypeSafe News` 1; `TypeSafe is now open to everyone. Let the Jevolution begin.` 1 (component named `No more waitlist`; the short variant "TypeSafe is now open to everyone" 4 more times for responsive breakpoints); a button component with `data-framer-name` `Sign up` / label `Sign up` exists in the module and `console.typesafe.ai` appears 2× in it — the button→href binding was not traced; say "a 'Sign up' button; console.typesafe.ai is referenced in the same module".
  - FAQ "Are these prices temporary or subsidized?" answer, verbatim: "We can serve Jev profitably at our current prices. Our goal is to make intelligence more affordable over time as we improve the technology." — 1. `production price` 0 in the HTML and in all 21 modules.
  - FAQ "Can Jev still get things wrong?" answer, verbatim: "Yes. Jev guarantees the shape of its answers, not that every decision is correct. If you provide a list of categories, it can’t invent a category outside that list, but it can choose the wrong one. Uncertainty is a feature! You can use Jev’s provided probabilities and confidence to set the threshold for when your software acts automatically and when it needs further review: higher for higher-stakes decisions, lower when errors are less costly." — 2 hits (the second variant says "acts autonomously" instead of "acts automatically"; rule-6 spread, name both).
  - FAQ "What are System One Models? What is Jev?" answer contains "Jev is TypeSafe’s first public System One Model, optimized for automation." — 1 in the module AND 1 in the served homepage HTML (this sentence is server-rendered, unlike the other FAQ answers). Source for R6(c).
  - Stale copy still present: FAQ "How do I get started or ask a question?" answer "Join the waitlist! Jev is in its early days, …" — 2; `form_hero_waitlist` — 3. Record as a rule-6 spread beside the Sep 20 banner.
  - `Join Waitlist` in the served HTML: 2, both `data-framer-name="Join Waitlist"` on a `RichTextContainer` div inside the anchor to `https://jobs.ashbyhq.com/typesafe-ai?utm_source=QLrx0vq4BW`; visible text `>Open roles<` — 2 hits; `Open roles` 2 in HTML. In the modules `Join Waitlist` is 7 (6 in `gDLmHFp7A.CrDe3kZW.mjs` = the button component's default title prop, 1 in the FAQ module). No visible "Join Waitlist" control.
- **Console (R4)** — `https://console.typesafe.ai/login` 200, 45,398 B; `grep -oE '/_next/static/chunks/[^"'"'"' ]+\.js'` → **18** chunks (pass: 26). Concatenated counts: `SELF_SERVE_DISABLED` **6** (pass 12), `signups_disabled` **6** (pass 12), `Email signup is disabled` **1** (pass 2), `You've been invited to join TypeSafe!` **1** (pass 2), `buildSignupsDisabledPath` 2, `buildEmailSignupsDisabledPath` 2. Confirms the fact-check: the pass's counts were exactly doubled. Ruling R4 is consistent with the evidence.
- **Token figure (R2)** — docs `models.md` line 13: `| Price (per Btok / per Mtok) | \$42 / \$0.042 |`. $5 ÷ $0.042 per Mtok = **119.05 M input tokens** → the post's "~120 million tokens" is consistent with the documented price (rounded).
- **Issue #10 (R1, R5)** — `api.github.com/repos/typesafe-ai/skills/issues/10`: `state: open`, created `2026-09-21T23:15:01Z`, updated `2026-09-22T12:10:21Z`, 1 comment, reporter `dashan-qi`; comment 2026-09-22T12:10:20Z (same reporter): "Still reproducible as of **2026-09-22 12:10 UTC** — importantly, on a **newer deployment** than when this issue was filed."; no vendor reply. Issue body: keyless `POST https://api.typesafe.ai/v1/systemone` returns `403 {"error_type":"authentication_error","message":"Must supply an API key!"}`; docs `api.md` line 331 lists `401 Unauthorized` | "Missing or invalid API key. Check the `Authorization` header." → the R5(b) 401-vs-403 open item is supported (third-party, no API call made).
- **Launch post** — `Sep 15, 2026` 3 hits (2 rendered + 1 locale-cache entry; fact-check said 2 — immaterial), `available today in early access` 2, `bringing developers off the waitlist as quickly as we can` 2. Date to add beside 1.5/6.2.
- **Verdict on the rulings so far:** R1–R6 are each consistent with my re-derivation; nothing to refuse. R7/R8 are transcription of `fact-check.md` §Prose and §Patterns (read; no numbers to re-derive beyond the above).

Rule-7 sweep (grep across `record.md`, `profile.md`, `verification.md`, `open-verification.md` for every claim string to be corrected; provenance files excluded). Sites to touch, by file:line:
```
record.md:7:**Standing claims:** S4 figure ("$42 per billion input tokens") **confirmed**; S4 qualifier ("production prices") **contradicted** — appears on no f
record.md:20:| 1.6 | The qualifier "production prices" does not appear on any first-party page (homepage, launch post, docs corpus, Models page, four legal page
record.md:21:| 1.7 | The price qualifiers that do exist: blog "We make our pricing transparent. We can’t prove it isn’t subsidized; we’ll need the long-term to 
record.md:92:| 6.1 | No free tier, trial, or free-credit amount is published anywhere. | unknown | docs sitemap; homepage; MCA | 2026-09-23 | `free tier`/`free 
record.md:93:| 6.2 | Access is "early access" with a waitlist per the launch post ("available today in early access"; "bringing developers off the waitlist as q
record.md:94:| 6.3 | Self-serve signup is implied by the quickstart ("Open the Playground and log in", key from `console.typesafe.ai/keys`) and the Google/email
record.md:98:| 6.7 | Promotional-credit amount, minimum top-up, and accepted payment methods are not published. | unknown | — | 2026-09-23 | no page states them
record.md:108:| 7.5 | Community: TypeSafe AI Discord (docs navbar `discord.gg/typesafe`; jaggedness page "Reach us on Discord"; invite metadata ~106.8k members,
record.md:125:- `Are these prices temporary or subsidized?` — 1 (heading only; no answer body served)
record.md:126:- `Join Waitlist` — 2 (anchor href `https://jobs.ashbyhq.com/typesafe-ai?utm_source=QLrx0vq4BW`)
record.md:127:- `production price` — 0
record.md:132:- `available today in early access` — 2; `bringing developers off the waitlist as quickly as we can` — 2
record.md:133:- `production price` — 0
record.md:174:- Public JS chunks (26, fetched fresh): `SELF_SERVE_DISABLED` — 12; `signups_disabled` — 12; `Email signup is disabled` — 2; `You've been invited 
record.md:196:- Headline from clusters: price is documented on docs `/models` ($42/Btok = $0.042/Mtok, input only, output free); "production prices" wording app
record.md:200:- Verification (`verification.md`): 43 checks on independent copies — 37 survived, 3 downgraded (V17 request-id header is SDK-only; V40/V41 live f
open-verification.md:8:| O1 | Whether the homepage FAQ answer to "Are these prices temporary or subsidized?" contains any qualifier such as "production prices" 
open-verification.md:10:| O3 | Promotional (free) credit amount for new accounts, minimum top-up, accepted payment methods, whether card top-up/auto-reload is l
open-verification.md:13:| O6 | Whether a new Google login is admitted self-serve or hits the `SELF_SERVE_DISABLED` / invite-only branch; whether console login c
open-verification.md:14:| O7 | How to join the waitlist named in the launch post (no form found; homepage "Join Waitlist" goes to the jobs board). | email hello
profile.md:6:The only price-bearing page is `https://docs.typesafe.ai/models`: `jev-1.13.0` at "$42 / $0.042" per Btok / Mtok, "Charged per input token. Output 
profile.md:18:No free tier or credit amount is published. The launch post calls Jev "available today in early access" and speaks of "bringing developers off the
profile.md:25:2. Access is not demonstrably self-serve today; expect a gate (invite/waitlist) and plan to email sales@ or privacy@ for anything enterprise (ZDR,
verification.md:9:| S4 qualifier "production prices" | `production price` = 0 hits on homepage (590 KB), launch post, docs `/models`, the 910 KB docs corpus (`l
verification.md:20:| V7 | 6.2 "early access" + "waitlist" documented in the launch post; homepage "Join Waitlist" → Ashby jobs board | `available today in early
verification.md:21:| V8 | 6.3 self-serve `implied`; console JS carries gating strings | fresh fetch of all 26 console JS chunks: `SELF_SERVE_DISABLED` 12, `sign
verification.md:40:| V23 | Q3-17 "the word 'waitlist' is not first-party (`waitlist`=0 in llms-full)" | llms-full `waitlist` = 0 is true, **but the launch post 
verification.md:70:| V41 | #5 Discord "106844 members" | fresh og:description "106852 members" | survived, **downgraded** to "~106.8k per invite metadata (live 
verification.md:80:Down: S4 qualifier (overturned), V17 (downgraded), V40 (precision), V41 (precision). Up / in the subject's favour: V23 (overturned an over-co
```

Edit plan for gen 2 (one Edit per site; mark each with `(corrected 2026-09-23; previously: "…")`):
- R1: record 6.2, 6.3 rows + header line 7 ("S5 confirmed … → /login" add access note) + tally line 5 (6.2 split → documented; 6.3 implied → documented/unverified; 6.1, 6.7 unknown → documented — recount the tally: 51→54 documented, 4→3 implied, 9→6 unknown, recheck the "10 split" list); profile §Access and billing paragraph + "What matters" #2; verification V7, V8 (annotate as rule-8 misses, not re-ratify), V23 note, Net movement; open-verification O6, O7.
- R2: record 6.1, 6.7 (split amount/top-up), appendix add an "X (@typesafeai)" block; profile §Access first sentence; open-verification O3 (narrow to top-up/payment methods).
- R3: record 6.2 wording + appendix line 126; profile §Access; verification V7; open-verification O7.
- R4: record 6.3 + appendix line 174 (18 chunks; 6/6/1/1, "as of 2026-09-23 fetch"); profile §Access; verification V8.
- R5: open-verification close O1, O7 (strike-through or "closed 2026-09-23: …"), add O29 "does console sign-up succeed today (issue #10, 500s Sep 21–22)" [account attempt] and O30 "docs say 401 for a missing key; issue #10 reports live 403 authentication_error" [key]; O6 narrow to the 500s.
- R6: record 1.7 + appendix line 125 (add answer quote + module URL); record header line 7 S4 sentence (replace the "production prices" attribution note with the FAQ answer as the vendor's own qualifier; keep 1.6 `contradicted`); profile §Price; add S3 temper to record header + 5.10 "Documented vs. implied" cell + profile "What matters" #4; add S1 origin note to record header.
- R7: apply the three §Prose rows exactly as `fact-check.md` lines 126–131 list them (profile paragraph rewrite; profile #2 replacement sentence given verbatim there; record header/appendix annotations; O1/O7; V7/V8 rule-8 note).
- R8: append `fact-check.md` lines 133–141 verbatim under `## Patterns from the independent check` at the end of `verification.md`.

## Entries per ruling
(none applied yet — gen 1 rolled over at the context-budget WARN after the evidence pass; gen 2 applies R1–R8 from the edit plan above and fills this section: one entry per ruling — applied / applied-reworded / refused / could-not-apply, with file + claim id.)

## Not applied
- R1–R8: all pending gen 2. No ruling refused: every re-derived number agrees with the ruling's figure (see the evidence block).

## New findings needing a ruling
- None that block. Two notes for the orchestrator, no ruling required: (a) the S3-temper FAQ answer exists in two variants in the module ("acts automatically" / "acts autonomously") — gen 2 will quote the served-first variant and name the spread (rule 6); (b) the fact-check's module names (`m1.mjs`, `m6.mjs`) do not match the current build's hashed names — the content is identical, names recorded above.
