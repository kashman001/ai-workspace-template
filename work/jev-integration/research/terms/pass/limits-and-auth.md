# terms / limits-and-auth — raw pass findings

- **Cluster:** `terms` → `limits-and-auth` (Q2 rate limits/quotas/concurrency; Q3 authentication)
- **Subject:** Jev, TypeSafe's "System One Model" (typesafe.ai)
- **Date checked:** 2026-09-23
- **Method:** public sources only; `curl` + grep on saved raw HTML/markdown/JSON; every docs page has a `.md` twin (`https://docs.typesafe.ai/<path>.md`) and the reference of record is the live OpenAPI schema at `https://api.typesafe.ai/openapi.json`. Tables were confirmed against the served HTML (rule 3). Two of three permitted web searches used.
- **Local evidence copies:** `/private/tmp/claude-501/-Users-kashif-Developer-experiments-ai-workspace-template/a5bbbd4b-fa98-48e5-a26a-314e3ac98f7b/scratchpad/ts/` (subdirs `md/`, `html/`, `legal/`, `src/`, `gh/`, `third/`)

## URLs fetched (HTTP status)

| URL | Status | Note |
|---|---|---|
| https://docs.typesafe.ai/ | 200 → `/introduction` | docs root |
| https://docs.typesafe.ai/sitemap.xml | 200 | 118 URLs |
| https://docs.typesafe.ai/robots.txt | 200 | `Content-Signal: ai-train=yes, search=yes, ai-input=yes` |
| https://docs.typesafe.ai/llms.txt | 200 | page index |
| https://docs.typesafe.ai/llms-full.txt | 200 | 910,292 bytes, full docs dump used for corpus-wide greps |
| https://docs.typesafe.ai/openapi.json, /openapi.yaml, /api-reference, /reference, /pricing | 404 | not the spec location |
| **https://api.typesafe.ai/openapi.json** | **200** | OpenAPI 3.1.0, `info.version` 0.2.0, 14,158 bytes — the reference |
| https://api.typesafe.ai/docs · /redoc | 200 · 200 | Swagger UI / ReDoc for the same spec |
| https://api.typesafe.ai/ | 404 | no root page |
| https://docs.typesafe.ai/api.md | 200 | HTTP API reference (error table, rate-limit section) |
| https://docs.typesafe.ai/models.md | 200 | rate-limit numbers, aliases |
| https://docs.typesafe.ai/introduction/quickstart.md · /introduction.md · /introduction/coding-agents.md | 200 | key acquisition |
| https://docs.typesafe.ai/legal.md · /sdk.md · /sdk/python.md · /sdk/javascript.md · /agent-skill.md | 200 | |
| https://docs.typesafe.ai/sdk/python/api/{retries,exceptions,constants,clients/sync,clients/async}.md · /sdk/python/usage.md · /sdk/python/changelog.md | 200 | Python SDK reference |
| https://docs.typesafe.ai/sdk/javascript/api/interfaces/{RetryPolicy,TypeSafeClientConfig,RequestOptions,Usage,ModelCard}.md · /classes/{RateLimitError,AuthenticationError,PermissionDeniedError,APIError,TypeSafeClient}.md · /variables/ENV.md · /sdk/javascript/api.md · /changelog.md | 200 | JS SDK reference |
| https://docs.typesafe.ai/models · /api · /sdk/python/usage (served HTML) | 200 | rule-3 table confirmation |
| https://typesafe.ai/ | 200 | marketing; 0 hits for "API key", "rate limit", "SSO", "organization", "enterprise" |
| https://typesafe.ai/blog/introducing-system-one-models-and-jev | 200 | marketing; same 0 hits |
| https://typesafe.ai/pricing | 404 | |
| https://typesafe.ai/legal/mca | 200 | Master Customer Agreement, "Last updated Sep 19, 2026" |
| https://typesafe.ai/legal/data-processing | 200 | DPA, "Last updated Apr 24, 2026"; no auth/limit terms |
| https://typesafe.ai/legal/privacy-policy | 200 | "Last updated Nov 19, 2025"; no auth/limit terms |
| https://console.typesafe.ai/ | 200 → `/login` | logged-out only |
| https://console.typesafe.ai/keys · /settings/keys · /playground · /signup · /register · /billing · /usage | 200 → `/login?returnTo=…` | all gated; not opened further |
| https://registry.npmjs.org/@typesafe-ai%2Fsdk | 200 | latest 0.6.0 (2026-09-15), MIT |
| https://pypi.org/pypi/typesafe-sdk/json | 200 | latest 0.7.1 (2026-09-21) |
| https://raw.githubusercontent.com/typesafe-ai/typesafe-sdk-js/v0.6.0/src/client.ts | 200 | header construction |
| https://raw.githubusercontent.com/typesafe-ai/typesafe-sdk-python/main/src/typesafe_sdk/constants.py and `_core/{config,transport,retry,errors,endpoints,constants}.py` | 200 | header construction, key validation |
| https://raw.githubusercontent.com/typesafe-ai/skills/main/skills/typesafe-ai/SKILL.md | 200 | |
| https://api.github.com/repos/typesafe-ai/skills/issues/10 (+ /comments) | 200 | third-party bug report on console login (see Q3 row 16) |
| https://vercel.com/docs/ai-gateway/sdks-and-apis/typesafe | 200 | gateway auth path cited by TypeSafe docs |
| https://openrouter.ai/~typesafe/jev-latest | 200 | 0 hits for rate/limit/key in served text (JS-rendered) |
| https://ai-sdk.dev/providers/ai-sdk-providers/typesafe-ai | 200 | third-party provider; env var `TYPESAFE_AI_API_KEY` |

