# Catchup prompt — Clear Session Loop (paste into a new agent session)

We're resuming clear-session-loop. Works in any runtime (Claude Code, Codex, Gemini,
OpenCode) — all read `CONTEXT.md` via their entrypoint.

> **This file is the LAUNCHER (catch-up prompt).** Forward-only, and REPLACED
> at each rollover: it holds what to do next, still-binding constraints, and
> pointers — never session history. Past-tense provenance lives in
> `handoff.md` (the append-only ledger). Convention:
> docs/work-directory-conventions.md.

## >>> START HERE <<<

Spec approved (three fixes). S13 shipped, S4 retired. Left: the S14 probe
(two runs) and S15 docs. The human follows `s14-runbook.md`; this session must
be started by hand, **not** under `session-loop.sh` (`--clear` refuses there).

## First actions

1. `scripts/context-budget.sh register --project clear-session-loop` (skip if
   the SessionStart hook already bound this item). If `TF_SESSION_LOOP=1` is
   set, stop and tell the user to restart with plain `claude` (runbook §0).
2. **If this context opened with a seeded rollover prompt after `/clear`**
   (session #6 or #7): first record the probe run in `probes.md` — table
   `run | date | claude version | turn started without typing? (PASS/FAIL) | first tool call | evidence`.
   PASS if your first turn began with no user message; FAIL if the user's
   first message says so. Run 2 recorded → do S15 (spec §4) for the result,
   then close the item (README success criteria, `work/README.md` row).
3. Session #5 only: add a `docs/template-workspace-backlog.html` entry for S13
   shipped / S4 retired (targeted grep; never load the file whole), and add
   `s14-runbook.md` and `probes.md` to README "Files".
4. Roll over with `--clear` (not `--emit`): write the ledger block, replace
   this launcher (keep START HERE pointing at the next probe run), commit, then
   `scripts/launch-next-session.sh clear-session-loop --clear`, and tell the
   user to follow runbook §2.

## Constraints already decided (do not re-litigate)

- Scope: S13 (done), S14/S15 only; S4 retired (`decisions.md`).
- Non-Claude runtimes keep the fresh-process path.
- Markdown is the source of truth; HTML twins are reading copies.

## Read these first, in order

1. `work/clear-session-loop/handoff.md` (top block)
2. `work/clear-session-loop/spec.md` §4 (S14/S15)
3. `work/clear-session-loop/s14-runbook.md`
