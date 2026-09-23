# Jev / TypeSafe — cluster `api-reference` — raw findings (pass)

Subject: what-jev-is. Questions Q2, Q3, Q4. Date checked: 2026-09-23.
Method: `curl -sL` of the Mintlify `.md` variants of docs.typesafe.ai pages; raw HTML of `/api` and `/models` for tables (rule 3); the public OpenAPI 3.1 spec at `https://api.typesafe.ai/openapi.json` (found by probing; HTTP 200, no auth, not a model call); raw HTML of typesafe.ai and the launch blog post. No WebSearch used. No accounts, keys, or API calls to the model.
Every quote below was copied from the curl output and re-grepped against the saved page (see "Verification log" at the end).

Sources fetched (all 200):
- https://docs.typesafe.ai/api.md and raw https://docs.typesafe.ai/api
- https://api.typesafe.ai/openapi.json (OpenAPI 3.1.0, `info.version` "0.2.0")
- https://docs.typesafe.ai/introduction/quickstart.md, /introduction.md, /primitives.md, /primitives/choice.md, /primitives/score.md, /primitives/noul.md, /primitives/advanced.md, /confidence.md, /concepts/state.md, /concepts/system-one.md, /introduction/machine-learning-primer.md, /models.md (+ raw HTML), /model-jaggedness/jev-1.13.md, /cookbooks/parallel_questions.md
- SDK: /sdk/javascript/api/interfaces/{SystemOneRequestPayload,SystemOneResult,ChoiceResponse,ScoreResponse,NoulResponse,Usage,ModelCard,ChoiceQuestion,ScoreQuestion,NoulQuestion,Questions}.md, /sdk/javascript/api/type-aliases/{JsonValue,Description}.md, /sdk/javascript/api/variables/ENV.md, /sdk/python/api/types/{responses,questions,common}.md, /sdk/python/api/{exceptions,constants}.md
- https://typesafe.ai (raw HTML, Framer), https://typesafe.ai/blog/introducing-system-one-models-and-jev (raw HTML)

---

## Q2 — API surface: base URL, endpoints, methods, request schema, response schema

**Finding.** One base URL, two endpoints. `POST https://api.typesafe.ai/v1/systemone` evaluates a `state` against a map of named `questions` and returns one `answers` entry per question plus `model` and `usage`. `GET https://api.typesafe.ai/v1/models` lists model names/aliases. Auth is `Authorization: Bearer <API_KEY>`. Content type `application/json`. No streaming, batch, or other endpoints exist in the OpenAPI spec (`paths` contains exactly `/v1/systemone` [post] and `/v1/models` [get]).

