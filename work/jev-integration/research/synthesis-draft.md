# Synthesis — jev-integration research wave 1 (DRAFT, session 3, 2026-09-23 — §3 and the sweep-confirmed patterns in §4 are unfilled; rename to synthesis.md once filled)

The corrected, fact-checked picture of TypeSafe's Jev after three subjects
(`what-jev-is`, `terms`, `integration-paths`), one fact-check per subject, two
corrections rounds per subject, the Phase 4 cross-subject sweep, and one
post-sweep corrections pass. Claim ids point into each subject's `record.md`;
the three `profile.md` files are the readable summaries and this file does not
repeat them. **This is not the fit decision.** The decision question is at the
end, verbatim, for the human.

## 1. The corrected facts that bear on a template integration

### What a call is and what comes back (`what-jev-is`, `integration-paths`)

- One synchronous HTTP endpoint, `POST https://api.typesafe.ai/v1/systemone`,
  Bearer API key, plus `GET /v1/models`; no streaming, batch, async, webhook or
  idempotency surface (what-jev-is C8, integration-paths 1.3, 1.10, 6.1, 6.4).
- A request is `{state, model, questions}`; `questions` is a caller-keyed map
  of typed questions: **Choice** (pick one of up to 255 labelled options),
  **Score** (2–10 ordered levels), **Noul** (yes/no → P(yes)). Text only; 64k
  tokens per request, 32k for state plus the longest question (what-jev-is
  C10, C26, C27; integration-paths 4.1, 4.2, 4.7; terms 2.8).
- The schema is plain JSON on the wire, not JSON Schema / enums / Pydantic;
  Choice is single-label — several labels means one Noul per label
  (integration-paths 4.1, 4.3). Jev "is not trained to generate text":
  extraction is a Choice over enumerated candidates the caller finds first
  (integration-paths 4.4).
- Answers: Choice `{choice, probabilities, confidence}`; Score `{score,
  legend, probabilities, confidence}`; **Noul `{noul}` with no `confidence`
  field** (what-jev-is C17, C19; integration-paths 4.5). `confidence` is a
  0–1 statistic derived from the distribution — a peakedness measure, not an
  independent probability of being right; the production formula is not
  published, the docs' demo approximation is `(3·max − 1)/2` (what-jev-is
  C21; integration-paths 4.6). No calibration metric is published anywhere
  (what-jev-is C53).
- **The API never abstains.** It always returns one of the caller's declared
  options with a distribution; the escape hatches are caller-side: (1) declare
  an `other` / `none of the above` option; (2) gate on `confidence` in your
  code — the docs' 0.5 / 0.6 / 0.85 are worked examples, "depends on your
  domain"; (3) pair a relative Choice with absolute Nouls to decide whether to
  act at all (integration-paths 5.1–5.6; what-jev-is C24). Malformed schema →
  `422`; out-of-distribution *state* degrades accuracy rather than erroring
  (integration-paths 5.8, 5.9).
- The docs and the OpenAPI spec disagree on the request schema:
  `instructions` required (docs `/api`) vs optional and nullable (spec
  `anyOf` string/object/array/null, in no `required` list; `/primitives/advanced`
  says "`string`, `object`, `array`, or `null`"; api.md's type list omits
  `null`); Choice 255 cap and Score 2–10 are docs-only (spec: `minItems: 1`,
  no max); probabilities "sum to 1" (docs) vs "approximately 1" (spec)
  (what-jev-is C14, C15; integration-paths 5.12-spec-spread). Which side the
  server enforces is open (integration-paths O21).
- Versioning: ids `jev-<major>.<minor>.<patch>`, one catalogued version
  `jev-1.13.0`; aliases `jev-latest` (SDK default) and `jev-preview` move on
  release without notice; the response echoes the versioned id. Pinning is
  conditional in the docs' own words: "If you have tuned confidence thresholds
  against a specific version, pin that version's ID instead of the alias"
  (what-jev-is C11, C54; integration-paths 5.7). No model changelog, no
  deprecation policy; 16 cookbook pages still cite `jev-1.12` (what-jev-is
  C55; terms 7.7).
