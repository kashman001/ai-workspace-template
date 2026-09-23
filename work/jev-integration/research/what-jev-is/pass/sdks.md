# Q5 — Which SDKs exist? (cluster: sdks; subject: what-jev-is)

Date checked: 2026-09-23. Method: `curl` against docs.typesafe.ai `.md` pages (Mintlify), registry JSON (npm, PyPI, JSR), GitHub REST API (unauthenticated), raw.githubusercontent.com. No accounts, no API calls to api.typesafe.ai, no search engine used (registries + GitHub API answered everything). Every quote below was copied from the fetched body and re-grepped against it.

Summary verdict: **two official client SDKs — Python (`typesafe-sdk`) and JavaScript/TypeScript (`@typesafe-ai/sdk`) — both MIT, both public on GitHub under `typesafe-ai`, both first published 2026-09-11/12.** Any other language = "call the HTTP API directly". Plus an "agent skill" (docs-context skill for coding agents; not an SDK) and a third-party-LLM shim (`system-one-adapter`). **No MCP server anywhere** (0 hits for `MCP` / `Model Context Protocol` across all 111 docs pages, SKILL.md, and both repo READMEs).

---

## SDK 1 — Python: `typesafe-sdk`

| Field | Finding | Verdict | Source |
|---|---|---|---|
| Language | Python | documented | https://docs.typesafe.ai/sdk/python.md |
| Install (verbatim) | `uv add typesafe-sdk` / `pip install typesafe-sdk` | documented | https://docs.typesafe.ai/sdk/python.md |
| Package name | `typesafe-sdk` (import name `typesafe_sdk`) | documented + registry | https://pypi.org/pypi/typesafe-sdk/json |
| Latest version | **0.7.1** | registry | PyPI `info.version` |
| Publish date (latest) | 2026-09-21T15:57:52Z | registry | PyPI `releases["0.7.1"][0].upload_time_iso_8601` |
| First public release | 0.5.7 uploaded 2026-09-11T23:05:50Z (a `0.0.1a0` pre-release exists, 2026-09-09) | registry | PyPI `releases` |
| Licence (registry) | `license_expression: "MIT"`; classifier `License :: OSI Approved :: MIT License` | registry | PyPI |
| Licence (repo) | GitHub API `license.spdx_id: "MIT"`; `pyproject.toml` `license = "MIT"`. **But the LICENSE file at `main` is an unfilled template** (see quote) | documented, with a repo defect | raw LICENSE |
| Repo URL (docs) | https://github.com/typesafe-ai/typesafe-sdk-python | documented | sdk/python.md |
| Repo URL (registry) | `project_urls.Repository: "https://github.com/typesafe-ai/typesafe-sdk-python"` | registry | PyPI |
| Repo public? | **Yes** — GitHub API HTTP 200, `"private": false` | verified | https://api.github.com/repos/typesafe-ai/typesafe-sdk-python |
| Stars / forks | 210 / 28 (created 2026-09-04T21:01:31Z, pushed 2026-09-21T15:57:12Z, 7 open issues) | verified | GitHub API |
| GitHub releases | v0.7.1, v0.7.0, v0.6.0, v0.5.7 (tags identical) | verified | /releases, /tags |
| Min runtime | **Python >= 3.10** (`requires_python: ">=3.10"`; classifiers 3.10–3.14) | documented + registry | quickstart.md, PyPI |
| Sync / async | Both: `TypeSafeClient` (sync) and `AsyncTypeSafeClient` (async) | documented | sdk/python.md; sdk/python/api/clients/{sync,async}.md |
| Env vars | `TYPESAFE_API_KEY`, `TYPESAFE_BASE_URL`, `TYPESAFE_DEFAULT_MODEL`, `TYPESAFE_LOG_LEVEL`; defaults `https://api.typesafe.ai`, `jev-latest`, timeout `10.0` s | documented | https://docs.typesafe.ai/sdk/python/api/constants.md |
| Runtime deps (0.7.1) | `httpx2>=2.0.0`, `pydantic>=2.12.0`, `pydantic-core>=2.41.1`, `tenacity>=9.0.0`, `typing-extensions>=4.13.0` | registry | PyPI `requires_dist` |
| Gateways | Docs show using the SDK via OpenRouter (`base_url="https://openrouter.ai/api"`, model `~typesafe/jev-latest`) and Vercel AI Gateway (`https://ai-gateway.vercel.sh/typesafe`, model `typesafe-ai/jev`) | documented | https://docs.typesafe.ai/sdk/python/usage.md |

