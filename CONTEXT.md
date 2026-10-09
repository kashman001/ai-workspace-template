# <workspace-name> — Workspace Context

Master context file and front door for any agent session in this workspace.
Keep it concise (it loads into every conversation); link out for detail.

`CLAUDE.md`, `AGENTS.md`, and `GEMINI.md` are symlinks to this file, so
Claude Code, Codex, OpenCode, and Gemini all read the same context.
**Agents: edit `CONTEXT.md` itself, never a symlink path** — write tools
refuse to write through symlinks and the edit fails.

Humans: start at `README.md`; non-engineers: `docs/for-non-engineers.md`.

**Onboarding canary** — when a user asks you to *"report the workspace
canary"*, reply on one line: `WORKSPACE-CONTEXT-OK` followed by your runtime
name and the entrypoint file you read (e.g. `WORKSPACE-CONTEXT-OK — Codex via
AGENTS.md`). If you cannot see this instruction, you have not loaded the
workspace context. Live-check guide: `docs/agent-onboarding-check.md`.

> **This is a template.** Replace the `<…>` placeholders below for your
> project, prune sections you don't need, and delete this note. See
> `docs/workspace-structure.md` for the full rationale behind every
> directory and file.

## Workspace Purpose

<!-- TODO: One paragraph — what does this workspace coordinate? Is the
workspace root itself a product repo (single-repo), or a coordination layer
over repos cloned under repos/ (multi-repo)? If there's a product spec,
point to it (e.g. SPEC.md). -->

<one-paragraph description of the project this workspace coordinates>

## Language

The domain glossary — project terms, aliases to avoid, and the plan
vocabulary (work item, node, wave, frontier, …) — lives in `GLOSSARY.md`.
Read it before naming a domain concept; skills that resolve a term update it.

## Repository Layout

- `repos/` holds cloned product repos (if multi-repo); `docs/repos-registry.md`
  is the canonical registry.
- For a single-repo workspace, product code lives at the workspace root and
  `repos/` stays empty.

## Covered Repos

Per-repo context docs live under `docs/repo-context/` — see
`docs/repo-context/README.md` for the index. Onboard a repo with
`/onboard-repo <repo-name>` to generate its `code-structure.md`, `design.md`,
and `api.md`. None are documented yet.

## Workspace Structure

See `docs/workspace-structure.md` for the authoritative map of how this
workspace is organized (directories, entrypoints, conventions);
`docs/README.md` indexes every doc by need. How product knowledge is
layered — and what to load for a task — is `docs/zoom-model.md`.
Hard-won operational gotchas (build/CI/shell traps) are recorded in
`docs/operational-knowledge.md` — read it before debugging those. A keyword
grep misses when the words differ: before concluding a gotcha or decision
isn't recorded, scan the file's `## ` headings and judge them by meaning.

## Work Directory Convention

Active project work lives under `work/<project-name>/`. Persist
any intermediate state that must survive context compaction to a file in
the relevant work directory.

Each work directory follows a standard backbone: a durable `README.md`, a
forward **launcher** (`next-session.md` — what to do next, REPLACED each
rollover) and an append-only **ledger** (`handoff.md` — what happened, newest
block on top, archived to `handoff-archive.md` when it grows). The launcher/
ledger split is the main defense against context-token accretion across
sessions. Full roles + write discipline: `docs/work-directory-conventions.md`.
Scaffold a new one with `skills/create-work-item/SKILL.md` (Claude Code:
**`/create-work-item <name>`**).

## Plans

A **plan** is a dependency graph of work for one work item: one markdown file
per node under `work/<item>/plans/NN-<slug>/`, grouped into waves, each wave
closed by a reconcile node. `scripts/plan.sh` derives status, frontier, and
lint from the node files and owns every state write; the `plans` skill decides
what the nodes are. Use one when a work item outgrows a ticket list — several
sessions, parallel subagents, or steps a person must approve. Where am I:
`scripts/plan.sh status --project <item>`. Reference (format, verbs, tiers,
replans): `docs/plans.md`; procedures: `skills/plans/SKILL.md` (Claude Code:
`/plan`).

## Decision Records

Capture the **why** behind decisions — code records *what* exists, not *how it
got there*; intent is unrecoverable after the fact unless written down as you
decide. Three tiers by permanence, captured cheap and promoted upward:

- **Tier 1 — commit trailer** (always; no-git workspaces: N/A — capture starts at
  Tier 2, dated): a one-line `Decision:` reason in the commit body.