Web searches (2/3): `typesafe.ai console API key organization SSO "typesafe" jev`; `"typesafe.ai" jev "rate limit" OR "rate limits" tier`. Neither surfaced a first-party page not already crawled; third-party claims from them are marked as such below.

## Q2 — Rate limits, quotas, concurrency

| # | Claim (one sentence) | Verdict | Source URL | Date checked | How verified | Documented vs. implied |
|---|---|---|---|---|---|---|
| Q2-1 | The published rate limit for `jev-1.13.0` is **250,000 tokens per second** and **1,200 requests per minute**. | documented | https://docs.typesafe.ai/models | 2026-09-23 | `grep -c` on `models.md` = 1; served-HTML `<tr>` parsed: `Rate limits \| 250,000 tokens per second / 1,200 requests per minute` (2-column row, no transposition) | Documented. Scope: the row is under the single model card "Jev 1.13 / jev-1.13.0"; the page does not say whether the figure is per key, per account, or global. |
| Q2-2 | Limits are metered in tokens/second and requests/minute, and exceeding **either** returns `429 Too Many Requests`. | documented | https://docs.typesafe.ai/models | 2026-09-23 | quote E3 verified | Documented |
| Q2-3 | There is no tokens-per-minute meter; the token meter is per second. | documented (absence) | https://docs.typesafe.ai/llms-full.txt | 2026-09-23 | `grep -c 'tokens per minute'` = 0 vs control `grep -c 'tokens per second'` = 2 on the same file | Documented absence |
| Q2-4 | Whether limits are per API key, per account/org, or per model is **not stated**. | unknown | https://docs.typesafe.ai/llms-full.txt ; https://api.typesafe.ai/openapi.json | 2026-09-23 | `per-key`=0, `per key`=0, `per organization`=0, `per account`=0 in llms-full (control: `TYPESAFE_API_KEY`=49); OpenAPI: `rate`=2 (both in "rating"), `limit`=0 (control: `HTTPBearer`=3) | Unknown. The only hint is a cookbook remark "Eight is already enough to hit a rate limit on a shared key" (E14) — implies limits attach to a key, but it is a worked example, not a spec. |
| Q2-5 | No concurrency cap (max in-flight requests) is documented. | unknown | https://docs.typesafe.ai/llms-full.txt | 2026-09-23 | `concurrency limit`=0, `concurrent request`=0 (control: `concurren`=12, all cookbook `ThreadPoolExecutor` code) | Unknown. Anecdotal cookbook comment (E15): `MAX_WORKERS = 6  # small pool; the public endpoint rate-limits above roughly eight` — written against `jev-1.12`, so it may predate the published limits. |
| Q2-6 | Limits are declared **dynamic and changeable without notice**; higher limits are offered only on "custom and enterprise plans" via sales@typesafe.ai. | documented | https://docs.typesafe.ai/models | 2026-09-23 | quotes E4, E5 verified (also in served HTML: 2 hits each) | Documented. No tier table, no self-serve upgrade, no numbers for enterprise limits. |
| Q2-7 | No published tier ladder (free/pro/etc.) with per-tier limits exists. | unknown | https://docs.typesafe.ai/llms-full.txt ; https://typesafe.ai/pricing (404) | 2026-09-23 | `tier`=5 hits, all "frontier"; `/pricing` 404; marketing pages 0 hits for "pricing"/"free" in a plan sense | Unknown / undisclosed. Third-party review pages (search) assert "no free tier" — not first-party, not adopted. |
| Q2-8 | On 429 the documented guidance is "Back off and retry after a short delay"; `529 Overloaded` gets the same guidance; the API page prescribes **exponential backoff**. | documented | https://docs.typesafe.ai/api | 2026-09-23 | quotes E6–E8 verified; served-HTML error table parsed: rows `401 / 422 / 429 / 529` | Documented |
| Q2-9 | 429 and 401 are **not declared in the OpenAPI schema** (each operation lists only `200` and `422`). | documented (absence) | https://api.typesafe.ai/openapi.json | 2026-09-23 | `429`=0, `401`=0, `403`=0 (controls: `422`=3, `systemone`=5) | Documented absence in the reference; the prose docs are the only place 401/429/529 are described. |
| Q2-10 | The SDKs honor `retry-after` (seconds) and `retry-after-ms` response headers; the docs say the server sends `retry-after` "when the response carries one", i.e. it is not guaranteed. | documented (SDK) / implied (server) | https://docs.typesafe.ai/models ; https://docs.typesafe.ai/sdk/javascript/api/interfaces/RetryPolicy ; Python `_core/constants.py` | 2026-09-23 | quotes E3 tail, E11, E12; `RETRY_AFTER_HEADER = "retry-after"`, `RETRY_AFTER_MS_HEADER = "retry-after-ms"` in Python source | Header *names* documented on the client side; server emission implied only. |
| Q2-11 | No `x-ratelimit-*` / `ratelimit-*` remaining/reset headers are documented anywhere. | documented (absence) | https://docs.typesafe.ai/llms-full.txt ; https://api.typesafe.ai/openapi.json | 2026-09-23 | `x-ratelimit`=0, `X-RateLimit`=0, `ratelimit-`=0 in llms-full (control: `429 Too Many Requests`=3); OpenAPI declares no response headers at all | Documented absence |
| Q2-12 | The only documented response header is `x-typesafe-request-id` (surfaced as `request_id`/`requestId` on SDK errors). | documented | https://docs.typesafe.ai/sdk/python/api/exceptions ; JS `RateLimitError` page | 2026-09-23 | quote E17 verified; Python `REQUEST_ID_HEADER = "x-typesafe-request-id"` | Documented |
| Q2-13 | Default SDK retry policy (Python 0.7.1): 2 retries, backoff 0.5 s doubling to 5.0 s max, jitter 0.25, retry on 408, 429 and 500–599, honor Retry-After, 30 s total budget per call, 10 s per-operation timeout. | documented | https://docs.typesafe.ai/sdk/python/api/retries ; https://docs.typesafe.ai/sdk/python/api/constants | 2026-09-23 | signature in retries.md; quotes E12, E13; `DEFAULT_TIMEOUT = 10.0` in `constants.py` | Documented |
| Q2-14 | Default SDK retry policy (JS 0.6.0): `maxRetries` 2, `backoffInitialMs` 500 → `backoffMaxMs` 5000, jitter 0.25, statuses 408/429/500–599, `respectRetryAfter` true capped by `maxRetryAfterMs` 60000, per-attempt timeout 10000 ms with no total budget; SDK adds `X-TypeSafe-Retry-Count` on retries. | documented | https://docs.typesafe.ai/sdk/javascript/api/interfaces/RetryPolicy ; https://docs.typesafe.ai/sdk/javascript/api/interfaces/TypeSafeClientConfig ; `client.ts` | 2026-09-23 | quotes E9–E11, E18 verified; `"X-TypeSafe-Retry-Count"` = 2 hits in client.ts | Documented |
| Q2-15 | Contractually, usage is bounded by "Usage Limits" set in the customer's Order; exceeding them is a license restriction and a suspension trigger. | documented | https://typesafe.ai/legal/mca | 2026-09-23 | quotes E20–E22 verified on tag-stripped MCA text | Documented (contract); no numbers — the Order is not public. |
| Q2-16 | Request size limits: 64k tokens per request total; 32k tokens for `state` plus the longest question; max 255 options per Choice; up to 10 Score levels. | documented | https://docs.typesafe.ai/models ; https://docs.typesafe.ai/api | 2026-09-23 | models.md quote E2b; api.md "maximum of 255 options per Choice", "the API accepts up to 10" | Documented (adjacent to Q2; not a rate limit) |
| Q2-17 | Monthly/credit quotas: the MCA says usage is paid via "TypeSafe-managed credits that are consumed by each Input"; no quota numbers are published. | unknown (numbers) | https://typesafe.ai/legal/mca | 2026-09-23 | MCA §8.2 text; `quota`=1 in llms-full and it is "quotable" (false positive) | Mechanism documented; amounts unknown. |

