# Vendored Skills — Matt Pocock Engineering Set

The skills listed here are vendored from
[github.com/mattpocock/skills](https://github.com/mattpocock/skills) (MIT,
license text below) so they ship with this workspace — no per-user clone or
symlink setup required, and every runtime (Claude Code, Codex, Gemini,
OpenCode, Copilot) reads the same `skills/<name>/SKILL.md`. Each directory
also carries upstream's `agents/openai.yaml` metadata for OpenAI-runtime
compatibility.

Each vendored `SKILL.md` opens with a provenance comment pinning the upstream
commit. Refresh all of them with `scripts/sync-vendored-skills.sh` (needs a
local clone of the upstream repo; the script prints instructions if missing).
Two classes:

- **Pristine** — the whole directory is upstream content, unmodified. Keep it
  that way so refreshes stay a clean re-copy.
- **Adapted** — the `SKILL.md` frontmatter + provenance comment are
  workspace-specific (wired to this workspace's tracker/spec conventions);
  the body below the comment is pristine upstream content.

Skills marked *(slash)* have a Claude Code shortcut under `.claude/commands/`;
the rest are model-invoked (triggered by their `description`).

## Engineering

- **ask-matt** *(slash)* — router: ask which skill or flow fits your situation.
- **code-review** — review changes since a fixed point along Standards + Spec
  axes. ⚠ Name collides with Claude Code's built-in `/code-review` command
  and the `code-review` plugin; invoke via the Skill tool if ambiguous.
- **codebase-design** — shared vocabulary for designing deep modules.
- **diagnosing-bugs** — diagnosis loop for hard bugs and perf regressions.
- **domain-modeling** — build and sharpen the project's domain model
  (CONTEXT.md glossary, ADRs).
- **grill-with-docs** *(slash)* — grill a plan, creating ADRs/glossary as you go.
- **implement** *(slash)* — implement a piece of work from a spec or tickets.
- **improve-codebase-architecture** *(slash)* — find deepening opportunities,
  HTML report, grill through your pick.
- **prototype** — throwaway prototype to answer a design question.
- **research** — investigate a question against primary sources, capture as
  a Markdown file.
- **resolving-merge-conflicts** — resolve an in-progress merge/rebase conflict.
- **setup-matt-pocock-skills** *(slash)* — one-time per-repo config (issue
  tracker, triage labels, domain docs) the engineering skills consume.
- **tdd** — red-green-refactor, one vertical slice at a time.
- **to-spec** *(slash, adapted)* — conversation → spec at `work/<effort>/spec.md`.
- **to-tickets** *(slash, adapted)* — plan/spec → tracer-bullet tickets.
- **triage** *(slash, adapted)* — move issues through the triage state machine.
- **wayfinder** *(slash, adapted)* — plan work too big for one session as a
  map of decision tickets.
- **wizard** — generate an interactive bash wizard for human-only steps.

## Productivity

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

## Setup / misc

- **git-guardrails-claude-code** — Claude Code hooks that block dangerous git
  commands.
- **setup-pre-commit** — Husky pre-commit hooks with lint-staged, typecheck,
  tests.

Not vendored: upstream's `skills/in-progress/` (marked unstable) and its
course-tooling misc skills (`scaffold-exercises`, `migrate-to-shoehorn`).
Workspace-authored skills (`checkpoint`, `session-rollover`, `create-work-item`,
`decision-log`, `doc-review`, `onboard-repo`, `rlm`) live alongside these in
`skills/` and are indexed in `CONTEXT.md`.

## Upstream license

MIT License

Copyright (c) 2026 Matt Pocock

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
