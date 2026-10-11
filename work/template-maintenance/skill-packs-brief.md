# Brief — integrate Addy Osmani's agent-skills and pstack

Session 24 dispatch brief for the orchestrator child. The report file is
`work/template-maintenance/skill-packs-report.md`.

## The user's request

"Analyze Addy Osmani's skills and pstack. We have already integrated Matt
Pocock's skills. See the differences between them, their benefits, and how
we can integrate them into this dev AI template. Then create backlog items
to work on the integration. Figure out the dependencies, then, respecting
those, work in parallel as much as possible. Use models from fable down,
depending on the task."

## Sources (verify on GitHub before relying on them)

- **Addy Osmani:** `github.com/addyosmani/agent-skills`. About 20 skills
  across the lifecycle (define, plan, build, verify, review, ship), plus
  slash commands, agent personas, and checklists. Check its license.
- **pstack:** Cursor's `pstack` plugin, written by poteto. The likely
  multi-agent port is `michael-denyer/pstack-claude`, but only an
  aggregator names it. Find the canonical upstream and its license, and
  say which repo you used and why.
- **Already integrated:** Matt Pocock's set (`mattpocock/skills`). See
  `skills/vendored-skills.md`, `scripts/sync-vendored-skills.sh`, and the
  workspace's own skills listed in `CONTEXT.md`.

Clone upstreams into the scratchpad or `/tmp/claude-*`, never into the repo.

## Phases

1. **Analyze** (parallel). Inventory each pack: every skill's purpose,
   triggers, and dependencies on its runtime or tooling (Cursor-only?
   Claude-only?). Also record license and maintenance activity.
2. **Compare and decide.** Map each skill against Matt Pocock's set and
   the workspace skills: duplicate, overlapping, or new capability. For
   each one, recommend adopt-vendored, adopt-adapted, fold-into-existing,
   or skip, with the reason. Write the result to
   `work/template-maintenance/skill-packs-analysis.md`. Make it a short,
   plain-language summary table first, detail after (see the user's
   preference below).
3. **Backlog.** Add one card per integration unit to
   `docs/template-workspace-backlog.html`, following its "Maintaining this
   backlog" rules: next free IDs, scorecard, "Last updated", and a log
   row. Grep the file; never load it whole. Put each card's dependencies
   in the card. Record the dependency graph and the waves in the analysis
   doc. Where it fits, a plan under `work/template-maintenance/plans/` via
   `scripts/plan.sh` and `skills/plans/SKILL.md` is welcome.
4. **Implement**, wave by wave, with independent cards in parallel.

## Hard rules

- **Licensing:** vendor only what the license permits. Carry provenance
  the same way the Matt Pocock set does: a pinned-commit comment, license
  text, and refresh through the sync script, or a sibling script.
- **Agent-agnostic (the user stressed this twice):** additions must work
  for Codex, Gemini, Copilot, and OpenCode, not just Claude Code. They go
  in `skills/<name>/SKILL.md`, with `.claude/commands/` shortcuts
  optional. Rewrite or drop anything that depends on a single runtime:
  Cursor rules, Claude-only hooks, plugin manifests, `Task`/subagent
  tool names. If a skill only works on one runtime, say so in its card
  and in the analysis. Don't ship it as if it were universal. Persona
  "agents" and slash commands also need a runtime-neutral form, such as a
  skill or a doc that any agent can read.
- **First-class:** document every addition for template downloaders. Wire
  it into `CONTEXT.md` (keep it lean), `docs/workspace-structure.md`, and
  `skills/vendored-skills.md` or a sibling doc.
- **Name collisions:** prefer the existing skill. Never silently shadow a
  workspace or Matt Pocock skill. Resolve each collision and record the
  call as a Tier-2 note in `work/template-maintenance/decisions.md`.
- **Restraint:** don't import the whole pack. Simplicity first. Skip what
  duplicates the existing set, and say why.
- **Shared files:** only the orchestrator edits the backlog HTML,
  `CONTEXT.md`, `skills/vendored-skills.md`, `docs/workspace-structure.md`,
  and `decisions.md`. Parallel workers touch only their own new
  directories or files, and report the wiring edits they need.
- **Verification:** the checks must pass: `scripts/run-checks.sh`, or
  whatever it runs, plus the `scripts/tests/` suites relevant to the
  change. Report only the commands you actually ran.
- **Git:** commit locally on `main`. Reference card IDs, add a `Decision:`
  trailer where a choice was made, and end with
  `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`. **Never push.**
  Before writing a shared file, re-check HEAD, because another session
  may commit concurrently.
- **Stop and report BLOCKED** if a license forbids vendoring, a decision
  needs the user's judgment and has no sensible default, or the upstream
  can't be identified.

## User preferences that apply

- Review docs in plain language. Lead with a one-page summary and a
  glossary, keep it self-contained, and avoid jargon.
- Parallelize independent tasks, and keep shared-file edits in one place.
- Integrations must be agent-agnostic and fully documented for
  downloaders.
