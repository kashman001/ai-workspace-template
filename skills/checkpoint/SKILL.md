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

## Which boundary skill? (first yes wins)

1. Context-budget WARN/STOP signal (hook message, or `context-budget.sh` exit code
   1/2)? → `session-rollover`.
2. Deliberate end of a work chunk, budget OK? → `checkpoint` (this skill).
3. Both true? → `session-rollover` — measurement wins; fold this skill's step-1
   reconciliation into its reflect/flush steps.

## Prerequisites
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
     `MEMORY.md` pointers. A human-driven retrospective ("what failed that we shouldn't
     repeat?") is best run here or at the *start* of a successor session — fresh context,
     ledger and git history in hand — never squeezed into a token-starved rollover.
   - the matching **reference docs** under `docs/` if a feature shipped or changed.
   - **decision notes** — scan `work/*/decisions.md` for entries flagged `Promote?: yes`
     (or a `maybe` whose condition now holds), **and** `work/*/map.md` "Decisions so far"
     entries — a resolved wayfinder ticket is a Tier-2 decision and the map substitutes
     for `decisions.md` (per `docs/agents/issue-tracker.md` → "Decision-log tie-in").
     For each, follow the `decision-log` skill's promotion steps (draft an ADR under
     `docs/adr/`, fill its Provenance block, flip the note to `done → ADR-NNNN`). This is
     where the session's ephemeral *why* becomes a durable, committed record — do it
     before context compacts.

2. **Write a hand-off doc** for the next chunk, under `work/<project-name>/` (the
   workspace convention). The hand-off contract:
   - reference artifacts by path/URL — never duplicate plans/specs/diffs into the doc;
   - include a **suggested skills** section for the next session;
   - redact secrets/PII.
   If the global `handoff` skill is installed (`docs/recommended-tooling.md`) you may use
   it to draft the doc; the contract above binds either way. Frame it around the next
   focus, or — if none given — the next item in the backlog's active sequence.

3. **Confirm repo/branch state** is clean and recorded: current branch, working tree clean,
   merged branches tidied or noted. If the project deploys, record the live deployment versions.

4. **Emit a ready-to-paste catch-up prompt** (for the next session, after context is
   compacted/cleared) in a fenced block — it must name the hand-off doc path and tell the next
   session to catch up + continue with the right starting skill (often
   `superpowers:brainstorming`). Keep it ~3–5 lines.

## Verification

- Hand-off doc is on disk: `ls work/<project-name>/` shows it.
- Promotion scan ran to completion: `grep -n 'Promote?: yes\|Promote?: maybe' work/*/decisions.md work/*/map.md`
  — every hit is either promoted this checkpoint (flipped to `done → ADR-NNNN`) or its
  `maybe` condition checked and still unmet.
- Branch state matches step 3's claim: `git status --short` is clean, or the exceptions
  are named in the hand-off doc.

## Outputs
- Reconciled backlog/issue tracker, project memory (+ `MEMORY.md`), and reference docs.
- A hand-off doc under `work/<project-name>/`.
- A catch-up prompt the user pastes into the next session.

End by telling the user to compact/clear context, then paste the catch-up prompt to continue.
Keep the whole response tight — this is a transition, not a status essay.
