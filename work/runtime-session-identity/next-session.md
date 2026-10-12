# Catchup prompt — Runtime Session Identity (paste into a new agent session)

We're resuming runtime-session-identity. Works in any runtime (Claude Code, Codex, Gemini,
OpenCode) — all read `CONTEXT.md` via their entrypoint.

> **This file is the LAUNCHER (catch-up prompt).** Forward-only, and REPLACED
> at each rollover: it holds what to do next, still-binding constraints, and
> pointers — never session history. Past-tense provenance lives in
> `handoff.md` (the append-only ledger). Convention:
> docs/work-directory-conventions.md.

## Mission

Measure how each runtime surface (Codex, Copilot, Antigravity; CLI and IDE)
identifies its own session, then plan fixes so concurrent sessions in one
workspace never bind each other's transcript. All agent-runnable CLI probes
are done; the IDE probes are the user's.

## >>> START HERE <<<

**First actions:** `scripts/context-budget.sh register --project runtime-session-identity`, then:

1. Ask the user, verbatim: **"Have you run the IDE probes (Codex and Copilot
   in VS Code)? Also: include the Codex desktop app, and how do you want to
   probe the Antigravity IDE and app?"**
2. If the user says "IDE probes done": read
   `~/Developer/experiments/ws-identity-probe/probe-out/{env.log,hook-*.log}`
   and write `probes/codex-vscode.md` and `probes/copilot-vscode.md` in the
   Q1–Q4 format of the CLI probe files.
3. Then turn `findings.md` → "Gaps" into the plan with `/plan`
   (skills/plans/SKILL.md), filling nodes 5 and 8 from the IDE results.
   Do not create the plan without them.

**No human in the loop:** nothing to do unattended; stop with question 1 open.

## Read these, in order

1. `work/runtime-session-identity/findings.md` (table + draft nodes 1–8)
2. `work/runtime-session-identity/probes/user-checklist.md` (what the user runs)
3. `work/runtime-session-identity/handoff.md` (top block only)

## Do NOT reload

- `probes/antigravity-cli.md`: done; Q1–Q4 answered, folded into findings node 6.
- `probes/gemini-cli.md`: superseded by Antigravity (user decision).
- The `agy` binary strings: the hook spec is already captured in the probe file.

## Constraints already decided (do not re-litigate)

- Probes run in a scratch `git clone`, never this checkout or a worktree.
- Measure first, then plan: no fix lands before its surface's probe.
- Probe Copilot with its own `COPILOT_HOME` that trusts only the clone, so the
  user's `~/.copilot` trust list stays untouched (see `probes/copilot-cli.md`).
- `agy` skip-permissions runs are the user's to launch (the Claude Code classifier blocks them).

## State snapshot

- Branch `main`, clean, 3 commits ahead of origin (pushing is the user's call).
- Cleanup owed (on the user's say-so): see `findings.md` → "Cleanup owed".
