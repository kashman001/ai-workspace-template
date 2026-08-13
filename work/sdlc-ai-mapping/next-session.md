# Catchup prompt — sdlc-ai-mapping (paste into a new agent session)

We're resuming sdlc-ai-mapping. Works in any runtime (Claude Code, Codex,
Gemini, OpenCode) — all read `CONTEXT.md` via their entrypoint.

> **This file is the LAUNCHER (catch-up prompt).** Forward-only, REPLACED at
> each rollover. History lives in `handoff.md` (ledger). Convention:
> docs/work-directory-conventions.md.

## Mission

The map work item is **closed** (PR #7 + #8 merged; Minors won't-do). The one
live thread is the **slide deck**: `slides/where-ai-actually-helps.html`,
v2 published at https://claude.ai/code/artifact/6989c82f-fec3-4302-b757-506a1d225d5f
after a 3-agent expert-panel revision. **The user has not yet reviewed v2** —
the promised discussion was interrupted by rollover. Get their feedback,
iterate, then land the source in the repo.

## First actions

1. `scripts/context-budget.sh register --project sdlc-ai-mapping`
2. Re-pose to the user: "Deck v2 is published at the artifact link above —
   walk through it and tell me what to change." Iterate on
   `work/sdlc-ai-mapping/slides/where-ai-actually-helps.html`; republish via
   the Artifact tool **with the URL above as `url`** (a bare publish from a
   new session would create a duplicate artifact).
3. When the user is happy: push a fresh branch with the slides commit(s) and
   open a PR (deck source is committed **locally only** on
   `worktree-sdlc-ai-mapping-s6-close`, whose remote is deleted). Offer the
   optional plainer PPTX translation (decision note: HTML chosen, PPTX
   possible later).

## Constraints already decided (do not re-litigate)

- Deck format: **HTML artifact**, not PPTX-first (`decisions.md` 2026-08-13).
- Deck content: the **map itself** (not the project story), mixed room,
  essentials-only, expert-reviewed. v2 already applied the panel's feedback —
  don't re-run the panel unless the user asks.
- All numbers in the deck are verified against `research-modern-qa.md`
  (Meta TestGen-LLM, OSS-Fuzz, DORA 2024/2025) — don't soften or embellish.
- Map/work-item constraints stand (standalone consumability, Minors won't-do,
  G9→L39 is template-backlog work).

## Read these, in order

1. `handoff.md` (top block) — deck state + what the panel changed.
2. `slides/where-ai-actually-helps.html` — only when editing it.
3. `research-modern-qa.md` — only to verify a number.

## Do NOT reload

- `sdlc-map.md` — deck already distills it; targeted reads only if the user
  asks for content the deck lacks.
- `review-findings.md` / `review2-findings.md` — settled review history.
- `doc-review-orchestrator.md` — not needed.

## State snapshot

- Main: everything merged (PR #4, #6, #7, #8). No open PRs.
- Worktree `sdlc-ai-mapping-s6-close` on branch
  `worktree-sdlc-ai-mapping-s6-close` (remote deleted): holds the slides
  commits + this rollover's bookkeeping, **local only** — do not delete the
  worktree/branch until the deck source is pushed via a fresh branch.
- Artifact: https://claude.ai/code/artifact/6989c82f-fec3-4302-b757-506a1d225d5f
  (favicon 🗺️, title "Where AI Actually Helps").
- `work/kimi-k3-agent-integration/` is another effort's dir — leave it.
