---
name: create-work-item
description: >
  Scaffold a new developer-scoped project directory under work/ that follows the
  work-directory conventions (README + launcher next-session.md + ledger
  handoff.md). Use when starting a new piece of multi-session work, when the user
  says "create a work item / work directory / project", or before beginning work
  that will span more than one session and needs a launcher + ledger. For
  single-file or one-shot tasks, do not create a work directory.
---

## Purpose

Create a `work/<project-name>/` directory pre-wired with the standard backbone
files (README, launcher, ledger) so multi-session work starts consistent and
stays context-cheap. This skill owns the scaffolding procedure; the durable
definition of each file's role lives in `docs/work-directory-conventions.md`.

Do **not** use this for trivial single-step tasks — those need no work
directory. Use it when work will span multiple sessions or needs persistent,
agent-neutral state on disk.

## Required Reads

**Always read first:**

1. `docs/work-directory-conventions.md` — the file roles and write discipline.

**Read on demand:**

1. `skills/session-rollover/SKILL.md` — how the launcher and ledger are
   maintained (and rolled over) across sessions.
2. `skills/decision-log/SKILL.md` — only if the project will keep a
   `decisions.md` / ADRs.

## Procedure

1. **Confirm scope and name.** Pick a hyphenated directory name
   (`work/<project-name>/`). Ask the user for the governing skill(s) if any
   workflow skill applies; use `—` if none.

2. **Create the directory and the three backbone files** below. Substitute
   `<project>`, a one-line description, the governing skill(s), and the first
   objective. Use the canonical names `next-session.md` (launcher) and
   `handoff.md` (ledger).

3. **README.md** (project identity — durable, changes rarely):

   ```markdown
   # <Project> — <one-line what-it-is>

   Governing skill(s): `<skill>` (or none).

   **Start here:** `next-session.md` (catch-up launcher) → `handoff.md`
   (session ledger, top block).

   ## What this is

   <2–4 sentences: goal, scope, why it exists.>

   ## Files

   - `next-session.md` — forward launcher (what to do next). REPLACED each rollover.
   - `handoff.md` — session ledger (what happened). APPEND newest-on-top; archive
     to `handoff-archive.md` when it exceeds the two most recent sessions.
   - <other project files, added as they appear.>
   ```

4. **next-session.md** (launcher — starts nearly empty, forward-only):

   ```markdown
   # Catchup prompt — <Project> (paste into a new agent session)

   We're resuming <project>. Works in any runtime (Claude Code, Codex, Gemini,
   OpenCode) — all read `CONTEXT.md` via their entrypoint.

   > **This file is the LAUNCHER (catch-up prompt).** Forward-only, and REPLACED
   > at each rollover: it holds what to do next, still-binding constraints, and
   > pointers — never session history. Past-tense provenance lives in
   > `handoff.md` (the append-only ledger). Convention:
   > docs/work-directory-conventions.md.

   ## >>> START HERE <<<

   <The current objective and the concrete next actions (a short numbered todo).>

   ## Constraints already decided (do not re-litigate)

   <One-liners + pointers, added as decisions are made.>

   ## Read these first, in order

   1. `work/<project>/README.md`
   2. `work/<project>/handoff.md` (top block)
   ```

5. **handoff.md** (ledger — purpose header + first block):

   ```markdown
   <!--
   PURPOSE: This is the LEDGER (provenance log). Append-only, newest block on
   TOP. Each "# Session Handoff" block records what happened in one session.
   Read the TOP block only; older blocks are in handoff-archive.md. Forward
   "what to do next" belongs in next-session.md, NOT here.
   Convention: docs/work-directory-conventions.md.
   -->

   # Session Handoff — <date> (session 1: <one-line summary>)

   <What got done, current state, immediate next step.>
   ```

6. **Optional files** — create only if the project needs them now:
   - `STATUS.md` — shareable status snapshot.
   - `glossary.md` — project-scoped terms.
   - `decisions.md` / `docs/adr/*` — per `skills/decision-log/SKILL.md`.

7. **Do not** add the project's internal files to any global workspace file
   (`CONTEXT.md`, `docs/workspace-structure.md`). Those may name the directory as
   a location pointer only.

## Verification

- `work/<project>/` contains `README.md`, `next-session.md`, `handoff.md`.
- The launcher's START HERE names a concrete first action; the ledger has one
  session block with the purpose header.
