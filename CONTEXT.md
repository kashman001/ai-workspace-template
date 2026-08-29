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

<!-- TODO: The project's domain glossary — resolved terms and aliases to
avoid. Keep terms tight and project-specific; general programming concepts
don't belong. Skills like grill-with-docs and improve-codebase-architecture
read this section. -->

- **<term>** — <one-line definition; note aliases to avoid>

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
`docs/operational-knowledge.md` — read it before debugging those.

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

Vendor-neutral skills live under `skills/<name>/SKILL.md` — any runtime can read
them (Codex/Gemini/OpenCode via this file; Claude Code also gets slash-command
shortcuts under `.claude/commands/`). One line each below — **open the skill's
`SKILL.md` for the full workflow before acting on it**; that file carries the
details omitted here. Adding a team capability (script vs. skill vs. agent
profile vs. runbook, plus the two wiring steps): `docs/workspace-structure.md`
→ "Authoring a Team Capability". Skills tagged **(anyone)** are safe for
non-engineers to drive conversationally (see `docs/for-non-engineers.md`);
untagged skills assume an engineering operator.

- **checkpoint** — session-boundary wrap-up: reconcile backlog/memory/docs,
  write a hand-off doc, emit a catch-up prompt for the next session. On a
  context-budget WARN/STOP, `session-rollover` takes precedence (measurement
  wins). `/checkpoint [next-focus]`
- **session-rollover** — deliberate, pruned handoff to a fresh session when the
  context budget hits WARN/STOP, instead of letting automatic compaction decide
  what survives (see **Context Budget** below). `/session-rollover [reason]`
- **create-work-item** *(anyone)* — scaffold a `work/<project>/` directory
  (README + launcher + ledger) when starting multi-session work; not for
  one-shot tasks. `/create-work-item <name>`
- **decision-log** *(anyone)* — capture the *why* behind a decision per the
  three-tier scheme above. `/decision <what + why + rejected>` (or
  `/decision promote <note>`)
- **doc-review** *(anyone)* — multi-perspective review of a technical
  document: audience gate first, six independent reviewer subagents, findings
  synthesized into prioritized recommendations. `/doc-review <path>`
- **onboard-repo** — bring a repo into the workspace: registry entry, graphify
  index, committed repo-context docs. `/onboard-repo <repo-name> [repo-path]`
- **research-wave** — research several subjects in parallel, then verify each
  result with an independent fact-checker before the claims are published or
  presented. User-invoked only. `/research-wave <subjects>`
- **rlm** — answer a query over a context too large to read into chat
  (persistent Python REPL + cheap leaf LLM over slices; good for counting,
  per-item classification, whole-corpus summaries). `/rlm context=<path> query=<question>`
- **to-spec** *(anyone)* — synthesize the current conversation into an effort
  spec at `work/<effort>/spec.md`, per the spec conventions
  (`docs/agents/issue-tracker.md`). `/to-spec [effort]`
- **to-tickets** — break a plan/spec/conversation into tracer-bullet tickets
  with blocking edges under `work/<effort>/issues/`. `/to-tickets [source]`
- **triage** — move issues through the triage state machine: categorise,
  verify, write agent-ready briefs. `/triage [request]`
- **wayfinder** — plan work too big for one session as a map of decision
  tickets, resolved one per session. User-invoked only. `/wayfinder [map path or ticket]`
- **writing-for-agents** — style guide for any document an agent consumes;
  consult before writing or reworking anything under `skills/`. Model-invoked
  (no slash command).

**Vendored engineering set (Matt Pocock, MIT)** — the full curated skill set
from `github.com/mattpocock/skills` ships in `skills/` alongside the above:
`tdd`, `grill-with-docs`/`grill-me`/`grilling`, `diagnosing-bugs`,
`domain-modeling`, `codebase-design`, `implement`, `code-review`,
`improve-codebase-architecture`, `prototype`, `research`,
`resolving-merge-conflicts`, `wizard`, `ask-matt`, `handoff`, `teach`,
`to-questionnaire`, `wait-what`, `setup-matt-pocock-skills`,
`git-guardrails-claude-code`, `setup-pre-commit` (and the adapted
`to-spec`/`to-tickets`/`triage`/`wayfinder` above). One-liners, slash-command
map, refresh workflow (`scripts/sync-vendored-skills.sh`), and license:
`skills/vendored-skills.md`. Run `setup-matt-pocock-skills` once per repo
before the tracker-dependent ones.

## Service Access

External services are documented in `docs/service-access.md`. MCP setup is
documented in `docs/mcp-setup.md`. Credentials live in the OS keychain —
never in tracked files or `.env`.

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
   until verified.

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

