# Catchup prompt — Concurrent Sessions (paste into a new agent session)

We're resuming concurrent-sessions. Works in any runtime (Claude Code, Codex,
Gemini, OpenCode) — all read `CONTEXT.md` via their entrypoint.

> **This file is the LAUNCHER (catch-up prompt).** Forward-only, and REPLACED
> at each rollover: it holds what to do next, still-binding constraints, and
> pointers — never session history. Past-tense provenance lives in
> `handoff.md` (the append-only ledger). Convention:
> docs/work-directory-conventions.md.

## >>> START HERE <<<

Objective: research whether several sessions can own parts of one work item
at the same time (README → "Success criteria").

1. `scripts/context-budget.sh register --project concurrent-sessions` (skip if
   the SessionStart hook already bound this item).
2. Ask the user what they want concurrency *for* (one question at a time): a
   use case that subagents under one owner do not cover is the research's
   anchor. If they have none, say so and suggest closing the item.
3. Draft `research.md`. Start from `work/clear-session-loop/research.md`
   §6 "The headline question" and §7 D — they list the one-owner assumptions
   (record `session`/`seq`, ledger prepend race, single launcher front,
   `plan.sh start` without compare-and-set, one supervisor child). Re-read each
   cited line before relying on it.
4. Spot-check the claims, write the Verification section, render
   `research.html`, then pause for the user's review.

## Constraints already decided (do not re-litigate)

- Independent of `/clear`: a clear chain is one process, one owner
  (`work/clear-session-loop/research.md` §6).
- Markdown is the source of truth; HTML twins are reading copies.

## Read these first, in order

1. `work/concurrent-sessions/README.md`
2. `work/concurrent-sessions/handoff.md` (top block)
3. `work/clear-session-loop/research.md` §6 and §7 D only
