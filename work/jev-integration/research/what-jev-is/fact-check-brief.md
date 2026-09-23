# Fact-check brief — `what-jev-is` (jev-integration wave 1, 2026-09-23)

Working directory: `/Users/kashif/Developer/experiments/ai-workspace-template`. Also read `work/jev-integration/research/schema.md` (standing claims S1–S6 and the landmines: marketing copy, 'no hallucinations' is a claim not a finding, JEV the virus is unrelated).


You did NOT do this research. You are the independent check on someone
else's work. Your value is finding what they got wrong, so read
adversarially: assume at least one claim is wrong until you prove
otherwise.

**Target:** `work/jev-integration/research/what-jev-is/`
**You write exactly one file:** `work/jev-integration/research/what-jev-is/fact-check.md`.
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
- T1 (contradicts standing claim S2) "Noul answers return a single probability field `noul` and NO `confidence` field; `confidence` exists only for Choice and Score." Check the API reference page, the confidence page, and the OpenAPI document at https://api.typesafe.ai/openapi.json (its `required` arrays). Could `confidence` be optional-but-present, or present under another name?
- T2 (contradicts S3) "The phrase 'needing no human in the loop' (or an equivalent) appears nowhere on typesafe.ai, the launch post, or the docs; the docs instead say low-confidence answers should be routed to a human." Fetch the rendered homepage text (marketing sites often inject copy via JS — try curl and WebFetch both) before agreeing.
- T3 "TypeSafe defines its 0% hallucination figure as a schema guarantee, with the verbatim words 'Our number is not empirical. Schema matching is guaranteed.'" Verify the quote exists verbatim at the cited URL.
- T4 "`confidence` is a 0–1 statistic computed from the answer's probability distribution (a peakedness measure); the exact formula is undocumented; calibration is claimed but no calibration measurements are published." Check whether any docs page gives a formula or a calibration plot/number.
- T5 "The API is POST https://api.typesafe.ai/v1/systemone plus GET /v1/models, bearer-key auth, three question types (noul/choice/score), 64k input / 32k token budgets, and one served model jev-1.13.0 behind aliases jev-latest and jev-preview." Re-derive every number and name from the docs/OpenAPI; note what the 64k/32k figures actually measure.
- T6 "TypeSafe raised $40M led by DCVC (source: The New Stack)." Verify amount, lead, date, and that the article says so.
- T7 (the pass overturned its own sub-agent) "No first-party MCP server exists, but third-party MCP packages for Jev exist on npm." Verify both halves; name the packages and their authors.
- T8 "The docs and the OpenAPI document contradict each other on whether `instructions` is a required request field." Verify which says what.
- T9 "SDK first-release dates differ between docs, package registries, and GitHub; the Python SDK's LICENSE file is an unfilled MIT template; the first-party agent skill links a 404 migration page." Verify each; these are the kind of claims a reader will repeat.

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

## Output: `work/jev-integration/research/what-jev-is/fact-check.md`

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
