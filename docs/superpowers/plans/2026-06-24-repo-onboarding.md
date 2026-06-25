# Repo Onboarding Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a repeatable `onboard-repo` workflow to the workspace template — record a repo's identity/auth, wire a graphify MCP query path (with a manual-scan fallback), and produce committed, provenance-stamped `code-structure.md` / `design.md` / `api.md` docs that agents and developers pull on demand.

**Architecture:** A thin idempotent `scripts/onboard-repo.sh` does the mechanical work (registry entry, graphify wiring, doc-template stamping, `--refresh`); a cross-agent `skills/onboard-repo/SKILL.md` (+ `/onboard-repo` Claude command) drives the judgement-heavy derivation. Three doc templates live in `docs/repo-context/_templates/`. Drift is managed (not eliminated) via a provenance block on every doc plus a warn-only `scripts/check-repo-context.sh`.

**Tech Stack:** Bash (POSIX-ish, matching existing `scripts/check-*.sh`), Markdown docs, JSON/JSONC MCP config, graphify (`graphifyy` ≥ 0.8.38, ships `graphify` + `graphify-mcp`).

**Spec:** `docs/superpowers/specs/2026-06-24-repo-onboarding-design.md` (read it before starting).

> **Testing note:** this repo has no unit-test framework — the `scripts/check-*.sh` scripts ARE its verifiers. So "write a failing test" here means: run the script / grep for the artifact and observe it fail, implement, then re-run and observe it pass. Follow that red→green→commit rhythm.

---

## File Structure

**Created:**
- `docs/repo-context/_templates/code-structure.md` — structure snapshot skeleton (provenance + 4 sections).
- `docs/repo-context/_templates/design.md` — design/rationale skeleton (provenance + 5 sections).
- `docs/repo-context/_templates/api.md` — adaptive API skeleton (provenance + service/library/CLI sections).
- `scripts/onboard-repo.sh` — mechanical onboarding (registry, graphify wiring, doc stamping, `--refresh`).
- `scripts/check-repo-context.sh` — warn-only freshness check (recorded SHA vs HEAD).
- `skills/onboard-repo/SKILL.md` — cross-agent workflow.
- `.claude/commands/onboard-repo.md` — thin `/onboard-repo` wrapper.

**Modified:**
- `.mcp.json.example` — add `graphify` stdio server under `mcpServers`.
- `.vscode/mcp.json.example` — add `graphify` stdio server under `servers` (JSONC).
- `docs/repos-registry.md` — 4 new per-repo fields; "Covered by context docs" wording.
- `docs/repo-context/README.md` — 2-doc → 3-doc; replace `prompt-library/` with `_templates/`.
- `scripts/check-workspace-structure.sh` — assert `_templates/` + 3 skeletons exist.
- `CONTEXT.md` — list `onboard-repo` under Workspace Skills; Covered Repos wording.
- `docs/recommended-tooling.md` — graphify MCP server note.
- `docs/mcp-setup.md` — graphify MCP server (optional) subsection.
- `docs/template-workspace-backlog.html` — change-log row.

Order: templates → script → check scripts → MCP config → doc edits → skill → backlog. Each task is independently committable.

---

## Task 1: Doc templates (`docs/repo-context/_templates/`)

**Files:**
- Create: `docs/repo-context/_templates/code-structure.md`
- Create: `docs/repo-context/_templates/design.md`
- Create: `docs/repo-context/_templates/api.md`

- [ ] **Step 1: Verify the dir is absent (red)**

Run: `ls docs/repo-context/_templates/ 2>&1`
Expected: `No such file or directory`.

- [ ] **Step 2: Create `code-structure.md`**

```markdown
<!--
File: docs/repo-context/<repo>/code-structure.md
Purpose: Durable, committed snapshot of this repo's code structure. graphify is
the LIVE source for this content (query the graph first); this doc is the
no-graphify fallback and the version-of-record present on every clone.
Generated/refreshed by scripts/onboard-repo.sh (and `/onboard-repo <repo> --refresh`).
-->

# <repo> — Code Structure

> Generated: <YYYY-MM-DD> | Source commit: <sha> | Refresh: `/onboard-repo <repo> --refresh`

## Directory map
<!-- TODO: top-level directories and what each holds -->

## Modules & responsibilities
<!-- TODO: the main modules/packages and the one job each owns -->

## Entrypoints
<!-- TODO: how execution starts — main(), server bootstrap, CLI entry, jobs -->

## Key flows
<!-- TODO: 2–4 important end-to-end paths through the code -->

---
*graphify is the live source for structure; regenerate this snapshot on material change.*
```

- [ ] **Step 3: Create `design.md`**

```markdown
<!--
File: docs/repo-context/<repo>/design.md
Purpose: Architecture & design rationale derived from the code — the "why" that is
NOT recoverable from the AST/graphify. Keep graphify-derivable facts in
code-structure.md, not here, so this drifts only when intent changes.
Generated/refreshed by scripts/onboard-repo.sh (and `/onboard-repo <repo> --refresh`).
-->

# <repo> — Design & Architecture

> Generated: <YYYY-MM-DD> | Source commit: <sha> | Refresh: `/onboard-repo <repo> --refresh`

## Architecture overview
<!-- TODO: the shape of the system in a few sentences -->

## Components & boundaries
<!-- TODO: the units, their responsibilities, and the interfaces between them -->

## Data flow
<!-- TODO: how data moves through the system -->

## Key decisions / trade-offs
<!-- TODO: notable choices and why (the irreplaceable part) -->

## Known constraints
<!-- TODO: limits, assumptions, invariants not to break -->
```

