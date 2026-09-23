# Fact-check brief — `integration-paths` (jev-integration wave 1, 2026-09-23)

Working directory: `/Users/kashif/Developer/experiments/ai-workspace-template`. Also read `work/jev-integration/research/schema.md` (standing claims S1–S6 and the landmines: marketing copy, 'no hallucinations' is a claim not a finding, JEV the virus is unrelated).


You did NOT do this research. You are the independent check on someone
else's work. Your value is finding what they got wrong, so read
adversarially: assume at least one claim is wrong until you prove
otherwise.

**Target:** `work/jev-integration/research/integration-paths/`
**You write exactly one file:** `work/jev-integration/research/integration-paths/fact-check.md`.
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
- T1 (the load-bearing finding for this workspace) "On an input that fits none of the declared options, the API never abstains, returns null, or errors — it always returns one of the caller's declared options plus a probability distribution; the only escape hatches are caller-side (declare an `other` option, gate on `confidence`, pair a Choice with per-option Nouls)." Verify against the docs and the OpenAPI response schema; look for any documented abstain/refusal/`none` behaviour or error code the pass may have missed.
- T2 "The docs' 0.5 / 0.6 / 0.85 confidence figures are worked examples, not defaults or recommendations." Verify the surrounding wording; an over-correction here would strip vendor guidance that actually exists.
- T3 "`confidence` is present for Choice and Score only; Noul answers carry none." (Also a target in the sibling `what-jev-is` check — verify independently from the OpenAPI `required` arrays.)
- T4 "Only one synchronous endpoint (POST https://api.typesafe.ai/v1/systemone) plus GET /v1/models; a public OpenAPI 3.1 spec exists; no first-party MCP server, CLI, OpenAI-compatible route, batch, streaming, webhooks, or idempotency key." Verify each absence by checking the docs nav, the OpenAPI paths, and TypeSafe's GitHub org (typesafe-ai), not just the pages the pass cited.
- T5 "Official Python SDK first, then JavaScript, then an agent skill for Claude Code/Codex; the Python SDK's default retry set is {408, 429, 500–599}." Verify package names, versions, and the retry set from source.
- T6 "OpenRouter and Vercel AI Gateway route to Jev (two models on OpenRouter); LangChain and Vercel AI SDK adapters exist vendor-side and are not mentioned by TypeSafe; the Vercel blog post is dated 2026-09-18." Verify each, with URLs and dates.
- T7 "The Jev 1.13 'jaggedness' docs page lists nine failure modes, including that adversarial state 'can move the answer'; SKILL.md says 'Typed output guarantees the interface, not truth.'" Verify the count and both quotes verbatim.
- T8 "Model aliases (jev-latest, jev-preview) move; the docs recommend pinning a version." Verify whether pinning is actually recommended or merely possible.
- Patterns from the sibling checks: (a) the docs and the OpenAPI document disagree in places (e.g. whether `instructions` is required) — where this subject cites one, check the other; (b) the README's "no human in the loop" wording has not been found on any first-party page — do not let it back in as an implied claim.

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

## Output: `work/jev-integration/research/integration-paths/fact-check.md`

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
