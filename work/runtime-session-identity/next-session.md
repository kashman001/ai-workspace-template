# Catchup prompt — Runtime Session Identity (paste into a new agent session)

We're resuming runtime-session-identity. Works in any runtime (Claude Code, Codex, Gemini,
OpenCode) — all read `CONTEXT.md` via their entrypoint.

> **This file is the LAUNCHER (catch-up prompt).** Forward-only, and REPLACED
> at each rollover: it holds what to do next, still-binding constraints, and
> pointers — never session history. Past-tense provenance lives in
> `handoff.md` (the append-only ledger). Convention:
> docs/work-directory-conventions.md.

## Mission

**Finished (s14, 2026-10-18).** Plans 01 and 02 are closed and every user call is made. No work is
queued. Reopen only for a new Copilot surface or a registry regression; the surfaces never probed
are backlog L86.

## >>> START HERE <<<

**First actions:** none. If reopened, read the top block of `handoff.md`, then start with
`superpowers:brainstorming`.

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
