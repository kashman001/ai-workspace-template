# Skill pack inventory: addyosmani/agent-skills

Inventory of one outside skill pack, made so it can be compared with the skills
this template already ships (`skills/vendored-skills.md` and the "Workspace
Skills" list in `CONTEXT.md`). Everything below was read from a local clone at
commit `1be8e34`. Line counts come from `wc -l`. The "fit" column is a first
guess; the final call is the orchestrator's.

## 1. Pack at a glance

- **What it is:** 25 engineering-workflow skills by Addy Osmani, ordered as
  software-lifecycle phases (Define, Plan, Build, Verify, Review, Ship). A router skill,
  `using-agent-skills`, picks among them.
- **License:** MIT. `LICENSE` says "Copyright (c) 2025 Addy Osmani". Both plugin manifests say `"license": "MIT"`.
- **Version:** commit `1be8e34`, dated 2026-10-10. Plugin version `0.6.12` (`plugin.json`, `.claude-plugin/plugin.json`, `.codex-plugin/plugin.json`).
- **Activity:** 322 commits since 2026-07-13, the last 90 days (`git log --since=2026-07-13 | wc -l`), out of 677 in total. Very active.
- **Layout:** `skills/` (25 directories; 21 hold only a SKILL.md, 4 also carry supporting files), `commands/*.toml` (9), `.claude/commands/*.md` (9), `.gemini/commands/*.toml` (9), `agents/` (4 personas), `hooks/` (3 hooks plus tests), `references/` (7 shared checklists), `evals/` (cases, fixtures, plugin cases), `scripts/` (Node validators and an eval runner), `docs/` (17 files, one setup guide per runtime).
- **Install model:** Claude Code marketplace plugin (`.claude-plugin/`), Codex plugin (`.codex-plugin/plugin.json` and `.agents/plugins/marketplace.json`), `gemini skills install … --path skills`, `npx skills add addyosmani/agent-skills`, or copying `skills/<name>/` by hand.
- **Runtimes:** the skills are plain `SKILL.md` files whose frontmatter has only `name` and `description` (checked on all 25). Any runtime that reads SKILL.md can use them, and none needs a hook or a manifest to work. The manifests only package the skills. What is tied to one runtime:
  - The short slash commands (`/spec`, `/build` and the rest) exist for Claude Code, Gemini CLI and Antigravity only. `docs/copilot-setup.md` says outright that they "never appear in Copilot". `docs/codex-setup.md` says to call the skill directly instead (for example `@spec-driven-development`).
  - The personas in `agents/` are subagents in Claude Code and Gemini. Copilot needs them renamed to `*.agent.md`.
  - The hooks are Claude Code `settings.json` hooks. The session-start hook is deliberately not wired up by either plugin.

## 2. Skill table

Invocation key: **M** means the agent picks the skill by matching its description. **M + /x** means it can also be started by slash command `/x`.

| skill | purpose (one line) | invocation | size | runtime/tool dependencies | depends on other skills in the pack | closest existing skill | first-guess fit |
|---|---|---|---|---|---|---|---|
| api-and-interface-design | Design stable REST/GraphQL/module interfaces that are hard to misuse | M | 367 | none | deprecation-and-migration | codebase-design | overlapping: deep-module vocabulary overlaps; adds REST/GraphQL contracts |
| browser-testing-with-devtools | Check live browser behaviour (DOM, console, network, performance) | M | 317 | **requires the chrome-devtools MCP server**; shows `.mcp.json` / Claude Code settings setup | none | none (Claude in Chrome is a plugin, not a skill) | new capability: runtime browser verification; depends on MCP availability |
| ci-cd-and-automation | Set up CI/CD pipelines, quality gates and deploy strategies | M | 390 | none | debugging-and-error-recovery | setup-pre-commit (narrow) | new capability: no CI/CD pipeline skill exists today |
| code-review-and-quality | Review on five axes: correctness, readability, architecture, security, performance | M + /review | 398 | `../../references/security-checklist.md`, `performance-checklist.md` | constraint-driven-development, performance-optimization, security-and-hardening | code-review (patched) | overlapping: different axes (5-axis vs Standards+Spec) |
| code-simplification | Make code easier to read without changing behaviour | M + /code-simplify | 331 | optional `hooks/simplify-ignore.sh` (Claude hook); reads CLAUDE.md "or equivalent" | none | none in skills/ (Claude-only built-in `simplify` and the code-simplifier plugin) | new capability: runtime-neutral version of a Claude-only feature |
| constraint-driven-development | Write the project's quality bar into CONSTRAINTS.md and catch agents lowering it | M + /constraints | 311 | own `references/floor-guard.md` (182 lines); edits AGENTS.md + CLAUDE.md; needs a live user | ci-cd, code-review-and-quality, interview-me, performance-optimization, security-and-hardening, test-driven-development | none (design-for-testability is adjacent) | new capability: written quality bar plus a check that it wasn't weakened |
| context-engineering | Choose and order what goes into the agent's context (rules files, MCP, etc.) | M | 353 | mentions CLAUDE.md, Cursor, Copilot and Codex rules files as examples | none | writing-for-agents; workspace context-budget rules | overlapping: the workspace already has stronger, tooled context discipline |
| debugging-and-error-recovery | Systematic root-cause debugging with a triage checklist | M | 300 | none | test-driven-development | diagnosing-bugs | duplicate: same reproduce→root-cause loop |
| deprecation-and-migration | Retire old code/APIs and move users over safely (expand/contract) | M | 247 | none | incremental-implementation | none | new capability: deprecation/sunset discipline is absent |
| documentation-and-adrs | Record decisions (ADRs) and the reasons behind them | M | 297 | default ADR path `docs/decisions/` (workspace uses `docs/adr/`) | none | decision-log, domain-modeling | overlapping: workspace has tiered decision capture already |
| doubt-driven-development | Get a fresh-context, adversarial review of each non-trivial decision, optionally from another model | M | 243 | spawns a subagent; offers Codex/Gemini CLI as a second model; `../../references/orchestration-patterns.md`; uses `agents/` personas in Claude Code | code-review-and-quality, debugging, source-driven, test-driven-development | research-wave (fact-checker), grilling | new capability: in-flight adversarial review, cross-model option |
| frontend-ui-engineering | Build accessible, responsive, non-generic UI | M | 340 | `../../references/accessibility-checklist.md` | none | none in skills/ (frontend-design plugin) | new capability: no UI-engineering skill ships today |
| git-workflow-and-versioning | Commit, branch and PR discipline, plus semver, tags and changelogs | M | 355 | none | api-and-interface-design, code-review-and-quality, deprecation-and-migration, shipping-and-launch | pr, git-guardrails-claude-code | overlapping: PR body exists; release/versioning part is new |
| idea-refine | Turn a vague idea into a one-page brief by widening options, then narrowing | M | 178 | own `scripts/idea-refine.sh` (makes `docs/ideas/`), `examples.md`, `frameworks.md`, `refinement-criteria.md` | none | grill-me / grilling, prototype | overlapping: ideation one-pager; grilling covers interrogation |
| incremental-implementation | Build in thin, checked slices; feature flags | M + /build (with TDD) | 249 | `../../references/definition-of-done.md` | git-workflow-and-versioning, test-driven-development | implement, tdd | overlapping: vertical-slice build already in implement/tdd |
| interview-me | Ask one question at a time until the real intent is clear | M | 235 | none; **description also triggers on "grill me"** | doubt-driven, idea-refine, planning, source-driven, spec-driven | grill-me / grilling | duplicate: same one-question interview; trigger collision |
| observability-and-instrumentation | Add logs, metrics, traces and alerts while writing the feature | M | 238 | `../../references/observability-checklist.md` | debugging, performance-optimization, security-and-hardening, shipping-and-launch | none | new capability: nothing covers production telemetry |
| performance-optimization | Measure, find the bottleneck, fix it, measure again (frontend, backend, database) | M | 267 | own `references/optimization-patterns.md` (250 lines); `../../references/performance-checklist.md`; MCP optional | none | diagnosing-bugs (perf regressions) | new capability: optimisation patterns, beyond regression diagnosis |
| planning-and-task-breakdown | Split a spec into ordered tasks with acceptance criteria | M + /planning (`/plan` in .claude) | 257 | writes `tasks/plan.md`, `tasks/todo.md`; `../../references/definition-of-done.md` | none | to-tickets, plans | overlapping: different output paths than work/ conventions |
| security-and-hardening | OWASP-style hardening, dependency audit, privacy | M | 216 | own `references/hardening-patterns.md` (324 lines); `../../references/security-checklist.md` | debugging, observability-and-instrumentation | none (built-in security-review is Claude-only) | new capability: no security skill in skills/ |
| shipping-and-launch | Pre-launch checklist, staged rollout, monitoring, rollback plan | M + /ship (fans out personas) | 336 | `../../references/` definition-of-done, security, performance, accessibility | observability-and-instrumentation | none | new capability: launch readiness is absent |
| source-driven-development | Check framework code against official docs and cite them | M | 216 | uses web fetch; optional `hooks/sdd-cache-*.sh` (Claude WebFetch hook) | security-and-hardening | research | overlapping: research does primary sources, not at implement time |
| spec-driven-development | Write a structured spec (PRD) before code | M + /spec | 259 | writes `SPEC.md` | api-and-interface-design, context-engineering, incremental-implementation, planning, test-driven-development | to-spec | overlapping: to-spec synthesises; this interviews; different path |
| test-driven-development | Red-green-refactor; "Prove-It" failing test for bugs | M + /test, /build | 398 | `../../references/testing-patterns.md` (JS/TS); mentions spawning a subagent; Chrome DevTools MCP | browser-testing-with-devtools | tdd | duplicate: same loop, different TDD philosophy |
| using-agent-skills | Router: choose the skill by lifecycle phase; always-on behaviours | M (or injected by session-start hook) | 192 | `../../references/definition-of-done.md`; MCP mention | **names all 24 other skills** | ask-matt; CONTEXT.md skill index | overlapping: a second router; conflicts with ask-matt |

Counts: 7 skills look most clearly new (browser-testing, ci-cd,
constraint-driven, deprecation, observability, security, shipping), with
doubt-driven, frontend-ui, performance and code-simplification close behind. 3
look like duplicates (debugging, interview-me, test-driven-development). The
rest overlap.

## 3. Commands, personas, hooks, references

### Commands
There are three copies of each command. `commands/*.toml` is for Antigravity (per the README). `.gemini/commands/*.toml` is identical to it for 5 of the 9 and differs only in runtime wording ("Gemini CLI") for code-simplify, constraints, ship and webperf. `.claude/commands/*.md` is the Claude Code version, where `planning` is named `plan.md`.

| command | what it does | runtime-neutral form | one-runtime parts |
|---|---|---|---|
| /spec (16 lines) | Starts spec-driven-development | Drop it; the skill is enough | none |
| /planning (18) | Starts planning-and-task-breakdown in read-only mode | Drop it | "plan mode" is a Claude notion |
| /build (43) | Runs incremental-implementation + TDD on one task; `/build auto` runs the whole approved plan | Make `auto` a section inside incremental-implementation, or drop it (the workspace has implement / implement-spec) | none really |
| /test (18) | Starts TDD; "Prove-It" steps for bugs | Drop it | none |
| /review (15) | Starts code-review-and-quality (5 axes) | Drop it | none |
| /code-simplify (21) | Starts code-simplification | Drop it | the optional simplify-ignore hook |
| /constraints (32) | Runs constraint-driven-development: detect the stack, ask, write CONSTRAINTS.md | Drop it; the skill holds the steps | none |
| /ship (71) | Runs code-reviewer, security-auditor and test-engineer as parallel subagents, then gives one go/no-go with a rollback plan | Would need a skill that says "run these three reviews, in parallel where possible"; its built-in fallback is to run the persona prompts one after another | relies on subagents named after agents/*.md (Claude, Gemini) |
| /webperf (32) | Runs the web-performance-auditor persona, quick or deep (with a Lighthouse JSON) | A skill or doc | persona-as-tool |

### Personas (`agents/`)
| persona | lines | what it does | runtime-neutral form |
|---|---|---|---|
| code-reviewer | 102 | Staff-engineer review on five axes | Mostly duplicates code-review-and-quality; drop it or treat it as a prompt the skill quotes |
| security-auditor | 112 | Vulnerability review and threat modelling | Could become a reviewer prompt inside security-and-hardening |
| test-engineer | 95 | Test strategy, coverage gaps | Could become a section of TDD |
| web-performance-auditor | 184 | Core Web Vitals audit, quick or deep mode | Could become a section of performance-optimization |

Personas are subagent definitions with only `name` + `description`
frontmatter. They work natively in Claude Code and Gemini. Copilot needs the
files renamed to `*.agent.md`. Codex does not wire them up (`docs/codex-setup.md`).

### Hooks (`hooks/`)
| hook | lines | what it does | runtime-neutral? |
|---|---|---|---|
| session-start.sh | 33 | Prints `using-agent-skills` as a SessionStart JSON message; needs `jq` | No. The SessionStart envelope is the Claude/Codex hook format, and the authors say not to use it where the runtime already routes skills |
| sdd-cache-pre.sh / -post.sh | 106 / 135 (+246 test, doc SDD-CACHE.md 167) | Disk cache for WebFetch, re-checked with the server (304) on every reuse | No. It is a Claude `PreToolUse`/`PostToolUse` matcher on `WebFetch`. Drop it |
| simplify-ignore.sh | 391 (+526 test, doc SIMPLIFY-IGNORE.md 91) | Hides `simplify-ignore-start/end` blocks from the model during /code-simplify | No. Claude hook. Drop it; the marker idea could be a sentence in the skill |

### References (`references/`, at the pack root and shared by several skills)
| file | lines | one line | used by |
|---|---|---|---|
| accessibility-checklist.md | 160 | WCAG 2.1 AA quick reference | frontend-ui, shipping |
| definition-of-done.md | 67 | Project-wide "is it finished" bar, kept separate from per-task acceptance criteria | incremental, planning, shipping, using-agent-skills |
| observability-checklist.md | 92 | Instrumentation checklist, including a pre-launch gate | observability |
| orchestration-patterns.md | 370 | Approved multi-agent patterns; "personas do not invoke other personas" | doubt-driven, /ship |
| performance-checklist.md | 236 | Web performance checklist, caching strategies | code-review, performance, shipping |
| security-checklist.md | 248 | Auth, input, headers, supply chain, AI/LLM, OWASP tables | code-review, security, shipping |
| testing-patterns.md | 235 | JS/TS test examples (Jest, RTL, Supertest, Playwright) | TDD |

All of these are runtime-neutral docs. The catch is where they live (see section 6).

## 4. Distinctive mechanisms worth knowing

- **Common Rationalizations tables.** These are two-column "Rationalization | Reality" tables that list the excuses an agent makes to skip a step, each with a rebuttal. 23 of 25 skills have one; idea-refine and using-agent-skills do not (checked with `grep -L`). `docs/skill-anatomy.md` (203 lines) calls them "the most distinctive feature of well-crafted skills" and requires one for every step an agent might skip.
- **Red Flags sections.** 24 of 25 skills have one; only using-agent-skills lacks it.
- **Fixed section order.** Every skill follows Overview / When to Use (with "When NOT to use") / Process / Rationalizations / Red Flags / Verification checklist (`docs/skill-anatomy.md`).
- **Three-tier eval framework** (`evals/README.md`, 101 lines; `scripts/run-evals.js`, about 27 KB, Node):
  - Tier 1 checks structure (`validate-skills.js`, `validate-commands.js`).
  - Tier 2 checks routing. It scores each skill description against sample prompts with word statistics (stemmed TF-IDF), checks that each skill's positive prompts rank it in the top results, and flags near-identical descriptions. It costs nothing and runs in CI.
  - Tier 3 checks behaviour. It runs headless `claude -p` in a throwaway git repo and grades the transcript against `expectations[]`.
  - There is one case file per skill (`evals/cases/*.json`, 25), plus `evals/fixtures/` (25 directories) and `evals/plugin/` (3 Claude `claude plugin eval` cases).
  - `evals/skill-impact.md` is an append-only log of skill changes rejected on eval evidence; it is empty so far.
  - Tier 2 is the part a template could borrow without depending on any one runtime.
- **`/build auto`** (`commands/build.toml` lines 19–43). It requires a spec at a known path and a clean `git status`, gets one firm human approval (a hedged "looks reasonable" does not count), then runs test → code → commit for every task. It stops for broken builds, unclear specs, or risky or irreversible tasks (sending those to doubt-driven-development). After a blocker it resumes from the next pending task.
- **`/ship` fan-out** (`commands/ship.toml`, 71 lines). It runs three personas in parallel, then the main agent merges their reports into one go/no-go decision with a rollback plan. It skips the fan-out only when the change touches 2 files or fewer, is under 50 lines, and avoids auth, payments and config. It falls back to running the personas one after another when subagents are unavailable.
- **Doubt-driven review across models** (`skills/doubt-driven-development/SKILL.md` lines 85–150). The reviewer gets the artifact and the contract, never the author's conclusion. The prompt tells it to find problems, not to approve. In an interactive session the skill must always offer a second opinion from Codex or Gemini CLI, written to a temp file and piped in so shell characters stay harmless. The loop is bounded at 3 cycles.
- **CONSTRAINTS.md plus a "floor guard"** (`skills/constraint-driven-development/`). It finds what it can before asking, asks four questions that each have a default, and defines a floor that always applies (no new `@ts-ignore`, skipped tests, stripped assertions or lowered thresholds). It offers three ways to enforce it: written only, a shell script, or a dedicated tool. A reference checker ships in `references/floor-guard.md` (182 lines).
- **`references/` checklists:** see the table in section 3. `definition-of-done.md` and `orchestration-patterns.md` are the two that are general rather than web-specific.

## 5. Name collisions with existing `skills/` directories

- **Exact matches:** none. None of the 25 names equals an existing `skills/` directory.
- **Near-matches and functional collisions:**
  - `test-driven-development` vs `tdd`. Same job, and `superpowers:test-driven-development` (a plugin installed on this machine) already uses the identical name.
  - `code-review-and-quality` vs `code-review`. The latter already collides with Claude Code's built-in `/code-review` command.
  - `debugging-and-error-recovery` vs `diagnosing-bugs`.
  - `interview-me` vs `grill-me` / `grilling`. interview-me's description lists "grill me" as a trigger phrase, so the agent could pick either.
  - `spec-driven-development` vs `to-spec`.
  - `planning-and-task-breakdown` vs `to-tickets` / `plans`. Its Claude command is `/plan`, which is the **exact name** of the workspace's `/plan` command (`.claude/commands/`).
  - `documentation-and-adrs` vs `decision-log` / `domain-modeling`.
  - `incremental-implementation` vs `implement`.
  - `using-agent-skills` vs `ask-matt` (two routers).
  - `code-simplification` vs Claude Code's built-in `simplify` (not in skills/).
- **Slash-command clashes if the commands were copied:** `/plan` (exact clash), `/review` and `/test` (generic names), `/build` and `/ship` (no clash found).

## 6. Risks for vendoring

- **Links that reach outside the skill folder.** 11 skills link to the root `references/` folder with `../../references/…`. Copying only `skills/<name>/` breaks those links. Upstream knows: `docs/skill-anatomy.md` "Shared References" and `docs/opencode-setup.md` cite issue #361. The 11 are code-review-and-quality, doubt-driven, frontend-ui, incremental, observability, performance, planning, security, shipping, TDD and using-agent-skills. Vendoring needs either a copy of `references/` at a matching relative path or rewritten links.
- **Skill-local files.** These are safe to copy because they travel with the folder: constraint-driven `references/floor-guard.md`, performance `references/optimization-patterns.md`, security `references/hardening-patterns.md`, and idea-refine's `examples.md`, `frameworks.md`, `refinement-criteria.md` and `scripts/idea-refine.sh`. The script writes to `docs/ideas/`. It is harmless, but it is a script from outside the repo.
- **The router names every skill.** `using-agent-skills` has a decision tree naming all 24 others, so a partial vendor leaves dead branches. The router would need editing, or should not be vendored, especially beside `ask-matt`. Upstream itself warns against preloading it where the runtime already routes skills.
- **Links between skills.** 17 of 25 skills mention other pack skills by name (see the table), so cherry-picked skills will point at skills that are not there. Examples: constraint-driven names 6 others, and spec-driven names 5.
- **Output paths that clash with workspace conventions.** `SPEC.md`, `tasks/plan.md` and `tasks/todo.md`, `docs/ideas/`, `docs/decisions/` for ADRs, and `CONSTRAINTS.md` (constraint-driven also edits AGENTS.md and CLAUDE.md, which are symlinks to CONTEXT.md here). Those last edits would have to go to CONTEXT.md.
- **Runtime-specific bits inside otherwise neutral skills.** browser-testing needs the chrome-devtools MCP server. doubt-driven assumes a subagent can be spawned and gives Claude Code-specific fallbacks. TDD suggests spawning a subagent. These degrade rather than fail.
- **Version pins and refresh.** There is no version pin inside any SKILL.md; the version (`0.6.12`) lives only in the manifests. The pack moves fast (322 commits in 90 days), so the template's provenance-comment and sync-script approach would need a second upstream and frequent refreshes. Repo-wide wording edits (for example "CLI" vs "Gemini CLI" in commands) show up as churn.
- **Size.** The skills are long, 178–398 lines each and 7,290 lines across all 25 SKILL.md files. That costs context when a skill loads, compared with the shorter Matt Pocock skills.
- **License:** MIT, copyright 2025 Addy Osmani. Vendoring needs only the copyright notice and permission text kept, as already done for the Matt Pocock set. No concern found.
