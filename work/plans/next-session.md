# Catchup prompt — plans (paste into a new agent session)

We're resuming `plans`. Works in any runtime (Claude Code, Codex, Gemini,
OpenCode) — all read `CONTEXT.md` via their entrypoint.

> **This file is the LAUNCHER (catch-up prompt).** Forward-only, REPLACED at
> each rollover: what to do next, still-binding constraints, pointers — never
> session history. Past-tense provenance lives in `handoff.md` (the ledger).
> Convention: docs/work-directory-conventions.md.

## Mission — tickets 12–15, hands-off

Tickets 01–11 are `done` (11 closed 2026-09-30; L48 verdict in
`decisions.md`). What remains is fixing the dogfood findings, in order:
**12** ledger lint gap → **13** default plan is the open one (a real bug in
`plan.sh` and `session-loop.sh`) → **14** `plan.sh` ergonomics → **15** docs
and skill wording (includes the L48 recipe). Nobody is watching: do not stop
with a question; make the call, record it as a Tier-2 note.

## First actions

1. `scripts/context-budget.sh register --project plans` (expect `seq=17`).
2. Take the lowest open ticket under `issues/` (12 first). Per ticket: note
   first (a failing test or fixture), fix second, suites third, then flip its
   `Status:` to `done` with date + session, tick its boxes, commit with a
   `Decision:` trailer. `record --label` after each ticket.
3. Budget: one ticket per session is the realistic size for 13 and 14; 12 and
   15 are small. At WARN, roll over `--loop-mode handsoff`.
4. After 15: README status line ("tickets 01–15 done"), `work/README.md` row,
   then `checkpoint` — no successor; the item is finished.

## Read these, in order (keep it lean)

1. The ticket you are on (`issues/NN-*.md`) — it names its sources.
2. The finding it cites in `decisions.md` (grep the session tag, e.g. `s18`).
3. Only the code the ticket touches: `scripts/plan.sh`, `scripts/session-loop.sh`,
   `scripts/check-ledger.py`, `skills/plans/SKILL.md`, `docs/plans.md`, and
   their suites under `scripts/tests/`.

## Do NOT reload

- `concept.md`, `seams.md`, `spec.md`, tickets 01–11, `handoff.md` beyond the
  top block, anything under `work/jev-integration/` (its own plan
  `02-follow-on` runs under its own supervisor; never touch it from here).

## Still binding

- No concrete model name anywhere. Nothing pushed to origin — report how far
  ahead main is.
- Suites stay green: `scripts/tests/test-plan.sh` (238),
  `test-session-loop.sh` (140), `test-doc-consistency.sh` (17),
  `test-template-version.sh` (9); counts rise only by tests you add.
- Plan vocabulary says "work item", never "worktree".
- After any ledger write: `scripts/check-ledger.py work/plans` exits 0.
- An uncommitted edit to `work/jev-integration/next-session.md` belongs to
  that item's session; never stage it (`git add work/plans …` only).

## State snapshot

Branch `main`; nothing pushed. Tickets 01–11 `done`; 12–15
`ready-for-agent`. Ledger TOP block = session 16. `TEMPLATE_VERSION` =
2026-09-24 (bump only if a ticket changes shipped template files).
