<!--
PURPOSE: This is the LEDGER (provenance log). Append-only, newest block on
TOP. Each "# Session Handoff" block records what happened in one session.
Read the TOP block only; older blocks are in handoff-archive.md. Forward
"what to do next" belongs in next-session.md, NOT here.
Convention: docs/work-directory-conventions.md.
-->

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

