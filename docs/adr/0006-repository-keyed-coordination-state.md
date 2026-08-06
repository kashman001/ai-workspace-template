# ADR-0006: Key coordination state to repository identity, never to a checkout

- Status: accepted
- Date: 2026-08-06
- Deciders: Kashif + Claude Code session 19 (automatic-session-rollover project)

Amends ADR-0004 and ADR-0005. Both were written under an implicit assumption
that a workspace has exactly one checkout — "the workspace root" meant the
directory the script happened to live in. This ADR records the correction:
the unit that owns coordination state is the *repository*, and every checkout
(main working copy or git worktree) of that repository converges on the same
state.

## Context

Git worktrees broke the one-checkout assumption in practice, not in theory.
Each rollover slice was implemented in an isolated worktree (per the
background-session discipline), and every worktree carried its own copy of
the coordination scripts — which resolved "workspace root" script-relatively.
So each worktree got its own `.context-budget/` registry, its own work-item
locks, its own ledger, its own `.session-seq`: sessions 16–17 produced a
string of divergences (double-registered sessions, locks that guarded nothing,
ledger entries landing in a checkout that would be deleted with the worktree).
Each symptom could be patched, but they were all one class: workspace
identity silently equaling checkout identity. The interim mitigations —
"register before isolating" and a ban on auto-relaunch from worktrees —
worked by ordering around the bug rather than removing it.

## Decision

Coordination state is keyed to **repository identity**. All five coordination
scripts (`context-budget.sh`, `launch-next-session.sh`, `attach-session.sh`,
`statusline-context-budget.sh`, `hooks/context-budget-hook-lib.sh`) resolve
`WORKSPACE_ROOT` via `git rev-parse --git-common-dir` → the parent of the
*common* `.git` directory — so every worktree of one repository shares one
`.context-budget/`, one lock per work item, one ledger, one `.session-seq`.
Outside a git repository (or when the git root is not this workspace, detected
by a marker: the script's own path under `scripts/`), the scripts fall back to
the old script-relative resolution. Paths are normalized with `pwd -P`
(macOS `/var` symlink).

Consequently, `launch-next-session.sh` invoked from a worktree is now safe and
mechanized: it verifies the worktree is committed+pushed and the main
checkout's `work/<proj>/` is clean, `pull --ff-only`s the main checkout, and
launches the successor from the main root (loud exit-3 refusal on each guard).
The "no auto-relaunch from worktrees" ban and the register-before-isolate
discipline are retired.

## Alternatives considered

- **Per-checkout state with synchronization** — rejected: recreates the
  divergence as a merge problem; two registries that must be reconciled are
  strictly worse than one registry.
- **State under `~` keyed by repo identity** — rejected: less discoverable
  and breaks the workspace's disk-state-lives-in-the-workspace convention.
  It *is* how vendors do it — and Claude Code's cwd-derived transcript slug
  (a `~`-side path that silently forks per checkout) is the cautionary tale,
  not the model.
- **A shared sourced library for the resolver** — rejected: the test suites
  and the vendor-hook deployment copy scripts around as self-contained units;
  ~12 duplicated lines per script is the cheaper cost. (Revisit if the
  resolver grows.)

## Consequences

- Worktree isolation and rollover automation now compose: a slice can be
  implemented in a worktree and still roll over, relaunch, and record to the
  one true ledger. First live use (session 19 → 21) worked end to end,
  including the T13 `superseded_by` back-stamp.
- The repository, not the filesystem layout, is the coordination boundary:
  clones (as opposed to worktrees) have distinct common `.git` dirs and so
  remain distinct coordination domains — sharing across clones is explicitly
  out of scope.
- The resolver is duplicated ~12 lines × 5 scripts; a change to resolution
  logic must be applied five times (tests G1/G2, W1–W5, T8 guard the
  behavior).
- The marker-guarded fallback means running a copy of the scripts inside some
  *other* git repository degrades to script-relative resolution rather than
  writing state into that repo — surprising but intentional.

## Provenance

- Promoted from:
  `work/automatic-session-rollover/decisions.md#2026-08-06--coordination-state-keyed-to-repository-identity-not-checkout-path-session-19`
- Commits: a850d7b
- Refs: ADR-0004, ADR-0005 (the model this amends);
  `work/automatic-session-rollover/plans/workspace-root-anchoring.md`;
  `work/automatic-session-rollover/issues/05-workspace-root-anchoring.md`;
  `docs/context-budget.md` → "Worktrees";
  tests: registry G1/G2, launcher W1–W5, statusline T8