- [ ] **Step 4: Create `api.md`**

```markdown
<!--
File: docs/repo-context/<repo>/api.md
Purpose: The repo's public surface. ADAPTIVE — fill the section(s) that match the
repo type and DELETE the rest.
Generated/refreshed by scripts/onboard-repo.sh (and `/onboard-repo <repo> --refresh`).
-->

# <repo> — API Surface

> Generated: <YYYY-MM-DD> | Source commit: <sha> | Refresh: `/onboard-repo <repo> --refresh`

**Repo type:** <service | library | CLI>  <!-- pick one; delete the inapplicable sections below -->

## Service endpoints
<!-- fill if applicable, else delete — routes, methods, request/response shapes, auth -->

## Library surface
<!-- fill if applicable, else delete — exported functions/classes/types + signatures -->

## CLI commands
<!-- fill if applicable, else delete — subcommands, flags, example invocations -->
```

- [ ] **Step 5: Verify all three exist (green)**

Run: `ls docs/repo-context/_templates/ && grep -l 'Source commit: <sha>' docs/repo-context/_templates/*.md`
Expected: all three files listed, and all three contain the provenance placeholder.

- [ ] **Step 6: Commit**

```bash
git add docs/repo-context/_templates/
git commit -m "feat(onboard): add repo-context doc templates with provenance blocks"
```

---

## Task 2: `scripts/onboard-repo.sh`

**Files:**
- Create: `scripts/onboard-repo.sh`

Depends on Task 1 (copies those templates).

- [ ] **Step 1: Verify the script is absent (red)**

Run: `scripts/onboard-repo.sh demo 2>&1 || echo "MISSING"`
Expected: `MISSING` (no such file).

- [ ] **Step 2: Write the script**

```bash
#!/usr/bin/env bash
# File: scripts/onboard-repo.sh
# Purpose: Thin, idempotent mechanical half of repo onboarding — scaffold the
#          registry entry, wire the graphify MCP server, stamp the repo-context
#          doc templates with provenance, and (on --refresh) update the graph.
#          Judgement-heavy derivation of the docs is done by the agent following
#          skills/onboard-repo/SKILL.md. Never fails onboarding just because
#          graphify is absent; signals availability via a Status: line.
# Usage:   scripts/onboard-repo.sh <repo-name> [repo-path]
#          scripts/onboard-repo.sh <repo-name> --refresh
# See: docs/superpowers/specs/2026-06-24-repo-onboarding-design.md
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

REPO="${1:-}"
if [ -z "$REPO" ]; then
  echo "usage: scripts/onboard-repo.sh <repo-name> [repo-path|--refresh]" >&2
  exit 2
fi

REFRESH=0
REPO_PATH=""
case "${2:-}" in
  --refresh) REFRESH=1 ;;
  "")        REPO_PATH="" ;;
  *)         REPO_PATH="$2" ;;
esac

# Default repo path: repos/<repo> for multi-repo, else workspace root (single-repo).
if [ -z "$REPO_PATH" ]; then
  if [ -d "repos/$REPO" ]; then REPO_PATH="repos/$REPO"; else REPO_PATH="."; fi
fi

TODAY="$(date +%Y-%m-%d)"
SHA="$(git -C "$REPO_PATH" rev-parse --short HEAD 2>/dev/null || echo unknown)"
CTX_DIR="docs/repo-context/$REPO"
graphify_status="fallback"

# Rewrite the "> Generated: ..." provenance line in a doc (fresh copy or --refresh).
set_provenance() {
  local prov="> Generated: $TODAY | Source commit: $SHA | Refresh: \`/onboard-repo $REPO --refresh\`"
  sed -i.bak -E "s@^> Generated:.*@$prov@" "$1" && rm -f "$1.bak"
}

add_registry_entry() {
  # Idempotency keyed on the heading PREFIX so it also matches "## <repo> (primary)".
  if grep -qiE "^##[[:space:]]+${REPO}([[:space:]]|\$)" docs/repos-registry.md; then
    echo "  registry: entry for $REPO already present — skipping"
    return
  fi
  cat >> docs/repos-registry.md <<EOF

## $REPO

- **Host**: <GitHub / GitLab / Bitbucket / local>
- **Clone URL**: \`<ssh-or-https-clone-url>\` (n/a for local)
- **Default branch**: \`main\`
- **Visibility**: <public / private>
- **Purpose**: <one line>
- **Auth method**: <gh CLI / SSH key X / PAT in keychain> — see docs/runbooks/authentication.md
- **Language / stack**: <languages + frameworks>
- **Build / test / run**: \`<build>\` / \`<test>\` / \`<run>\`
- **Network**: <none special / VPN required / SSH key X>
- **Location**: \`$REPO_PATH\`
- **Covered by context docs**: yes — \`docs/repo-context/$REPO/\` (code-structure.md, design.md, api.md)
- **Tier**: <primary | optional>
EOF
  echo "  registry: appended entry for $REPO"
}

wire_graphify_mcp() {
  # Ensure a local .mcp.json exists (carries the graphify server entry from the example).
  if [ ! -f .mcp.json ] && [ -f .mcp.json.example ]; then
    cp .mcp.json.example .mcp.json
    echo "  mcp: created .mcp.json from example (graphify server included)"
  fi
}

refresh_graph() {
  # AST-only, no API cost. Only meaningful if a graph already exists.
  if command -v graphify >/dev/null 2>&1 && [ -f "$REPO_PATH/graphify-out/graph.json" ]; then
    ( cd "$REPO_PATH" && graphify update . >/dev/null 2>&1 || true )
  fi
}

detect_graph() {
  [ -f "$REPO_PATH/graphify-out/graph.json" ] && graphify_status="live"
}

echo "Onboarding repo: $REPO  (path: $REPO_PATH, head: $SHA)"
wire_graphify_mcp

if [ "$REFRESH" = 1 ]; then
  if [ ! -d "$CTX_DIR" ]; then
    echo "  ✗ $CTX_DIR does not exist — run without --refresh first" >&2
    exit 2
  fi
  refresh_graph
  for f in code-structure.md design.md api.md; do
    [ -f "$CTX_DIR/$f" ] && set_provenance "$CTX_DIR/$f"
  done
  echo "  refreshed provenance (date=$TODAY sha=$SHA) and graph (if present)"
else
  add_registry_entry
  mkdir -p "$CTX_DIR"
  for f in code-structure.md design.md api.md; do
    if [ -f "$CTX_DIR/$f" ]; then
      echo "  docs: $CTX_DIR/$f exists — skipping (not clobbered)"
    else
      cp "docs/repo-context/_templates/$f" "$CTX_DIR/$f"
      sed -i.bak "s@<repo>@$REPO@g" "$CTX_DIR/$f" && rm -f "$CTX_DIR/$f.bak"
      set_provenance "$CTX_DIR/$f"
      echo "  docs: created $CTX_DIR/$f"
    fi
  done
fi

detect_graph
echo "Status: graphify=$graphify_status"
if [ "$graphify_status" != live ]; then
  echo "graphify graph not built — agents fall back to the committed docs; run /graphify in $REPO_PATH for live queries" >&2
fi
exit 0
```

