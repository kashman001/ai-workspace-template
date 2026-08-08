# Catchup prompt — usage-scenarios (paste into a new agent session)

We're resuming usage-scenarios. Works in any runtime (Claude Code, Codex,
Gemini, OpenCode) — all read `CONTEXT.md` via their entrypoint.

> **This file is the LAUNCHER (catch-up prompt).** Forward-only, and REPLACED
> at each rollover: it holds what to do next, still-binding constraints, and
> pointers — never session history. Past-tense provenance lives in
> `handoff.md` (the append-only ledger). Convention:
> docs/work-directory-conventions.md.

## Mission status: BUILD PHASE COMPLETE (session 2)

The catalog and gap analysis are done. `scenarios.md` (E1–E18 external +
I1–I10 internal + zoom model + coverage matrix) and `gaps-and-coverage.md`
(8 ranked gaps, recommendations, sequencing) are the deliverables. The
backlog carries M15 (meta-card) + M16/L32/L33 (promoted findings).

## The one remaining step

**Deliver branch `worktree-usage-scenarios-s2` to main.** Session 2 ran as
a background job (worktree-isolated, forbidden from merging). Merge it —
`git merge worktree-usage-scenarios-s2` from main — or review first via
`scripts/diff-review.sh worktree-usage-scenarios-s2 main`. Then delete the
worktree/branch.

## After delivery (user's call, not automatic)

- Read `gaps-and-coverage.md` end-to-end (it's the payoff artifact).
- Pick up gaps as new work items per its "Recommended sequencing"; Gap 1
  (multi-user) explicitly wants a wayfinder map; Gap 6's clean-room test is
  the recommended first mover.
- The usage-scenarios.html supersede decision (Gap 7) is recorded but not
  executed — it's a recommendation until the user endorses it.

## Do NOT reload

- The four session-1 subagent raw reports — gone; `ground-truth.md` IS the
  distillate.
- docs/context-budget.md, docs/workspace-structure.md, usage-scenarios.html,
  ADRs — mined into ground-truth.md; re-read only to verify a specific fact.
- Zoom-model design debate — settled in scenarios.md §1/§1b/§1c.

## Constraints already decided (do not re-litigate)

- `ROLLOVER_RELAUNCH=auto` via committed per-item context-budget.env.
- Catalog supersets docs/usage-scenarios.html; its fate (supersede) is a
  recommendation in gaps-and-coverage.md Gap 7, pending user endorsement.
- Brief req 10 (team capabilities) added mid-session-2 → E18/Gap 8.

## State snapshot

- Branch: `worktree-usage-scenarios-s2` (from main @ session-1 commit),
  committed + pushed at session-2 close. Main untouched.
- All 5 tasks done. No running processes, no open subagents.
- Known trap for background sessions on this repo: fresh worktrees branch
  from origin/main — if local main is ahead, `git merge --ff-only main`
  before editing (see ledger session-2 learnings; backlog L33/M16).
