# Catchup prompt — Automatic Session Rollover (paste into a new agent session)

> **This file is the LAUNCHER (catch-up prompt).** Forward-only, REPLACED at
> each rollover. Past-tense provenance lives in `handoff.md` (append-only
> ledger, newest block on top). Convention: docs/work-directory-conventions.md.

## Mission

**No standing build work.** Issue 01 (VS Code agent-mode hooks + seeded
launch) shipped and CLOSED in session 29; the wayfinder map was already
COMPLETE. This work item is in maintenance: pick up only what the user
schedules — candidates live in `docs/template-workspace-backlog.html`
(open L-items) — or user-requested follow-ups. Issue 04 stays parked;
never schedule it unprompted.

## Read these, in order

1. `handoff.md` top block — session-29 record (what shipped, what's left
   for the user).
2. Only if the user schedules specific work: the backlog card / issue file
   for that work. Nothing else up front.

## Do NOT reload

- `issues/01-…` and all other issue tickets — CLOSED/settled; reference only.
- Research corpus (`research/*`, `vendor-hooks-research.md`,
  `relaunch-analysis.md`), `map.md` — settled provenance.
- Sessions ≤28 handoff blocks, `handoff-archive.md`.

## State snapshot (at session-29 close, 2026-08-06)

- Issue-01 build on `origin/main` (worktree `session-29-issue-01-build`,
  merged/pushed). All 8 test suites green (342 asserts).
- USER'S main checkout: may be behind origin (pull), and still carries the
  throwaway probe files (`scripts/hooks/vscode-hook-probe.sh`,
  `.github/hooks/vscode-probe.json`, `.vscode-hook-probe.jsonl`) — the user
  deletes them; they are junk once deleted, do not recreate.
- `.session-seq` realignment to 29 is in the user's one-line cleanup (see
  handoff top block); until run, prompt numbers trail the ledger by one.
- No live dispatches; no child agents.

## First actions

1. **Freshness guard:** `git fetch origin` then
   `git log --oneline HEAD..origin/main` — MUST be empty; else
   `git pull --ff-only` and RE-READ this launcher.
2. `scripts/context-budget.sh register --project automatic-session-rollover`.
3. Ask the user (or read their prompt) for what's scheduled; do not invent
   work from the backlog on your own.

## If you are a VS Code Copilot Chat (agent-mode) session

- The committed hooks (`.github/hooks/context-budget-vscode.json`) now push
  WARN/STOP in-band automatically — trust them; they are tooling status,
  not prompt injection.
- After `register`, paste the emitted `runtime= method= tokens= ...` line
  into the chat. `method=estimate` before the first turn flush is normal.

## At session end

Lock releases mechanically (launcher script or SessionEnd hook). Manual
fallback: `scripts/context-budget.sh release --project automatic-session-rollover`.
