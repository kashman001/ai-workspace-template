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
2. Rebuild the probe clone at current `main`. The old clone is at `bc1cce4`, which is pre-fix.
   Ask the user before deleting `~/Developer/experiments/ws-identity-probe`. Otherwise pass a
   new dest to `probes/make-ide-probe-clone.sh`. Check the script's hook wrapper list first:
   it wraps codex/copilot/copilot-vscode/gemini/stop but not the `claude` or `antigravity`
   hooks. Add them so all seven surfaces log their payloads.
3. Rewrite `probes/user-checklist.md` as one post-fix checklist with a row per surface. For
   each one: open two sessions in the clone, run `./probe-env.sh <runtime> <label>` and
   `scripts/context-budget.sh check` in each, and send a turn. Pass means each session's
   `artifact=` is its own transcript, and `.context-budget/sessions/` holds one record per
   session with no cross-binding. Include the Codex hook-trust re-prompt (config changed since
   bc1cce4) and the Claude VS Code plugin (new: probe its env id vars and hooks the way
   `probes/codex-vscode.md` did).
4. Run the four CLI surfaces yourself where possible, using their non-interactive modes in
   the clone (sign-in and the Codex trust prompt may need the user). Write each result into
   `probes/<surface>.md` under a new "Post-fix (s9)" heading.
5. Hand the three VS Code rows to the user with the exact steps. Then read `probe-out/`
   and write up the results.
6. File any gap as a backlog card, or open plan 02 if there are several. Update L86.

**No human in the loop:** steps 1–4 can run unattended, apart from sign-in and trust prompts.
Step 5 needs the user's clicks: prepare and commit the checklist, then stop with it open.

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
