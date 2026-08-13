# sdlc-ai-mapping — session 8 launcher

> **This file is the LAUNCHER** (forward-looking, replaced each rollover).
> What happened is in `handoff.md` (top two blocks — session 7 and the
> parallel session-6-cont. block that built the deck; read BOTH).

## Mission

Land the two open threads, then re-close the item:
1. **PR #10** (four deck-v3 formulations ported into `sdlc-map.md`) —
   open, awaiting user merge/review.
2. **Deck repo copy v2 → v3** — `slides/where-ai-actually-helps.html`
   is on main (landed via PR #9) but still v2; the live artifact is v3
   (five review fixes, session-7 handoff block lists them). WebFetch the
   artifact, update the file on a fresh branch, PR. Optional: offer the
   plainer PPTX translation (decided: HTML first).

## Constraints already decided (do not re-litigate)

- Deck: HTML artifact, mixed room, essentials-only; numbers verified
  against `research-modern-qa.md` — don't soften or embellish.
- Map: standalone consumability; round-2 Minors won't-do; G9→L39 is
  template-backlog work.
- Deck "asks" slide NOT ported to the map (decisions.md, session 7).

## State snapshot

- Main checkout: `main` at `792393a` (session-7 rollover + addendum
  pushed). PR #10 branch `worktree-sdlc-ai-mapping-s7-deck-learnings`
  (`09153e0`) pushed.
- `.claude/worktrees/sdlc-ai-mapping-s6-close` + branch: fully merged via
  PR #9 (verified: `828e850` is ancestor of main) — remove worktree
  (unlock first) and branch once the user is out of the worktree.
- Artifact: https://claude.ai/code/artifact/6989c82f-fec3-4302-b757-506a1d225d5f
  (favicon 🗺️, title "Where AI Actually Helps", label `v3-five-fixes`).
- `work/kimi-k3-agent-integration/` is another effort's dir — leave it.

## Read these, in order

1. `handoff.md` — top TWO blocks (session 7 + session 6 cont.).
2. `gh pr view 10` / `gh pr diff 10` — only when merging/reviewing.
3. `slides/where-ai-actually-helps.html` (s6-close worktree) — only when
   updating it to v3.

## Do NOT reload

- `sdlc-map.md` in full — PR #10 touches only front matter + gap-register
  intro; read the diff.
- `review-findings.md` / `review2-findings.md` / `doc-review-orchestrator.md`
  — settled history.
- The deck's full HTML — WebFetch the artifact only when editing.

## First actions

1. `scripts/context-budget.sh register --project sdlc-ai-mapping`
2. `gh pr view 10 --json state` — merged? pull main + delete the s7
   branch. Open? ask the user: merge or review.
3. Deck thread (Mission item 2): update repo copy to v3, fresh branch, PR.
4. Cleanup: remove s6-close worktree (unlock first) + branch once the
   user is out of it.
5. After everything lands: re-close the item (CLOSED launcher per
   session-6 precedent).
