# Catchup prompt — Clear Session Loop (paste into a new agent session)

We're resuming clear-session-loop. Works in any runtime (Claude Code, Codex, Gemini,
OpenCode) — all read `CONTEXT.md` via their entrypoint.

> **This file is the LAUNCHER (catch-up prompt).** Forward-only, and REPLACED
> at each rollover: it holds what to do next, still-binding constraints, and
> pointers — never session history. Past-tense provenance lives in
> `handoff.md` (the append-only ledger). Convention:
> docs/work-directory-conventions.md.

## >>> START HERE <<<

You were reached by `/clear` (probe **run 1**; record seq 5, the runbook's "#6"). Record the run,
then roll over with `--clear` again for probe **run 2**. The human follows
`s14-runbook.md` §2–3. Not under `session-loop.sh`.

## First actions

1. `scripts/context-budget.sh register --project clear-session-loop` (skip if
   the SessionStart hook already bound this item). If `TF_SESSION_LOOP=1` is
   set, stop and tell the user to restart with plain `claude` (runbook §0).
2. Create `work/clear-session-loop/probes.md` with a table
   `run | date | claude version (claude --version) | turn started without typing? (PASS/FAIL) | first tool call | evidence`
   and record **run 1**. PASS if your first turn began with no user message;
   FAIL if the user's first message says so (quote it as evidence).
3. Roll over with `--clear` (not `--emit`): write the ledger block (keep only
   the two newest blocks in `handoff.md`; archive the rest, newest on top),
   replace this launcher for the next session (START HERE: record **run 2**, then do
   S15 per spec §4 for the combined result and close the item — README
   success criteria, `work/README.md` row), commit, run
   `scripts/launch-next-session.sh clear-session-loop --clear`, and tell the
   user to follow runbook §3.
   If it refuses `chain_closed`, clear `.chain.closed` with jq as the previous
   session did (backlog L91) and log it.

## Constraints already decided (do not re-litigate)

- Scope: S13 (done), S14/S15 only; S4 retired (`decisions.md`).
- Non-Claude runtimes keep the fresh-process path.
- Markdown is the source of truth; HTML twins are reading copies.
- Pushing `main` is the user's call; commit locally only.

## Read these first, in order

1. `work/clear-session-loop/handoff.md` (top block)
2. `work/clear-session-loop/s14-runbook.md`
3. `work/clear-session-loop/spec.md` §4 (S14/S15) — only when doing S15
