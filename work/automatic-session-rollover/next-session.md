# Catchup prompt — Automatic Session Rollover (paste into a new agent session)

We're resuming automatic-session-rollover. Works in any runtime (Claude Code,
Codex, Gemini, OpenCode, Copilot) — all read `CONTEXT.md` via their entrypoint.

> **This file is the LAUNCHER (catch-up prompt).** Forward-only, and REPLACED
> at each rollover: it holds what to do next, still-binding constraints, and
> pointers — never session history. Past-tense provenance lives in
> `handoff.md` (the append-only ledger). Convention:
> docs/work-directory-conventions.md.

## First actions

1. `git pull --ff-only` if the checkout lags origin/main (a stale checkout
   bit session 8 — verify before anything else).
2. `scripts/context-budget.sh register --project automatic-session-rollover`
   — acquires the work-item lock the predecessor released.
3. Read the plan: `work/automatic-session-rollover/plans/2026-08-05-vendor-hook-deployments.md`.
4. Execute it from **Task 2** with `superpowers:executing-plans` (or
   subagent-driven-development), committing per task as the plan specifies.

## Mission: execute plan Tasks 2–8 (vendor hooks + option inheritance)

**Task 1 is DONE** (commit `4a39bf8`): shared hook lib
`scripts/hooks/context-budget-hook-lib.sh` + claude wrapper refactor + test
suite `scripts/tests/test-vendor-budget-hooks.sh` (13 asserts green). Do not
redo it; later tasks source the lib and append tests to that suite exactly as
the plan specifies.

Remaining: opencode runtime in context-budget.sh (2), codex (3), gemini (4),
opencode (5), copilot (6) deployments, successor option inheritance in
launch-next-session.sh (7), docs/backlog/decisions + verification gate (8).
The plan is COMPLETE and self-contained — all code and test blocks inlined.
**Do NOT re-plan and do NOT re-research vendor hook schemas.**

**Budget note:** session 8 hit WARN at ~121K immediately after plan load.
Expect 2–4 tasks per session, then roll over; consider subagent-driven
execution to keep the parent context lean.

## Constraints already decided (do not re-litigate)

- The plan's **Global Constraints** section is authoritative (ADR-0003/0004;
  escalation-only / throttled / fail-open; gemini JSON-only stdout; opencode
  Part schema; copilot folder-trust + STOP-only block; verify vendor flags
  against live `--help` before wiring).
- Standing push-to-main approval applies.
- VS Code agent-mode verification OUT of scope → `issues/01-vscode-agent-mode-hooks.md`.
- At session end / rollover: release the lock (`scripts/context-budget.sh
  release --project automatic-session-rollover`) after the verification gate.

## Demand-load only if the plan's inline facts prove insufficient

- `vendor-hooks-research.md` — per-runtime hook schemas/events + citations.
- `smoke-test-opencode.md` / `smoke-test-copilot.md` — live-verified payloads,
  auth paths, artifact details.

## Do NOT reload

- `handoff-archive.md` — sessions 1–6 provenance, superseded.
- `plans/2026-08-05-session-keyed-registry.md`, `plans/2026-08-05-launch-next-session.md`
  — executed and landed; shape references only.
- `relaunch-analysis.md`, `docs/adr/0001*/0002*` — background only.
- Items #1/#2 design questions — settled, implemented, regression-tested;
  `decisions.md` tail has the notes.
- Task 1 design (lib interface) — settled; read the lib file itself if needed.

## State snapshot (at session-8 rollover, 2026-08-05)

- Branch `main`, pushed through the session-8 rollover commit (Task 1 =
  `4a39bf8`). Working tree clean; only the live `.active-session` lock is
  untracked, by design.
- Test suites green: vendor-budget-hooks 13 asserts (new), launch-next-session
  28, registry 13 (both untouched since session 6).
- Cleanup candidate: leftover merged worktree
  `.claude/worktrees/vendor-hook-deployments` (+ its branch) — remove when
  convenient, low priority.
- Machine: claude, codex 0.142.4, gemini 0.46.0, opencode 1.18.14, copilot
  CLI 1.0.78, sqlite3 present. No running background processes.
- Work-item lock released at rollover; successor re-acquires via First
  action 2.
