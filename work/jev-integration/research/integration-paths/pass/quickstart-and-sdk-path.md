# integration-paths / Q1 — quickstart-and-sdk-path (raw pass findings)

Subject: Jev (TypeSafe, typesafe.ai). Cluster: `quickstart-and-sdk-path`. Question Q1: the canonical call path per TypeSafe's docs (quickstart): HTTP? SDK? which language first? Plus the full docs nav index for the other clusters.
Date checked for every row: 2026-09-23. Method: `curl -sL -A "Mozilla/5.0"` to a scratchpad, then `grep -c` / Python `str.count` on the saved page. Every docs page was fetched twice: the rendered HTML and the `.md` variant that the docs site (Mintlify) serves at `<page>.md`. Counts below name which copy they were taken on.

Scope kept: public pages only; no account, no key, no API call. `console.typesafe.ai` was only probed for its logged-out HTTP status.

## Claims

| # | Claim (one sentence) | Verdict | Source URL (the page, not the site) | Date checked | How verified | Documented vs. implied |
|---|---|---|---|---|---|---|
| 1 | `https://docs.typesafe.ai/` redirects (curl `-L`) to `https://docs.typesafe.ai/introduction`, whose "Next steps" list names Quick Start first. | documented | https://docs.typesafe.ai/introduction | 2026-09-23 | `curl -sL -w %{url_effective}` on the root gave `.../introduction`; `.md` copy: "* [Quick Start](/introduction/quickstart) — Everything you need to get started immediately." is the first bullet under `## Next steps`. | documented |
| 2 | The quickstart page has four sections in this order: "Try it: the Playground", "Call it: the API", "Code it: the Python SDK", "Vibe it: the agent skill". | documented | https://docs.typesafe.ai/introduction/quickstart | 2026-09-23 | `.md` copy: each `## ` heading occurs once; rendered HTML: each heading text occurs 4× (nav/TOC + body). Order confirmed by line order in the `.md` copy. | documented |
| 3 | The first thing the quickstart tells a new user to do is open the Playground in the console and log in, then paste text as "state" and add a Noul question — not curl, pip, or npm. | documented | https://docs.typesafe.ai/introduction/quickstart | 2026-09-23 | `.md` copy step 1 under "Try it": "**Open the [Playground](https://console.typesafe.ai/playground)** and log in." (1×). | documented |
| 4 | The first *code* path on the quickstart is raw HTTP: `POST https://api.typesafe.ai/v1/systemone` with a sample cURL command, before any SDK. | documented | https://docs.typesafe.ai/introduction/quickstart | 2026-09-23 | `.md` copy: "POST https://api.typesafe.ai/v1/systemone" 2×, "curl -X POST https://api.typesafe.ai/v1/systemone" 1×; rendered HTML: "api.typesafe.ai/v1/systemone" 4×. Section order per claim 2. | documented |
| 5 | Auth header shape is `Authorization: Bearer <API_KEY>`, and the API key comes from the console dashboard at `https://console.typesafe.ai/keys`. | documented | https://docs.typesafe.ai/introduction/quickstart | 2026-09-23 | `.md` copy: "Authorization: Bearer <API_KEY>" 1×; cURL sample uses `-H "Authorization: Bearer $TYPESAFE_API_KEY"` 1×; "Get your API key" links `https://console.typesafe.ai/keys` 1×. Rendered HTML: "Authorization: Bearer" 2×. Same header block on https://docs.typesafe.ai/api (1×). | documented |
| 6 | The request is JSON (`Content-Type: application/json`) with three top-level fields: `state` (string/object/array), `model` (e.g. `"jev-latest"`), and `questions` (a map of named typed questions). | documented | https://docs.typesafe.ai/api | 2026-09-23 | `.md` copy of /api: `<ParamField body="state" type="string \| object \| array" required>`, `<ParamField body="model" type="string" required>`, `<ParamField body="questions" type="map<string, Question>" required>` each 1×. Quickstart `.md`: "Content-Type: application/json" 2×. | documented |
| 7 | The quickstart's worked request evaluates one support-ticket string against three questions — `department` (choice: billing/technical/sales), `frustration` (score: three levels), `is_urgent` (noul) — with `"model": "jev-latest"`. | documented | https://docs.typesafe.ai/introduction/quickstart | 2026-09-23 | `.md` copy under `### Request body`: `"model": "jev-latest"` 2× on page (cURL + request body); keys `"department"`, `"frustration"`, `"is_urgent"` present; verbatim JSON reproduced in Evidence quotes. | documented |
| 8 | The quickstart's worked response reports `"model": "jev-1.13.0"`, an `answers` map keyed by the same three ids, and `usage` of 392 input / 65 output tokens; the choice answer carries `choice`, `confidence` (0.78) and `probabilities`; the score answer carries `score`, `confidence`, `legend`, `probabilities`; the noul answer carries only `noul` (1.0). | documented | https://docs.typesafe.ai/introduction/quickstart | 2026-09-23 | `.md` copy: `"model": "jev-1.13.0"` 1×, `"input_tokens": 392` 1×, `"output_tokens": 65` 1×, `"confidence": 0.78` 1×, `"noul": 1.0` 1×. Rendered HTML: "jev-1.13.0" 2×, "input_tokens" 2×. | documented |
| 9 | The only SDK on the quickstart is Python: `pip install typesafe-sdk` (or `uv add typesafe-sdk`), "requires Python >= 3.10", client `TypeSafeClient()` and method `client.system_one(state=..., questions=...)`. | documented | https://docs.typesafe.ai/introduction/quickstart | 2026-09-23 | `.md` copy: "pip install typesafe-sdk" 1×, "uv add typesafe-sdk" 1×, "requires Python >= 3.10" 1×, "from typesafe_sdk import Choice, Noul, Score, TypeSafeClient" 1×, "response = client.system_one(" 1×. Rendered HTML: "typesafe-sdk" 4×, "client.system_one(" 2×; the multi-word shell line is split across spans (0× contiguous) — not absence. No `npm` string anywhere on the quickstart (`.md` 0×). | documented |
| 10 | The SDK reads `TYPESAFE_API_KEY` from the environment and calls `jev-latest` by default. | documented | https://docs.typesafe.ai/introduction/quickstart | 2026-09-23 | `.md` copy: "The client reads `TYPESAFE_API_KEY` from the environment and calls `jev-latest` by default." 1×. Cross-checked on https://docs.typesafe.ai/sdk/python/api/constants (`API_KEY_ENV = 'TYPESAFE_API_KEY'`, `DEFAULT_MODEL = 'jev-latest'`, `DEFAULT_BASE_URL = 'https://api.typesafe.ai'`, `DEFAULT_TIMEOUT = 10.0` each 1×) and https://docs.typesafe.ai/sdk/javascript/api/variables/ENV ("defaults to `jev-latest`" 1×, "defaults to `https://api.typesafe.ai`" 1×). | documented |
| 11 | The SDK index orders the languages Python first, then JavaScript/TypeScript, and adds that the HTTP API can be called "directly from any language". | documented | https://docs.typesafe.ai/sdk | 2026-09-23 | `.md` copy: `<Card title="Python" href="/sdk/python">` precedes `<Card title="JavaScript / TypeScript" href="/sdk/javascript">`; "You can also call the [HTTP API](/api) directly from any language." 1×. | documented |
| 12 | The JavaScript SDK is `npm install @typesafe-ai/sdk`, requires Node.js 20 or newer, exposes `new TypeSafeClient()` and `client.systemOne({ state, questions })`, and ships ESM, CommonJS and TypeScript declarations. | documented | https://docs.typesafe.ai/sdk/javascript | 2026-09-23 | `.md` copy: "npm install @typesafe-ai/sdk" 1×, "Install the SDK (Node.js 20 or newer)" 1×, "client.systemOne(" 1×, "The package includes ESM, CommonJS, and TypeScript declarations." 1×. | documented |
| 13 | The Python SDK's own page shows async (`AsyncTypeSafeClient`) and sync (`TypeSafeClient`) clients and links its source at `github.com/typesafe-ai/typesafe-sdk-python`. | documented | https://docs.typesafe.ai/sdk/python | 2026-09-23 | `.md` copy: "Browse the [Python SDK source on GitHub](https://github.com/typesafe-ai/typesafe-sdk-python)." 1×; `<Tab title="Async">` and `<Tab title="Sync">` 1× each. | documented |
| 14 | Published package versions on 2026-09-23: PyPI `typesafe-sdk` 0.7.1 (releases 0.0.1a0, 0.5.7, 0.6.0, 0.7.0, 0.7.1; requires_python >=3.10); npm `@typesafe-ai/sdk` latest 0.6.0 (versions 0.0.0-bootstrap.0, 0.5.7, 0.6.0; engines node >=20). | documented | https://pypi.org/pypi/typesafe-sdk/json and https://registry.npmjs.org/@typesafe-ai/sdk | 2026-09-23 | Both registry JSON endpoints returned 200; fields read with Python `json`. Docs changelogs agree: Python "v0.7.1 (2026-09-21)" … "v0.5.7 (2026-09-14) This is the initial public release" (https://docs.typesafe.ai/sdk/python/changelog); JS "v0.6.0 (2026-09-15)" … "v0.5.7 (2026-09-11) This is the initial public release" (https://docs.typesafe.ai/sdk/javascript/changelog). | documented |
| 15 | The SDK GitHub repos are `typesafe-ai/typesafe-sdk-python` (created 2026-09-04, MIT, 210 stars) and `typesafe-ai/typesafe-sdk-js` (created 2026-09-04, MIT, 229 stars); the skill repo `typesafe-ai/skills` (created 2026-08-24, MIT, 1,981 stars). | documented | https://api.github.com/repos/typesafe-ai/typesafe-sdk-python ; https://api.github.com/repos/typesafe-ai/typesafe-sdk-js ; https://api.github.com/repos/typesafe-ai/skills | 2026-09-23 | GitHub REST responses (200) read with Python `json`: `created_at`, `license.spdx_id`, `stargazers_count`. Star counts are a point-in-time reading. | documented |
| 16 | The fourth quickstart path is an agent skill: Claude Code `claude plugin marketplace add typesafe-ai/skills` + `claude plugin install typesafe@typesafe-ai`, or `npx skills add typesafe-ai/skills --skill typesafe-ai` for other agents, with SKILL.md public on GitHub. | documented | https://docs.typesafe.ai/introduction/quickstart (and https://docs.typesafe.ai/agent-skill) | 2026-09-23 | Quickstart `.md`: "claude plugin marketplace add typesafe-ai/skills" 2×, "npx skills add typesafe-ai/skills --skill typesafe-ai" 3×; rendered HTML 2× / 4×. Agent-skill page subtitle "Drop-in skill for Claude Code, Codex, and other agent environments." 1×. Raw SKILL.md fetched (200, 10,040 bytes). | documented |
| 17 | The public SKILL.md does not itself prescribe curl vs SDK; it tells the agent to read the live docs (starting from `llms.txt`) and "read the current API or chosen SDK page" before writing an integration. | documented | https://raw.githubusercontent.com/typesafe-ai/skills/main/skills/typesafe-ai/SKILL.md | 2026-09-23 | grep counts on the raw file: `curl` 0, `pip install` 0, `npm install` 0, `/v1/systemone` 0, `typesafe-sdk`/`typesafe_sdk` 0, `@typesafe-ai/sdk` 0; the quoted sentence occurs 1×. | documented |
| 18 | Every model is served by the same endpoint `POST /v1/systemone`; the `model` field selects it; `jev-latest` and `jev-preview` both resolve to `jev-1.13.0` today; `jev-latest` is "The default in our client SDKs, and the name the examples in these docs use." | documented | https://docs.typesafe.ai/models | 2026-09-23 | `.md` copy: "Every model on this page is served by the same endpoint, `POST /v1/systemone`." 1×; alias table rows `jev-latest` → `jev-1.13.0`, `jev-preview` → `jev-1.13.0`; the quoted sentence 1×. | documented |
| 19 | A second endpoint, `GET /v1/models`, lists the names the account can send in `model`, with cURL/Python/JavaScript examples. | documented | https://docs.typesafe.ai/models | 2026-09-23 | `.md` copy: "GET /v1/models" 1×; `curl https://api.typesafe.ai/v1/models` 1×; `client.models.list()` in both SDK tabs. | documented |
| 20 | The API reference documents four error statuses — 401, 422, 429, 529 — and says the SDKs retry 429/529 with backoff by default. | documented | https://docs.typesafe.ai/api | 2026-09-23 | `.md` copy error table rows `401 Unauthorized`, `422 Unprocessable Entity`, `429 Too Many Requests`, `529 Overloaded` 1× each; "Our client SDKs handle this automatically" 1×. | documented |
| 21 | Standing claim S6 holds: neither the homepage nor the launch post says how Jev is called — no `curl`, `pip install`, `npm install`, `SDK`, `api.typesafe.ai`, `/v1/systemone` or `Authorization` string occurs in either raw HTML; they only link "Docs" (docs.typesafe.ai) and "Sign in" (console.typesafe.ai), and the launch post links one shared Playground query. | documented | https://typesafe.ai/ and https://typesafe.ai/blog/introducing-system-one-models-and-jev | 2026-09-23 | `grep -o -i` counts on the saved raw HTML (590 KB / 259 KB): all seven strings 0× on both pages. Anchor extraction: homepage `<a>`s to docs/console = "Docs", "Sign in", plus two icon links; launch post adds `https://docs.typesafe.ai/` ("defined in advance") and `https://console.typesafe.ai/playground?share=shr_13a74b…` ("actual query"). Absence is on the raw HTML, not on visible text only; the answer sits on the docs reference (claims 4–6), satisfying method rule 2. | documented (absence) |
| 22 | Logged out, `console.typesafe.ai/`, `/playground`, `/keys` and `/docs/cookbooks` all 200 → `/login?returnTo=…`; the console shows nothing public beyond a login page. | documented | https://console.typesafe.ai/login | 2026-09-23 | `curl -sL -o /dev/null -w "%{http_code} %{url_effective}"` for each: 200, final URL `https://console.typesafe.ai/login` (with `returnTo` for the three sub-paths). Login page content not inspected further (scope). | documented |
| 23 | The docs site is Mintlify-hosted and serves Markdown at `<page>.md`; `llms.txt` (111 pages) and `sitemap.xml` (111 URLs) list exactly the same page set. | documented | https://docs.typesafe.ai/llms.txt and https://docs.typesafe.ai/sitemap.xml | 2026-09-23 | `comm` of the two sorted URL lists: empty both ways. Rendered HTML references `/mintlify-assets/…`; SKILL.md says "Mintlify serves Markdown by appending `.md` to a page path" (1×). `llms-full.txt` also exists (200, 910,292 bytes). | documented |
| 24 | The docs' own Python-SDK page passes `state` as an object (`{"document": "…"}`) whereas the quickstart passes a plain string; both shapes are documented (API: `state` is `string \| object \| array`). | documented | https://docs.typesafe.ai/sdk/python and https://docs.typesafe.ai/api | 2026-09-23 | sdk/python `.md`: `state={"document": "I was charged twice. Please fix this ASAP."}` 2× (async + sync tabs); quickstart `.md`: `state=ticket` with a str. API `.md`: `type="string \| object \| array"` on `state` 1×. Not a contradiction; recorded so other clusters do not flag it as one. | documented |
| 25 | Whether the quickstart is the path TypeSafe considers *canonical* (as opposed to merely first) is not stated anywhere; the ordering Playground → HTTP → Python SDK → agent skill is the only signal. | unknown | https://docs.typesafe.ai/introduction/quickstart | 2026-09-23 | No sentence on the quickstart, /sdk, or /api page ranks the paths; `grep -i -c "recommend"` on the quickstart `.md` = 0, on /sdk `.md` = 0. | implied (ordering only) |

