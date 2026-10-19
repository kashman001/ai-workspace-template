# Catchup prompt — Runtime Session Identity (paste into a new agent session)

We're resuming runtime-session-identity. Works in any runtime (Claude Code, Codex, Gemini,
OpenCode) — all read `CONTEXT.md` via their entrypoint.

> **This file is the LAUNCHER (catch-up prompt).** Forward-only, and REPLACED
> at each rollover: it holds what to do next, still-binding constraints, and
> pointers — never session history. Past-tense provenance lives in
> `handoff.md` (the append-only ledger). Convention:
> docs/work-directory-conventions.md.

## Mission

Plans 01 and 02 are both closed. No agent work is queued. Two calls are left, both the user's:

1. **Turn-1 estimate gap.** In a Copilot VS Code chat, turn 1 is always `method=estimate`, about 22–30%
   low (s12: 29,783 vs 42,654; s14: 33,151 vs 42,785). `prompt_tokens` first appears at turn end.
   Options: document it in `docs/context-budget.md` (Copilot VS Code row), or accept it as is.
   Recorded in plan 02's `plan.md` → "Not yet specified".
2. **Push `main`.** Never push from a session; report how far ahead `main` is.

## >>> START HERE <<<

**First actions:**

1. `scripts/context-budget.sh register --project runtime-session-identity`
2. Ask the user about item 1 above, if they have not answered yet. If they pick "document": add one
   sentence to the Copilot VS Code row, run `scripts/tests/test-doc-consistency.sh`, and commit by path.
3. With nothing left open, close the work item: run `checkpoint` (or tell the user it is ready to archive).

## Read these, in order

1. Top block of `handoff.md`

## Do NOT reload

- Plans 01 and 02: closed, each node verified. Node Logs hold the evidence.
- Probe write-ups (`probes/*.md`).

## Constraints already decided (do not re-litigate)

- Fixes must be agent-agnostic, proven by a suite case that fails before the fix.
- Registry: one name per Copilot session on the CLI runtime, copilot-cli, keyed on the session-state
  transcript path (f87afb0).
- Never probe in the workspace itself; use a clone (`~/Developer/experiments/ws-identity-probe-s9`).
- Pushing `main` is the user's call.

## Plan position

<!-- plan:begin position -->
Position: plan 02-copilot-vscode-followups, closed, wave 4 of 4, done 12/12, doing 0, todo 0, blocked 0, dropped 0, sessions 4.
Frontier: none. Remaining: 0 of 12.
<!-- plan:end position -->

## State snapshot

- Branch `main`: s14 commits f87afb0, 7c56d05, 8194288 and the s14 close commit. Not pushed.
- Other sessions commit in this checkout at the same time: commit by path (zsh: use an array).
