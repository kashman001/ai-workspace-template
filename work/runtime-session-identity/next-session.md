# Catchup prompt — Runtime Session Identity (paste into a new agent session)

We're resuming runtime-session-identity. Works in any runtime (Claude Code, Codex, Gemini,
OpenCode) — all read `CONTEXT.md` via their entrypoint.

> **This file is the LAUNCHER (catch-up prompt).** Forward-only, and REPLACED
> at each rollover: it holds what to do next, still-binding constraints, and
> pointers — never session history. Past-tense provenance lives in
> `handoff.md` (the append-only ledger). Convention:
> docs/work-directory-conventions.md.

## Mission

Plan `02-copilot-vscode-followups`, wave 4 (the last). Run node 11: review the plan-02 work since
`816a7d9^`. Node 10 is the user's live re-probe and runs in parallel. Close with node 12 once
both are done.

## >>> START HERE <<<

**First actions:**

1. `scripts/context-budget.sh register --project runtime-session-identity`
2. `scripts/plan.sh start 11-review-plan-02 --project=runtime-session-identity`; read the node.
3. Run the `code-review` skill on `816a7d9^..HEAD`, filtered to plan-02 paths (`scripts/context-budget.sh`,
   `scripts/hooks/`, `.claude/settings.json`, `scripts/tests/test-context-budget-registry.sh`,
   `scripts/tests/test-vendor-budget-hooks.sh`, `docs/context-budget.md`). Other work items commit in
   this range. Spec = the two decided notes in `decisions.md` (node-02 and node-03, dated 2026-10-18).
4. List the findings in node 11's Log (write Log lines by hand; `plan.sh note` writes to plan.md).
   Fix each finding with a suite case seen red first, or add it as a node (`plan.sh add`). Suites:
   registry, vendor hooks, statusline, attach-session, doc-consistency. Commit by path.
5. If node 10 is done (`plan.sh status`), run node 12 (reconcile w4). Otherwise stop after node 11 and
   re-post the node 10 instructions below.

**Node 10 — for the user (hitl), in the probe clone `~/Developer/experiments/ws-identity-probe-s9`
(at 7b18ce1, which has the node 07 and 08 fixes):** open two new Copilot chats in VS Code, with fresh
labels. In each chat, have the agent run
`scripts/context-budget.sh register --runtime copilot-vscode` on turn 1, then
`scripts/context-budget.sh check` on turn 2. Paste the raw `runtime=` lines and
`ls .context-budget/sessions/`. Pass: one `copilot-cli-<sid>.json` per chat, no `copilot-vscode-*` and
no `claude-*` record, turn 2 `method=exact`. Then `plan.sh done 10-live-reprobe-vscode --by human
--project=runtime-session-identity` (or `drop`).

**No human in the loop:** do steps 1–4 unattended; never run node 10 yourself. Also open for the user,
not urgent: turn 1 of a Copilot VS Code chat is always an estimate (~30% low). Document it or accept it
(`plan.md` → "Not yet specified").

## Read these, in order

1. Top block of `handoff.md`
2. Node `plans/02-copilot-vscode-followups/nodes/11-review-plan-02.md`
3. The node-02 and node-03 notes in `decisions.md` (from line ~84)

## Do NOT reload

- Nodes 01–09: verified and committed. Their Logs hold the evidence.
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
Position: plan 02-copilot-vscode-followups, open, wave 4 of 4, done 9/12, doing 0, todo 3, blocked 0, dropped 0, sessions 3.
Frontier: 10-live-reprobe-vscode, 11-review-plan-02. Remaining: 3 of 12 — wave 4: 10-live-reprobe-vscode todo, 11-review-plan-02 todo, 12-reconcile-w4 todo.
<!-- plan:end position -->

## State snapshot

- Branch `main`: s13 commits 6c5ae3a plus the s13 rollover commit, on top of s12's. Not pushed.
- Probe clone at 7b18ce1. Its probe hook wrappers are uncommitted on purpose.
- Other sessions commit in this checkout at the same time: commit by path (zsh: use an array), and
  never stage their files.
