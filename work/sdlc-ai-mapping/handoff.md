<!--
PURPOSE: This is the LEDGER (provenance log). Append-only, newest block on
TOP. Each "# Session Handoff" block records what happened in one session.
Read the TOP block only; older blocks are in handoff-archive.md. Forward
"what to do next" belongs in next-session.md, NOT here.
Convention: docs/work-directory-conventions.md.
-->

# Session Handoff — 2026-08-13 (session 10: item briefly reopened — standalone map built, published, both maps reframed to three views)

Interactive session, user-driven. Shipped:

- **`sdlc-map-standalone.md` (new):** workspace-independent version of the
  map for discussing AI in the SDLC outside this workspace — template
  overlay, gap register, and template glossary terms stripped; evidence
  sources (DORA, TestGen-LLM, OSS-Fuzz) named inline so tiers stand alone.
- **Both maps reframed to three views** (user decision): legend hoisted to
  the top, "Two views" → "Three views", View 1 renamed "the phases", the
  artifacts appendix promoted to View 3 right after the graph, all
  per-node "Appendix → Nx rows" pointers → "View 3 → Nx rows".
  `sdlc-map.md` keeps all template content unchanged, just reordered.
- **Standalone published as a NEW artifact** (separate from the deck):
  https://claude.ai/code/artifact/f86be94e-2362-4342-bddf-0105f395a204
- Consistency-checked both docs (no stale refs, equal row/pointer counts,
  companions nested under View 2 in both). README files list updated.

Leftover from before this session: the s9-close worktree still holds
unmerged commit `b1eebdc` (launcher cleanup note) — unrelated to this
session's changes.

# Session Handoff — 2026-08-13 (session 9: item RE-CLOSED — worktree cleanup deferred, both held by live sessions)

Background session, bookkeeping only, per the session-9 launcher:

- Pulled main: already current at `d264ee2` (PR #12 merge — the session-8
  rollover bookkeeping had landed as its own PR since the launcher was
  written).
- Verified both leftover branches (`worktree-sdlc-ai-mapping-s6-close`,
  `worktree-sdlc-ai-mapping-s8-rollover`) are merged into main.
- **Worktree removal deferred again — both locked by live Claude
  sessions** (s6-close: pid 94056, the same session as at session-8
  close; s8-deck-v3: pid 78591 with an active `caffeinate`, now holding
  the s8-rollover branch). Removing a worktree under a live process was
  judged unsafe; exact removal commands are in the CLOSED launcher's
  "Deferred cleanup" section for whoever gets there first.
- Replaced the launcher with a CLOSED launcher (session-6 `40d2451`
  precedent, updated for PRs #9–#12 and the deferred cleanup).

No content changes anywhere — item closed.

# Session Handoff — 2026-08-13 (session 8 close: PRs #10 + #11 MERGED, branches deleted — only cleanup + re-close remain)

Continuation of the session-8 background job, user in the loop. Shipped:

- **PR #11 merged** (`c7ab560`): deck repo copy now = artifact v3, plus
  session-8 ledger/launcher.
- **PR #10 merged** (`24f0919`, main tip): four deck formulations in
  `sdlc-map.md` + decision note. Needed a conflict fix first — both the
  branch and main had appended a decision note to `decisions.md`
  (deck-v3-port vs HTML-artifact); resolved by keeping both,
  chronological order (`21a3bda`).
- Both PR branches deleted, local + remote. The user pulled main in the
  primary checkout (confirmed in chat).
- **Not done:** s6-close worktree removal — still locked by live claude
  process pid 94056 (cwd inside it). The s8-deck-v3 worktree is
  detached at `24f0919`, branch already deleted; removable any time.

All build/land work on this item is now complete; session 9 is cleanup
+ writing the CLOSED launcher (session-6 precedent).

Learnings: a worktree-isolated session cannot run git against the
user's main checkout (hook-enforced) — hand `git pull` to the user.

Suggested skills next session: none — bookkeeping only.

# Session Handoff — 2026-08-13 (session 8: deck repo copy synced to v3 as PR #11 — both PRs open, awaiting user)

Background session. One unit shipped, one blocked, one deferred:

**1. Deck repo copy v2 → v3 — PR #11 (OPEN):** branch
`worktree-sdlc-ai-mapping-s8-deck-v3` (commit `0bb3e8d`). The v3 source
was extracted **verbatim** from the published artifact (live version
`1786633261-5406`, label `v3-five-fixes`) and the v2→v3 diff verified to
contain exactly the five session-7 review fixes, nothing else. Method
worth remembering: WebFetch on an owned claude.ai artifact URL saves the
full raw HTML to a file under the session's tool-results dir — no
browser gymnastics needed (direct fetches of the claudeusercontent
frame origin are CORS/redirect-blocked). This ledger block + the new
launcher ride on the same PR.

**2. PR #10 (map learnings): still OPEN** — merge/review is the user's
call; nothing changed there this session.

**3. s6-close worktree NOT removed:** still locked by a live Claude
session (pid 94056, cwd inside the worktree, started 13:54). Removal
stays deferred until that session ends.

