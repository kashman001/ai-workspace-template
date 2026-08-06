# Catchup prompt — Automatic Session Rollover (paste into a new agent session)

> **This file is the LAUNCHER (catch-up prompt).** Forward-only, REPLACED at
> each rollover. Past-tense provenance lives in `handoff.md` (append-only
> ledger, newest block on top). Convention: docs/work-directory-conventions.md.

## Mission

**Execute the issue-01 build spec** — turn the session-28 live verification
of VS Code agent-mode hooks + `code chat` seeded launch into shipped wiring.
The spec is fully written down: `issues/01-vscode-agent-mode-hooks.md` →
"Update 2026-08-06 (session 28)" → **Build spec**, steps 1–6 (vscode hook
script, PascalCase JSON wiring, cwd/relative-path probe v4, launcher
`code chat` branch, W-test + vendor T9 tests, docs + backlog). Nothing needs
re-verifying; do not re-run the probe sessions except the ONE open leg
(spec step 3: hook-process cwd — needs the user to relay one `!` cp and one
`code chat` run; probe files are already in place in the main checkout).

After the build ships green: issue 01 is done — record versions in the
ticket per its "Done when", have the user delete the probe files +
`.vscode-hook-probe.jsonl`, and fall back to the user-scheduled menu
(backlog items in `docs/template-workspace-backlog.html`; nothing else is
standing — the wayfinder map is complete).

## Read these, in order

1. `handoff.md` top block — session-28 record.
2. `issues/01-vscode-agent-mode-hooks.md` — session-28 update block ONLY
   (verified contract + build spec). Earlier blocks are provenance.
3. At build time, the files the spec touches:
   `scripts/hooks/context-budget-copilot-hook.sh` (pattern to mirror),
   `scripts/hooks/context-budget-hook-lib.sh` (budget_hook_check/message),
   `scripts/launch-next-session.sh` (copilot-vscode branch ~line 268),
   `scripts/tests/test-vendor-budget-hooks.sh` (T8 = model for T9),
   `scripts/tests/test-launch-next-session.sh` (T-test pattern).

## Do NOT reload

- Research md/HTML corpus, `research/*`, `vendor-hooks-research.md` — the
  session-28 ticket block supersedes its VS Code guesses (verified > doc).
- Map (`map.md`) + tickets 06–09 — map COMPLETE; reference only.
- Issue 04 — parked by the user; never schedule unprompted.
- Sessions ≤27 handoff blocks, `handoff-archive.md` — settled.
- `work/context-decay/copilot-vscode-sandbox-discovery-fix.md` — shipped;
  unrelated to the hook path (hooks read `~/Library` unsandboxed).
- Probe transcripts under `~/Library/…/GitHub.copilot-chat/transcripts/` —
  findings already distilled into the ticket.

## Constraints already decided (do not re-litigate)

- Stop-block channel is **exit 2 + stderr** (JSON `decision:block` verified
  IGNORED by VS Code) — don't "fix" the new hook to emit JSON blocks.
- Hook fires ONLY for VS Code payloads: guard on snake_case `session_id`
  (CLI sends camelCase `sessionId`) — keeps shared `.github/hooks/` files
  safe for both runtimes.
- Mirror copilot-cli hook semantics: SessionStart additionalContext
  (WARN/STOP catch-up), Stop block ONLY at STOP; escalation-only lib
  semantics stay.
- Role schema, repository-keyed state (ADR-0006), one shared WARN/STOP
  threshold pair (ticket 08 YAGNI), standing push-to-main approval — all
  unchanged.

## State snapshot (at session-28 rollover, 2026-08-06)

- main at `64c3f85` (issue-01 findings + build spec), pushed. Session-28
  rollover commit lands after this file. Tests last green at `2c45bfe`
  (326 asserts); nothing code-bearing changed since.
- USER'S main checkout: probe files present, untracked, NEEDED for spec
  step 3 (`scripts/hooks/vscode-hook-probe.sh`,
  `.github/hooks/vscode-probe.json`, `.vscode-hook-probe.jsonl`) — plus it
  may be behind origin; the user pulls, or the freshness guard catches it.
- Worktrees: only `session-28-issue-01-vscode` (this rollover's, pushed,
  disposable after merge). All older worktrees/branches pruned (session 28
  housekeeping).
- No live dispatches; no child agents. Copilot durable evidence dirs
  (don't delete): `~/.copilot/session-state/c356dbd8-…`, `96cbc930-…`.
- The user is live in VS Code with a Copilot agent chat panel and will
  relay `!` commands and `code chat` runs on request.

## First actions

1. **Freshness guard:** `git fetch origin` then
   `git log --oneline HEAD..origin/main` — MUST be empty; else
   `git pull --ff-only` and RE-READ this launcher.
2. `scripts/context-budget.sh register --project automatic-session-rollover`
   — expect `role=primary`; session 28's record back-stamped with your id.
3. Open the ticket's Build spec and start at step 3 (probe v4 cwd check —
   it gates the JSON command form in step 2), then steps 1–2, 4–6.

## If you are a VS Code Copilot Chat (agent-mode) session

- After `register`, paste the emitted `runtime= method= tokens= ...` line
  into the chat. Discovery works from the sandboxed terminal IF
  `VSCODE_TARGET_SESSION_LOG` is exported first (visible in session
  context, NOT auto-exported). `method=estimate` before the first turn
  flush is normal; expect `exact` afterward.
- If `register` reports `role=auxiliary`, a live claude session owns the
  work item — coordinate with the user before touching anything.

## At session end

Lock releases mechanically (launcher script or SessionEnd hook). Manual
fallback: `scripts/context-budget.sh release --project automatic-session-rollover`.
