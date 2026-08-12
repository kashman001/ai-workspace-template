# Catchup prompt — DevEx fix package (b): spec workflow (M20–M22)

We're resuming devex-review — the FIX PROGRAM. Works in any runtime
(Claude Code, Codex, Gemini, OpenCode).

> **This file is the LAUNCHER (catch-up prompt).** Forward-only, REPLACED at
> each rollover: what to do next, still-binding constraints, pointers — never
> session history. Past-tense provenance lives in `handoff.md` (append-only
> ledger). Convention: docs/work-directory-conventions.md.

## MERGE GATE — check before anything else

Session 4 ran as a background job on branch
`worktree-devex-m24-setup-correctness` (package (c)/M24, commit `a7efb94`).
If `git log --oneline -5` does not show that commit, the branch is unmerged —
**stop and ask the user to merge it first**. Merge note: main may carry
uncommitted changes to `work/devex-review/handoff*.md` (a `rollover-prep.sh`
bug rotated main's ledger from the worktree — card M25); they duplicate what
the branch carries, so discard them first:
`git checkout -- work/devex-review/` in main.

## Mission

Execute fix package (b) — backlog cards **M20–M22** (spec workflow). This is
a **COLLABORATIVE session**: the fixes define team conventions (spec format,
traceability, verification evidence) that need the user's judgement — grill
and agree before writing. Do not run it as an autonomous background job.

## Read these, in order

1. `docs/template-workspace-backlog.html` — the M20, M21, M22 cards (grep
   each ID).
2. Raw evidence on demand: `work/devex-review/findings/qa-persona.md` hat B
   (B1–B6) and `dev-persona.md` "Addendum — Spec Workflow" — targeted greps.

## Do NOT reload

- `findings/devex-review.md` in full — fix lists already carded.
- The persona review process — complete; never re-dispatch.
- Packages (a)/M19 and (c)/M24 — done and archived; handoff.md top block
  only if needed.
- Package sequencing — settled (decisions.md); after (b), remaining open:
  M23, L32, L33, L35.
- Hooks-check design — settled (decisions.md, 2026-08-11 M24 note).

## Constraints already decided (do not re-litigate)

- One work item for the whole fix program; one package per session.
- Template additions stay agent-agnostic and downloader-ready (project
  memory).
- `ROLLOVER_RELAUNCH=auto`; a committed work-item env can override per item.
- Telemetry ledger lives at `.context-budget/context-ledger.jsonl`.

## State snapshot

- Package (c) on branch `worktree-devex-m24-setup-correctness`, pushed (see
  MERGE GATE); main was in sync with origin at session-4 start.
- `work/kimi-k3-agent-integration/` untracked = other effort, leave alone.
- No running processes, no open agents.

## First actions

1. `scripts/context-budget.sh register --project devex-review` (skip if the
   SessionStart hook registered; re-run with `--project` for linkage).
2. Check the MERGE GATE above.
3. Confirm the user is present — package (b) is collaborative; if running
   unattended, stop and ask how to proceed.
4. Grep the M20–M22 cards; grill the user on the conventions; implement the
   agreed fixes; close cards per backlog maintenance rules.
5. Pre-flight before any second package: `record`, check headroom; roll over
   rather than continue past WARN.