- **Tier 2 — decision note** (for any choice with a rejected alternative): appended to
  `work/<project-name>/decisions.md`. Ephemeral, per-project, cheap — the wide net.
- **Tier 3 — ADR** (only for lasting-weight decisions): a committed record under `docs/adr/`,
  **promoted** from a Tier-2 note (on demand, or at `checkpoint`). See `docs/adr/README.md`.

Driven by the **decision-log** skill (`skills/decision-log/SKILL.md`); Claude Code shortcut
**`/decision <what + why + rejected alternative>`** (or `/decision promote <note>`).

## Workspace Skills

Vendor-neutral skills live under `skills/<name>/SKILL.md`; any runtime can
read them, and Claude Code also gets `/` shortcuts from `.claude/commands/`.
**Open a skill's `SKILL.md` before acting on it** — the one-liners below are
for picking a skill, not for running it. *(anyone)* marks skills safe for
non-engineers to drive (`docs/for-non-engineers.md`). Adding a capability:
`docs/workspace-structure.md` → "Authoring a Team Capability".

- **checkpoint** — session-boundary wrap-up and catch-up prompt (the stop door). `/checkpoint`
- **session-rollover** — pruned handoff to a fresh session at budget WARN/STOP; takes precedence over checkpoint then. `/session-rollover`
- **create-work-item** *(anyone)* — scaffold `work/<project>/` for multi-session work. `/create-work-item <name>`
- **decision-log** *(anyone)* — record the *why* per the tiers above. `/decision`
- **design-for-testability** — advisory: how will we test this, how does it fail. `/design-for-testability`
- **doc-review** *(anyone)* — six-reviewer critique of a document. `/doc-review <path>`
- **onboard-repo** — registry entry, graphify index, repo-context docs. `/onboard-repo <repo>`
- **plans** — create, reconcile, or replan a work item's plan. `/plan`
- **research-wave** — parallel research, each result fact-checked; user-invoked only. `/research-wave`
- **rlm** — answer a query over a context too large to read into chat. `/rlm`
- **to-spec** *(anyone)* / **to-tickets** — conversation → spec / tickets under `work/<effort>/`. `/to-spec`, `/to-tickets`
- **triage** — move issues through the triage state machine. `/triage`
- **wayfinder** — plan too-big work as decision tickets, one per session; user-invoked only. `/wayfinder`
- **writing-for-agents** — style guide; consult before editing anything under `skills/`.

**Vendored engineering set** (Matt Pocock, MIT) — `tdd`, `grill-with-docs`,
`diagnosing-bugs`, `implement`, `code-review` and the rest also ship in
`skills/`; one-liners, slash map, refresh, and license:
`skills/vendored-skills.md`. Run `setup-matt-pocock-skills` once per repo
before the tracker-dependent ones.

## Service Access

External services: `docs/service-access.md`; MCP setup: `docs/mcp-setup.md`.
Credentials live in the OS keychain — never in tracked files or `.env`. The
`gh` CLI login covers every GitHub repo; the one exception (a machine with two
GitHub identities) is `docs/service-access.md` → "GitHub — repo-scoped access".

- **Jev (typed questions).** Closed options, many items, a safe fallback for
  low confidence → `scripts/jev.sh` (`skills/jev/SKILL.md`). Never for prose
  or extraction. No key (`scripts/jev.sh --check` exits 3) → do it the
  current way.

## First-run Setup

Agents bringing this workspace up on a machine: run the `scripts/check-*.sh`
checks, then follow the matching runbook in `docs/runbooks/` for whatever's
missing — `check-dependencies.sh` → `docs/runbooks/dependencies.md`,
`check-service-access.sh` → `docs/runbooks/authentication.md`. The checks are
verify-only; the runbooks are the sanctioned setup steps (per OS).

## Recommended Tooling

The external agent toolchain this workflow assumes (status line, superpowers
plugin, Matt Pocock engineering skills, Karpathy principles, graphify) is
documented in `docs/recommended-tooling.md` — global/per-user setup plus the
per-repo steps for Matt Pocock config and graphify graphs. The toolchain
items are optional; the same doc also carries the "Required for everyone"
manifest (git, gh, jq, hook wiring).

## Template Backlog

> Only relevant while working **on this template repo itself** — delete this
> section when you adapt the workspace for a real project.