- [ ] **Step 3: Make it executable**

Run: `chmod +x scripts/onboard-repo.sh`

- [ ] **Step 4: Verify a dry onboarding (green)**

Run:
```bash
scripts/onboard-repo.sh demo .
echo "exit=$?"
ls docs/repo-context/demo/
grep '^> Generated:' docs/repo-context/demo/code-structure.md
grep -A1 '^## demo' docs/repos-registry.md | head -3
```
Expected: prints `Status: graphify=fallback`, `exit=0`; the three docs exist; the provenance line shows a real date + short SHA (not `<sha>`); a `## demo` registry block was appended.

- [ ] **Step 5: Verify idempotency**

Run:
```bash
scripts/onboard-repo.sh demo .
grep -c '^## demo$' docs/repos-registry.md
```
Expected: re-run prints "already present — skipping" and "exists — skipping"; the count of `## demo` headings is exactly `1` (no double-append).

- [ ] **Step 6: Verify `--refresh` re-stamps**

Run:
```bash
scripts/onboard-repo.sh demo --refresh
grep '^> Generated:' docs/repo-context/demo/design.md
```
Expected: exit 0; the provenance line is present with today's date.

- [ ] **Step 7: Remove the scratch artifacts**

Run:
```bash
rm -rf docs/repo-context/demo
git checkout -- docs/repos-registry.md 2>/dev/null || true
git diff --stat docs/repos-registry.md
```
Expected: `docs/repo-context/demo` gone; `docs/repos-registry.md` shows no diff (the demo block was reverted). The registry's real field changes come in Task 6.

- [ ] **Step 8: Commit**

```bash
git add scripts/onboard-repo.sh
git commit -m "feat(onboard): add idempotent onboard-repo.sh (registry + graphify wiring + doc stamping)"
```

---

## Task 3: `scripts/check-repo-context.sh` (freshness)

**Files:**
- Create: `scripts/check-repo-context.sh`

- [ ] **Step 1: Verify absent (red)**

Run: `scripts/check-repo-context.sh 2>&1 || echo MISSING`
Expected: `MISSING`.

- [ ] **Step 2: Write the script**

```bash
#!/usr/bin/env bash
# File: scripts/check-repo-context.sh
# Purpose: Warn-only freshness check for per-repo context docs. For each covered
#          repo, compare the provenance "Source commit" recorded in its
#          code-structure.md against the repo's current HEAD; flag drift. Never
#          blocks — always exits 0, signals via a Status: line (suite convention).
# See: docs/superpowers/specs/2026-06-24-repo-onboarding-design.md → Drift management
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

status="ok"
found=0
echo "Repo-context freshness:"

for d in docs/repo-context/*/; do
  [ -d "$d" ] || continue
  name="$(basename "$d")"
  [ "$name" = "_templates" ] && continue
  doc="${d}code-structure.md"
  [ -f "$doc" ] || continue
  found=1

  rec="$(grep -m1 -oE 'Source commit: [0-9a-f]+' "$doc" | awk '{print $3}')"
  if [ -d "repos/$name" ]; then path="repos/$name"; else path="."; fi

  if [ -z "$rec" ]; then
    echo "  ? $name: no recorded source commit — run /onboard-repo $name --refresh"
    status="degraded"; continue
  fi
  if ! git -C "$path" rev-parse -q --verify "${rec}^{commit}" >/dev/null 2>&1; then
    echo "  ? $name: recorded commit $rec not found in $path — run /onboard-repo $name --refresh"
    status="degraded"; continue
  fi
  # Exclude the context docs themselves so doc commits don't self-report as drift.
  changes="$(git -C "$path" log "${rec}..HEAD" --oneline -- . ':(exclude)docs/repo-context' 2>/dev/null)"
  if [ -n "$changes" ]; then
    echo "  ✗ $name: code changed since $rec — context docs may be stale (/onboard-repo $name --refresh)"
    status="degraded"
  else
    echo "  ✓ $name: up to date ($rec)"
  fi
done

[ "$found" = 1 ] || echo "  (no covered repos with context docs yet)"
echo "Status: repo-context=$status"
exit 0
```

