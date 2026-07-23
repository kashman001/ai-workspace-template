# Work Directory Conventions

Every project under `work/<project-name>/` is developer-scoped and made of plain
Markdown / JSON / scripts, so any agent runtime (Claude Code, Codex, Gemini,
OpenCode, …) or a human can pick it up. This doc defines the **standard files**
each work directory should have and the **write discipline** that keeps them
useful over long, multi-session, compaction-prone work.

To scaffold a new work directory that follows these conventions, use
`skills/create-work-item/SKILL.md`.

## The two-file backbone: launcher + ledger

The single most important convention is the split between the **launcher** and
the **ledger**. They answer different questions and have opposite write
disciplines. Conflating them is the main cause of context-token accretion across
sessions. The `session-rollover` skill already emits these two files; this doc
formalizes their roles.

| | **Launcher** (`next-session.md`) | **Ledger** (`handoff.md`) |
|---|---|---|
| **Question it answers** | "What do I do next, and the minimum I must know to start?" | "What happened, in what order, and why?" |
| **Direction** | Forward (imperative) | Backward (provenance) |
| **Write pattern** | **Replace** — rewritten each rollover to describe only the current front | **Append** — one dated block per session, newest on **top** |
| **Growth** | Bounded (~1 screen); should not accumulate history | Bounded by archival, not by size (see below) |
| **Read pattern** | Read in **full** | Read the **top block only**; older blocks are archive |
| **Never contains** | Session history / past-tense narrative | Forward "what to do next" plans |

**The rule that keeps them separate:** past-tense → ledger; future-tense →
launcher; a still-binding constraint → a one-line summary + pointer in the
launcher, with the full record in the ledger. Because the bootstrap ritual reads
**both** files, the launcher never needs to inline history to be self-sufficient
— it points into the ledger and the state files instead.

### Launcher (`next-session.md`)

The catch-up prompt you paste into a fresh session. Top of file states its
purpose (see header block below). Contents, in order:

1. One-line "resuming `<project>`; works in any runtime" preamble.
2. A **START HERE** block: the current objective and the concrete next actions
   (ideally a short numbered todo).
3. Still-binding **constraints / decisions** as one-liners + pointers ("do not
   re-litigate X — see `<file>`").
4. A **read-these-first** list of the project's durable files, in order.

Rewrite it at every rollover. Anything that has become history moves to the
ledger; anything superseded is deleted, not annotated as "superseded".

### Ledger (`handoff.md`)

The append-only provenance log. Each session prepends one
`# Session Handoff — <date> (session N: <one-line summary>)` block containing:
what got done, repo/state at rollover, and the immediate next step. Read only
the top block; the rest is history.

**Archival (prevents unbounded growth):** keep only the two most recent session
blocks live in `handoff.md`; move older blocks to `handoff-archive.md` (read on
demand only). The archive uses the same newest-on-top ordering.

**Alternative pattern — dated handoff files.** Some projects use one file per
session, `handoff-YYYY-MM-DD-topic.md`, instead of a single append-only file.
This is naturally bounded (no archival step) but needs the launcher to point at
the latest. Either pattern is acceptable; pick one per project and be consistent.

## Required and optional files

| File | Required? | Role |
|------|-----------|------|
| `README.md` | **Required** | Project identity: what it is, governing skill(s), and the start-here pointer. Durable — changes rarely. |
| `next-session.md` | Recommended | The **launcher** (see above). |
| `handoff.md` (+ `handoff-archive.md`) | Recommended | The **ledger** (see above). |
| `decisions.md` / `docs/adr/*` | Optional | Decision records, per `skills/decision-log/SKILL.md`. |
| `STATUS.md` | Optional | Shareable program/status snapshot (per-area state, blockers). Distinct from the launcher: STATUS is for humans reviewing progress; the launcher is for an agent resuming work. |
| `glossary.md` | Optional | Project-scoped terms/acronyms. |

Keep everything else (state trackers, registries, run logs, specs) named for
what it is; the governing skill owns the full file-level detail.

## Naming

- Canonical backbone for new work directories: **`handoff.md`** (ledger) +
  **`next-session.md`** (launcher) — the same names the `session-rollover` skill
  produces.
- Use hyphens between words in the project directory name (matches the `skills/`
  naming convention), e.g. `work/my-project/`.

## Purpose headers

Both backbone files should declare their role at the very top so a fresh reader
(or a new runtime) treats them correctly. The launcher uses a visible blockquote
(it is meant to be read/pasted); the ledger uses an HTML comment (it is a log,
kept clean for prepending).

Launcher header (top of `next-session.md`):

```markdown
> **This file is the LAUNCHER (catch-up prompt).** Forward-only, and REPLACED
> at each rollover: it holds what to do next, still-binding constraints, and
> pointers — never session history. Past-tense provenance lives in `handoff.md`
> (the append-only ledger). Convention: docs/work-directory-conventions.md.
```

Ledger header (top of `handoff.md`):

```markdown
<!--
PURPOSE: This is the LEDGER (provenance log). Append-only, newest block on TOP.
Each "# Session Handoff" block records what happened in one session. Read the
TOP block only; older blocks are in handoff-archive.md. Forward "what to do
next" belongs in next-session.md, NOT here.
Convention: docs/work-directory-conventions.md.
-->
```

## Content boundaries

Work directories are developer-scoped. Keep the split clean:

- Global workspace files (`CONTEXT.md`, `docs/workspace-structure.md`) may
  **name** a work directory as a location pointer but must not list its internal
  files, schemas, or state.
- The **governing skill** owns the full file-level detail for its workflow's
  directory.

## Why this matters (context hygiene)

Launcher-and-ledger discipline directly limits per-session token cost:

- A launcher that **replaces** instead of appends stays ~1 screen instead of
  becoming a second handoff.
- A ledger that **archives** old blocks stays small in the read path instead of
  growing unbounded.
- Full-text duplication of the same lesson across multiple early-loaded files is
  a multiplier leak; keep the detail in **one** on-demand doc and use one-line
  pointers everywhere else.

See the **Agent Context Discipline** and **Context Budget** sections of
`CONTEXT.md`, and the `session-rollover` skill, for the surrounding discipline.
