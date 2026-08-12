# Catchup prompt — DevEx fix package (c): setup correctness (M24)

We're resuming devex-review — the FIX PROGRAM. Works in any runtime
(Claude Code, Codex, Gemini, OpenCode).

> **This file is the LAUNCHER (catch-up prompt).** Forward-only, REPLACED at
> each rollover: what to do next, still-binding constraints, pointers — never
> session history. Past-tense provenance lives in `handoff.md` (append-only
> ledger). Convention: docs/work-directory-conventions.md.

## MERGE GATE — check before anything else

Session 3 ran as a background job on branch `worktree-devex-m19-clean-day1`
(package (a)/M19: ledger move, prune docs, archive promotion, backlog close).
If `git log --oneline -1` does not show the M19 commit, that branch is
unmerged — **stop and ask the user to merge it first**; starting (c) on a
pre-M19 tree will conflict with it.

## Mission

Execute fix package (c) — backlog card **M24**, "setup correctness +
doc-drift papercuts": make the first documented command succeed on a pristine
clone. Fix list (from the card): runtime-aware hooks check (not
Claude-Code-only); swap check-before-setup order; align conflicting
settings-copy targets; fix the `graphifyy` typo; demote the from-scratch
"Agent Bootstrap" appendix; drop stale literal counts; add the `## Language`
placeholder to the CONTEXT.md template. Close by flipping M24 to Resolved
(+ `Fixed:` line), moving the card to the archive per its maintenance rules.

## Read these, in order

1. `docs/template-workspace-backlog.html` — the M24 card only (grep "M24").
2. Raw evidence on demand: `work/devex-review/findings/dev-persona.md`
   items 1, 3, 4, 5, 12 and `qa-persona.md` A1–A3, B7 — targeted greps.

## Do NOT reload

- `findings/devex-review.md` in full — fix list already carded.
- The persona review process — complete; never re-dispatch.
- Package sequencing — settled (decisions.md): after (c) comes (b) M20–M22
  spec workflow, a COLLABORATIVE session with the user — don't pull forward.
- M19 details — done and archived; see handoff.md top block only if needed.

## Constraints already decided (do not re-litigate)

- One work item for the whole fix program; one package per session.
- Template additions stay agent-agnostic and downloader-ready (project
  memory).
- `ROLLOVER_RELAUNCH=auto`; a committed work-item env can override per item.
- Telemetry ledger now lives at `.context-budget/context-ledger.jsonl` —
  legacy path references are bugs, not conventions.

## State snapshot

- Package (a) work on branch `worktree-devex-m19-clean-day1` (see MERGE
  GATE); main also carries 4 older unpushed commits — push still pending.
- `work/kimi-k3-agent-integration/` untracked = other effort, leave alone.
- No running processes, no open agents.

## First actions

1. `scripts/context-budget.sh register --project devex-review`
   (skip if the SessionStart hook registered; then just re-run with
   `--project` for linkage).
2. Check the MERGE GATE above.
3. Grep the M24 card; verify each papercut still reproduces on the current
   tree (several may have drifted since the review); fix with tests where a
   check script changes (`scripts/tests/`).
4. Pre-flight before any second package: `record`, check headroom; roll over
   rather than start (b) past ~100K.
