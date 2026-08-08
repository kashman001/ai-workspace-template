# Usage Scenario Catalog — ai-workspace-template

Working catalog of external usage scenarios and critical internal scenarios
for the workspace template. Purpose: an **evaluation lens** — each scenario is
something the template must support well; the catalog maps each one to what
exists today, what the agent harnesses already give us, where docs should
carry it, and what test/eval coverage it has. Seed requirements:
`brief.md`. Gap analysis and recommendations: `gaps-and-coverage.md`.

Status: DRAFT (session 1). Sections marked ⏳ await ground-truth reports.

---

## 1. The zoom-level model (the map metaphor)

The organizing abstraction for **product information**: how knowledge about
the product is layered so that what an agent loads at each zoom level fits a
realistic slice of the context budget. Like a map: earth view shows
continents; street view shows houses. Top zoom = big picture and top-level
architecture; maximum zoom = a single source file. (Operational state —
work items, sessions, per-user machines — is a *separate* dimension, handled
by the scenario catalogs below; zoom levels are about what the product *is*,
not what's currently happening to it.)

Budget figures assume the workspace's ~150K usable window, of which product
knowledge can realistically claim only a fraction — the rest goes to the
task conversation, tool results, and work-item state. Rule of thumb: **all
always-loaded product context ≤ ~10K tokens; any single zoom-in ≤ ~15K.**

| Zoom | Scope | What you see at this level | Canonical artifacts | Realistic budget share |
|---|---|---|---|---|
| **Z0 — Product** | The whole product | What it is, who it's for, top-level architecture (services and how they talk), how it's built/run/debugged, where everything lives | Root `CONTEXT.md` + a root architecture overview; repos registry as the index into Z1 | ~2–5K tokens, always loaded — the only level with a standing claim on every session |
| **Z1 — Repo / service** | One repo of the product | The service's purpose and boundaries, its internal architecture, key flows, API surface, build/test/deploy specifics | `docs/repo-context/<repo>/` (code-structure, design, api); the repo's own entry doc | ~5–15K, loaded on demand when working in that repo; only its index line exists at Z0 |
| **Z2 — Subsystem / module** | One area within a repo | Module design: responsibilities, invariants, key types, seams, why it's shaped this way | Module-level docs where they exist; graphify community/`explain` output; ADRs scoped to the module | ~5–10K per zoom-in; usually *generated on demand* (graphify query) rather than pre-written |
| **Z3 — Source file** | A few files on one street | The code itself | Source files; targeted `Read`/`Grep` slices, not whole-file loads | Bounded per read; never resident — read, use, let it fall out of context |

### 1b. The second dimension: the operational hierarchy

Orthogonal to product-information zoom is the **operational hierarchy** —
not what the product *is*, but who is doing what to it right now. Scenarios
live at intersections of the two dimensions (e.g. "a session (O3) zooms
into a module (Z2)").

| Level | Scope | Question | Canonical artifacts | Discipline |
|---|---|---|---|---|
| **O0 — Team/product org** | Everyone on the product | Who works on this, with what shared services and non-negotiable tooling? | Workspace repo remote, shared registries (repos, services), required-tooling manifest (missing today) | Shared, committed; the only level all people see |
| **O1 — Person/machine** | One developer on one computer | What do *I* have configured here — secrets, optional tools, runtimes? | Untracked local settings, OS keychain/local vault, `*.example`→local copies | Never committed; discovered/repaired by check scripts + runbooks |
| **O2 — Work item** | One ongoing effort | What is this effort, what's decided, what's next? | `work/<project>/` (README, launcher, ledger, decisions) | Engaged deliberately; launcher read whole, ledger top block only; one primary session |
| **O3 — Session** | One agent conversation | What's in my context window; when do I roll over? | Session artifact, budget registry, `.active-session` lock | Measured never guessed; WARN/STOP → rollover |
| **O4 — Work unit** | One step in a session | What did this step change and why? | Commits + `Decision:` trailers, budget `record` entries, dispatch records | Recorded at every boundary; the grain of provenance |

The same self-similarity holds here (each level: identity + state +
pointers down), and the two dimensions compose: **context budget is spent
across both** — a session's window holds its O-level state (launcher,
ledger top) *plus* whatever Z-level pane the task needs. Today the template
is strong at O2–O4 (that's the whole context-budget subsystem), thin at O1,
and absent at O0.

### 1c. Agents per zoom level (proposed principle)

User proposal, endorsed with one refinement: **each zoom level gets an agent
*profile*, not a standing agent** — a reusable definition of (a) what that
level's agent preloads (its Z-pane), (b) what tools it carries, and (c) what
it is allowed to return upward (a bounded summary + pointers, never content
dumps). Work at level N stays in a level-N window; zoom-ins are delegated
to a child instantiated from the N+1 profile, and only its capped return
re-enters the parent. This extends "summaries up, pointers down" from
documents to computation.

| Level | Agent profile | Preloads | Returns upward |
|---|---|---|---|
| Z0 | Product orchestrator | CONTEXT.md + architecture overview + registries | Decisions, fan-out results |
| Z1 | Repo/service agent | That repo's context docs + its graphify graph | Findings as file:line refs + synthesis |
| Z2 | Module specialist | graphify explain/community output for the module | Design answers, invariants, seams |
| Z3 | Reader/editor | Nothing standing — targeted reads only | Diffs, verified facts |

Evidence this works, already in the repo: `repo-navigator` (`.claude/agents/`)
*is* the Z1 profile — read-only tools, graph-first method, file:line returns;
the R2 dispatch contract's 15-line return cap is the "bounded return" rule;
ADR-0002's asymmetric parent/child toolsets is the same principle for tools.
What's missing: profiles for the other levels, and a stated rule for **when
to delegate vs. zoom in place** — delegation costs a hop (latency + dispatch
tokens), so: *zoom in place when the working set fits your remaining budget
slice; delegate when it wouldn't, or when the child needs tools/context you
shouldn't carry.* Cross-cutting tasks (a feature spanning services) run as a
Z0 orchestrator fanning out per-repo Z1 agents — levels are panes, not
territories; the O-dimension analogue is the primary session (O2/O3)
dispatching recorded children (O4).

Properties that make the Z-stack work:

- **Variable depth (user, 2026-08-08).** The number of levels scales with
  the product: a simple single-executable product may collapse to Z0+Z3
  (overview → files); a multi-service SaaS gets the full stack, and a very
  large one may need an extra tier (product → domain → service → module →
  file). Z-levels are a naming scheme, not a mandate — each product
  instantiates only the levels that carry real structure, and the
  "summaries up, pointers down" rule holds between whatever levels exist.
  Same for agent profiles (§1c): fewer levels = fewer profiles.

- **Self-similarity (recursion).** Every level has the same shape: a short
  *identity* summary, a *map* of the level below, and *zoom-in pointers*.
  Z0's architecture overview names services; each Z1 doc names its modules;
  each Z2 view names its files. An agent can navigate from earth to street
  without ever holding two full levels at once.
- **Summaries up, pointers down.** Level N carries its own detail plus one
  line per child — never child content. The repos registry is Z0's index of
  Z1; a code-structure doc is Z1's index of Z2/Z3.
- **Written vs. generated.** Z0–Z1 are cheap to keep written and current
  (they change slowly). Z2 goes stale fastest — prefer generating it on
  demand (graphify query/explain, repo-navigator agent) over maintaining
  prose. Z3 is never documented, only read.
- **The failure modes** the model prevents: *all levels open at once*
  (context accretion — e.g. loading three repos' full context docs to answer
  a Z0 question), and *wrong level open* (answering a Z2 design question
  from the Z0 one-liner in stale memory instead of zooming in).

---

## 2. What harnesses provide vs. what the template adds

Requirement from brief: don't rebuild what Claude Code / Codex / Gemini /
OpenCode / Copilot already do. Current split, by capability area:

| Capability | Harness provides (today) | Template adds | Verdict |
|---|---|---|---|
| Entry context file | Each runtime reads its own file (CLAUDE.md / AGENTS.md / GEMINI.md); Claude Code adds a global `~/.claude/CLAUDE.md` layer and directory-scoped files | One canonical `CONTEXT.md` + symlinks so all runtimes read the same thing | Template's cheapest, highest-value trick; keep |
| Per-user local settings | Claude Code: `settings.local.json` (gitignored by convention), user-scope MCP config; Codex/Gemini: per-user home-dir config | Nothing systematic yet across runtimes (⏳ verify agent report) | Likely gap: no unified "personal layer" convention |
| Skills/commands | Claude Code skills/commands, plugins; other runtimes vary widely | Vendor-neutral `skills/<name>/SKILL.md` readable by any runtime, mirrored to `.claude/commands/` | Keep; this is the portability layer |
| MCP servers | All major runtimes support MCP; per-project + per-user registration | Core-vs-fragments split (`.mcp.json` lean core, `mcp-fragments/` opt-in per session) | Keep; addresses standing-context tax harnesses ignore |
| Context compaction | Auto-compaction (Claude Code ~200K trigger); summarization on overflow | **Measured** budget (`context-budget.sh`) + deliberate rollover *before* compaction decides what survives | Core differentiator; harness compaction is the fallback, not the plan |
| Session continuity | `--resume`/`--continue`, session pickers, transcript files | Launcher/ledger discipline, bootstrap prompts, session numbering, auto-relaunch chain | Template adds cross-runtime, on-disk continuity harnesses don't have |
| Multi-session concurrency | Multiple sessions can run; no coordination between them | `.active-session` lock, primary/auxiliary roles, session registry keyed to artifacts | Template-only; no harness coordinates sessions |
| Subagent management | Claude Code agents/Task tools; effort/model routing | Dispatch records + rollover contract for long-running children; per-child budget sweep | Template extends budget discipline into the agent tree |
| Memory | Claude Code auto-memory (per-user); other runtimes little/none | `work/` as shared, agent-neutral project state; memory reserved for personal prefs | Keep the split; it's explicitly stated in CONTEXT.md |
| Secrets | None meaningful (env vars at best) | OS keychain convention (⏳ verify depth); no shared-vault story | Likely gap vs. brief's shared-keyvault requirement |
| Provenance/decisions | Git history; nothing about *why* | 3-tier decision records (trailer → note → ADR) wired into graphify | Keep |
| Codebase navigation | Grep/glob/read; some indexing (IDE) | graphify knowledge graph + repo-navigator agent profile | Keep as optional layer |

Working principle for the catalog: **a scenario step is a template
responsibility only if no harness covers it portably.** Where one harness
covers it (e.g. Claude Code settings.local.json), the template's job is the
*convention* that makes the same idea work in all runtimes, not a mechanism.

---

## 3. External scenario catalog

Each entry: what happens, who acts, where it sits in the two dimensions
(Z = product-information zoom, O = operational level), current support
(✅ solid / ◐ partial / ❌ absent), and the one-line verdict. Evidence and
pointers: `ground-truth.md`. E1–E16 is the evaluation checklist: a template
change is good if it moves some scenario toward ✅ without dragging another
back.

### Lifecycle: getting a product onto the template

**E1 — Instantiate a product workspace** (O0 · Z0) ◐
Human takes the template (GitHub "use this template", clone, or agent
scaffold per bootstrap instructions) and makes a concrete workspace: run
`setup.sh`, fill placeholders, wire symlinks. *Choice point the docs leave
implicit: workspace stays strictly local (git init, no remote) vs. becomes
a repo.* Today: bootstrap path is solid; the local-vs-remote fork is
undocumented and the docs contradict each other across it (template-usage
says `rm -rf .git && git init`; workspace-setup assumes `git clone <url>`).

**E2 — Publish the workspace as a shared team repo** (O0 · Z0) ❌
Create remote, push, set branch/PR policy *for the workspace repo itself*,
define merge expectations for `work/` files and ADR numbering, decide
public/private. Today: never described anywhere; `work/` is committed (which
only makes sense with a remote) yet no doc addresses the team as a unit.

**E3 — Onboard a product** (O0 · Z0→Z1) ❌→◐
Populate the product level: what the product is, top-level architecture
(which repos/services own what), how it's built/run/debugged, service
registry, repo registry with tiers. Today the weakest onboarding: no skill
or check exists; `SPEC.md` is a 5-line stub, `docs/system-design.md` a
15-line TODO; the S0 precondition interview captures the facts but nothing
turns them into Z0 docs. **This is the scenario the zoom model most needs.**

**E4 — Onboard a repo/service** (O0 · Z1) ✅
`/onboard-repo`: registry entry, graphify index, three repo-context docs,
freshness check, refresh path. Strongest flow in the template. Minor gap:
step-7 discoverability wiring (registry "covered" field, indexes) is
unverified by any check.

**E5 — Onboard a new person/machine** (O1) ◐
Clone → `check-dependencies` → `setup.sh` → `check-service-access` →
`check-workspace-structure`, runbooks fix what checks flag. Pattern is
good but single-user in shape ("you on your new machine", never "second
person joining"); the whole global layer (agent CLIs, MCP registration,
hooks wiring, Copilot trustedFolders) is manual with no runbook; only 2
runbooks exist; Claude Code hooks are never wired by any script; Windows
weakest.

### Personal layer: settings, secrets, tooling

**E6 — Configure the personal layer** (O1) ◐
Each developer picks their optional skills/tools/MCP servers on top of a
shared baseline. Today: gitignore-and-copy (`*.example` → local) works for
Claude Code/VS Code but is uneven — OpenCode has no local layer (enabling a
server dirties a tracked file), Codex/Gemini push per-user MCP to global
home config (always-on for every project), `.mcp.json` is gitignored so
even the *shared core* can't be enforced. No layering/merge of shared
baseline + personal overrides.

**E7 — Declare non-negotiable vs. optional tooling** (O0→O1) ❌
Product declares required-for-everyone tools/skills/MCP/services; checks
enforce them; the rest is per-user choice. Today: the only hard requirement
anywhere is `req git`+`req gh` in check-dependencies.sh (binaries only,
workspace-global); recommended-tooling.md says "everything optional"; no
manifest, no per-product or per-service required marking,
check-service-access always exits 0.

**E8 — Set up service access & secrets** (O1, shared services O0) ◐
Personal secrets: OS keychain + registry + verify-only runbooks — sound,
but macOS-detailed only, and today holds exactly one credential (gh).
Shared-service secrets (team keyvault, shared vs. personal credentials,
secret bootstrap for a new member, rotation coordination): **entirely
absent** — no team-vault concept exists in the repo.

### The working loop

**E9 — Start a work item** (O2) ✅
`/create-work-item`: README + launcher + ledger per conventions doc.
Solid; this session used it.

**E10 — The feature loop** (O2–O4 · Z1–Z3) ✅/◐
Verifiable goal → red/green/refactor → review → `graphify update` →
persist state to `work/` → `/decision` for the why. Well documented, but
3 of 4 upstream skills it names (brainstorming, to-spec, to-tickets) are
external optional tooling — the loop's doc assumes tools the template
doesn't guarantee (ties to E7).

**E11 — Checkpoint & resume across sessions** (O2/O3) ✅
`/checkpoint` reconciles backlog/memory/docs, writes handoff, emits
catch-up prompt. Rollover takes precedence on WARN/STOP (correctly stated
in CONTEXT.md; missing from the usage-scenarios doc).

**E12 — Finish a branch / integrate** (O2 · Z1) ✅
Verification-before-completion → integration path → PR → merge → graph
update. Product-repo focused; fine.

**E13 — Plan bigger-than-one-session work** (O2) ✅
Wayfinder map + decision tickets, one per session. Documented, vendored,
user-invoked.

### Knowledge access (the zoom dimension in action)

**E14 — Answer a product question at the right zoom level** (Z0–Z3) ◐
"How does auth work across services?" should resolve at Z0/Z1 docs +
graphify queries, zooming to Z2/Z3 only as needed; rlm for
bigger-than-context corpora; repo-navigator to keep the parent lean. The
*mechanisms* all exist; what's missing is the Z0 pane itself (system-design
stub, no architecture overview) and any stated zoom discipline connecting
the levels (§1 of this catalog is the proposal).

**E15 — Root-level product documentation** (Z0) ❌→◐
The brief requires root docs answering: what the product is, how it works,
how it's built, how to debug it. Today: placeholders exist (CONTEXT.md
Workspace Purpose, SPEC.md, system-design.md, operational-knowledge.md) but
product-level content has no owner, no generator, no check — nothing makes
these real during onboarding (E3's gap surfaces here).

### Concurrency

**E16 — One person, several concurrent work items/sessions** (O2/O3) ✅/◐
The multi-session model (session-keyed registry, per-item lock,
primary/auxiliary roles, worktree anchoring) directly supports this — the
template's deepest machinery. Three live races remain (WARN push swallowed
via busy child; worktree-move stales registry artifact → wrongful lock
sweep; launcher staleness when checkout lags remote).

**E17 — Multiple people on one product** (O0) ❌
Two+ people, each with their own machines, secrets, tool choices, work
items; shared visibility of who holds what. Today: no user identity in any
state (registry, lock, work/ paths); the lock is machine-local by design so
cross-machine arbitration is impossible; single-writer work/ files collide
on merge; ADR numbering collides. The operating model is documented as
"one developer" (ADR-0004). Everything multi-user is greenfield.

## 4. Internal scenario catalog ⏳

(To be filled from ground-truth report on context-budget machinery, rollover,
checkpoint, wayfinder, dispatch, locks, multi-runtime hooks.)

## 5. Scenario → docs → tests coverage matrix ⏳

(See `gaps-and-coverage.md` once drafted.)