- SDKs: Python `typesafe-sdk` 0.7.1 and JS `@typesafe-ai/sdk` 0.6.0, both
  MIT, both read `TYPESAFE_API_KEY`, default `jev-latest`, retry 429/529 with
  backoff, 10 s per-attempt timeout (what-jev-is C35–C37; integration-paths
  6.6). **No first-party MCP server, no CLI, not OpenAI-compatible**;
  `docs.typesafe.ai/mcp` is the docs host's site-search MCP. Third-party MCP
  servers, CLIs and framework adapters are numerous and days old
  (what-jev-is C42; integration-paths 2.1–2.4, 2.9). Documented gateway
  routes: OpenRouter `~typesafe/jev-latest`, Vercel AI Gateway
  `typesafe-ai/jev` via `base_url` (integration-paths 2.5, 2.6).
- Performance is asserted, not specified: three unreconciled vendor latency
  figures; the one docs number with a payload is 0.27 s for 13 questions over
  ~54k characters on `jev-1.12`; TypeSafe's own evals site shows 67.8% mean
  accuracy, below two LLM rows (what-jev-is C45, C50; profile). The cookbook
  speed ratios divide contended LLM latency (16-way pool) by uncontended
  TypeSafe latency — see the sweep's ruling on R17 in §3.
- "Zero Hallucinations" is, by the vendor's own definition, a schema
  guarantee ("Schema matching is guaranteed"), not correctness; the docs list
  nine failure-mode sections for `jev-1.13` including context rot
  (what-jev-is C32, C33, C52; integration-paths 5.11).

### Terms (`terms`)

- Price: `$42 / $0.042` per Btok / Mtok input, "Output tokens are free", on
  the docs Models page only; no pricing page exists. The qualifier "production
  prices" appears on no first-party page; the qualifiers that do exist are the
  launch post's "can't prove it isn't subsidized … (which we expect to go down,
  not up)" and the homepage FAQ's "We can serve Jev profitably at our current
  prices" (terms 1.1, 1.4, 1.5, 1.7; what-jev-is S4, C25).
- Rate limits 250,000 tokens/s and 1,200 requests/min → 429, "adjusting
  dynamically … can change without notice"; scope (per key / org) undisclosed;
  no concurrency cap, no `x-ratelimit-*` headers, OpenAPI declares only
  200/422 (terms 2.1, 2.3, 2.4, 2.7; integration-paths 6.8).
- Auth: Bearer API key from the login-gated console; no OAuth, no key scopes,
  org model, rotation or SSO documented (terms 3.1, 3.2, 3.5).
- Data: inputs not trained on, in three documents; the MCA's perpetual
  **Telemetry** licence and open-ended retention are the caveats; ZDR only for
  enterprise via email; US-hosted; a DPA exists; no SOC 2 / ISO / HIPAA claim
  readable (terms 4.2–4.5).