- [ ] **Step 3: Make executable + verify the empty case (green)**

Run: `chmod +x scripts/check-repo-context.sh && scripts/check-repo-context.sh; echo "exit=$?"`
Expected: prints `(no covered repos with context docs yet)`, `Status: repo-context=ok`, `exit=0`.

- [ ] **Step 4: Verify the stale path with a scratch repo**

Run:
```bash
scripts/onboard-repo.sh demo .
# advance HEAD with a non-context change so the check sees drift:
touch /tmp/onboard-probe && git add -A && git commit -q -m "probe: scratch commit for freshness test"
scripts/check-repo-context.sh
```
Expected: prints `✗ demo: code changed since <sha> ...` and `Status: repo-context=degraded`, exit 0.

- [ ] **Step 5: Clean up the scratch state**

Run:
```bash
git reset -q --hard HEAD~1
rm -rf docs/repo-context/demo
git checkout -- docs/repos-registry.md 2>/dev/null || true
```
Expected: scratch commit and demo artifacts gone; clean tree.

- [ ] **Step 6: Commit**

```bash
git add scripts/check-repo-context.sh
git commit -m "feat(onboard): add warn-only check-repo-context.sh freshness check"
```

---

## Task 4: Extend `scripts/check-workspace-structure.sh`

**Files:**
- Modify: `scripts/check-workspace-structure.sh`

- [ ] **Step 1: Confirm it currently ignores `_templates/` (red)**

Run: `grep -c '_templates' scripts/check-workspace-structure.sh`
Expected: `0`.

- [ ] **Step 2: Add the template assertions**

Find this block (the executable-scripts loop) in `scripts/check-workspace-structure.sh`:

```bash
# Scripts executable
for s in scripts/*.sh; do
  [ -x "$s" ] && ok "executable $s" || bad "not executable $s (chmod +x)"
done
```

Insert immediately AFTER it:

```bash
# repo-context doc templates present (onboard-repo depends on these)
for f in code-structure.md design.md api.md; do
  [ -f "docs/repo-context/_templates/$f" ] && ok "template _templates/$f" \
    || bad "missing template docs/repo-context/_templates/$f"
done
```

- [ ] **Step 3: Verify it passes (green)**

Run: `scripts/check-workspace-structure.sh; echo "exit=$?"`
Expected: includes three `✓ template _templates/...` lines, `All checks passed.`, `exit=0`.

- [ ] **Step 4: Commit**

```bash
git add scripts/check-workspace-structure.sh
git commit -m "test(onboard): assert repo-context templates exist in structure check"
```

---

## Task 5: graphify MCP server entries

**Files:**
- Modify: `.mcp.json.example`
- Modify: `.vscode/mcp.json.example`

- [ ] **Step 1: Confirm graphify is absent from both (red)**

Run: `grep -c graphify .mcp.json.example .vscode/mcp.json.example`
Expected: both report `0`.

- [ ] **Step 2: Add the graphify server to `.mcp.json.example` (key `mcpServers`)**

In `.mcp.json.example`, change the `mcpServers` block from:

```json
  "mcpServers": {
    "github": {
      "type": "http",
      "url": "https://api.githubcopilot.com/mcp/",
      "headers": {
        "Authorization": "Bearer ${GITHUB_PERSONAL_ACCESS_TOKEN}"
      }
    }
  }
```

to (add the `graphify` sibling — note the comma after the github block):

```json
  "mcpServers": {
    "github": {
      "type": "http",
      "url": "https://api.githubcopilot.com/mcp/",
      "headers": {
        "Authorization": "Bearer ${GITHUB_PERSONAL_ACCESS_TOKEN}"
      }
    },
    "graphify": {
      "type": "stdio",
      "command": "graphify-mcp",
      "args": []
    }
  }
```

Also append to the existing `_comment` string (before its closing quote) so the multi-repo note travels with the file:
` graphify serves graphify-out/graph.json over stdio; for a multi-repo workspace point it at a specific graph via args, e.g. \"args\": [\"repos/<name>/graphify-out/graph.json\"].`

- [ ] **Step 3: Add the graphify server to `.vscode/mcp.json.example` (key `servers`, JSONC)**

In `.vscode/mcp.json.example`, change the `servers` block from:

```jsonc
  "servers": {
    "github": {
      "type": "http",
      "url": "https://api.githubcopilot.com/mcp/",
      "headers": {
        "Authorization": "Bearer ${GITHUB_PERSONAL_ACCESS_TOKEN}"
      }
    }
  }
```

to:

