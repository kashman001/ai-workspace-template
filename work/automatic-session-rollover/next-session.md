# Catchup prompt — Automatic Session Rollover (paste into a new agent session)

We're resuming automatic-session-rollover. Works in any runtime (Claude Code,
Codex, Gemini, OpenCode, Copilot) — all read `CONTEXT.md` via their entrypoint.

> **This file is the LAUNCHER (catch-up prompt).** Forward-only, and REPLACED
> at each rollover: it holds what to do next, still-binding constraints, and
> pointers — never session history. Past-tense provenance lives in
> `handoff.md` (the append-only ledger). Convention:
> docs/work-directory-conventions.md.

## First actions

1. If `work/automatic-session-rollover/plans/2026-08-05-vendor-hook-deployments.md`
   is missing, `git pull` first — session 7 pushed it to `main` from a
   worktree, so a stale checkout may not have it yet.
2. `scripts/context-budget.sh register --project automatic-session-rollover`
   — acquires the work-item lock the predecessor released. (If you later use
   EnterWorktree: **re-run register afterwards** — the transcript path moves;
   see `docs/operational-knowledge.md` → "EnterWorktree re-keys".)
3. Read the plan: `work/automatic-session-rollover/plans/2026-08-05-vendor-hook-deployments.md`.
4. Execute it task-by-task with `superpowers:executing-plans` (or
   subagent-driven-development), committing per task as the plan specifies.

## Mission: execute the item #3 plan (vendor hooks + option inheritance)

The plan is COMPLETE and self-contained — all wrapper/lib/plugin/config code
and test blocks are inlined, vendor envelopes and payload fields are pinned
with citations, and each task carries its own live smoke check. **Do NOT
re-plan and do NOT re-research vendor hook schemas.** Eight tasks: shared
hook lib (1), opencode runtime for context-budget.sh (2), codex (3),
gemini (4), opencode (5), copilot (6) deployments, successor option
inheritance in launch-next-session.sh — a user requirement, all five
runtimes (7), docs/backlog/decisions + verification gate (8).

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

- `handoff-archive.md` — sessions 1–5 provenance, superseded.
- `plans/2026-08-05-session-keyed-registry.md`, `plans/2026-08-05-launch-next-session.md`
  — executed and landed; shape references only.
- `relaunch-analysis.md`, `docs/adr/0001*/0002*` — background only.
- Items #1/#2 design questions — settled, implemented, regression-tested;
  `decisions.md` tail has the notes.

## State snapshot (at session-7 rollover, 2026-08-05)

- Session 7 planned only — STOP rollover (171K exact) right after writing the
  plan; **no plan task has been executed**.
- Plan + handoff + this launcher + ops note committed on branch
  `worktree-vendor-hook-deployments`, pushed to `main`. The primary checkout
  may lag origin/main until pulled and has uncommitted
  `work/context-decay/context-ledger.jsonl` rows — fold them into the next
  work commit.
- Test suites green pre-session-7 (untouched): launch-next-session 28
  asserts, registry 13.
- Machine: claude, codex 0.142.4, gemini 0.46.0, opencode 1.18.14, copilot
  CLI 1.0.78 installed; sqlite3 3.51 present. No running background processes.
- Work-item lock released at rollover; successor re-acquires via First
  action 2.