## Evidence quotes

All quotes verbatim from the `.md` copy of the page unless noted; count = occurrences on that copy confirmed with `grep -c -F` (or Python `str.count` where the string spans quoting characters).

**https://docs.typesafe.ai/introduction/quickstart** (`.md` copy, 7,053 bytes; rendered HTML 399,995 bytes)

- "Prefer to just dive in? Here's everything you need to get started immediately." — 1× (rendered HTML 10×)
- "## Try it: the Playground" — 1×; "1. **Open the [Playground](https://console.typesafe.ai/playground)** and log in." — 1×
- "## Call it: the API" — 1×; "1. **Get your API key** from the [dashboard](https://console.typesafe.ai/keys)" — 1×; "2. **Make a POST request** to the API endpoint" — 1×
- Endpoint block (each line 1×; "POST https://api.typesafe.ai/v1/systemone" 2× on page):
  ```http
  POST https://api.typesafe.ai/v1/systemone
  Authorization: Bearer <API_KEY>
  Content-Type: application/json
  ```
- Sample cURL command (`curl -X POST https://api.typesafe.ai/v1/systemone` 1×; `-H "Authorization: Bearer $TYPESAFE_API_KEY"` 1×):
  ```bash
  curl -X POST https://api.typesafe.ai/v1/systemone \
    -H "Authorization: Bearer $TYPESAFE_API_KEY" \
    -H "Content-Type: application/json" \
    -d @- <<'EOF'
    {
      "state": "Hi, I've been trying to connect my Stripe account for 3 days and the integration keeps failing. I'm losing sales. Please help ASAP.",
      "model": "jev-latest",
      "questions": {
        "urgency": {
          "type": "noul",
          "instructions": "Does this message express urgency?"
        }
      }
    }
  EOF
  ```
