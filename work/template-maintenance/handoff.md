<!--
PURPOSE: This is the LEDGER (provenance log). Append-only, newest block on TOP.
Each "# Session Handoff" block records what happened in one session. Read the
TOP block only; older blocks are in handoff-archive.md. Forward "what to do
next" belongs in next-session.md, NOT here.
Convention: docs/work-directory-conventions.md.
-->

# Session Handoff — 2026-08-29 (session 8, bg: M31 closed & delivered)

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
  (Resolved), branch merged to `main` via PR #40 (`gh pr merge` was
  classifier-blocked; delivered via the authorized ff `git push origin
  m31-close:main`, PR auto-marked merged).
- **Post-delivery:** user renamed session (`template-maintenance #8`); peer
  session R11PolicyDev #202 (downstream insight-dev-ai-workspace) flagged four
  rollover/ledger divergences — all four verified present in the template and
  filed as backlog cards **M32** (check-ledger grammar port), **M33**
  (launch-next-session sNNN lineage-gate blind spot), **L41**
  (ROLLOVER_RELAUNCH default claim), **L42** (decision-log 16KB bar).
  Scorecard 10 open / 69 resolved. Context STOP (152K) fired — via the very
  PostToolUse hook M31 fixed — so the fixes roll to session #9.

**Learnings:**
- Git clobbers *ignored* untracked files on merge/checkout with no warning —
  the "untracked working tree files would be overwritten" guard only covers
  non-ignored files. Any future "start tracking a previously-gitignored file"
  migration must warn users to back up first.

