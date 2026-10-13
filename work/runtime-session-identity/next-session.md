# Catchup prompt — Runtime Session Identity (paste into a new agent session)

We're resuming runtime-session-identity. Works in any runtime (Claude Code, Codex, Gemini,
OpenCode) — all read `CONTEXT.md` via their entrypoint.

> **This file is the LAUNCHER (catch-up prompt).** Forward-only, and REPLACED
> at each rollover: it holds what to do next, still-binding constraints, and
> pointers — never session history. Past-tense provenance lives in
> `handoff.md` (the append-only ledger). Convention:
> docs/work-directory-conventions.md.

## Mission

Live verification on current `main` of the user's stated expectation. Each of these surfaces
binds and measures its **own** session, including with two sessions open at once in one
workspace:

- **CLI:** Claude Code, Codex, Antigravity (`agy`), GitHub Copilot (`copilot`, and check
  whether `gh copilot` launches the same runtime).
- **VS Code plugins:** Claude, Codex, GitHub Copilot.

The user asked for this setup in session 8. Plan 01 is closed and was fixture-tested only, and
the Claude VS Code plugin was never probed. This widens backlog L86 (which covered only the
Antigravity IDE/app and Codex desktop) to all seven surfaces.

## >>> START HERE <<<

**First actions:**

1. `scripts/context-budget.sh register --project runtime-session-identity`
2. Status of `probes/user-checklist.md`, rows 1–3: **PASS** (written up in `copilot-cli.md`,
   `antigravity-cli.md`, `claude-vscode.md`). All four CLIs pass (s9). Remaining: **row 4**
   (Codex VS Code, labels `codex-vscode-A/B`, accept the hook-trust re-prompt) and **row 5**
   (Copilot VS Code Agent mode, `copilot-vscode-A/B`). Walk the user through them one at a time,
   then read `~/Developer/experiments/ws-identity-probe-s9/probe-out/` (`env-<label>.log`,
   `hook-*.log`) and `.context-budget/sessions/` and record each row under "Post-fix (s9)" in
   `probes/codex-vscode.md` / `probes/copilot-vscode.md`.
3. Optional row: Copilot Chat with a Claude model (still Copilot runtime).
4. File any gap as a backlog card, or open plan 02 if there are several. Update L86. Add a
   post-fix column to `findings.md` → "Where we stand".

Notes: a bare `ok` in Copilot can get an empty model reply ("No response was returned"). Our
hook still ran and succeeded, so tell the user to send `ok, thanks` instead. `probe-env.sh`'s
env grep also captures `*_TOKEN`/CSRF values into the clone's logs. They are local and never
committed, but filter them out if the script is reused.

**The item's checks:** `scripts/tests/test-context-budget-registry.sh`,
`test-statusline-context-budget.sh`, `test-vendor-budget-hooks.sh`, `test-attach-session.sh`,
`test-doc-consistency.sh` (green at s8 end: 276/20/167/27/17).

## Read these, in order

1. Top block of `handoff.md`
2. `findings.md` → "Where we stand" (the pre-fix matrix) and "Gaps"
3. `probes/user-checklist.md`, `probes/make-ide-probe-clone.sh`, `probes/probe-env.sh`
4. `docs/context-budget.md` → the support matrix (hook config per runtime)

## Do NOT reload

- Plan 01 nodes and diffs: closed and reviewed.
- `probes/gemini-cli.md`: Gemini CLI is out of scope (superseded by Antigravity).

## Constraints already decided (do not re-litigate)

- Fixes must be agent-agnostic, proven by a suite case that fails before the fix.
- Pid-walk is out for identifying a session; liveness never relies on pid.
- Ambiguous discovery refuses on every command; the Copilot CLI hook config owns every Copilot payload.
- No session-id field in hook payloads; phantom grace is a fixed 60 min (`decisions.md`).
- Never probe in the workspace itself; use a clone.
- Pushing `main` is the user's call; the user approved pushing in s8, but ask again.

## Plan position

<!-- plan:begin position -->
Position: plan 01-session-identity-fixes, closed, wave 5 of 5, done 16/17, doing 0, todo 0, blocked 0, dropped 1, sessions 4.
Frontier: none. Remaining: 0 of 17.
<!-- plan:end position -->

## State snapshot

- Branch `main` = `origin/main` before this rollover commit. Unrelated worktrees
  (doc-review-skill, stage4, tir-s2): leave them.
- Old probe clone `~/Developer/experiments/ws-identity-probe` (at bc1cce4, pre-fix).
