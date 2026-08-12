<!--
PURPOSE: This is the LEDGER (provenance log). Append-only, newest block on TOP.
Each "# Session Handoff" block records what happened in one session. Read the
TOP block only; older blocks are in handoff-archive.md. Forward "what to do
next" belongs in next-session.md, NOT here.
Convention: docs/work-directory-conventions.md.
-->

# Session Handoff — 2026-08-12 (session #5: L37 fixed — house-sale mission COMPLETE)

**Trigger:** normal completion (background session, worktree
`worktree-template-maintenance-s5-l37`; well under WARN).

**What shipped (on the worktree branch, NOT yet on main — user merges):**
- **L37** (portable agent brief): new "Portable agent brief" section in
  `docs/work-directory-conventions.md` (between Verification evidence and
  Naming) + a `briefs/<audience>-vN.md` row in the optional-files table.
  Convention: one sealed file per version (corrections = v(N+1)), supersession
  header ("Supersedes all earlier briefs; discard them"), explicit
  never-reveal section (fact + deflection), ledger notes at issue and at
  staleness, skeleton included. Contrasted with dispatch records
  (same-machine children). Convention-only — no skill (simplicity-first;
  promotable if the pattern recurs); Tier-2 note in `decisions.md`
  (2026-08-12: convention-over-skill).
- Card Resolved → archive (Low, before Decisions); scorecard **1 Open
  (M16) / 66 Resolved**. Doc-only change — no suites affected.
- Backlog hygiene: added the change-log row session 4 omitted for its own
  M26+L36 resolution (marked retroactive), fixed the stale footer date.
- `work/README.md` status row refreshed.

**House-sale mission (M26 → L36 → L37) is COMPLETE.** Remaining open card
M16 was explicitly out of mission scope.

---

# Session Handoff — 2026-08-12 (session #4: M26 + L36 fixed; L37 next)

**Trigger:** context-budget WARN at 123K after closing L36.

**What shipped (main, commits `208a228` + `405810b`, local — ahead of origin):**
- Mission queued in the launcher: house-sale cards M26 → L36 → L37 (filed by
  `bc0f682` from the devex-review evidence pass).
- **M26** (no-git "private" mode): `docs/template-usage.md` §1 third
  instantiation variant + "No-git mode" subsection (paste-in Privacy Posture
  block for CONTEXT.md, Tier-1→Tier-2 decision-capture rewrite, N/A list for
  git-dependent machinery); one-line N/A notes at each point of use
  (CONTEXT.md Tier-1 bullet, decision-log / checkpoint / session-rollover
  skills). No code changes — launch-next-session.sh already degrades
  gracefully without git.
- **L36** (instantiation prune): §5 broadened to the full
  template-development prune list (backlog pair, template-usage itself,
  mcp-fragments, LICENSE swap, README index rows, operational-knowledge trim;
  scaffolding dirs stay — check-workspace-structure.sh expects them);
  setup.sh prune reminder gated on the backlog pair (regression T1c); M19
  ledger-migration shim verified via registry G3. Tests: 72/72 registry,
  28/28 instantiation.
- Both cards Resolved → archive with Fixed: notes; scorecard **2 Open
  (M16, L37) / 65 Resolved**. Tier-2 decision notes for both in
  `decisions.md` (2026-08-12: posture-block-over-CONTEXT-section;
  reminder-over-prune-flag).

**Learnings (parked):**
- The backlog *archive* HTML has no scorecard block — the active file's
  scorecard is the single copy; its counts span both files.

**Suggested skills:** `writing-for-agents` (before authoring the L37
convention text); `decision-log`.
