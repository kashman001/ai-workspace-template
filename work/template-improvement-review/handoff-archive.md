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

# Session Handoff — 2 (2026-09-10): review list drained — cards archived, L45 filed, C2–C12 fixed; checkpoint

**Summary.** Mission fully delivered in one commit `39224b8` on
`review/template-improvement-review-s1` (not merged, not pushed — merging is
the user's call); origin/main (PR #44, M38) merged into the branch at
checkpoint, backlog conflicts resolved, M38's missing change-log row added. Suites 21/21 green
(`test-turn-end-exit.sh` skips 4 tty assertions without a controlling
terminal), structure + ledger checks clean.

**Shipped.** M27/M28/M29/L38/L39 flipped Resolved with `Fixed:` lines and
moved to the archive; new card **L45** (gitignored work dirs lost in
worktree-forced background sessions, from A10); scorecard 1 open / 86
resolved (incl. M38 from PR #44); two change-log rows. C2–C12 applied by one subagent pass (see
`review.md` §C, all "done (session 2)"); `skills/vendored-skills.md` also
gained `design-for-testability`. `work/template-maintenance/next-session.md`
carries a supersede note (options-brief walk no longer needed).
`work/README.md` rows for both items updated.

**Decisions.** Commit trailer only: `probe-results.md` citations repointed
to the session-loop spec's "Open questions" table because the file was never
committed (C2c). No new Tier-2 note.

**Open / next.** Nothing left for an agent in this item. Remaining items are
user-only (`review.md` §E) plus: merge this branch; decide L45's fix
direction (guard exemption vs. copy-back); review the five build-under-
assumption choices in `decisions.md`. Item state: **complete pending merge**.

**Learnings:**
- Session 1's "main is 3 ahead of origin" snapshot was stale by session 2:
  local main had been pushed and origin/main had gained PR #44, which also
  edited the backlog files. Run `git fetch && git log main..origin/main` at
  start, before touching the backlog, rather than trusting the launcher's
  branch arithmetic. PR #44 also skipped its change-log row (rule 6 applied).
- The review's C2 claim about `docs/adr/0008:125` was wrong (it cites
  `decisions.md`, a provenance line, not `probe-results.md`); the subagent
  verified before editing, which is the right discipline for stale-line
  findings.

# Session Handoff — 1 (2026-09-10): pooled review written, housekeeping + 5 design-gap cards built

**Summary.** Created this item; surveyed every `work/*` item, the 5 open
backlog cards + options brief, ran a fresh-eyes template review; baseline
and post-change suites all green (21 suites + ledger checker + structure).
Everything landed in one commit `dc1f334` on branch
`review/template-improvement-review-s1` (not merged, not pushed — the
user's global rule is branch-first; merging is their call).

**Shipped.** See `review.md` for the full table. A1–A9 housekeeping done
(work index rows, context-decay ledger path, stale claims, banners, routing
pointers). Built: M27 `skills/design-for-testability` + command + CONTEXT.md
bullet + optional spec heading; M28 `uat.md` slot in
`docs/work-directory-conventions.md`; M29 `docs/postmortems/` + pointers;
L39 posture section in `docs/agents/issue-tracker.md`; L38 routed into
`work/quality-gates/README.md`. Context-decay savings validation run:
verdict negative (`work/context-decay/savings-validation-2026-09-10.md`).

**Decisions.** `decisions.md` (build-under-assumptions; ASR seq 31→32).

**Open / next.** Backlog cards M27/M28/M29/L38/L39 still show Open in
`docs/template-workspace-backlog.html` — resolve + archive + scorecard
(5→0 open, 80→85 resolved) is session 2's first job. Then fresh-eyes fixes
C2–C12 and the new A10 card. Successor's session-2 preamble was written
by session 1 (ad-hoc start: counter `created` at 1 this session).

**Suggested skills.** decision-log (if any new choice), checkpoint at end.

**Learnings:**
- Subagent survey claimed an unmerged `feat/clear-in-place-rollover`
  branch; disk showed none. Verify branch claims with `git branch -r --no-merged`.
- Fresh-eyes reviewer found `docs/workspace-structure.md`'s docs tree lists
  neither `adr/` nor `postmortems/` (fold into C3).

# Session Handoff — 1 (2026-09-10): scaffolded; pooling open threads

Work item created. Survey of all `work/*` items, the 5 open backlog cards,
the options brief, and a baseline run of every test suite in progress.
Immediate next step: write `review.md`, then start delivering.
