<!--
PURPOSE: This is the LEDGER (provenance log). Append-only, newest block on TOP.
Each "# Session Handoff" block records what happened in one session. Read the
TOP block only; older blocks are in handoff-archive.md. Forward "what to do
next" belongs in next-session.md, NOT here.
Convention: docs/work-directory-conventions.md.
-->

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

