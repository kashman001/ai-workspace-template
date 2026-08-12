# Catchup prompt — DevEx fix program: final package (M23 + L35)

We're resuming devex-review — the FIX PROGRAM. Works in any runtime
(Claude Code, Codex, Gemini, OpenCode).

> **This file is the LAUNCHER (catch-up prompt).** Forward-only, REPLACED at
> each rollover: what to do next, still-binding constraints, pointers — never
> session history. Past-tense provenance lives in `handoff.md` (append-only
> ledger). Convention: docs/work-directory-conventions.md.

## Freshness check — before anything else

This launcher was written at session-7 rollover **on branch
`worktree-devex-fix-package-d`** (fix package (d): M25+L33+L32, commit
`d9c1382` + this rollover commit). If `git log --oneline -3` on main does not
show the "Fix M25+L33+L32" commit, **the branch is unmerged — stop and ask
the user to merge it** (fast-forward: `git merge worktree-devex-fix-package-d`).
Note: `scripts/launch-next-session.sh` now enforces this mechanically (L33
guard, shipped in that same commit) — if you were launched by the script,
the launcher is fresh.

## Mission

Execute the FINAL fix package from the remaining open backlog cards:
**M23** (PM-facing entry point: one-page `docs/for-non-engineers.md` with
status/decisions/contributing + ~6-term glossary, `work/README.md` status
index, audience tags on skills) and **L35** (top-of-doc "Minimal mode"
statement of the 3-command solo subset in `docs/context-budget.md`; label
the rest fleet-only). Both are doc-writing, largely autonomous with user
review. This closes the program: after these, 1 open card remains only if
new findings are filed.

## Read these, in order

1. `docs/template-workspace-backlog.html` — grep the card IDs (M23, L35).
2. Raw evidence on demand only: `work/devex-review/findings/` per-persona
   files (PM findings 1.1, 2.2, 2.3, 4.2, 5.1; dev 11) — targeted greps.

## Do NOT reload

- `findings/devex-review.md` in full — fix lists already carded.
- The persona review process — complete; never re-dispatch.
- Packages (a)/M19, (c)/M24, (b)/M20–M22, (d)/M25+L33+L32 — done and
  archived; handoff.md top block only if needed.
- Spec-workflow conventions — settled 2026-08-12 (decisions.md).
- M25/L33/L32 mechanics — fixed and tested; do not re-verify unless a test
  fails.

## Constraints already decided (do not re-litigate)

- One work item for the whole fix program; one package per session.
- Template additions stay agent-agnostic and downloader-ready (project
  memory).
- `ROLLOVER_RELAUNCH=auto`; committed work-item env can override per item.
- Telemetry ledger lives at `.context-budget/context-ledger.jsonl`.
- Backlog rules: Fixed: note + card → archive + scorecard + changelog row.

## State snapshot

- Branch `worktree-devex-fix-package-d` pushed with package (d) + this
  rollover; **merge to main pending** (user action — see Freshness check).
- Work-item lock released manually at rollover (guard refusal path — see
  handoff.md Learnings).
- `work/kimi-k3-agent-integration/` untracked = other effort, leave alone.
- No running processes, no open agents.

## First actions

1. `scripts/context-budget.sh register --project devex-review` (skip if the
   SessionStart hook registered; re-run with `--project` for linkage).
2. Run the Freshness check above — stop if the branch is unmerged.
3. Grep the open cards (M23, L35); confirm the package with the user (it is
   the last one — both cards fit one session); execute; close cards per
   backlog rules.
4. Pre-flight before anything extra: `record`, check headroom; roll over
   rather than continue past WARN.
