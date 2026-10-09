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
`scripts/check-drift.sh` warns once the oldest pinned commit is more than 60
days old; refresh then. Three classes:

- **Pristine** — the whole directory is upstream content, unmodified. Keep it
  that way so refreshes stay a clean re-copy.
- **Adapted** — the `SKILL.md` frontmatter + provenance comment are
  workspace-specific (wired to this workspace's tracker/spec conventions);
  the body below the comment is pristine upstream content.
- **Patched** — a pristine skill whose directory also holds a
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
the rest are model-invoked (triggered by their `description`).

## Engineering

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
`decision-log`, `design-for-testability`, `doc-review`, `onboard-repo`,
`research-wave`, `rlm`, `jev`) live alongside these in `skills/` and are indexed in
`CONTEXT.md`.

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

## Upstream license (Matt Pocock set)

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
