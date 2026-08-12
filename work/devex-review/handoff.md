<!--
PURPOSE: This is the LEDGER (provenance log). Append-only, newest block on
TOP. Each "# Session Handoff" block records what happened in one session.
Read the TOP block only; older blocks are in handoff-archive.md. Forward
"what to do next" belongs in next-session.md, NOT here.
Convention: docs/work-directory-conventions.md.
-->

# Session Handoff — 2026-08-11 (session 3: fix package (a)/M19 shipped)

Ran as a background job in worktree `worktree-devex-m19-clean-day1`
(`.claude/worktrees/devex-m19-clean-day1`) — **all work is committed on that
branch, NOT on main; user must merge** (bg sessions may not merge/push main).
M19 "clean day-1 state" fully shipped and closed:

- **Ledger moved** to `.context-budget/context-ledger.jsonl`
  (`context-budget.sh`, statusline script, both test suites, docs,
  `.gitignore`); self-cleaning migration shim folds legacy ledgers in at
  script load — see the new decisions.md note (top). New G3a–c asserts.
- **Prune-`work/` step**: `docs/template-usage.md` §5 (+ step-4 bullet in
  `setup-guide.html`) — work/ is a worked example, deletable day 1.
- **Promoted to `docs/archive/`**: ledger-analysis.md,
  ledger-analysis-heavy-deployment-2026-08-11.md,
  rollover-cost-analysis-2026-08-11.md, design.html →
  context-budget-design.html.
- **Citations repointed** in session-rollover SKILL, context-budget.sh
  header, copilot-vscode hook, context-inspect.sh, context-budget.md; the
  `copilot-vscode-hook-research-findings.md` pointer was dangling (file never
  imported) — dropped, conclusion already inline.
- **Backlog**: M19 card → Resolved + archived, history row added, scorecard
  9 open / 53 resolved. All 10 test suites green (402 asserts).
- Living pointers inside `work/context-decay/` (README, next-session) updated
  to the new paths; its handoff/spec history left frozen.

Suggested skills for next session: backlog maintenance (M24 card), `tdd` for
check-script changes, `session-rollover` at WARN/STOP.

Learnings:
- Claude bg-job worktrees branch from origin/main — with unpushed local commits, `git merge --ff-only main` first or the worktree is stale.
- `docs/operational-knowledge.md:25` still points at `work/automatic-session-rollover/relaunch-analysis.md` (prunable dir) — sweep candidate for a later package.
- `rollover-prep.sh` rotated only 1 of 2 older handoff blocks ("rotated 1 block(s)", session-1-close left behind; fixed by hand). If it repeats, file a card.

# Session Handoff — 2026-08-11 (session 2 close: fix plan agreed, backlog filed)

Session 2 completed the planning mission early (rolled at ~72K, not WARN —
deliberate: each fix package is a heavy unit, so the executor starts fresh).
Shipped:

- **Backlog filed:** 7 consolidated cards M19–M24 + L34 in
  `docs/template-workspace-backlog.html` mapping the review's 7-item fix list
  (commit "backlog(devex-review): file M19-M24, L34…"); scorecard 3→10 open.
- **Plan agreed with user** (see `decisions.md`, both notes): one work item
  (this one), packages sequenced (a) M19 day-1 state → (c) M24 setup
  correctness → (b) M20–M22 spec workflow + QA seat (collaborative session)
  → (d) M23 PM entry point → (e) L34 minimal mode. Rejected: wayfinder map,
  per-package work items, spec-first ordering.
- **`ROLLOVER_RELAUNCH=auto`** in `context-budget.env` (user directive,
  committed with Decision trailer) — successors now auto-launch.

Nothing dirty except this rollover's own files at write time; no processes,
no open agents. `work/kimi-k3-agent-integration/` untracked = other effort,
leave alone.

Suggested skills for next session: `decision-log` (scope calls inside M19),
backlog maintenance per `docs/template-workspace-backlog.html` (flip M19 to
Resolved + archive the card when done), `session-rollover` at WARN/STOP.

Learnings:
- Session-1 handoff wrote `.session-seq`=1 but the bootstrap prompt said #2; per ADR-0007 the prompt wins — repaired to 2 at this rollover.


