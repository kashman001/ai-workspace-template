<!--
PURPOSE: This is the LEDGER (provenance log). Append-only, newest block on TOP.
Each "# Session Handoff" block records what happened in one session. Read the
TOP block only; older blocks are in handoff-archive.md. Forward "what to do
next" belongs in next-session.md, NOT here.
Convention: docs/work-directory-conventions.md.
-->

# Session Handoff — 9 (2026-08-29): M32+M33+L41+L42 delivered to main; audit findings filed

**Summary:** All four peer-flagged cards fixed, tested, and ff-pushed to main
(`dcebc95`, worktree `tm-s9`). Setup-docs audit (mission item 3) ran as a
read-only subagent; 18 findings persisted to
`work/template-maintenance/setup-docs-audit-2026-08-29.md` — fixes not yet
applied. Workspace currency (mission item 2) not yet done.

**Shipped (commit dcebc95):**
- M33: launch-next-session.sh TOP_N grammar widened (sNNN/#N/current forms;
  skip announced). T23o–T23t; suite 207/0.
- M32: check-ledger.py tolerant heading parse (optional num/date, neither =
  malformed), nearest-key-above ordering, archive no longer hidden by broken
  live ledger; tests 9/9; work-directory-conventions.md updated (via fork
  subagent). L41/L42 skill doc rewords.
- Backlog: 4 cards → archive with Fixed: notes; **L43 filed** (two historical
  archives genuinely out of order — repo-wide check-ledger exits 1 until a
  deliberate ledger-content pass; per-project runs green).

**Decisions:** L43 instead of inline archive re-filing (content edits reserved
for a deliberate pass; rejected widening the ordering rule to tolerate
restarts). Delivery included ff-merging `vendor-mattpocock-skills` (launcher's
"fully merged" claim was wrong — session-8's card/launcher commits sat only on
that branch; now truly merged via the main push).

**State:** main = dcebc95; worktree branch `worktree-tm-s9` = main + this
rollover commit. `m31-close` worktree still present (locked), vendor branch
retirable. User's main checkout still on `vendor-mattpocock-skills`, not yet
pulled.

**Learnings:**
- A rollover-bookkeeping commit made on a feature branch (session-8's cards on
  vendor-mattpocock-skills) makes the next session's worktree-from-main miss
  the backlog cards; deliver bookkeeping to main with the close.

**Suggested skills next:** none special — targeted edits + verification;
session-rollover at WARN.

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