```jsonc
  "servers": {
    "github": {
      "type": "http",
      "url": "https://api.githubcopilot.com/mcp/",
      "headers": {
        "Authorization": "Bearer ${GITHUB_PERSONAL_ACCESS_TOKEN}"
      }
    },
    // graphify serves graphify-out/graph.json over stdio. Multi-repo: set
    // "args": ["repos/<name>/graphify-out/graph.json"] to pick a specific graph.
    "graphify": {
      "type": "stdio",
      "command": "graphify-mcp",
      "args": []
    }
  }
```

- [ ] **Step 4: Verify both keys + JSON validity (green)**

Run:
```bash
python3 -c "import json,sys; d=json.load(open('.mcp.json.example')); assert 'graphify' in d['mcpServers']; print('mcp ok')"
python3 -c "import json,re; s=open('.vscode/mcp.json.example').read(); s=re.sub(r'(?m)^\s*//.*$','',s); d=json.loads(s); assert 'graphify' in d['servers']; print('vscode ok')"
```
Expected: `mcp ok` then `vscode ok` (the second strips `//` comment lines before parsing). If either raises, fix the trailing comma / key.

- [ ] **Step 5: Commit**

```bash
git add .mcp.json.example .vscode/mcp.json.example
git commit -m "feat(onboard): wire graphify-mcp stdio server in MCP config examples"
```

---

## Task 6: Registry new fields (`docs/repos-registry.md`)

**Files:**
- Modify: `docs/repos-registry.md`

- [ ] **Step 1: Confirm the new fields are absent (red)**

Run: `grep -c 'Auth method' docs/repos-registry.md`
Expected: `0`.

- [ ] **Step 2: Update the example entry**

Replace the entire example block (from `## <repo-name> (primary)` to the final `- **Tier**:` line) with:

```markdown
## <repo-name> (primary)

- **Host**: <GitHub / GitLab / Bitbucket / local>
- **Clone URL**: `<ssh-or-https-clone-url>` (n/a for local)
- **Default branch**: `main`
- **Visibility**: <public / private>
- **Purpose**: <one line>
- **Auth method**: <gh CLI / SSH key X / PAT in keychain> — see `docs/runbooks/authentication.md`
- **Language / stack**: <languages + frameworks>
- **Build / test / run**: `<build>` / `<test>` / `<run>`
- **Network**: <none special / VPN required / SSH key X>
- **Location**: `repos/<repo-name>/` (or "workspace root" for single-repo; a local path for a non-hosted repo)
- **Covered by context docs**: not yet — once onboarded, `docs/repo-context/<repo-name>/` holds `code-structure.md`, `design.md`, `api.md`
- **Tier**: <primary | optional>
```

- [ ] **Step 3: Verify (green)**

Run: `grep -E 'Auth method|Language / stack|Build / test / run|local' docs/repos-registry.md`
Expected: the three new field labels and the `local` host option all appear.

- [ ] **Step 4: Commit**

```bash
git add docs/repos-registry.md
git commit -m "feat(onboard): add auth/local/stack/commands fields to repos registry"
```

---

## Task 7: repo-context README (2-doc → 3-doc)

**Files:**
- Modify: `docs/repo-context/README.md`

- [ ] **Step 1: Confirm it still says two docs + prompt-library (red)**

Run: `grep -E 'prompt-library|api.md' docs/repo-context/README.md`
Expected: `prompt-library` appears; `api.md` does NOT.

- [ ] **Step 2: Replace the body**

Replace everything from `# Repo Context — Index` to the end of the file with:

```markdown
# Repo Context — Index

Per-repo navigation (`code-structure.md`), architecture (`design.md`), and API
surface (`api.md`) docs. None are populated yet.

Add one folder per covered repo via the onboarding workflow — run
`/onboard-repo <repo-name>` (or `scripts/onboard-repo.sh <repo-name> [repo-path]`),
then fill the three docs following `skills/onboard-repo/SKILL.md`. The skeletons in
`docs/repo-context/_templates/` keep the output format consistent. Each doc carries
a provenance block (generation date + source commit); `scripts/check-repo-context.sh`
flags when a repo's code has moved past that commit.

> None yet.
```

- [ ] **Step 3: Verify (green)**

Run: `grep -E 'api.md|_templates|onboard-repo' docs/repo-context/README.md && ! grep -q 'prompt-library' docs/repo-context/README.md && echo "no prompt-library"`
Expected: the three references appear and `no prompt-library` prints.

- [ ] **Step 4: Commit**

```bash
git add docs/repo-context/README.md
git commit -m "docs(onboard): repo-context index covers 3-doc trio + _templates"
```

---

## Task 8: The skill + Claude command

**Files:**
- Create: `skills/onboard-repo/SKILL.md`
- Create: `.claude/commands/onboard-repo.md`

- [ ] **Step 1: Verify absent (red)**

Run: `ls skills/onboard-repo/SKILL.md .claude/commands/onboard-repo.md 2>&1 | grep -c 'No such'`
Expected: `2`.

- [ ] **Step 2: Write `skills/onboard-repo/SKILL.md`**

