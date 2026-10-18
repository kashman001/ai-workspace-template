# T6 — OpenViking (Volcengine context database)

Track T6 of `work/external-tools-review/`. Research only; no template files changed.

## Sources (fetched 2026-10-18)

- Repo: https://github.com/volcengine/OpenViking — shallow clone at `9cd7786`
  (committed 2026-10-19 01:30 +08:00). Read as data; no code was run.
- `gh api repos/volcengine/OpenViking` (stars, license, dates), `/releases`,
  `/contributors`, `/issues`, `/commits?path=LICENSE`, and the original
  `LICENSE` at commit `f98dc0e`.
- PyPI JSON: https://pypi.org/pypi/openviking/json (version, license, Python).
- In-repo docs (mirrored at https://docs.openviking.ai): `README.md`,
  `docs/en/concepts/03-context-layers.md`, `05-storage.md`, `13-privacy.md`,
  `docs/en/guides/01-configuration.md`, `07-operation-telemetry.md`,
  `docs/en/agent-integrations/02-claude-code.md`, `06-mcp-clients.md`,
  `15-agent-plugins.md`, `benchmark/locomo/README.md`.
- Not fetched: the benchmark blog post
  (https://blog.openviking.ai/post/openviking-benchmark-results/) and the
  arXiv papers. Claims from them below come via the README only.

## What it is

- A "context database for AI agents". Knowledge, memory and skills live in one
  virtual filesystem under `viking://` (`resources/`, `user/{id}/memories/`,
  `user/{id}/skills/`, …). Agents use `ls`, `tree`, `read`, `grep`, `find`,
  `search`. (README "What is OpenViking".)
- Tiered loading. Each processed **directory** gets two generated sidecars:
  `.abstract.md` (L0, default 256 chars) and `.overview.md` (L1, default
  4000 chars). L2 is the original files. L0 feeds vector retrieval; L1 feeds
  rerank and the "should I open this?" decision.
  (`concepts/03-context-layers.md`.) Note: sidecars are per directory, not
  per file.
- Retrieval is "directory-aware": scope a semantic search to a subtree before
  vector ranking. `find` runs a query; `search` plans retrieval from session
  context. (README "Why OpenViking".)
- Sessions: committing a session archives the conversation and extracts
  memories as Markdown. (README; `concepts/08-session.md` not read in full.)

## How it runs

- **Server, not a library.** `uv tool install openviking` then
  `openviking-server init`; the server runs in the foreground, default
  `http://127.0.0.1:1933`. Needs Python ≥3.10 (PyPI `requires_python`).
  A Rust `ov` CLI ships in the package. SDKs: Python, Go, TypeScript, HTTP API.
- **Needs two models.** "Deploying your own needs uv, Python 3.10+ and a model
  provider with an embedding model and a VLM." (README "Quick start".)
  - Embedding providers: openai, azure, volcengine, vikingdb, jina, ollama,
    gemini, voyage, dashscope, minimax, cohere, litellm, `local` (GGUF).
  - VLM providers: volcengine, openai(-compatible), openai-codex (ChatGPT
    OAuth), kimi, glm, litellm. Config docs show an Ollama model through the
    OpenAI-compatible path.
  - Without a working VLM, summaries come out empty and overviews show a
    "not-ready placeholder". So L0/L1 depend on the model.
  - **Local-only looks possible** (Ollama or `local` embeddings plus an
    Ollama VLM). *Unverified* — not run, and the published benchmark used
    Doubao cloud models, not local ones.
- **Storage.** `~/.openviking/ov.conf` holds config. Data goes to
  `storage.workspace` (default `./data`): content in "AGFS" (localfs, s3fs
  or memory backends) plus a separate vector index; a sqlite queue under
  `_system/queue/`. (`guides/01-configuration.md`, `concepts/05-storage.md`.)
  This is a database directory, not reviewable Markdown in git.
- **Hosted option.** Volcengine runs it as a service (Beijing endpoint; first
  50 files free). Commercial self-managed edition is licence-key gated.
- Also: a desktop "helper" app (beta), Web Studio, VikingBot, a gateway.

## MCP, CLI and agent integrations

- **MCP:** the server exposes Streamable HTTP at `/mcp`. Tools include
  `find`, `search`, `read`, `remember`, `write`, `add_skill`.
  (`agent-integrations/06-mcp-clients.md`, `15-agent-plugins.md`.)
- **CLI:** `ov status`, `ov add-resource`, `ov ls`, `ov tree`, `ov find`,
  `ov grep`. It talks to the server; it does not work without one.
- **Official integrations** (README table): Claude Code (hooks + MCP), Codex
  (hooks + MCP), Cursor, TRAE, OpenCode, pi, OpenClaw (context engine),
  Hermes (built-in), DeerFlow, DSH, LangChain, Microsoft Agent Framework.
  Installed by `curl -fsSL https://openviking.ai/install | bash`, which
  writes into the home directory and each agent's config.
- The Claude Code plugin **auto-captures every turn**, including tool calls
  and verbatim tool output, and auto-recalls on every prompt (defaults
  `OPENVIKING_AUTO_CAPTURE=true`, `OPENVIKING_AUTO_RECALL=true`).
  (`02-claude-code.md`.)
- "Agent Plugins 1.0" package (`agent-plugins/`): a vendor-neutral manifest +
  stdio MCP proxy + four skills. It has no hooks, so no auto-capture; the
  model must choose to recall and remember.
- **Not named anywhere in the integration docs: GitHub Copilot, Gemini CLI,
  Antigravity.** (grep over `docs/en/agent-integrations/` and
  `agent-plugins/README.md`: zero hits.) They could connect as generic MCP
  clients; *unverified*.

## Licence

- The root `LICENSE` is **GNU AGPL-3.0**. GitHub's API and PyPI metadata both
  say `AGPL-3.0`.
- It started as **Apache-2.0**: the first commit `f98dc0e` (2026-01-29) has
  an Apache LICENSE; commit `ce99887` (2026-03-30, PR #1085) is titled
  "change the main license from Apache-2.0 to AGPL-v3". That explains the
  conflicting aggregators. Releases before that date stay Apache-2.0.
- Mixed tree today (README "License"): `crates/ov_cli` and `examples/` are
  Apache-2.0; `integrations/frameworks/*` adapters are AGPL-3.0; a Hermes
  example and the bot's vendored nanobot are MIT.
- Extra README condition: "any wholesale rewriting and subsequent
  re-open-sourcing of this project is prohibited"; translating the code to
  another language "requires prior written authorization". That sits oddly
  with AGPL and is a legal question, not answered here.
- **Implications for the template.** Linking to it or documenting it as an
  optional install carries no AGPL duty for the template. Vendoring any of its
  code, skills or plugin files into the template would pull AGPL (or the
  Apache/MIT parts' notices) into every downstream copy. Anyone who exposes a
  modified server over a network owes source to its users. Companies often
  ban AGPL outright, so it can't be a default dependency.

## Maturity

- Created 2026-01-05; ~40,250 stars, 3,225 forks; pushed 2026-10-18.
- 100+ contributors (the API page cap of 100 was hit).
- Releases about weekly: v0.4.20 (09-14), v0.4.21 (09-20), v0.4.22 (09-28),
  v0.4.23 (10-02), v0.5.0 (10-09); 58 PyPI releases. Still pre-1.0.
- ~410 commits since 2026-09-18 (GitHub commit search; approximate).
- 342 open issues and 651 open PRs. Recent open bugs cluster on durability
  and queues: an unbounded delta table that OOMs at startup, records
  disappearing from vector search after a failed index save, retries silently
  acked, a server that answers `/health` but hangs on auth calls, a
  working-memory setting silently ignored in 0.5.0, and per-agent plugin bugs
  (Codex, OpenCode, ZCode).
- Read: very active and popular, but fast-moving and still finding
  data-loss-class bugs.

## Benchmark claims — self-reported

- README "Proof it works": OpenViking 0.3.22 on LoCoMo (long-conversation
  memory) and tau2-bench. LoCoMo accuracy native vs with OpenViking: OpenClaw
  24.20% → 82.08%, Hermes 33.38% → 82.86%, Claude Code 57.21% → 80.32%.
  Claims input tokens −34.3 to −91.0% and query latency −58 to −66%.
  tau2-bench: +6.87pp retail, +11.87pp airline.
- **Who measured:** the OpenViking team. **Setup:** Doubao 2.0 Pro as the VLM
  and Doubao embedding (both Volcengine's own models); scoring by an LLM judge
  (`benchmark/locomo/*/judge.py`). Judge model and prompts not checked.
- Scripts are public (`benchmark/`), so it is reproducible in principle.
  **No independent replication found or looked for.** Treat as self-reported.
- The test is chat-memory recall, not repo-coding work. It says little about
  whether an agent working on a codebase does better.

## Data and privacy

- **Content goes to whatever model you configure.** Every resource and
  captured turn is summarised by the VLM and embedded. With the default
  wizard choices that is a cloud API (Volcengine, OpenAI, Kimi, GLM). Only an
  Ollama/local setup keeps it on the machine. (`01-configuration.md`.)
- **Auto-capture sends everything**: prompts, answers, and verbatim tool
  output (file contents, command output, possibly secrets) to the server, and
  from there to the model. Regex capture filters exist but are empty by
  default. (`02-claude-code.md`.)
- "Telemetry" in the docs is an opt-in per-request `telemetry` object returned
  to the caller (`07-operation-telemetry.md`). A grep for common analytics
  SDKs (posthog, sentry, mixpanel, amplitude, scarf) in `openviking/`,
  `openviking_cli/`, `crates/`, `agent-plugins/`, `scripts/` found none.
  *Partly verified* — no phone-home seen, but the code was not audited, and
  the hosted service and desktop app were not examined.
- Skill "privacy extraction" uses a model to pull API keys out of a skill's
  body into a versioned store. The docs say it "does not guarantee discovery
  of every sensitive value". (`concepts/13-privacy.md`.)

## What the template already has for the same need

| OpenViking idea | Template equivalent |
|---|---|
| L0/L1/L2 tiered loading | `docs/zoom-model.md`: Z0–Z3 levels, "summaries up, pointers down", budgets per level (≤~10K always-loaded, ≤~15K per zoom-in) |
| L0 one-liner per item | `Purpose:` header comment in 13 of 17 `docs/*.md`; `description:` frontmatter in 55 of 57 `skills/*/SKILL.md`; one line per repo in `docs/repos-registry.md` |
| L1 overview of a directory | `docs/README.md` (doc index by need); `docs/repo-context/<repo>/code-structure.md`; `work/<item>/README.md` |
| Directory-scoped semantic search | `graphify query/path/explain` (`docs/recommended-tooling.md` §5, core MCP in `.mcp.json`); `repo-navigator` agent |
| Session memory extraction | `work/<item>/handoff.md` ledger + `next-session.md` launcher (`docs/work-directory-conventions.md`); `session-rollover`, `checkpoint` skills |
| Long-term memories | `work/<item>/decisions.md`, `docs/adr/`, `GLOSSARY.md`; per-user `MEMORY.md` for preferences only (`CONTEXT.md` → "Agent Context Discipline" rule 5) |
| Query a huge corpus | `skills/rlm/` |
| Token budget awareness | `docs/context-budget.md`, `scripts/context-budget.sh` |

The template's answer to "what does the agent load, and when" is plain files
in git plus a budget rule. OpenViking's answer is a model-generated index in a
database. The template already covers the same need without a server.

Side note: OpenViking's rerank config lists `"jev"` as a provider
(`01-configuration.md` line ~1186), the same Jev the template uses in
`scripts/jev.sh`. Not followed up.

## Fit against the template's principles

- **Agent-agnostic: partial.** Strong for Claude Code and Codex (hooks + MCP),
  OpenCode and Cursor. No named support for Copilot, Gemini CLI or
  Antigravity; those get only the generic MCP path with no auto-capture.
  Behaviour would differ by agent, which the template forbids for core
  features.
- **State in git and on disk: fails.** Memory lives in a server's data
  directory and vector index, outside the repo, not diffable or reviewable
  in a PR. `CONTEXT.md` says project state goes in `work/`, not
  agent-specific stores. A second, hidden memory would compete with
  handoff/launcher/decisions as the source of truth.
- **CLI-first: weak.** There is an `ov` CLI, but it needs a running server
  and two models first. Compare graphify: one `uv tool install`, local files.
- **Lean by default: fails as a default.** Always-on recall injects up to ~2K
  tokens on every prompt (`OPENVIKING_RECALL_TOKEN_BUDGET=2000`) — exactly the
  standing context tax the template tries to avoid. Plus a long-running
  server, model API keys, and a curl-pipe-bash installer that edits each
  agent's home config.
- **Licence: poor fit for a copied template** (AGPL, with extra non-standard
  conditions).

## Verdict: learn-from

Do not adopt, ship, vendor or wire it in. It solves a real problem
(cross-session memory and cheap relevance checks), but as an external,
model-dependent database with uneven agent coverage and an AGPL licence. The
template already solves the same problem with files in git. The one idea
worth taking is L0/L1 as an explicit, budgeted rule — and the template is
mostly there already.

## Candidate recommendations

**O1 — Name the L0/L1/L2 pattern in `docs/zoom-model.md`.** Add a short
paragraph under "Properties that make the stack work": each level offers a
one-line abstract (L0) and a short map (L1) before full content (L2); point
at the existing carriers (`Purpose:` headers, skill `description:`,
`docs/README.md`, registry lines). Cite OpenViking as prior art. Cost: ~10
lines. Value: low–medium (gives a shared vocabulary; no new mechanism).
Agent-agnostic: yes.

**O2 — Close the L0 gap in docs.** Give the 4 of 17 `docs/*.md` files
without a `Purpose:` header one, and state a length cap (one sentence, like
OpenViking's 256 chars) in the stub-header rule in
`docs/workspace-structure.md`. Cost: small. Value: low–medium (an agent can
scan all doc purposes with one grep before opening any). Agent-agnostic: yes.
Check first: a lint already enforcing headers would make this a lint tweak.

**O3 — Optional "external memory servers" note in
`docs/recommended-tooling.md`.** A few lines: OpenViking exists; it is
AGPL, server + two models, cloud by default, auto-capture sends tool output;
if a user wants it, use its own installer, and keep `work/` as the source of
truth. No fragment file shipped. Cost: ~10 lines. Value: low (saves the next
person this research). Agent-agnostic: yes (it's a doc).

**O4 — Optional MCP fragment `mcp-fragments/openviking.json`.** A
local-loopback HTTP entry pointing at `http://127.0.0.1:1933/mcp`. Cost:
small file plus a row in `mcp-fragments/README.md` and `docs/mcp-setup.md`;
the real cost is that each user must run the server and models. Value: low.
Agent-agnostic: no (fragments load cleanly only in some runtimes; no
Copilot/Gemini story upstream). **Lean: not recommended** unless the user
actively wants to trial it; O3 covers the need.

### Not recommended

- Installing it as a default, or adding it to `.mcp.json` core: breaks
  lean-by-default and needs a server and model keys.
- Using it as the template's memory or handoff store: moves state out of git,
  splits the source of truth, and differs per agent.
- Vendoring its skills, plugin or `agent-plugins/` package: AGPL and the
  extra "no rewrite" condition would flow into every copy.
- Recommending its auto-capture plugin: it sends verbatim tool output to a
  model by default.
- Generating `.abstract.md` / `.overview.md` sidecars per directory with a
  model: stale-prone and adds a model dependency. Z2 is already "generate on
  demand" via graphify.
- Citing its LoCoMo numbers as evidence: self-reported, vendor models,
  chat-memory benchmark rather than coding work.

## Open questions for the user

- Is there a real cross-machine or cross-agent memory need that `work/` plus
  git does not meet? If yes, a separate trial work item could test
  OpenViking fully local (Ollama) on one repo. If no, O1–O3 are enough.
