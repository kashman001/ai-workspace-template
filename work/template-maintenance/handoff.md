<!--
PURPOSE: This is the LEDGER (provenance log). Append-only, newest block on TOP.
Each "# Session Handoff" block records what happened in one session. Read the
TOP block only; older blocks are in handoff-archive.md. Forward "what to do
next" belongs in next-session.md, NOT here.
Convention: docs/work-directory-conventions.md.
-->

# Session Handoff — 17 (2026-10-08): doc-gap cards L53, L55–L59 resolved; L54 left for the maintainer

**What got done (on main, one commit per card):**
- L53 `48cef9f` — `docs/context-budget.md` output line gains `cache=`.
- L55 `18f2021` — `docs/workspace-structure.md` "What CONTEXT.md Should
  Contain" gains a Size-and-stability bullet (Z0 budget, no dates).
- L56 `08c330c` — stale `CONTEXT.md` → "Tool & Context Loading" pointers:
  repointed in workspace-structure; dropped in mcp-setup (self-pointer).
- L57 `e562940` — `**Retired:**` notes explained in
  work-directory-conventions and for-non-engineers.
- L58 `d557d56` — ledger-splice gotcha notes `rollover-prep.sh` removal;
  `Last confirmed` → 2026-10-08.
- L59 `f3445b5` — ADR-0009 amendment names the `relaunch_off` gate and
  test R5 instead of the never-committed `docs/session-chain-scenarios.md`.
- Each card archived; scorecard now 6/105/5/0/6.

**Verification:** all 27 `scripts/tests/test-*` suites pass;
`scripts/check-workspace-structure.sh` passes; no operational-knowledge
entries past the 6-month review age.

**For the user:**
- **L54 still open, your call:** when to cut a release and bump
  `TEMPLATE_VERSION` (still `2026-09-30`).
- Main is ahead of origin; not pushed.
- `work/harness-engineering/issues/01-run-checks.md` has an uncommitted
  edit from the other session; left untouched.

# Session Handoff — 15 (2026-08-31): options brief for the 5 open design-gap cards; blocked on user direction

**What got done (worktree branch tm-s15-options-brief):**
- Ran unattended; per the session-15 mission, did NOT design conventions
  solo. Wrote `open-cards-options-brief.md`: per-card proposed shape,
  landing place, and open questions for M27 (testability prompt), M28
  (UAT/beta), M29 (postmortem), L38 (dep/suite health — recommendation:
  route into `work/quality-gates/`), L39 (generic backlog — extract vs.
  declare bring-your-own-tracker).
- No code, test, doc, or backlog changes. Suites untouched (21 green as
  of s14); backlog still 5 open / 77 resolved.

**State:** blocked on user input — every card needs its open questions
answered before building. Next session walks the brief with the user.
Rolled over at user request (they exit and pick up later themselves —
no successor launched); pick up via `scripts/launch-next-session.sh
template-maintenance` from the main checkout so the self-heal ff-pushes
this worktree branch to main first.

Learnings:
- M16 fix verified live a second time: `record` from this session's
  worktree re-pinned the relocated artifact correctly (glob resolution).

Suggested skills next session: none required — conversation over the
brief, then per-card implementation skills as picked (tdd for anything
with scripts/tests).