Every always-on tool and doc taxes every session; bring capabilities in on
demand instead. Three layers (full detail + per-runtime commands:
`docs/mcp-setup.md`, `mcp-fragments/README.md`):

1. **CLI-first.** Capabilities enter as CLIs on `PATH` (`gh`, `graphify`,
   `yt-dlp`) — zero standing context, every runtime. MCP is the exception,
   for where it genuinely beats the CLI.
2. **Core vs. fragments.** `.mcp.json` carries only the core set (graphify);
   heavier servers live in `mcp-fragments/`, loaded per session
   (`claude --mcp-config mcp-fragments/<name>.json`; other runtimes per
   `docs/mcp-setup.md`).
3. **Asymmetric parent/child toolsets.** The parent stays lean and delegates:
   `.claude/agents/` profiles narrow a child (e.g. `repo-navigator`); a child
   carrying tools the parent lacks is a scoped worker
   (`claude -p "<task>" --mcp-config mcp-fragments/<name>.json`).

## Context Budget — Measure, Don't Guess

LLM quality degrades past ~150K context tokens (the "dumb zone") regardless of
advertised window size. You **cannot introspect your own usage** — the numbers
live in the API envelope, on disk; never estimate them. Thresholds are in
`context-budget.env` (checked in; raise in one place as models improve).

- At session start: `scripts/context-budget.sh register` (Claude Code and
  Copilot VS Code agent mode: the `SessionStart` hook already ran it
  mechanically — don't re-run; register manually only if hooks are disabled).
- At every work-unit boundary: `scripts/context-budget.sh record --label "<what just finished>"`.
- Act on the exit code: `1` (WARN, ≥120K) — wrap up the current unit, then ask
  the user whether to roll over (`session-rollover` skill; declined = write
  ahead to disk incrementally); `2` (STOP, ≥150K) — finish only the current
  atomic step and roll over immediately, no ask. All six runtimes
  (claude/codex/gemini/opencode/copilot CLI/Copilot VS Code agent mode) get
  the in-band push at these thresholds via their committed hook wiring
  (`docs/context-budget.md` → "Vendor hook deployments").
- Dispatching a long-running subagent: open a dispatch record and emit the
  rollover contract for its prompt in one step —
  `scripts/context-budget.sh dispatch-open --project <p> --task <slug>
  --report <path>`; close it at yield (`dispatch-close --status <S>`); at
  child WARN/STOP, roll (fresh `dispatch-open`), never resume
  (`docs/context-budget.md` → "Dispatching long-running children").

Relaunch of the successor session is governed by `ROLLOVER_RELAUNCH` in
`context-budget.env` via `scripts/launch-next-session.sh` (see
`docs/context-budget.md` → "Relaunch knobs"); a committed
`work/<proj>/context-budget.env` overrides it per work item. The successor
inherits the predecessor's launch options via `work/<proj>/.rollover-options`.

**`ROLLOVER_RELAUNCH=auto` is standing authorization to launch the successor —
do not ask, and do not stop to be told.** It is committed to disk precisely so
agent work continues across session boundaries without a human restarting it
each time. Needing the user's input is expressed by rolling over with
`--mode interactive`, so the successor re-poses the question on a fresh window;
it is never expressed by declining to launch, which burns the handoff and
strands the work. And before concluding you *cannot* launch, run
`scripts/launch-next-session.sh <project> --dry-run` — a believed blocker is not
a blocker until the dry-run confirms it. Details:
`skills/session-rollover/SKILL.md` step 6.

Full reference: `docs/context-budget.md`; rollover workflow:
`skills/session-rollover/SKILL.md`.

## graphify

This workspace ships [graphify](https://graphify.net) wiring (a knowledge-graph
tool: Gemini `BeforeTool` hook, OpenCode plugin), active only once a graph
exists at `graphify-out/` — per repo, never committed. Placement, multi-repo
setup, and removal if unused: `docs/recommended-tooling.md` §5.

Rules once `graphify-out/graph.json` exists:
- Answer codebase questions with `graphify query "<question>"` first (repo
  root); `graphify path "<A>" "<B>"` for relationships, `graphify explain
  "<concept>"` for focused concepts — each returns a scoped subgraph far
  smaller than raw grep output. Use `graphify-out/wiki/index.md` (if present)
  for broad navigation; read `graphify-out/GRAPH_REPORT.md` only for broad
  architecture review.
- After modifying code, run `graphify update .` (AST-only, no API cost).
  Committed ADRs and `Decision:`/`Refs:` commit trailers let the graph answer
  *why* (`code → commit → ADR → alternatives-rejected`), not just *what*.
