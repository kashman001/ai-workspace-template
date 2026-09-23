# Fact-check brief — `terms` (jev-integration wave 1, 2026-09-23)

Working directory: `/Users/kashif/Developer/experiments/ai-workspace-template`. Also read `work/jev-integration/research/schema.md` (standing claims S1–S6 and the landmines: marketing copy, 'no hallucinations' is a claim not a finding, JEV the virus is unrelated).


You did NOT do this research. You are the independent check on someone
else's work. Your value is finding what they got wrong, so read
adversarially: assume at least one claim is wrong until you prove
otherwise.

**Target:** `work/jev-integration/research/terms/`
**You write exactly one file:** `work/jev-integration/research/terms/fact-check.md`.
Leave every other file in that directory as you found it — other items
are being worked on concurrently, and you recommend rather than edit.

**First, read `skills/research-wave/references/method-rules.md` in full.** It is the standing
evidence and process discipline for this wave, and rules 1–4 are your
primary tools.

**Tool budget:** WebFetch, WebSearch and `curl` via Bash (load deferred tools with ToolSearch `select:WebFetch,WebSearch`); no Chrome tools; no accounts, keys, API calls or spend. Search is shared with two other concurrent checks — start from the cited URLs and the docs index at https://docs.typesafe.ai/.. Plan around it before you start rather than discovering
it mid-run.

## What to check, in priority order

1. **The priority targets below** — the claims that change a decision or
   contradict something already published.
2. Every claim a reader would **act on**, and every claim carrying a
   **number**.
3. Every **absence claim** — these are the weakest evidence class and the
   most frequently wrong. Method rules 1 and 2 govern.
4. A **sample of the rest**, at least ten more.
5. **The prose, not just the structured claims.** Headers, coverage
   lines, summary verdicts and narrative all state facts, and on some
   items every single error lived there while the structured cells stayed
   clean. On others the reverse. Check both.

**Priority targets for this item:**
Each target cuts both ways: the pass may be right, or it may have over-corrected against the subject. Rule each one.
- T1 (contradicts standing claim S4's qualifier) "The phrase 'production prices' appears on no first-party TypeSafe page (homepage, launch post, docs, legal pages)." The homepage is a JS-rendered marketing site — fetch it with both curl and WebFetch, and check the homepage FAQ ("Are these prices temporary or subsidized?") before agreeing. An over-correction here would wrongly strip a qualifier the vendor actually states.
- T2 "Docs /models states '$42' per billion input tokens / '$0.042' per million, 'Charged per input token. Output tokens are free.' There is no /pricing page (404 on typesafe.ai and docs.typesafe.ai)." Verify the exact wording, unit, and the 404s.
- T3 "Access is not demonstrably self-serve: the launch post says early access/waitlist; the homepage 'Join Waitlist' button links to the jobs board; console JS carries SELF_SERVE_DISABLED/invite branches; GitHub issue typesafe-ai/skills#10 (2026-09-21) reports console logins returning 500." Verify each of the four legs separately; the console-JS leg in particular is an inference from minified code — say what the code actually shows.
- T4 "Rate limits are 250k tokens/s and 1,200 requests/min, described as 'adjusting dynamically… can change without notice'; no SLA exists anywhere." Re-derive the numbers and the quote; check whether they are per-key, per-org, or per-model.
- T5 "The governing document is a Master Customer Agreement dated Sep 19, 2026 (not a ToS); liability cap is the greater of 12 months' fees or $50; billing is prepaid credits expiring after 12 months; California law with JAMS arbitration and no opt-out; it bans standalone resale, distillation/competing models, reverse engineering, and any security testing; it contains no restriction on automation or agents." Verify each clause against the document text.
- T6 "No-training commitment appears in three documents (Privacy Policy dated Nov 19 2025, MCA §4.1 with a prior-consent carve-out, docs), but the MCA grants a perpetual telemetry licence 'without restriction' with open-ended retention; zero-data-retention is enterprise-only via privacy@; hosting is US; no SOC 2 / ISO / HIPAA claim on any readable page." Verify the quotes and the carve-out wording; check whether the docs' no-training statement is unconditional.
- T7 "The MCA says output 'MAY PRODUCE INACCURATE OR ERRONEOUS OUTPUT' and the customer must independently evaluate it" (this tempers standing claim S3). Verify verbatim.
- T8 "SDKs are MIT-licensed." The sibling subject found the Python SDK LICENSE is an unfilled MIT template — check what the licence files actually say for each SDK.
- Pattern from the sibling subject `what-jev-is`: several claims there rested on a docs page and an OpenAPI document that disagree; where this subject cites the docs for limits or auth, check whether https://api.typesafe.ai/openapi.json says the same.

## Failure modes — flag each by name

- **Source does not support the claim** — page says something weaker,
  narrower, or different.
- **Dead or redirected source** — 404, or lands somewhere without the
  cited text.
- **Marketing scored as documentation** — a landing-page phrase treated
  as a documented capability.
- **Preview scored as generally available** — real, but beta/waitlisted,
  and the claim does not say so.
- **Someone else's capability** — an upstream provider's or subsidiary's
  feature recorded as the subject's own.
- **Fabricated quote** — quoted string absent from the cited page. Check
  raw HTML; report the occurrence count.
- **Missing configuration** — a performance number without the hardware
  and settings behind it, or without saying they are undisclosed.
- **Over-correction against the subject** — a capability it genuinely
  has, understated or denied. Roughly half of real findings are these.
- **Wrong standard** — "unknown" where the source plainly answers, or a
  confident verdict where "unknown" is honest.
- **Stale date** — checked date not matching what was actually verified.

## Output: `work/jev-integration/research/terms/fact-check.md`

Header: who checked, the date, how many claims re-fetched of how many
total. Then one row per claim: **claim | verdict (CONFIRMED /
OVERSTATED / WRONG / UNVERIFIABLE) | what the source actually says |
recommended correction.** Confirmed claims get one line; problems get as
much room as they need.

Close with a **patterns** section: the systematic biases you saw across
the item. These matter more than any single claim — they transfer to
every other item in the wave, and they are what the orchestrator
propagates.

**Recommend; do not edit.** The orchestrator rules on your findings.

## Return: at most 12 lines

First line: `CLEAN` / `CORRECTIONS_NEEDED` / `SERIOUS`. Then counts by
verdict, the worst two or three findings, and any pattern. Detail belongs
in the file — the orchestrator's context is the binding constraint on the
whole wave.
