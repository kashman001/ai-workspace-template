<!--
PURPOSE: This is the LEDGER (provenance log). Append-only, newest block on TOP.
Each "# Session Handoff" block records what happened in one session. Read the
TOP block only; older blocks are in handoff-archive.md. Forward "what to do
next" belongs in next-session.md, NOT here.
Convention: docs/work-directory-conventions.md.
-->

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

# Session Handoff — 2026-08-07 (L30: GitHub MCP removed, gh required; rollover)

**Trigger:** user-requested rollover. Same conversation continued past the
2026-08-06 STOP rollover and shipped one more approved plan.

**What shipped (all on `main`, clean tree, pushed):**
- `2ba9f11` — L30: GitHub MCP fully removed; `gh` CLI promoted to required
  prerequisite (20 files, −101 net). Fragment deleted (re-add recipe in
  `mcp-fragments/README.md`), PAT-export plumbing gone (auth runbook is just
  `gh auth login`), docker dep dropped, ADR-0002 amended, setup-guide.html
  swept (exploration had missed it). Both check scripts verified passing.
- Launcher touch-up commit marking L30 done in the floor-trim thread.
- Backlog: L30 resolved card (scorecard 44); Tier-2 decision note in
  `decisions.md` (full-removal over escape-hatch; `Promote?: no`, ADR-0002
  amendment carries it).

**Learnings (parked):**
- github MCP on this machine was project-local only (stale pre-split live
  `.mcp.json`); user-scope `~/.claude.json` has no `mcpServers` at all —
  `claude mcp list` confirms clean. No user-scope removal was needed.
- Old worktree `.claude/worktrees/session-30-issue-10/` still holds pre-L30
  file copies (separate checkout; intentionally untouched).

---

# Session Handoff — 2026-08-06 (context audit: L25–L29 shipped; STOP rollover)

**Trigger:** context-budget STOP (151K, then 157K mid-rollover) right after the
L29 commit. All work committed and pushed; clean tree.

**What shipped (three commits on `main`):**
- `f9bceae` — L25–L27 demand-load trims: context-budget.md section index +
  grep-the-header access note; decision-log skill heredoc-append + 16KB
  archive rule; CONTEXT.md condensed 14.0→12.6KB (graphify removal steps
  moved into recommended-tooling.md §5, ending its circular pointer).
- `4b94d76` — L28: `register` tolerates a missing/empty transcript at
  SessionStart (`method=deferred status=OK`, exit 0) instead of "error:
  measurement failed"; register instruction scoped so Claude Code agents
  don't re-run what the hook already did. Verified live.
- `a3da781` — L29: /context under-reports ~10K until the first real message
  (harness listing attachments materialize with turn one); gotcha documented
  in `docs/operational-knowledge.md`. Tracker was correct throughout.
- Backlog: L25–L29 resolved cards in the archive file, scorecard 43 Resolved.
- Tier-2 decision note (index-over-split, condense-over-delete) in
  `decisions.md`.

**Learnings (parked):**
- Empty-session floor measured ~44.7K (2026-08-06): harness-fixed ~22.5K;
  superpowers plugin ~1.8K; MCP-attributable ~2.2K (github ~900,
  chrome ~500 + ~800 hidden in system prompt/skill, claude.ai connectors
  ~410, rest small); skills roster ~4.9K. Per-server/per-skill tables live
  only in the 2026-08-06 session transcript — re-derive from a fresh
  session's jsonl if needed (method: jq over attachment types).
- Warp terminal plugin injects a `hook_success` envelope per PostToolUse —
  model-visible cost unmeasured; worth checking if it bites again.

---
