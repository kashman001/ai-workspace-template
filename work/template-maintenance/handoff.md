<!--
PURPOSE: This is the LEDGER (provenance log). Append-only, newest block on TOP.
Each "# Session Handoff" block records what happened in one session. Read the
TOP block only; older blocks are in handoff-archive.md. Forward "what to do
next" belongs in next-session.md, NOT here.
Convention: docs/work-directory-conventions.md.
-->

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

---

# Session Handoff — 2026-08-07 (session #3: L17+L18 resolved — backlog at 0 Open)

**Trigger:** normal completion (background session; 107K tokens, under WARN).

**What shipped (branch `worktree-l17-l18-backlog-fixes`, NOT yet on main —
worktree-isolated background session; user merges):**
- L17 (four deferred rollover-script issues): attach-session.sh
  live-but-unlocked message reworded to match its flags (T4d updated); both
  `ls -t` glob loops (attach-session.sh, own_record in
  launch-next-session.sh) made space-safe via `while IFS= read -r`;
  opencode_measure SQL-escapes `$PWD`/`$sid`; the stale registry-suite
  filename was only in the test file's own `# File:` header — the
  docs/context-budget.md reference was already correct.
- L18: per-variable precedence around the context-budget.env source in
  context-budget.sh (capture-before/restore-after, the launch-next-session.sh
  ROLLOVER_* pattern). New regression test T16 — verified red on the pre-fix
  script, green after. Tier-2 decision note (capture/restore over default-only
  env assignments; the latter inverts the per-item override chain).
- All eight test suites green (343 asserts). Backlog: L17+L18 cards moved to
  archive with Fixed: notes; scorecard 0 Open / 46 Resolved; change-log row.

**Learnings (parked):**
- L30's session added no change-log row for L30 in the backlog (card+scorecard
  only); left as-is per surgical-changes.

---

