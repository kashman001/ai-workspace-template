<!--
File: docs/zoom-model.md
Purpose: The zoom-level model — how product knowledge is layered so each
         session loads only the pane it needs, and how work delegates
         across levels. Promoted from work/usage-scenarios/scenarios.md §1
         (2026-08-08); this is the committed, canonical statement.
See: docs/workspace-structure.md (the directory map these levels live in)
-->

# The Zoom Model

How this workspace layers knowledge about a product so that what an agent
loads at any moment fits a realistic slice of the context budget. Like a
map: earth view shows continents; street view shows houses. Top zoom = big
picture and top-level architecture; maximum zoom = a single source file.

Budget figures assume the ~150K usable window (`docs/context-budget.md`),
of which product knowledge can claim only a fraction — the rest goes to the
task conversation, tool results, and work-item state. Rule of thumb: **all
always-loaded product context ≤ ~10K tokens; any single zoom-in ≤ ~15K.**

## Zoom levels — what the product *is*

| Zoom | Scope | What you see at this level | Canonical artifacts | Budget share |
|---|---|---|---|---|
| **Z0 — Product** | The whole product | What it is, who it's for, top-level architecture (services and how they talk), how it's built/run/debugged, where everything lives | Root `CONTEXT.md` + `SPEC.md` + `docs/system-design.md`; repos registry as the index into Z1 | ~2–5K, always loaded — the only level with a standing claim on every session |
| **Z1 — Repo / service** | One repo | The service's purpose and boundaries, internal architecture, key flows, API surface, build/test/deploy specifics | `docs/repo-context/<repo>/` (code-structure, design, api) | ~5–15K, on demand when working in that repo; only its index line exists at Z0 |
| **Z2 — Subsystem / module** | One area within a repo | Module design: responsibilities, invariants, key types, seams, why it's shaped this way | Module docs where they exist; graphify community/`explain` output; module-scoped ADRs | ~5–10K per zoom-in; usually *generated on demand* (graphify) rather than pre-written |
| **Z3 — Source file** | A few files on one street | The code itself | Source files; targeted `Read`/`Grep` slices | Bounded per read; never resident — read, use, let it fall out of context |

**Variable depth.** The number of levels scales with the product: a simple
single-executable product may collapse to Z0+Z3; a very large one may need
an extra tier (product → domain → service → module → file). Z-levels are a
naming scheme, not a mandate — instantiate only the levels that carry real
structure; the rules below hold between whatever levels exist.

## Properties that make the stack work

- **Self-similarity.** Every level has the same shape: a short *identity*
  summary, a *map* of the level below, and *zoom-in pointers*. Z0's
  architecture overview names services; each Z1 doc names its modules; each
  Z2 view names its files. An agent navigates from earth to street without
  ever holding two full levels at once.
- **Summaries up, pointers down.** Level N carries its own detail plus one
  line per child — never child content. The repos registry is Z0's index of
  Z1; a code-structure doc is Z1's index of Z2/Z3.
- **Written vs. generated.** Z0–Z1 are cheap to keep written and current
  (they change slowly). Z2 goes stale fastest — prefer generating it on
  demand (graphify query/explain, `repo-navigator` agent) over maintaining
  prose. Z3 is never documented, only read.
- **The failure modes the model prevents:** *all levels open at once*
  (context accretion — loading three repos' full context docs to answer a
  Z0 question) and *wrong level open* (answering a Z2 design question from
  the Z0 one-liner in stale memory instead of zooming in).

## The second dimension: the operational hierarchy

Orthogonal to product-information zoom is the **operational hierarchy** —
not what the product *is*, but who is doing what to it right now. Work
lives at intersections of the two ("a session (O3) zooms into a module
(Z2)").

| Level | Scope | Question | Canonical artifacts | Discipline |
|---|---|---|---|---|
| **O0 — Team/product org** | Everyone on the product | Who works on this, with what shared services and non-negotiable tooling? | Workspace repo remote, shared registries (repos, services), the required-tooling manifest (`scripts/check-dependencies.sh` + `docs/recommended-tooling.md` → "Required for everyone") | Shared, committed; the only level all people see |
| **O1 — Person/machine** | One developer on one computer | What do *I* have configured here — secrets, optional tools, runtimes? | Untracked local settings, OS keychain, `*.example`→local copies | Never committed; discovered/repaired by check scripts + runbooks |
| **O2 — Work item** | One ongoing effort | What is this effort, what's decided, what's next? | `work/<project>/` (README, launcher, ledger, decisions) | Engaged deliberately; launcher read whole, ledger top block only; one primary session |
| **O3 — Session** | One agent conversation | What's in my context window; when do I roll over? | Session artifact, budget registry, `.active-session` lock | Measured never guessed; WARN/STOP → rollover |
| **O4 — Work unit** | One step in a session | What did this step change and why? | Commits + `Decision:` trailers, budget `record` entries, dispatch records | Recorded at every boundary; the grain of provenance |

**Context budget is spent across both dimensions**: a session's window
holds its O-level state (launcher, ledger top block) *plus* whatever
Z-level pane the task needs. Keep each side lean so the other fits.

## Agents per zoom level

Each zoom level gets an agent **profile**, not a standing agent — a
reusable definition of (a) what that level's agent preloads (its Z-pane),
(b) what tools it carries, and (c) what it returns upward (a bounded
summary + pointers, never content dumps). Work at level N stays in a
level-N window; zoom-ins are delegated to a child instantiated from the
N+1 profile, and only its capped return re-enters the parent — "summaries
up, pointers down" extended from documents to computation.

| Level | Agent profile | Preloads | Returns upward |
|---|---|---|---|
| Z0 | Product orchestrator | CONTEXT.md + architecture overview + registries | Decisions, fan-out results |
| Z1 | Repo/service agent | That repo's context docs + its graphify graph | Findings as file:line refs + synthesis |
| Z2 | Module specialist | graphify explain/community output for the module | Design answers, invariants, seams |
| Z3 | Reader/editor | Nothing standing — targeted reads only | Diffs, verified facts |

The shipped `.claude/agents/repo-navigator` **is** the Z1 profile
(read-only tools, graph-first method, file:line returns); ADR-0002's
asymmetric parent/child toolsets is the same principle applied to tools.
Add profiles for other levels only when a product's size demands them.

**When to delegate vs. zoom in place:** delegation costs a hop (latency +
dispatch tokens), so *zoom in place when the working set fits your
remaining budget slice; delegate when it wouldn't, or when the child needs
tools or context you shouldn't carry.* Cross-cutting tasks (a feature
spanning services) run as a Z0 orchestrator fanning out per-repo Z1
agents — levels are panes, not territories.
