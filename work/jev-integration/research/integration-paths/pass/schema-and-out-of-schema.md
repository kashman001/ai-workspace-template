# integration-paths / schema-and-out-of-schema — raw findings

Subject: Jev (TypeSafe, typesafe.ai). Questions Q4 (schema declaration) and Q5
(out-of-schema behaviour). Date checked: 2026-09-23. Method: `curl -sL` of the
docs site's own markdown renderings (`https://docs.typesafe.ai/<path>.md`, served
HTTP 200 by the docs site itself) plus served-HTML re-checks of the load-bearing
pages; every quote below was grep-counted against the fetched file. No accounts,
keys, API calls, or Chrome tools were used.

Orientation: `https://docs.typesafe.ai/llms.txt` (HTTP 200) is the full nav
index; `https://docs.typesafe.ai/llms-full.txt` (910 KB, HTTP 200) is the whole
corpus in one file and was used for corpus-wide greps. No OpenAPI spec is
published at the paths tried (`/openapi.json`, `/api-reference/openapi.json`
both 404); the HTTP reference is the single page `https://docs.typesafe.ai/api`.

## Claims

### Q4 — how a decision schema is declared; single vs multi-label; closed choice vs free text

| # | Claim (one sentence) | Verdict | Source URL (the page, not the site) | Date checked | How verified | Documented vs. implied |
|---|---|---|---|---|---|---|
| 4.1 | The schema is declared per request as a `questions` map whose values are JSON objects with `type` (`"noul"`, `"choice"`, or `"score"`), `instructions`, and a type-specific `criteria`; it is not JSON Schema, not an enum type, and not a Pydantic/Zod schema. | documented | https://docs.typesafe.ai/api | 2026-09-23 | Read the "Request body" and "Question types" sections of `/api.md`; confirmed the same four-field shape in the quickstart request body. | Documented. (The Python SDK's `Choice`/`Score`/`Noul` classes and the TS `ChoiceQuestion<T>` interface are typed wrappers over exactly this shape, not an alternative schema language.) |
| 4.2 | A Choice declares its options as a map from option name to description, where each description is `string \| object \| array \| null`, with a maximum of 255 options per Choice. | documented | https://docs.typesafe.ai/api | 2026-09-23 | `ParamField body="criteria" type="map<string, string \| object \| array \| null>"` and "You can have a maximum of 255 options per Choice." on `/api.md`; "up to 255 options" also on `/primitives/choice` (HTML count 3). | Documented |
| 4.3 | A Score declares its levels as an ordered array of level descriptions, at least two, and the API accepts up to 10. | documented | https://docs.typesafe.ai/api | 2026-09-23 | `ParamField body="criteria" type="array<string \| object \| array>"` + "A Score should have at least two levels; the API accepts up to 10." (HTML count 2). | Documented |
| 4.4 | A Noul is a yes/no question with required `instructions` and optional `criteria.true` / `criteria.false` descriptions of what yes and no mean. | documented | https://docs.typesafe.ai/api | 2026-09-23 | "### Noul" section of `/api.md`. | Documented |
| 4.5 | `instructions` and every `criteria` value accept JSON structure (`string`, `object`, `array`, or `null`), so natural-language options, structured rubrics, or a taxonomy fragment can all be passed. | documented | https://docs.typesafe.ai/primitives/advanced | 2026-09-23 | "Where structure is allowed" table on `/primitives/advanced.md`; `/api.md` repeats "The `instructions` property can be a string, an object, or an array." | Documented |
| 4.6 | Choice is single-label: the answer's `choice` is "The highest-probability option", and the docs describe Choice as "selecting one option from a defined set". | documented | https://docs.typesafe.ai/api | 2026-09-23 | `ResponseField name="choice" type="string" required` "The highest-probability option." on `/api.md`; page description on `/primitives/choice` (HTML count 16, md 1). | Documented |
| 4.7 | There is no multi-label mode on Choice; the documented way to allow several labels to apply is one Noul per label. | documented | https://docs.typesafe.ai/model-jaggedness/jev-1.13 | 2026-09-23 | Jaggedness page: "A Choice over options and one Noul per option answer different questions: the Choice is relative, settling *which* option, while each Noul is absolute and can be low for all of them." Official SKILL.md on GitHub: "use one per label when several may apply". Corpus grep for `multi-label`/`multilabel` = 0 hits in `llms-full.txt`. | Documented (positive guidance); the *absence* of a multi-label flag rests on the `/api` reference listing no such field. |
| 4.8 | Jev is strictly closed-choice: it does not generate text, and the docs say to turn extraction into a Choice over enumerated candidates (found by regex or a generative model) rather than asking for the value. | documented | https://docs.typesafe.ai/model-jaggedness/jev-1.13 | 2026-09-23 | "## Generation" section: "`jev-1.13` is not trained to generate text." (HTML count 2) and "turn extraction into a [Choice] over the options rather than asking for the value itself." | Documented |
| 4.9 | The response is `{ "model": <versioned id>, "answers": { <same ids> : Answer }, "usage": { "input_tokens", "output_tokens" } }`. | documented | https://docs.typesafe.ai/api | 2026-09-23 | "Response body" section; verbatim examples in section 2 below. | Documented |
| 4.10 | A Choice answer is `{ "type": "choice", "choice": string, "probabilities": map<option, number> (floats that sum to 1), "confidence": number }`, with `confidence` in 0–1 "derived from the answer's probability distribution". | documented | https://docs.typesafe.ai/api | 2026-09-23 | "### Choice answer" ResponseFields; "floats that sum to 1" (HTML count 4); "Choice and Score answers also carry a `confidence` between 0 to 1, derived from the answer's probability distribution." | Documented |
| 4.11 | A Score answer is `{ "type": "score", "score": number (probability-weighted, can land between levels), "legend": map<level-index-string, description>, "probabilities": map<level-index-string, number>, "confidence": number }`. | documented | https://docs.typesafe.ai/api | 2026-09-23 | "### Score answer" ResponseFields; example `"score": 1.05`. | Documented |
| 4.12 | A Noul answer is `{ "type": "noul", "noul": number }` on a 0 (no) to 1 (yes) scale, and carries no `confidence` field. | documented | https://docs.typesafe.ai/api | 2026-09-23 | "### Noul answer"; `/confidence`: "(Noul answers don’t carry one.)" (HTML count 3, curly apostrophe); `/primitives`: "Noul has no separate `confidence`." (HTML count 3). | Documented |
| 4.13 | The exact formula for `confidence` is not published; the Confidence page says it is computed "from how the probability is spread across the options" and its interactive demo uses `(3 × largest probability − 1) / 2` "to approximate confidence for three options" (the demo's code generalises this to `(count × peak − 1) / (count − 1)`, clamped to 0–1). | documented (derivation); unknown (official closed form) | https://docs.typesafe.ai/confidence | 2026-09-23 | Read the `ConfidenceExplorer` component source and the "How this demo calculates Confidence" note in `/confidence.md`; no other page states a formula (corpus grep for the demo expression). | Documented that it is derived from `probabilities`; the closed form is the demo's approximation, so treat the exact function as undisclosed. |
| 4.14 | Question ids are chosen by the caller, echoed back as the `answers` keys, and are not sent to the model. | documented | https://docs.typesafe.ai/api | 2026-09-23 | "The key is not sent to the underlying model and is not used in inference." | Documented |
| 4.15 | `state` may be a string, a JSON object, or an array (the JS SDK also accepts `null`); text only, no image/audio/video. | documented | https://docs.typesafe.ai/api | 2026-09-23 | `ParamField body="state" type="string \| object \| array"`; JS `SystemOneRequestPayload.state: EntryType` "Text, a JSON object or array, or `null` to evaluate."; `/models`: "Text only. String, JSON object, or array of text values." | Documented |
| 4.16 | In the JS SDK the option type is inferred from the `criteria` keys (`ChoiceQuestion<T extends ChoiceCriteria>`, `ChoiceResponse.choice: keyof T & string`); in the Python SDK `Choice.criteria` is a `Mapping` and answers are Pydantic models. | documented | https://docs.typesafe.ai/sdk/javascript/api/interfaces/ChoiceResponse | 2026-09-23 | Read `ChoiceResponse.md`, `ChoiceQuestion.md`; Python `sdk/python/api/types/questions.md` (`Mapping[...]`) and `responses.md` (`pydantic-model` markers, `"confidence"` description "from 0 to 1"). | Documented. Note: Pydantic/TS generics are how the *SDKs* type the criteria map; the wire format is claim 4.1. |

### Q5 — behaviour on inputs outside the schema; thresholds; unsure/other/reject; HTTP errors

| # | Claim (one sentence) | Verdict | Source URL (the page, not the site) | Date checked | How verified | Documented vs. implied |
|---|---|---|---|---|---|---|
| 5.1 | The API never abstains, returns null, or errors because an input does not fit the declared options: every Choice answer carries a required `choice` (the highest-probability option) and a distribution over exactly the declared options, and every Score answer a required `score` within the declared levels. | documented | https://docs.typesafe.ai/api | 2026-09-23 | `ResponseField name="choice" type="string" required`, `probabilities` "Every option mapped to its probability (floats that sum to 1)", `score` required. No abstain/null/reject field exists in the Answer types. Corpus grep: `abstain` = 3 hits, all in cookbook *client* code (`choice_decision_with_uncertainty` in `consistency_choice_cookbook`), none in the API. | Absence claim rests on the `/api` reference's Answer types (rule 2). |
| 5.2 | The documented mechanism for "none of the above" is to declare it yourself as an option: "Add an `other` or `none of the above` option when the list might not cover every input, so the model can say none of the others fit." | documented | https://docs.typesafe.ai/primitives/choice | 2026-09-23 | Quote on `/primitives/choice.md` (HTML count for "none of the above" = 16, md 6); repeated on `/primitives` ("Give the full list of options, and add an `other` or `none of the above` option when the list might not cover every input.", HTML count 3); official SKILL.md: "Include a no-match outcome when nothing may fit". | Documented |
| 5.3 | The second documented out-of-schema mechanism is confidence gating in caller code: "Confidence gives you a built-in mechanism for the model to say "I'm not sure about this one."" | documented | https://docs.typesafe.ai/confidence | 2026-09-23 | "## “I don't know” is a useful signal" section (HTML count for "is a useful signal" = 5). | Documented |
| 5.4 | Documented threshold guidance is a three-band pattern — high confidence: "Act automatically"; medium: "Proceed with caution" (confirm/flag/gather more); low: "Do not act" (route to a human, clarify, fall back) — with the explicit caveat that boundaries "depend on the stakes" and "The correct threshold values depend on your domain and the performance of the model for your use case." | documented | https://docs.typesafe.ai/confidence | 2026-09-23 | "## Three paths for using confidence in your code" and "## Thresholds scale with risk" ("Act automatically" HTML count 3, "Do not act" 3, "A confidence threshold is not one number" 3, "Start with conservative thresholds" 3). | Documented |
| 5.5 | The numeric thresholds in the docs are worked examples, not product recommendations: `confidence < 0.5` → human (Confidence page, Intent-routing pattern), `< 0.6` floor and `> 0.85` for a high-stakes action (Confidence-gated routing pattern), top probability `>= 0.60` else `"uncertain"` (Self-consistency cookbook). | documented | https://docs.typesafe.ai/patterns/confidence-routing | 2026-09-23 | Code blocks on `/confidence.md` (0.5, 0.9), `/patterns/confidence-routing.md` (0.6, 0.85), `/patterns/intent-routing.md` (0.5), `/cookbooks/consistency_choice_cookbook.md` (`MIN_CHOICE_PROBABILITY = 0.60  # illustrative automatic-action threshold`). SKILL.md: "Treat cookbook thresholds and demo results as examples to evaluate, not universal rules". | Documented as examples; no page states a product-level default threshold. |
| 5.6 | For Noul there is no confidence field; the docs say to threshold `noul` in code, "Use 0.5 when yes and no are equally easy to act on", raise it when a false yes is expensive, lower it when a missed yes is expensive; "near 0.5 uncertain". | documented | https://docs.typesafe.ai/primitives/noul | 2026-09-23 | Lines "Most often your code thresholds `noul` into a boolean" and "Where to set the threshold depends on the cost of being wrong. Use 0.5 when yes and no are equally easy to act on." on `/primitives/noul.md`. | Documented |
| 5.7 | A third documented mechanism for "should I act at all" is to pair a relative Choice with absolute Nouls: "the Choice to pick a skill and the Nouls to decide whether to suggest one at all". | documented | https://docs.typesafe.ai/model-jaggedness/jev-1.13 | 2026-09-23 | Quote in "## Common-sense structural invariants" (corpus count 1); it points at `/cookbooks/skill_suggestion`. | Documented |
| 5.8 | Cookbooks put the escape hatch in the option list: date extraction adds "an explicit "not stated" option so a missing part is reported rather than guessed", and pre-parsed value extraction defines `NONE = "none"  # the escape hatch on every selection: "none of the candidates fits"`. | documented | https://docs.typesafe.ai/model-jaggedness/jev-1.13 | 2026-09-23 | "not stated" on jaggedness page (HTML count 2); `NONE = "none"` line under the `# Pre-parsed value extraction` heading in `llms-full.txt` (page: https://docs.typesafe.ai/cookbooks/pre_parsed_value_extraction_cookbook). | Documented |
| 5.9 | Confidence thresholds are version-sensitive: aliases move on release, and the docs say "If you have tuned confidence thresholds against a specific version, pin that version's ID instead of the alias." | documented | https://docs.typesafe.ai/models | 2026-09-23 | "## Aliases" section of `/models.md`. | Documented |
| 5.10 | A malformed or invalid schema is a request-validation failure returning HTTP `422 Unprocessable Entity` ("a missing required field or a malformed question. The body details the offending field."). | documented | https://docs.typesafe.ai/api | 2026-09-23 | "## Errors" table (HTML count for "422 Unprocessable Entity" = 2). | Documented |
| 5.11 | The HTTP reference's error table lists exactly four statuses: `401 Unauthorized`, `422 Unprocessable Entity`, `429 Too Many Requests`, `529 Overloaded`; 429/529 should be retried with exponential backoff. | documented | https://docs.typesafe.ai/api | 2026-09-23 | "## Errors" table and "### Handling rate limits" (HTML counts: 401=2, 422=2, 429=4, 529=4, "Handling rate limits"=4). | Documented |
| 5.12 | The SDK references model more statuses than the HTTP reference lists: Python defines `TypeSafeBadRequestError` (400), `TypeSafeAuthenticationError` (401), `TypeSafePermissionDeniedError` (403), `TypeSafeNotFoundError` (404), `TypeSafeUnprocessableEntityError` (422), `TypeSafeRateLimitError` (429); JS additionally `InternalServerError`; the Python default retry set is `{429, 500, 502, 503, 504}`. | documented (spread) | https://docs.typesafe.ai/sdk/python/api/exceptions | 2026-09-23 | Read `/sdk/python/api/exceptions.md` ("The request was invalid (400)." etc.); JS `APIError.md` "Extended by" list; `/sdk/python/api/retries.md` line `http_statuses={429, 500, 502, 503, 504}`. | Documented — a count spread per rule 6: 4 statuses on `/api`, 6–7 in the SDKs; recorded, not resolved. |
| 5.13 | The JSON shape of an error body is not shown anywhere in the docs; only "a JSON body describing what went wrong" and "The body details the offending field" are stated. | unknown | https://docs.typesafe.ai/api | 2026-09-23 | Corpus grep of `llms-full.txt` for `"detail"`, `"error"`, `error body`, `offending field`: the only hits are the `/api` sentence and unrelated example state; SDK pages say `body` is "The server's JSON error body, plain response text, or `None`". Pages checked are listed in section 4. | Unknown; an authenticated 422 would settle it. |
| 5.14 | Out-of-distribution *state* (irrelevant, adversarial, or contradictory input) does not trigger an error or abstention; the docs say accuracy degrades and adversarial content "can move the answer", and the remedy is precise criteria, filtering in code, and testing. | documented | https://docs.typesafe.ai/model-jaggedness/jev-1.13 | 2026-09-23 | "## Adversarial content": "State is data, and `jev-1.13` does not treat it as hostile by default." (HTML count 2); "## Large state full of irrelevant detail": "Accuracy falls as the state grows with content unrelated to the decision." | Documented |
| 5.15 | There is no Score-specific guidance for a "not applicable" level; Score is bounded by the declared levels (`score` is the probability-weighted mean of level indices) and the docs' escape-hatch advice is stated for Choice only. | unknown (Score N/A guidance) | https://docs.typesafe.ai/primitives/score | 2026-09-23 | Grep of `/primitives/score.md` for `not applicable`, `none of`, `fallback`, `abstain`, `doesn't apply` = 0 hits; `/api` `score` "The probability-weighted answer across the levels; can land between levels." | Absence of guidance is anchored on `/primitives/score` and `/api`; whether adding an N/A level to a Score is sensible is not addressed. |
| 5.16 | Reading the marketing "Zero Hallucinations" / "can't hallucinate" claim against the reference, what is guaranteed is *type* safety — the answer is always one of the declared options with a distribution — not correctness; the same vendor's jaggedness page lists nine failure modes for `jev-1.13`. | implied | https://typesafe.ai/blog/introducing-system-one-models-and-jev | 2026-09-23 | Blog: "While Jev gives up string generation, it’s optimized for structured outputs and can’t hallucinate." and "Hallucination and type-safety are intrinsically related"; homepage "Zero Hallucinations Every Jev decision comes with a confidence estimate, so your software can act when confidence is high and escalate when it is not."; SKILL.md: "Typed output guarantees the interface, not truth." | Implied: the blog links hallucination to type-safety; the SKILL.md sentence is the closest to an explicit statement. The reference never uses "hallucinat" about Jev's own answers. |

## Request and response shapes

All verbatim. Source: https://docs.typesafe.ai/introduction/quickstart (markdown rendering `https://docs.typesafe.ai/introduction/quickstart.md`, HTTP 200; served HTML re-checked: `api.typesafe.ai/v1/systemone` count 4, `jev-1.13.0` 2, `0.78` 2).

Endpoint:

```http
POST https://api.typesafe.ai/v1/systemone
Authorization: Bearer <API_KEY>
Content-Type: application/json
```

Request body (all three question types in one call):

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

Response body:

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

Source: https://docs.typesafe.ai/api (`/api.md`). Field-level definitions from the reference's ParamField/ResponseField blocks. The quoted description strings are verbatim (each grep-counted); the two-column layout is mine, markdown link markup is removed (e.g. "One [Answer](#answer-types) per question" is shown as "One Answer per question"), and `...` marks an elision.

Request:

```text
state      string | object | array   required  The content to evaluate. A plain string for text, or structured data (object/array) ...
model      string                    required  The model that handles the request. Use "jev-latest" ...
questions  map<string, Question>     required  A map of typed Question objects. You choose each key; answers come back under the same keys.

Noul   : type "noul"   required; instructions string | object | array required; criteria object (optional) { true: string | object | array; false: string | object | array }
Choice : type "choice" required; instructions string | object | array required; criteria map<string, string | object | array | null> required  — "A map of option to rubric description; use null when an option needs no extra detail. You can have a maximum of 255 options per Choice."
Score  : type "score"  required; instructions string | object | array required; criteria array<string | object | array> required — "An ordered array of level descriptions. A Score should have at least two levels; the API accepts up to 10."
```

Response:

```text
model    string               required  The model that performed the evaluation.
answers  map<string, Answer>  required  One Answer per question, keyed by the same ids you used in questions.
usage    object               required  { input_tokens: integer, output_tokens: integer }

Noul answer  : type "noul";   noul number required — "The yes/no answer on a scale from 0 (no) to 1 (yes)."
Choice answer: type "choice"; choice string required — "The highest-probability option."; probabilities map<string, number> required — "Every option mapped to its probability (floats that sum to 1)."; confidence number required — "How certain the model is, derived from probabilities."
Score answer : type "score";  score number required — "The probability-weighted answer across the levels; can land between levels."; legend map<string, string> required; probabilities map<string, number> required — "Each level (string key) mapped to its probability (floats that sum to 1)."; confidence number required
```

Reference's own Choice and Score answer examples:

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

Structured instructions (reference example of JSON in `instructions`):

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

Errors table, verbatim from https://docs.typesafe.ai/api:

```text
| Status                     | Meaning                                                                                                                                  |
| `401 Unauthorized`         | Missing or invalid API key. Check the `Authorization` header.                                                                            |
| `422 Unprocessable Entity` | The request body failed validation — for example a missing required field or a malformed question. The body details the offending field. |
| `429 Too Many Requests`    | You have exceeded your rate limit. Back off and retry after a short delay.                                                               |
| `529 Overloaded`           | TypeSafe is temporarily overloaded. Retry after a short delay.                                                                           |
```

JS SDK typed shapes, verbatim (https://docs.typesafe.ai/sdk/javascript/api/interfaces/ChoiceResponse, .../ChoiceQuestion, .../NoulResponse):

```ts
// ChoiceQuestion<T extends ChoiceCriteria>
criteria: T;                       // Descriptions of the available outcomes.
optional instructions?: EntryType; // The question as text, a JSON object, or an array; optional or `null`.
type: "choice";

// ChoiceResponse<T>
readonly choice: keyof T & string;   // The selected label.
readonly confidence: number;         // Reported confidence in the selected label.
readonly probabilities: { readonly [label in string | number | symbol]: number };
readonly type: "choice";

// NoulResponse
readonly noul: number;               // Probability of a yes answer, from zero to one.
readonly type: "noul";
```

Python SDK answer-model descriptions, verbatim from https://docs.typesafe.ai/sdk/python/api/types/responses:

```text
choice:      "The name of the choice with the highest probability among the question's criteria."
confidence:  "Confidence in the selected choice, from 0 to 1. Higher values indicate greater certainty; use lower values to flag uncertain selections for review."
probabilities: "Probability of each choice in criteria, keyed by choice name, from 0 to 1. Shows how likely the alternatives are; values sum to approximately 1."
score:       "Expected score: the probability-weighted average of the rubric levels. May fall between integer levels."
```

Threshold example code, verbatim from https://docs.typesafe.ai/patterns/confidence-routing:

```python
action = response.answers["intent"]

# Below 0.6 confidence on any action, route to a human
if action.confidence < 0.6:
    route_to_support_agent(account_id)

elif action.choice == "check_balance":
    # Low stakes. 0.6 confidence is sufficient.
    show_balance(account_id)

elif action.choice == "approve_transfer":
    if action.confidence > 0.85:
        # High stakes, but high confidence. Safe to act automatically.
        approve_transfer(account_id)
    else:
        # High stakes, moderate confidence. Verify intent first.
        ask_user_to_confirm("Just to confirm: you would like to approve this transfer, is that correct?")

else:
    route_to_support_agent(account_id)
```

## Evidence quotes

Format: quote — URL — grep count (`md` = the page's `.md` rendering; `html` = served HTML of the same page; `corpus` = `llms-full.txt`).

Q4:

1. "Picks one option from a set you define. Returns the chosen option and the full probability distribution." — https://docs.typesafe.ai/api — md 1.
2. "You can have a maximum of 255 options per Choice." — https://docs.typesafe.ai/api — md 1; "maximum of 255 options" html 2.
3. "An ordered array of level descriptions. A Score should have at least two levels; the API accepts up to 10." — https://docs.typesafe.ai/api — md 1; "the API accepts up to 10" html 2.
4. "The key is not sent to the underlying model and is not used in inference." — https://docs.typesafe.ai/api — md 1.
5. "Every answer carries a `type` matching its question. Choice and Score answers also carry a `confidence` between 0 to 1, derived from the answer's probability distribution." — https://docs.typesafe.ai/api — md 1.
6. "The highest-probability option." — https://docs.typesafe.ai/api — md 1, html 2.
7. "Every option mapped to its probability (floats that sum to 1)." — https://docs.typesafe.ai/api — "floats that sum to 1" md 2, html 4.
8. "The probability-weighted answer across the levels; can land between levels." — https://docs.typesafe.ai/api — md 1.
9. "A Choice is a System One question type for selecting one option from a defined set. The answer includes the selected option, a probability for each option, and confidence." — https://docs.typesafe.ai/primitives/choice — "selecting one option from a defined set" md 1, html 16.
10. "`jev-1.13` is not trained to generate text. While you can force it to by chaining choices, this will not work well and will be very slow. For data extraction, it is better to extract possible options using regex or a generative model and let `jev-1.13` pick the correct extraction." — https://docs.typesafe.ai/model-jaggedness/jev-1.13 — "is not trained to generate text" md 1, html 2.
11. "A Choice over options and one Noul per option answer different questions: the Choice is relative, settling *which* option, while each Noul is absolute and can be low for all of them." — https://docs.typesafe.ai/model-jaggedness/jev-1.13 — md 1.
12. "| Whether a condition holds | [Noul](https://docs.typesafe.ai/primitives/noul.md) | Probability of yes; no separate confidence; use one per label when several may apply |" — https://github.com/typesafe-ai/skills/blob/main/skills/typesafe-ai/SKILL.md (raw fetched) — 1.
13. "TypeSafe computes confidence from how the probability is spread across the options. All of it on one option gives 1.0; the more evenly it spreads, the lower the confidence. This demo uses <code>(3 × largest probability − 1) / 2</code> to approximate confidence for three options." — https://docs.typesafe.ai/confidence — md 1.
14. "Every one of these fields is an [`EntryType`]" + table rows `string`, `object`, `array`, or `null` for `instructions` and all `criteria` values — https://docs.typesafe.ai/primitives/advanced — md 1.

Q5:

15. "Add an `other` or `none of the above` option when the list might not cover every input, so the model can say none of the others fit." — https://docs.typesafe.ai/primitives/choice — md 1; "none of the above" html 16.
16. "Give the full list of options, and add an `other` or `none of the above` option when the list might not cover every input." — https://docs.typesafe.ai/primitives — md 1; "none of the above" html 3.
17. "Confidence gives you a built-in mechanism for the model to say "I'm not sure about this one." This lets your code implement different behavior for different levels of certainty, which is the foundation for building systems you can actually rely on." — https://docs.typesafe.ai/confidence — md 1; heading "is a useful signal" html 5.
18. "**High confidence:** Act automatically. The model has a clear read and you can proceed without human involvement." — https://docs.typesafe.ai/confidence — "Act automatically" md 1, html 3.
19. "**Low confidence:** Do not act. Route to a human, request clarification, or fall back to a different system. The model is telling you it does not have enough information or the question is not a good fit." — https://docs.typesafe.ai/confidence — "Do not act" md 1, html 3.
20. "A confidence threshold is not one number. Different actions within the same system should be gated at different levels depending on the consequences of getting it wrong." — https://docs.typesafe.ai/confidence — md 1, html 3.
21. "The correct threshold values depend on your domain and the performance of the model for your use case. Start with conservative thresholds, test with your own data, and adjust as you observe results." — https://docs.typesafe.ai/confidence — "Start with conservative thresholds" md 1, html 3.
22. "The 0.6 floor catches anything the model is genuinely uncertain about. Above that floor, each action type has its own threshold based on the consequences of acting on a wrong classification." — https://docs.typesafe.ai/patterns/confidence-routing — md 1.
23. "Where to set the threshold depends on the cost of being wrong. Use 0.5 when yes and no are equally easy to act on." — https://docs.typesafe.ai/primitives/noul — md 1.
24. "Near 1 is a strong yes, near 0 a strong no, near 0.5 uncertain. Noul has no separate `confidence`." — https://docs.typesafe.ai/primitives — "Noul has no separate" md 1, html 3.
25. "(Noul answers don't carry one.)" — https://docs.typesafe.ai/confidence — md 1 (straight apostrophe); html 3 as "answers don’t carry one" (curly apostrophe).
26. "The [skill suggestion cookbook](/cookbooks/skill_suggestion) uses both on the same shortlist, the Choice to pick a skill and the Nouls to decide whether to suggest one at all." — https://docs.typesafe.ai/model-jaggedness/jev-1.13 — corpus 1.
27. "it gives you somewhere to put an explicit "not stated" option so a missing part is reported rather than guessed." — https://docs.typesafe.ai/model-jaggedness/jev-1.13 — "not stated" md 1, html 2.
28. `NONE = "none"  # the escape hatch on every selection: "none of the candidates fits"` — https://docs.typesafe.ai/cookbooks/pre_parsed_value_extraction_cookbook — corpus 1 (under the `# Pre-parsed value extraction` heading).
29. `MIN_CHOICE_PROBABILITY = 0.60  # illustrative automatic-action threshold` — https://docs.typesafe.ai/cookbooks/consistency_choice_cookbook — md 1.
30. "Treat cookbook thresholds and demo results as examples to evaluate, not universal rules or permanent model limitations." — SKILL.md (raw GitHub) — 1.
31. "Include a no-match outcome when nothing may fit; use a separate presence judgment when it is independently useful. For source-value selection, check candidate coverage: the model cannot choose an omitted value." — SKILL.md (raw GitHub) — 1.
32. "Typed output guarantees the interface, not truth. System One models are trained for calibrated decisions; validate their performance in the target domain." — SKILL.md (raw GitHub) — 1.
33. "If you have tuned confidence thresholds against a specific version, pin that version's ID instead of the alias and move to the new one on your own schedule." — https://docs.typesafe.ai/models — md 1.
34. "Errors use standard HTTP status codes with a JSON body describing what went wrong." — https://docs.typesafe.ai/api — md 1.
35. "The request body failed validation — for example a missing required field or a malformed question. The body details the offending field." — https://docs.typesafe.ai/api — md 1; "422 Unprocessable Entity" html 2.
36. "When you receive a `429 Too Many Requests` or `529 Overloaded` response, retry the request with exponential backoff instead of retrying immediately." — https://docs.typesafe.ai/api — md 1; "529 Overloaded" html 4.
37. "The request was invalid (400)." / "Access was denied (403)." / "The resource was not found (404)." / "The request failed server validation (422)." / "The rate limit was exceeded (429)." — https://docs.typesafe.ai/sdk/python/api/exceptions — md 1 each.
38. `max_retries=3, timeout=10.0, http_statuses={429, 500, 502, 503, 504}` — https://docs.typesafe.ai/sdk/python/api/retries — md 1.
39. "State is data, and `jev-1.13` does not treat it as hostile by default. Content written to adversarially steer the model, whether that is an injected instruction, a deliberately misleading framing, or text that argues for its own classification, can move the answer." — https://docs.typesafe.ai/model-jaggedness/jev-1.13 — "does not treat it as hostile by default" md 1, html 2.
40. "Accuracy falls as the state grows with content unrelated to the decision." — https://docs.typesafe.ai/model-jaggedness/jev-1.13 — md 1.
41. "**Applies to `jev-1.13`.** Last reviewed 2026-09-17." — https://docs.typesafe.ai/model-jaggedness/jev-1.13 — "Last reviewed 2026-09-17" md 1, html 2.
42. "Zero Hallucinations Every Jev decision comes with a confidence estimate, so your software can act when confidence is high and escalate when it is not." — https://typesafe.ai/ — "Zero Hallucinations" 2, "confidence estimate" 2 (tags stripped; the two phrases are adjacent elements).
43. "While Jev gives up string generation, it’s optimized for structured outputs and can’t hallucinate." — https://typesafe.ai/blog/introducing-system-one-models-and-jev — "hallucinate" 6, "typed probabilistic decisions out" 2 (Framer page inlines each passage twice).
44. "Hallucination and type-safety are intrinsically related, and we think the latter is table stakes for automation." — https://typesafe.ai/blog/introducing-system-one-models-and-jev — present (tags stripped).
45. "Existing models, *no matter how smart*, still hallucinate and have type errors." — https://typesafe.ai/blog/introducing-system-one-models-and-jev — "still hallucinate and have type errors" 2 (the italic phrase is an `<em>` element in the source, so a tag-stripped grep matches only with a space before the comma: "smart , still").

## Reference pages checked for Q5

Read in full or grepped for abstain / none-of-the-above / other / fallback / unsure / reject / null / not applicable / threshold / error / 4xx-5xx:

- https://docs.typesafe.ai/api (HTTP reference: request, question types, answer types, errors) — read in full; served HTML re-checked.
- https://docs.typesafe.ai/introduction/quickstart — read in full; served HTML re-checked.
- https://docs.typesafe.ai/primitives — grepped; served HTML re-checked.
- https://docs.typesafe.ai/primitives/choice — grepped; served HTML re-checked.
- https://docs.typesafe.ai/primitives/score — grepped (0 hits for N/A-style guidance).
- https://docs.typesafe.ai/primitives/noul — grepped.
- https://docs.typesafe.ai/primitives/advanced — "Where structure is allowed" read.
- https://docs.typesafe.ai/confidence — read in full; served HTML re-checked.
- https://docs.typesafe.ai/patterns/confidence-routing — thresholds read.
- https://docs.typesafe.ai/patterns/intent-routing — thresholds grepped.
- https://docs.typesafe.ai/models — read in full.
- https://docs.typesafe.ai/model-jaggedness/jev-1.13 — read in full; served HTML re-checked.
- https://docs.typesafe.ai/sdk/python/api/exceptions — read in full.
- https://docs.typesafe.ai/sdk/python/api/retries — grepped for status sets.
- https://docs.typesafe.ai/sdk/python/api/types/questions and .../responses — grepped for types and field descriptions.
- https://docs.typesafe.ai/sdk/javascript/api/classes/APIError and .../UnprocessableEntityError — read.
- https://docs.typesafe.ai/sdk/javascript/api/interfaces/ChoiceResponse, ChoiceQuestion, ScoreResponse, NoulResponse, SystemOneRequestPayload — read.
- https://docs.typesafe.ai/cookbooks/consistency_choice_cookbook — "uncertain" mechanism grepped (it is client-side thresholding on `max(probabilities)`, not an API feature).
- https://docs.typesafe.ai/llms-full.txt — corpus-wide greps: `abstain` 3 (all cookbook client code), `none of the above` 5, `multi-label`/`multilabel` 0, `catch-all` 0, `escape hatch` 2, `not stated` 1, `JSON Schema` 13 (all inside the SDE-cascade cookbook, describing the *LLM* baseline's output schema — not a Jev declaration mechanism), `pydantic` 40 (all in the Python SDK reference).
- https://raw.githubusercontent.com/typesafe-ai/skills/main/skills/typesafe-ai/SKILL.md — the vendor's official agent skill, read lines 96–150.
- Tried and 404: https://docs.typesafe.ai/openapi.json, https://docs.typesafe.ai/api-reference/openapi.json, https://docs.typesafe.ai/api-reference.md, https://docs.typesafe.ai/api-reference/errors.md, https://docs.typesafe.ai/errors.md, https://docs.typesafe.ai/reference.md.

## Fetch log

All via `curl -sL -A "Mozilla/5.0" -o <file> -w "%{http_code}" <url>` on 2026-09-23.

| HTTP | URL | Bytes |
|---|---|---|
| 200 | https://docs.typesafe.ai/ | 276036 |
| 200 | https://docs.typesafe.ai/llms.txt | 16019 |
| 200 | https://docs.typesafe.ai/llms-full.txt | 910292 |
| 200 | https://docs.typesafe.ai/sitemap.xml | 15616 |
| 404 | https://docs.typesafe.ai/openapi.json | 15 |
| 404 | https://docs.typesafe.ai/api-reference/openapi.json | 15 |
| 200 | https://typesafe.ai/ | 590563 |
| 200 | https://typesafe.ai/blog/introducing-system-one-models-and-jev | 258883 |
| 200 | https://docs.typesafe.ai/introduction.md | 4317 |
| 200 | https://docs.typesafe.ai/introduction/quickstart.md | 7053 |
| 200 | https://docs.typesafe.ai/primitives.md | 24810 |
| 200 | https://docs.typesafe.ai/primitives/choice.md | 26794 |
| 200 | https://docs.typesafe.ai/primitives/score.md | 43992 |
| 200 | https://docs.typesafe.ai/primitives/noul.md | 27363 |
| 200 | https://docs.typesafe.ai/primitives/advanced.md | 19060 |
| 200 | https://docs.typesafe.ai/confidence.md | 11396 |
| 200 | https://docs.typesafe.ai/patterns/confidence-routing.md | 12168 |
| 200 | https://docs.typesafe.ai/concepts/state.md | 3874 |
| 404 | https://docs.typesafe.ai/api-reference.md | 539 |
| 404 | https://docs.typesafe.ai/api-reference/errors.md | 626 |
| 404 | https://docs.typesafe.ai/errors.md | 645 |
| 404 | https://docs.typesafe.ai/reference.md | 524 |
| 200 | https://docs.typesafe.ai/api.md | 11772 |
| 200 | https://docs.typesafe.ai/models.md | 7245 |
| 200 | https://docs.typesafe.ai/model-jaggedness/jev-1.13.md | 11588 |
| 200 | https://docs.typesafe.ai/sdk/python/api/exceptions.md | 7059 |
| 200 | https://docs.typesafe.ai/sdk/python/api/types/questions.md | 30016 |
| 200 | https://docs.typesafe.ai/sdk/python/api/types/responses.md | 38625 |
| 200 | https://docs.typesafe.ai/sdk/python/api/retries.md | 15732 |
| 200 | https://docs.typesafe.ai/sdk/javascript/api/interfaces/ChoiceResponse.md | 982 |
| 200 | https://docs.typesafe.ai/sdk/javascript/api/interfaces/ChoiceQuestion.md | 834 |
| 200 | https://docs.typesafe.ai/sdk/javascript/api/interfaces/ScoreResponse.md | 1139 |
| 200 | https://docs.typesafe.ai/sdk/javascript/api/interfaces/NoulResponse.md | 447 |
| 200 | https://docs.typesafe.ai/sdk/javascript/api/interfaces/SystemOneRequestPayload.md | 1292 |
| 200 | https://docs.typesafe.ai/sdk/javascript/api/interfaces/SystemOneResult.md | 828 |
| 200 | https://docs.typesafe.ai/sdk/javascript/api/classes/APIError.md | 2190 |
| 200 | https://docs.typesafe.ai/sdk/javascript/api/classes/UnprocessableEntityError.md | 2422 |
| 200 | https://docs.typesafe.ai/agent-skill.md | 5798 |
| 200 | https://docs.typesafe.ai/sdk/python.md | 3324 |
| 200 | https://docs.typesafe.ai/sdk/javascript.md | 1302 |
| 200 | https://docs.typesafe.ai/patterns/intent-routing.md | 13444 |
| 200 | https://docs.typesafe.ai/cookbooks/consistency_choice_cookbook.md | 49891 |
| 200 | https://docs.typesafe.ai/cookbooks/classification_using_confidence.md | 30705 |
| 200 | https://docs.typesafe.ai/concepts/how-to-build-with-system-one.md | 40921 |
| 200 | https://raw.githubusercontent.com/typesafe-ai/skills/main/skills/typesafe-ai/SKILL.md | 10040 |
| 200 | https://docs.typesafe.ai/api (served HTML) | 516970 |
| 200 | https://docs.typesafe.ai/confidence (served HTML) | 326549 |
| 200 | https://docs.typesafe.ai/primitives/choice (served HTML) | 537130 |
| 200 | https://docs.typesafe.ai/introduction/quickstart (served HTML) | 399995 |
| 200 | https://docs.typesafe.ai/model-jaggedness/jev-1.13 (served HTML) | 349840 |
| 200 | https://docs.typesafe.ai/primitives (served HTML) | 439771 |

No WebSearch calls were spent; the docs index answered every question in scope.

## Unsettled

1. **Error body JSON shape (5.13).** The reference says only "a JSON body describing what went wrong" / "The body details the offending field". One authenticated request with a deliberately malformed question would settle the 422 body format; that is out of scope (no keys, no calls).
2. **Exact `confidence` formula (4.13).** The Confidence page's demo uses `(n × peak − 1)/(n − 1)` as an approximation and the note says a separate cookbook on alternative measures is planned ("will add the link here when we do!"). Whether the served `confidence` equals this expression could be checked with one authenticated call against the returned `probabilities`.
3. **Status-code spread (5.12).** `/api` lists 401/422/429/529; the SDKs also model 400/403/404/500 (and retry 500/502/503/504). Whether the endpoint actually emits 400 or 403 for any client-caused condition is not stated on any page; a vendor answer or an OpenAPI spec (none published at the paths tried) would settle it.
4. **Score "not applicable" (5.15).** The escape-hatch guidance ("add `other` / `none of the above`") is written for Choice; the docs never say whether a Score should carry an N/A level or how `score` (a weighted mean over level indices) should be read if one is added. A docs guide or vendor answer would settle it.
5. **Behaviour when `state` is empty / `null`.** The JS SDK types `state` as `EntryType` including `null`; no page says what the model returns for empty state (presumably some distribution, given 5.1, but this is inference, not a finding).
6. **Whether an `other` option is ever auto-injected.** All evidence says no — the caller declares it — but this rests on the reference's `criteria` definition ("A map of option to rubric description") and the absence of any injection language, not on an explicit denial.
