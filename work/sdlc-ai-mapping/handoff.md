<!--
PURPOSE: This is the LEDGER (provenance log). Append-only, newest block on
TOP. Each "# Session Handoff" block records what happened in one session.
Read the TOP block only; older blocks are in handoff-archive.md. Forward
"what to do next" belongs in next-session.md, NOT here.
Convention: docs/work-directory-conventions.md.
-->

# Session Handoff — 2026-08-13 (session 7: deck reviewed + fixed, four deck learnings ported to map as PR #10 — ITEM REOPENED pending merge)

Item reopened with a fresh reason (user walkthrough of the presentation
deck). Two units shipped:

**1. Deck "Where AI Actually Helps" reviewed and fixed (v3).** Artifact:
https://claude.ai/code/artifact/6989c82f-fec3-4302-b757-506a1d225d5f
(user-owned; version label `v3-five-fixes`). All headline numbers verified
against `research-modern-qa.md` — no factual errors found. Five review
fixes applied and republished: dense slide 9 split into paradox-mechanism
+ seams slides (audit finding promoted to callout); slide-4 ring caption
now explains Design folds into build; "two loudest pitches" sentence moved
card→callout on the hype slide; DORA note links dora.dev + 2024/2025
reports; progress/counter exclude the 2 backup slides (now "1 / 12" +
"backup n / 2") and arrow-key scrolling fixed (slides take focus;
appendix table focusable). v3 source: the artifact (WebFetch it) — the
repo copy `slides/where-ai-actually-helps.html` on branch
`worktree-sdlc-ai-mapping-s6-close` is still v2, local-only.

**2. Four deck learnings ported back to sdlc-map.md — PR #10 (OPEN,
awaiting user merge):** branch `worktree-sdlc-ai-mapping-s7-deck-learnings`
(commit `09153e0`). Claim 4 + mechanism (writing time→review time,
bottleneck moves to human checkpoints); claim 2 recast as if/then rule;
three-sentence refrain closes the preamble; gap register notes both
High-severity gaps are seams, not stages. Rejected: porting the "asks"
slide (pitch, not map) — decision note in `decisions.md`. Touches only
front matter + gap-register intro.

**Not done / CORRECTION:** the `s6-close` worktree holds the deck's v2
source commits, LOCAL-ONLY (predecessor ledger block below) — do NOT
remove it until the slides land on a fresh branch + PR; the user's
"fully merged" was inaccurate for the slides commits.

Suggested skills next session: none beyond session-rollover bookkeeping;
`code-review` only if the user wants PR #10 reviewed before merge.

# Session Handoff — 2026-08-13 (session 6 cont.: PR #8 merged, item closed; slide deck v2 built, discussion with user pending)

Second half of session 6, after the close-out. PR #8 (ledger/launcher/decision
close-out) **merged**; s6-close remote branch deleted. The user then asked for
**slides communicating the map** — mixed room (leadership + engineers),
essentials-only, **HTML artifact** format (decision note in `decisions.md`;
PPTX rejected, plainer translation possible later).

Shipped: **deck v2** — `work/sdlc-ai-mapping/slides/where-ai-actually-helps.html`,
published at https://claude.ai/code/artifact/6989c82f-fec3-4302-b757-506a1d225d5f
(13 slides: 11 core + 2 backup). v1 was critiqued by a 3-agent expert panel
(storytelling / exec-comm / slide-design); v2 applied all convergent feedback:
DORA-paradox hook up front (−1.5% throughput / −7.2% stability per +25% AI
adoption, 2024; 2025 = amplifier), three-claim spine, ring diagram only (full
graph → backup), measured wins with real numbers (verified against
`research-modern-qa.md`: Meta 73%/25%, OSS-Fuzz ~30%/26 vulns), hype split
from amplifier, tax+seams merged, decision-asks slide, refrain close, plus six
SVG geometry/contrast fixes.

**Pending: the user was told "come back and we'll discuss" — they have NOT yet
reviewed v2.** Rollover (STOP 162K) interrupted before that conversation.

Deck source committed locally on `worktree-sdlc-ai-mapping-s6-close` (remote
deleted — local only until the deck is final; then push fresh branch + PR).

Suggested skills next session: none up front; `artifact-design` reload only if
restyling the deck heavily.

# Session Handoff — 2026-08-13 (session 6: PR #7 merged, cleanup done, Minors closed won't-do — ITEM CLOSED)

Session 6 found **PR #7 already merged** (2026-08-13 14:12 UTC, merge commit
`726bbed` on main) — the full round-2 fix pass is on main. Cleanup done:
removed the `sdlc-ai-mapping-s4-review` and stale `sdlc-ai-mapping-s2`
worktrees and deleted both branches locally and on origin (both fully merged,
both worktrees clean; verified before deletion).

Sourcery's PR-#7 review left two advisory comments the user merged past
without requesting changes: (1) the preamble's audience-routing paragraph is
dense — suggest a per-reader bullet list; (2) GAP cross-reference wording
varies across node entries vs. the register — suggest standardizing. Both
overlap the leftover round-2 Minors territory (`review2-findings.md` §3);
recorded here, not acted on.

**Minors decision resolved**: the user closed the remaining round-2 Minors
(session-5 list below + the two Sourcery comments) as **won't-do**
(2026-08-13; decision note in `decisions.md`). **The work item is closed.**
No map edits were made this session; only this ledger block, the launcher,
and `decisions.md` were updated (shipped via PR #8).

