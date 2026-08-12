<!--
PURPOSE: This is the LEDGER (provenance log). Append-only, newest block on
TOP. Each "# Session Handoff" block records what happened in one session.
Read the TOP block only; older blocks are in handoff-archive.md. Forward
"what to do next" belongs in next-session.md, NOT here.
Convention: docs/work-directory-conventions.md.
-->

# Session Handoff — 2026-08-12 (session 5: M24 verified, merged, cleaned up)

Launched as a background job from main's **stale** launcher (still pointing at
package (c)/M24 because session 4's branch was unmerged — L33 third strike,
card updated). EnterWorktree resumed session 4's worktree, surfaced its
commits, and a redo was averted: instead of re-executing M24 this session
**verified** session 4's work (all seven fixes spot-checked on the branch;
`scripts/tests/test-check-dependencies.sh` 5/5) and reported.

User then went interactive and directed:
- Fast-forward merge of `worktree-devex-m24-setup-correctness` into main
  (`cf502d9..75fa589`, 17 files) and push of main to origin (including the
  4 older unpushed commits).
- Removal of the local worktree + branch and the remote branch — M24 work is
  now fully consolidated on pushed main; no side branches remain.

No new template changes this session beyond the L33 evidence line in the
backlog. Rollover requested by the user to start package (b) fresh.

Suggested skills for next session: `grilling` for the M20–M22 convention
design (collaborative); `session-rollover` at WARN/STOP.

Learnings:
- L33 (launcher staleness) third strike — now recorded on the card itself;
  a background-job successor should treat "worktree resume with unexpected
  commits" as a stop-and-verify signal, which worked here.

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

