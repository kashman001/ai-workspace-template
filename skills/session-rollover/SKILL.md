---
name: session-rollover
description: Use when the context budget hits WARN/STOP (hook message, `context-budget.sh` exit code 1/2, or the user asks) to roll work over to a fresh session via a deliberate, pruned handoff instead of uncontrolled automatic compaction. Rollover = reflect (route conversation-only learnings to disk) + flush (make disk fully current) + handoff (backward-looking handoff.md, forward-looking next-session.md) + bootstrap prompt.
---

# session-rollover

The session is approaching or past the **dumb zone** — the ~150K-token point where
LLM quality degrades regardless of advertised window size (see
`docs/context-budget.md`). Roll the work over to a fresh session *deliberately*:
decide what the next session loads, instead of letting automatic compaction decide.

Vendor-neutral: any agent runtime can follow these steps. Claude Code also exposes
this as the `/session-rollover` slash command (`.claude/commands/session-rollover.md`,
a thin wrapper around this skill).

## When to invoke

- **STOP** (tokens ≥ `CONTEXT_DUMB_ZONE_TOKENS`, exit code 2, or a hook STOP
  message): finish only the current *atomic step* — nothing new — then run this.
- **WARN** (exit code 1, or a hook WARN message): finish the current *work unit*,
  then run this before starting the next.
- The user asks to roll over / hand off to a fresh session.

Never roll over mid-atomic-step (half-written file, unresolved merge, mid-migration).

## Prerequisites

- `scripts/context-budget.sh` (measurement) — see `docs/context-budget.md`.
- The `handoff` skill (for the backward-looking doc) — see `docs/recommended-tooling.md`.

## Steps

1. **Record the trigger.** `scripts/context-budget.sh record --label "rollover start: <reason>"`.

2. **Reflect — route conversation-only learnings to disk.** Anything learned this
   session that lives only in conversation is unrecoverable after rollover. Route it
   now, per workspace convention: operational gotchas → `docs/operational-knowledge.md`;
   decisions with a rejected alternative → `work/<project-name>/decisions.md` (the
   `decision-log` skill); durable reference facts → the matching doc under `docs/`,
   with `repo/path:line` pointers where code-derived.

3. **Flush — make disk fully current.** Update state/tracker files the session was
   maintaining; run `git status` in every touched repo; commit per convention or
   explicitly note uncommitted work in the handoff; verify any sub-agent-claimed
   outputs actually exist on disk (summaries are hints, not facts).

4. **Write `work/<project-name>/handoff.md`** — *backward-looking*: what happened,
   what shipped, where things stand. Invoke the `handoff` skill (secret-free);
   persist its output here.

5. **Write `work/<project-name>/next-session.md`** — *forward-looking and
   deliberately pruned*:
   - **Mission** — the goal, one paragraph.
   - **Read these, in order** — the *smallest sufficient* set of file pointers.
   - **Do NOT reload** — settled side quests and dead ends, each with a one-line
     why, so the next session doesn't re-litigate them.
   - **State snapshot** — branch, uncommitted work, running processes, open items.
   - **First actions** — step 1 is always `scripts/context-budget.sh register`;
     then the concrete next steps.

6. **Emit the bootstrap prompt** for the user to paste into the fresh session, in a
   fenced block, e.g.:

   > Read `work/<project-name>/next-session.md` and continue from **First actions**.
   > Governing skill: `skills/<skill>/SKILL.md`.

7. **Record completion.** `scripts/context-budget.sh record --label "rollover complete: <project>"`.

## Guardrails

- **Specialized workflow state files win.** If a skill (onboard-repo, rlm, …) keeps
  its own state/handoff files, they stay authoritative — `next-session.md` carries
  thin pointers to them, never a fork of their content.
- Prefer **file pointers over content summaries** — a summary spends the next
  session's budget on possibly-stale prose; a pointer lets it demand-load.
- **No secrets** in any rollover artifact.
- If no `work/<project-name>/` directory fits the current work, ask the user where
  to persist rather than inventing a location.

## Outputs

- Ledger entries bracketing the rollover (`work/context-decay/context-ledger.jsonl`).
- Learnings routed to their workspace homes; disk fully current.
- `work/<project-name>/handoff.md` and `next-session.md`.
- A paste-ready bootstrap prompt.

End by telling the user: start a fresh session (don't `/compact` — rollover replaces
compaction) and paste the bootstrap prompt.
