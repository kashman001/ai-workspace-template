<!--
PURPOSE: This is the LEDGER (provenance log). Append-only, newest block on
TOP. Each "# Session Handoff" block records what happened in one session.
Read the TOP block only; older blocks are in handoff-archive.md. Forward
"what to do next" belongs in next-session.md, NOT here.
Convention: docs/work-directory-conventions.md.
-->

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

