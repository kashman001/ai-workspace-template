# Addy Osmani's agent-skills and pstack: what to take, what to leave

Session 24, 2026-10-11. The user asked: compare these two skill packs with the
Matt Pocock set the template already ships, say what each adds, and turn the
useful parts into backlog work. This page is the answer. The one-page summary
comes first; the detail, the dependency graph, and the waves follow.

Inventories behind this page: `skill-packs-inventory-addy.md` and
`skill-packs-inventory-pstack.md` (same directory). Both were read from local
clones; nothing from the clones was executed.

## One-page summary

**Take 16 skills out of 77: 9 from Addy Osmani, 7 from pstack.** Leave the
rest, mostly because the template already has an equivalent, or because the
skill only works inside Cursor.

| Pack | Skills in pack | Take | Why these |
|---|---|---|---|
| Addy Osmani `agent-skills` | 25 | 9 | They cover lifecycle areas the template has nothing for: security, observability, launch, CI/CD, deprecation, performance, a written quality bar, in-flight adversarial review, code simplification. All plain Markdown, any runtime reads them. |
| pstack (Lauren Tan) | 52 (28 workflow + 24 principles) | 7 | Short, plain-text skills that stand alone: a catalog of AI-prose tells, a technical-writing standard, a benchmark-vetting checklist, "what could this break" proof-by-running, "why is the code like this" history recovery, and a generator plus upkeep loop for a per-repo "drive the real app" skill. |

What we leave and why, in one line each:

- **Duplicates of what we have.** Addy: `test-driven-development` (we have `tdd`), `debugging-and-error-recovery` (`diagnosing-bugs`), `interview-me` (`grill-me`; it even fires on "grill me"), `using-agent-skills` (a second router beside `ask-matt`), `spec-driven-development` (`to-spec`), `planning-and-task-breakdown` (`to-tickets`, `plans`; its `/plan` command clashes with ours), `incremental-implementation` (`implement`), `documentation-and-adrs` (`decision-log`), `context-engineering` (our context-budget tooling is stronger), `idea-refine` (`grill-me`, `prototype`), `source-driven-development` (`research`), `git-workflow-and-versioning` (`pr`), `api-and-interface-design` (`codebase-design`). pstack: `tdd` and `teach` (same names, ours stay), `bro` (`wait-what`), `reflect` and `correct` (`retro`), `poteto-help` (`ask-matt`), `show-me-your-work` (`decision-log`), `recall` (`handoff`, launcher/ledger), `figure-it-out` (`plans`, `wayfinder`), `interrogate` (`code-review`), `how` (graphify, `onboard-repo`), `architect` (`codebase-design`, `prototype`).
- **Only work in one place.** pstack's `poteto-mode` (the whole operating mode), `setup-pstack`, `swarm`, `arena`, `automate-me`, `make-bot-ui`, `no-comments`, the `benny` automations and the 23 playbooks need Cursor's subagent tool, model routing, cloud workers, `/loop`, transcript paths or Cursor rules. Addy's slash commands, persona agents and hooks are Claude Code or Gemini only. None of these ship.
- **Domain-specific.** Addy's `frontend-ui-engineering` and `browser-testing-with-devtools` (web only; the latter needs a Chrome DevTools MCP server) and pstack's `typescript-best-practices`. A project that needs them can add them per repo.
- **The 24 pstack principles.** Short one-rule cards. Six repeat the template's own coding principles; four contradict them (`never-block-on-the-human` versus "ask when uncertain", and `subtract-before-you-add`, `redesign-from-first-principles`, `migrate-callers-then-delete` versus "surgical changes"). On their own they are inert; only `poteto-mode` points at them. Not adopted.

What the user should know:

