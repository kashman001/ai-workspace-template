# Catchup prompt — Runtime Session Identity (paste into a new agent session)

We're resuming runtime-session-identity. Works in any runtime (Claude Code, Codex, Gemini,
OpenCode) — all read `CONTEXT.md` via their entrypoint.

> **This file is the LAUNCHER (catch-up prompt).** Forward-only, and REPLACED
> at each rollover: it holds what to do next, still-binding constraints, and
> pointers — never session history. Past-tense provenance lives in
> `handoff.md` (the append-only ledger). Convention:
> docs/work-directory-conventions.md.

## >>> START HERE <<<

**First actions:** `scripts/context-budget.sh register --project runtime-session-identity`, then:

0. **Antigravity CLI probe** (agent, no human needed): item 2 below. Do it first.

**No human in the loop:** do item 0 and item 2, commit, then stop with items 1 and 3 waiting on the user's IDE probes. Do not create the plan without the IDE results.

The CLI probes are done; `findings.md` has the results table and a draft plan (nodes 1–8).

1. **IDE probes (user).** If the user says "IDE probes done", read
   `~/Developer/experiments/ws-identity-probe/probe-out/{env.log,hook-*.log}`
   and write `probes/codex-vscode.md` and `probes/copilot-vscode.md` in the
   Q1–Q4 format the CLI probe files use. Still open with the user: whether
   to include the Codex desktop app (not installed).
2. **Antigravity CLI probe (agent).** Antigravity replaces Gemini (user
   decision). It has NO adapter row, hook wiring or measurer today: a new
   runtime. First find out how `agy` works: hooks? a session-id env var?
   where transcripts live (`~/.gemini/antigravity-cli/`)? Then run Q1–Q4 in a
   scratch clone → `probes/antigravity-cli.md`. Draft-plan node 6 (Gemini)
   becomes "Antigravity: add as a runtime".
3. Turn `findings.md` → "Gaps" into the plan with `/plan` (skills/plans/SKILL.md),
   adding the IDE-driven nodes (5 and 8).

## Constraints already decided (do not re-litigate)

- Probes run in a scratch `git clone`, never this checkout or a worktree.
- Measure first, then plan: no fix lands before its surface's probe.
- Probe Copilot with its own `COPILOT_HOME` that trusts only the clone, so the
  user's `~/.copilot` trust list stays untouched (see `probes/copilot-cli.md`).

## Read these first, in order

1. `work/runtime-session-identity/README.md`
2. `work/runtime-session-identity/findings.md`
3. `work/runtime-session-identity/handoff.md` (top block)