## Q3 — Authentication

| # | Claim (one sentence) | Verdict | Source URL | Date checked | How verified | Documented vs. implied |
|---|---|---|---|---|---|---|
| Q3-1 | Authentication is an API key sent as `Authorization: Bearer <API_KEY>`; the OpenAPI security scheme is `HTTPBearer` (`type: http, scheme: bearer`) on both operations. | documented | https://api.typesafe.ai/openapi.json ; https://docs.typesafe.ai/api | 2026-09-23 | quotes E1, E1b, E6b verified; `HTTPBearer`=3 in spec; both SDKs build `Authorization: Bearer …` (E18, E19) | Documented |
| Q3-2 | There is no `x-api-key` header scheme and no OAuth flow. | documented (absence) | https://api.typesafe.ai/openapi.json ; https://docs.typesafe.ai/llms-full.txt | 2026-09-23 | spec: `apiKey`=0, `x-api-key`=0, `oauth`=0 (control `HTTPBearer`=3); llms-full: `x-api-key`=0, `OAuth`=0 (control `Authorization`=5). Note: the Python SDK's log-redaction list names `"x-api-key"` and `"api-key"` generically — that is a redaction denylist, not an accepted header. | Documented absence |
| Q3-3 | Keys are created in the console dashboard (`https://console.typesafe.ai/keys`); the console is the only documented issuance path. | documented | https://docs.typesafe.ai/introduction/quickstart | 2026-09-23 | quote E23 verified; `console.typesafe.ai/keys`=3 in llms-full; `/settings/keys` (from a third-party search snippet) also redirects to login, `=0` in docs | Documented. Key issuance UI itself is behind login — not inspected. |
| Q3-4 | Console sign-in offers "Continue with Google" or email ("Continue" / "Email me a code instead"); the logged-out page has no password field. | documented | https://console.typesafe.ai/login | 2026-09-23 | quotes E24, E25 verified in raw HTML; `password`=0, `GitHub`=0, `SSO`/`saml`/`oidc`=0 in the full page source incl. inlined JS | Documented (logged-out UI only) |
| Q3-5 | The MCA describes Web Interface access as "a username and password", which does not match the passwordless login UI. | contradicted (minor, wording) | https://typesafe.ai/legal/mca vs https://console.typesafe.ai/login | 2026-09-23 | quote E20 vs Q3-4 | The MCA phrase is generic contract language; flag, do not over-read. |
| Q3-6 | API key format/prefix is not documented; the Python SDK's only client-side rule is "printable ASCII characters without whitespace". | unknown (format) / documented (validation) | `typesafe-sdk-python` `_core/config.py` ; https://docs.typesafe.ai/sdk/python/usage | 2026-09-23 | quote E19b, E26 verified; llms-full `sk-`=6 (all "flask-conical"/prose), `ts_`=24 (all code identifiers) — no prefix example anywhere | Format unknown; no prefix check exists in either SDK. |
| Q3-7 | Environment variable is `TYPESAFE_API_KEY` in both official SDKs (JS `ENV.apiKey`, Python `API_KEY_ENV`); an explicitly empty key does not fall back to the env. | documented | https://docs.typesafe.ai/sdk/javascript/api/variables/ENV ; https://docs.typesafe.ai/sdk/python/api/constants ; usage.md | 2026-09-23 | ENV.md line 20 `readonly apiKey: "TYPESAFE_API_KEY"`; constants.py; quote E26 | Documented. (Third-party Vercel AI SDK provider uses `TYPESAFE_AI_API_KEY` instead — different name, third-party.) |
| Q3-8 | Organization / project / workspace scoping of keys is not documented; the spec speaks only of "the authenticated account". | unknown | https://api.typesafe.ai/openapi.json ; https://docs.typesafe.ai/llms-full.txt | 2026-09-23 | spec `organization`=0, `project`=0, `scope`=0 (control `authenticated account` appears in E1c); llms-full `organization`=3 (all cookbook prose), `workspace`=0 | Unknown — console-gated |
| Q3-9 | Key scopes/permissions (read-only, model-restricted, etc.) are not documented. | unknown | same as Q3-8 | 2026-09-23 | `scope`=1 in llms-full ("well-scoped thing", prose) | Unknown |
| Q3-10 | Key rotation, expiry and revocation are not documented; the MCA only obliges the customer to "promptly notify TypeSafe" on compromise. | unknown (mechanism) / documented (obligation) | https://typesafe.ai/legal/mca ; llms-full | 2026-09-23 | quote E22 verified; llms-full `rotate`=2 and `key rotation`=1, all in the `classifying_rag_passages` cookbook about JWT rotation (source line checked) | Mechanism unknown — console-gated |
| Q3-11 | Service accounts / machine identities are not documented. | unknown | llms-full | 2026-09-23 | `service account`=0 (control `API key`=25) | Unknown |
| Q3-12 | SSO (SAML/OIDC) for the console is not documented; only Google and email-code login appear. | unknown | llms-full ; console login page | 2026-09-23 | `SSO`=1 in llms-full but it is a character run inside a playground share-URL (line 9579), `single sign`=0; console source `saml`/`oidc`=0 | Unknown / not offered on the visible login page |
| Q3-13 | Error semantics: `401 Unauthorized` = "Missing or invalid API key. Check the `Authorization` header."; the SDKs also model `403` (`PermissionDeniedError` / `TypeSafePermissionDeniedError`) but the docs never say when the server returns 403. | documented (401) / implied (403) | https://docs.typesafe.ai/api ; https://docs.typesafe.ai/sdk/python/api/exceptions | 2026-09-23 | quote E6b; E16 "Access was denied (403)." | 401 documented; 403 exists in SDK surface only |
| Q3-14 | The JS SDK refuses to run in a browser unless `dangerouslyAllowBrowser: true`; the agent skill says "Keep API credentials server-side in web apps." | documented | https://docs.typesafe.ai/sdk/javascript/api/interfaces/TypeSafeClientConfig ; SKILL.md | 2026-09-23 | quotes E9b, E27 verified | Documented |
| Q3-15 | Alternate access with a different credential: the docs show using an OpenRouter key or a Vercel AI Gateway key by changing `base_url`/`baseURL`; Vercel's page says the gateway accepts its own API key or a Vercel OIDC token as `Authorization: Bearer`. | documented | https://docs.typesafe.ai/sdk/python/usage ; https://vercel.com/docs/ai-gateway/sdks-and-apis/typesafe | 2026-09-23 | usage.md lines 154–192 (OpenRouter, `https://ai-gateway.vercel.sh/typesafe`); quote E28 verified in raw Vercel HTML | Documented (gateway auth is the gateway's, not TypeSafe's) |
| Q3-16 | A third-party GitHub issue on TypeSafe's own `skills` repo (opened 2026-09-21, still open) reports every console login action (email, email-code, Google) returning HTTP 500 for two days, so no key could be obtained. | implied (unverified report) | https://github.com/typesafe-ai/skills/issues/10 | 2026-09-23 | issue JSON fetched (200); reporter `author_association: NONE`; no maintainer reply at fetch time; login POST not attempted by this pass (scope rule) | Not first-party confirmed. Relevant to feasibility of obtaining a key, not to the auth scheme. |
| Q3-17 | Access appears gated/waitlisted: the models page says limits change "as … we let in more users"; third-party pages (search) say "no self-serve signup yet". | implied | https://docs.typesafe.ai/models | 2026-09-23 | quote E4 verified; the "waitlist" wording is third-party only (`waitlist`=0 in llms-full and on the three gateway pages) | Implied by first-party wording; the word "waitlist" is not first-party. |
| Q3-18 | SDK logging redacts `authorization` and other secret headers but does **not** redact request/response bodies. | documented | https://docs.typesafe.ai/sdk/python/usage | 2026-09-23 | quote E26b verified | Documented |
| Q3-19 | Contract terms on keys: "Access Credentials" must be kept confidential and not shared; the customer is responsible for all actions under them; console access is limited to employees/contractors ("Customer Users"). | documented | https://typesafe.ai/legal/mca §2.4 | 2026-09-23 | quotes E20–E22 verified | Documented |

