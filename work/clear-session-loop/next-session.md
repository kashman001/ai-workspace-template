# Catchup prompt — Clear Session Loop (paste into a new agent session)

We're resuming clear-session-loop. Works in any runtime (Claude Code, Codex, Gemini,
OpenCode) — all read `CONTEXT.md` via their entrypoint.

> **This file is the LAUNCHER (catch-up prompt).** Forward-only, and REPLACED
> at each rollover: it holds what to do next, still-binding constraints, and
> pointers — never session history. Past-tense provenance lives in
> `handoff.md` (the append-only ledger). Convention:
> docs/work-directory-conventions.md.

## >>> START HERE <<<

You were reached by `/clear` (probe **run 2**; record seq 6). Record the run,
then do S15 for the combined result and close the item. Not under
`session-loop.sh`. Run 1 was **FAIL** (`probes.md`).

## First actions

1. `scripts/context-budget.sh register --project clear-session-loop` (skip if
   the SessionStart hook already bound this item). If `TF_SESSION_LOOP=1` is
   set, stop and tell the user to restart with plain `claude` (runbook §0).
2. Add **run 2** to the table in `work/clear-session-loop/probes.md`. PASS if
   your first turn began with no user message; FAIL if the user's first
   message says so (quote it as evidence).
3. Do S15 per `spec.md` §4 for the combined result (run 1 FAIL + run 2):
   both FAIL (or mixed) → document "press `/clear`, then type `go`"; both
   PASS would be "verified" — not possible now that run 1 failed.
4. Close the item: tick README success criteria, update the
   `work/README.md` row, write the ledger block, then `checkpoint` (stop
   door, not a rollover). Commit locally; do not push.

## Constraints already decided (do not re-litigate)

- Scope: S13 (done), S14/S15 only; S4 retired (`decisions.md`).
- Non-Claude runtimes keep the fresh-process path.
- Markdown is the source of truth; HTML twins are reading copies.
- Pushing `main` is the user's call; commit locally only.

## Read these first, in order

1. `work/clear-session-loop/handoff.md` (top block)
2. `work/clear-session-loop/probes.md`
3. `work/clear-session-loop/spec.md` §4 (S14/S15)
