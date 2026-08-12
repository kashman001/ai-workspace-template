<!--
PURPOSE: This is the LEDGER (provenance log). Append-only, newest block on
TOP. Each "# Session Handoff" block records what happened in one session.
Read the TOP block only; older blocks are in handoff-archive.md. Forward
"what to do next" belongs in next-session.md, NOT here.
Convention: docs/work-directory-conventions.md.
-->

# Session Handoff — 2026-08-12 (session 8: fix package (e) M23+L35 shipped — PROGRAM COMPLETE)

Final package executed autonomously (background job) per the launcher's
pre-agreed scope. Freshness check passed on local main; the worktree branched
from origin/main (2 commits behind local main) and was fast-forwarded to
`e8f031b` before backlog edits — origin lags local, push pending.

Shipped (commit `6164366` on branch `worktree-devex-fix-package-e`,
NOT merged — user must merge):
- M23: `docs/for-non-engineers.md` (status/decisions/contributing + 6-term
  glossary + agent-prompt fallbacks); `work/README.md` status index (committed
  items only — decision note) + 60-second reading key; *(anyone)* tags on
  create-work-item/decision-log/to-spec in CONTEXT.md + human redirect line;
  rows in docs/README.md (non-engineer row, rendered-backlog URL) + README.md
  pointer.
- L35: "Minimal mode" blockquote atop docs/context-budget.md (solo loop =
  register + record + session-rollover); fleet-only tags on the section-index
  entries (multi-session, worktrees, per-child sweep, dispatching children).
- Backlog: both cards → archive with Fixed: notes; scorecard 1/63/4/0/6;
  changelog row. Sole remaining open card: **M16** (pre-review finding, not
  part of this program).

Doc-only change; entrypoint (8) + parameterization suites green.

**The devex-review fix program is COMPLETE**: all 10 review-born cards
(M19–M25, L32, L33, L35) fixed across packages (a)–(e). Future findings go
through template-maintenance.

Learnings:
- EnterWorktree branches from origin/main (baseRef=fresh), not local HEAD —
  when local main is ahead, ff the worktree branch to local main before
  editing files the unpushed commits touched (backlog HTML here), or the
  merge conflicts.

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

