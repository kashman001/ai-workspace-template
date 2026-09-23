# Catchup prompt — session-management-followups (paste into a new agent session)

We're resuming `session-management-followups`. Works in any runtime (Claude
Code, Codex, Gemini, OpenCode) — all read `CONTEXT.md` via their entrypoint.

> **This file is the LAUNCHER (catch-up prompt).** Forward-only, and REPLACED
> at each rollover: it holds what to do next, still-binding constraints, and
> pointers — never session history. Past-tense provenance lives in
> `handoff.md` (the append-only ledger). Convention:
> docs/work-directory-conventions.md.

## >>> START HERE <<<

Position: **item complete** (closed 2026-09-22 through the stop door, session
4). All three tickets under `issues/` are `done`: 01 in e7c2356 (M40), 02 in
8a14af3 (M41), 03 in 523bf54 (M42). Nothing to do unless a ticket reopens.

If one does:

1. `scripts/context-budget.sh register --project session-management-followups`
   (the counter mints the next number after the close).
2. Reopen the ticket file (`**Status:** todo`, untick the failed box), work it
   test-first per the ticket, land it with its backlog card (next free ID:
   check the open backlog's change log) and a Decision note where an
   alternative is rejected. One commit per ticket.
3. Ledger block on top of `handoff.md` (plain numbered form), keep two blocks,
   archive the third; `python3 scripts/check-ledger.py
   work/session-management-followups` exit 0; rewrite this launcher; end
   through the stop door (`scripts/context-budget.sh close`).

## Constraints already decided (do not re-litigate)

- Scope is tickets 01–03 only. Scaffolded lanes, human-only items, and parked
  items are out (README "What this is", categories 2–4).
- Ledger headings: one rule, `docs/work-directory-conventions.md` → Ledger
  ("One heading rule, two parsers"); the addendum form is grandfathered
  history, never written anew.
- `import-session-seq.sh` stays; it is the downstream migration tool.
- Ticket 01's readers live in `scripts/lib/session-lib.sh`;
  `context-budget.sh` keeps its own `owner_live()` (follow-up candidate,
  `decisions.md`).
- `TEMPLATE_VERSION` is the marker only; no upgrade tool. Its shape is an
  assumption the human may reverse (`decisions.md` top note).
- Do not push main; report how far ahead it is.

## Read these first, in order

1. `work/session-management-followups/README.md`
2. `work/session-management-followups/handoff.md` (top block)