- **Licenses are fine.** Both packs are MIT. Addy: "Copyright (c) 2025 Addy Osmani". pstack: "Copyright (c) 2026 Lauren Tan" (`pstack/LICENSE` in the `cursor/plugins` repo). Same terms as the Matt Pocock set, different copyright holders. The license texts go into the catalog doc.
- **pstack upstream.** We vendor from the canonical source, `github.com/cursor/plugins`, directory `pstack/` (Lauren Tan is "poteto"; the directory carries its own LICENSE). The multi-harness port `michael-denyer/pstack-claude` was read to learn how Cursor features were translated, but not copied: it carries 47 local forks and a second copyright, and the seven skills we take are plain text that need no port.
- **Everything is agent-agnostic.** Each skill lands as `skills/<name>/SKILL.md`, readable by Claude Code, Codex, Gemini CLI, Copilot and OpenCode. Where a skill mentions "spawn a subagent", it is phrased as an option with a sequential fallback; where it named a Cursor path or a Claude Code `agents/` roster, a small patch replaces the sentence. Two skills are user-invoked (`create-verification-skill`, `maintain-verification-skill`); they get `.claude/commands/` shortcuts and the Codex `agents/openai.yaml` switch, like the existing user-invoked set.
- **Refresh path.** The existing sync script learns a second and third upstream, so all vendored skills refresh the same way, carry the same pinned-commit comment, and trip the same 60-day drift warning.
- **Nothing needs the user's decision.** Every call below has a sensible default and a recorded reason. The one thing to notice: this adds 16 skills (about 4,300 lines) to the repo. Each loads only when triggered, so day-to-day context cost is small.

## Glossary

- **Skill** — a folder `skills/<name>/` with a `SKILL.md` an agent reads when the task matches. Plain Markdown; every runtime understands it.
- **Vendored** — copied into this repo from an upstream project, with a comment that records the upstream commit, so it can be refreshed and its license honoured.
- **Pristine / adapted / patched** — the three vendored classes (`skills/vendored-skills.md`). Pristine: an exact copy. Adapted: we own the frontmatter (the YAML header), the body is upstream's. Patched: upstream's file plus a small saved diff the refresh re-applies.
- **Model-invoked / user-invoked** — a skill the agent picks on its own when the description matches, versus one the user starts by name (slash command).
- **Runtime** — the agent program: Claude Code, Codex, Gemini CLI, Copilot, OpenCode, Cursor.
- **Subagent** — a child agent a runtime can start for a side task. Not every runtime has one, so a skill may suggest it but must work without it.
- **Playbook** (pstack) — a numbered step list inside `poteto-mode` for one kind of task.
- **Shared references** (Addy) — checklists kept at the pack's root `references/` folder and linked from several skills with `../../references/...`.
- **Card** — one item in `docs/template-workspace-backlog.html`, with an ID like `L75`.
- **Wave** — a group of cards with no dependencies between them, so they run in parallel.

## Detail: Addy Osmani's agent-skills

Pack facts: 25 skills, 7,290 lines of SKILL.md, every file plain Markdown with only `name` and `description` in the header. Very active (322 commits in 90 days). Install models are Claude Code plugin, Codex plugin, `gemini skills install`, `npx skills add`, or copy by hand. The runtime-specific parts (9 slash commands, 4 persona agents, 3 hooks, an eval framework) sit beside the skills, not inside them. Every skill has a "Common Rationalizations" table (excuses an agent makes to skip a step, each rebutted) and a "Red Flags" list; both are plain text and travel with the skill.

Decision per skill. "Shared refs" names the pack-root checklists the skill links to.

