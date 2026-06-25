# Repo Onboarding — Design

**Date:** 2026-06-24
**Status:** Approved (brainstorm) — pending implementation plan
**Scope:** A new capability for the `ai-workspace-template` repo.

## Problem

Bringing a repo into the workspace is currently ad-hoc. The template already
ships the *destinations* for repo knowledge — `docs/repos-registry.md` (repo
identity) and `docs/repo-context/<repo>/` (per-repo `code-structure.md` +
`design.md`) — but nothing walks an agent through populating them, no API doc
slot exists, and graphify is wired only as a CLI + agent hooks (no MCP query
path). The result: repo knowledge isn't captured consistently, and agents have
no reliable, demand-loadable source of code structure / design / API for a repo.

## Goal

A repeatable workflow that onboards a repo: record its identity + auth, build a
queryable code index, and derive committed reference docs — so **AI agents and
developers can pull repo knowledge on demand**.

## Non-goals (YAGNI)

- No repo-type auto-detector in bash — the agent decides repo type while reasoning.
- No auto-refresh/CI for the derived docs — they are regenerated manually on
  material structural change (graphify is the live layer; see below).
- No onboarding of a real product repo as part of *this* change — that is *using*
  the template, not building it. Dogfooding is a separate, optional follow-up.

## Architecture

Two cooperating pieces, matching how the template already does workflows
(cf. the `checkpoint` skill + `scripts/check-*.sh`):

1. **`skills/onboard-repo/SKILL.md`** (cross-agent) + **`.claude/commands/onboard-repo.md`**
   shortcut exposing **`/onboard-repo`** in Claude Code. The skill drives the
   judgement-heavy steps (derive structure/design/API, wire discoverability).
2. **`scripts/onboard-repo.sh`** — thin, idempotent. Handles only the mechanical
   parts; contains no code reasoning. Its exit status tells the skill whether the
   graphify live path is available.

### Component: `scripts/onboard-repo.sh`

Responsibilities (each idempotent — safe to re-run):
- **Scaffold the registry entry** — append a templated `## <repo-name>` block to
  `docs/repos-registry.md` if absent (fields filled from flags/args where given,
  else left as `<placeholders>` for the agent/human to complete).
- **Wire the graphify MCP server** — ensure the local MCP config exists from the
  example (the example itself ships the `graphify` server entry; see below).
- **Attempt the graphify build** — if the `graphify` CLI is installed, build the
  graph for the target path; treat `graphify-out/graph.json` existing as success.
- **Stamp the doc templates** — create `docs/repo-context/<repo>/` and copy the
  three templates (`code-structure.md`, `design.md`, `api.md`) from
  `docs/repo-context/_templates/` if not already present.
- **Signal** graphify availability via exit code (e.g. `0` = graph built / live
  path available, non-zero-but-documented = fallback to manual scan). Never fail
  the whole onboarding just because graphify is unavailable.

Per-OS handling follows the existing `scripts/check-*.sh` conventions
(Darwin/Linux/MINGW); required vs optional tool handling mirrors
`check-dependencies.sh`.

### Component: `skills/onboard-repo/SKILL.md`

Ordered steps the agent follows (concise, reference artifacts by path):

1. **Record repo info** → registry entry (run the script, then fill fields).
2. **Verify host auth** — point at `docs/runbooks/authentication.md`; verify-only,
   no interactive login, no secrets written (consistent with M7 `check-service-access.sh`).
3. **Set up indexing** — run the script's graphify wire + build. If the graph
   built, the live MCP query path is available; otherwise note fallback.
4. **Write `code-structure.md`** — ALWAYS produced and committed. Use graphify
   queries when available, else a manual scan. High-level only (dir map, modules,
   entrypoints, responsibilities, key flows) — not line-level.
5. **Derive `design.md`** — architecture/design from the structure.
6. **Derive `api.md`** — adaptive public surface; the skill detects repo type
   (service → endpoints/contracts/auth; library → exported symbols; CLI →
   subcommands) and fills the matching section.
7. **Wire discoverability** — flip the registry's "Covered by context docs" to
   yes + link; add the repo to `docs/repo-context/README.md`'s index; note it
   under `CONTEXT.md` → Covered Repos.

### Repo-info record — new fields (`docs/repos-registry.md`)

