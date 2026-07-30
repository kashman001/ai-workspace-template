<!--
File: docs/superpowers/specs/2026-07-30-wayfinder-integration-design.md
Purpose: Approved design for bringing Matt Pocock's wayfinder skill into the
         template as a vendored, agent-agnostic workspace skill, plus the
         accompanying upstream-sync doc refresh.
-->

# Wayfinder Integration — Design

**Date:** 2026-07-30
**Status:** Approved
**Approach:** Hybrid — vendor wayfinder into the repo; document (don't vendor) the
other new upstream skills.

## Problem

The Matt Pocock skills (including `wayfinder`) are installed as a **global,
per-machine** layer via agent-context symlinks (`docs/recommended-tooling.md` §3).
That covers Claude Code, Codex, and Gemini *on a machine that ran the setup* — but:

- **Copilot** doesn't read `~/.claude/skills/`; it reads the repo's `AGENTS.md`.
- **Template downloaders** without agent-context get no skills at all.
- Wayfinder additionally needs **per-repo tracker wiring** (a "Wayfinding
  operations" section in an issue-tracker doc); without it, it invents a
  `.scratch/` convention that ignores this template's `work/` layout.

## Design

### 1. Vendored skill — `skills/wayfinder/`

- Copy `SKILL.md` and `agents/openai.yaml` from
  `github.com/mattpocock/skills` at clone commit `2ab9580`
  (source path `skills/engineering/wayfinder/`).
- Add a provenance comment after the frontmatter: upstream repo, source path,
  pinned commit, refresh procedure (re-copy + diff after pulling the reference
  clone / `agent-context-sync`).
- `openai.yaml` rides along so Codex renders it as an invokable agent skill.

### 2. Tracker wiring — `docs/agents/issue-tracker.md`

Local-markdown tracker, **adapted to the template's work-directory convention**
(upstream default uses `.scratch/`):

- **Map:** `work/<effort>/map.md` — a wayfinder effort *is* a work directory,
  alongside `README.md` / `next-session.md` / `handoff.md` / `decisions.md`.
- **Tickets:** `work/<effort>/issues/NN-<slug>.md`, `Type:` / `Status:` /
  `Blocked by:` lines per upstream local-markdown conventions.
- **Decision-log tie-in:** a resolved wayfinder ticket is a Tier-2 decision;
  promote lasting ones to ADRs via `/decision promote`.
- Pointer (not a copy) to upstream's GitHub-tracker variant for repos that
  want issues on GitHub instead.

### 3. Front door

- `CLAUDE.md` → Workspace Skills bullet for wayfinder: purpose, where maps
  live, shortcut, and the degraded-mode caveat (ticket types lean on global
  `/grilling`, `/research`, `/prototype`, `/domain-modeling`; without them
  those ticket types degrade to plain conversation).
- `.claude/commands/wayfinder.md` shortcut matching the existing pattern.

### 4. Doc refresh + new-skills mentions (no vendoring)

- `docs/recommended-tooling.md`: bucket list gains `in-progress/`; wayfinder
  row notes the in-repo vendored copy and the duplicate-skill caveat for
  machines with the global symlink install; short "newer upstream skills to
  watch" note — `to-questionnaire` and `wizard` recommended,
  `batch-grill-me` nice-to-have, `claude-handoff` **not** recommended here
  (competes with `session-rollover`), all flagged in-progress upstream.
- `docs/workspace-structure.md` + `docs/work-directory-conventions.md`:
  register `docs/agents/`, `skills/wayfinder/`, and the optional
  `map.md` / `issues/` files in a work directory.
- `docs/template-workspace-backlog.html`: row/card for this addition.

## Out of scope

- Vendoring any other upstream skill.
- GitHub-tracker wiring (documented as a swap, not implemented).
- Changes to the user's global `~/.claude/CLAUDE.md` workflow table.

## Success criteria

- A fresh template clone with no global skills can run wayfinder from any
  AGENTS.md-reading agent, and maps land under `work/<effort>/`.
- Vendored `SKILL.md` diff vs upstream is provenance-comment-only.
- Every new file/dir is registered in the structure docs and backlog.