## Verbatim evidence quotes

Each quote was checked with `grep -c -F -- '<quote>' <saved file>` (or Python `str.count` for the JSON/tag-stripped text). All counts ≥ 1 unless noted.

- **E1** — https://api.typesafe.ai/openapi.json (`info.description`): `Send your API key in the Authorization header as \`Bearer <API_KEY>\`.` — count 1
- **E1b** — same file (`components.securitySchemes.HTTPBearer`): `"scheme":"bearer"` — count 1; `HTTPBearer` — count 3
- **E1c** — same file (`GET /v1/models` description): `List the models and aliases available to the authenticated account.` — count 1
- **E2** — https://docs.typesafe.ai/models.md: `250,000 tokens per second / 1,200 requests per minute` — count 1 (served HTML: 2)
- **E2b** — same: `64k tokens per request; 32k tokens for \`state\` plus the longest question` — count 1
- **E3** — same: `Measured in tokens per second and requests per minute. A request over either limit returns \`429 Too Many Requests\`.` — count 1; continues `retry with backoff by default and honor the \`retry-after\` header when the response carries one` — count 1
- **E4** — same: `Rate limits are adjusting dynamically.` — count 1; `the limits above can change without notice while we do, as upcoming large GPU deals land and we let in more users` — count 1
- **E5** — same: `Higher limits are available on custom and enterprise plans.` — count 1
- **E6** — https://docs.typesafe.ai/api.md: `You have exceeded your rate limit. Back off and retry after a short delay.` — count 1
- **E6b** — same: `Missing or invalid API key. Check the \`Authorization\` header.` — count 1; `Authorization: Bearer <API_KEY>` — count 1
- **E7** — same: `TypeSafe is temporarily overloaded. Retry after a short delay.` — count 1
- **E8** — same: `retry the request with exponential backoff instead of retrying immediately` — count 1; `Our client SDKs handle this automatically, so no extra handling is needed if you use one of our SDKs with its default retry policy.` — count 1
- **E9** — https://docs.typesafe.ai/sdk/javascript/api/interfaces/RetryPolicy.md: `HTTP status codes to retry. Default: 408, 429, and 500–599.` — 1; `Maximum retries after the initial attempt; \`0\` disables retries. Default: 2.` — 1; `First backoff delay in milliseconds, doubled up to \`backoffMaxMs\`. Default: 500.` — 1; `Maximum backoff delay in milliseconds. Default: 5000.` — 1
- **E9b** — https://docs.typesafe.ai/sdk/javascript/api/interfaces/TypeSafeClientConfig.md: `Required API key; falls back to \`TYPESAFE_API_KEY\`.` — 1; `Allow browser use, exposing the API key to page users. Default: false.` — 1; `Timeout per attempt in milliseconds, without a total retry budget. Default: 10000.` — 1
- **E10** — RetryPolicy.md: `Maximum server retry delay in milliseconds; longer delays use backoff. Default: 60000.` — count 1
- **E11** — RetryPolicy.md: `Honor \`Retry-After\` and \`retry-after-ms\` up to \`maxRetryAfterMs\`. Default: true.` — count 1; https://docs.typesafe.ai/sdk/javascript/api/classes/RateLimitError.md: `Server retry delay in milliseconds, or \`undefined\` when absent or invalid.` — count 1
- **E12** — https://docs.typesafe.ai/sdk/python/api/retries.md: `Whether to honor \`Retry-After\` and \`retry-after-ms\` response headers.` — count 1; `First backoff delay in seconds, doubled each attempt up to \`backoff_max\`; zero disables backoff.` — count 1
- **E13** — same: `Total retry budget in seconds per SDK call, including the initial attempt and delays; \`None\` disables the limit.` — count 1. Signature defaults on the page: `max_retries: int = 2`, `backoff_initial: float = 0.5`, `backoff_max: float = 5.0`, `backoff_jitter: float = 0.25`, `http_statuses … {408, 429, *range(500, 600)}`, `respect_retry_after: bool = True`, `timeout: float | None = 30.0`
- **E14** — https://docs.typesafe.ai/cookbooks/autoresearch_feature_discovery (via llms-full.txt line 3202–3203): `Raise the worker pool slowly. Eight is already enough to hit` / `a rate limit on a shared key.` — `grep -c 'a rate limit on a shared key.'` = 1
- **E15** — https://docs.typesafe.ai/cookbooks/entity_alignment (llms-full.txt line 7243): `MAX_WORKERS = 6  # small pool; the public endpoint rate-limits above roughly eight` — count 1 (preceded by `TYPESAFE_MODEL = "jev-1.12"`)
- **E16** — https://docs.typesafe.ai/sdk/python/api/exceptions.md: `The rate limit was exceeded (429).` — 1; `Authentication failed (401).` — 1; `Access was denied (403).` — 1
- **E17** — same: `The \`x-typesafe-request-id\` response header, or \`None\` if absent.` — count 1
- **E18** — https://raw.githubusercontent.com/typesafe-ai/typesafe-sdk-js/v0.6.0/src/client.ts: `Authorization: \`Bearer ${this.#apiKey}\`` — count 1; `"X-TypeSafe-Retry-Count"` — count 2; also `DEFAULT_BASE_URL = "https://api.typesafe.ai"`
- **E19** — https://raw.githubusercontent.com/typesafe-ai/typesafe-sdk-python/main/src/typesafe_sdk/_core/transport.py: `AUTHORIZATION_HEADER: f"Bearer {config.api_key}"` — count 1
- **E19b** — `_core/config.py`: `API key must contain only printable ASCII characters without whitespace.` — count 1 (guard: `if not key.isascii() or not key.isprintable() or " " in key:`)
- **E19c** — `_core/constants.py`: `RETRY_AFTER_HEADER = "retry-after"`, `RETRY_AFTER_MS_HEADER = "retry-after-ms"`, `REQUEST_ID_HEADER = "x-typesafe-request-id"`, `SECRET_HEADERS = frozenset({"authorization", "proxy-authorization", "x-api-key", "api-key", "cookie", "set-cookie"})`; `src/typesafe_sdk/constants.py`: `DEFAULT_TIMEOUT = 10.0` — count 1
- **E20** — https://typesafe.ai/legal/mca (tag-stripped text, §2.4): `including an API key (in the case of the API) and a username and password (in the case of the Web Interface)` — count 1; header `Last updated Sep 19, 2026` — count 1
- **E21** — same (§2.1): `compliance with the usage limits set forth in the Order (“ Usage Limits ”)` — count 1; (§2.3) `(j) exceed any Usage Limits` — count 1; (§6) `TypeSafe may immediately suspend Customer’s access to any or all of the Services if` — count 1
- **E22** — same (§2.4): `keeps the Access Credentials confidential and does not share them with anyone else` — count 1; `Customer will promptly notify TypeSafe if it becomes aware of any compromise of any Access Credentials` — count 1
- **E23** — https://docs.typesafe.ai/introduction/quickstart.md: `**Get your API key** from the [dashboard](https://console.typesafe.ai/keys)` — count 1; `The client reads \`TYPESAFE_API_KEY\` from the environment and calls \`jev-latest\` by default.` — count 1
- **E24** — https://console.typesafe.ai/login (raw HTML): `Continue with Google` — count 1
- **E25** — same: `Email me a code instead` — count 1
- **E26** — https://docs.typesafe.ai/sdk/python/usage.md: `API keys supplied through \`api_key\` or \`TYPESAFE_API_KEY\` have leading and trailing whitespace stripped, including newlines from key files. Empty keys, internal whitespace, control characters, and non-ASCII characters are rejected before sending a request.` — count 1; `Invalid API keys raise \`TypeSafeError\` during client creation, before any request or retry.` — count 1
- **E26b** — same: `Secret headers — authorization, API keys, cookies, and any header whose name contains \`token\` or \`secret\` — are redacted from log output.` — count 1 (next sentence on page: `Request and response bodies are **not** redacted.`)
- **E27** — https://raw.githubusercontent.com/typesafe-ai/skills/main/skills/typesafe-ai/SKILL.md: `Keep API credentials server-side in web apps.` — count 1
- **E28** — https://vercel.com/docs/ai-gateway/sdks-and-apis/typesafe (raw HTML): `Use your AI Gateway API key with the \`Authorization: Bearer ` — count 1 (text continues in a `<code>` element)
- **E29** — https://docs.typesafe.ai/legal.md: `We also offer zero data retention (ZDR) for enterprise customers.` — count 1
- **E30** — https://api.github.com/repos/typesafe-ai/skills/issues/10 `title`: `console.typesafe.ai: all auth server actions return HTTP 500 - sign-in/sign-up impossible for 2 days (survives redeploy)` — exact JSON field

