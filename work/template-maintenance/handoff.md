<!--
PURPOSE: This is the LEDGER (provenance log). Append-only, newest block on TOP.
Each "# Session Handoff" block records what happened in one session. Read the
TOP block only; older blocks are in handoff-archive.md. Forward "what to do
next" belongs in next-session.md, NOT here.
Convention: docs/work-directory-conventions.md.
-->

# Session Handoff — 2026-08-29 (session #8: M31 closed & delivered)

**Trigger:** planned close per launcher; ran as a background job in worktree
`m31-close` (branched off `vendor-mattpocock-skills`).

**What happened:**
- Finished the M31 docs: context-budget.md (vendor table row, registration +
  `--clear` + SessionEnd paragraphs, new existing-workspace migration note),
  CONTEXT.md, workspace-structure.md (§`.claude/`, tracked/untracked tables,
  gitignore excerpt), runbooks/dependencies.md; repointed
  check-dependencies.sh remediation + hook/statusline header comments.
- Tests: new X10 block in test-vendor-budget-hooks.sh (settings.json tracked,
  valid JSON, 4 hooks + statusLine resolver-form, hook-free example) — 85/85;
  repointed test-rollover-clear-seed.sh H7 (was red against the stripped
  example) — 27/27; session-loop 68/68, turn-end-exit 5/5. Fresh-clone
  setup.sh simulation verified (local seeded hook-free, tracked wiring
  present).
- **Migration reality check:** live merge test at a660150^ showed git does
  NOT refuse — it silently overwrites the ignored untracked
  `.claude/settings.json` (personal copy lost). Docs now say save it aside
  BEFORE pulling. This contradicts the collision wording session #7 expected.
- Two-axis code-review (standards + spec subagents) run; all findings
  addressed (stale check-dependencies remediation, red H7b, resolver-rationale
  restored to the vendor table, test prefix deduped).
- **Delivered:** close commit on top of a660150, backlog M31 → archive
  (Resolved, 6 open / 69 resolved), branch merged to `main` via PR, pushed.

**Learnings:**
- Git clobbers *ignored* untracked files on merge/checkout with no warning —
  the "untracked working tree files would be overwritten" guard only covers
  non-ignored files. Any future "start tracking a previously-gitignored file"
  migration must warn users to back up first.

# Session Handoff — 2026-08-29 (session #7: M31 — Claude Code hook wiring committed, partial)

**Trigger:** context STOP (~184K) mid-M31; user directed rollover + relaunch via
launcher, successor to finish testing, review, and delivery.

**What happened (branch `vendor-mattpocock-skills`, ahead 1 unpushed):**
- Pulled the session-loop hardening set (branch ff 48e3f79→036a0af; local main
  ff'd to 0dc3bac; supervisor/Stop-hook/research-wave landed).
- Diagnosed "auto relaunch doesn't happen even with the supervisor": staging +
  sentinel are still agent instructions; total-forget maps to silent
  "deliberate quit" exit 0 (session-loop.sh:172); and THIS checkout's
  `.claude/settings.json` (Aug 6) lacked the Stop hook + used the broken bare
  `$CLAUDE_PROJECT_DIR` form → supervisor would block in eval. Root cause:
  setup.sh:43 `copy_if_missing` never reconciles → filed backlog **M31**.
- **Commit a660150** (fix M31, partial): `.claude/settings.json` now TRACKED
  (hooks + statusLine, resolver form, incl. session-loop Stop hook);
  `.gitignore` un-ignores it with rationale; `settings.json.example` stripped
  to personal starter (permissions/MCP/connectors); backlog M31 card added
  (Open). Remaining steps are in the commit body + next-session.md.
- STOP arrived in-band via the very PostToolUse hook the fix repaired.

**Session numbering correction:** counter held 5 but ledger shows #6 ran
(2026-08-16, ad-hoc, never seq-synced); this session is #7, seq-sync raised.

**Learnings:**
- Claude Code schema-validates tracked `.claude/settings.json` — `_comment`
  is rejected there (fine in `.example` and `settings.local.json`).
- Other 5 runtimes' hook wiring already committed — M31 was Claude-Code-only.

**Suggested skills:** code-review (pre-delivery), decision-log (if scope moves).

# Session Handoff — 2026-08-16 (session #6: M30 — Matt Pocock skill set vendored)

**Trigger:** work-unit complete at context-budget WARN (~127K); PR open,
merge pending.

**What shipped (branch `vendor-mattpocock-skills`, PR #23 — user merges):**
- **M30** (filed + resolved same pass): all 27 curated Matt Pocock skills now
  vendored at `skills/<name>/`, pinned to upstream `068b6e0` (2026-08-15,
  MIT), agent-agnostic (every runtime reads SKILL.md; upstream
  `agents/openai.yaml` ships too). 22 new + the 5 previously vendored
  refreshed. Upstream `in-progress/` + course-tooling skipped deliberately.
- `scripts/sync-vendored-skills.sh` — refresh for both classes (pristine
  re-copy + stamp; adapted: frontmatter/comment preserved, body swapped).
  Verified idempotent + graceful without the upstream clone.
- `skills/vendored-skills.md` — index, slash map, pristine/adapted classes,
  embedded MIT license, `code-review` name-collision flag.
- 10 `.claude/commands/` wrappers for user-invoked skills.
- CONTEXT.md: one grouped vendored-set entry. `recommended-tooling.md` §3
  flipped: vendored = default path, global symlinks = maintainer path (+
  duplicate-copy note & `.syncignore` fix). Backlog M30 card → archive;
  scorecard 6/67/4/0/6. Tier-2 decision note in `decisions.md` (2026-08-16,
  vendor > submodule/plugin/setup-script).
- Fresh-clone verification passed (27 stamped skills, zero abs paths).

**Not done / follow-ups:**
- PR #23 merge — user's call.
- Optional, origin machine only: dedupe global `~/.claude/skills` symlinks
  vs vendored copies (documented in recommended-tooling.md §3).

