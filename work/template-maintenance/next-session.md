> **This file is the LAUNCHER (catch-up prompt).** Forward-only, and REPLACED
> at each rollover: it holds what to do next, still-binding constraints, and
> pointers — never session history. Past-tense provenance lives in `handoff.md`
> (the append-only ledger). Convention: docs/work-directory-conventions.md.

## Mission

**Fix L37 — portable agent brief** (last card of the house-sale mission;
M26 and L36 shipped in session #4). Card: grep `id">L37` in
`docs/template-workspace-backlog.html`. Shape per the card's Fix line: a
lightweight convention (or a small `portable-brief` skill) for exporting
workspace state to an out-of-workspace agent — a sealed, dated,
self-contained brief with a supersession header, an explicit
never-reveal/redaction section, and a ledger note recording when a brief was
issued and when it went stale; documented in
`docs/work-directory-conventions.md` next to the dispatch-record pattern.
Convention-vs-skill is an open design call — default to the leaner
convention-only form (simplicity-first; a skill can be promoted later if the
pattern recurs), record a Tier-2 note either way. Resolve the card with a `Fixed:` note → archive (Low section,
before `<h2>Decisions</h2>`), scorecard 2→1 Open / 65→66 Resolved.

## Read these, in order

1. `work/template-maintenance/handoff.md` (top block) — what session #4 shipped.
2. The L37 card (targeted grep, never the whole backlog file).
3. `docs/work-directory-conventions.md` — the dispatch-record section the
   convention slots next to.
4. `skills/writing-for-agents` (or the global copy) before authoring the text.

## Do NOT reload

- M26/L36 details — resolved cards in the backlog archive; don't re-open.
- The house-sale evidence pass — its conclusions are the three filed cards;
  the pass itself lives in devex-review history.
- The 2026-08-06 context-audit thread (optional empty-session-floor trim) —
  parked, awaiting user appetite; numbers in `handoff-archive.md`.
- `docs/context-budget.md` whole-file — grep the section header you need.

## State snapshot

- Branch `main`, clean except untracked `work/kimi-k3-agent-integration/`
  (another session's item — leave it). Local main is **ahead of origin**
  (M26 `208a228`, L36 `405810b`, plus the session-4 rollover commit) — push
  when the user wants.
- Backlog: 2 Open — M16 (out of mission scope), L37.
- Vendored skill pins unchanged: `wayfinder`/`writing-for-agents` at
  upstream `8b36d4f`.

## First actions

1. `scripts/context-budget.sh register` (skip if the Claude Code
   SessionStart hook already ran it).
2. Work L37 per the Mission above.
