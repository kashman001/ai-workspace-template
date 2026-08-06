# Task brief — per-work-item override of ROLLOVER_RELAUNCH

One-shot implementation task. Scope, design constraints, and slices below;
design was settled in discussion on 2026-08-06 — do not re-litigate the
rejected alternative without new evidence.

## Goal

Let a single work item choose its own successor-relaunch behavior
(`off | manual | auto`) instead of inheriting the workspace-global
`ROLLOVER_RELAUNCH` from root `context-budget.env`. Motivating case:
`work/automatic-session-rollover/` wants `auto` (hands-free STOP→successor
chaining) while the workspace default stays `manual`.

## Design (decided)

- **Mechanism:** a new optional, checked-in file
  `work/<project>/context-budget.env`, sourced by
  `scripts/launch-next-session.sh` after the global one.
- **Precedence:** explicit environment variable > per-item file > global
  `context-budget.env` > built-in default (`off`).
- **Rejected:** carrying the knob in `work/<project>/.rollover-options`.
  That file is a *record of how the last session was launched* — written
  from knowledge at rollover, possibly absent, replaced over time. A
  standing policy knob there would be clobbered or lost by the
  session-rollover skill's normal write behavior. Policy and provenance
  stay in separate files.
- **Scope guard:** only the relaunch knobs are being made per-item. Do not
  wire per-item WARN/STOP thresholds into the hooks now (YAGNI) — but the
  file name/shape is deliberately the same as the global env so it can
  accommodate that later without a rename.
- The per-item file is **committed** (it is standing policy, unlike the
  `.active-session` lock and `.rollover-options`), so it applies to anyone
  who clones the workspace — say so in the docs.

## Implementation slices

1. **`scripts/launch-next-session.sh`** — current sourcing is lines 33–35
   (global env sourced only when `ROLLOVER_RELAUNCH` is unset in the
   environment). Extend to: capture any explicit env value first, source
   global, then source `$WORKSPACE_ROOT/work/$PROJECT/.../context-budget.env`
   if present, then restore the explicit value so it still wins. Note the
   ordering problem: `$PROJECT` is parsed from args *after* the current
   sourcing block — move the sourcing below arg parsing or split it.
   Respect `set -u`; tolerate unreadable files the same way the global
   sourcing does (`|| true`).
2. **Tests** — extend `scripts/tests/test-launch-next-session.sh` (38
   asserts today, mktemp-fixture style): (a) per-item file overrides global;
   (b) explicit env var beats per-item file; (c) no per-item file → global
   still applies; (d) per-item file may also override `ROLLOVER_RUNTIME`.
3. **Docs** — `docs/context-budget.md` → "Relaunch knobs": document the
   per-item file + precedence chain + committed-policy caveat. One-line
   mention in root `CLAUDE.md` → "Context Budget" where `ROLLOVER_RELAUNCH`
   is already named. Update the parenthetical at
   `skills/session-rollover/SKILL.md:99` ("honor `ROLLOVER_RELAUNCH`
   (`context-budget.env`)") to name the per-item override too.
4. **Backlog** — add the row/card to `docs/template-workspace-backlog.html`
   per its "Maintaining this backlog" convention, with the delivering
   commit hash.
5. **Apply the motivating case** — create
   `work/automatic-session-rollover/context-budget.env` with
   `ROLLOVER_RELAUNCH=auto` (confirm with the user first if they're present;
   otherwise ship it — it was the stated motivation).

## Verification

- Test suite green (`scripts/tests/test-launch-next-session.sh`).
- Live dry-run: `scripts/launch-next-session.sh <project> --dry` (check the
  flag name in the script) against a temp work dir with and without the
  per-item file; confirm reported mode flips.

## Conventions that apply

- Commit with a `Decision:` trailer; standing push-to-main approval applies.
- Tier-2 decision note in `work/per-item-relaunch-override/decisions.md`
  (the rejected-alternative above is the content; this brief may be cited).
- Surgical diff: don't refactor the launcher beyond the sourcing change.
- Register the session: `scripts/context-budget.sh register --project
  per-item-relaunch-override`; release the lock at session end.
