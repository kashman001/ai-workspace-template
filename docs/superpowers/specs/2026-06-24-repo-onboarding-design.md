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
   parts; contains no code reasoning. It prints a `Status:` line the skill parses
   (it does **not** branch on exit code — see below).

### Component: `scripts/onboard-repo.sh`

**Input.** `onboard-repo.sh <repo-name> [repo-path]` — `repo-name` is the registry
key and `repo-context/<repo-name>/` folder name (required); `repo-path` defaults to
the workspace root for a single-repo workspace, else `repos/<repo-name>/`. The
`/onboard-repo` Claude command and the skill pass the same `<repo-name>` through.

Responsibilities (each idempotent — safe to re-run):
- **Scaffold the registry entry** — append a templated block to
  `docs/repos-registry.md` only if no `## <repo-name>` heading exists yet. The
  presence test matches the heading **prefix** so it also detects the
  `## <repo-name> (primary)` single-repo form (avoids double-append on re-run).
  Fields are filled from args where given, else left as `<placeholders>`.
- **Wire the graphify MCP server** — ensure the local MCP config(s) exist from the
  examples (the examples themselves ship the `graphify` server entry; see below).
- **Attempt the graphify build** — if the `graphify` CLI is installed, build the
  graph for `repo-path`; treat `<repo-path>/graphify-out/graph.json` existing as
  success.
- **Stamp the doc templates** — create `docs/repo-context/<repo-name>/` and copy
  the three templates (`code-structure.md`, `design.md`, `api.md`) from
  `docs/repo-context/_templates/` if not already present (never clobber existing).
- **Signal graphify availability via a `Status:` stdout line** (e.g.
  `Status: graphify=live` or `Status: graphify=fallback`) and **always `exit 0`**
  unless a required precondition (missing `repo-name` arg) fails. This matches
  `check-service-access.sh`, which `exit 0`s even when degraded and signals via a
  printed `Status:` line — a graphify-absent onboarding is *degraded, not broken*,
  so reserving non-zero for it would contradict the sibling scripts' semantics.

Per-OS handling follows the existing `scripts/check-*.sh` conventions
(`uname -s` → `Darwin`/`Linux`/`MINGW*`); required vs optional tool handling
mirrors `check-dependencies.sh`.

### Component: `skills/onboard-repo/SKILL.md`

Matches the `checkpoint/SKILL.md` format exactly: YAML frontmatter (`name`,
`description`), `# onboard-repo`, a vendor-neutral note pointing at
`.claude/commands/onboard-repo.md`, then `## When to use`, `## Prerequisites`
(graphify optional; auth runbook; a known `<repo-name>`), `## Steps`, `## Outputs`.

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
8. **Flag for human review** — `design.md` and `api.md` are *agent-asserted* (the
   agent's reading of the code, not mechanically extracted). The skill ends by
   telling the user these two docs must be reviewed in the PR/commit diff before
   they're trusted. `code-structure.md` is closer to mechanical (dir map + graphify
   output) but still gets the same diff review.

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

**Verified invocation** (`graphify-mcp --help`, package `graphifyy v0.8.38`): it
serves a graph over MCP, **stdio transport by default**, defaulting to
`graphify-out/graph.json`. It accepts an optional `graph_path` positional (or
`--path`) — this is how a **multi-repo** workspace points the server at a specific
repo's `repos/<name>/graphify-out/graph.json`. So the MCP entry is a stdio server:
`command: "graphify-mcp"`, `args: []` for single-repo (default graph), or
`args: ["repos/<name>/graphify-out/graph.json"]` per repo for multi-repo.

- Add the `graphify` stdio server entry to **both** example configs, respecting
  their **different schemas** (verified): `.mcp.json.example` nests servers under
  **`mcpServers`**; `.vscode/mcp.json.example` nests them under **`servers`** and
  uses `//` line comments. A naive "same entry in both" produces an invalid VS
  Code config — the plan must spell out the per-file key.
