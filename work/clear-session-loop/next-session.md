# Catchup prompt — Clear Session Loop (paste into a new agent session)

We're resuming clear-session-loop. Works in any runtime (Claude Code, Codex, Gemini,
OpenCode) — all read `CONTEXT.md` via their entrypoint.

> **This file is the LAUNCHER (catch-up prompt).** Forward-only, and REPLACED
> at each rollover: it holds what to do next, still-binding constraints, and
> pointers — never session history. Past-tense provenance lives in
> `handoff.md` (the append-only ledger). Convention:
> docs/work-directory-conventions.md.

## >>> START HERE <<<

**This item is finished** (README → Status). There is no next step here. Do
not start a session on it unless the user reopens it.

## If reopened

- The one open follow-up is backlog card **L91** (reopen a closed chain
  without starting the supervisor) in `docs/template-workspace-backlog.html`.
  It is template work, not this item's scope; take it in its own work item or
  as a direct fix.
- A future claude version may start a cleared session on its own. To check,
  repeat the probe in `s14-runbook.md` and add rows to `probes.md`; two PASS
  runs would reverse S15 (`spec.md` §4).

## Constraints already decided (do not re-litigate)

- `/clear` rollover = press `/clear`, then type `go` (2 of 2 probes FAIL,
  claude 2.1.300). The bootstrap prompt text does not change (TADR-0003).
- Non-Claude runtimes keep the fresh-process path.
- Pushing `main` is the user's call; commit locally only.

## Read these first, in order

1. `work/clear-session-loop/README.md` (Status)
2. `work/clear-session-loop/handoff.md` (top block)