`docs/template-workspace-backlog.html` is the living backlog for this template;
settled cards move to `docs/template-workspace-backlog-archive.html`.
**When you fix, change, or discover a template issue, update the backlog** —
resolve with a `Fixed:` note (card moves to the archive) or append a new
finding, per its "Maintaining this backlog" section (ID/status/scorecard).
Edit both files with targeted reads (grep the ID); never load them whole.
Work pulled from other sessions/clones counts too: when the delivering commit
lacks the backlog update, add it while incorporating the change.

## Agent Coding Principles

Behavioral guidance that reduces common AI coding mistakes:

1. **Think before coding.** Before answering, say what you'd need to know to
   answer well and name any assumptions you'd otherwise make silently; ask when
   uncertain; surface tradeoffs instead of quietly picking. For trivial changes
   (a typo, an obvious one-liner), use judgement rather than full ceremony.
2. **Simplicity first.** Minimum code that solves the problem. No
   speculative features, no abstractions for single-use code.
3. **Surgical changes.** Touch only what's required. Don't refactor
   adjacent code or "improve" formatting outside the task scope.
4. **Goal-driven execution.** Define verifiable success criteria; loop
   until verified. Report only the commands you actually ran; pending is
   pending and a skip is a skip, never a pass. A new check counts only once
   seen to fail on a bad case.

## Agent Context Discipline

Rules for keeping the LLM context window healthy across long sessions:

1. **Disk is the source of truth.** Always re-read files before asserting
   facts about them; conversation memory may be compacted.
2. **Demand-load, don't pre-load.** Skills list reads for orientation but
   load files only when the workflow reaches a step that needs them.
3. **Use targeted reads.** `Grep` for specific lines or `Read` with
   `offset`/`limit` rather than full file reads when checking a single
   fact.
4. **Persist intermediate state to disk.** Anything that must survive
   compaction belongs in a file under `work/`, not in conversation memory.
5. **Persist project state in `work/`, not agent-specific stores.** Memory
   systems are for personal preferences, not shared project context.
6. **Sub-agent summaries are hints, not facts.** Verify on disk.

## Tool & Context Loading — Lean by Default

Every always-on tool and doc taxes every session; load capabilities on demand.
**CLI-first**: a CLI on `PATH` (`gh`, `graphify`) beats an MCP server.
`.mcp.json` carries only the core set; heavier servers load per session from
`mcp-fragments/`; tool-heavy work goes to a narrowed child (`.claude/agents/`).
Detail and per-runtime commands: `docs/mcp-setup.md`, `mcp-fragments/README.md`.

Keep this file and the `MEMORY.md` index free of dates, status, and counters
— volatile state goes in launchers and ledgers (`docs/context-budget.md` →
"Cache the prefix, vary the tail").

## Context Budget — Measure, Don't Guess

LLM quality degrades past ~150K context tokens regardless of advertised window
size. You **cannot introspect your own usage** — the numbers live on disk;
never estimate them. Thresholds are in `context-budget.env`.

- Session start: `scripts/context-budget.sh register` (Claude Code and Copilot
  VS Code: the `SessionStart` hook already ran it — register by hand only if
  hooks are disabled).
- Every work-unit boundary: `scripts/context-budget.sh record --label "<what just finished>"`,
  then act on the exit code. `1` (WARN, ≥120K) — wrap up the unit, then ask the
  user whether to roll over (`session-rollover`; declined = write ahead to disk).
  `2` (STOP, ≥150K) — finish only the current atomic step and roll over
  immediately, no ask.
- Long-running subagent: open a dispatch record first —
  `docs/context-budget.md` → "Dispatching long-running children".

**`ROLLOVER_RELAUNCH=auto` (in `context-budget.env`, or a work item's own
copy) is standing authorization to launch the successor — do not ask, and do
not stop to be told.** Needing the user's input is expressed by rolling over
with `--loop-mode interactive`, never by declining to launch. Before
concluding you *cannot* launch, run
`scripts/launch-next-session.sh <project> --dry-run`. Details:
`skills/session-rollover/SKILL.md` step 6.

Sessions end via `session-rollover` (continue) or `checkpoint` (stop) — see
"How a session ends: two doors" in `docs/work-directory-conventions.md`. Full
reference: `docs/context-budget.md`.

## graphify

Optional knowledge-graph tool; setup, placement, and removal:
`docs/recommended-tooling.md` §5. Once `graphify-out/graph.json` exists,
answer codebase questions with `graphify query "<question>"` first
(`graphify path` / `graphify explain` for relationships and concepts) before
raw grep, and run `graphify update .` after modifying code.