- `### Request body` (the three-question example; `"model": "jev-latest"` 2× on page, `"department"` / `"frustration"` / `"is_urgent"` keys present):
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
- `### Response body` (`"model": "jev-1.13.0"` 1×, `"input_tokens": 392` 1×, `"output_tokens": 65` 1×, `"confidence": 0.78` 1×, `"noul": 1.0` 1×):
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
- "## Code it: the Python SDK" — 1×; "1. **Install the SDK** (requires Python >= 3.10)." — 1×; "pip install typesafe-sdk" — 1×; "uv add typesafe-sdk" — 1×
- "2. **Use the SDK.** The client reads `TYPESAFE_API_KEY` from the environment and calls `jev-latest` by default." — 1×
- "from typesafe_sdk import Choice, Noul, Score, TypeSafeClient" — 1×; "client = TypeSafeClient()" — 1×; "response = client.system_one(" — 1×
- "## Vibe it: the agent skill" — 1×; "claude plugin marketplace add typesafe-ai/skills" — 2×; "claude plugin install typesafe@typesafe-ai" — 2×; "npx skills add typesafe-ai/skills --skill typesafe-ai" — 3×
- "See [client SDKs](/sdk) for installation options and detailed usage." — 1×

**https://docs.typesafe.ai/introduction** (`.md` copy)
- "* [Quick Start](/introduction/quickstart) — Everything you need to get started immediately." — 1× (first bullet under `## Next steps`)
- "Jev is TypeSafe's flagship model and the first [System One model](/concepts/system-one)." — 1×

