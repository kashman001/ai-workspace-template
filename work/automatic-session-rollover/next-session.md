# Catchup prompt — Automatic Session Rollover (paste into a new agent session)

We're resuming automatic-session-rollover. Works in any runtime (Claude Code,
Codex, Gemini, OpenCode, Copilot) — all read `CONTEXT.md` via their entrypoint.

> **This file is the LAUNCHER (catch-up prompt).** Forward-only, and REPLACED
> at each rollover: it holds what to do next, still-binding constraints, and
> pointers — never session history. Past-tense provenance lives in
> `handoff.md` (the append-only ledger). Convention:
> docs/work-directory-conventions.md.

## First actions

1. `git pull --ff-only` if the checkout lags origin/main.
2. `scripts/context-budget.sh register --project automatic-session-rollover`
   — re-acquires the work-item lock the predecessor released.
3. Read the plan's **Global Constraints** only (not the task bodies):
   `work/automatic-session-rollover/plans/2026-08-05-vendor-hook-deployments.md`.
4. Continue with `superpowers:subagent-driven-development`. The SDD ledger
   `.superpowers/sdd/2026-08-05-vendor-hook-deployments/progress.md` records
   Tasks 1–8 complete. Resume at **Task 9 (user-added)** — brief already
   written: `.superpowers/sdd/2026-08-05-vendor-hook-deployments/task-9-brief.md`
   (attach-session.sh helper; user overrode the YAGNI call, this is mandated).
   Dispatch implementer → task review per SDD.
5. Then the plan-wide **final whole-branch review** (most capable model) over
   range `13201b5..HEAD` — includes Task 9's commit; triage the SDD ledger's
   deferred minors (T3 set -e sourcing, T5 report self-description, T7 dangling
   pointer now fixed by Task 8, T8 backlog footer date).

## Mission: Task 9 (attach-session.sh), then the final whole-branch review

Tasks 1–8 are DONE and pushed (through `f9e003a`) — all five runtime hooks,
option inheritance, docs gate. Do not redo or re-review them individually;
the final review covers the whole branch.

## Constraints already decided (do not re-litigate)

- Plan's **Global Constraints** are authoritative (ADR-0003/0004; escalation-
  only / throttled / fail-open; bash-3.2 empty-array form; verify vendor flags
  against live `--help` before wiring — the plan's table already had one
  nonexistent codex flag).
- Standing push-to-main approval applies.
- Task 9 is user-mandated (attach helper ≠ YAGNI); its brief is the
  requirements doc — follow it, including the claude-attach-syntax live
  verification and the non-claude "already interactive elsewhere" behavior.
- Machine gotchas (do NOT re-diagnose): codex global config pins unavailable
  model; gemini has no auth; `opencode run` re-appends `$schema` — all in
  docs/operational-knowledge.md.
- At session end / rollover: release the lock (`scripts/context-budget.sh
  release --project automatic-session-rollover`).

## Do NOT reload

- `handoff-archive.md` — sessions 1–8 provenance, superseded.
- Task 1–8 briefs/reports under `.superpowers/sdd/…/` — reviewed and closed;
  only `progress.md` (deferred minors) + `task-9-brief.md` matter now.
- `vendor-hooks-research.md`, `smoke-test-*.md`, `relaunch-analysis.md`,
  `docs/adr/0001*/0002*` — consumed/background only.
- The multi-hop rollover design discussion — settled and flushed into
  `docs/context-budget.md` ("Chained rollovers & re-attach", gemini caveat);
  Task 9's brief carries the actionable remainder.

## State snapshot (at session-10 rollover, 2026-08-06)

- Branch `main` pushed through `f9e003a`. Uncommitted at rollover: only
  `work/context-decay/context-ledger.jsonl` (budget ledger, committed by the
  rollover commit) and the live `.active-session` lock (untracked by design).
- Suites green: vendor-budget-hooks 37, launch-next-session 38, registry 13.
- No `.rollover-options` file exists — this session didn't know its own launch
  flags (skill says leave absent); successor launches with runtime defaults.
- Cleanup candidate (low priority): leftover merged worktree
  `.claude/worktrees/vendor-hook-deployments` + its branch.
- No running background processes; work-item lock released at rollover.
