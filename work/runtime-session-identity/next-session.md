# Catchup prompt — Runtime Session Identity (paste into a new agent session)

We're resuming runtime-session-identity. Works in any runtime (Claude Code, Codex, Gemini,
OpenCode) — all read `CONTEXT.md` via their entrypoint.

> **This file is the LAUNCHER (catch-up prompt).** Forward-only, and REPLACED
> at each rollover: it holds what to do next, still-binding constraints, and
> pointers — never session history. Past-tense provenance lives in
> `handoff.md` (the append-only ledger). Convention:
> docs/work-directory-conventions.md.

## Mission

Plan `plans/01-session-identity-fixes` is closed. No agent work is queued. What is left
needs the user to decide or act.

## >>> START HERE <<<

**First actions:**

1. `scripts/context-budget.sh register --project runtime-session-identity`
2. Read the top block of `handoff.md`, then ask the user which of these to pick up:
   - **L86** (template backlog): Antigravity IDE/app and Codex desktop probes. The user runs
     steps 3–4 of `probes/user-checklist.md` in the probe clone, then an agent writes up the
     probes and files any gap.
   - **Probe cleanup** (`findings.md` → "Cleanup owed"). This needs the user's go-ahead
     after L86.
   - **Push `main`.** This is the user's call.
   - **Close the item.** If nothing above belongs here, archive per
     `docs/work-directory-conventions.md`.

**The item's checks:** `scripts/tests/test-context-budget-registry.sh`,
`test-statusline-context-budget.sh`, `test-vendor-budget-hooks.sh`, `test-attach-session.sh`,
`test-doc-consistency.sh` (all green after the L87 fix: 276/20/167/27/17).

## Constraints already decided (do not re-litigate)

- Fixes must be agent-agnostic, proven by a suite case that fails before the fix.
- Pid-walk is out for identifying a session; liveness never relies on pid.
- Ambiguous discovery refuses on every command; the Copilot CLI hook config owns every Copilot payload.
- No session-id field in hook payloads; phantom grace is a fixed 60 min (`decisions.md`).
- Pushing `main` is the user's call; never push.
- Probe cleanup (`findings.md` → "Cleanup owed") waits for L86 and the user's say-so.

## Plan position

<!-- plan:begin position -->
Position: plan 01-session-identity-fixes, closed, wave 5 of 5, done 16/17, doing 0, todo 0, blocked 0, dropped 1, sessions 4.
Frontier: none. Remaining: 0 of 17.
<!-- plan:end position -->

## State snapshot

- Branch `main`, clean after the session 8 checkpoint commit; many commits ahead of origin
  (not pushed).
- Unrelated pre-existing worktrees (doc-review-skill, stage4, tir-s2): leave them.
- Probe clone `~/Developer/experiments/ws-identity-probe` kept for backlog L86.