```markdown
---
name: onboard-repo
description: Use when bringing a repository into the workspace — record its identity and auth in the registry, build/wire a graphify code index (with a manual-scan fallback), and derive committed code-structure / design / api docs under docs/repo-context/<repo>/ so agents and developers can pull repo knowledge on demand. Trigger when adding a repo, or when the user says "onboard this repo".
---

# onboard-repo

You are **onboarding a repository** into this workspace. Capture its identity, build a
queryable index, and produce the committed reference docs other agents will pull on demand.

Vendor-neutral: any agent runtime can follow these steps. Claude Code also exposes this as
the `/onboard-repo` slash command (`.claude/commands/onboard-repo.md`, a thin wrapper around
this skill). Required input — the **repo name** (the registry key + `docs/repo-context/<name>/`
folder); optional second input — the **repo path** (defaults to the workspace root for a
single-repo workspace, else `repos/<name>/`).

## When to use
- Adding a new repo to the workspace (hosted or local).
- Refreshing an already-onboarded repo after material code change (`--refresh`).
- When the user says "onboard this repo".

## Prerequisites
- `scripts/onboard-repo.sh` (mechanical scaffolding) and the `docs/repo-context/_templates/`.
- graphify is **optional** — its absence triggers the manual-scan fallback, not a failure.
- Auth: `docs/runbooks/authentication.md` (verify-only; never log in or store secrets here).

## Steps

Do these in order, concisely (reference artifacts by path — don't duplicate code):

1. **Record repo info.** Run `scripts/onboard-repo.sh <repo-name> [repo-path]`. Then open
   `docs/repos-registry.md` and fill the new entry's placeholders (Host/Clone URL/Auth
   method/Language-stack/Build-test-run/etc.). For a local repo use `Host: local`, `Clone
   URL: n/a`.
2. **Verify host auth.** Confirm access to the repo's host per `docs/runbooks/authentication.md`
   (e.g. `gh auth status`). Verify only — do not log in or write secrets. Local repos: skip.
3. **Set up indexing.** Read the script's `Status:` line. If `graphify=fallback` and you want
   live queries, build the graph: run `/graphify` (Claude Code) or the graphify CLI in the repo
   path — this is an API-cost step, so do it deliberately. If graphify can't be used (not
   installed / unsupported), proceed with a manual scan; the committed docs below are produced
   either way.
4. **Write `code-structure.md`.** Fill `docs/repo-context/<repo>/code-structure.md` —
   directory map, modules & responsibilities, entrypoints, key flows. Use graphify queries
   (`graphify query/path/explain`, or the graphify MCP tools) when live; else a manual scan.
   Keep it high-level (not line-level) so it ages well.
5. **Derive `design.md`.** Fill architecture overview, components & boundaries, data flow,
   key decisions/trade-offs, known constraints. This holds the "why" graphify can't recover —
   keep graphify-derivable facts in code-structure.md, not here.
6. **Derive `api.md`.** Detect the repo type (service / library / CLI), fill the matching
   section(s), and delete the inapplicable ones.
7. **Wire discoverability.** Confirm the registry entry's "Covered by context docs" points at
   the folder; add the repo to `docs/repo-context/README.md`'s index; note it under
   `CONTEXT.md` → Covered Repos.
8. **Flag for human review.** `design.md` and `api.md` are *your reading* of the code, not
   mechanically extracted — tell the user to review the three docs in the commit/PR diff
   before trusting them.

To refresh later: `scripts/onboard-repo.sh <repo-name> --refresh` (re-stamps provenance +
runs `graphify update .`), then re-derive any docs whose content has drifted.

## Outputs
- A completed `docs/repos-registry.md` entry (identity + auth + stack + commands).
- A graphify graph (live query path) or a documented fallback.
- `docs/repo-context/<repo>/{code-structure,design,api}.md`, provenance-stamped.
- Discoverability wired (registry "covered", README index, CONTEXT.md) + a review nudge.

End by listing the three docs for the user to review, and whether graphify is live or fallback.
```

- [ ] **Step 3: Write `.claude/commands/onboard-repo.md`**

```markdown
---
description: Onboard a repository — registry entry, graphify index, and committed code-structure/design/api docs
argument-hint: "<repo-name> [repo-path]   (e.g. 'payments-api repos/payments-api')"
---

Repo to onboard: **$ARGUMENTS**

Execute the **onboard-repo** workflow defined in `skills/onboard-repo/SKILL.md` — follow its
steps in order (record repo info → verify auth → set up graphify indexing → write
code-structure.md → derive design.md → derive api.md → wire discoverability → flag for review),
using the repo name (and optional path) above.

End by listing the three docs for review and stating whether graphify is live or fallback.
```

- [ ] **Step 4: Verify (green)**

Run: `head -3 skills/onboard-repo/SKILL.md && grep -c 'onboard-repo' .claude/commands/onboard-repo.md`
Expected: the SKILL.md frontmatter (`name: onboard-repo`) prints; the command file references `onboard-repo` (count ≥ 1).

- [ ] **Step 5: Commit**

```bash
git add skills/onboard-repo/SKILL.md .claude/commands/onboard-repo.md
git commit -m "feat(onboard): add onboard-repo skill + /onboard-repo command"
```

---

## Task 9: `CONTEXT.md` — list the skill + Covered Repos wording

**Files:**
- Modify: `CONTEXT.md`

- [ ] **Step 1: Confirm absent (red)**

Run: `grep -c 'onboard-repo' CONTEXT.md`
Expected: `0`.

- [ ] **Step 2: Add the skill bullet under Workspace Skills**