**Discrepancy (dates):** docs changelog says `v0.5.7 (2026-09-14)`; PyPI upload is `2026-09-11T23:05:50Z`; the GitHub release is titled `v0.5.7 (2026-09-12)` and published `2026-09-11T23:06:00Z`. Three different dates for the same initial release. (v0.6.0, v0.7.0, v0.7.1 dates agree across docs/PyPI/GitHub.)

**Discrepancy (licence file):** repo `LICENSE` at `main` reads `Copyright (c) [year] [fullname]` — the GitHub MIT template placeholders were never filled in. Metadata (pyproject, PyPI, GitHub API) all say MIT, so the licence itself is not in doubt; the copyright holder line is.

### Changelog head (verbatim, https://docs.typesafe.ai/sdk/python/changelog.md)
```
v0.7.1 (2026-09-21)
Bug fixes
* validate the API key early and exclude the value from logged exceptions
Documentation
* add examples for usage with AI gateways

v0.7.0 (2026-09-18)
Breaking Changes
* ser/de library has been changed from `msgspec` to `pydantic`
Bug fixes
* `str` subclasses are now correctly serialized as strings instead of lists of characters
Features
* the `system_one` method now accepts a new `response_model` argument that can be set to a desired `pydantic` model for additional *type-safety*

v0.6.0 (2026-09-15)
Breaking Changes
* accept `Score.criteria` as an ordered sequence instead of a dictionary keyed by integers
Features
* improve type annotations on SDK inputs to accept abstract types like `Mapping` and `Sequence`
* improve error messages to include http details and metadata
Bug fixes
* handle invalid values in `RetryPolicy`
* make exceptions and responses picklable
Documentation
* link more concepts from main [docs](https://docs.typesafe.ai/)

v0.5.7 (2026-09-14)
This is the initial public release of TypeSafe Python SDK. Learn more in the [documentation](https://docs.typesafe.ai/sdk/python).
```
(Headings in the source are `<h2>`/`<h3>` HTML; bullet text is exact.)

### Verbatim evidence
- sdk/python.md: "Browse the [Python SDK source on GitHub](https://github.com/typesafe-ai/typesafe-sdk-python)."
- sdk/python.md: "Asynchronous and synchronous Python clients for the [TypeSafe](https://typesafe.ai) API."
- sdk/python.md: "2. Set `TYPESAFE_API_KEY` in your environment (create it [here](https://console.typesafe.ai/))"
- introduction/quickstart.md: "1. **Install the SDK** (requires Python >= 3.10)."
- introduction/quickstart.md: "2. **Use the SDK.** The client reads `TYPESAFE_API_KEY` from the environment and calls `jev-latest` by default."
- sdk/python/api/constants.md: `API_KEY_ENV = 'TYPESAFE_API_KEY'` / `BASE_URL_ENV = 'TYPESAFE_BASE_URL'` / `DEFAULT_MODEL_ENV = 'TYPESAFE_DEFAULT_MODEL'` / `LOG_LEVEL_ENV = 'TYPESAFE_LOG_LEVEL'` / `DEFAULT_BASE_URL = 'https://api.typesafe.ai'` / `DEFAULT_MODEL = 'jev-latest'` / `DEFAULT_TIMEOUT = 10.0`
- sdk/python/usage.md: "In order to use the SDK with a different API url, set `base_url` on the client or the `TYPESAFE_BASE_URL` environment variable." and "This requires the alternative API to follow the [TypeSafe OpenAPI spec](https://api.typesafe.ai/docs/)."
- PyPI JSON (raw): `"version": "0.7.1"`, `"license_expression": "MIT"`, `"requires_python": ">=3.10"`, `"author_email": "TypeSafe AI <support@typesafe.ai>"`, `"summary": "Python SDK for TypeSafe AI API."`, `"Repository": "https://github.com/typesafe-ai/typesafe-sdk-python"`; releases: `0.0.1a0` 2026-09-09T10:34:07Z, `0.5.7` 2026-09-11T23:05:50Z, `0.6.0` 2026-09-15T10:23:18Z, `0.7.0` 2026-09-18T09:12:29Z, `0.7.1` 2026-09-21T15:57:52Z
- GitHub API (raw): `"full_name": "typesafe-ai/typesafe-sdk-python"`, `"private": false`, `"stargazers_count": 210`, `"forks_count": 28`, `"license": "MIT"`, `"created_at": "2026-09-04T21:01:31Z"`, `"description": "The official Python library for the TypeSafe API"`, `"homepage": "https://docs.typesafe.ai/sdk/python"`
- pyproject.toml (main): `license = "MIT"`, `requires-python = ">=3.10"`, `maintainers = [ { name = "Daniel Gafni", email = "daniel@typesafe.ai" } ]`, `markers = ["integration: live API tests requiring TYPESAFE_API_KEY"]`
- LICENSE (main, first two lines): "MIT License" / "Copyright (c) [year] [fullname]"

