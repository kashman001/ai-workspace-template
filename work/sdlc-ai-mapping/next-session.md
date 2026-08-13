# sdlc-ai-mapping — session 9 launcher

> **This file is the LAUNCHER** (forward-looking, replaced each rollover).
> What happened is in `handoff.md` (top block — session 8).

## Mission

Everything is built; only landing + cleanup remain, then re-close:
1. **PR #10** (four deck-v3 formulations in `sdlc-map.md`) — open,
   user's merge/review call.
2. **PR #11** (deck repo copy synced to artifact v3, plus the session-8
   ledger/launcher update) — open, user's merge call.
3. After both merge: cleanup, then re-close the item (CLOSED launcher
   per session-6 precedent).

## Constraints already decided (do not re-litigate)

- Deck: HTML artifact, mixed room, essentials-only; numbers verified
  against `research-modern-qa.md`.
- Map: standalone consumability; round-2 Minors won't-do; G9→L39 is
  template-backlog work.
- Deck "asks" slide NOT ported to the map (decisions.md, session 7).
- Deck v3 port was byte-exact from the artifact — do not re-derive or
  "improve" it.

## State snapshot

- PR #10: branch `worktree-sdlc-ai-mapping-s7-deck-learnings` (`09153e0`).
- PR #11: branch `worktree-sdlc-ai-mapping-s8-deck-v3` (`0bb3e8d` + ledger
  commit).
- Artifact (v3 live, label `v3-five-fixes`, version `1786633261-5406`):
  https://claude.ai/code/artifact/6989c82f-fec3-4302-b757-506a1d225d5f
- `.claude/worktrees/sdlc-ai-mapping-s6-close` + branch: fully merged via
  PR #9 — was still locked by a live session (pid 94056) at end of
  session 8; remove worktree (unlock first) + branch once free.
- `.claude/worktrees/sdlc-ai-mapping-s8-deck-v3` + branch: remove after
  PR #11 merges.
- `work/kimi-k3-agent-integration/` is another effort's dir — leave it.

## First actions

1. `scripts/context-budget.sh register --project sdlc-ai-mapping`
2. `gh pr view 10 --json state` / `gh pr view 11 --json state` — merged?
   pull main, delete the merged branches. Open? ask the user.
3. Cleanup worktrees per State snapshot (verify merged + unlocked first).
4. Re-close the item: CLOSED launcher, final ledger block.

## Do NOT reload

- `sdlc-map.md`, the deck HTML, review findings — all settled; read PR
  diffs only if reviewing.