**https://docs.typesafe.ai/sdk** (`.md` copy)
- "Our client SDKs provide typed questions and answers for the TypeSafe API and handle retries automatically with their default retry policy." — 1×
- "You can also call the [HTTP API](/api) directly from any language." — 1×

**https://docs.typesafe.ai/sdk/python** (`.md` copy)
- "Browse the [Python SDK source on GitHub](https://github.com/typesafe-ai/typesafe-sdk-python)." — 1×
- "2. Set `TYPESAFE_API_KEY` in your environment (create it [here](https://console.typesafe.ai/))" — 1×

**https://docs.typesafe.ai/sdk/javascript** (`.md` copy)
- "Install the SDK (Node.js 20 or newer):" — 1×; "npm install @typesafe-ai/sdk" — 1×
- "Answer types are inferred from your questions. The package includes ESM, CommonJS, and TypeScript declarations." — 1×
- "See the SDK's [client](https://github.com/typesafe-ai/typesafe-sdk-js/blob/v0.6.0/src/client.ts) and [types](https://github.com/typesafe-ai/typesafe-sdk-js/blob/v0.6.0/src/types.ts) for API options and defaults." — 1×

**https://docs.typesafe.ai/api** (`.md` copy)
- "> Full HTTP API reference for the TypeSafe evaluation endpoint." — 1×
- "Evaluate a `state` against a map of typed `questions` and get back structured `answers`, one per question." — 1×
- "Every answer carries a `type` matching its question. Choice and Score answers also carry a `confidence` between 0 to 1, derived from the answer's probability distribution." — 1×
- "When you receive a `429 Too Many Requests` or `529 Overloaded` response, retry the request with exponential backoff instead of retrying immediately. Our client SDKs handle this automatically, so no extra handling is needed if you use one of our SDKs with its default retry policy." — 1×