| Skill | Decision | Class | Reason | Shared refs |
|---|---|---|---|---|
| security-and-hardening | adopt | pristine | No security skill exists. Threat model, OWASP walk, privacy. Own `references/hardening-patterns.md` travels with it. | security-checklist |
| observability-and-instrumentation | adopt | pristine | Nothing covers logs, metrics, traces, alerts. | observability-checklist |
| shipping-and-launch | adopt | pristine | Launch readiness, staged rollout, rollback. Its `/ship` persona fan-out stays behind; the catalog says to run the three reviews yourself. | definition-of-done, security, performance, accessibility |
| ci-cd-and-automation | adopt | pristine | No CI/CD skill exists. | none |
| deprecation-and-migration | adopt | pristine | Expand/contract deprecation discipline is absent. | none |
| performance-optimization | adopt | pristine | `diagnosing-bugs` finds a regression; this one optimises (measure, bottleneck, fix, measure). Own `references/optimization-patterns.md`. | performance-checklist |
| code-simplification | adopt | pristine | Runtime-neutral version of a Claude Code only feature (`simplify`). Its optional hook is not vendored. | none |
| doubt-driven-development | adopt | patched | In-flight adversarial review of each non-trivial decision, with a second model via Codex or Gemini CLI. New. Patch: the three lines that point at a Claude Code `agents/` persona roster we do not ship. | orchestration-patterns |
| constraint-driven-development | adopt | patched | A written quality bar (`CONSTRAINTS.md`) plus a "floor guard" that catches an agent weakening it. New. Patch: "add one line to `AGENTS.md` and `CLAUDE.md`" becomes `CONTEXT.md` (those two are symlinks here). Names six pack skills; the catalog maps the three we skip to our equivalents (`interview-me` → `grill-me`, `test-driven-development` → `tdd`, `code-review-and-quality` → `code-review`). | none |
| test-driven-development | skip | | Same loop as `tdd`, different philosophy; name also used by the superpowers plugin. | |
| debugging-and-error-recovery | skip | | Same reproduce → root-cause loop as `diagnosing-bugs`. | |
| interview-me | skip | | Same one-question interview as `grill-me`; its trigger phrase collides. | |
| using-agent-skills | skip | | A router that names all 24 other skills; `ask-matt` and the `CONTEXT.md` index already route. | |
| spec-driven-development | skip | | `to-spec` covers it under our `work/<effort>/spec.md` convention. | |
| planning-and-task-breakdown | skip | | `to-tickets` and `plans`; its Claude command is `/plan`, which we already use. | |
| incremental-implementation | skip | | `implement` and `tdd` already build in slices. | |
| documentation-and-adrs | skip | | `decision-log` with its three tiers; different ADR path. | |
| context-engineering | skip | | The workspace has tooled context discipline (budget, hooks). | |
| idea-refine | skip | | `grill-me` and `prototype`. | |
| source-driven-development | skip | | `research` reads primary sources. | |
| git-workflow-and-versioning | skip | | `pr` covers the PR body; the rest is generic. | |
| api-and-interface-design | skip | | `codebase-design`; the REST/GraphQL part is per project. | |
| frontend-ui-engineering | skip | | Web-domain specific; add per project. | |
| browser-testing-with-devtools | skip | | Needs the Chrome DevTools MCP server; add per project. | |
| code-review-and-quality | skip | | `code-review` (patched) is the reviewer; five axes versus two is not worth two review skills. | |

Not vendored around the skills: the slash commands (the skills trigger by description; `/plan` would clash), the four personas (`code-reviewer` duplicates a review skill; the others are prompts a skill can carry), the hooks (Claude Code `settings.json` format), the eval framework (Node tooling keyed to their catalog; the routing-collision check is a good idea for later).

Where the shared checklists go. Eleven Addy skills link to `../../references/<file>.md`, which from `skills/<name>/SKILL.md` resolves to the repo root `references/` folder. The workspace already has that folder (a registry of external references, with its clones gitignored). Decision: vendor the six needed checklists at `references/<file>.md` exactly, add `!references/*.md` to `.gitignore`, and list them in `references/README.md`. The skills stay pristine and their links work. Rejected: rewriting the links by patch (fragile against a fast-moving upstream) or a sub-folder (would still need a rewrite).

## Detail: pstack

Pack facts: 52 skills (11,720 lines with support files), 2 subagent definitions, 23 playbooks, Bun/TypeScript tooling (about 6,700 lines) inside `poteto-mode`. Canonical source `github.com/cursor/plugins`, directory `pstack/`, MIT, Lauren Tan. 51 commits in 90 days. Two-step use: `/setup-pstack` writes a Cursor rule mapping roles to models (defaults `claude-opus-5-5-xhigh` for judgment and `grok-4.7-xhigh-fast` for code), then `/poteto-mode` picks a playbook and calls the other skills through Cursor's `Task` tool with named models. Every skill except `setup-pstack` is user-invoked. The denyer port needed 74 mechanical substitutions and 47 forks to run elsewhere, and verified only skill discovery on OpenCode and Gemini.

Decision per workflow skill:

