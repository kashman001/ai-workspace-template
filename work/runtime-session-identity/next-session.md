# Catchup prompt — Runtime Session Identity (paste into a new agent session)

We're resuming runtime-session-identity. Works in any runtime (Claude Code, Codex, Gemini,
OpenCode) — all read `CONTEXT.md` via their entrypoint.

> **This file is the LAUNCHER (catch-up prompt).** Forward-only, and REPLACED
> at each rollover: it holds what to do next, still-binding constraints, and
> pointers — never session history. Past-tense provenance lives in
> `handoff.md` (the append-only ledger). Convention:
> docs/work-directory-conventions.md.

## Mission

Execute plan `plans/01-session-identity-fixes` so concurrent sessions in one
workspace never bind each other's transcript. Each node's Goal and Acceptance
are the spec.

## >>> START HERE <<<

**First actions:**

1. `scripts/context-budget.sh register --project runtime-session-identity`
2. `scripts/plan.sh status --project=runtime-session-identity` and
   `scripts/plan.sh frontier --project=runtime-session-identity`.
3. Wave 2 (nodes 03–07) is the frontier: dispatch the five to parallel subagents
   with `isolated: yes` (own worktree each; they all edit `scripts/context-budget.sh`
   and `scripts/tests/test-context-budget-registry.sh`). Use the template in
   `skills/plans/SKILL.md` → "Subagent prompt template": `start` every node and commit
   before dispatch, actors `s6-a`…`s6-e`, each node test-first (`tdd`, every Acceptance
   suite case seen failing before the fix). Merge each branch, verify on disk, `done`,
   then run reconcile node `08-reconcile-w2`. Give each child a distinct suite-section
   prefix (e.g. E/F/G/H/K) so the merged labels don't clash.
4. Read the two `plan.sh note` lines in `plan.md` before dispatching nodes 05–07, and
   pass them on to those children.

**No human in the loop:** waves 1–2 run unattended. Stop at node
`11-remaining-surface-probes` (hitl) and ask the user, verbatim, **"Do you want to
run the Antigravity IDE/app and Codex desktop app probes now
(`probes/user-checklist.md` steps 3–4), or skip them?"**

## Read these, in order

1. `work/runtime-session-identity/plans/01-session-identity-fixes/plan.md`
2. The wave-2 node files under `plans/01-session-identity-fixes/nodes/` (03–08)
3. The probe file(s) a node names (`probes/<surface>.md`), only when needed

## Do NOT reload

- `findings.md` in full: every gap is now a node with its own Goal.
- `probes/gemini-cli.md`: superseded by Antigravity (user decision).
- Node 01's diff: done and reconciled (commits `3828bf2`, `95ddf21`).

## Constraints already decided (do not re-litigate)

- Fixes must be agent-agnostic (Codex/Copilot/Antigravity/Claude), proven by a suite case
  that fails before the fix.
- Pid-walk is out for identifying a session (Copilot shares one process; the Codex sandbox
  blocks `ps`).
- Ambiguous discovery refuses on every command (`decisions.md`).
- Pushing `main` is the user's call; never push.
- Probe cleanup (`findings.md` → "Cleanup owed") waits for the user's say-so.

## Plan position

<!-- plan:begin position -->
Position: plan 01-session-identity-fixes, open, wave 2 of 5, done 2/16, doing 5, todo 9, blocked 0, dropped 0, sessions 2.
Frontier: none (03-codex-hook-registration doing, 04-copilot-cli-hook-registration doing, 05-copilot-vscode-cli-runtime doing, 06-one-hook-per-copilot-event doing, 07-antigravity-runtime doing). Remaining: 14 of 16 — wave 2: 03-codex-hook-registration doing, 04-copilot-cli-hook-registration doing, 05-copilot-vscode-cli-runtime doing, 06-one-hook-per-copilot-event doing, 07-antigravity-runtime doing, 08-reconcile-w2 todo.
<!-- plan:end position -->

## State snapshot

- Branch `main`, clean after the rollover commit; 7+ commits ahead of origin.
- Probe clone `~/Developer/experiments/ws-identity-probe` still exists ("Cleanup owed").
