# 05 — Workspace-root anchoring: coordination state keyed to repository, not checkout

Status: RESOLVED (session 19, 2026-08-06 — implemented per the codification
plan; see `plans/workspace-root-anchoring.md` and the session-19 decision
note) · raised 2026-08-06 (session 17 post-rollover discussion with user,
after two sessions of worktree/rollover friction)

## Problem

Every worktree/rollover divergence hit in sessions 16–17 is one bug wearing
different costumes: `WORKSPACE_ROOT` in the workspace scripts is derived
from the script's own file path, so **workspace identity silently equals
checkout identity**. Symptoms observed live:

- `record` run inside a worktree wrote to the *worktree's own*
  `.context-budget/` + ledger while the lock/registry lived in the main
  checkout (session 17; second strike after session 16's
  operational-knowledge entry).
- The register-before-isolate discipline exists only to dodge this.
- Auto-relaunch is banned from worktrees (stale-launcher hazard: the
  successor launches in a main checkout that hasn't pulled the rolled-over
  launcher yet), degrading `ROLLOVER_RELAUNCH=auto` to manual every time
  work happens in a worktree.

## Attribution (which layer brings in the worktree)

| Layer | Contribution | Session-aware? |
|---|---|---|
| git | Mechanism: many working dirs, one object store/ref set | No |
| Vendor agent (Claude Code) | Policy: *when* a session is isolated into a worktree — incl. involuntarily (bg jobs must isolate before editing); can move a session between checkouts mid-flight | Only about its own sessions |
| Workspace scripts | The broken assumption: workspace root = script path ⇒ per-checkout state | Ours |

Claude Code has the same anti-pattern one level up (`~/.claude/projects/`
slug is cwd-derived — a session's transcript dir changes when it enters a
worktree). "Key state by directory path" is the disease; worktrees are just
the exposure.

## Model (four entities, currently conflated)

1. **Repository** (logical) — one per project; canonical identity:
   `git rev-parse --git-common-dir` (stable across all worktrees).
2. **Checkout** (physical root) — many per repository (main + N worktrees);
   ephemeral, disposable.
3. **Coordination domain** — cross-session runtime state: `work/*/.active-session`
   + `.agent-locks/`, `.context-budget/sessions/`, ledger, `.session-seq`,
   `.rollover-options`.
4. **Session** — runtime + session-id, artifact-keyed (already right per
   ADR-0004/0005); bound to one checkout *at a time* but mobile.

**Load-bearing invariant: coordination state is keyed to the repository,
never to a checkout.** Subsidiary rules:

- Tracked handoff artifacts (launcher/ledger) flow only through git —
  correct today; the fix there is protocol: the rollover's final step is
  "make the successor's launch root current" (push + ff-only pull), owned
  by `launch-next-session.sh`, not the human.
- Vendor worktree mechanics stay vendor-scoped: we never manage
  `.claude/worktrees/` or its session locks; invariant #1 gives us cwd
  immunity, which also keeps the fix agent-agnostic (any runtime in any
  manually-created git worktree gets the same behavior — pure git + bash).

## Codification plan (the slice)

1. **Anchor `WORKSPACE_ROOT` to repo identity** in `context-budget.sh`,
   `launch-next-session.sh`, `attach-session.sh`,
   `statusline-context-budget.sh`, and the vendor hooks: resolve via
   `git rev-parse --git-common-dir` → parent of `.git`; fall back to the
   current script-relative resolution when not in a git repo (template
   pre-`git init`). All checkouts then converge on one `.context-budget/`,
   one lock per work item, one ledger.
2. **Mechanize the sync step**: `launch-next-session.sh` invoked from a
   non-main checkout verifies the branch is pushed, ff-only-pulls the main
   checkout (loud refusal if dirty/diverged — human problem), then launches
   from the main root. Retires the "no auto-relaunch from worktrees" ban
   and the manual pull-then-launch dance.
3. **TDD in the existing harness style**: registry test running `register`
   from a simulated worktree asserting lock/record land in the shared root;
   launcher tests for the worktree-invoked path (pushed-check, ff-pull,
   dirty-refusal). All five suites stay green.
4. **Decision capture**: Tier-2 note — "coordination state keyed to
   repository identity, not checkout path"; rejected alternatives:
   per-checkout state with sync (recreates the divergence as a merge
   problem), moving state under `~` keyed by repo-id (less discoverable,
   breaks disk-state-in-workspace convention; note it IS how vendors do it,
   with the slug bug as a warning). Promote-candidate amending
   ADR-0004/0005's implicit single-checkout assumption. Docs: "Worktrees"
   subsection in `context-budget.md`; the operational-knowledge
   worktree-divergence entry gets a "superseded by fix" note, not deletion.

## Consequence to record honestly

With repo-keyed state a worktree can be deleted while "its" session still
has live registry entries/locks — strictly better than state dying with the
directory, and the existing release-time stale sweep already covers it.

## Provenance

Raised from session 17's live friction (see `handoff.md` session-17 block,
Learnings) and the post-rollover design exchange with the user (2026-08-06).
Builds on ADR-0004 (multi-session model) and ADR-0005 (roles + child
registry) — amends their implicit one-checkout assumption.
