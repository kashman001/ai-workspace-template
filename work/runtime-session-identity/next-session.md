# Catchup prompt — Runtime Session Identity (paste into a new agent session)

We're resuming runtime-session-identity. Works in any runtime (Claude Code, Codex, Gemini,
OpenCode) — all read `CONTEXT.md` via their entrypoint.

> **This file is the LAUNCHER (catch-up prompt).** Forward-only, and REPLACED
> at each rollover: it holds what to do next, still-binding constraints, and
> pointers — never session history. Past-tense provenance lives in
> `handoff.md` (the append-only ledger). Convention:
> docs/work-directory-conventions.md.

## Mission

Plan `02-copilot-vscode-followups`, wave 2. The token fix shipped (3928a86). Now node 05 is the
user's: two decisions and one live VS Code check. Then node 06 turns the answers into a replan.

## >>> START HERE <<<

**First actions:**

1. `scripts/context-budget.sh register --project runtime-session-identity`
2. Read the two `PROPOSED` notes at the bottom of `decisions.md` (nodes 02 and 03), then node
   `plans/02-copilot-vscode-followups/nodes/05-approve-decisions.md`.
3. Walk the user through node 05 **one question at a time, plain language, options spelled out**
   (no jargon; explain "hook" / "registry record" in a sentence). Ask, in this order:
   - **Q1 (hook files).** "Copilot runs four sets of our budget hooks on each event, two of them
     meant for Claude Code. Only the right one acts; the other three already stand down. Keep it
     that way and add two small safety checks (recommended), delete the VS Code hook file, make
     the Claude hooks refuse by environment variable, or ask users to switch hooks off?"
   - **Q2 (duplicate records).** "A Copilot chat can end up with two bookkeeping records, but only
     when an agent passes `--runtime copilot-vscode` by hand. It can stop that chat from taking
     over its own work item. Always file it under one name, copilot-cli (recommended), just
     document the trap, look records up by session id everywhere, or file under copilot-vscode?"
   - **Q3 (live check).** Ask the user to open a new Copilot chat in VS Code in
     `~/Developer/experiments/ws-identity-probe-s9` (it has the fix, d93e71a) and have the agent
     run `scripts/context-budget.sh check`. Expect `method=exact`.
4. Record the answers in node 05's Log, tick its boxes, `scripts/plan.sh done 05-approve-decisions
   --by human`; flip the chosen notes from PROPOSED to decided. Then node 06: replan wave 3 with
   the delivery nodes (test-first, each fix with a suite case seen red).

## Read these, in order

1. Top block of `handoff.md`
2. The two PROPOSED notes in `decisions.md`
3. `plans/02-copilot-vscode-followups/nodes/05-approve-decisions.md`

## Do NOT reload

- Nodes 01–04 and their diffs: verified and committed; their Logs hold the evidence.
- Probe write-ups (`probes/*.md`): the notes cite what they need.
- Subagent sandbox `scratchpad/n03/sandbox.sh`: session-local, gone.

## Constraints already decided (do not re-litigate)

- Fixes must be agent-agnostic, proven by a suite case that fails before the fix.
- Pid-walk is out for identifying a session; liveness never relies on pid.
- Ambiguous discovery refuses on every command; the Copilot CLI hook config owns every Copilot payload.
- Never probe in the workspace itself; use a clone.
- Pushing `main` is the user's call.

## Plan position

<!-- plan:begin position -->
Position: plan 02-copilot-vscode-followups, open, wave 2 of 2, done 4/6, doing 0, todo 2, blocked 0, dropped 0, sessions 1.
Frontier: 05-approve-decisions. Remaining: 2 of 6 — wave 2: 05-approve-decisions todo, 06-reconcile-w2 todo.
<!-- plan:end position -->

## State snapshot

- Branch `main`, item commits 3928a86, c54c478, 4bc3579 + the s11 rollover commit; not pushed.
- Probe clone at d93e71a (fix cherry-picked); its probe hook wrappers are uncommitted on purpose.
- Other sessions commit in this checkout concurrently: commit by path, never stage their files.
