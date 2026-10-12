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
are the spec; `findings.md` → "Gaps" is the source.

## >>> START HERE <<<

**First actions:**

1. `scripts/context-budget.sh register --project runtime-session-identity`
2. `scripts/plan.sh status --project=runtime-session-identity` and
   `scripts/plan.sh frontier --project=runtime-session-identity`.
3. Work the frontier node (now `01-refuse-instead-of-guess`) per
   `skills/plans/SKILL.md`: `start` → test-first (`tdd`; each Acceptance suite
   case must be seen failing before the fix) → `done`. Then the wave's
   reconcile node. Wave 2's five nodes are independent: dispatch them to
   parallel subagents (the template in `skills/plans/SKILL.md`).

**No human in the loop:** waves 1–2 run unattended. Stop at node
`11-remaining-surface-probes` (hitl): ask the user, verbatim, **"Do you want to
run the Antigravity IDE/app and Codex desktop app probes now
(`probes/user-checklist.md` steps 3–4), or skip them?"**

## Read these, in order

1. `work/runtime-session-identity/plans/01-session-identity-fixes/plan.md`
2. The frontier node file under `plans/01-session-identity-fixes/nodes/`
3. The probe file(s) that node names (`probes/<surface>.md`), only when needed

## Do NOT reload

- `findings.md` in full: every gap is now a node with its own Goal; read a
  single node's section only if a node is unclear.
- `probes/gemini-cli.md`: superseded by Antigravity (user decision).
- The `probe-out/` logs in the clone: already written up in
  `probes/codex-vscode.md` and `probes/copilot-vscode.md`.

## Constraints already decided (do not re-litigate)

- Fixes must be agent-agnostic (Codex/Copilot/Antigravity/Claude), proven by a suite case
  that fails before the fix.
- Pid-walk is out for identifying a session (Copilot shares one process; the Codex sandbox
  blocks `ps`).
- Pushing `main` is the user's call; never push.
- Probe cleanup (`findings.md` → "Cleanup owed") waits for the user's say-so.

## Plan position

<!-- plan:begin position -->
Position: plan 01-session-identity-fixes, open, wave 2 of 5, done 2/16, doing 0, todo 14, blocked 0, dropped 0, sessions 1.
Frontier: 03-codex-hook-registration, 04-copilot-cli-hook-registration, 05-copilot-vscode-cli-runtime, 06-one-hook-per-copilot-event, 07-antigravity-runtime. Remaining: 14 of 16 — wave 2: 03-codex-hook-registration todo, 04-copilot-cli-hook-registration todo, 05-copilot-vscode-cli-runtime todo, 06-one-hook-per-copilot-event todo, 07-antigravity-runtime todo, 08-reconcile-w2 todo.
<!-- plan:end position -->

## State snapshot

- Branch `main`; the rollover commit holds everything. 5 commits ahead of origin.
- Probe clone `~/Developer/experiments/ws-identity-probe` is still there (VS Code may have
  it open); it's in "Cleanup owed".