**https://docs.typesafe.ai/models** (`.md` copy)
- "Every model on this page is served by the same endpoint, `POST /v1/systemone`." — 1×
- "| `jev-latest`  | `jev-1.13.0` | The most recent stable, official release. The default in our client SDKs, and the name the examples in these docs use.        |" — 1×
- "`GET /v1/models` returns the names your account can send in the `model` field, with a description and release date for each." — 1×

**https://docs.typesafe.ai/sdk/python/api/constants** (`.md` copy) — each 1×
- `API_KEY_ENV = 'TYPESAFE_API_KEY'`; `BASE_URL_ENV = 'TYPESAFE_BASE_URL'`; `DEFAULT_MODEL_ENV = 'TYPESAFE_DEFAULT_MODEL'`; `DEFAULT_BASE_URL = 'https://api.typesafe.ai'`; `DEFAULT_MODEL = 'jev-latest'`; `DEFAULT_TIMEOUT = 10.0` ("Default timeout in seconds for each HTTP operation.")

**https://docs.typesafe.ai/sdk/javascript/api/variables/ENV** (`.md` copy) — each 1×
- "API root; defaults to `https://api.typesafe.ai`."; "Default model name; defaults to `jev-latest`."; "Log level; defaults to `warn`."

**https://docs.typesafe.ai/sdk/python/changelog** (`.md` copy)
- "v0.7.1 (2026-09-21)" — 1×; "v0.5.7 (2026-09-14)" — 1×; "This is the initial public release of TypeSafe Python SDK." — 1×
- "the `system_one` method now accepts a new `response_model` argument that can be set to a desired `pydantic` model for additional *type-safety*" — 1× (v0.7.0, 2026-09-18)

**https://docs.typesafe.ai/sdk/javascript/changelog** (`.md` copy)
- "v0.6.0 (2026-09-15)" — 1×; "v0.5.7 (2026-09-11)" — 1×; "This is the initial public release of TypeSafe JavaScript and TypeScript SDK." — 1×

**https://docs.typesafe.ai/agent-skill** (`.md` copy)
- "> Drop-in skill for Claude Code, Codex, and other agent environments." — 1×
- "### The agent invents request or response fields" / "A stale skill can cause this. Update it using your installation method above and retry." — 1× each