Add to the per-repo template, alongside the existing Host / Clone URL / Default
branch / Visibility / Purpose / Network / Location / Tier:

- **Auth method** — how to authenticate to the host for this repo (e.g. "gh CLI",
  "SSH key X", "PAT in keychain") + a pointer to `docs/runbooks/authentication.md`.
- **Local vs hosted** — make the local-only case first-class: `Host: local`,
  `Clone URL: n/a`, `Location: <path>`.
- **Language / stack** — primary languages + frameworks.
- **Build / test / run commands** — the canonical entrypoint commands.

### Indexing — graphify MCP server + fallback

- Add a **`graphify` MCP server** entry (command `graphify-mcp`) to
  `.mcp.json.example` and `.vscode/mcp.json.example`. MCP-capable agents (Claude,
  Codex) query the graph as a tool. **Keep** the existing Gemini `BeforeTool`
  hook and OpenCode plugin — both query paths point at the same `graphify-out/`
  graph. This is additive; no existing wiring is removed.
- Document the MCP server in `docs/mcp-setup.md` and `docs/recommended-tooling.md`.
- **Fallback:** if graphify is absent, the build fails, or the language is
  unsupported, the skill produces the same committed docs via a manual scan. The
  three repo-context docs are the durable output in either case.

### Per-repo docs (`docs/repo-context/<repo>/`)

Three committed docs, generated from graphify queries when available else manual
scan, with shipped templates under `docs/repo-context/_templates/`:

- **`code-structure.md`** — always written. Durable, committed, reviewable
  snapshot of structure. graphify is the *live* query layer on top when present;
  this doc is the version of record that exists on every clone without a rebuild.
- **`design.md`** — architecture/design derived from the structure.
- **`api.md`** — adaptive public surface (service / library / CLI).

**Why `code-structure.md` is always written (not graphify-only):** `graphify-out/`
is gitignored and machine-local, so a live-only index leaves a fresh clone (or a
machine without graphify built) with no structural reference, and `design.md`/
`api.md` would cite a source that isn't always present. The committed doc is
durable and shows drift in PR diffs; graphify adds speed, not the source of record.

## Data flow

```
onboard-repo.sh ──► registry entry + doc templates + graphify build attempt
        │
        ▼ (exit status: graphify live? yes/no)
skill ──► code-structure.md ──► design.md
                   │
                   └──────────► api.md
        │
        ▼
discoverability: registry "covered" + repo-context/README index + CONTEXT.md
        │
        ▼
agents/devs pull on demand (graphify MCP live queries; committed docs always)
```

## Error / edge handling

- **graphify unavailable / build fails** — documented fallback to manual scan;
  onboarding still completes with committed docs. Never hard-fail on graphify.
- **Re-run on an already-onboarded repo** — script is idempotent: existing
  registry entry and docs are left in place (not clobbered); the agent updates
  content rather than the script overwriting.
- **Local-only repo (no remote)** — first-class via the registry fields; auth
  step is a no-op pointer.
- **Unsupported language for graphify** — same as unavailable: manual scan path.

## Discoverability ("pull in as needed")

No new indexing system — reuse what exists:
- `docs/repos-registry.md` → "Covered by context docs: yes" + links.
- `docs/repo-context/README.md` index lists the repo.
- `CONTEXT.md` → Covered Repos pointer.
- graphify MCP server for live queries.
- The demand-load discipline already in `CONTEXT.md` governs *when* agents read
  these (only when the task needs them) — keeping the context window healthy.

## Template docs to update

- `docs/workspace-structure.md` — the onboarding flow + the repo-context doc trio.
- `docs/recommended-tooling.md` + `docs/mcp-setup.md` — graphify MCP server setup.
- `CONTEXT.md` — list the `onboard-repo` skill under Workspace Skills.
- `docs/repo-context/README.md` — the doc trio + `_templates/`.
- `docs/template-workspace-backlog.html` — a change-log row for the feature.

## Verification

- `scripts/onboard-repo.sh` runs idempotently (re-run is a no-op on existing
  artifacts) and exits non-error when graphify is absent.
- `docs/repo-context/_templates/` renders the three docs into a new repo folder.
- The graphify MCP server entry parses in `.mcp.json.example`.
- `scripts/check-workspace-structure.sh` still passes.
