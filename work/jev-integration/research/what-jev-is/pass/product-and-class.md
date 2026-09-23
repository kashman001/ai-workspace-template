# what-jev-is — pass: product-and-class

Subject: Jev (TypeSafe AI). Cluster: product-and-class. Date checked: 2026-09-23.
Method: public pages only; curl raw HTML for typesafe.ai (Framer site) and docs `.md` variants (Mintlify);
`https://docs.typesafe.ai/llms-full.txt` grepped for model-id strings; 2 WebSearch calls for Q8, then one press page
fetched raw to confirm. Every quote below was grep-confirmed against the fetched source (script run 2026-09-23;
counts noted as `[n]` = occurrences in the served HTML/markdown, tags stripped).

Landmine note: the homepage and launch-post FAQ accordions are collapsed in the served HTML — only the question
headings are present (e.g. "Is Jev just a smaller LLM?", "Can Jev still get things wrong?", "Is Jev deterministic?").
The answer text is NOT in the HTML and could not be read without a browser. Exception: the first homepage FAQ entry
("What are System One Models? What is Jev?") IS rendered, and it is the source of S1.

---

## Q1 — What does TypeSafe call the model class, how do they define it, and is Jev the only one?

**Finding.** The class is called "System One Model(s)" (docs: "System One model"; marketing: "System One Model(s)").
Definition, in their words: a class of AI models built to make fast, structured decisions that software can use
directly — evaluates a `state` and returns typed answers and probabilities rather than generated text. The name is
credited to Kahneman's System 1 / System 2. Jev is described everywhere as "the first System One model" and the
"flagship model"; the launch post says "Our first public model is Jev". The Models page lists exactly one model
(Jev 1.13, `jev-1.13.0`); both aliases (`jev-latest`, `jev-preview`) resolve to it. No second System One model is
named on any public page. Whether an unreleased/non-public model exists is `unknown` ("first public" is the
launch post's own hedge).

**Verdict.** documented (class name + definition + Jev-is-first); "only one" = documented for the public catalog
(Models page lists one), `unknown` beyond that.

**Sources.** https://docs.typesafe.ai/concepts/system-one (via `.md`), https://docs.typesafe.ai/introduction (`.md`),
https://docs.typesafe.ai/models (`.md`), https://typesafe.ai (raw HTML), https://typesafe.ai/blog/introducing-system-one-models-and-jev (raw HTML).

**Verbatim evidence.**
- docs/concepts/system-one [1]: "System One models are a class of AI models built to make fast, structured decisions that software can use directly. A System One model evaluates a [state](/concepts/state) and returns typed answers and probabilities."
- docs/concepts/system-one [2]: "Jev is TypeSafe's flagship model and the first System One model."
- docs/concepts/system-one [1]: "Like an LLM, a System One model understands natural-language input. It returns typed decisions and probabilities rather than generated text."
- docs/concepts/system-one [1]: "The System One name comes from the concept Daniel Kahneman popularized in his book *Thinking, Fast and Slow*."
- docs/introduction [1]: "Jev is TypeSafe's flagship model and the first [System One model](/concepts/system-one). System One models are built to make fast, structured decisions that software can use directly. Jev evaluates typed *questions* against a *state* and returns structured results directly. No text generation, no parsing."
- docs/models [1] (the only row in "Current models"): "| Jev 1.13                    | `jev-1.13.0`"
- homepage FAQ [1]: "System One Models are a new class of AI model built for decisions inside software. Jev is TypeSafe’s first public System One Model, optimized for automation. Send Jev structured questions and get typed decisions with probabilities and confidence that your software can act on."
- homepage [2]: "We built a new class of models, System One Models, to be natively used by machines."
- launch post [2]: "a new class of frontier models built to make fast, structured decisions that software can use directly."
- launch post [2]: "Our first public model is" (followed by a linked "Jev" — the tag splits the sentence; rendered text reads "Our first public model is Jev, available today in early access.")
- launch post FAQ [2]: "The model class name draws on the distinction between fast, intuitive System 1 thinking and slow, deliberate System 2 reasoning."
- launch post FAQ [2]: "We named Jev after William Stanley Jevons."
- docs/introduction/coding-agents [1]: "Jev is a [System One model](/concepts/system-one). It does not generate text, write code, or hold a conversation."

---

## Q7 — Model versions / naming, deprecation policy, changelog

**Finding.** Naming: versioned IDs `jev-<major>.<minor>.<patch>` (only `jev-1.13.0` is published) plus two aliases,
`jev-latest` (stable; SDK default) and `jev-preview` (may move ahead; currently identical). The short form `jev-1.13`
(no patch) is used in the jaggedness page, the primitives pages, and code samples; `jev-1.12` appears in 14 cookbooks
as the model that produced their published numbers (runs dated 2026-07-31 through 2026-09). Whether `jev-1.12` is
still callable is `unknown` — the Models page only says versioned IDs "such as `jev-1.13.0`" are accepted.
Deprecation policy: none found — grep of the full docs corpus for deprecat/sunset/retire/end-of-life returns nothing
model-related. The only lifecycle statements are the alias-movement note and the advice to pin a versioned ID.
Changelog: there is NO model changelog. The two changelogs are SDK changelogs (Python v0.5.7 initial public 2026-09-14
→ v0.7.1 2026-09-21; JS v0.5.7 initial public 2026-09-11 → v0.6.0 2026-09-15) and contain zero model-version mentions.
Release dates per model are exposed via `GET /v1/models` (`release_date` field), which requires an API key, so not
read here. The jaggedness page carries "Last reviewed 2026-09-17".

**Verdict.** naming/aliases: documented. deprecation policy: `unknown` (absence checked against the full docs corpus
and the API reference, not just marketing). model changelog: `unknown`/absent (only SDK changelogs exist).

**Sources.** https://docs.typesafe.ai/models (`.md`), https://docs.typesafe.ai/api (`.md`),
https://docs.typesafe.ai/model-jaggedness/jev-1.13 (`.md`), https://docs.typesafe.ai/sdk/python/changelog (`.md`),
https://docs.typesafe.ai/sdk/javascript/changelog (`.md`), https://docs.typesafe.ai/llms-full.txt (grep).

**Verbatim evidence.**
- docs/models [1]: "| `jev-latest`  | `jev-1.13.0` | The most recent stable, official release. The default in our client SDKs, and the name the examples in these docs use.        |"
- docs/models [1]: "| `jev-preview` | `jev-1.13.0` | The most recent release, whether or not it is an official one. Moves ahead of `jev-latest` when a preview build is available. |"
- docs/models [1]: "`jev-preview` currently points to the same model as `jev-latest`. There is no preview build available right now."
- docs/models [1]: "An alias moves when a new release ships, so the answers behind it can change without a change on your side. The response's `model` field reports the versioned ID that answered, so you can log which model produced each result. If you have tuned confidence thresholds against a specific version, pin that version's ID instead of the alias and move to the new one on your own schedule."
- docs/models [1]: "`GET /v1/models` returns the names your account can send in the `model` field, with a description and release date for each. It currently lists the aliases. Versioned IDs such as `jev-1.13.0` are accepted by the `model` field whether or not they appear in the list."
- docs/api [1]: "The model that handles the request. Use `\"jev-latest\"`, TypeSafe's flagship model. See [Models](/models) for the available models and aliases."
- docs/model-jaggedness/jev-1.13 [1]: "**Applies to `jev-1.13`.** Last reviewed 2026-09-17."
- docs/model-jaggedness/jev-1.13 [1]: "Jev isn't perfect. Here are some jagged edges we are aware of with jev-1.13. Many of these will be fixed in later versions."
- docs/sdk/python/changelog [1]: "v0.5.7 (2026-09-14)" / "This is the initial public release of TypeSafe Python SDK."
- docs/sdk/javascript/changelog [1]: "v0.5.7 (2026-09-11)" / "This is the initial public release of TypeSafe JavaScript and TypeScript SDK."
- llms-full.txt, cookbooks/skill_suggestion [1]: "published run used `jev-1.12` and `claude-haiku-4-5-20251001`, rendered 2026-07-31."
- llms-full.txt, cookbooks/parallel_questions [1]: "TypeSafe jev-1.12 as of 2026-09, see README"

### Model versions seen (every id string, with page)
Counts are occurrences in https://docs.typesafe.ai/llms-full.txt unless noted. Spread recorded, not resolved.
- `jev-1.13.0` — 20: docs/models (table + aliases), docs/api (response examples `"model": "jev-1.13.0"`), docs/introduction/quickstart (line 100 response example).
- `jev-1.13` — 17: docs/model-jaggedness/jev-1.13 (15), docs/primitives/choice, /score, /noul (3 each per source count), docs/cookbooks/consistency_noul_cookbook, /consistency_choice_cookbook (1 each).
- `jev-1.12` — 27, all in cookbooks as `TYPESAFE_MODEL = "jev-1.12"` / `TS_MODEL` / `MODEL` plus "Numbers below came from `jev-1.12` on <date>" lines: skill_suggestion (run 2026-07-31), semantic_find, sde_cascade, rerank_typesafe ("as of 2026-08"), pre_parsed_value_extraction_cookbook, parallel_questions ("as of 2026-09"), llm_guardrails (2026-08-15), hierarchical_classification, function_calling, entity_alignment (2026-08-11), date_extraction_cookbook, classifying_rag_passages, classification_using_confidence (2026-08-12), citation_check (2026-08-16), autoresearch_feature_discovery (2026-08-03), autoformat ("as of 2026-09").
- `jev-latest` — 34: docs/models, docs/api (request examples), docs/concepts/system-one, docs/introduction/quickstart, docs/introduction/coding-agents, SDK pages.
- `jev-preview` — 2: docs/models only.
- "Jev 1.13" (display name) — docs/models table header.
- Not a model id but a version-like label on the marketing site: "TypeSafeAI 1.1", "Clock Tool 1.1", "Glider 1.1", "Version 0.01", "TS.AI.0S1" (homepage decorative widgets/footer; ignore).
- Launch post compares against "GPT-5.6 Terra", "GPT-6 Astra", "Fable 5.1" — third-party models, listed only so nobody mistakes them for Jev versions.

---

## Q8 — Who is TypeSafe (company, founders, funding, launch date of Jev)

**Finding (one paragraph).** TypeSafe AI is a San Francisco AI lab ("Made in SF."; team works in-person "in our San
Francisco office near the Embarcadero station") that describes itself as "building machine-native intelligence
infrastructure for automation". Founders per the team page: Diogo Almeida (CEO; "co-invented RLHF and InstructGPT",
previously Google Brain; the launch post is bylined "Diogo Almeida, founder, TypeSafe"), Sasha Sheng (COO; ex Meta/FAIR),
Erik Gafni (CTO; repeat founder, Ravel; early at Invitae and Freenome). Funding: $40M seed led by DCVC, reported by
FinSMEs on 2026-09-16 (the site itself says only "backed by top-tier investors"; no investor is named on typesafe.ai).
Other investors: `unknown`. Founding year: `unknown` on any page read — search-result summaries say 2024 and the launch
post says "After two years in stealth" (consistent with 2024, but not stated as a date). Jev launch: the launch post is
dated Sep 15, 2026 and says Jev is "available today in early access"; SDK "initial public release" dates are 2026-09-11
(JS) and 2026-09-14 (Python). The homepage meta description still says "in early access" as of 2026-09-23.

**Verdict.** company/founders/launch date: documented (typesafe.ai). funding: documented via third-party press
(FinSMEs, dated), implied on site. founding year and other investors: `unknown`.

**Sources.** https://typesafe.ai/team (raw HTML), https://typesafe.ai (raw HTML meta), https://typesafe.ai/manifesto,
https://typesafe.ai/blog/introducing-system-one-models-and-jev (raw HTML), https://docs.typesafe.ai/introduction/machine-learning-primer (`.md`),
https://www.finsmes.com/2026/09/typesafe-ai-raises-40m-in-seed-funding.html (raw HTML, `datePublished` 2026-09-16T09:00:47+00:00).
Not used (bot-walled, "Just a moment..."): dealroom.co. Not fetched: seedtable/tracxn/kucoin etc. (search-result titles only).

**Verbatim evidence.**
- homepage meta description [3]: "TypeSafe AI is an AI lab building machine-native intelligence infrastructure for automation, designed to make decisions within software. Try our first System One Model, Jev, in early access."
- homepage footer [6]: "Made in SF. With Love."
- team page [2]: "Diogo co-invented RLHF and InstructGPT, the methods that lead to ChatGPT and GPT4. Previously, he was at Google Brain."
- team page [2]: "Sasha is an ex-research engineer from Meta/FAIR"
- team page [2]: "Erik is a repeat founder (Ravel, multi-modal AI for dna-sequencing), an early employee at two unicorns (Invitae and Freenome)"
- team page [2]: "We're backed by top-tier investors who share our vision for building the foundation of truly transformative AI."
- team page [1]: "Our team works in-person five days a week in our San Francisco office near the Embarcadero station."
- launch post [3]: "Sep 15, 2026"; byline [2]: "Diogo Almeida, founder, TypeSafe"
- launch post [2]: "At OpenAI, I helped build the methods that made language models useful at following instructions and talking with people."
- launch post [2]: "After two years in stealth, countless technical challenges, and research breakthroughs… I am beyond excited to announce that today, TypeSafe AI is releasing our first"
- launch post [2]: "We’re still in Jev’s early days."
- docs/introduction/machine-learning-primer [1]: "RLHF was used to train InstructGPT and ChatGPT and was [co-invented by Diogo Almeida](https://scholar.google.com/citations?user=0T4y07QAAAAJ\&hl=en), cofounder of TypeSafe."
- FinSMEs [1]: "September 16, 2026"; [1]: "raised $40M in Seed financing"; [1]: "The round was led by DCVC"; [1]: "Led by CEO Diogo Almeida, CTO Erik Gafni, and COO Sasha Sheng"
- manifesto page title [1]: "Composable AI: Build Prod, Not God"
- other blog posts (blog index is JS-rendered; the three posts are linked from the homepage): "The Bitterest Lesson" dated "Sep 10, 2026"; "AI: too good to be true, too bad to be useful | TypeSafe AI" dated "Jun 19, 2026" (body not in served HTML).

---

## S1 — "Jev is TypeSafe's first public System One Model, optimized for automation"

**Finding.** This is a verbatim quote from the homepage FAQ (rendered answer to "What are System One Models? What is
Jev?"), apostrophe rendered as ’. The docs use the unhedged "first System One model" / "flagship model"; the launch
post uses "Our first public model is Jev". "optimized for automation" appears only on the homepage; the docs say the
equivalent in other words ("built to make fast, structured decisions that software can use directly").

**Verdict.** documented (homepage verbatim; docs back the substance with slightly different wording).

**Exact wording by source.**
- homepage https://typesafe.ai [1]: "Jev is TypeSafe’s first public System One Model, optimized for automation."
- homepage meta [3]: "Try our first System One Model, Jev, in early access."
- launch post [2]: "Our first public model is" + linked "Jev" + ", available today in early access."
- launch post [2]: "We built a new stack entirely focused on automation: with a new model architecture, parallel sampler for maximum efficiency, and training method we call Reinforcement Learning for Calibrated Decisions (RLCD)."
- docs/concepts/system-one [2]: "Jev is TypeSafe's flagship model and the first System One model."
- docs llms.txt [1]: "[Introduction](https://docs.typesafe.ai/introduction.md): Jev is TypeSafe's flagship model and the first System One model."

---

## S2 — "It returns typed decisions with confidence estimates instead of text"

**Finding.** Marketing states this flatly for every decision. The docs qualify it: `confidence` is returned on Choice
and Score answers only; Noul returns a single probability `noul` (0–1) with no `confidence` field. `confidence` is a
statistic derived from the returned `probabilities` (not an independent estimate). So the return shape is:
Choice → `choice`, `probabilities`, `confidence`; Score → `score`, `probabilities`, `confidence`; Noul → `noul`.
"instead of text" is fully documented (no generation).

**Verdict.** documented for Choice/Score; the blanket "every decision" phrasing is contradicted by the docs for Noul
(a count-of-primitives spread: marketing says all, docs say 2 of 3). "instead of text": documented.

**Exact wording by source.**
- homepage [2]: "Every decision includes an estimate of how confident the model is."
- homepage [1]: "Every Jev decision comes with a confidence estimate, so your software can act when confidence is high and escalate when it is not."
- homepage [1]: "Jev returns typed decisions with calibrated probabilities, so your software can account for uncertainty. Set the thresholds for when it acts autonomously and when it asks for review."
- homepage [2]: "Decisions, not strings" / "Typed outputs that software can act on."
- homepage [2]: "LLMs produce words for people. Jev produces typed decisions and is more like code: reliable, fast, self-consistent, and type-safe."
- launch post [2]: "All answers are accompanied with calibrated probabilities and confidence scores."
- launch post [2]: "Always communicates confidence and uncertainty with every output."
- launch post [2]: "Think of Jev as a frontier-intelligence function call: unstructured state in, typed probabilistic decisions out."
- docs/introduction [1]: "Choice and Score also return [confidence](/confidence), which your code can use to decide whether and how to act on an answer."
- docs/introduction primitives table [1]: "| [Noul](/primitives/noul)     | Is this statement true?      | `noul` (0–1)                            |"
- docs/confidence [1]: "`confidence` is a statistic computed from the probability distribution the answer already gives you. TypeSafe computes it for you and returns it on every Choice and Score answer, so the common case needs no extra work on your side."
- docs/concepts/system-one [1]: "Answers from System One models also include [confidence](/confidence), so you can decide when to act and when to escalate to a person or a reasoning model."
- docs/model-jaggedness/jev-1.13 [1]: "`jev-1.13` is not trained to generate text."

---

## S3 — "It is sold on not hallucinating and needing no human in the loop"

**Finding.** Half documented, half over-paraphrase. (a) "not hallucinating": the homepage has a "Zero Hallucinations"
panel and the launch post says Jev "can’t hallucinate" (with "can’t" italicised). But the launch post itself defines
the claim as schema/type-level ("Schema matching is guaranteed ... 0%"), and the docs say calibration "does not
guarantee that an individual answer is correct", list nine failure modes for jev-1.13, and admit adversarial state "can
move the answer". (b) "needing no human in the loop": NOT stated anywhere. The site's "humans-in-the-loop" language
is a critique of LLMs ("These flaws mean that LLMs require humans-in-the-loop"; manifesto: RLHF "requires humans in the
loop instead of running in the background"). The product copy and docs instead sell a confidence gate that routes to
a human at low confidence ("Low confidence: Do not act. Route to a human"; homepage: "when it asks for review").

**Verdict.** "not hallucinating": documented as marketing wording (homepage, launch post), but the docs qualify it
to type/schema errors and disclose wrong-answer modes — treat as contradicted for the natural reading "never wrong".
"needing no human in the loop": contradicted (no such wording; docs prescribe human routing at low confidence).
Closest defensible paraphrase: "sold on zero type/schema errors, with confidence so software can decide when to
escalate to a human".

**Exact wording by source.**
- homepage [2]: "Zero Hallucinations" (panel heading; its body text is the "Every Jev decision comes with a confidence estimate..." sentence above).
- homepage [3]: "These flaws mean that LLMs require humans-in-the-loop." (about RLHF LLMs, not Jev)
- homepage [1]: "...Set the thresholds for when it acts autonomously and when it asks for review."
- launch post [2]: "available today in early access. Jev achieves similar levels of intelligence on System One tasks compared to existing LLMs, while being two orders of magnitude faster and more efficient. While Jev gives up string generation, it’s optimized for structured outputs and " + italic "can’t" + " hallucinate."
- launch post [2]: "Our number is not empirical. Schema matching is guaranteed, thus we can confidently add 0% into the plots."
- launch post [2]: "Existing models, " + italic "no matter how smart" + ", still hallucinate and have type errors."
- manifesto [4]: "Yet the foreseeable consequence is AI that requires humans in the loop instead of running in the background." (about current assistant-style AI)
- docs/concepts/system-one [1]: "System One models are trained for calibrated decisions: their probabilities are optimized against outcomes to reflect uncertainty. Calibration is measured across groups of predictions; it does not guarantee that an individual answer is correct."
- docs/introduction/machine-learning-primer [1]: "These rates describe groups of predictions, not a guarantee about any single answer."
- docs/introduction/machine-learning-primer [1]: "An output can be compelling to a person without being reliable enough for unattended automation."
- docs/introduction/machine-learning-primer [1]: "Our expectation is that large-scale AI automation will be closer to 99% machine-to-machine interactions and 1% human interaction."
- docs/confidence [1]: "**High confidence:** Act automatically. The model has a clear read and you can proceed without human involvement."
- docs/confidence [1]: "**Low confidence:** Do not act. Route to a human, request clarification, or fall back to a different system."
- docs/model-jaggedness/jev-1.13 [1]: "State is data, and `jev-1.13` does not treat it as hostile by default. Content written to adversarially steer the model, whether that is an injected instruction, a deliberately misleading framing, or text that argues for its own classification, can move the answer."

---

## Things I could not find
- Any FAQ answer text on the homepage or launch post other than the first homepage entry (accordions not in served HTML): "Is Jev just a smaller LLM?", "Can Jev still get things wrong?", "Is Jev deterministic?", "Are these prices temporary or subsidized?", "Where does our training data come from?", "How does Jev perform against public benchmarks?" — `unknown` without a browser.
- A model deprecation / sunset / support-window policy — `unknown` (absent from docs corpus and API reference).
- A model (not SDK) changelog or release-notes page — `unknown`/absent. Release dates live only behind `GET /v1/models`.
- Whether `jev-1.12` (used in 14 cookbooks) is still served — `unknown`.
- Whether any non-public / second System One model exists — `unknown`.
- Founding year (search summaries say 2024; no fetched page states it) — `unknown`.
- Investors other than DCVC — `unknown`. Round date beyond the FinSMEs publication date (2026-09-16) — `unknown`.
- Blog index page content (JS-rendered; empty in served HTML) — relied on the three posts linked from the homepage.
- Body of the Jun 19, 2026 post "AI: too good to be true, too bad to be useful" (not in served HTML).
- The "workflow evals site" the launch post links to — not followed (out of scope for this cluster).
- Careers page (jobs.ashbyhq.com/typesafe-ai) — JS-only; role list `unknown`.