### Absence-control greps (rule 1 / rule 2)

- `api.typesafe.ai/openapi.json`: `429`=0, `401`=0, `403`=0, `apiKey`=0, `oauth`=0, `x-api-key`=0, `limit`=0, `organization`=0, `project`=0, `scope`=0 — controls on the same file: `HTTPBearer`=3, `422`=3, `systemone`=5.
- `docs.typesafe.ai/llms-full.txt`: `x-ratelimit`=0, `X-RateLimit`=0, `ratelimit-`=0, `OAuth`=0, `service account`=0, `single sign`=0, `per-key`=0, `per key`=0, `per organization`=0, `per account`=0, `concurrency limit`=0, `concurrent request`=0, `tokens per minute`=0, `workspace`=0, `x-api-key`=0 — controls: `TYPESAFE_API_KEY`=49, `429 Too Many Requests`=3, `tokens per second`=2, `requests per minute`=2, `API key`=25, `console.typesafe.ai/keys`=3. Non-zero near-misses inspected: `SSO`=1 (share-URL noise), `per-account`=1 ("per-account weights", models page), `key rotation`=1 / `rotate`=2 (JWT cookbook), `quota`=1 ("quotable"), `tier`=5 ("frontier"), `sk-`=6 (not a key prefix), `ts_`=24 (identifiers).
- `console.typesafe.ai/login` full source incl. inlined JS: `password`=0, `organization`=0, `workspace`=0, `team`=0, `SSO`=0, `saml`=0, `oidc`=0, `GitHub`=0, `api key`=0 — controls: `Continue with Google`=1, `Email me a code instead`=1.
- Marketing (`typesafe.ai/`, blog post): `API key`=0, `rate limit`=0, `SSO`=0, `organization`=0, `enterprise`=0 — control: `$42`/`$0.042` price strings present on both.