In `CONTEXT.md`, find the `## Workspace Skills` section and the `checkpoint` bullet that
ends with `... See `docs/recommended-tooling.md`).` Insert this bullet immediately after the
checkpoint bullet (blank line between):

```markdown
- **onboard-repo** (`skills/onboard-repo/SKILL.md`) — bring a repo into the
  workspace: record its identity/auth in `docs/repos-registry.md`, build/wire a
  graphify code index (manual-scan fallback), and derive committed
  `code-structure.md` / `design.md` / `api.md` under `docs/repo-context/<repo>/`.
  Claude Code shortcut: **`/onboard-repo <repo-name> [repo-path]`**. Freshness:
  `scripts/check-repo-context.sh`; refresh: `scripts/onboard-repo.sh <repo> --refresh`.
```

- [ ] **Step 3: Update the Covered Repos section**

Find the `## Covered Repos` section. Replace its body with:

```markdown
Per-repo context docs live under `docs/repo-context/` — see
`docs/repo-context/README.md` for the index. Onboard a repo with
`/onboard-repo <repo-name>` to generate its `code-structure.md`, `design.md`,
and `api.md`. None are documented yet.
```

- [ ] **Step 4: Verify (green)**

Run: `grep -E 'onboard-repo|api.md' CONTEXT.md | head`
Expected: the skill bullet and the Covered Repos `api.md` reference both appear.

- [ ] **Step 5: Commit**

```bash
git add CONTEXT.md
git commit -m "docs(onboard): list onboard-repo skill + update Covered Repos in CONTEXT.md"
```

---

## Task 10: Tooling/MCP docs + backlog change-log

**Files:**
- Modify: `docs/recommended-tooling.md`
- Modify: `docs/mcp-setup.md`
- Modify: `docs/template-workspace-backlog.html`

- [ ] **Step 1: Confirm graphify MCP undocumented (red)**

Run: `grep -c 'graphify-mcp' docs/recommended-tooling.md docs/mcp-setup.md`
Expected: both `0`.

- [ ] **Step 2: Add a graphify-MCP note to `docs/recommended-tooling.md`**

In `docs/recommended-tooling.md`, find the line:

```markdown
`graphify-out/` is already in this template's `.gitignore` — the graph is
regenerated locally per machine, never committed.
```

Insert immediately BEFORE it:

```markdown
**Query it from an MCP-capable agent (optional):** the package ships a
`graphify-mcp` stdio server that exposes the graph as MCP tools. This template
pre-wires it in `.mcp.json.example` and `.vscode/mcp.json.example` (see
`docs/mcp-setup.md`); the `onboard-repo` workflow copies `.mcp.json` for you.
For a multi-repo workspace, point the server at a specific graph via
`"args": ["repos/<name>/graphify-out/graph.json"]`. The Gemini/OpenCode hooks
remain the query path for those runtimes.

```

- [ ] **Step 3: Add a graphify section to `docs/mcp-setup.md`**

In `docs/mcp-setup.md`, find the `### Other runtimes` heading (the last `###` under
`## Per-runtime configuration`). Insert this new subsection immediately BEFORE it:

```markdown
### graphify — code knowledge graph (optional)

The `graphify-mcp` stdio server (from `uv tool install graphifyy`) serves a repo's
`graphify-out/graph.json` as MCP query tools. It's pre-staged in `.mcp.json.example`
and `.vscode/mcp.json.example` under their respective server keys
(`mcpServers` vs `servers`), so MCP-capable runtimes (Claude Code, VS Code) pick it
up once you copy the example to the live file.

- **Single-repo:** default args (`[]`) serve `graphify-out/graph.json` in the cwd.
- **Multi-repo:** set `"args": ["repos/<name>/graphify-out/graph.json"]` per repo.
- **Codex / Gemini / OpenCode:** not pre-wired — add the same `graphify-mcp` stdio
  command to that runtime's MCP config if desired; otherwise the existing graphify
  hooks (`.gemini/settings.json`, `.opencode/`) already provide the query nudge.

The graph must be built first (`/graphify` or the graphify CLI); see
`docs/recommended-tooling.md` → graphify.

```

- [ ] **Step 4: Add a change-log row to the backlog**

In `docs/template-workspace-backlog.html`, find the change-log table (search for the
most recent `<tr>` row mentioning `checkpoint`). Add a new row immediately after the
table's opening `<tbody>` (so newest is first), matching the existing row markup:

```html
        <tr><td>2026-06-24</td><td>Feature: added the <code>onboard-repo</code> workflow (<code>skills/onboard-repo/SKILL.md</code> + <code>/onboard-repo</code> + <code>scripts/onboard-repo.sh</code>) — registry identity/auth fields, graphify MCP wiring (<code>graphify-mcp</code>) with manual-scan fallback, and provenance-stamped <code>code-structure.md</code>/<code>design.md</code>/<code>api.md</code> under <code>docs/repo-context/&lt;repo&gt;/</code>, plus <code>check-repo-context.sh</code> freshness check.</td></tr>
```

(If the existing rows are ordered oldest-first instead, append it as the last row to match.)

- [ ] **Step 5: Verify (green)**

Run:
```bash
grep -c 'graphify-mcp' docs/recommended-tooling.md docs/mcp-setup.md
grep -c 'onboard-repo' docs/template-workspace-backlog.html
```
Expected: the first two are ≥ 1; the backlog count is ≥ 1.

- [ ] **Step 6: Run the full structure check**

