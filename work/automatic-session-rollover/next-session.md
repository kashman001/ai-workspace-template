# Catchup prompt — Automatic Session Rollover (paste into a new agent session)

> **This file is the LAUNCHER (catch-up prompt).** Forward-only, REPLACED at
> each rollover. Past-tense provenance lives in `handoff.md` (append-only
> ledger, newest block on top). Convention: docs/work-directory-conventions.md.

## Mission

**The wayfinder map is COMPLETE** (destination reached, session 27): all
research-§14.4 questions are recorded decisions, no open tickets, no fog.
There is **no standing mission** — every remaining item is user-scheduled.
Menu (take one ONLY when the user picks it, or the bootstrap names it):

- **Issue 01 items 1+3** (`issues/01-vscode-agent-mode-hooks.md`) — HITL,
  needs the user live in VS Code: (1) verify agent-mode hooks fire in-band;
  (3) verify `code chat -r -m agent "<prompt>"` end-to-end, then upgrade
  `launch-next-session.sh`'s copilot-vscode branch + W-test + docs. Item 2
  is closed (only the optional UI-meter comparison leg remains).
- **Backlog items** (template work, in `docs/template-workspace-backlog.html`):
  swallowed-WARN defect; EnterWorktree registry staleness (two strikes);
  launcher-staleness mechanical fix (guaranteed ff-pull before the successor
  reads this file); copilot adapter BUILD (designed in ticket 09; slice 0 =
  background/`write_agent` probe + `copilot_cli_measure` sqlite-first).
- **Housekeeping:** prune the disposable worktrees (all pushed); delete
  branch `session-26-pre-reconcile`.

If the user is AFK and named nothing: idle-report. Do not invent work.

## Read these, in order

1. `handoff.md` top block — session-27 record.
2. Only what the chosen item needs: its issue file / backlog row. The map
   (`map.md`) is now reference, not frontier — load only if asked about
   past decisions.

## Do NOT reload

- Research md/HTML corpus, `research/*` — settled; distilled into
  ADR-0005/0006, `docs/context-budget.md`, ticket answers.
- All map tickets 06–09 + ticket 08 — RESOLVED (answers inline in the
  ticket files; map's Decisions-so-far has the gists). The map needs no
  further updates.
- Issue 04 — parked by the user; never schedule unprompted (its file is
  intentionally untracked in the user's checkout).
- `rollover-scenarios.md`, `plans/*` — build slices all COMPLETE.
- Sessions ≤25 handoff blocks, `handoff-archive.md` — settled.
- `work/context-decay/copilot-vscode-sandbox-discovery-fix.md` — spec
  IMPLEMENTED + VERIFIED (session 27); read only if the fix regresses.

## Constraints already decided (do not re-litigate)

- Role schema final: primary / auxiliary / child / superseded.
- Dispatch-time contract is the load-bearing parent→child channel.
  Accelerator tier (hook injection into children): CLOSED (ticket 06).
- Copilot measured-tier adapter: DESIGNED (ticket 09); build unscheduled.
- **Per-role WARN/STOP thresholds: YAGNI (ticket 08)** — one shared pair,
  keyed to the model's dumb zone; revisit trigger lives in
  `docs/context-budget.md` → Thresholds. Per-item threshold plumbing
  deliberately unbuilt (per-item env = relaunch knobs only).
- Coordination state is repository-keyed (ADR-0006).
- R2/R3/R4 shipped; R6 drain mode stays deferred. Runtime state stays
  gitignored. Standing push-to-main approval applies.

## State snapshot (at session-27 rollover, 2026-08-06)

- All session-27 work committed on main and pushed: `2c45bfe` (sandbox
  discovery fix, live-verified in-copilot) + `18c5aee` (ticket 08 + map
  completion) + the rollover commit.
- Tests: eight suites, 326 asserts, green this session (at `2c45bfe`).
- No live dispatches; no child agents.
- Copilot durable evidence dirs (don't delete):
  `~/.copilot/session-state/c356dbd8-…` and `96cbc930-…`.
- Worktrees (all pushed, disposable — prune when convenient):
  `session-26-ticket-09` (carries deletable branch
  `session-26-pre-reconcile`), `session-25-ticket-09`,
  `session-24-wayfinder-tickets`, `session-23-registry-hygiene`, plus the
  session-22-snapshot set (`git worktree list` is authoritative).
- Sandbox gotchas live in `docs/operational-knowledge.md`.

## First actions

1. **Freshness guard — BEFORE trusting anything in this file:**
   `git fetch origin` then `git log --oneline HEAD..origin/main` — MUST be
   empty. If not, `git pull --ff-only` and RE-READ this launcher. (If the
   pull refuses on an untracked file, diff it against the incoming blob
   first — delete only if identical/stale.)
2. `scripts/context-budget.sh register --project automatic-session-rollover`
   — expect `role=primary`; session 27's record back-stamped with YOUR id.
3. Ask the user (or read the bootstrap) which menu item to take. AFK with
   no instruction → idle-report only.

## If you are a VS Code Copilot Chat (agent-mode) session

- After `register`, paste the emitted `runtime= method= tokens= ...` line
  into the chat — with the session-27 sandbox fix, discovery should now
  succeed from the sandboxed terminal IF `VSCODE_TARGET_SESSION_LOG` is
  exported (visible in session context, NOT auto-exported to the shell —
  export it first). `method=estimate` before the first turn flush is
  normal; expect `exact` afterward.
- If `register` reports `role=auxiliary`, a live claude session owns the
  work item — coordinate with the user before touching anything.

## At session end

Lock releases mechanically (launcher script or SessionEnd hook). Manual
fallback: `scripts/context-budget.sh release --project automatic-session-rollover`.