**Verdict:** documented (docs page + OpenAPI spec agree on endpoints, auth, and top-level shape).
**Source:** https://docs.typesafe.ai/api.md ; https://api.typesafe.ai/openapi.json ; https://docs.typesafe.ai/models.md ; SDK constants pages.
**How verified:** curl .md; raw HTML of /api (no embedded OpenAPI; page's `openApiReferenceData` is `$undefined`, so the reference is hand-written MDX); openapi.json fetched and parsed with python `json`.

### Base URL and auth header — verbatim

api.md:
```
POST https://api.typesafe.ai/v1/systemone
Authorization: Bearer <API_KEY>
Content-Type: application/json
```
openapi.json `info.description`: "Send your API key in the Authorization header as `Bearer <API_KEY>`. Use GET /v1/models to discover available model names."
openapi.json `components.securitySchemes`: `{"HTTPBearer": {"type": "http", "scheme": "bearer"}}`; both operations carry `"security": [{"HTTPBearer": []}]`.
Python constants: `DEFAULT_BASE_URL = 'https://api.typesafe.ai'`, `API_KEY_ENV = 'TYPESAFE_API_KEY'`, `DEFAULT_MODEL = 'jev-latest'`, `DEFAULT_TIMEOUT = 10.0` ("Default timeout in seconds for each HTTP operation.").
JS ENV: `baseURL: "TYPESAFE_BASE_URL"` — "API root; defaults to `https://api.typesafe.ai`."; `defaultModel` — "Default model name; defaults to `jev-latest`."

### Request schema — verbatim (api.md)

> "Evaluate a `state` against a map of typed `questions` and get back structured `answers`, one per question."

Top-level fields (api.md ParamField blocks):
- `state` — type `string | object | array`, required — "The content to evaluate. A plain string for text, or structured data (object/array) for things like chat logs, records, or the current state of your application."
- `model` — type `string`, required — "The model that handles the request. Use `"jev-latest"`, TypeSafe's flagship model."
- `questions` — type `map<string, Question>`, required — "A map of typed [Question](#question-types) objects. You choose each key; answers come back under the same keys." / "The key is not sent to the underlying model and is not used in inference."

OpenAPI `SystemOneRequest`: `required: ["model","questions","state"]`; `state.anyOf` = string | object | array (no null); `questions` has `"minProperties": 1`; description "Content and named questions to evaluate together using a TypeSafe model."

Full example request, verbatim from api.md:
```json
{
  "state": "Help! My payouts have been failing for 3 days.",
  "model": "jev-latest",
  "questions": {
    "is_urgent": {
      "type": "noul",
      "instructions": "Does this convey urgency?"
    }
  }
}
```

Full multi-type example request, verbatim from introduction/quickstart.md ("Request body"):
```json
{
  "state": "Hi, I've been trying to connect my Stripe account for 3 days and the integration keeps failing. I'm losing sales. Please help ASAP.",
  "model": "jev-latest",
  "questions": {
    "department": {
      "type": "choice",
      "instructions": "Which team should handle this",
      "criteria": {
        "billing": "Payment or subscription issues",
        "technical": "Bugs or integration problems",
        "sales": "Pricing or account questions"
      }
    },
    "frustration": {
      "type": "score",
      "instructions": "How frustrated the customer appears",
      "criteria": [
        "Calm, just stating facts",
        "Frustrated but civil",
        "Very angry, strong language"
      ]
    },
    "is_urgent": {
      "type": "noul",
      "instructions": "The message conveys urgency or time-sensitivity"
    }
  }
}
```

### Question types — verbatim (api.md)

> "A `Question` is one of three types, set by its `type` field. All three share `type` and `instructions`; each adds its own `criteria`."

- Noul: "A yes/no question. Returns the probability the answer is yes." Fields: `type` `"noul"` required; `instructions` `string | object | array` required; `criteria` `object` optional with `true` ("What a yes (value near 1) means.") and `false` ("What a no (value near 0) means.").
- Choice: "Picks one option from a set you define. Returns the chosen option and the full probability distribution." Fields: `type` `"choice"` required; `instructions` required; `criteria` `map<string, string | object | array | null>` required — "A map of option to rubric description; use null when an option needs no extra detail. You can have a maximum of 255 options per Choice."
- Score: "Rates the state along a rubric you define. Returns a probability-weighted value across your levels." Fields: `type` `"score"` required; `instructions` required; `criteria` `array<string | object | array>` required — "An ordered array of level descriptions. A Score should have at least two levels; the API accepts up to 10."

OpenAPI `Question`: `oneOf` NoulQuestion | ChoiceQuestion | ScoreQuestion with `discriminator.propertyName: "type"`.

### Response schema — verbatim (api.md)

> "One answer per question, returned under the same ids you provided."
- `model` `string` required — "The model that performed the evaluation." (OpenAPI: "Name of the model that answered the questions. May differ from the alias supplied in the request.")
- `answers` `map<string, Answer>` required — "One [Answer](#answer-types) per question, keyed by the same ids you used in questions."
- `usage` `object` required — "Token usage for the request." with `input_tokens` integer, `output_tokens` integer. (OpenAPI Usage: `input_tokens` "Number of billable input tokens used to evaluate the request."; `output_tokens` "Number of output tokens used to answer the questions. Output tokens are currently free of charge.")

Full example response, verbatim from api.md:
```json
{
  "model": "jev-1.13.0",
  "answers": {
    "is_urgent": {
      "type": "noul",
      "noul": 0.95
    }
  },
  "usage": { "input_tokens": 296, "output_tokens": 20 }
}
```

Full multi-type example response, verbatim from introduction/quickstart.md ("Response body"):
```json
{
  "model": "jev-1.13.0",
  "answers": {
    "department": {
      "type": "choice",
      "choice": "technical",
      "confidence": 0.78,
      "probabilities": {
        "technical": 0.85,
        "sales": 0.0,
        "billing": 0.15
      }
    },
    "frustration": {
      "type": "score",
      "score": 1.0,
      "confidence": 1.0,
      "legend": {
        "0": "Calm, just stating facts",
        "1": "Frustrated but civil",
        "2": "Very angry, strong language"
      },
      "probabilities": {
        "0": 0.0,
        "1": 1.0,
        "2": 0.0
      }
    },
    "is_urgent": {
      "type": "noul",
      "noul": 1.0
    }
  },
  "usage": {
    "input_tokens": 392,
    "output_tokens": 65
  }
}
```

Response headers documented: `x-typesafe-request-id` (Python SDK `SystemOneResponse.request_id`: "The `x-typesafe-request-id` response header."); `retry-after` on 429 (models.md: "honor the `retry-after` header when the response carries one").

### GET /v1/models — verbatim
models.md: "`GET /v1/models` returns the names your account can send in the `model` field, with a description and release date for each. It currently lists the aliases. Versioned IDs such as `jev-1.13.0` are accepted by the `model` field whether or not they appear in the list."
OpenAPI `ModelMetadataList.models[]` = `{name, description, release_date}` all required; `release_date` "Model release date, formatted as YYYY-MM-DD."

### Models and aliases (models.md; table verified in raw HTML, rule 3)
Raw-HTML table rows extracted from https://docs.typesafe.ai/models:
```
Jev 1.13 | jev-1.13.0
Price (per Btok / per Mtok) | $42 / $0.042
Rate limits | 250,000 tokens per second / 1,200 requests per minute
Context length | 64k tokens per request; 32k tokens for state plus the longest question
Input | Text only. String, JSON object, or array of text values. No image, audio, or video input.
Alias | Points to | Meaning
jev-latest | jev-1.13.0 | The most recent stable, official release. The default in our client SDKs, and the name the examples in these docs use.
jev-preview | jev-1.13.0 | The most recent release, whether or not it is an official one. Moves ahead of jev-latest when a preview build is available.
```
(Markdown and raw HTML agree; the Markdown table's header row is the "Jev 1.13 | jev-1.13.0" row — a rendering quirk, not a data difference.)

---

## Q3 — How a decision comes back, and how confidence comes back (LOAD-BEARING)

**Finding.** A decision is a typed JSON object per question, discriminated by `type`. Choice returns the label as a string in `choice` plus a full `probabilities` map and a scalar `confidence`. Score returns a float `score` (probability-weighted position on your 0..N-1 levels), a `legend`, `probabilities`, and `confidence`. Noul returns a single float `noul` (probability of yes) and **no** `confidence` field. `confidence` is a number in [0,1], **derived from the answer's probability distribution** (a peakedness statistic), not an independent calibrated probability. The exact production formula is **not documented**; the docs' interactive demo uses `(count × largest probability − 1) / (count − 1)` and says this "approximate[s]" confidence. TypeSafe's calibration claim attaches to the *probabilities* (documented in the AI primer / System One pages as group-level calibration), not to `confidence` itself.

**Verdict:** documented (field names/types/ranges and the derived-from-probabilities definition); **unknown** for the exact confidence formula; **documented** for calibration being a property of probabilities measured across groups.
**Sources:** https://docs.typesafe.ai/api.md (Answer types), https://docs.typesafe.ai/confidence.md, https://docs.typesafe.ai/primitives/choice.md, /primitives/score.md, /primitives/noul.md, https://api.typesafe.ai/openapi.json, https://docs.typesafe.ai/introduction/machine-learning-primer.md, https://docs.typesafe.ai/concepts/system-one.md.
**How verified:** curl .md, openapi.json parsed.

### Exact field list per answer type (api.md + OpenAPI; all fields `required`)

| Type | Fields | Types (api.md) | OpenAPI `required` |
|---|---|---|---|
| Noul answer | `type`, `noul` | `"noul"`, `number` | `["noul","type"]` |
| Choice answer | `type`, `choice`, `probabilities`, `confidence` | `"choice"`, `string`, `map<string, number>`, `number` | `["choice","confidence","probabilities","type"]` |
| Score answer | `type`, `score`, `legend`, `probabilities`, `confidence` | `"score"`, `number`, `map<string, string>`, `map<string, number>`, `number` | `["score","confidence","legend","probabilities","type"]` |

OpenAPI `Answer`: `oneOf` NoulAnswer | ScoreAnswer | ChoiceAnswer, `discriminator.propertyName: "type"`.

### Verbatim definitions — api.md "Answer types"
> "Every answer carries a `type` matching its question. Choice and Score answers also carry a `confidence` between 0 to 1, derived from the answer's probability distribution. See [Confidence](/confidence)."

Noul: `noul` — "The yes/no answer on a scale from 0 (no) to 1 (yes)."
Choice: `choice` — "The highest-probability option."; `probabilities` — "Every option mapped to its probability (floats that sum to 1)."; `confidence` — "How certain the model is, derived from probabilities."
Score: `score` — "The probability-weighted answer across the levels; can land between levels."; `legend` — "Each level number mapped back to its description."; `probabilities` — "Each level (string key) mapped to its probability (floats that sum to 1)."; `confidence` — "How certain the model is, derived from probabilities."

Per-type example responses, verbatim from api.md:
```json
{
  "model": "jev-1.13.0",
  "answers": {
    "department": {
      "type": "choice",
      "choice": "billing",
      "probabilities": { "billing": 0.88, "technical": 0.12, "sales": 0.0 },
      "confidence": 0.81
    }
  },
  "usage": { "input_tokens": 318, "output_tokens": 34 }
}
```
```json
{
  "model": "jev-1.13.0",
  "answers": {
    "frustration": {
      "type": "score",
      "score": 1.05,
      "legend": { "0": "Calm", "1": "Frustrated", "2": "Very angry" },
      "probabilities": { "0": 0.0, "1": 0.95, "2": 0.05 },
      "confidence": 0.92
    }
  },
  "usage": { "input_tokens": 304, "output_tokens": 18 }
}
```

### Verbatim definitions — OpenAPI schema descriptions (api.typesafe.ai/openapi.json)
- ChoiceAnswer.choice: "The name of the choice with the highest probability among the question's criteria."
- ChoiceAnswer.confidence: "Confidence in the selected choice, from 0 to 1. Higher values indicate greater certainty; use lower values to flag uncertain selections for review."
- ChoiceAnswer.probabilities: "Probability of each choice in criteria, keyed by choice name, from 0 to 1. Shows how likely the alternatives are; values sum to approximately 1."
- ScoreAnswer.score: "Expected score: the probability-weighted average of the rubric levels. May fall between integer levels."
- ScoreAnswer.confidence: "Confidence in the score, from 0 to 1. Higher values indicate greater certainty; use lower values to flag uncertain ratings for review."
- ScoreAnswer.legend: "The requested criteria mapped to their score levels, so you can interpret the score."
- ScoreAnswer.probabilities: "Probability of each score level, from 0 to 1, using the same keys as legend. Shows how likely the alternatives are; values sum to approximately 1."
- NoulAnswer.noul: "Probability of a yes answer or a true statement, from 0 to 1. Values near 1 favor yes or true, values near 0 favor no or false, and values near 0.5 indicate uncertainty."
(Note the wording difference: api.md says probabilities are "floats that sum to 1"; OpenAPI says "values sum to approximately 1".)

### TypeSafe's own definition of confidence vs probability — verbatim, confidence.md
> "All Score and Choice answers from TypeSafe include a `probabilities` property representing the probability distribution across the options (for Choice) or levels (for Score). The *shape* of that distribution is what tells you how certain the model is: concentrated on one outcome means a confident answer, spread out means an uncertain one."
> "The answer's `confidence` property collapses that shape into a single number from 0 to 1, so you can threshold on it without doing the math yourself. (Noul answers don't carry one.)"
> "`confidence` is a statistic computed from the probability distribution the answer already gives you. TypeSafe computes it for you and returns it on every Choice and Score answer, so the common case needs no extra work on your side."
> "**A solid default:** We provide `confidence` as a convenient measure that fits most use-cases, but you are never locked into our definition. Depending on what you are evaluating, a different measure may serve you better, which is exactly why we give you the full `probabilities` in the response. The pros and cons of different computations is a specialized topic that we'll keep to a separate cookbook rather than this page, and will add the link here when we do!"
> "For a [Choice](/primitives/choice), the distribution is `probabilities` across your options. For a [Score](/primitives/score), it is the distribution across your levels. In both cases a flatter distribution means lower confidence: low confidence on a Choice often means none of the options are a clear winner over the others, and low confidence on a Score often means the levels are ambiguous, multi-dimensional, or the state doesn't contain enough to go on."

The page's interactive demo (inline JSX, `ConfidenceExplorer`) computes `Math.max(0, Math.min(1, (count * peak - 1) / (count - 1)))` where `peak = Math.max(...values) / 100`, and its caption says:
> "TypeSafe computes confidence from how the probability is spread across the options. All of it on one option gives 1.0; the more evenly it spreads, the lower the confidence. This demo uses <code>(3 × largest probability − 1) / 2</code> to approximate confidence for three options."
=> The production formula is explicitly labelled an approximation here; no page states the exact formula. (Checked: grep for `entropy|peak|formula|Math.log` across confidence.md, choice.md, score.md, noul.md — only the demo function above.)

Choice page (primitives/choice.md):
> "* [`confidence`](/confidence): A number from 0 to 1 computed from how `probabilities` is spread. A flat shape, with probability spread across several options, means low confidence. A single peak on one option means high confidence."
Score page (primitives/score.md):
> "* `score`: The position on the level number line, from 0 to the top level number, which is 2 here. It's each level number multiplied by its probability, added up: 0 x 0.0 + 1 x 0.57 + 2 x 0.43 = 1.43."
> "* [`confidence`](/confidence): A number from 0 to 1 computed from how `probabilities` is spread. A single peak on one level means high confidence. Probability spread over several levels means low confidence."
> "In these examples, confidence 1.0 means the returned distribution puts all its probability on one level. This describes the model's answer, not a guarantee that the answer is correct."
> "Different distributions can produce the same score. A score of 1.0 can mean all probability is on level 1, or half is on each of levels 0 and 2. Read `probabilities` and `confidence` alongside the score to distinguish these cases."
> "Using the Python SDK, `ScoreAnswer` has `score`, `confidence`, `probabilities`, and `legend` as typed fields. The SDK keys `probabilities` and `legend` by integer level rather than by string."
Noul page (primitives/noul.md):
> "There is no separate `confidence` value for a Noul, unlike a [Choice](/primitives/choice) or a [Score](/primitives/score). A Noul's probability distribution has only two outcomes, yes and no, so the single `noul` value describes it completely. A Choice or Score spreads probability over several options or levels, and `confidence` summarizes that spread."
> "The number is the answer and the certainty in one. A value near 1 is a strong yes. A value near 0 is a strong no. A value near 0.5 means the model gives yes and no similar probability."

### Calibration — what TypeSafe claims about the *probabilities* (not `confidence`)
introduction/machine-learning-primer.md:
> "Calibration makes uncertainty usable by software. Across many predictions from a well-calibrated model:"
> "* Outcomes assigned a probability of `0.2` should occur about 20% of the time."
> "* Outcomes assigned a probability of `0.8` should occur about 80% of the time."
> "* Outcomes assigned a probability of `1.0` should occur 100% of the time."
> "These rates describe groups of predictions, not a guarantee about any single answer."
concepts/system-one.md:
> "System One models are trained for calibrated decisions: their probabilities are optimized against outcomes to reflect uncertainty. Calibration is measured across groups of predictions; it does not guarantee that an individual answer is correct."
=> Calibration is stated as a property of the probability outputs, as a group statistic. No page says `confidence` is itself a calibrated probability of correctness; confidence.md defines it as a shape statistic. The docs give no calibration measurements (no ECE, reliability plots, or accuracy-vs-confidence tables) on the pages fetched.

### SDK wire types (confirm the shape)
JS ChoiceResponse: `readonly choice: keyof T & string;` ("The selected label."), `readonly confidence: number;` ("Reported confidence in the selected label."), `readonly probabilities: { readonly [label in string | number | symbol]: number };`, `readonly type: "choice";`
JS ScoreResponse: `readonly confidence: number;` ("Reported confidence in the score."), `readonly legend: ScoreLegend<T>;`, `readonly probabilities: { readonly [score in number | `${number}`]: number };`, `readonly score: number;` ("Expected score, which may fall between integer rubric levels."), `readonly type: "score";`
JS NoulResponse: `readonly noul: number;` ("Probability of a yes answer, from zero to one."), `readonly type: "noul";`
Python: `ChoiceAnswer.confidence: float`; `ScoreAnswer.probabilities: dict[int, float]` ("Probabilities keyed by integer score."); `ScoreAnswer.legend: dict[int, ...]` ("Rubric descriptions keyed by integer score.").

### Homepage / blog wording vs docs (subject risk S1–S3)
Homepage (typesafe.ai, raw HTML text), verbatim:
- "Decisions, not strings" / "Typed outputs that software can act on."
- "calibrated confidence" / "Every decision includes an estimate of how confident the model is."
- "Zero Hallucinations" / "Every Jev decision comes with a confidence estimate, so your software can act when confidence is high and escalate when it is not."
- "Jev returns typed decisions with calibrated probabilities, so your software can account for uncertainty. Set the thresholds for when it acts autonomously and when it asks for review."
- FAQ: "System One Models are a new class of AI model built for decisions inside software. Jev is TypeSafe's first public System One Model, optimized for automation. Send Jev structured questions and get typed decisions with probabilities and confidence that your software can act on."
Blog (introducing-system-one-models-and-jev), verbatim:
- "While Jev gives up string generation, it’s optimized for structured outputs and can’t hallucinate." (raw HTML: curly apostrophes; "can’t" is wrapped in `<em class="framer-text">…</em>`)
- "Think of Jev as a frontier-intelligence function call: unstructured state in, typed probabilistic decisions out."
- Table row "Confidence": "Always communicates confidence and uncertainty with every output. Calibrated: higher confidence means higher accuracy. More consistent: returns similar answers for similar inputs."
- "No type errors: This would be an easy thing to falsify with just a single counter-example, but it is mathematically impossible." (raw HTML: "No type errors" is inside `<strong>…</strong>`, the rest follows the closing tag)
- "Our number is not empirical. Schema matching is guaranteed, thus we can confidently add 0% into the plots."
- "Jev supports a cardinality up to 255."
Do the docs back these?
- "Every decision includes … confidence" (homepage) vs docs: Noul answers carry **no** `confidence` field (api.md, confidence.md, noul.md). Docs' own framing: the Noul value "is the answer and the certainty in one". => homepage wording is broader than the schema; docs are consistent with each other.
- "Zero hallucinations"/"can't hallucinate": the docs frame this as **schema/type guarantee**, not correctness: primitives.md "* **Every answer is constrained to the options you supplied.** The model returns a probability distribution over your options or levels, never a value outside them. Your code never has to recover a value from generated prose."; the blog itself says the 0% figure "is not empirical. Schema matching is guaranteed". score.md: "This describes the model's answer, not a guarantee that the answer is correct." The jaggedness page lists known failure modes (counting, indirection, large state, adversarial state).
- "Calibrated: higher confidence means higher accuracy" (blog) — the docs attach calibration to probabilities as a group property (primer, system-one page) and provide no measurements on the fetched pages.

---

## Q4 — What input does a call take; limits

**Finding.** One `state` (string, JSON object, or JSON array of text values — text only, no images/audio/video) plus a map of ≥1 named questions, each `{type, instructions, criteria}`; `instructions` and every criteria value may themselves be string/object/array (and `null` per the Advanced page, SDKs, and OpenAPI). All questions in one request see the same state and are evaluated independently and in parallel. Documented limits for `jev-1.13.0`: 64k tokens per request (state + all questions), 32k tokens for state + the single longest question; ≤255 Choice options; Score levels "at least two … up to 10"; rate limits 250,000 tokens/s and 1,200 requests/min (stated to be changing without notice). No documented maximum number of questions other than the token budget.

**Verdict:** documented (shapes, token budgets, per-question limits, rate limits); **unknown** for max question count, max state bytes, server-side timeout.
**Sources:** https://docs.typesafe.ai/concepts/state.md, /api.md, /primitives.md, /primitives/advanced.md, /models.md (raw HTML for the table), /model-jaggedness/jev-1.13.md, openapi.json, SDK pages.
**How verified:** curl .md; raw HTML of /models; openapi.json.

### State — verbatim (concepts/state.md)
> "**State** is the content you ask a System One model to evaluate. It could be a support message, a passage of text, or the current state of your application. You pass it in the `state` field of an API request, alongside the questions you want answered."
> "Each request evaluates one state against one or more questions. All questions see the same state and are evaluated independently. You can mix [Choice](/primitives/choice), [Score](/primitives/score), and [Noul](/primitives/noul) questions in one request."
> "Jev accepts text only. State must be a string, JSON object, or array of text values. Images, audio, and video are not supported (yet). Jev's primary training language is English; other languages, including CJK scripts, are accepted but currently have lower accuracy — see [Models](/models#language-support)."
State format table (state.md): String — "A message, article, or passage"; Object — "Named fields, related records, or application state"; Array — "A sequence of messages or records".
Python questions.md: "`state` is the text or JSON object you want to ask questions about. It cannot be `None`, but values inside an object may be `None`."
JS SystemOneRequestPayload: `state: EntryType;` "Text, a JSON object or array, or `null` to evaluate." (JS SDK type admits `null`; OpenAPI `SystemOneRequest.state` anyOf = string|object|array, no null; Python says it cannot be None. Recorded as a spread, not resolved.)

### Questions structure — verbatim (primitives.md)
> "Every question has an ID, a `type`, and `instructions`. Choice and Score questions also take `criteria`, which define the options for a Choice question or the levels for a Score. Noul questions accept `criteria` as an optional clarification of what yes and no mean."
> "Question IDs are for your code. They are not sent to the model. Write the complete question in `instructions`, even when the ID seems self-explanatory."
> "Send every question that uses the same state in one request. You can mix question types freely. System One models evaluate every question in a request in parallel. Adding questions barely changes the response time and costs only the tokens for the extra questions, which are cheap. Asking a question you might not need is close to free."
> "Questions in the same request are independent: one answer does not become context for another question. If a later judgment depends on an earlier answer, make a second request in code."
Referencing structured state (primitives.md): "When a question is about one of those parts, name it in the `instructions` with a dot-and-index path to its key, including the backticks." Example instruction: "Does `ticket.messages[0].text` request a refund?"

Structured instructions example, verbatim (api.md):
```json
"instructions": {
  "potential_duplicate": {
    "name": "John Smith",
    "location": "Oakland, California",
    "last_employer": "Google"
  },
  "question": "Is the resume for the same person as `potential_duplicate`?"
}
```
Where structure is allowed (primitives/advanced.md table, all rows): `instructions` (Choice, Score, Noul) — "`string`, `object`, `array`, or `null`"; `criteria` values (Choice) — same; `criteria` entries (Score) — same; `criteria.true` and `criteria.false` (Noul) — same.

Score levels (primitives/score.md): "A level's number is its position in the `criteria` array, starting at 0, so the three entries above are levels 0, 1 and 2. The order of the array is the numbering." / "The model gets the descriptions and nothing else, and each level is judged on its own against the state." / "Use as many levels as you can describe distinctly, up to 10. Three is fine."
Choice options (primitives/choice.md): "A Choice question accepts up to 255 options, and adding options costs a few tokens each, so give the model the full list of teams, categories, or products rather than a shortlist."

### Every documented limit (with page)

| Limit | Value | Page (verbatim) |
|---|---|---|
| Context per request | 64k tokens | models.md: "Context length | 64k tokens per request; 32k tokens for `state` plus the longest question" |
| State + longest question | 32k tokens | models.md: "The 64k budget covers the `state` plus all questions combined; the 32k budget applies to the `state` plus the single longest question." |
| Choice options | max 255 | api.md: "You can have a maximum of 255 options per Choice."; choice.md: "up to 255 options"; blog: "Jev supports a cardinality up to 255." |
| Score levels | "at least two"; "up to 10" | api.md: "A Score should have at least two levels; the API accepts up to 10."; score.md same. OpenAPI: `ScoreQuestion.criteria` `"minItems": 1`, no `maxItems` (spread — see Discrepancies) |
| Questions per request | min 1; no max stated | OpenAPI `SystemOneRequest.questions` `"minProperties": 1`; no maximum on any page (only the token budgets) |
| Rate limit (tokens) | 250,000 tokens per second | models.md table (raw HTML verified) |
| Rate limit (requests) | 1,200 requests per minute | models.md table (raw HTML verified); "A request over either limit returns `429 Too Many Requests`." |
| Rate-limit stability | changes without notice | models.md: "**Rate limits are adjusting dynamically.** We are serving a very large volume of demand, and the limits above can change without notice while we do" |
| Input modality | text only | models.md: "Text only. String, JSON object, or array of text values. No image, audio, or video input." |
| Price (input) | $42 / Btok = $0.042 / Mtok; output free | models.md: "Price (per Btok / per Mtok) | $42 / $0.042"; "Charged per input token. Output tokens are free." (meter scope: input tokens, jev-1.13.0, the only listed model) |
| Client timeout (SDK default, not server) | 10.0 s | Python constants: `DEFAULT_TIMEOUT = 10.0` "Default timeout in seconds for each HTTP operation." |
| Server-side timeout / max latency | not documented | (grep `timeout` across api.md, models.md, state.md: no hit) |
| Max state bytes / characters | not documented as bytes; only the token budgets above | — |

Accuracy vs state size (model-jaggedness/jev-1.13.md): "Accuracy falls as the state grows with content unrelated to the decision. Unrelated detail acts as a distractor, and a large state makes it harder to tell which part of the input produced a wrong answer." / "**Context length limit.** `jev-1.13` has a bounded context window. See the [Models](/models) page for the exact token limits." / "Jev suffers from context rot, so unrelated material in the `state` costs you accuracy."

### Every documented error code (api.md "Errors" table; raw HTML of /api checked — same four rows)

| Status | Meaning (verbatim) |
|---|---|
| `401 Unauthorized` | "Missing or invalid API key. Check the `Authorization` header." |
| `422 Unprocessable Entity` | "The request body failed validation — for example a missing required field or a malformed question. The body details the offending field." |
| `429 Too Many Requests` | "You have exceeded your rate limit. Back off and retry after a short delay." |
| `529 Overloaded` | "TypeSafe is temporarily overloaded. Retry after a short delay." |

> "Errors use standard HTTP status codes with a JSON body describing what went wrong."
> "When you receive a `429 Too Many Requests` or `529 Overloaded` response, retry the request with exponential backoff instead of retrying immediately. Our client SDKs handle this automatically, so no extra handling is needed if you use one of our SDKs with its default retry policy."

OpenAPI declares only `200` and `422` per operation; 422 body = `HTTPValidationError` `{ "detail": [ { "loc": [...], "msg": "...", "type": "...", "input": ..., "ctx": {...} } ] }` (`loc`, `msg`, `type` required). Example in spec: `{"loc": ["body","state"], "msg": "Field required", "type": "missing"}`.
SDK exception classes imply more statuses than the API page lists: Python `TypeSafeBadRequestError`, `TypeSafeAuthenticationError` ("Authentication failed (401)."), `TypeSafePermissionDeniedError`, `TypeSafeNotFoundError`, `TypeSafeUnprocessableEntityError` ("The request failed server validation (422)."), `TypeSafeRateLimitError` ("The rate limit was exceeded (429)."; has `retry_after_ms`), `TypeSafeInternalServerError`, `TypeSafeAPIConnectionError`, `TypeSafeAPITimeoutError`, `TypeSafeAPIResponseValidationError` ("A successful HTTP response whose body was missing or structurally invalid required data."). JS: `BadRequestError`, `AuthenticationError`, `PermissionDeniedError`, `NotFoundError`, `UnprocessableEntityError`, `RateLimitError`, `InternalServerError`, `APIConnectionError`, `APITimeoutError`, `APIUserAbortError` (from llms.txt index). => 400/403/404/5xx are handled by SDKs but not documented on the API page (verdict for those: implied).

---

## Discrepancies found (docs vs OpenAPI vs SDK) — recorded, not resolved

1. `instructions` required? api.md marks `instructions` **required** on all three question types. OpenAPI `required` lists: NoulQuestion `["type"]`, ChoiceQuestion `["criteria","type"]`, ScoreQuestion `["criteria","type"]` — `instructions` optional and nullable (`anyOf` includes `{"type":"null"}`). JS SDK: `optional instructions?: EntryType;` "The question as text, a JSON object, or an array; optional or `null`." Python: `instructions (JSONContent | None)`. advanced.md table: `instructions` accepts "`string`, `object`, `array`, or `null`". => Schema and SDKs say optional/nullable; the API reference prose says required.
2. Score level count: api.md/score.md "at least two levels; the API accepts up to 10" vs OpenAPI `ScoreQuestion.criteria` `"minItems": 1` and no `maxItems`. The "up to 10" cap is prose-only (may be enforced server-side beyond the schema; not verifiable without a call).
3. Choice option cap: "maximum of 255 options" is prose-only; OpenAPI `ChoiceQuestion.criteria` has no `maxProperties`.
4. `state` null: JS SDK `EntryType` allows `null`; OpenAPI and Python do not.
5. Probabilities sum: api.md "floats that sum to 1" vs OpenAPI "values sum to approximately 1".
6. Model name in response example: api.md/quickstart examples show `"model": "jev-1.13.0"` (versioned ID); OpenAPI example shows `"jev-latest"`. models.md says the response reports "the versioned ID that answered".
7. Batching speedup figures (count spread, rule 6): llms.txt and cookbooks/parallel_questions.md say "12.2x cheaper and 10.0x faster"; primitives.md says "11.5x cheaper and 9.6x faster than 13 separate calls". Same cookbook, two figures; adopt neither.
8. Cookbook code pins `jev-1.12` pricing comments ("TypeSafe jev-1.12 as of 2026-09") while models.md lists only `jev-1.13.0` — noted for the pricing cluster, not resolved here.

---

## Things I could not find (each with the check that proves I looked)

- **Exact production formula for `confidence`.** confidence.md labels its JS `(count × peak − 1)/(count − 1)` an approximation ("This demo uses … to approximate confidence for three options"); grep `entropy|formula|peak|Math.log` over confidence.md, primitives/choice.md, primitives/score.md, primitives/noul.md found only that demo function. Verdict: unknown.
- **Any calibration measurement (ECE, reliability diagram, accuracy-by-confidence-bucket).** grep `calibrat` across confidence.md (0 hits), machine-learning-primer.md, concepts/system-one.md — definitions only, no numbers. The blog links a "workflow evals site" (not fetched; out of this cluster's scope). Verdict: unknown on docs.
- **Maximum number of questions per request.** grep `maximum|up to|limit` across api.md, primitives.md, models.md, state.md: only 255 options, 10 levels, and the 64k/32k token budgets. OpenAPI: `minProperties: 1`, no `maxProperties`. Verdict: unknown (bounded only by tokens).
- **Server-side timeout / latency SLA.** grep `timeout` in api.md, models.md, state.md: no hit. Only SDK client default (10.0 s). Blog claims "70ms-500ms" end-to-end but that is marketing, not a documented limit. Verdict: unknown.
- **Documented behaviour for `state` over 32k / request over 64k tokens** (which status code). api.md lists 401/422/429/529 only; models.md states the budgets but not the failure mode. Verdict: unknown.
- **OpenAPI spec linked from the docs site.** Raw HTML of /api has `openApiReferenceData":"$undefined"` and no openapi link; /openapi.json, /openapi.yaml, /api/openapi.json, /docs.json on docs.typesafe.ai all 404. Found instead at https://api.typesafe.ai/openapi.json (200). (`https://api.typesafe.ai/docs` also returns 200 text/html — Swagger-style UI, not fetched further.)
- **Homepage FAQ answers** beyond the first ("What are System One Models? What is Jev?"). The Framer page's served HTML contains the FAQ questions but the answer bodies are not in the HTML (each question is immediately followed by the next question in the raw source); only the first answer is rendered. Not recoverable without a browser. Verdict: unknown from raw HTML.
- **Streaming, batch, async/job endpoints.** OpenAPI `paths` = `/v1/systemone`, `/v1/models` only; llms.txt lists no such pages. Verdict: absent (based on the schema, rule 2).
- **Request/response size limits in bytes, request IDs semantics, idempotency keys.** Only `x-typesafe-request-id` (Python `request_id` property) and `retry-after` are documented. Verdict: unknown.

---

## Verification log (rule 4)

94 quotes from the .md/.html sources plus 11 OpenAPI description strings were checked with exact substring matching (python `in`) against the saved curl output in the scratchpad (`jev/*.md`, `openapi.json`, `home_raw.html`, `blog_raw.html`). Result: 94/94 and 11/11 present after three markup-only corrections (the primitives.md sentence carries `**` bold markers; the two blog quotes span `<em>`/`<strong>` tags and use curly apostrophes — noted inline above). OpenAPI constraint values quoted (`minItems: 1`, no `maxItems`, no `maxProperties`, `minProperties: 1`, the `required` arrays, `instructions` anyOf including `null`) were read from the parsed JSON. Tables from models.md and api.md were re-extracted from raw HTML (`<tr>/<td>` cells): models table 8 rows and api Errors table 4 rows both matched the Markdown cell-for-cell.
