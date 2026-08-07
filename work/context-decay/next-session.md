> **This file is the LAUNCHER (catch-up prompt).** Forward-only, and REPLACED
> at each rollover: it holds what to do next, still-binding constraints, and
> pointers — never session history. Past-tense provenance lives in `handoff.md`
> (the append-only ledger). Convention: docs/work-directory-conventions.md.

# Next Session — context-decay

## Mission

**Act on the 2026-08-07 audit** (numbers in the TOP block of `handoff.md`).
The tooling is done: `context-inspect.sh --phases`, `context-experiment.sh`,
`capture-rollover-options.sh` (all in `scripts/`, doc:
`docs/context-budget.md` → Quickstart — agent). Next:

1. Ask the user to prioritize the trim candidates: skill_listing ~4.0K
   (largest workspace lever), project CLAUDE.md ~3.1K (template-only
   sections), superpowers SessionStart ~1.9K + claude.ai connectors
   (user-global — need user action, not repo changes). Open a work item or
   backlog card per accepted trim, then execute by priority.
2. After any trim lands: `scripts/context-experiment.sh` for the
   before/after S1/S2/S3 comparison (that's the tool's purpose).
3. Settle the open attribution question: do Warp PostToolUse `hook_success`
   records enter model context? Compare a `--phases` run on a Warp session
   vs a non-Warp one (residual analysis) — L19 card has the background.

## Read these, in order

1. This file.
2. TOP block of `handoff.md` (session #3: audit numbers + what shipped).

## Do NOT reload

- `plan-snapshot-tool.md`, `context-decay-spec.md`, `design.html` —
  implemented; reference only.
- **Gemini auth on this machine** — settled dead ends
  (`docs/operational-knowledge.md`); do not retry.
- `ledger-analysis.md` — re-read only at the next analysis pass.

## Open items (unchanged, externally gated)

1. Gemini live-response verification — needs a user `GEMINI_API_KEY`.
2. Copilot CLI adapter live verification — needs Copilot CLI installed.
3. Next ledger analysis — after ~40 entries / first `method=estimate` rows /
   first non-claude rows.

## State snapshot

Session #3 worked on branch `worktree-context-decay-snapshot-tool`
(worktree), committed + pushed; **verify it's merged to `main` before
trusting this launcher** (if `git log main..origin/worktree-context-decay-snapshot-tool`
is non-empty, merge first — a draft PR may already exist).
`work/context-decay/.rollover-options` in the main checkout carries
`ROLLOVER_OPT_APPROVAL=auto` — successors launch in auto permission mode
via `launch-next-session.sh`.

## First actions

1. `git fetch origin` + confirm the snapshot-tool branch is merged and
   `git log HEAD..origin/main` is empty (staleness race — backlog
   2026-08-06 finding).
2. `scripts/context-budget.sh register` (skip if the SessionStart hook ran).
3. Follow the Mission — step 1 needs the user's priority call.
