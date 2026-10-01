# Catchup prompt — plans (paste into a new agent session)

We're resuming `plans`. Works in any runtime (Claude Code, Codex, Gemini,
OpenCode) — all read `CONTEXT.md` via their entrypoint.

> **This file is the LAUNCHER (catch-up prompt).** Forward-only, REPLACED at
> each rollover: what to do next, still-binding constraints, pointers — never
> session history. Past-tense provenance lives in `handoff.md` (the ledger).
> Convention: docs/work-directory-conventions.md.

## Mission — tickets 14–15, hands-off

Tickets 01–13 are `done` (13 closed 2026-09-30, s18). Remaining, in order:
**14** `plan.sh` ergonomics (four sub-items a–d) → **15** docs and skill
wording (includes the L48 recipe, plus the single `TEMPLATE_VERSION` bump
deferred from 12). Nobody is watching: do not stop with a question; make the
call, record it as a Tier-2 note.

## First actions

1. `scripts/context-budget.sh register --project plans` (expect `seq=19`).
2. Take the lowest open ticket under `issues/` (14 first). Per ticket: note
   first (a failing test or fixture), fix second, suites third, then flip its
   `Status:` to `done` with date + session, tick its boxes, commit with a
   `Decision:` trailer. `record --label` after each ticket.
3. Budget: 14 is one session; 15 is small. At WARN, or when the
   next ticket will not fit, roll over `--loop-mode handsoff`.
4. After 15: bump `TEMPLATE_VERSION` (plus its backlog changelog row), README
   status line ("tickets 01–15 done"), `work/README.md` row, then
   `checkpoint`. No successor; the item is finished.

## Read these, in order (keep it lean)

1. The ticket you are on (`issues/NN-*.md`) — it names its sources.
2. The finding it cites in `decisions.md` (grep the session tag, e.g. `s15`).
3. Only the code the ticket touches: `scripts/plan.sh`, `scripts/session-loop.sh`,
   `skills/plans/SKILL.md`, `docs/plans.md`, and
   their suites under `scripts/tests/`.

## Do NOT reload

- `concept.md`, `seams.md`, `spec.md`, tickets 01–13, `handoff.md` beyond the
  top block, anything under `work/jev-integration/` (its own plan
  `02-follow-on` runs under its own supervisor; never touch it from here).

## Still binding

- No concrete model name anywhere. Nothing pushed to origin — report how far
  ahead main is.
- Suites stay green (run the two `.sh` suites with `bash`; they are not
  executable): `scripts/tests/test-plan.sh` (243),
  `test-session-loop.sh` (144), `test-doc-consistency.sh` (17),
  `test-template-version.sh` (9), `test-check-ledger.py` (29); counts rise
  only by tests you add.
- Plan vocabulary says "work item", never "worktree".
- After any ledger write: `scripts/check-ledger.py work/plans` exits 0.
- An uncommitted edit to `work/jev-integration/next-session.md` belongs to
  that item's session; never stage it (`git add work/plans …` only).

## State snapshot

Branch `main`; nothing pushed. Tickets 01–13 `done`; 14–15
`ready-for-agent`. Ledger TOP block = session 18 (blocks 11–16 archived).
`TEMPLATE_VERSION` = 2026-09-24, bump once at ticket 15.