| Skill | Decision | Class | Reason |
|---|---|---|---|
| unslop | adopt | adapted (frontmatter) | A numbered catalog of AI-prose tells. Nothing like it exists; `writing-for-agents` is about agent readers. 62 lines, no dependencies. Made model-invoked so it fires when prose is written. |
| technical-writing | adopt | adapted (frontmatter) | A human-facing doc standard (Diátaxis, Google style, STE, Global English). The workspace has agent-facing style and doc critique, not this. Depends only on `unslop`. |
| benchmark-checklist | adopt | adapted + patch | Seven questions that vet a performance number. Plain shell tools. Patch: its last section names three poteto-mode playbooks; replace with the `pr` skill. |
| blast-radius | adopt | adapted + patch | "What could this break" beyond the diff, and prove the one safety fact by running code. `code-review` reads the diff only. Patch: `how` → the repo's own navigation (graphify, `onboard-repo` docs); the `arena` step → ask a second model as `doubt-driven-development` does. `why` and `unslop` are adopted, so those references hold. |
| why | adopt | adapted (rewrite) | Recover why code is shaped as it is: git history, PR discussion, tickets, docs, incidents, graded by confidence. Nothing does this; `decision-log` only helps when an ADR exists. Upstream's text is built on Cursor's `Task` tool, model lines and an `mcps/` directory, so the SKILL.md is rewritten in the workspace's words (crediting pstack); `references/epistemics.md` (the confidence framework) is vendored verbatim. Subagents are optional, sources sequential otherwise. |
| create-verification-skill | adopt | adapted + patch | Generates a per-repo skill that launches, drives and captures evidence from the real app. Matches "Authoring a Team Capability". Patch: `.cursor/skills/verify-<app>/` → `skills/verify-<app>/` (three places). User-invoked. |
| maintain-verification-skill | adopt | adapted + patch | The upkeep loop for the skill above. Patch: the `.cursor/skills/verify-*/` path. User-invoked. The "one read-only subagent per feature" step is optional; read sequentially where the runtime has no subagents. |
| tdd | skip | | Name collision; ours is the fuller red-green-refactor loop. |
| teach | skip | | Name collision; ours teaches a concept, theirs explains code. |
| bro | skip | | `wait-what`. |
| reflect, correct | skip | | `retro`; `correct`'s "prove each check fails first" is already a workspace principle. |
| poteto-help | skip | | Router for pstack only; `ask-matt` routes ours. |
| show-me-your-work | skip | | `decision-log` and the ledger. |
| recall | skip | | Mines Cursor transcripts; the workspace keeps state in `work/` instead. |
| figure-it-out | skip | | `plans` and `wayfinder`. |
| interrogate | skip | | Multi-model `code-review`; needs the model sheet. |
| how | skip | | graphify, `repo-navigator`, `onboard-repo` docs. |
| architect | skip | | `codebase-design`, `prototype`; its value is multi-model, Cursor-bound. |
| arena, swarm | skip | | Best-of-N and fan-out need Cursor subagents, model routing, cloud workers. Worth a look later for runtimes with subagents. |
| automate-me, setup-pstack, make-bot-ui, no-comments | skip | | Cursor rules, transcripts, routines, or a Cursor-format agent file. |
| ketchup | skip | | Small; `checkpoint` and the ledger. |
| typescript-best-practices | skip | | Language-specific; per project. |
| poteto-mode (+23 playbooks) | skip | | The operating mode is Cursor-bound (Custom Mode, `/loop`, cloud, bundled scripts) and its autonomy rule contradicts the workspace's "ask when uncertain". The `hillclimb` and `bug-fix` playbook texts are good reading; not vendored. |
| 24 `principle-*` | skip | | See the summary. |

## Name collisions, resolved

Rule: the existing skill wins; nothing is shadowed. Recorded as Tier-2 notes in `decisions.md`.

| Incoming | Existing | Call |
|---|---|---|
| pstack `tdd`, `teach` | `tdd`, `teach` (Matt Pocock) | not vendored |
| Addy `interview-me` (fires on "grill me") | `grill-me` | not vendored |
| Addy `planning-and-task-breakdown` (`/plan`) | `/plan` | not vendored |
| Addy `using-agent-skills`, pstack `poteto-help` | `ask-matt` | not vendored |
| Addy `code-review-and-quality` | `code-review` | not vendored |
| pstack `create-verification-skill` output | Claude Code built-in `/verify`, `run` | output named `verify-<app>`, no clash |

