# Catchup prompt — Runtime Session Identity (paste into a new agent session)

We're resuming runtime-session-identity. Works in any runtime (Claude Code, Codex, Gemini,
OpenCode) — all read `CONTEXT.md` via their entrypoint.

> **This file is the LAUNCHER (catch-up prompt).** Forward-only, and REPLACED
> at each rollover: it holds what to do next, still-binding constraints, and
> pointers — never session history. Past-tense provenance lives in
> `handoff.md` (the append-only ledger). Convention:
> docs/work-directory-conventions.md.

## Mission

Plan `02-copilot-vscode-followups`, wave 3. Node 07 shipped (34c76b4). Build node 08 test-first:
one registry name per Copilot session (copilot-cli), then reconcile wave 3 (node 09) and stage the
user's live re-probe (node 10).

## >>> START HERE <<<

**First actions:**

1. `scripts/context-budget.sh register --project runtime-session-identity`
2. `scripts/plan.sh start 08-canonical-copilot-registry-name --project=runtime-session-identity`,
   read that node (Goal + Acceptance) and the decided node-03 note in `decisions.md`
   ("One registry name per Copilot session").
3. TDD: add the registry case first (`scripts/tests/test-context-budget-registry.sh`, near H2 ~:763):
   `register --runtime copilot-vscode` on a session-state `events.jsonl`, then the auto copilot-cli
   register → one `copilot-cli-<sid>.json` record, no `owner_live`. See it red. Then the one guard in
   `scripts/context-budget.sh` (the runtime resolution), update H2 and `probes/probe-env.sh`, keep a
   chatSessions-artifact case filing as `copilot-vscode`, note it in `docs/context-budget.md`.
4. Suites: registry, vendor hooks, statusline, attach-session, doc-consistency. Commit by path.
5. Node 09 reconcile: verify 07 + 08 on disk; cherry-pick both code commits into the probe clone
   `~/Developer/experiments/ws-identity-probe-s9` (`git rm` conflicting `work/` files, `--continue`).
6. Node 10 is the user's (hitl): two new VS Code Copilot chats in the probe clone; each agent runs
   `register --runtime copilot-vscode` by hand, then `check` on turn 2; user pastes the raw `runtime=`
   lines. Expect one `copilot-cli-*` record per chat, `method=exact`. Answer:
   `plan.sh done 10-live-reprobe-vscode --by human`. Node 11 (review) can run alongside.

**No human in the loop:** do steps 1–5 unattended; stop at node 10 with its instructions in the
launcher. Also open for the user, not urgent: turn 1 of a Copilot VS Code chat is always an estimate
(~30% low) — document it or accept (`plan.md` → "Not yet specified").

## Read these, in order

1. Top block of `handoff.md`
2. Node `plans/02-copilot-vscode-followups/nodes/08-canonical-copilot-registry-name.md`
3. The node-03 note in `decisions.md` (line ~84)

## Do NOT reload

- Nodes 01–07 and their diffs: verified and committed; their Logs hold the evidence.
- Probe write-ups (`probes/*.md`): the notes cite what they need.
- The s12 live chat `bec02542-…`: evidence is in node 05's Log.

## Constraints already decided (do not re-litigate)

- Fixes must be agent-agnostic, proven by a suite case that fails before the fix.
- Hook fan-out: keep all four hook files; the dispatcher's session-state path test is the gate.
- Registry: one name per Copilot session on the CLI runtime, copilot-cli.
- Pid-walk is out for identifying a session; liveness never relies on pid.
- Never probe in the workspace itself; use a clone.
- Pushing `main` is the user's call.

## Plan position

<!-- plan:begin position -->
Position: plan 02-copilot-vscode-followups, open, wave 3 of 4, done 7/12, doing 0, todo 5, blocked 0, dropped 0, sessions 2.
Frontier: 08-canonical-copilot-registry-name. Remaining: 5 of 12 — wave 3: 08-canonical-copilot-registry-name todo, 09-reconcile-w3 todo.
<!-- plan:end position -->

## State snapshot

- Branch `main`, s12 commits d308262, 34c76b4 + the s12 rollover commit; not pushed.
- Probe clone at d93e71a (lacks 34c76b4); its probe hook wrappers are uncommitted on purpose.
- Other sessions commit in this checkout concurrently: commit by path (zsh: use an array), never
  stage their files.