## What I could not settle

1. **Scope of the 250k tok/s + 1,200 rpm limits** (per key / per account / per org / global) — needs an **account** (console usage/limits page) or **email** to sales@/support.
2. **Whether the server actually emits `retry-after` / `retry-after-ms` on 429/529**, and whether any `x-ratelimit-*` headers exist undocumented — needs a **key** (observe a 429 response). Not attempted (no API calls).
3. **Concurrency cap** — same as 1; the "roughly eight workers" cookbook note is anecdotal and tied to `jev-1.12`.
4. **API key format/prefix, key naming, multiple keys per account, rotation/revocation, expiry** — needs an **account** (console `/keys` UI).
5. **Org/project/workspace model, key scopes, service accounts, SSO/SAML** — needs an **account**, or **email** (enterprise plan inquiry to sales@typesafe.ai).
6. **Tier ladder and enterprise limit numbers, credit quotas, what an "Order" specifies** — needs **email** to sales@ (docs say only "custom and enterprise plans").
7. **Whether console login is currently functional / whether signup is waitlisted** — needs an **account attempt** (a login POST is out of scope for this pass); the only evidence is an open third-party GitHub issue (E30) and first-party wording "we let in more users" (E4).
8. **403 conditions** — the SDKs model `PermissionDeniedError (403)` but no doc says when it fires; needs a **key** or **email**.