---

## SDK 2 — JavaScript / TypeScript: `@typesafe-ai/sdk`

| Field | Finding | Verdict | Source |
|---|---|---|---|
| Language | JavaScript + TypeScript (ESM, CJS, `.d.ts`) | documented | https://docs.typesafe.ai/sdk/javascript.md |
| Install (verbatim) | `npm install @typesafe-ai/sdk` | documented | sdk/javascript.md |
| Package name | `@typesafe-ai/sdk` | documented + registry | https://registry.npmjs.org/@typesafe-ai%2Fsdk |
| Latest version | **0.6.0** (`dist-tags.latest`); also a `bootstrap` tag → `0.0.0-bootstrap.0` | registry | npm |
| Publish date (latest) | `"0.6.0": "2026-09-15T18:17:19.263Z"` | registry | npm `time` |
| First public release | `"0.5.7": "2026-09-12T04:13:21.117Z"` (package created `2026-09-12T02:56:18.693Z` with the bootstrap placeholder) | registry | npm `time` |
| VERSION constant | `const VERSION: "0.6.0" = "0.6.0";` — matches npm latest | documented | https://docs.typesafe.ai/sdk/javascript/api/variables/VERSION.md |
| Licence (registry) | `"license": "MIT"` (top-level and on 0.6.0) | registry | npm |
| Licence (repo) | GitHub API `"license": "MIT"`; package.json `"license": "MIT"`; LICENSE file "Copyright (c) 2026 TypeSafe" (properly filled, unlike Python) | verified | raw LICENSE |
| Repo URL (docs) | https://github.com/typesafe-ai/typesafe-sdk-js (docs link the v0.6.0-pinned `src/client.ts` and `src/types.ts`) | documented | sdk/javascript.md |
| Repo URL (registry) | `"repository": {"type": "git", "url": "git+https://github.com/typesafe-ai/typesafe-sdk-js.git"}`; `"homepage": "https://docs.typesafe.ai/sdk/javascript"` | registry | npm |
| Repo public? | **Yes** — GitHub API HTTP 200, `"private": false` | verified | https://api.github.com/repos/typesafe-ai/typesafe-sdk-js |
| Stars / forks | 229 / 24 (created 2026-09-04T22:16:47Z, pushed 2026-09-15T18:16:49Z, 14 open issues) | verified | GitHub API |
| GitHub releases | v0.6.0 (2026-09-15T18:17:21Z), v0.5.7 (2026-09-12T04:13:23Z; release title says "(2026-09-11)") | verified | /releases |
| Min runtime | **Node.js 20 or newer** — `"engines": {"node": ">=20"}` | documented + registry | sdk/javascript.md; npm |
| Sync / async | Single promise-based client `TypeSafeClient` with `systemOne<Q>(request, options?): APIPromise<SystemOneResult<Q>>` — no sync variant (JS is async by nature) | documented | sdk/javascript/api/classes/TypeSafeClient.md |
| Env vars | `ENV.apiKey = "TYPESAFE_API_KEY"`, `ENV.baseURL = "TYPESAFE_BASE_URL"`, `ENV.defaultModel = "TYPESAFE_DEFAULT_MODEL"`, `ENV.logLevel = "TYPESAFE_LOG_LEVEL"` — same four names as Python; defaults `https://api.typesafe.ai`, `jev-latest`, `warn` | documented | https://docs.typesafe.ai/sdk/javascript/api/variables/ENV.md |
| Runtime deps | none (`dependencies`/`peerDependencies` absent on 0.6.0) | registry | npm |
| npm maintainers | `alliesafe <allie@typesafe.ai>`, `diogo149 <diogo@typesafe.ai>`; package.json `"author": "evinism"` | registry | npm |
| JSR | package.json has `push:jsr` scripts, but **not published on JSR**: `https://api.jsr.io/scopes/typesafe-ai/packages/sdk` → HTTP 404 `{"code":"packageNotFound"}`; positive control `https://api.jsr.io/scopes/std/packages/path` → 200 with rows | verified absence | api.jsr.io |

