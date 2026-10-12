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
2. `scripts/plan.sh status --project=runtime-session-identity` and `… frontier …`.
3. Ask the user, verbatim (still unanswered from session 6):
   **"Do you want to run the Antigravity IDE/app and Codex desktop app probes now
   (`probes/user-checklist.md` steps 3–4), or skip them?"**
   Skip → `scripts/plan.sh drop 11-remaining-surface-probes "<reason>"`. Run → walk them
   through the checklist and write the probe files per node 11's Goal.
4. Without waiting on that answer, dispatch the three wave-3 work nodes —
   `09-phantom-records`, `10-record-without-env-id`, `11-copilot-vscode-measure-inputtokens` —
   to parallel subagents with `isolation: worktree`, per `skills/plans/SKILL.md` →
   "Subagent prompt template": `start` each and commit before dispatch, actors `s7-a`…`s7-c`,
   test-first (every Acceptance case seen failing first), distinct suite prefixes
   (unused so far: **A, B, Q** — E/F/H/K/L/D/R/T/… are taken). Tell each child the base SHA
   and to reset onto it if missing (worktrees were cut without it every time in s6).
   Merge each branch (suite-tail conflicts are append-vs-append: keep both), verify on disk,
   `done`, then reconcile `12-reconcile-w3` once node 11 is done or dropped.
5. Read the plan's "Not yet specified" notes before dispatch and pass the relevant ones on
   (node 10 ↔ the pid-less antigravity/codex note; node 09 ↔ Claude VS Code idle records).

## Read these, in order

1. `plans/01-session-identity-fixes/plan.md` (notes + Replans)
2. Wave-3 node files 09, 10, 11-copilot-vscode-measure-inputtokens, 11-remaining-surface-probes, 12
3. `probes/user-checklist.md` only if the user runs the probes

## Do NOT reload

- `findings.md` in full: every gap is a node with its own Goal.
- `probes/gemini-cli.md`: superseded by Antigravity (user decision).
- Wave-1/2 diffs: done and reconciled (`handoff.md` top block; `decisions.md`).

## Constraints already decided (do not re-litigate)

- Fixes must be agent-agnostic, proven by a suite case that fails before the fix.
- Pid-walk is out for identifying a session (Copilot shares one process; Codex sandbox blocks `ps`).
- Ambiguous discovery refuses on every command; the Copilot CLI hook config owns every Copilot payload (`decisions.md`).
- Pushing `main` is the user's call; never push.
- Probe cleanup (`findings.md` → "Cleanup owed") waits for the user's say-so.

## Plan position

<!-- plan:begin position -->
Position: plan 01-session-identity-fixes, open, wave 4 of 5, done 12/17, doing 0, todo 4, blocked 0, dropped 1, sessions 3.
Frontier: 13-docs. Remaining: 4 of 17 — wave 4: 13-docs todo, 14-reconcile-w4 todo.
<!-- plan:end position -->

## State snapshot

- Branch `main`, clean after the rollover commit; many commits ahead of origin (not pushed).
- Unrelated pre-existing worktrees (doc-review-skill, stage4, tir-s2) — leave them.
- Probe clone `~/Developer/experiments/ws-identity-probe` still exists ("Cleanup owed").