**https://raw.githubusercontent.com/typesafe-ai/skills/main/skills/typesafe-ai/SKILL.md** (raw, 10,040 bytes)
- "**The live TypeSafe docs are the source of truth. Read them as part of the task.**" — 1×
- "Mintlify serves Markdown by appending `.md` to a page path" — 1×
- "Before writing an integration, read the current API or chosen SDK page and the question guidance relevant to the design." — 1×

**https://typesafe.ai/blog/introducing-system-one-models-and-jev** (raw HTML, visible text)
- "…our System One LLM wrapper, which constrains LLMs to output structured decisions compatible with our API." — 1× (the only visible-text occurrence of "API" on the post; it describes a benchmark baseline, not a call path)

## Docs nav index

Source of the list: `https://docs.typesafe.ai/llms.txt` (200, 16,019 bytes; 111 entries) — cross-checked against `https://docs.typesafe.ai/sitemap.xml` (200; 111 `<loc>` URLs; `comm` shows the two sets identical). The rendered quickstart HTML's top-level nav (25 internal hrefs) is a strict subset. Every `<page>` below also serves `<page>.md` (Mintlify). Titles are the llms.txt link texts; parenthetical descriptions are llms.txt's own one-liners, lightly truncated.

Intro / concepts
- Introduction — https://docs.typesafe.ai/introduction (root `/` redirects here)
- Quick start — https://docs.typesafe.ai/introduction/quickstart
- Jev with coding agents — https://docs.typesafe.ai/introduction/coding-agents
- AI primer — https://docs.typesafe.ai/introduction/machine-learning-primer
- Example use cases — https://docs.typesafe.ai/concepts/use-case-map
- System One — https://docs.typesafe.ai/concepts/system-one
- State — https://docs.typesafe.ai/concepts/state
- How to build with TypeSafe — https://docs.typesafe.ai/concepts/how-to-build-with-system-one

Primitives / confidence
- Primitives (Questions) — https://docs.typesafe.ai/primitives
- Choice — https://docs.typesafe.ai/primitives/choice
- Score — https://docs.typesafe.ai/primitives/score
- Noul — https://docs.typesafe.ai/primitives/noul
- Advanced: structure — https://docs.typesafe.ai/primitives/advanced
- Confidence — https://docs.typesafe.ai/confidence

Patterns
- Patterns — https://docs.typesafe.ai/patterns
- Speculative fan-out — https://docs.typesafe.ai/patterns/fan-out
- Confidence-gated routing — https://docs.typesafe.ai/patterns/confidence-routing
- Composite scoring — https://docs.typesafe.ai/patterns/composite-scoring
- Intent routing — https://docs.typesafe.ai/patterns/intent-routing

Cookbooks (index + 18)
- Cookbooks — https://docs.typesafe.ai/cookbooks
- Self-consistency: nouls — https://docs.typesafe.ai/cookbooks/consistency_noul_cookbook
- Self-consistency: choices — https://docs.typesafe.ai/cookbooks/consistency_choice_cookbook
- Parallel questions — https://docs.typesafe.ai/cookbooks/parallel_questions (13-question GDPR briefing; "12.2x cheaper and 10.0x faster")
- Re-ranking — https://docs.typesafe.ai/cookbooks/rerank_typesafe (CLERC legal queries)
- Line-by-line search — https://docs.typesafe.ai/cookbooks/semantic_find (GitHub ToS)
- Structure recovery — https://docs.typesafe.ai/cookbooks/autoformat
- Function calling — https://docs.typesafe.ai/cookbooks/function_calling
- Skill suggestion — https://docs.typesafe.ai/cookbooks/skill_suggestion (Hermes catalog, 182 skills)
- Knowledge graph entity alignment — https://docs.typesafe.ai/cookbooks/entity_alignment
- Classifying RAG passages — https://docs.typesafe.ai/cookbooks/classifying_rag_passages
- Double-checking citations — https://docs.typesafe.ai/cookbooks/citation_check
- Guardrails for LLMs — https://docs.typesafe.ai/cookbooks/llm_guardrails
- SDE cascade — https://docs.typesafe.ai/cookbooks/sde_cascade
- Date extraction — https://docs.typesafe.ai/cookbooks/date_extraction_cookbook
- Pre-parsed value extraction — https://docs.typesafe.ai/cookbooks/pre_parsed_value_extraction_cookbook
- Hierarchical classification — https://docs.typesafe.ai/cookbooks/hierarchical_classification
- Autoresearch feature discovery — https://docs.typesafe.ai/cookbooks/autoresearch_feature_discovery
- Classification using confidence — https://docs.typesafe.ai/cookbooks/classification_using_confidence

