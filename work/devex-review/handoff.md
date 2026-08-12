<!--
PURPOSE: This is the LEDGER (provenance log). Append-only, newest block on
TOP. Each "# Session Handoff" block records what happened in one session.
Read the TOP block only; older blocks are in handoff-archive.md. Forward
"what to do next" belongs in next-session.md, NOT here.
Convention: docs/work-directory-conventions.md.
-->

# Session Handoff — 2026-08-11 (session 4: fix package (c)/M24 shipped)

Ran as a background job in worktree `worktree-devex-m24-setup-correctness`
(`.claude/worktrees/devex-m24-setup-correctness`) — **all work committed on
that branch as `a7efb94` "Fix M24: …", NOT on main; user must merge.** The
session-3 branch WAS merged before this session started (merge gate passed).
M24 "setup correctness + doc-drift papercuts" fully shipped and closed; all
seven papercuts re-verified on the current tree before fixing:

- **Runtime-aware hooks check** in `scripts/check-dependencies.sh`:
  committed codex/gemini/opencode/copilot wiring satisfies it; the Claude
  settings copy required only when `claude` is installed. New suite
  `scripts/tests/test-check-dependencies.sh` (5 asserts, sandboxed PATH).
  Decision note appended to decisions.md.
- **Order swapped** in `docs/workspace-setup.md` (setup.sh before
  check-dependencies.sh); dependencies runbook hooks row updated.
- **Settings-copy target aligned** on `.claude/settings.local.json`:
  example `_comment`, `docs/context-budget.md` ×2.
- **`graphifyy` typo** fixed.
- **Agent Bootstrap demoted**: moved to end-of-doc "Appendix … (degraded
  path)" in `docs/workspace-structure.md` with prefer-cloning banner +
  conditional opener; TOC/cross-refs updated; HTML regenerated.
- **Counts de-drifted**: template-usage.md skills list uncounted,
  docs/README.md suite count dropped, scripts tree completed (6 missing
  scripts, hooks/ summarized).
- **CONTEXT.md**: `## Language` placeholder added; hook-wiring claim
  qualified (Claude copy is setup-materialized).
- **Backlog**: M24 → Resolved + archived (before M19), scorecard 8/55.
  Tests green: new suite 5/5, agent-entrypoints 8/8, structure check,
  parameterization.

Suggested skills for next session: none mechanical — package (b) is
collaborative (`grilling`/spec work with the user); `session-rollover` at
WARN/STOP.

Learnings:
- `docs/operational-knowledge.md:25` still points at `work/automatic-session-rollover/relaunch-analysis.md` (prunable dir) — carried from s3; sweep candidate for a later package.
- Worktree bash guard rejects compound commands mixing loops/redirects with repo paths — keep worktree commands single-purpose; split extract/assemble steps.

# Session Handoff — 2026-08-11 (session 3: fix package (a)/M19 shipped)

Ran as a background job in worktree `worktree-devex-m19-clean-day1`
(`.claude/worktrees/devex-m19-clean-day1`) — **all work is committed on that
branch, NOT on main; user must merge** (bg sessions may not merge/push main).
M19 "clean day-1 state" fully shipped and closed:

- **Ledger moved** to `.context-budget/context-ledger.jsonl`
  (`context-budget.sh`, statusline script, both test suites, docs,
  `.gitignore`); self-cleaning migration shim folds legacy ledgers in at
  script load — see the new decisions.md note (top). New G3a–c asserts.
- **Prune-`work/` step**: `docs/template-usage.md` §5 (+ step-4 bullet in
  `setup-guide.html`) — work/ is a worked example, deletable day 1.
- **Promoted to `docs/archive/`**: ledger-analysis.md,
  ledger-analysis-heavy-deployment-2026-08-11.md,
  rollover-cost-analysis-2026-08-11.md, design.html →
  context-budget-design.html.
- **Citations repointed** in session-rollover SKILL, context-budget.sh
  header, copilot-vscode hook, context-inspect.sh, context-budget.md; the
  `copilot-vscode-hook-research-findings.md` pointer was dangling (file never
  imported) — dropped, conclusion already inline.
- **Backlog**: M19 card → Resolved + archived, history row added, scorecard
  9 open / 53 resolved. All 10 test suites green (402 asserts).
- Living pointers inside `work/context-decay/` (README, next-session) updated
  to the new paths; its handoff/spec history left frozen.

Suggested skills for next session: backlog maintenance (M24 card), `tdd` for
check-script changes, `session-rollover` at WARN/STOP.

Learnings:
- Claude bg-job worktrees branch from origin/main — with unpushed local commits, `git merge --ff-only main` first or the worktree is stale.
- `docs/operational-knowledge.md:25` still points at `work/automatic-session-rollover/relaunch-analysis.md` (prunable dir) — sweep candidate for a later package.
- `rollover-prep.sh` rotated only 1 of 2 older handoff blocks ("rotated 1 block(s)", session-1-close left behind; fixed by hand). If it repeats, file a card.
