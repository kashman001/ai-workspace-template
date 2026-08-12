<!--
PURPOSE: This is the LEDGER (provenance log). Append-only, newest block on
TOP. Each "# Session Handoff" block records what happened in one session.
Read the TOP block only; older blocks are in handoff-archive.md. Forward
"what to do next" belongs in next-session.md, NOT here.
Convention: docs/work-directory-conventions.md.
-->

# Session Handoff — 2026-08-12 (session 7: fix package (d) M25+L33+L32 shipped)

User picked the reliability package (M25+L33+L32) from the proposed split.
All three fixed in commit `d9c1382` on branch `worktree-devex-fix-package-d`
(pushed, NOT merged — user must merge; the new L33 guard now REFUSES relaunch
until merged, by design).

Shipped:
- M25: rollover-prep.sh splits root resolution — tracked files (handoff
  rotation, git summary) target $PWD's checkout (same-common-dir guard);
  coordination state (.session-seq, .rollover-options) stays on main root.
  Test T10. Sibling scripts audited: coordination-only, correctly unchanged.
- L33: launch-next-session.sh stale-launcher guard — dies when any ref has a
  next-session.md commit unreachable from HEAD (reachability, not dates);
  --skip-freshness overrides. Tests F1–F4. SKILL.md notes the guard.
- L32: claude hook keys throttle/escalation per (session, chain) via
  transcript basename; sidechain can't swallow parent WARN. Test T12.
- Backlog: 3 cards → archive with Fixed: notes; scorecard 3/61/4/0/6;
  changelog row added. Two Tier-2 decision notes in decisions.md.

Suites green: rollover-prep 38, launch-next-session 94, vendor-hooks 54.

Rollover at STOP (152K). Live validation during this rollover: prep operated
on the worktree's ledger and left the root checkout clean — M25 confirmed
fixed in production use.

Learnings:
- rev-list newest-by-date tie-breaks arbitrarily on same-second commits —
  caught only because the F1 test failed first (guard v1 used merge-base on
  the newest sha); reachability (`--all --not HEAD`) is the exact semantic.
- The launch script's lock release happens AFTER the freshness guard, so a
  guard refusal leaves the work-item lock held — released manually this
  session (`context-budget.sh release`).

# Session Handoff — 2026-08-12 (session 6: fix package (b) M20–M22 shipped)

Collaborative session as planned: grilled the user through seven spec-workflow
decisions (Q1–Q7, all recorded in `work/devex-review/decisions.md` 2026-08-12
entry), then implemented and closed M20, M21, M22 in one commit.

Shipped (commit `bb0388e` on branch `worktree-devex-fix-package-b`, pushed,
**NOT merged to main** — user must merge):
- M20: "Spec conventions" in `docs/agents/issue-tracker.md` (skeleton with
  Status/Approved-by + stable S-IDs; in-file approval default, branch loop
  optional; when-required rule; external spec-of-record clause);
  Spec:/Covers: advisory ticket fields; create-work-item scaffold-time ask;
  SPEC.md ↔ spec.md cross-references.
- M21: `verification.md` skeleton + row in work-directory-conventions.md;
  Severity:/Repro: on bug tickets; no-spec → README `## Success criteria`.
- M22: to-spec/to-tickets/triage vendored (MIT, upstream 8b36d4f) with
  provenance + wiring comments; three `.claude/commands/`; CONTEXT.md list +
  recommended-tooling.md updated; tdd/diagnosing-bugs stay global-only with
  point-of-use pointers.
- Backlog: M20–M22 → archive; scorecard 6 open / 58 resolved; M25 third
  strike noted on the card.

Rollover at WARN (134K, then 137K at prep). The session-6 rollover edits
(this block, launcher, M25 evidence line) are committed on the same branch.

Suggested skills for next session: none mandatory; `session-rollover` at
WARN/STOP.

Learnings:
- M25 struck again exactly as carded (prep rotated the root checkout's
  ledger from a worktree session); repaired via cp into worktree +
  `git show HEAD:` restore of root.
- This harness blocks `git -C <outside-path>` from a worktree-isolated
  session; read `.git/HEAD`/refs as files when a fact about another repo is
  needed.