Demos
- Demos — https://docs.typesafe.ai/demos
- Smart home assistant demo — https://docs.typesafe.ai/demos/smart-home

Reference / misc
- Models — https://docs.typesafe.ai/models (price, rate limits, context length, aliases, `GET /v1/models`)
- API reference — https://docs.typesafe.ai/api
- Agent skill — https://docs.typesafe.ai/agent-skill
- Legal — https://docs.typesafe.ai/legal
- Jev 1.13 jaggedness — https://docs.typesafe.ai/model-jaggedness/jev-1.13
- Client SDKs — https://docs.typesafe.ai/sdk

Python SDK (12)
- TypeSafe Python SDK — https://docs.typesafe.ai/sdk/python
- Usage — https://docs.typesafe.ai/sdk/python/usage
- Changelog — https://docs.typesafe.ai/sdk/python/changelog
- API reference — https://docs.typesafe.ai/sdk/python/api
- Asynchronous client — https://docs.typesafe.ai/sdk/python/api/clients/async
- Synchronous client — https://docs.typesafe.ai/sdk/python/api/clients/sync
- Questions — https://docs.typesafe.ai/sdk/python/api/types/questions
- Answers and responses — https://docs.typesafe.ai/sdk/python/api/types/responses
- Retries — https://docs.typesafe.ai/sdk/python/api/retries
- Common types — https://docs.typesafe.ai/sdk/python/api/types/common
- Exceptions — https://docs.typesafe.ai/sdk/python/api/exceptions
- Constants — https://docs.typesafe.ai/sdk/python/api/constants

JavaScript SDK (index, changelog, api, + 50 generated reference pages)
- JavaScript SDK — https://docs.typesafe.ai/sdk/javascript
- Changelog — https://docs.typesafe.ai/sdk/javascript/changelog
- API reference — https://docs.typesafe.ai/sdk/javascript/api
- Classes (14): https://docs.typesafe.ai/sdk/javascript/api/classes/{APIConnectionError, APIError, APIPromise, APITimeoutError, APIUserAbortError, AuthenticationError, BadRequestError, InternalServerError, NotFoundError, PermissionDeniedError, RateLimitError, TypeSafeClient, TypeSafeError, UnprocessableEntityError}
- Interfaces (18): https://docs.typesafe.ai/sdk/javascript/api/interfaces/{ChoiceQuestion, ChoiceResponse, Logger, ModelCard, Models, NoulQuestion, NoulResponse, Questions, RequestOptions, RetryPolicy, ScoreQuestion, ScoreResponse, SystemOneRequest, SystemOneRequestPayload, SystemOneResult, TypeSafeClientConfig, Usage, WithResponse}
- Type aliases (12): https://docs.typesafe.ai/sdk/javascript/api/type-aliases/{ChoiceCriteria, Description, EntryType, EnvVar, Fetch, JsonValue, LogLevel, Question, ResultFor, ScoreCriteria, ScoreLegend, ScoreOf}
- Variables (3): https://docs.typesafe.ai/sdk/javascript/api/variables/{ENV, LOG_LEVELS, VERSION}
- Functions (3): https://docs.typesafe.ai/sdk/javascript/api/functions/{choice, noul, score}

Adjacent non-docs pages (from `https://typesafe.ai/sitemap.xml`, 13 URLs): `/`, `/team`, `/manifesto`, `/blog`, `/blog/introducing-system-one-models-and-jev`, `/blog/antibenchmaxxing`, `/blog/bitterest-lesson`, `/blog/ai-too-good-to-be-true-too-bad-to-be-useful-typesafe-ai`, `/blog/diogo-almeida---founders-you-should-know`, `/legal/data-processing`, `/legal/mca`, `/legal/privacy-policy`, `/legal/terms`.

Also present: `https://docs.typesafe.ai/llms-full.txt` (200, 910,292 bytes — full text of every page; not read in this pass). `robots.txt` on docs: `Content-Signal: ai-train=yes, search=yes, ai-input=yes`, disallows `/cdn-cgi/` and `/_next/`.

## Fetch log

All via `curl -sL -A "Mozilla/5.0"` on 2026-09-23. "JS-rendered?" = whether the useful content was in the served HTML.

