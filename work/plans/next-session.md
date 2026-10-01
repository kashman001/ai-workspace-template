# Catchup prompt — plans (paste into a new agent session)

> **This file is the LAUNCHER (catch-up prompt).** Forward-only, REPLACED at
> each rollover. Past-tense provenance lives in `handoff.md` (the ledger).
> Convention: docs/work-directory-conventions.md.

## Status — finished (2026-09-30, session 19)

Tickets 01–15 are done; L48 is archived; `TEMPLATE_VERSION` = 2026-09-30.
Nothing is queued. Start no session here unless there is a new plans finding.

## If a new finding arrives

1. `scripts/context-budget.sh register --project plans`.
2. Append it to `decisions.md` → "Dogfood findings", then open a ticket
   under `issues/` (next number) and work it test-first, as tickets 12–15 did.

## Still binding

- No concrete model name anywhere; nothing pushed by a session.
- Plan vocabulary says "work item", never "worktree".
- After any ledger write: `scripts/check-ledger.py work/plans` exits 0.
- Never touch `work/jev-integration/` from here.
