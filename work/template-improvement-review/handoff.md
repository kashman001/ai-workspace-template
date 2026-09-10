<!--
PURPOSE: This is the LEDGER (provenance log). Append-only, newest block on
TOP. Each "# Session Handoff" block records what happened in one session.
Read the TOP block only; older blocks are in handoff-archive.md. Forward
"what to do next" belongs in next-session.md, NOT here.
Convention: docs/work-directory-conventions.md.
-->

# Session Handoff — 4 (2026-09-10): L45 probed live, merged to main, item complete (checkpoint)

**Summary.** Live end-to-end probe of L45 via `Agent(isolation: worktree)`:
the `work/learn-agentic-workflows` symlink appeared in the worktree, the
probe write landed in the real directory, `.git/info/exclude` gained the
exact `work/learn-agentic-workflows` line, and the worktree was auto-cleaned
as "unchanged" while the write survived — the exact case the card named.
Result recorded as a bullet in `operational-knowledge.md` (`7a98718`), then
`fix/l45-gitignored-work-dirs` merged into main `--no-ff` (`5fd5480`).
23/23 suites green on merged main; structure + ledger checks clean. Backlog
row and archived card updated with the merge; `work/README.md` status row
flipped to Complete. Local fix branch deleted (merged).

**Decisions.** None new; promotion scan clean (no `Promote?: yes|maybe`).

**Learnings:**
- The worktree's branch is cut from `origin/main`, which predates the fix,
  so it had no `scripts/link-local-work.sh` — yet the link appeared. Hooks
  run the *main checkout's* lib (`CLAUDE_PROJECT_DIR` in the hook wiring;
  the lib's root resolver walks to the git common dir). The fix therefore
  holds in worktrees cut from any base.
- The harness's worktree guard refuses compound `git -C "$PWD" …; pwd`
  commands inside an isolated subagent; single commands pass.

**Open / next.** Item **complete**. Only outstanding: pushing main (13
ahead of `origin/main`) — the user's call, not done. `review.md` §E lists
user-only items. `.claude/worktrees/learn-agentic-workflows-s2` still holds
a stale real copy of that item (by design; delete it to get the link).
`review/template-improvement-review-s1` is merged but not deleted.

**Suggested skills.** None — no successor session planned. If reopened:
`checkpoint` after the push.

# Session Handoff — 3 (2026-09-10): L45 built and committed on a branch; rollover at WARN

**Summary.** Built backlog **L45** test-first in one commit `5f51898` on
`fix/l45-gitignored-work-dirs` (off main `6f8c6c2`; not merged, not pushed).
New `scripts/link-local-work.sh` symlinks every ignored `work/<item>/` from
the main checkout into a git worktree; called unthrottled from the shared
hook lib (all six runtimes' per-tool hooks) and from `context-budget.sh
register`. Suite `test-link-local-work.sh` 30/30; all 22 suites green,
structure + ledger checks clean; guide HTML rebuilt. Card L45 archived,
scorecard 0 open / 87 resolved, change-log row added. Docs:
`work-directory-conventions.md` (local-only items + worktrees),
`operational-knowledge.md` (new entry), `workspace-structure.md` tree line.
Rolled over at WARN (130K).

**Decisions.** Tier-2 note (top of `decisions.md`): share-in by symlink; the
card's "repo guard" does not exist in repo code — the redirect is the
runtime's own worktree isolation — so exemption was impossible, and
copy-back loses the auto-cleaned "unchanged" worktree case.

**Learnings:**
- A `work/<item>/` ignore pattern (trailing slash) matches directories only;
  a symlink at that path shows as `??` in the worktree. The script registers
  the exact path in the shared `.git/info/exclude` after linking.
- Claude Code's Write/Edit tools write through a symlinked *directory*
  (verified in scratchpad); the CONTEXT.md refusal is for symlinked files.
- `work/learn-agentic-workflows` is excluded via `.git/info/exclude`, not
  `.gitignore`; the fix handles both.

**Open / next.** Not yet done: a live end-to-end probe in a real worktree
session (register + hook wiring under Claude Code's isolation), merging the
branch into main, and `checkpoint`. `.claude/worktrees/learn-agentic-workflows-s2`
still holds a stale manual copy of that item — it will stay a real dir (by
design) until deleted. Push of main remains the user's call.

**Suggested skills.** verification-before-completion, checkpoint.