**Discrepancy (dates):** docs changelog says `v0.5.7 (2026-09-11)`; npm publish timestamp is `2026-09-12T04:13:21.117Z` (UTC). Consistent with a US-timezone 09-11 evening publish; noting only because the docs date and registry date differ by calendar day. v0.6.0 agrees everywhere (2026-09-15).

**Version lag vs Python:** JS is at 0.6.0 (2026-09-15); Python is at 0.7.1 (2026-09-21). Python's 0.7.0 `response_model` feature and 0.7.1 API-key-redaction fix have no JS counterpart in the JS changelog as of today.

### Changelog head (verbatim, https://docs.typesafe.ai/sdk/javascript/changelog.md — entire page)
```
## v0.6.0 (2026-09-15)

### Breaking changes

* accept `Score.criteria` as an ordered sequence instead of a dictionary keyed by integers

## v0.5.7 (2026-09-11)

This is the initial public release of TypeSafe JavaScript and TypeScript SDK. Learn more in the [documentation](https://docs.typesafe.ai/sdk/javascript).
```

### Verbatim evidence
- sdk/javascript.md: "JavaScript and TypeScript SDK for [TypeSafe AI](https://typesafe.ai)."
- sdk/javascript.md: "Install the SDK (Node.js 20 or newer):"
- sdk/javascript.md: "Set `TYPESAFE_API_KEY` in your environment, then create and use the client:"
- sdk/javascript.md: "Answer types are inferred from your questions. The package includes ESM, CommonJS, and TypeScript declarations."
- sdk/javascript.md: "See the SDK's [client](https://github.com/typesafe-ai/typesafe-sdk-js/blob/v0.6.0/src/client.ts) and [types](https://github.com/typesafe-ai/typesafe-sdk-js/blob/v0.6.0/src/types.ts) for API options and defaults."
- sdk/javascript/api/variables/VERSION.md: `const VERSION: "0.6.0" = "0.6.0";`
- sdk/javascript/api/variables/ENV.md: "Environment variable names for client configuration. Explicit options take precedence." / `readonly apiKey: "TYPESAFE_API_KEY" = "TYPESAFE_API_KEY";` "Required API key; used when `apiKey` is omitted." / `readonly baseURL: "TYPESAFE_BASE_URL" = "TYPESAFE_BASE_URL";` "API root; defaults to `https://api.typesafe.ai`." / `readonly defaultModel: "TYPESAFE_DEFAULT_MODEL" = "TYPESAFE_DEFAULT_MODEL";` "Default model name; defaults to `jev-latest`." / `readonly logLevel: "TYPESAFE_LOG_LEVEL" = "TYPESAFE_LOG_LEVEL";` "Log level; defaults to `warn`."
- sdk/javascript/api/classes/TypeSafeClient.md: `systemOne<Q>(request, options?): APIPromise<SystemOneResult<Q>>;`
- npm JSON (raw): `"name": "@typesafe-ai/sdk"`, `"dist-tags": {"bootstrap": "0.0.0-bootstrap.0", "latest": "0.6.0"}`, `"license": "MIT"`, `"description": "TypeScript SDK for the TypeSafe API"`, `"time": {"created": "2026-09-12T02:56:18.693Z", "modified": "2026-09-15T18:17:19.633Z", "0.0.0-bootstrap.0": "2026-09-12T02:56:19.015Z", "0.5.7": "2026-09-12T04:13:21.117Z", "0.6.0": "2026-09-15T18:17:19.263Z"}`, `"engines": {"node": ">=20"}`
- GitHub API (raw): `"full_name": "typesafe-ai/typesafe-sdk-js"`, `"private": false`, `"stargazers_count": 229`, `"forks_count": 24`, `"license": "MIT"`, `"created_at": "2026-09-04T22:16:47Z"`, `"description": "The official TypeScript/JavaScript library for the TypeSafe API"`, `"language": "TypeScript"`
- package.json (main): `"version": "0.6.0"`, `"license": "MIT"`, `"author": "evinism"`, `"type": "module"`, `"engines": { "node": ">=20" }`, `"push:jsr": "npm run check && jsr publish"`
- LICENSE (main, first two lines): "MIT License" / "Copyright (c) 2026 TypeSafe"

