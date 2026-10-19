# Vendored Skills

The skills listed here are vendored from three upstreams, all MIT (one
license text, three copyright holders, at the bottom), so they ship with this
workspace — no per-user clone or symlink setup required, and every runtime
(Claude Code, Codex, Gemini, OpenCode, Copilot) reads the same
`skills/<name>/SKILL.md`:

- **Matt Pocock engineering set** —
  [github.com/mattpocock/skills](https://github.com/mattpocock/skills). The
  core workflow: grilling, specs, tickets, TDD, review. Each directory also
  carries upstream's `agents/openai.yaml` metadata for OpenAI-runtime
  compatibility.
- **Addy Osmani lifecycle set** —
  [github.com/addyosmani/agent-skills](https://github.com/addyosmani/agent-skills).
  Eight skills for the lifecycle areas the core set lacks (security,
  observability, launch, CI/CD, deprecation, performance, a written quality
  bar, in-flight adversarial review).
- **pstack** (Lauren Tan, "poteto") —
  [github.com/cursor/plugins](https://github.com/cursor/plugins/tree/main/pstack),
  directory `pstack/`. Seven short plain-text skills: prose, benchmarks, blast
  radius, decision archaeology, a per-repo "drive the real app" harness.

Why these and not the rest of each pack (duplicates, Cursor-only, domain
specific) is recorded in `work/template-maintenance/skill-packs-analysis.md`.

Each vendored `SKILL.md` opens with a provenance comment pinning the upstream
commit. Refresh with `scripts/sync-vendored-skills.sh [<upstream> [<clone>]]`
— upstream keys `mattpocock`, `addyosmani`, `pstack`; with no arguments it
refreshes every upstream whose clone it finds and prints `git clone`
instructions for the missing ones (a sparse clone of only `pstack/` is enough
for `cursor/plugins`). The pstack pin is the last commit touching `pstack/`,
not the repo HEAD. `scripts/check-drift.sh` warns once the oldest pinned
commit of any upstream is more than 60 days old; refresh then. Three classes:

- **Pristine** — the whole directory is upstream content, unmodified. Keep it
  that way so refreshes stay a clean re-copy.
- **Adapted** — the `SKILL.md` frontmatter + provenance comment are
  workspace-specific (wired to this workspace's tracker/spec conventions, or
  switching a skill between user- and model-invoked); the body below the
  comment is pristine upstream content. A workspace-owned
  `agents/openai.yaml` survives the refresh when upstream ships none.
- **Patched** — a pristine or adapted skill whose directory also holds a
  `workspace.patch` (a unified diff against its `SKILL.md`). The sync
  re-copies upstream, then re-applies the patch; if the patch no longer
  applies, the sync stops and names the skill, so rewrite the patch against
  the re-copied file. To change a patched skill, edit the patch, not
  `SKILL.md`. Prefer sending the change upstream; patch only what upstream
  has not taken. Start the patch with a line `Upstream: <owner>/<repo>#<N>`
  naming the upstream issue or PR, above the diff (`patch` ignores it), or
  `Upstream: none filed`. When `gh` reports that issue or PR closed, the sync
  prints "upstream may have landed this; delete the patch"; without `gh`, or
  offline, it says nothing.

Skills marked *(slash)* have a Claude Code shortcut under `.claude/commands/`;
the rest are model-invoked (triggered by their `description`). Every
model-invoked description is weighed by the runtime on every turn, so
`scripts/check-skill-descriptions.sh` bounds their total;
adding one means trimming another or making a procedure skill user-invoked.
Which skills a change needs at all: `docs/stakes-to-ceremony.md`.

## Matt Pocock engineering set

### Engineering

- **ask-matt** *(slash)* — router: ask which skill or flow fits your situation.
- **code-review** *(patched)* — review changes since a fixed point along
  Standards + Spec axes; the patch groups each axis into blockers and
  suggestions. ⚠ Name collides with Claude Code's built-in `/code-review` command
  and the `code-review` plugin; invoke via the Skill tool if ambiguous.
- **codebase-design** — shared vocabulary for designing deep modules.
- **diagnosing-bugs** — diagnosis loop for hard bugs and perf regressions.
- **domain-modeling** — build and sharpen the project's domain model
  (`GLOSSARY.md` glossary, ADRs).
- **grill-with-docs** *(slash)* — grill a plan, creating ADRs/glossary as you go.
- **implement** *(slash)* — implement a piece of work from a spec or tickets.
- **implement-spec** *(slash)* — implement a whole spec's tickets as a task
  graph, with parallel subagents on one integration branch. Use it for
  tracker-backed to-spec/to-tickets output; a multi-session work item with
  waves or HITL steps belongs to `/plan`.
- **improve-codebase-architecture** *(slash)* — find deepening opportunities,
  HTML report, grill through your pick.
- **pr** — template for a PR body that is fast to review.
- **prototype** — throwaway prototype to answer a design question.
- **research** — investigate a question against primary sources, capture as
  a Markdown file.
- **retro** *(slash)* — retrospective on a session: suggest improvements to
  the agent's environment (navigation, checks, standards, steering files).
- **setup-matt-pocock-skills** *(slash)* — one-time per-repo config (issue
  tracker, triage labels, domain docs) the engineering skills consume.
- **tdd** — red-green-refactor, one vertical slice at a time.
- **to-spec** *(slash, adapted)* — conversation → spec at `work/<effort>/spec.md`.
- **to-tickets** *(slash, adapted)* — plan/spec → tracer-bullet tickets.
- **triage** *(slash, adapted)* — move issues through the triage state machine.
- **wayfinder** *(slash, adapted)* — plan work too big for one session as a
  map of decision tickets.
- **wizard** — generate an interactive bash wizard for human-only steps.

### Productivity

- **grill-me** *(slash)* — relentless interview to sharpen a plan or design.
- **grilling** — the underlying grilling technique (used by grill-me /
  grill-with-docs).
- **handoff** *(slash)* — compact the conversation into a handoff doc for
  another agent.
- **teach** *(slash)* — teach the user a new skill or concept.
- **to-questionnaire** *(slash)* — turn an unanswerable decision into a
  questionnaire for someone else.
- **wait-what** *(slash)* — stop; that last message did not land — re-pitch it.
- **writing-for-agents** *(adapted)* — style guide for any document an agent
  consumes (skills, `AGENTS.md`/`CLAUDE.md`, pointed-to docs).

### Setup / misc

- **git-guardrails-claude-code** — Claude Code hooks that block dangerous git
  commands.
- **setup-pre-commit** — Husky pre-commit hooks with lint-staged, typecheck,
  tests.

Not vendored: upstream's `skills/in-progress/` (marked unstable) and its
course-tooling misc skills (`scaffold-exercises`, `migrate-to-shoehorn`).
Workspace-authored skills (`checkpoint`, `session-rollover`, `create-work-item`,
`decision-log`, `design-for-testability`, `doc-review`, `onboard-repo`,
`research-wave`, `rlm`, `jev`) live alongside these in `skills/` and are indexed in
`CONTEXT.md`.

## Addy Osmani lifecycle set

Pinned at `1be8e34` (2026-10-10). All model-invoked (two with a tightened
description through their patch, below); every skill carries a
"Common Rationalizations" table (the excuses an agent makes to skip a step,
each rebutted) and a "Red Flags" list. Several link to shared checklists with
`../../references/<file>.md`; those six files are vendored at the repo root
`references/` (see `references/README.md`) so the links resolve unchanged.
One of them, `orchestration-patterns.md`, describes Claude Code's subagent
mechanics only; on another runtime, use its own subagent or second-CLI path.
Where a skill names a pack skill we did not take, use ours:
`interview-me` → `grill-me`, `test-driven-development` → `tdd`,
`code-review-and-quality` (and `/review`) → `code-review`,
`debugging-and-error-recovery` → `diagnosing-bugs`,
`source-driven-development` → `research`, `incremental-implementation` →
`implement`, `planning-and-task-breakdown` → `to-tickets`, `code-simplification` →
the always-on "Simplicity first" principle (with the optional
`karpathy-examples`, or Claude Code's `simplify`); the pack's
`/build auto` (implement a whole plan with subagents) → `implement-spec`.
`code-simplification` was vendored until L99 pruned it: it scored below no
skill in the skill-earns-its-place pilot (`work/backlog-sweep/pilot/results.md`).
Don't re-add it on a refresh.

- **security-and-hardening** — threat model, OWASP walk, input and auth
  handling, dependency audit, privacy; own `references/hardening-patterns.md`.
- **observability-and-instrumentation** — logs, metrics, traces and alerts
  added while the feature is written, not after.
- **shipping-and-launch** — pre-launch checklist, staged rollout, monitoring,
  rollback plan. Upstream's `/ship` command fans this out to three persona
  subagents; here, run the security, test and performance reviews yourself
  (in parallel where your runtime can).
- **ci-cd-and-automation** — pipelines, quality gates, deploy strategies.
- **deprecation-and-migration** — retire code and APIs safely
  (expand/contract, sunsets, zero-downtime schema changes).
- **performance-optimization** — measure, find the bottleneck, fix, measure
  again; own `references/optimization-patterns.md`. One example step names
  the Chrome DevTools MCP; use whatever profiler the stack has.
- **doubt-driven-development** *(patched)* — each non-trivial decision gets
  an adversarial, fresh-context review before it stands, with an optional
  second model through the Codex or Gemini CLI. The patch replaces the
  pointer to a Claude Code `agents/` persona roster with runtime-neutral
  wording and narrows the description to high-stakes work (upstream's fired
  on any confident output). Its `/review` means our `code-review`.
- **constraint-driven-development** *(patched)* — writes the project's
  quality bar into `CONSTRAINTS.md` and flags changes that quietly lower it
  (suppressions, skipped tests, lowered thresholds); own
  `references/floor-guard.md`. The patch points its "add a line" step and
  checklist at `CONTEXT.md` instead of the `AGENTS.md`/`CLAUDE.md` symlinks,
  and shortens the description to its real triggers. Its `/build`, `/test`,
  `/review`, `/ship` table names phases, not commands that exist here.

Not vendored from this pack: its slash commands (the skills trigger by
description; its `/plan` would clash with ours), the four persona agents,
the Claude Code hooks, the Node eval framework, and sixteen skills that
duplicate the core set or are web-domain specific (`frontend-ui-engineering`,
`browser-testing-with-devtools`; add those per project).

## pstack

Pinned at `978ca6e` (2026-10-10, the last commit touching `pstack/`). Upstream
marks every skill user-invoked and runs them through Cursor's model routing;
here they are adapted (frontmatter ours, body upstream's) and four carry a
small patch.

- **unslop** *(adapted)* — a numbered catalog of AI-prose tells to cut from
  writing. Model-invoked as a final pass on human-facing text (docs,
  READMEs, PR text, reports); upstream's "must always apply" fired on code
  and agent-facing text too, where it contradicts `writing-for-agents`.
- **technical-writing** *(adapted)* — a layered standard for human-facing
  docs, RFCs, READMEs and PR descriptions (Diátaxis, Google developer style,
  STE, Global English); the trigger no longer names a slash command or
  commit messages. `writing-for-agents` covers agent readers; this covers
  people.
- **benchmark-checklist** *(adapted, patched)* — seven questions that vet a
  performance number (limiter, tuning, limits, errors, repeatability,
  relevance, did the work happen) before you report or act on it. The patch
  points at `pr` and `diagnosing-bugs` instead of poteto-mode playbooks.
- **blast-radius** *(adapted, patched)* — what a change could break beyond
  the diff, and proof of the one fact that makes it safe by running real
  code. The patch drops the `how`/`arena` references: use the repo's own
  navigation, and a second model as in `doubt-driven-development`.
- **why** *(adapted, rewritten)* — traces the commits, PRs, tickets, docs and
  chat behind a piece of code into a cited answer graded by confidence, after
  first checking `docs/adr/` and `decisions.md`; `references/epistemics.md`
  is upstream's verbatim. A rewrite, not a copy, so the sync does not touch
  it; refresh by re-reading upstream's `pstack/skills/why/`.
- **create-verification-skill** *(adapted, patched, slash)* — generates a
  project-local `skills/verify-<app>/` skill that launches, drives and
  captures evidence from the real app the way a user would, with a feature
  map. User-invoked.
- **maintain-verification-skill** *(adapted, patched, slash)* — the upkeep
  pass for that skill: source check per feature, one live pass, at most one
  PR of proven corrections. Where the runtime has no subagents, it reads the
  feature files sequentially. User-invoked.

Not vendored from this pack: `poteto-mode` (the operating mode and its 23
playbooks: Cursor Custom Mode, named models, `/loop`, cloud workers, bundled
Bun scripts), `setup-pstack`, the 24 `principle-*` cards (inert without
poteto-mode; four contradict this workspace's "surgical changes" and "ask
when uncertain"), and the skills with an equivalent here — `tdd` and `teach`
(same names; ours stay), `bro` (`wait-what`), `reflect`/`correct` (`retro`),
`poteto-help` (`ask-matt`), `show-me-your-work` (`decision-log`), `recall`
(`handoff`), `figure-it-out` (`plans`/`wayfinder`), `interrogate`
(`code-review`), `how` (graphify, `onboard-repo`), `architect`
(`codebase-design`, `prototype`) — plus `arena`, `swarm`, `automate-me`,
`make-bot-ui`, `no-comments`, `ketchup` and `typescript-best-practices`.

## TypeSafe agent skill (vendored beside `jev`)

- **jev/typesafe-ai** *(pristine)* — TypeSafe's own agent skill for its
  System One models (Jev), vendored from
  [github.com/typesafe-ai/skills](https://github.com/typesafe-ai/skills)
  `skills/typesafe-ai/SKILL.md` at commit `65a39f3` (v0.5.7, 2026-09-12;
  re-checked 2026-09-27) into `skills/jev/typesafe-ai/` with its `LICENSE`.
  Not a standalone workspace skill: it is reached from the workspace's own
  `jev` skill (`skills/jev/SKILL.md`, which carries the CLI contract) for
  design guidance and live-docs pointers. Not covered by
  `scripts/sync-vendored-skills.sh` (different upstream); refresh by
  re-copying `SKILL.md` + `LICENSE` from the new commit and bumping the pin
  in the provenance comment and here. License: MIT, Copyright (c) 2026
  TypeSafe AI — the text is `skills/jev/typesafe-ai/LICENSE`; it has the
  same terms as the Matt Pocock license below with a different copyright
  holder.

## Upstream licenses

All three upstreams use the MIT License with the same permission text; only
the copyright line differs. Reproduced once, with every holder:

MIT License

Copyright (c) 2026 Matt Pocock (github.com/mattpocock/skills)
Copyright (c) 2025 Addy Osmani (github.com/addyosmani/agent-skills)
Copyright (c) 2026 Lauren Tan (github.com/cursor/plugins, pstack/)

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
