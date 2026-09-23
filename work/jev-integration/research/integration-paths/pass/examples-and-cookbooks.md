# integration-paths / Q3 — Examples, cookbooks, sample repos (cluster `examples-and-cookbooks`)

Subject: Jev (TypeSafe, typesafe.ai). Date checked: 2026-09-23. Method: `curl -sL` raw HTML / Mintlify `.md` pages saved to scratchpad and grepped; GitHub REST API (unauthenticated), npm and PyPI registry JSON. No accounts, no API calls, no console pages beyond logged-out shells. Every quote below was grep-counted on its saved source (counts in "Evidence quotes").

Reference base for absence claims (rule 2): `https://docs.typesafe.ai/llms.txt` (the docs nav index, 112 entries), `https://docs.typesafe.ai/sitemap.xml` (same page set), `https://api.github.com/orgs/typesafe-ai/repos` (10 public repos), and the git trees of the four official repos.

## Claims

| # | Claim (one sentence) | Verdict | Source URL (the page, not the site) | Date checked | How verified | Documented vs. implied |
|---|---|---|---|---|---|---|
| 1 | The official docs carry a "Cookbooks" section of exactly 18 worked examples, grouped as Self-consistency (2), Batching (1), How-to (9), Extraction (3), Classification (3). | documented | https://docs.typesafe.ai/cookbooks | 2026-09-23 | `cookbooks.md` tables counted (2+1+9+3+3=18); `llms.txt` lists 18 `/cookbooks/*` URLs; `sitemap.xml` lists the same 18. | Documented |
| 2 | Every one of the 18 cookbooks is written in Python against `typesafe-sdk`; none is offered in another language. | documented | https://docs.typesafe.ai/cookbooks | 2026-09-23 | Fenced-block language tally over all 18 `.md` pages: only `python`, `bash`, `json`, `text`, `mermaid`; zero `ts`/`js`/`go` blocks. | Documented (by code content) |
| 3 | The cookbooks are inline code walkthroughs on the doc page; no cookbook page links a notebook, Colab, or downloadable script. | documented | https://docs.typesafe.ai/llms-full.txt | 2026-09-23 | `grep -oiE 'colab\.research|\.ipynb'` over `llms-full.txt` (910 KB, all pages) → 0 hits; rendered HTML of `/cookbooks/citation_check` grepped for `open in colab|download|jupyter|.ipynb` → 0 hits (only the nav's `github.com/typesafe-ai` link). | Documented (absence rests on the full-docs dump + rendered page) |
| 4 | Cookbooks describe themselves as complete worked examples: "a real dataset, the TypeSafe questions that decide something about it, and the code that turns those decisions into a working system." | documented | https://docs.typesafe.ai/cookbooks | 2026-09-23 | Quote grep count 1 on `cookbooks.md`. | Documented |
| 5 | Each cookbook installs a helper package `cooksafe` (PyPI 0.2.0, "Shared helpers for the TypeSafe cookbooks": `JsonCache`, `make_playground_link`) and reads `TYPESAFE_API_KEY`; the cookbook text says a cached `json_cache.json` and, for function-calling, `trader.py`/`dispatch.py` "ship with the cookbook". | documented | https://docs.typesafe.ai/cookbooks/citation_check | 2026-09-23 | `pip install ... 'cooksafe>=0.2.0,<0.3.0'` appears in 17 of 18 cookbook setup blocks (hierarchical_classification has no bash block); PyPI `cooksafe` JSON read; quotes grep-counted 1 each. | Documented |
| 6 | The companion files the cookbooks say "ship with the cookbook" are not publicly locatable: `cooksafe`'s PyPI README points at `github.com/typesafe-ai/CookSafe`, which returns 404 (API and HTML) and is absent from the org's public repo listing. | contradicted (docs say the files ship; the only named location 404s) | https://pypi.org/project/cooksafe/ vs https://github.com/typesafe-ai/CookSafe | 2026-09-23 | `curl api.github.com/repos/typesafe-ai/CookSafe` → 404; `curl github.com/typesafe-ai/CookSafe` → 404; org listing of 10 repos has no CookSafe; GitHub repo search `cooksafe` returns 4 unrelated kitchen-safety repos. | Documented statement vs. missing artifact |
| 7 | The 18 cookbooks cover: classification (hierarchical taxonomies, SEC industry groups with confidence fallback, moderation labels), routing/function-calling, extraction (dates, regex-preselected values, SDE verification cascade), guardrails/moderation (jailbreak/hazard screening), verification (citation checking), search/re-ranking/RAG gating, entity alignment, structure recovery, agent skill selection, and ML feature extraction. | documented | https://docs.typesafe.ai/cookbooks | 2026-09-23 | Read the index tables and each page's one-line summary (`llms.txt` descriptions). | Documented |
| 8 | Four cookbooks state the model and date behind their published numbers: `jev-1.12` on 2026-08-11 (entity_alignment), 08-12 (classification_using_confidence), 08-15 (llm_guardrails), 08-16 (citation_check); the other 14 do not carry such a line. | documented | https://docs.typesafe.ai/cookbooks/citation_check | 2026-09-23 | `grep -n 'Numbers below came from'` across all 18 `.md` pages → 4 hits. | Documented |
| 9 | The docs' "Patterns" section holds 4 architectural patterns (Speculative Fan-Out, Confidence-Gated Routing, Composite Scoring, Intent Routing), each illustrated by one Python snippet of the code-side branching over `response.answers[...]` — not a runnable sample. | documented | https://docs.typesafe.ai/patterns | 2026-09-23 | `patterns.md` table has 4 rows; each pattern page has exactly 1 `python` block and 1 `mermaid` block and no install/bash block. | Documented |
| 10 | The docs' "Demos" section lists exactly one demo, the Smart Home Assistant (Vite/React SPA, Loom video), and its page says "The full source code will be available on GitHub at release." — no such repo exists in the official org's 10 public repos. | documented (statement); source not published | https://docs.typesafe.ai/demos/smart-home | 2026-09-23 | `demos.md` has one bullet; quotes grep-counted 1; `api.github.com/orgs/typesafe-ai/repos` lists 10 repos, none smart-home/demo. | Documented statement; absence via org listing |
| 11 | The Quick start's worked example is support-ticket triage: a `choice` (department: billing/technical/sales), a `score` (frustration, 3 levels), and a `noul` (is_urgent), shown as curl + request/response JSON + Python SDK. | documented | https://docs.typesafe.ai/introduction/quickstart | 2026-09-23 | Page read; JSON blocks copied verbatim in "Example inventory" E0. | Documented |
| 12 | The decision schema in every official example is a `questions` map keyed by caller-chosen names, each `{type: choice|score|noul, instructions, criteria?}`: `choice` criteria = object label→description-or-null; `score` criteria = ordered array of level descriptions; `noul` = instructions (+ optional `NoulCriteria(true=…, false=…)`). | documented | https://docs.typesafe.ai/introduction/quickstart | 2026-09-23 | Quickstart request body; SDK pages; cookbook question blocks (`NoulCriteria` in rerank, llm_guardrails). | Documented |
| 13 | Official docs state a `Choice` accepts up to 255 options ("A `Choice` question accepts up to 255 options"), consistent with the launch post ("Jev supports a cardinality up to 255"). | documented | https://docs.typesafe.ai/cookbooks/semantic_find | 2026-09-23 | Quote grep count 1 (docs) and 2 (launch post HTML, duplicated markup). | Documented |
| 14 | The "Example use cases" page is a brainstorming map (5 category cards, 19 industry accordions, a 10-row "decision shape" table: Classification, Detection, Scoring, Routing, Search, Retrieval, Ranking, Verification, ML Feature Extraction, Structured Data Extraction), not worked examples. | documented | https://docs.typesafe.ai/concepts/use-case-map | 2026-09-23 | Page read; counted `<Card>` (5), `<Accordion>` (19), table rows (10). | Documented |
| 15 | The official agent skill repo `typesafe-ai/skills` (1,981 stars) contains a single skill (`skills/typesafe-ai/SKILL.md` + LICENSE; 9 tree paths) and no example code; its SKILL.md tells the agent to read the live docs and cookbooks. | documented | https://github.com/typesafe-ai/skills | 2026-09-23 | `git/trees/main?recursive=1` → 9 paths; SKILL.md fetched raw (10,040 bytes); quote grep count 1. | Documented |
| 16 | The official JS SDK repo ships one runnable example, `examples/demo.ts` (54 lines; "Run with `npm run demo`"), a support-ticket sample with `noul`/`choice`/`score`; the official Python SDK repo has no examples directory. | documented | https://github.com/typesafe-ai/typesafe-sdk-js/blob/main/examples/demo.ts | 2026-09-23 | JS tree (65 paths) contains `examples/demo.ts`, fetched raw; Python tree (83 paths) matched only `README.md` on `example|sample|demo|cookbook`. | Documented |
| 17 | The official `typesafe-ai/system-one-adapter-python` (277 stars) is "A drop-in replacement for `typesafe_sdk`'s `system_one` evaluation API, backed by LLM APIs" for cost/speed comparison — it is linked from the launch post and is a reference for the SDK call shape, not a Jev example. | documented | https://github.com/typesafe-ai/system-one-adapter-python | 2026-09-23 | README fetched; quote grep count 1; launch post HTML hrefs include this repo. | Documented |
| 18 | The launch post says "Below is the simplest of the 4 workflows we're publishing" and links "our workflow evals site" (`https://evals.typesafe.ai/`), which has four workflow pages (Security Incidents, Agent Trace Observability, Invoice Processing, Customer Service), each stating inputs and the output action set with accuracy/cost/time plots. | documented | https://typesafe.ai/blog/introducing-system-one-models-and-jev | 2026-09-23 | Quote grep count 2; `evals.typesafe.ai` index (200, 65 KB) links the four `.html` pages; two fetched (200). | Documented |
| 19 | The launch post promises "examples, disagreements, full queries, and each workflow" on the evals site, but the two workflow pages fetched contain zero occurrences of the API's question-type tokens (`"type": "choice|score|noul"`) and no JSON assets — whether the full queries are exposed in some other form is unsettled. | unknown | https://evals.typesafe.ai/customer_service.html | 2026-09-23 | `customer_service.html` (167 KB) and `security_incidents.html` (47 KB) grepped; 0 question-type tokens; no `.json` asset references. Two of four pages checked. | Implied by the blog wording; not confirmed on the pages fetched |
| 20 | The launch post's two "Fun Demos" (Doom bot, Wikiracing) are video-only; it says "we intend to not only release an in-depth walkthrough", and no Doom/Wikiracing page exists in the docs nav. | documented (statement); walkthrough absent | https://typesafe.ai/blog/introducing-system-one-models-and-jev | 2026-09-23 | Quote grep count 2; `grep -i 'doom\|wikirac'` on `llms.txt` → 0. | Documented statement; absence via nav index |
| 21 | The launch post's "actual query" link is a Playground share URL that, fetched logged-out, returns the console login shell (22 "login" occurrences), so the side-by-side example is not readable without an account. | documented | https://console.typesafe.ai/playground?share=shr_13a74b495fb786c4bd7964f11597301e7c9 | 2026-09-23 | `curl -sL` → 200, 46 KB, `grep -c login` 22; no `questions`/`noul`/`choice` strings. | Documented (logged-out behaviour) |
| 22 | The homepage contains no example, cookbook, or GitHub links — its only outbound docs/console hrefs are `console.typesafe.ai/`, `docs.typesafe.ai/`, `docs.typesafe.ai/introduction`. | documented | https://typesafe.ai/ | 2026-09-23 | `grep -oE 'https?://(github\.com|docs\.typesafe\.ai|console\.typesafe\.ai)[^"]*'` on the 590 KB served HTML → those 3 URLs only. | Documented (by href inventory) |
| 23 | The agent-skill page points agents at `https://console.typesafe.ai/docs/cookbooks`, which redirects to `console.typesafe.ai/login?returnTo=%2Fdocs%2Fcookbooks` — the same cookbooks are freely readable at `docs.typesafe.ai/cookbooks`. | documented | https://docs.typesafe.ai/agent-skill | 2026-09-23 | `curl -sL -w '%{url_effective}'` → 200 at the login URL. | Documented |
| 24 | SKILL.md's "Migration guide" link (`https://docs.typesafe.ai/migrating-to-v1.md`) returns 404 and is absent from `llms.txt`/sitemap. | documented (broken link) | https://github.com/typesafe-ai/skills/blob/main/skills/typesafe-ai/SKILL.md | 2026-09-23 | `curl` → 404; `grep migrating llms.txt` → 0. | Documented |
| 25 | Third-party examples are numerous: unauthenticated GitHub search returned 2,374 repositories for `typesafe jev`, 580 for `"typesafe.ai"`, and 2,312 for `jev typesafe example OR cookbook OR demo` on 2026-09-23. | documented (search totals; contents unverified) | https://api.github.com/search/repositories?q=typesafe+jev | 2026-09-23 | `total_count` fields read from the three JSON responses (HTTP 200). Counts include noise (e.g. `tinystruct/tinystruct`, `kitfunso/hippo-memory`). | Documented (counts), not vetted |
| 26 | At least 12 community "awesome-jev"-style lists exist; the two largest by stars self-report different coverage: `yibie/awesome-jev` (1,439 stars, created 2026-09-17) lists 407 linked entries across 14 categories, while `heyjunpenn/awesome-jev` says "834" in its GitHub description and "832 open-source projects" in its README (count spread — recorded, not resolved). | documented (third-party, self-reported) | https://github.com/yibie/awesome-jev | 2026-09-23 | Repo API JSON; README fetched raw and `- [` lines counted per `###` section; heyjunpenn README lines 6/28 grepped. | Documented (self-reported counts) |
| 27 | Third-party task coverage (from repo descriptions and yibie's category tallies) includes: MCP servers (`jkudish/jev-mcp`, `itsmostafa/typesafe-mcp`, `Brainwires/jevwire`), code review (`devagrawal09/jev-review`), per-turn model routing (`0xNatoshi/jev-codex-router`), web/codebase search & re-ranking (`superagents-lab/jev-search`, `ellipsis-dev/blink`), browser/voice control, games/sim (`fhshaik/typesafe-mario`, `RomanSlack/jev-drone`), Postgres extensions (`realZachi/pg-jev`, `giuliosmall/pg_typesafe`), trading bots, profanity/toxicity screening (`gg-friggin-ez`), an n8n node, and Ruby/Java(Spring AI)/Go/Effect clients. | documented (descriptions only) | https://api.github.com/search/repositories?q=typesafe+jev | 2026-09-23 | Descriptions and `language` fields from GitHub search JSON and npm search JSON; no third-party code was read. | Documented (metadata), implied (that the code works) |
| 28 | Two GitHub organisations use the name: `typesafe-ai` (official — blog `https://typesafe.ai/`, created 2024-05-28, 10 public repos, hosts both SDKs and `skills`) and `TypeSafeAI` (created 2026-09-18, 7 repos, self-described "This is an UNOFFICIAL organization made for community repos."). | documented | https://api.github.com/orgs/TypeSafeAI | 2026-09-23 | Both org JSONs read; quote grep count 1; PyPI `typesafe-sdk` and npm `@typesafe-ai/sdk` repository fields point at `typesafe-ai/*`. | Documented |
| 29 | Vercel publishes an official-to-Vercel AI SDK provider `@ai-sdk/typesafe-ai` (3.0.5, in the `vercel/ai` monorepo, `packages/typesafe-ai`) whose README example calls `experimental_evaluate` with question types `choice` and `boolean` (not `noul`) and states "Evaluation is experimental." | documented (third-party to TypeSafe) | https://github.com/vercel/ai/blob/main/packages/typesafe-ai/README.md | 2026-09-23 | npm registry JSON for `@ai-sdk/typesafe-ai`; README fetched raw; quote grep count 1. | Documented |
| 30 | The Python SDK "Usage" page carries gateway examples (OpenRouter `~typesafe/jev-latest`, Vercel AI Gateway `typesafe-ai/jev`) as alternate `base_url` snippets — the only official examples of calling Jev through a third-party endpoint. | documented | https://docs.typesafe.ai/sdk/python/usage | 2026-09-23 | Page read; both `<Tab>` snippets present. | Documented |
| 31 | GitHub code search (`/search/code?q="docs.typesafe.ai"`) requires authentication (HTTP 401), so "which repos reference the docs" could not be measured without a token. | documented (tool limit) | https://api.github.com/search/code?q=%22docs.typesafe.ai%22 | 2026-09-23 | `curl` → 401 `{"message":"Requires authentication"}`. | n/a |

## Example inventory

Legend — **Official** = published by TypeSafe (docs.typesafe.ai, typesafe.ai, `typesafe-ai` GitHub org, TypeSafe-authored PyPI/npm). **Third-party** = anyone else, including the unofficial `TypeSafeAI` org. **Runnable** = a complete program you can execute as published; **walkthrough** = complete code shown inline across the page but companion files/data referenced without a public download; **snippet** = a fragment.

### E0 — Quick start (Official, Python + curl + JSON, runnable snippet)
- URL: https://docs.typesafe.ai/introduction/quickstart
- Task: support-ticket triage (department routing, frustration score, urgency detection).
- Schema (verbatim request body):
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
- Response shape (verbatim): `"answers": { "department": { "type": "choice", "choice": "technical", "confidence": 0.78, "probabilities": {...} }, "frustration": { "type": "score", "score": 1.0, "confidence": 1.0, "legend": {...}, "probabilities": {...} }, "is_urgent": { "type": "noul", "noul": 1.0 } }, "usage": { "input_tokens": 392, "output_tokens": 65 }` with `"model": "jev-1.13.0"`.

### E1–E18 — Cookbooks (Official, all Python, all walkthroughs)
Common properties: each page is a full inline Python program with a `## Setup` block (`pip install ... 'cooksafe>=0.2.0,<0.3.0'`, set `TYPESAFE_API_KEY`), uses `IPython.display`, decorates API calls with a `@json_cache` from `cooksafe`, and refers to a `json_cache.json` that "ships with the cookbook" — but no cookbook page offers a download and the only named repo (`typesafe-ai/CookSafe`) 404s (claim 6). Levels are the docs' own labels.

| # | Cookbook | URL | Task | Level | Schema shape (verbatim where short) |
|---|---|---|---|---|---|
| E1 | Self-consistency: nouls | https://docs.typesafe.ai/cookbooks/consistency_noul_cookbook | Repeat noul questions on a claim; route uncertain probabilities to human review | Beginner | `questions = {key: Noul(instructions=question) for key, question in QUESTIONS.items()}`; state `{"uid": ..., "claim": CLAIM}` |
| E2 | Self-consistency: choices | https://docs.typesafe.ai/cookbooks/consistency_choice_cookbook | Moderation labels with an added "uncertain" outcome; label agreement vs. automatic-action share | Beginner | `questions = {key: Choice(instructions=instructions, criteria=choices) for key, (instructions, choices) in QUESTIONS.items()}`; state `{"uid": ..., "post": POST}` |
| E3 | Parallel questions | https://docs.typesafe.ai/cookbooks/parallel_questions | 13-question regulatory briefing over the GDPR article in one call (batching) | Beginner | `QUESTIONS = {"breach_72h": Noul(instructions="Must a personal data breach be reported to the supervisory authority within 72 hours?"), "applies_non_eu": Noul(...), ...}` |
| E4 | Re-ranking | https://docs.typesafe.ai/cookbooks/rerank_typesafe | Re-rank BM25 shortlists for 40 CLERC legal queries, one Noul per query–candidate pair | Beginner | `question = Noul(instructions="Is this candidate the cited case?", criteria=NoulCriteria(true="The candidate states the specific rule the query cites.", false="The candidate is only on a similar topic."))` |
| E5 | Line-by-line search | https://docs.typesafe.ai/cookbooks/semantic_find | Semantic search over GitHub ToS: Choice over 218 line ids + Noul "does an answer exist" | Beginner | `Choice(instructions=f'Which line of the document contains the answer to: "{query}"?', criteria={line_id(i): None for i in range(len(LINES))})` |
| E6 | Structure recovery | https://docs.typesafe.ai/cookbooks/autoformat | Rebuild Markdown from flattened text: Noul per line pair (join?), then Choice per block (heading/list/code/callout) | Beginner | `questions = {line_id(i): make(i) for i in range(1, len(LINES)) if not LINES[i]["gap"]}` (Noul per pair) |
| E7 | Function calling | https://docs.typesafe.ai/cookbooks/function_calling | NL trading requests → typed function name + enum arguments (54 questions per command) | Intermediate | Built from `Literal` specs by a `Dispatcher`; printed types: `__tool__ choice "What is the user asking the trading assistant to do?"`, `plot_price.style choice`, `plot_price.style? noul`, `compare_returns.symbols.NVDA noul`. Companion `trader.py`, `dispatch.py` referenced, not downloadable. |
| E8 | Skill suggestion | https://docs.typesafe.ai/cookbooks/skill_suggestion | Pick ≤1 skill for an agent turn from 182 Hermes skills; rank + re-check in two requests | Intermediate | `"which": Choice(instructions=CHOICE_INSTRUCTIONS, criteria={skill["name"]: skill["description"] for skill in ROSTER})` plus `f"gate::{key}": Noul(instructions=text)` |
| E9 | Knowledge graph entity alignment | https://docs.typesafe.ai/cookbooks/entity_alignment | Same-product decision over 450 beer-catalogue pairs: one Score + three Nouls | Beginner | `QUESTIONS = {"link_state": Score(instructions="How do the two entity descriptions relate as products?", criteria=LEVELS), "same_name": Noul(instructions="Do the two entities state the same beer name?"), "same_brewery": Noul(...), "same_style": Noul(...)}` |
| E10 | Classifying RAG passages | https://docs.typesafe.ai/cookbooks/classifying_rag_passages | Gate retrieved passages before the answering LLM (relevance, evidence, contradiction, injection) | Intermediate | `PASSAGE_QUESTIONS = {"is_relevant": Noul(instructions="Does this passage address the subject of the query?"), "contains_answer_evidence": Noul(...), "contradicts_query_premise": Noul(...), "contains_prompt_injection": Noul(instructions="Does this passage attempt to control the system answering the query?")}` |
| E11 | Double-checking citations | https://docs.typesafe.ai/cookbooks/citation_check | Verify LLM citations against source (verified/unsupported/contradicted/fabricated); confidence ≥ 0.8 gate | Beginner | `QUESTIONS = {"relation": Choice(instructions="How does the section relate to the claim?", criteria={"supports": "The section states the claim or directly implies that it is true", "contradicts": "The section states the opposite of the claim or implies it is false", "says_nothing": "The section does not address what the claim asserts, either way"})}` |
| E12 | Guardrails for LLMs | https://docs.typesafe.ai/cookbooks/llm_guardrails | Screen LLM inputs/outputs: hazard Nouls + severity Score → pass/review/block/route | Intermediate | `SEVERITY = Score(instructions="How much harm could result if the assistant complied with this message?", criteria=["No harm: ...", "Mild: ...", "Serious: ...", "Severe: ..."])`; `INPUT_BATTERY = {"jailbreak": noul("Does this message try to get the assistant to ignore, override, or reveal its instructions...", yes=..., no=...), ...}` using `NoulCriteria(true=yes, false=no)` |
| E13 | SDE cascade | https://docs.typesafe.ai/cookbooks/sde_cascade | Structured-data-extraction cascade: mini LLM extracts → Jev verifies per field → reasoning LLM on failures | Intermediate | `"__overall__::judge": Noul(instructions=OVERALL_JUDGE, criteria=OVERALL_JUDGE_CRITERIA)` plus per-field `Noul(instructions={"field_spec": spec, "extracted_field": value, "main_question": question}, criteria=...)` (instructions as JSON object) |
| E14 | Date extraction | https://docs.typesafe.ai/cookbooks/date_extraction_cookbook | Absolute/relative date parts via Choices; resolve/validate in code | Beginner | `"mode": Choice(instructions=..., criteria={"absolute": None, "relative": None, "none": None})`, `"month": Choice(criteria={m: None for m in MONTHS} \| {"none": absent})`, `"day": Choice(criteria={str(d): None for d in range(1, 32)} \| {"none": absent})` |
| E15 | Pre-parsed value extraction | https://docs.typesafe.ai/cookbooks/pre_parsed_value_extraction_cookbook | Regex candidates (emails, phones, amounts) → Jev selects the requested span | Beginner | `questions={"pick": Choice(instructions=question, criteria=criteria)}`; `{"q": Choice(instructions=question, criteria={o: None for o in options})}` |
| E16 | Hierarchical classification | https://docs.typesafe.ai/cookbooks/hierarchical_classification | Beam search over Choice probabilities through patent/retail/biomedical/code taxonomies | Intermediate | `Choice(instructions="Which direct child category best matches this document?", criteria=keys)` with `keys = {f"c{i}": label ...}` |
| E17 | Autoresearch feature discovery | https://docs.typesafe.ai/cookbooks/autoresearch_feature_discovery | Loop proposes questions → numeric features → CatBoost regressor | Advanced | `Score(instructions=feature["question"], criteria=INTENSITY_LEVELS)` or `Noul(instructions=feature["question"], criteria=PRESENCE_CRITERIA)` per proposed feature |
| E18 | Classification using confidence | https://docs.typesafe.ai/cookbooks/classification_using_confidence | SEC filings → 75 industry groups; report division instead when confidence < 0.9 | Beginner | `"group": Choice(instructions=QUESTION, criteria={group: describe(group) for group in sorted(GROUPS)})` |

### E19–E22 — Patterns (Official, Python, snippets)
- https://docs.typesafe.ai/patterns/fan-out — speculative fan-out for ticket triage; snippet branches on `category.choice`, `bug_severity.score > 1.5 and bug_repro.noul > 0.6`, `refund.noul > 0.7`, `frustration.score > 1.5`.
- https://docs.typesafe.ai/patterns/confidence-routing — banking intent; `if action.confidence < 0.6: route_to_support_agent(...)`, `approve_transfer` only `if action.confidence > 0.85`.
- https://docs.typesafe.ai/patterns/composite-scoring — hiring: four `score / 4` dimensions weighted in code for IC vs EM.
- https://docs.typesafe.ai/patterns/intent-routing — support tickets: `intent.confidence < 0.5` → human; `complaint` with `complexity.score > 1` → human, else LLM specialist.
No question definitions are shown on the pattern pages; only the consuming code.

### E23 — Smart home assistant demo (Official, Vite/React, NOT published)
- URL: https://docs.typesafe.ai/demos/smart-home — Loom video + prose; speculative fan-out (category / domain / device / action Choices, one Noul "more than one distinct action"), LLM fallback for conversation. "The full source code will be available on GitHub at release." No repo in the official org.

### E24 — JS SDK demo (Official, TypeScript, runnable)
- URL: https://github.com/typesafe-ai/typesafe-sdk-js/blob/main/examples/demo.ts — support ticket; schema verbatim:
```ts
questions: {
  isBilling: noul("Is this ticket about billing?"),
  sentiment: choice("What is the customer's tone?", { calm: null, frustrated: null, angry: null }),
  urgency: score("How urgent is this ticket?", ["can wait", "this week", "today", "right now"]),
  refundRisk: score("How likely is the customer to demand a refund?", ["unlikely", "possible", "likely"]),
}
```

### E25–E27 — SDK landing/usage pages (Official, snippets)
- https://docs.typesafe.ai/sdk/python and https://docs.typesafe.ai/sdk/python/usage — Python sync/async ticket example (`billing` Noul, `tone` Choice `{"calm": None, "frustrated": None, "angry": None}`, `urgency` Score `["can wait", "this week", "today"]`); typed `response_model`; raw dict questions `{"type": "noul", "instructions": "About billing?", "weight": 2}`; OpenRouter and Vercel AI Gateway `base_url` snippets.
- https://docs.typesafe.ai/sdk/javascript — `category: choice("What is this ticket about?", { billing: null, technical: null, other: null })`.

### E28 — Agent skill (Official, Markdown, not code)
- https://docs.typesafe.ai/agent-skill and https://github.com/typesafe-ai/skills/blob/main/skills/typesafe-ai/SKILL.md — instructs a coding agent to read `llms.txt` and cookbooks; three example prompts; no sample code.

### E29 — Workflow evals (Official, web pages, queries not exposed in served HTML)
- https://evals.typesafe.ai/ → `security_incidents.html` (output: one of AUTO CLOSE / NOTIFY USER / ESCALATE TIER2 / KILL PROCESS / DISABLE ACCOUNT / ESCALATE URGENT), `customer_service.html` (output: any of SAY / REFUND / FREEZE CARD / SET INTENT / HAND OFF / FLAG FOR REVIEW / CLOSE), `agent_trace_observability.html`, `invoice_processing.html` (last two not fetched). Task: multi-signal operational decisions; Jev line on the index: "Jev · workflow · 67.8% · $0.0004 · 0.4 s" (configuration: "Each point averages one model configuration's accuracy, cost and time over the four workflows with equal weight, against the consensus labels. Every model runs at its provider's default reasoning setting.").

### E30 — Launch-post demos (Official, video only)
- https://typesafe.ai/blog/introducing-system-one-models-and-jev — side-by-side query (Playground share, login-walled), Doom bot ("~$7/hour" at 10 queries/s, stated in prose), Wikiracing (2-stage scoring then explicit choice for >255 links). No code published.

### Third-party (sampled by GitHub/npm metadata only; code not read)
| Repo / package | Task | Language | Notes |
|---|---|---|---|
| https://github.com/yibie/awesome-jev | Curated list, 407 entries; categories: Classification & Routing 37, Verification & Guardrails 31, Scoring & Ranking 28, Agent Decisions 43, Infra/SDKs 66, Game & Sim 19, Content Moderation 7, Finance 5, Compliance 1, Evaluation 26, Calibration 27, Data Labeling 7, Adaptive UI 8, Discussions 72 | Markdown | 1,439 stars; created 2026-09-17; "Curation is not endorsement" |
| https://github.com/heyjunpenn/awesome-jev | Catalog; "834" (description) / "832 open-source projects" (README) | Astro | count spread recorded |
| https://github.com/Anil-matcha/awesome-jev-by-typesafe | Guide + starter code | Python/Markdown | 816 stars; repo created 2023-05-17 (predates Jev — repurposed repo) |
| https://github.com/jkudish/jev-mcp ; https://github.com/itsmostafa/typesafe-mcp ; https://github.com/Brainwires/jevwire | MCP servers exposing Jev judgments | JS / Go / (unstated) | 309 / 275 / 18 stars |
| https://github.com/devagrawal09/jev-review | Staged code review + dashboard | TypeScript | 572 stars |
| https://github.com/0xNatoshi/jev-codex-router | Per-turn model/reasoning routing for Codex | JavaScript | routing |
| https://github.com/superagents-lab/jev-search ; https://github.com/ellipsis-dev/blink | Web search source selection/ranking; codebase search | TypeScript | search/rerank |
| https://github.com/realZachi/pg-jev ; https://github.com/giuliosmall/pg_typesafe | PostgreSQL extensions (NL questions over tables; categorical classification) | Shell / (unstated) | extraction/classification in-DB |
| https://github.com/fhshaik/typesafe-mario ; https://github.com/RomanSlack/jev-drone | Game/sim agents from structured state | Python | real-time decisions |
| npm `gg-friggin-ez` | Profanity/toxicity screener | Node | moderation |
| npm `n8n-nodes-typesafe-ai` ; `@mhingston5/jev-cli` ; `jev-repl` ; `pi-typesafe` | n8n node; CLIs; REPL | JS/TS | integrations |
| https://github.com/joshmn/typesafe-sdk (Ruby) ; https://github.com/spring-ai-community/spring-ai-typesafe (Java) ; npm `@effect-agent/ai-typesafe` | Community clients | Ruby / Java / TS | unofficial SDKs |
| https://github.com/vercel/ai/tree/main/packages/typesafe-ai (`@ai-sdk/typesafe-ai` 3.0.5) | Vercel AI SDK provider, `experimental_evaluate` | TypeScript | uses `boolean` where TypeSafe says `noul` |
| https://github.com/TypeSafeAI/* (clarity-judge, jev-harness, typesafe-playground "110 use cases", typesafe-router, typesafe-ui) | Community org, self-declared UNOFFICIAL | TypeScript | do not cite as official |
| https://github.com/TheoLeeCJ/SemIf-OpenJev (4,033 stars) ; https://github.com/wfzyx/von ; https://github.com/logan-markewich/jeff ; https://github.com/kyegomez/open-jev | Open re-implementations / drop-in alternatives, explicitly unaffiliated | Python | not Jev examples; noise for this question |

## Evidence quotes

Format: quote — URL — `grep -c` on the saved source.

1. "Each cookbook is a worked example: a real dataset, the TypeSafe questions that decide something about it, and the code that turns those decisions into a working system." — https://docs.typesafe.ai/cookbooks.md — 1
2. "The full source code will be available on GitHub at release." — https://docs.typesafe.ai/demos/smart-home.md — 1
3. "This demo is a simple Vite/React single-page app" — https://docs.typesafe.ai/demos/smart-home.md — 1
4. "Every API call is cached in `json_cache.json`, which ships" (…"with the cookbook, so re-running replays the published numbers instead of calling the API.") — https://docs.typesafe.ai/cookbooks/citation_check.md — 1
5. "Two modules sit beside this file." (…"`trader.py` holds the ten…", "`dispatch.py` holds the code that reads a…") — https://docs.typesafe.ai/cookbooks/function_calling.md — 1
6. "Numbers below came from `jev-1.12` on 2026-08-16." — https://docs.typesafe.ai/cookbooks/citation_check.md — 1 (and 08-11 / 08-12 / 08-15 on entity_alignment / classification_using_confidence / llm_guardrails)
7. "A `Choice` question accepts up to 255 options" — https://docs.typesafe.ai/cookbooks/semantic_find.md — 1
8. "Jev supports a cardinality up to 255" — https://typesafe.ai/blog/introducing-system-one-models-and-jev — 2 (page markup is duplicated)
9. "Below is the simplest of the 4 workflows we" (…"'re publishing") — https://typesafe.ai/blog/introducing-system-one-models-and-jev — 2
10. "we intend to not only release an in-depth walkthrough" — https://typesafe.ai/blog/introducing-system-one-models-and-jev — 2
11. "Learning to think in terms of discrete, atomic decisions that compose into complex system behavior is a key skill" — https://docs.typesafe.ai/patterns.md — 1
12. "Vibe it: the agent skill" — https://docs.typesafe.ai/introduction/quickstart.md — 1
13. "Point your agent at a [specific cookbook]" — https://docs.typesafe.ai/agent-skill.md — 1
14. "Jev is **not** a drop-in replacement for the LLM behind Claude Code" — https://docs.typesafe.ai/introduction/coding-agents.md — 1
15. "The live TypeSafe docs are the source of truth." — https://raw.githubusercontent.com/typesafe-ai/skills/main/skills/typesafe-ai/SKILL.md — 1
16. "A drop-in replacement for `typesafe_sdk`'s `system_one` evaluation API, backed by LLM" — https://raw.githubusercontent.com/typesafe-ai/system-one-adapter-python/main/README.md — 1
17. "Run with `npm run demo`. Needs TYPESAFE_API_KEY in the environment." — https://raw.githubusercontent.com/typesafe-ai/typesafe-sdk-js/main/examples/demo.ts — 1
18. "Evaluation is experimental." — https://raw.githubusercontent.com/vercel/ai/main/packages/typesafe-ai/README.md — 1
19. "This is an UNOFFICIAL organization made for community repos." — https://api.github.com/orgs/TypeSafeAI (`description`) — 1
20. "Each point averages one model configuration's accuracy, cost and time over the four workflows" — https://evals.typesafe.ai/ — 1
21. "Shared helpers for the TypeSafe cookbooks" — https://pypi.org/pypi/cooksafe/json (`summary`) — read from JSON
22. "See the [CookSafe cookbooks](https://github.com/typesafe-ai/CookSafe/tree/main/cookbooks) for complete examples." — https://pypi.org/pypi/cooksafe/json (`description`) — read from JSON; target 404s
23. "Example task categories" — https://docs.typesafe.ai/concepts/use-case-map.md — 1

## Fetch log

All via `curl -sL -A "Mozilla/5.0"` unless noted; status = final HTTP status.

| URL | Status | Note |
|---|---|---|
| https://docs.typesafe.ai/ | 200 | 276 KB |
| https://docs.typesafe.ai/sitemap.xml | 200 | 112 URLs |
| https://docs.typesafe.ai/llms.txt | 200 | nav index, 112 entries |
| https://docs.typesafe.ai/llms-full.txt | 200 | 910 KB full dump |
| https://typesafe.ai/ | 200 | 590 KB (Framer) |
| https://typesafe.ai/sitemap.xml | 200 | 13 URLs |
| https://typesafe.ai/llms.txt | 404 | |
| https://typesafe.ai/blog/introducing-system-one-models-and-jev | 200 | 259 KB |
| https://docs.typesafe.ai/{cookbooks, cookbooks/<18 slugs>, patterns, patterns/<4>, demos, demos/smart-home, concepts/use-case-map, introduction/quickstart, agent-skill, sdk, sdk/python, sdk/javascript, sdk/python/usage, introduction/coding-agents, api}.md | 200 (all 36) | sizes 588 B – 71 KB |
| https://docs.typesafe.ai/{examples,guides,recipes,use-cases,tutorials}.md | 404 (all 5) | probes; absence rests on llms.txt, not these |
| https://docs.typesafe.ai/cookbooks/citation_check (rendered HTML) | 200 | no notebook/download links |
| https://docs.typesafe.ai/migrating-to-v1.md | 404 | linked from SKILL.md |
| https://console.typesafe.ai/docs/cookbooks | 200 → redirected to https://console.typesafe.ai/login?returnTo=%2Fdocs%2Fcookbooks | login-walled |
| https://console.typesafe.ai/playground?share=shr_13a74b495fb786c4bd7964f11597301e7c9 | 200 | login shell (logged-out) |
| https://evals.typesafe.ai/ | 200 | 65 KB |
| https://evals.typesafe.ai/customer_service.html | 200 | 168 KB |
| https://evals.typesafe.ai/security_incidents.html | 200 | 47 KB |
| https://api.github.com/search/repositories?q=typesafe+jev | 200 | total_count 2374 |
| https://api.github.com/search/repositories?q=%22typesafe.ai%22 | 200 | total_count 580 |
| https://api.github.com/search/repositories?q=jev+typesafe+example+OR+cookbook+OR+demo&sort=stars | 200 | total_count 2312 |
| https://api.github.com/search/repositories?q=cooksafe | 200 | 4 unrelated |
| https://api.github.com/search/code?q=%22docs.typesafe.ai%22 | 401 | "Requires authentication" |
| https://github.com/search?q=%22typesafe.ai%22&type=repositories (raw HTML) | 200 | 271 KB; inlined result objects readable |
| https://api.github.com/orgs/typesafe-ai/repos ; /orgs/typesafe-ai | 200 | 10 repos |
| https://api.github.com/users/TypeSafeAI/repos ; /orgs/TypeSafeAI | 200 | 7 repos, "UNOFFICIAL" |
| https://api.github.com/repos/typesafe-ai/{skills,typesafe-sdk-python,typesafe-sdk-js,system-one-adapter-python}/git/trees/main?recursive=1 | 200 (all 4) | 9 / 83 / 65 / 94 paths, none truncated |
| https://raw.githubusercontent.com/typesafe-ai/{skills,typesafe-sdk-python,typesafe-sdk-js,system-one-adapter-python}/main/README.md | 200 (all 4) | |
| https://raw.githubusercontent.com/typesafe-ai/skills/main/skills/typesafe-ai/SKILL.md | 200 | 10,040 B |
| https://raw.githubusercontent.com/typesafe-ai/typesafe-sdk-js/main/examples/demo.ts | 200 | 54 lines |
| https://api.github.com/repos/typesafe-ai/CookSafe ; https://github.com/typesafe-ai/CookSafe | 404 / 404 | |
| https://raw.githubusercontent.com/{yibie/awesome-jev,Anil-matcha/awesome-jev-by-typesafe,heyjunpenn/awesome-jev}/main/README.md | 200 (all 3) | |
| https://api.github.com/repos/{yibie/awesome-jev,Anil-matcha/awesome-jev-by-typesafe} | 200 | |
| https://raw.githubusercontent.com/vercel/ai/main/packages/typesafe-ai/README.md | 200 | |
| https://registry.npmjs.org/-/v1/search?text=typesafe%20ai&size=20 ; /@typesafe-ai/sdk ; /@ai-sdk/typesafe-ai | 200 (all 3) | |
| https://pypi.org/pypi/{typesafe,typesafe-ai,typesafe_ai,typesafe-sdk,cooksafe}/json | 200 (all) ; /typesafeai/json 404 | `typesafe` 0.9.1 is an unrelated decorators package |

## Unsettled

1. **Where the cookbooks' companion files live.** The pages say `json_cache.json` (and `trader.py`/`dispatch.py`, `retrievers.py`) ship with the cookbook; the only named home (`github.com/typesafe-ai/CookSafe`) 404s and no docs page offers a download. Settled by: TypeSafe publishing the repo, or a logged-in console docs view showing attachments (out of scope: no login).
2. **Whether the evals site exposes the "full queries".** Two of four workflow pages fetched contain no question-type tokens; `agent_trace_observability.html` and `invoice_processing.html` not fetched. Settled by: fetching the remaining two and inspecting for an alternative rendering (e.g. `<details>` blocks or images of queries).
3. **Smart-home demo source.** Promised "at release"; not in the org as of 2026-09-23. Settled by: re-checking the org listing later.
4. **Third-party quality.** Everything third-party here is metadata (descriptions, stars, self-reported counts). None of the repos was read; the two awesome-lists disagree with each other and with themselves (834 vs 832). Settled by: reading a sample of the top-starred repos — belongs to Q7's cluster.
5. **Code-search-based usage counts** (which public repos import `typesafe-sdk`/`@typesafe-ai/sdk`) need an authenticated GitHub code search or a dependents page; not attempted.
6. **`Anil-matcha/awesome-jev-by-typesafe` created 2023-05-17** predates the 2026-09-15 launch — a repurposed repo; its "by-typesafe" name could be mistaken for official. Not investigated further.
