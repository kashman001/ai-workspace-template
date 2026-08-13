# sdlc-ai-mapping — CLOSED (no next session planned)

> **This file is the LAUNCHER.** The work item was re-closed on 2026-08-13
> (session 9). Everything is built and merged: map (PR #4/#6/#7/#8),
> map learnings (PR #10), deck v3 repo copy (PR #11), session-8 rollover
> bookkeeping (PR #12). Round-2 Minors stay won't-do. Provenance:
> `handoff.md` (top block) and `decisions.md`.

## Deferred cleanup (mechanical, any session or the user)

Two worktrees could not be removed at close — each was still locked by a
live Claude session (s6-close: pid 94056; s8-deck-v3: pid 78591). Both
their branches are **verified merged into main**. Once those sessions
have ended:

```sh
git worktree remove .claude/worktrees/sdlc-ai-mapping-s6-close   # if refused: git worktree unlock <path> first
git worktree remove .claude/worktrees/sdlc-ai-mapping-s8-deck-v3
git branch -d worktree-sdlc-ai-mapping-s6-close worktree-sdlc-ai-mapping-s8-rollover
```

(The s9-close worktree/branch carrying this commit gets the same
treatment after its PR merges.)

## If this item is ever reopened

1. `scripts/context-budget.sh register --project sdlc-ai-mapping`
2. Read `handoff.md` top block, then `README.md` for the item's shape.
3. Deliverables on main: `sdlc-map.md` (map + deck formulations) and
   `slides/where-ai-actually-helps.html` (deck v3). Published artifact:
   https://claude.ai/code/artifact/6989c82f-fec3-4302-b757-506a1d225d5f
   — republish only **with that URL as `url`** to avoid a duplicate.

## Still-binding constraints (if reopened)

- The map must be consumable independent of the workspace.
- Round-2 Minors: won't-do; deck "asks" slide not ported — both by user
  decision, re-litigate only with a fresh reason.
- Deck numbers are verified against `research-modern-qa.md` — don't
  soften or embellish.
- Gap G9 → backlog card L39 is a template-backlog item, not this item's job.

## Follow-on work (separate efforts, not this item)

- `work/feedback-intake/` (G1), `work/quality-gates/` (G2/G3),
  backlog cards M27–M29 + L38/L39.
- `work/kimi-k3-agent-integration/` is another effort's dir — leave it.
