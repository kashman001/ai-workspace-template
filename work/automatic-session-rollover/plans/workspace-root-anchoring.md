# Workspace-root anchoring — coordination state keyed to repository, not checkout

Status: COMPLETE (session 19; G1/G2 + W1–W5 + T8 green, all six suites green
— registry 60, attach 22, launcher 81, statusline 16, vendor 37, children 27
= 243 asserts).
Scope: `WORKSPACE_ROOT` resolution in `scripts/context-budget.sh`,
`scripts/launch-next-session.sh`, `scripts/attach-session.sh`,
`scripts/statusline-context-budget.sh`, `scripts/hooks/context-budget-hook-lib.sh`;
new worktree-invoked sync path in `launch-next-session.sh`; tests in the
registry + launcher suites. Source: `issues/05-workspace-root-anchoring.md`
(user-adopted). Amends ADR-0004/0005's implicit one-checkout assumption.

## Design (decided this session)

- **Resolution rule:** `WORKSPACE_ROOT` = parent of `git rev-parse
  --git-common-dir` resolved from the script's own location (statusline:
  from the session's `project_dir`/`cwd` input); falls back to the current
  script-relative derivation when not in a git repo (template pre-`git init`)
  or git absent. All checkouts of one repository then converge on one
  `.context-budget/`, one lock per work item, one ledger, one `.session-seq`.
- **Duplicated helper, not a shared lib** (rejected: `scripts/lib/` sourced
  file — every test suite and the vendor-hook deployment copies scripts as
  self-contained units; a sourced lib breaks that convention for ~10 lines).
  Same short `resolve_workspace_root` function pasted into each of the five
  sites, normalized with `pwd -P` on both paths (macOS `/var` → `/private/var`
  symlink would otherwise make main-checkout invocations look worktree-like).
  `--git-common-dir` output may be relative (`.git`) in the main checkout and
  absolute in a worktree — normalize before taking the parent. Not using
  `--path-format=absolute` (needs git ≥2.31; the case-prefix normalization is
  version-independent).
- **hook-lib keeps its `${WORKSPACE_ROOT:-…}` env override**; the resolution
  applies only to the default arm.
- **Worktree-invoked launch sync** (`launch-next-session.sh`): detect
  `SCRIPT_ROOT != WORKSPACE_ROOT` (physical paths) → before the
  `next-session.md` existence check:
  1. worktree has uncommitted changes under `work/<project>/` (`status
     --porcelain -uno`) → loud die (launcher/ledger not committed);
  2. worktree has commits absent from every remote (`rev-list -n1 HEAD
     --not --remotes`) → loud die (successor would launch against a stale
     main root);
  3. main checkout has uncommitted tracked changes under `work/<project>/`
     → loud die (clear message beats a git checkout error);
  4. `git -C <main> pull --ff-only` → die on failure (diverged / offline —
     human problem, per issue).
  Then `cd "$WORKSPACE_ROOT"` so the successor launches from the main root.
  This retires the "no auto-relaunch from worktrees" operational ban.
  Sync failures are precondition failures (die before the paste-me prompt,
  like the existing missing-launcher die); the prompt-survives-failure
  contract covers launch failures only.
- **Vendor worktree mechanics stay vendor-scoped:** no touching
  `.claude/worktrees/` internals; pure git + bash keeps it agent-agnostic.
- **Consequence accepted:** a worktree can be deleted while "its" session
  still has registry entries/locks in the shared root — covered by the
  existing release-time stale sweep (issue 05 "Consequence" section).

## Test plan

Registry suite (`test-context-budget-registry.sh`, new block; harness gains
nothing — new tests build their own git-enabled temp workspace):

- G1 `register --project` run from a simulated worktree (`git init` + commit
  + `git worktree add`, script invoked via the *worktree's* copy) → lock and
  session record land in the **main** temp root, not the worktree.
- G2 `record` from the worktree → ledger line appended under the main root.
- G3 non-git temp workspace (the existing harness) → script-relative
  fallback; implicitly asserted by every existing test staying green.

Launcher suite (`test-launch-next-session.sh`, new block; temp workspace +
local bare `origin`):

- W1 worktree-invoked, pushed, main clean → main root ff-pulled (launcher
  file appears), `--dry-run` cmd printed, `.session-seq` written in main
  root only.
- W2 worktree has unpushed commits → die, exit 3.
- W3 main checkout diverged from origin → die (ff-only pull fails).
- W4 main checkout has dirty tracked `work/<proj>/` files → die.
- W5 main-checkout invocation: sync block skipped (no fetch attempted, works
  with no remote configured).

Statusline suite: one assert — `project_dir` pointing at a worktree resolves
state from the main root.

All six suites stay green (registry, attach, launcher, statusline, vendor
hooks, children).

## Follow-through (after green)

- Tier-2 decision note: coordination state keyed to repository identity,
  not checkout path (rejected: per-checkout state + sync; `~`-keyed state
  by repo-id). Promote-candidate amending ADR-0004/0005.
- Docs: `docs/context-budget.md` "Worktrees" subsection;
  `docs/operational-knowledge.md` worktree-divergence entry gets a
  "superseded by fix" note (not deleted); retire the register-before-isolate
  and no-auto-relaunch-from-worktree caveats where stated.
- Backlog changelog row in `docs/template-workspace-backlog.html`.
- Commit + push to origin/main (standing approval); user pulls main checkout.
