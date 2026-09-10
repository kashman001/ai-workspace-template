# Decisions — template-improvement-review

Tier-2 notes (see `skills/decision-log/SKILL.md`). Newest on top.

## 2026-09-10 — L45: share local-only work items into worktrees by symlink (not copy-back, not a guard exemption)

**Decision:** a new `scripts/link-local-work.sh` symlinks every ignored
(`.gitignore` or `.git/info/exclude`) top-level `work/<item>/` from the main
checkout into a worktree that lacks it, so a worktree-isolated session reads
and writes the real directory and nothing dies with the worktree. It runs on
every per-tool hook firing (shared `context-budget-hook-lib.sh`, so all six
runtimes get it, unthrottled so no write can race the link) and at
`context-budget.sh register`. Pre-existing real directories in the worktree
are never touched; untracked-but-not-ignored items are never linked (a
symlink would be committable).
**Why:** the "repo guard" named on the card does not exist in repo code —
the redirect is the runtime's own worktree isolation (Claude Code
`EnterWorktree` / `isolation: worktree` / background sessions), so
"exempt the dirs from the guard" is only realizable by sharing the directory
in. Verified in-session that Claude Code's Write/Edit tools write through a
symlinked *directory* (the symlink-file refusal in CONTEXT.md is about
symlinked files).
**Rejected:** (a) guard exemption — no repo-owned guard to edit. (b) copy-back
on worktree exit / in `rollover-prep.sh` — lossy by construction: a worktree
whose only changes are ignored files looks *unchanged* and is auto-removed
before anything repo-owned runs, and `ExitWorktree(remove)` is a runtime
tool with no repo hook. (c) doc-only — the operator already does the manual
`cp`; the card is about removing that.
**Reversal cost:** delete the script and its two one-line call sites.
**Promote?:** no.

## 2026-09-10 — User approved the session-2 checkpoint requests

**Decision:** the user approved "the things requested above" at the session-2
checkpoint: merge `review/template-improvement-review-s1` into main; the five
build-under-assumption choices below stand as built; L45 is to be built (fix
direction left to the building session — investigate the repo guard first).
The §E machine/credential items remain user-only. **Promote?:** no.

## 2026-09-10 — Build the 5 design-gap cards under stated assumptions

**Decision:** the user asked this session to review and improve the template
autonomously ("leave you to think, try, and improve"). That supersedes the
template-maintenance session-15 rule "do not design conventions solo" for
these cards. Each card follows the options brief's proposed shape, choosing
the simplest posture where the brief left a choice:
- **L38** → routed into `work/quality-gates/` (brief's recommendation).
- **L39** → posture (b) "bring your own tracker", documented in
  `docs/agents/issue-tracker.md`, with the template's own backlog files named
  as a copyable worked example. Rejected (a) a `create-backlog` scaffold:
  real ongoing surface with no adopter demand on record.
- **M29** → (a) committed `docs/postmortems/` with a blameless template;
  threshold = any incident that cost a session or reached a user, adopter-
  tunable; ships with a forward pointer to feedback-intake rather than
  blocking on it. Rejected (b) work items (pruned over time) and (c) a
  paragraph in operational-knowledge (not a landing place for artifacts).
- **M28** → convention only (a `uat.md` slot beside `verification.md`);
  no-go recorded as a Tier-2 decision note. A `/uat-plan` skill is not built.
- **M27** → advisory companion skill `design-for-testability` (no gate);
  specs get a suggested "Testability" heading, not a required one.
**Reversal cost:** each is a doc/skill addition; delete or reshape freely.
**Promote?:** no.

## 2026-09-10 — ASR `.session-seq` synced 31 → 32

Ledger top block was session 32; ADR-0007 says the counter is canonical and
drift is repaired toward the prompt number, so the counter was raised via
`context-budget.sh seq-sync`. Machine-local file, no commit.