- Legal: governed by a Master Customer Agreement (Sep 19, 2026), not a ToS;
  integrating the API into customer applications is licensed; **no automation
  or agent restriction**; prohibited: resale as a standalone service,
  distillation, reverse engineering, security testing; liability cap max(12
  months' fees, $50); JAMS arbitration (terms 5.1, 5.6, 5.9).
- Access: open self-serve as of 2026-09-20 (X post "No waitlist", homepage
  "NO MORE WAITLIST" banner); $5 starting credit (~120M tokens), stated on X
  only; prepaid credits expiring after 12 months; a third-party issue reports
  console auth returning HTTP 500 on Sep 21–22, unverified since (terms
  6.1–6.4, 6.7; O29).
- **No SLA**; status page at `status.typesafe.ai` (Better Stack, unlinked;
  API 99.839% over 90 days as of 2026-09-23); support "commercially
  reasonable efforts" with no response-time commitment; SDK changelogs only
  (terms 7.1, 7.3, 7.4, 7.7).

## 2. What changed versus the standing claims S1–S6 (`schema.md`)

| Claim | Verdict after the wave | What moved and where |
|---|---|---|
| S1 "first public System One Model, optimized for automation" | documented | Verbatim on the homepage FAQ; the docs say "flagship model and the first System One model" (what-jev-is C3). |
| S2 typed decisions with confidence estimates | documented for Choice and Score; **contradicted for Noul** | Noul returns one probability and no `confidence` field; the homepage's "Every Jev decision comes with a confidence estimate" is broader than the schema (what-jev-is S2, C19, C31; integration-paths 4.5, 5.5). |
| S3 "sold on not hallucinating and needing no human in the loop" | hallucination half documented **as a schema guarantee**; human-in-the-loop half **implied**, conditioned on confidence | No page says "no human in the loop"; the docs say "without a human co-pilot" / "proceed without human involvement" at high confidence and route low confidence to a human; the launch post's comparison table files human oversight under LLMs; the homepage FAQ says "Jev guarantees the shape of its answers, not that every decision is correct" and the served HTML says to set thresholds for "when it acts autonomously and when it asks for review" (what-jev-is S3, C32–C34; terms R6/R9; integration-paths 5.11, R3; rulings R1, R22). |
| S4 "$42 per billion input tokens" / "production prices" | figure documented; **qualifier contradicted** | "production prices" is the launcher's wording, not the site's (terms 1.1, 1.7; what-jev-is S4). |
| S5 docs at docs.typesafe.ai, console at console.typesafe.ai | documented | Unchanged. |
| S6 nothing on the homepage says how it is called | documented **for the homepage only** | The docs are a full Mintlify site with an HTTP reference and an unlinked OpenAPI spec (what-jev-is C9, S6; integration-paths profile). |

## 3. What the sweep found and how it was ruled

<!-- FILL AFTER SWEEP: per-sweep counts, R17 outcome, R20 mirror, formatting rows, stale counts; rulings R24+ -->

## 4. Wave patterns (the transferable output)

Recorded in `rulings.md` as they were found; confirmed or added by the sweep
as noted.

1. **Absence claims over-correct.** Passes grep for one spelling, then say
   "nowhere"/"anywhere". Absence built from the machine-readable reference
   (OpenAPI paths, `required` arrays) survived the fact-checks; absence built
   from grep did not. Fix: derive absence from a reference, and name the
   corpus and the spellings searched.
2. **Access/state claims go stale fast.** The vendor's X channel carried the
   state change (waitlist → open, $5 credit) that no docs page carries; passes
   never consulted it. JS-rendered copy (Framer module scripts, Next.js
   chunks) is one extra curl away and reverses "not in the served HTML".
3. **Diff the spec against the prose docs** and record the spread as its own
   `contradicted` claim rather than adopting either side (the `instructions`
   / 255 / 2–10 / "sum to 1" spread).
4. **Marketing overstates the schema.** "Every decision has a confidence",
   "Zero Hallucinations", "no human in the loop": each is narrower on the
   reference than on the homepage. Score marketing sentences against the
   OpenAPI/docs sentence side by side.
5. **Two agents reading one source line opposite ways cannot be settled from
   summaries.** Route the dispute to a re-fetch of the exact line range
   (R17); rule only on quoted lines.
6. **Fact-checkers get premises wrong too** (R12: two "not discoverable"
   findings were on pages the pass had linked). The corrections agent's
   refusal with evidence is the safeguard; provenance files stay untouched.
7. **Count spreads, not counts.** Where sources give different numbers
   (cookbook count 14 vs 16, chunk counts, two FAQ variants), record both
   with sources rather than picking one.
<!-- ADD sweep-confirmed / new patterns -->

## 5. Template seams a typed-decision model could serve — PROVISIONAL

From `research/seam-inventory.md` (an Explore agent's read of this template;
pointers below re-verified on disk in session 3). This is an inventory of
where the shape fits, **not** a recommendation; the fit decision weighs each
against the current runtime and records rejected alternatives.

What every candidate needs from the API, per §1:

- **A closed option set plus an explicit `other` option** — the API never
  abstains (integration-paths 5.1, 5.2).
- **A confidence-threshold policy** — Choice/Score only; a Noul seam
  thresholds `noul` itself (integration-paths 5.3–5.5).
- **Model-version pinning** — alias `jev-latest` by default; pin `jev-1.13.0`
  once thresholds are tuned (integration-paths 5.7; what-jev-is C54).
- **Cost** at $42/Btok input, output free; budget on it, do not contract on
  it (terms 1.1, 1.7).
- **Terms**: no SLA, rate limits may change without notice, $50 liability
  floor, "output may be inaccurate" disclaimer (terms 2.1, 5.9, 7.3).
- **Template rules** (already decided, not re-litigated): agent-agnostic,
  CLI-first or `mcp-fragments/`, key in the OS keychain via
  `security find-generic-password`, documented as a first-class addition, a
  test that proves it without a live key.

| Seam | Where (verified) | Shape today | What Jev would need | Fit hint |
|---|---|---|---|---|
| `rlm` leaf classification | `skills/rlm/SKILL.md:144-171`; `skills/rlm/scripts/rlm_repl.py:82,112,193` (`RLM_SUB_MODEL`, `_claude_exe()`, `claude -p --model`) | Root-declared closed category list; 50-record batches; labels regex-parsed; no `other`, no confidence; tens–hundreds of calls per run | One Choice per record; a batch can be one request — `state` = the record array, one question per record referencing `` `records[i]` `` (what-jev-is C28; integration-paths 6.2), within the 32k-token state limit; add `other`; threshold `confidence`; swap point is one subprocess | Strongest shape fit (high volume, caller-declared set, one swap point); cost and call-count model needed |
| research-wave per-claim verdict | `skills/research-wave/references/fact-check-brief.md:69-88` | {CONFIRMED, OVERSTATED, WRONG, UNVERIFIABLE} per claim; UNVERIFIABLE is already a none-of-the-above | Choice over 4 options with the claim + source text as `state`; the fact-checker still fetches the source | Shape fits; the value of the check is the re-fetch, not the label |
| triage category / state / severity | `skills/triage/SKILL.md:38-59` | {bug, enhancement}; five states; severity for bugs; human confirms | Three questions per issue (Choice, Choice, Choice); `other` for state | Low volume; human confirms anyway |
| doc-review severity / confidence | `skills/doc-review/SKILL.md:122-136` | {Blocker, Major, Minor, Polish} + {High, Medium, Low} per finding | Score (4 ordered levels) per finding; Jev's `confidence` would replace the verbal one | Finding text is open-ended; only the labelling is closed |
| decision-log tier / Promote? | `skills/decision-log/SKILL.md:35-55` | Tier {1,2,3}; Promote? {yes, maybe, no} | Score / Choice | A few per session; marginal |
| checkpoint learning routing | `skills/checkpoint/SKILL.md:38-60` | {setup-time, operational, code-pointer, decision, park} | Choice with `park` as `other` | Once per boundary; marginal |

**Not candidates** (ADR-0011 `docs/adr/0011-mechanical-gates-and-reason-codes.md:17-30`:
load-bearing gates are scripts with reason codes, never model calls):
session-loop verdicts, context-budget OK/WARN/STOP, launch-next-session
gates, `check-ledger.py`. Also not candidates: anything whose value is
open-ended text (handoff/launcher writing, triage briefs, doc-review
synthesis, code-review prose).

Open facts a fit decision would want and the research could not settle
without an account (off-limits, R0.4): whether sign-up works today (terms
O29); which schema limits the server enforces (integration-paths O21);
actual latency from this machine; calibration in practice.

## 6. The decision question (verbatim from `README.md` → Success criteria)

> **Fit decision** in `decisions.md`: which template seam(s) a typed-decision
> model serves better than the current runtime (or none), with the rejected
> alternatives and the evidence from `research/`.
