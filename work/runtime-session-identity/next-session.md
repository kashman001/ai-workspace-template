# Catchup prompt — Runtime Session Identity (paste into a new agent session)

We're resuming runtime-session-identity. Works in any runtime (Claude Code, Codex, Gemini,
OpenCode) — all read `CONTEXT.md` via their entrypoint.

> **This file is the LAUNCHER (catch-up prompt).** Forward-only, and REPLACED
> at each rollover: it holds what to do next, still-binding constraints, and
> pointers — never session history. Past-tense provenance lives in
> `handoff.md` (the append-only ledger). Convention:
> docs/work-directory-conventions.md.

## Mission

Run plan `02-copilot-vscode-followups`: close the three findings from the s10 Copilot VS Code
re-probe. (1) Token count is a ~30%-low size estimate because `prompt_tokens` isn't read;
(2) four hook sets fire per Copilot event, two of them Claude Code's; (3) two registry
records per chat. Fix 1 now; investigate 2 and 3 and put options to the user.

## >>> START HERE <<<

**First actions:**

1. `scripts/context-budget.sh register --project runtime-session-identity`
2. `scripts/plan.sh frontier --project runtime-session-identity` — wave 1: nodes 01, 02, 03.
   Read each node file under `plans/02-copilot-vscode-followups/nodes/` (Goal + Acceptance).
3. Dispatch nodes **02** and **03** as parallel read-only subagents (plans skill → "Subagent
   prompt template", actors `s11-a`/`s11-b`). Tell them NOT to edit `decisions.md`: each
   returns its draft Tier-2 note in its report; the main session appends both.
4. Run node **01** in the main session, test-first (`tdd`): real transcripts in
   `~/.copilot/session-state/{d5d80a4e…,90bc99b7…}` (VS Code) and `018beebd…` (CLI); probe
   clone `~/Developer/experiments/ws-identity-probe-s9`. Live acceptance needs a VS Code
   chat after the fix lands in the clone (`git -C <clone> pull`/cherry-pick) — ask the user.
5. Reconcile node 04 (verify on disk), then node 05 is the user's: walk them through the two
   notes **one question at a time**, plain language.

**No human in the loop:** do nodes 01–04; leave 05 with both notes committed and the
questions written here.

**The item's checks:** `scripts/tests/test-context-budget-registry.sh`,
`test-statusline-context-budget.sh`, `test-vendor-budget-hooks.sh`, `test-attach-session.sh`,
`test-doc-consistency.sh`.

## Read these, in order

1. Top block of `handoff.md`
2. `plans/02-copilot-vscode-followups/plan.md` and its nodes
3. `probes/copilot-vscode.md` → "Re-probe (s10)" only

## Do NOT reload

- Plan 01 nodes and diffs: closed and reviewed.
- Probe rows 1–4 (Claude/Codex/Copilot/agy CLIs, Claude VS Code, Codex VS Code): PASS, written up.
- "Hooks silent" (s9): a misread, corrected in s10.
- `probes/gemini-cli.md`: Gemini CLI out of scope.

## Constraints already decided (do not re-litigate)

- Fixes must be agent-agnostic, proven by a suite case that fails before the fix.
- Pid-walk is out for identifying a session; liveness never relies on pid.
- Ambiguous discovery refuses on every command; the Copilot CLI hook config owns every Copilot payload.
- Never probe in the workspace itself; use a clone.
- Pushing `main` is the user's call.

## Plan position

<!-- plan:begin position -->
Position: plan 02-copilot-vscode-followups, open, wave 1 of 2, done 0/6, doing 0, todo 6, blocked 0, dropped 0, sessions 0.
Frontier: 01-fix-copilot-vscode-exact-tokens, 02-investigate-hook-fanout, 03-investigate-duplicate-records. Remaining: 6 of 6 — wave 1: 01-fix-copilot-vscode-exact-tokens todo, 02-investigate-hook-fanout todo, 03-investigate-duplicate-records todo, 04-reconcile-w1 todo.
<!-- plan:end position -->

## State snapshot

- Branch `main`, last item commit = the s10 rollover commit; `main` = `origin/main` before it.
- Other sessions have uncommitted edits in this checkout (docs/context-budget.md,
  scripts/launch-next-session.sh, scripts/session-loop.sh + their tests, backlog html,
  work/html-kit, work/clear-session-loop). Not ours: never stage them; commit by path.
- Unrelated worktrees (doc-review-skill, stage4, tir-s2): leave them.