## Backlog cards, dependencies, waves

Cards live in `docs/template-workspace-backlog.html`.

| Card | What | Depends on | Wave | Worker |
|---|---|---|---|---|
| M50 | Sync script and drift check learn multiple upstreams (Addy, pstack beside Matt Pocock); patches apply to adapted skills; adapted skills keep a workspace `agents/openai.yaml`; vendored reference files get the provenance stamp | — | 1 | opus, TDD |
| L75 | Vendor the 7 pristine Addy skills + 6 shared checklists at `references/`, gitignore exception | — | 1 | sonnet |
| L76 | Vendor the 2 patched Addy skills (doubt-driven, constraint-driven) with their `workspace.patch` | — | 1 | opus |
| L77 | Vendor pstack `unslop`, `technical-writing` (adapted) and `benchmark-checklist` (adapted + patch) | — | 1 | sonnet |
| L78 | Vendor pstack `blast-radius`, `create-verification-skill`, `maintain-verification-skill` (adapted + patch), with `agents/openai.yaml` for the two user-invoked ones | — | 1 | opus |
| L79 | Write the adapted `why` skill (rewrite) with `references/epistemics.md` vendored | — | 1 | opus |
| L80 | Catalog and wiring: `skills/vendored-skills.md` (three upstreams, licenses), `CONTEXT.md`, `docs/workspace-structure.md`, `docs/recommended-tooling.md`, `references/README.md`, `.claude/commands/` for the user-invoked pair, decisions | M50, L75–L79 | 2 | orchestrator |
| L81 | Verify: run the sync against the clones and check `git diff` is empty (round trip), audit every new skill for leftover runtime-specific text, run `scripts/run-checks.sh` | L80 | 3 | sonnet audit + orchestrator |

Wave 1 cards all write to disjoint new directories, so they run at once. Wave 1
workers copy files by hand with the agreed provenance comment; the sync's
round trip in L81 proves the copies match what the script would produce.

Dependency graph (arrows point at what must finish first):

```
M50 ─┐
L75 ─┤
L76 ─┤
L77 ─┼──▶ L80 ──▶ L81
L78 ─┤
L79 ─┘
```

No `scripts/plan.sh` plan was created: the work is one session, the
orchestrator holds the graph, and the cards and this table record it.

## After the video (2026-10-11)

Rob Shocks' video on Addy Osmani's agent-skills made three points. What plan
`01-skill-ceremony` did for each:

1. **Match ceremony to stakes.** New guide `docs/stakes-to-ceremony.md`: a table
   from a change's size and risk to the skills it deserves, plus an "Adopting
   the skills" note (roll out gradually, verification first, prune).
2. **More skills is not a smarter agent.** Trigger review with counts, verdicts
   and reasons: `work/template-maintenance/trigger-review.md`. Applied:
   - `checkpoint`, `session-rollover`, `design-for-testability` became
     user-invoked (`disable-model-invocation: true`; slash commands already existed).
   - `unslop` is a final editing pass on human-facing prose, no longer "always apply";
     `technical-writing` no longer triggers on commit messages or a slash command.
   - `constraint-driven-development` and `doubt-driven-development` got tighter
     descriptions through their patches; `decision-log` (910 → 305 bytes) and
     `jev` (482 → 303) in their own frontmatter.
   - New check `scripts/check-skill-descriptions.sh` bounds the model-invoked
     description total at 7500 bytes (29 skills, 7,303 bytes; was 10,174).
3. **Steal Addy's anti-rationalization tables.** `## Common rationalizations`
   tables now sit in `checkpoint`, `session-rollover`, `decision-log`,
   `create-work-item` and `plans`.

Mapping: Addy's `/build auto` corresponds to `implement-spec` here.

Not done: Addy's "update the skill when the agent repeats a mistake" line was
not added to `retro`, because `retro` is pristine vendored (edits would break
the sync round trip). The guide's "Floors" section carries that advice instead.

The Tier-2 notes for these choices are at the end of
`work/template-maintenance/decisions.md`.
