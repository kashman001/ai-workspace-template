---
name: checkpoint
description: Use at a session boundary between major chunks of work to wrap up what shipped and prepare a clean hand-off into the next chunk — reconcile the backlog/issue tracker, project memory, and reference docs; write a hand-off doc; confirm clean branch state; and emit a catch-up prompt for the next (post-context-compaction) session. Trigger when finishing a work chunk, before compacting/clearing context, or when the user says "checkpoint".
---

# checkpoint

You are at a **checkpoint between major chunks of work**. Wrap up what just shipped and
prepare a clean hand-off into the next chunk — so the user doesn't retype this each time.

Vendor-neutral: any agent runtime can follow these steps. Claude Code also exposes this as
the `/checkpoint` slash command (`.claude/commands/checkpoint.md`, a thin wrapper around this
skill). Optional input — the **next focus** (e.g. "Phase 3 Trends"); if omitted, infer it
from the backlog's active sequence.

## When to use
- Finishing a major chunk of work, before starting the next.
- Before compacting or clearing the context window (Claude Code `/compact`, or your
  runtime's equivalent).
- When the user says "checkpoint".

## Prerequisites
- The `handoff` skill (for the hand-off doc) — see `docs/recommended-tooling.md`.
- A project memory location and an issue-tracker/backlog convention (per
  `docs/agents/issue-tracker.md` if the Matt Pocock skills were set up).

## Steps

Do these in order, concisely (reference artifacts by path — do NOT duplicate plans/specs/diffs):

1. **Reconcile the record.** Make sure what just shipped is reflected in:
   - the project's **issue tracker / backlog** — per `docs/agents/issue-tracker.md` if
     configured, else the repo's own convention (GitHub Issues, a `BACKLOG.md`, `.scratch/`).
     Mark finished items `Done` (date + how / PR + any deploy versions); add newly-discovered
     work. If committed docs change, follow the repo's branch/PR pattern — don't push to the
     default branch unless that's the convention.
   - **project memory** (the agent's per-project memory dir, e.g.
     `~/.claude/projects/<project-id>/memory/` for Claude Code) — update the running-arc
     memory and add durable, non-obvious learnings (gotchas, decisions, preferences); update
     `MEMORY.md` pointers.
   - the matching **reference docs** under `docs/` if a feature shipped or changed.
   - **decision notes** — scan `work/<username>_<project-name>/decisions.md` for entries
     flagged `Promote?: yes` (or a `maybe` whose condition now holds). For each, follow the
     `decision-log` skill's promotion steps (draft an ADR under `docs/adr/`, fill its
     Provenance block, flip the note to `done → ADR-NNNN`). This is where the session's
     ephemeral *why* becomes a durable, committed record — do it before context compacts.

2. **Write a hand-off doc** for the next chunk: invoke the `handoff` skill (secret-free, with
   a suggested-skills section). Persist it under `work/<username>_<project-name>/` (the
   workspace convention) or the skill's default location. Frame it around the next focus, or —
   if none given — the next item in the backlog's active sequence. Reference the
   spec/plan/runbook by path.

3. **Confirm repo/branch state** is clean and recorded: current branch, working tree clean,
   merged branches tidied or noted. If the project deploys, record the live deployment versions.

4. **Emit a ready-to-paste catch-up prompt** (for the next session, after context is
   compacted/cleared) in a fenced block — it must name the hand-off doc path and tell the next
   session to catch up + continue with the right starting skill (often
   `superpowers:brainstorming`). Keep it ~3–5 lines.

## Outputs
- Reconciled backlog/issue tracker, project memory (+ `MEMORY.md`), and reference docs.
- A hand-off doc under `work/<username>_<project-name>/` (or the `handoff` skill's default).
- A catch-up prompt the user pastes into the next session.

End by telling the user to compact/clear context, then paste the catch-up prompt to continue.
Keep the whole response tight — this is a transition, not a status essay.