Run: `scripts/check-workspace-structure.sh; echo "exit=$?"`
Expected: `All checks passed.`, `exit=0` (templates + scripts all present and executable).

- [ ] **Step 7: Commit**

```bash
git add docs/recommended-tooling.md docs/mcp-setup.md docs/template-workspace-backlog.html
git commit -m "docs(onboard): document graphify MCP server + log onboard-repo in backlog"
```

---

## Task 11: `workspace-structure.md` reconciliation + setup.sh hint

**Files:**
- Modify: `docs/workspace-structure.md`
- Modify: `scripts/setup.sh`

The structure doc still describes a *two*-doc convention and an aspirational
`repo-context-docs` skill — `onboard-repo` is the concrete implementation. Reconcile.

- [ ] **Step 1: Confirm the stale references (red)**

Run: `grep -nE 'repo-context-docs|prompt contract \(see' docs/workspace-structure.md`
Expected: matches at the skills tree, the generic-skills list, and the "Why Per-Repo
Context Docs?" section.

- [ ] **Step 2: Add `api.md` to the repo-context tree**

In `docs/workspace-structure.md`, change:

```
    └── <repo>/                 #   One folder per covered repo
        ├── code-structure.md   #   Factual navigation ("where is it?")
        └── design.md           #   Architecture and design ("how does it fit?")
```

to:

```
    ├── _templates/             #   Skeletons copied into each repo folder
    └── <repo>/                 #   One folder per covered repo
        ├── code-structure.md   #   Factual navigation ("where is it?")
        ├── design.md           #   Architecture and design ("how does it fit?")
        └── api.md              #   Public surface (service / library / CLI)
```

- [ ] **Step 3: Rewrite the "Why Per-Repo Context Docs?" body**

Replace the section body (from `When agents work inside a repo` through
`not committed back to the product repos.`) with:

```markdown
When agents work inside a repo, they need orientation faster than
"read every file." Three short docs per repo answer the common questions:

- **`code-structure.md`** — a factual map: where modules live, what each
  directory does, how to find specific functionality.
- **`design.md`** — architecture and component boundaries: how the pieces
  fit together, what's a separate process vs. a library, why.
- **`api.md`** — the repo's public surface (service endpoints, library
  exports, or CLI commands — whichever applies).

Generate them with the **`onboard-repo`** workflow (`/onboard-repo <repo-name>`,
backed by `scripts/onboard-repo.sh` and the skeletons in
`docs/repo-context/_templates/`); each doc carries a provenance block (date +
source commit) and `scripts/check-repo-context.sh` flags when the code has moved
past it. Refresh with `scripts/onboard-repo.sh <repo> --refresh`. They are
workspace artifacts, not committed back to the product repos.
```

- [ ] **Step 4: Rename the skill in the skills tree + generic list**

Change the skills-tree line:

```
├── repo-context-docs/          # Generate/refresh repo context documents
```

to:

```
├── onboard-repo/               # Onboard a repo: registry + index + context docs
```

And in the "Generic vs. Domain-Specific Skills" list, change `repo-context-docs`
to `onboard-repo`:

```markdown
- **Generic** (`handoff`, `diagnose`, `tdd`, `grill`, `context-analysis`,
  `onboard-repo`) — useful in any project.
```

- [ ] **Step 5: Reference the freshness check in `setup.sh`**

In `scripts/setup.sh`, change the closing hints from:

```bash
echo "Done. Next:"
echo "  - authenticate / export the MCP token: scripts/check-service-access.sh (then docs/runbooks/authentication.md)"
echo "  - fill in CONTEXT.md, then run scripts/check-workspace-structure.sh"
```

to:

```bash
echo "Done. Next:"
echo "  - authenticate / export the MCP token: scripts/check-service-access.sh (then docs/runbooks/authentication.md)"
echo "  - fill in CONTEXT.md, then run scripts/check-workspace-structure.sh"
echo "  - onboard a repo: /onboard-repo <repo-name>  (freshness later: scripts/check-repo-context.sh)"
```

- [ ] **Step 6: Verify (green)**

Run: `grep -c 'onboard-repo' docs/workspace-structure.md scripts/setup.sh && ! grep -q 'repo-context-docs' docs/workspace-structure.md && echo "renamed"`
Expected: both counts ≥ 1 and `renamed` prints (no `repo-context-docs` left).

- [ ] **Step 7: Commit**

```bash
git add docs/workspace-structure.md scripts/setup.sh
git commit -m "docs(onboard): reconcile workspace-structure to onboard-repo + 3-doc trio"
```

---

## Final verification

- [ ] **Step 1: Self-contained dry run on the template itself**

Run:
```bash
scripts/onboard-repo.sh self .
scripts/check-repo-context.sh
ls docs/repo-context/self/
```
Expected: three provenance-stamped docs created; freshness check runs and `exit 0`s.

- [ ] **Step 2: Clean up the dry-run artifacts**

Run:
```bash
rm -rf docs/repo-context/self
git checkout -- docs/repos-registry.md 2>/dev/null || true
git status --short
```
Expected: no `docs/repo-context/self`, no stray registry diff; tree clean (all real changes already committed in Tasks 1–10).

- [ ] **Step 3: Confirm the workspace is healthy**

Run: `scripts/check-workspace-structure.sh && echo OK`
Expected: `All checks passed.` then `OK`.
