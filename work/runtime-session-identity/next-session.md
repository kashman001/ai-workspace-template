# Catchup prompt — Runtime Session Identity (paste into a new agent session)

We're resuming runtime-session-identity. Works in any runtime (Claude Code, Codex, Gemini,
OpenCode) — all read `CONTEXT.md` via their entrypoint.

> **This file is the LAUNCHER (catch-up prompt).** Forward-only, and REPLACED
> at each rollover: it holds what to do next, still-binding constraints, and
> pointers — never session history. Past-tense provenance lives in
> `handoff.md` (the append-only ledger). Convention:
> docs/work-directory-conventions.md.

## Mission

Plan `02-copilot-vscode-followups`, wave 4 (the last). Node 11 (review) is done (f87afb0). What is left:
node 10, the user's live re-probe, and then node 12 (reconcile w4), which closes the plan.

## >>> START HERE <<<

**First actions:**

1. `scripts/context-budget.sh register --project runtime-session-identity`
2. `scripts/plan.sh status --project=runtime-session-identity`. If node 10 is still todo, re-post the
   node 10 instructions below and stop.
3. If node 10 is done or dropped: `scripts/plan.sh start 12-reconcile-w4 --project=runtime-session-identity`,
   read the node, and run it (see the `plan` skill's reconcile procedure). Note: f87afb0 (the node 11
   fix) is not in the probe clone. It does not change node 10's pass criteria, because a
   session-state artifact still files as copilot-cli.

**Node 10 — for the user (hitl), in the probe clone `~/Developer/experiments/ws-identity-probe-s9`
(at 7b18ce1, which has the node 07 and 08 fixes):** open two new Copilot chats in VS Code, with fresh
labels. In each chat, have the agent run
`scripts/context-budget.sh register --runtime copilot-vscode` on turn 1, then
`scripts/context-budget.sh check` on turn 2. Paste the raw `runtime=` lines and
`ls .context-budget/sessions/`. Pass: one `copilot-cli-<sid>.json` per chat, no `copilot-vscode-*` and
no `claude-*` record, turn 2 `method=exact`. Then `plan.sh done 10-live-reprobe-vscode --by human
--project=runtime-session-identity` (or `drop`).

**No human in the loop:** never run node 10 yourself. Also open for the user,
not urgent: turn 1 of a Copilot VS Code chat is always an estimate (~30% low). Document it or accept it
(`plan.md` → "Not yet specified").

## Read these, in order

1. Top block of `handoff.md`
2. Node `plans/02-copilot-vscode-followups/nodes/12-reconcile-w4.md`
3. Node 11's Log (findings F1–F7)

## Do NOT reload

- Nodes 01–09 and 11: verified and committed. Their Logs hold the evidence (node 11's Log lists the review findings).
- Probe write-ups (`probes/*.md`): the notes cite what they need.
- The probe clone's vendor-hooks J1d failure: it comes from the uncommitted probe wrappers, and a clean HEAD passes (node 09 Log).

## Constraints already decided (do not re-litigate)

- Fixes must be agent-agnostic, proven by a suite case that fails before the fix.
- Hook fan-out: keep all four hook files; the dispatcher's session-state path test is the gate.
- Registry: one name per Copilot session on the CLI runtime, copilot-cli (shipped 6c5ae3a).
- Pid-walk is out for identifying a session; liveness never relies on pid.
- Never probe in the workspace itself; use a clone.
- Pushing `main` is the user's call.

## Plan position

<!-- plan:begin position -->
Position: plan 02-copilot-vscode-followups, open, wave 4 of 4, done 11/12, doing 0, todo 1, blocked 0, dropped 0, sessions 4.
Frontier: 12-reconcile-w4. Remaining: 1 of 12 — wave 4: 12-reconcile-w4 todo.
<!-- plan:end position -->

## State snapshot

- Branch `main`: s14 commit f87afb0 plus the s14 rollover commit. Not pushed.
- Probe clone at 7b18ce1. Its probe hook wrappers are uncommitted on purpose.
- Other sessions commit in this checkout at the same time: commit by path (zsh: use an array), and
  never stage their files.