---

## Other surfaces

### Other languages (Go, Rust, Java, …): none — HTTP API is the fallback
- Verdict: **documented absence** (rests on the SDK index page + the API reference, not a silent marketing page).
- Sources: https://docs.typesafe.ai/sdk.md, https://docs.typesafe.ai/api.md, https://docs.typesafe.ai/introduction/quickstart.md
- Verified how: grepped all 111 pages from llms.txt for `golang|rust|java|ruby|php|c#|.net|swift|kotlin|elixir|\bGo\b`. The only hits are inside cookbook/primitive *example data* (e.g. a resume "eight years of Python and Go experience", a choice option "rust, other") — none are SDK mentions. `curl` appears on exactly 3 pages (quickstart "Sample cURL command", models.md, citation_check cookbook).
- Verbatim, sdk.md: "Our client SDKs provide typed questions and answers for the TypeSafe API and handle retries automatically with their default retry policy." / "You can also call the [HTTP API](/api) directly from any language."
- Verbatim, sdk.md cards: `<Card title="Python" href="/sdk/python">` and `<Card title="JavaScript / TypeScript" href="/sdk/javascript">` — exactly two.
- Verbatim, quickstart.md: "### Sample cURL command" followed by `curl -X POST https://api.typesafe.ai/v1/systemone \` / `-H "Authorization: Bearer $TYPESAFE_API_KEY" \`
- Verbatim, api.md: `POST https://api.typesafe.ai/v1/systemone` / `Authorization: Bearer <API_KEY>`
- Verbatim, concepts/system-one.md: "Call a System One model through one of our [client SDKs](/sdk) or `POST /v1/systemone` in the [HTTP API](/api)."
- Verbatim, introduction/coding-agents.md: "* [Quick start](/introduction/quickstart) — Try Jev in the Playground, over HTTP, or with the Python SDK." (the quickstart's code section is Python-only: "## Code it: the Python SDK").
- Marketing pages: `https://typesafe.ai` (590,563 bytes, Framer-rendered; only 7,322 chars of visible text) and the blog post (258,883 bytes) contain **zero** occurrences of `sdk`, `SDK`, `pip install`, `npm install`, `Python`, `TypeScript`, `JavaScript`, `curl`, `MCP` in the raw HTML (fixed-string grep). The blog's only code-adjacent link is to `https://github.com/typesafe-ai/system-one-adapter-python` ("System One LLM" wrapper). So neither marketing page makes any SDK/language claim — nothing to reconcile there.

### Agent skill (`typesafe-ai/skills`) — NOT part of the SDK surface; a docs-context skill
- Verdict: documented. It is a Markdown skill for coding agents, distributed as a Claude Code plugin marketplace and via skills.sh. It contains no code, no SDK, no MCP server.
- Source: https://docs.typesafe.ai/agent-skill.md ; repo https://github.com/typesafe-ai/skills
- Verified how: GitHub API 200, `"private": false`, **1981 stars**, 107 forks, `"license": "MIT"`, created 2026-08-24T23:58:39Z, pushed 2026-09-12T05:42:06Z; one tag `v0.5.7`, zero GitHub releases. Full recursive tree (`truncated: false`, 9 entries): `.claude-plugin/marketplace.json`, `.claude-plugin/plugin.json`, `LICENSE`, `README.md`, `skills/typesafe-ai/LICENSE`, `skills/typesafe-ai/SKILL.md` (10,040 bytes). `plugin.json`: `"name": "typesafe"`, `"version": "0.5.7"`, `"license": "MIT"`.
- Verbatim, agent-skill.md: "> Drop-in skill for Claude Code, Codex, and other agent environments." / "The TypeSafe agent skill gives your AI coding agent full context on the TypeSafe API: the three question [types](/primitives), the architectural [patterns](/patterns), and best practices for structuring evaluations."
- Install (verbatim): `claude plugin marketplace add typesafe-ai/skills` / `claude plugin install typesafe@typesafe-ai` ; other agents: `npx skills add typesafe-ai/skills --skill typesafe-ai`
- Verbatim, agent-skill.md: "With the Claude Code plugin, you can also invoke `/typesafe:typesafe-ai` directly."
- Verbatim, SKILL.md frontmatter: `name: typesafe-ai` / `license: MIT`; body: "**The live TypeSafe docs are the source of truth. Read them as part of the task.**" and its task table row: "| Write API code | [HTTP API](https://docs.typesafe.ai/api.md), [Python SDK](https://docs.typesafe.ai/sdk/python.md), or [JavaScript SDK](https://docs.typesafe.ai/sdk/javascript.md) |" — the skill itself names exactly the same two SDKs.
- **Discrepancy 1 (reference files):** agent-skill.md says "For manual installation, copy the entire [skills/typesafe-ai directory](https://github.com/typesafe-ai/skills/tree/main/skills/typesafe-ai), including its reference files, into your agent's skills directory." — but the directory contains only `LICENSE` and `SKILL.md`; there are no reference files at `main` today.
- **Discrepancy 2 (dead link in SKILL.md):** SKILL.md row "| Update an older integration | [Migration guide](https://docs.typesafe.ai/migrating-to-v1.md) and the installed SDK's current reference |" — `https://docs.typesafe.ai/migrating-to-v1.md` returns HTTP 404 ("# Page Not Found") and the page is absent from llms.txt. (This is the "stale skill" failure mode the docs page itself warns about: "### The agent invents request or response fields / A stale skill can cause this.")

### MCP server: none found
- Verdict: **documented absence**. Query that proves the corpus was searched: `grep -rliE '\bMCP\b|model context protocol' docs raw` over 111 docs pages + 10 raw repo files → 0 files. Positive control for the same grep method: `grep -rniE 'gateway' docs` → hits in sdk/python/usage.md and sdk/python/changelog.md. The typesafe-ai GitHub org (10 public repos, listed below) has no repo whose name or description mentions MCP.
- Org repo list (GitHub API `orgs/typesafe-ai/repos`, all `private=false`): typesafe-ai.github.io (2★), vllm (3★, fork), LLaDA (11★, fork), daggerverse (16★), pulumi-clickhouse (3★), system-one-adapter-python (277★), skills (1981★), Overwatch (5★, no description), typesafe-sdk-python (210★), typesafe-sdk-js (229★).

### `system-one-adapter` (Python) — companion package, not an SDK for Jev
- Verdict: documented (repo + PyPI), but it is a shim that runs the `typesafe_sdk` question API against OpenAI/Anthropic/Gemini instead of TypeSafe — useful for benchmarking Jev vs LLMs, not for calling Jev.
- Sources: https://github.com/typesafe-ai/system-one-adapter-python (277★, MIT, created 2026-08-08, pushed 2026-09-22); https://pypi.org/pypi/system-one-adapter/json → `"version": "0.2.1"`, `"license_expression": "MIT"`, `"requires_python": ">=3.10"`, releases `0.0.1a0, 0.1.3, 0.1.4, 0.1.5, 0.2.0, 0.2.1`. Linked from the TypeSafe blog post.
- Verbatim, README: "A drop-in replacement for `typesafe_sdk`'s `system_one` evaluation API, backed by LLM APIs instead of TypeSafe." / "Useful for comparing TypeSafe against an LLM on" ⏎ "cost/speed/intelligence." (hard-wrapped across two lines in the source README) / install: `pip install 'system-one-adapter[openai]'      # OpenAI-compatible providers`

### Gateways / third-party distribution (relevant to "other surfaces")
- Python usage.md documents OpenRouter (`https://openrouter.ai/~typesafe/jev-latest/`, model id `~typesafe/jev-latest`) and Vercel AI Gateway (`https://vercel.com/docs/ai-gateway/sdks-and-apis/typesafe`, model id `typesafe-ai/jev`) as base-URL overrides. Verified only that the docs say so; the gateway pages themselves were not fetched (out of scope for Q5).

---

## Things I could not find (with the queries that prove I looked)

1. **A JSR publication of the JS SDK.** `curl https://api.jsr.io/scopes/typesafe-ai/packages/sdk` → 404 `{"code":"packageNotFound"}`; `curl https://jsr.io/@typesafe-ai/sdk` → 404. Positive control: `curl https://api.jsr.io/scopes/std/packages/path` → 200 `{"scope":"std","name":"path",...}`. The `push:jsr` script exists in package.json but nothing is published.
2. **Any SDK in Go, Rust, Java, Ruby, PHP, C#/.NET, Swift, Kotlin.** `grep -rnoiE '\b(golang|rust|java|ruby|php|c#|\.net|swift|kotlin|elixir)\b' docs/` over 111 pages → only example-data hits (listed above). GitHub org listing (10 repos) has no such repo. Not searched on registries (no package name to look up — docs name none; per brief, package names must come from docs).
3. **An MCP server.** Corpus grep → 0 files (query shown above); org repo list has none.
4. **The `migrating-to-v1` docs page** the SKILL.md links to: HTTP 404, absent from llms.txt (`grep -c migrating llms.txt` → 0).
5. **"Reference files" in the skill directory** (agent-skill.md says to copy them): recursive tree of `typesafe-ai/skills@main` is 9 entries, `truncated: false`; only SKILL.md + LICENSE under `skills/typesafe-ai/`.
6. **Any SDK/language claim on typesafe.ai or the launch blog post**: fixed-string greps for `sdk`, `SDK`, `pip install`, `npm install`, `Python`, `TypeScript`, `JavaScript`, `curl`, `MCP` on both raw HTML bodies → 0 each (page sizes 590,563 and 258,883 bytes, so the bodies were fetched). The pages are Framer-rendered; the visible-text extraction is 7.3K / 13.6K chars.
7. **Python repo LICENSE copyright holder** — file exists but is the unfilled MIT template (`Copyright (c) [year] [fullname]`). Not a lookup failure; recorded as a defect.

## Scratch artefacts (not part of deliverable)
All fetched bodies are under `/private/tmp/claude-501/-Users-kashif-Developer-experiments-ai-workspace-template/a5bbbd4b-fa98-48e5-a26a-314e3ac98f7b/scratchpad/sdks/` (`docs/` = 111 llms.txt pages, `raw/` = repo files, `npm.json`, `pypi.json`, `gh_*.json`, `home.html`, `blog.html`) for the fact-checker to re-grep.