- **v1 scope:** wire only `.mcp.json.example` (Claude Code / generic) and
  `.vscode/mcp.json.example`. For Codex (TOML) / Gemini / OpenCode, *document* the
  graphify MCP server in `docs/mcp-setup.md` as an optional addition rather than
  shipping it pre-wired — those runtimes already have the graphify **hooks** as
  their query path, and `mcp-setup.md` already carries per-version "verify" caveats
  we don't want to multiply. **Keep** the existing Gemini `BeforeTool` hook and
  OpenCode plugin untouched — additive, no existing wiring removed.
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

**Convention change — 2 docs → 3.** Today the per-repo convention is *two* docs.
The plan MUST update every place that hard-codes it, or the docs drift:
`docs/repo-context/README.md` (lines naming `code-structure.md` and `design.md`),
the `docs/repos-registry.md` "Covered by context docs" field, and `CONTEXT.md` →
Covered Repos. The README currently names a `prompt-library/` contract as "the
recommended way to keep output format consistent"; the shipped
`docs/repo-context/_templates/` **supersedes** that mechanism — update the README
to point at `_templates/` instead of `prompt-library/` (don't leave both).

### Doc templates (`docs/repo-context/_templates/`)

This dir does not exist yet; the plan creates it with three skeleton files (the
script copies them verbatim into each new repo folder). Each is a markdown skeleton
with a leading HTML-comment header (matching the template's existing doc style) and
`<placeholder>`/`TODO` sections the agent fills:

- **`code-structure.md`** — sections: *Directory map*, *Modules & responsibilities*,
  *Entrypoints*, *Key flows*, plus a footer note "graphify is the live source;
  regenerate on material change."
- **`design.md`** — sections: *Architecture overview*, *Components & boundaries*,
  *Data flow*, *Key decisions / trade-offs*, *Known constraints*.
- **`api.md`** — a *Repo type* line (service | library | CLI) followed by **all
  three** adaptive sections, each marked "fill if applicable, else delete":
  *Service endpoints* (routes, request/response, auth), *Library surface* (exported
  symbols + signatures), *CLI commands* (subcommands + flags).

**Why `code-structure.md` is always written (not graphify-only):** `graphify-out/`
is gitignored and machine-local, so a live-only index leaves a fresh clone (or a
machine without graphify built) with no structural reference, and `design.md`/
`api.md` would cite a source that isn't always present. The committed doc is
durable and shows drift in PR diffs; graphify adds speed, not the source of record.

## Data flow

```
onboard-repo.sh ──► registry entry + doc templates + graphify build attempt
        │
        ▼ (Status: graphify=live | graphify=fallback)
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
- `docs/recommended-tooling.md` + `docs/mcp-setup.md` — graphify MCP server setup
  (incl. the optional per-runtime notes for Codex/Gemini/OpenCode).
- `CONTEXT.md` — list the `onboard-repo` skill under Workspace Skills; update the
  Covered Repos description for the 3-doc trio.
- `docs/repo-context/README.md` — 2-doc → 3-doc trio; replace the `prompt-library/`
  contract reference with `_templates/`.
- `docs/repos-registry.md` — the four new fields **and** the "Covered by context
  docs" wording for the 3-doc trio.
- `docs/template-workspace-backlog.html` — a change-log row for the feature.

## Verification

- `scripts/onboard-repo.sh` runs idempotently (re-run is a no-op on existing
  artifacts: no duplicate `## <repo>` heading, no clobbered docs) and `exit 0`s
  with `Status: graphify=fallback` when graphify is absent.
- `docs/repo-context/_templates/` exists with the three skeletons; the script
  copies them into a new `repo-context/<repo>/` folder.
- Both example MCP configs stay valid JSON with the graphify entry under the
  **correct per-file key** (`mcpServers` vs `servers`); `graphify-mcp` resolves on
  a machine with `graphifyy` installed.
- **Extend `scripts/check-workspace-structure.sh`** to assert `_templates/` and its
  three skeletons exist (today it has no knowledge of `repo-context/` contents, so
  "still passes" would be vacuous) — then confirm it passes.
