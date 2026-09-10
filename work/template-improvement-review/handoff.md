<!--
PURPOSE: This is the LEDGER (provenance log). Append-only, newest block on
TOP. Each "# Session Handoff" block records what happened in one session.
Read the TOP block only; older blocks are in handoff-archive.md. Forward
"what to do next" belongs in next-session.md, NOT here.
Convention: docs/work-directory-conventions.md.
-->

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

# Session Handoff — 2 (2026-09-10): post-checkpoint — user approval, merged to main, rollover to build L45

**Summary.** After the checkpoint the user approved every request in it
("go build it"). Recorded in `decisions.md` (top note), then the branch was
merged into local main (`0cba137`, --no-ff; main now 7 ahead of origin/main,
**not pushed** — outward-facing, left to the user). Rolled over at WARN
(135K) so L45 is built with headroom, not in the dumb zone.

**Current state.** On `main`, clean tree, suites green at the branch tip
(main's tip = that tip + merge commit). Backlog 1 open (L45) / 86 resolved.

**Decisions.** The five build-under-assumption choices stand (user
approval). L45's fix direction is delegated to session 3 after it reads the
repo guard.

**Next.** Session 3 builds L45 per `next-session.md`; then checkpoint or
roll over. Push of main stays the user's call.

**Suggested skills.** brainstorming (briefly, for the L45 direction), tdd,
decision-log, checkpoint.

