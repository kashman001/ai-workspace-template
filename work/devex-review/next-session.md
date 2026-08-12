# Catchup prompt — DevEx fix program: next package (M23 / M25 / L-cards)

We're resuming devex-review — the FIX PROGRAM. Works in any runtime
(Claude Code, Codex, Gemini, OpenCode).

> **This file is the LAUNCHER (catch-up prompt).** Forward-only, REPLACED at
> each rollover: what to do next, still-binding constraints, pointers — never
> session history. Past-tense provenance lives in `handoff.md` (append-only
> ledger). Convention: docs/work-directory-conventions.md.

## Freshness check — before anything else

This launcher was written at session-6 rollover **on branch
`worktree-devex-fix-package-b`** (fix package (b) + this rollover, commit
range through the session-6 rollover commit). If `git log --oneline -3` on
main does not show the "Fix M20–M22" / session-6 rollover commits, **the
branch is unmerged — stop and ask the user to merge it** (fast-forward:
`git merge worktree-devex-fix-package-b`). Launching from an unmerged main
is backlog card L33 (three strikes already) — do not proceed on stale state.

## Mission

Execute the next fix package from the remaining open backlog cards:
**M23** (PM-facing entry point — doc writing, largely autonomous with user
review), **M25** (rollover-prep worktree bug — small script fix + test,
three strikes logged), **L32, L33, L35** (low). Propose a package split to
the user first (M25 is now the most-struck open card; M23 is the last
medium). One package per session; pre-flight headroom before any second.

## Read these, in order

1. `docs/template-workspace-backlog.html` — grep the card IDs you're fixing
   (M23, M25, L32, L33, L35).
2. Raw evidence on demand only: `work/devex-review/findings/` per-persona
   files — targeted greps, never full loads.

## Do NOT reload

- `findings/devex-review.md` in full — fix lists already carded.
- The persona review process — complete; never re-dispatch.
- Packages (a)/M19, (c)/M24, (b)/M20–M22 — done and archived; handoff.md
  top block only if needed.
- Spec-workflow conventions — settled 2026-08-12 (decisions.md); do not
  re-litigate skeleton shape, approval flow, vendoring line.

## Constraints already decided (do not re-litigate)

- One work item for the whole fix program; one package per session.
- Template additions stay agent-agnostic and downloader-ready (project
  memory).
- `ROLLOVER_RELAUNCH=auto`; committed work-item env can override per item.
- Telemetry ledger lives at `.context-budget/context-ledger.jsonl`.
- Vendored-skill refreshes: re-copy + re-add provenance comment, pinned
  commit updated (see any vendored SKILL.md header).

## State snapshot

- Branch `worktree-devex-fix-package-b` pushed with package (b) + session-6
  rollover; **merge to main pending** (user action — see Freshness check).
- Root checkout ledger restored clean after M25 strike (see handoff.md).
- `work/kimi-k3-agent-integration/` untracked = other effort, leave alone.
- No running processes, no open agents.

## First actions

1. `scripts/context-budget.sh register --project devex-review` (skip if the
   SessionStart hook registered; re-run with `--project` for linkage).
2. Run the Freshness check above — stop if the branch is unmerged.
3. Grep the open cards (M23, M25, L32, L33, L35); propose the package split
   to the user; execute the agreed package; close cards per backlog rules.
4. Pre-flight before any second package: `record`, check headroom; roll
   over rather than continue past WARN.