| URL | HTTP | Notes |
|---|---|---|
| https://docs.typesafe.ai/ | 200 | 302-chain to `/introduction`; 276,036 bytes HTML |
| https://docs.typesafe.ai/sitemap.xml | 200 | 15,616 bytes; 111 URLs |
| https://docs.typesafe.ai/llms.txt | 200 | 16,019 bytes; 111 entries |
| https://docs.typesafe.ai/llms-full.txt | 200 | 910,292 bytes; saved, not read |
| https://docs.typesafe.ai/robots.txt | 200 | 172 bytes |
| https://docs.typesafe.ai/introduction/quickstart | 200 | 399,995 bytes rendered HTML; headings and identifiers present, shell one-liners split across spans (not empty) |
| https://docs.typesafe.ai/introduction/quickstart.md | 200 | 7,053 bytes clean Markdown — primary copy for quotes |
| https://docs.typesafe.ai/introduction.md | 200 | 4,317 bytes |
| https://docs.typesafe.ai/sdk.md | 200 | 823 bytes |
| https://docs.typesafe.ai/sdk/python.md | 200 | 3,324 bytes |
| https://docs.typesafe.ai/sdk/javascript.md | 200 | 1,302 bytes |
| https://docs.typesafe.ai/api.md | 200 | 11,772 bytes |
| https://docs.typesafe.ai/agent-skill.md | 200 | 5,798 bytes |
| https://docs.typesafe.ai/models.md | 200 | 7,245 bytes |
| https://docs.typesafe.ai/sdk/python/changelog.md | 200 | 1,828 bytes |
| https://docs.typesafe.ai/sdk/javascript/changelog.md | 200 | 508 bytes |
| https://docs.typesafe.ai/sdk/python/api/constants.md | 200 | 1,782 bytes |
| https://docs.typesafe.ai/sdk/javascript/api/variables/ENV.md | 200 | 1,039 bytes |
| https://typesafe.ai/ | 200 | 590,563 bytes; ~7.3 KB visible text; no call-path strings |
| https://typesafe.ai/blog/introducing-system-one-models-and-jev | 200 | 258,883 bytes; ~13.6 KB visible text; no call-path strings |
| https://typesafe.ai/sitemap.xml | 200 | 935 bytes; 13 URLs |
| https://typesafe.ai/robots.txt | 200 | 64 bytes; `Allow: /` |
| https://console.typesafe.ai/ | 200 | final `…/login` (logged out) |
| https://console.typesafe.ai/playground | 200 | final `…/login?returnTo=%2Fplayground` |
| https://console.typesafe.ai/keys | 200 | final `…/login?returnTo=%2Fkeys` |
| https://console.typesafe.ai/docs/cookbooks | 200 | final `…/login?returnTo=%2Fdocs%2Fcookbooks` (URL appears on the agent-skill page) |
| https://pypi.org/pypi/typesafe-sdk/json | 200 | version 0.7.1 |
| https://registry.npmjs.org/@typesafe-ai/sdk | 200 | latest 0.6.0 |
| https://api.github.com/repos/typesafe-ai/typesafe-sdk-python | 200 | |
| https://api.github.com/repos/typesafe-ai/typesafe-sdk-js | 200 | |
| https://api.github.com/repos/typesafe-ai/skills | 200 | |
| https://raw.githubusercontent.com/typesafe-ai/skills/main/skills/typesafe-ai/SKILL.md | 200 | 10,040 bytes |

No WebSearch or WebFetch calls were spent; everything came from the docs index, sitemaps, and public registries.

## Unsettled

- **"Canonical" is inferred from ordering only** (claim 25). No docs sentence says "we recommend the SDK" or "use HTTP". Settling it would take a TypeSafe statement (support/sales, or a future docs line); public pages do not say.
- **Rendered-page quote counts for shell one-liners are 0×** because the HTML splits code tokens across spans; the `.md` copy (which the docs site itself serves) is the verified source. A fact-checker with a browser could confirm the rendered code blocks visually; not needed for the claims.
- **What the Playground shows once logged in** (the true first step per the quickstart) is out of scope — every console URL redirects to `/login`. Only an account would settle whether the Playground surfaces a "copy as curl / Python" export that would change which code path a new user actually sees first.
- **`llms-full.txt` (910 KB) was saved but not read**; other clusters (Q3 cookbooks, Q4 schema, Q5 out-of-schema behaviour, Q6 batch/streaming/timeouts) should pull their pages from it or from `<page>.md` rather than from the rendered HTML. The `models` page already carries rate limits, context length (64k/32k), price ($42/Btok, "Output tokens are free"), and `DEFAULT_TIMEOUT = 10.0` sits on the Python constants page — hand-offs for `terms` and Q6.
- **A surprise for Q5's owner, not settled here:** in the quickstart's own response example the Noul answer carries *no* `confidence` field; only Choice and Score do (API page: "Choice and Score answers also carry a `confidence`"). Any "confidence on every answer" wording elsewhere in the wave should be checked against that.
- **Star counts and versions are point-in-time** (2026-09-23) and will drift; the GitHub repo creation dates (SDKs 2026-09-04, skills 2026-08-24) are stable.
