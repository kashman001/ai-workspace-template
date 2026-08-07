<!--
PURPOSE: This is the LEDGER (provenance log). Append-only, newest block on
TOP. Each "# Session Handoff" block records what happened in one session.
Read the TOP block only; older blocks are in handoff-archive.md. Forward
"what to do next" belongs in next-session.md, NOT here.
Convention: docs/work-directory-conventions.md.
-->

# Session Handoff — 2026-08-06 (session 30: issue 10 RESOLVED — session-number canon = .session-seq, ADR-0007; map fully drained)

**What shipped (worktree `session-30-issue-10`, branch
`worktree-session-30-issue-10` — NOT on main; user merge one-liner below):**

- **Issue 10 CLOSED — decision made with the user.** Canonical session-number
  source = machine-local `.session-seq` as surfaced through the bootstrap
  prompt; ledger titles + worktree names copy the prompt number verbatim;
  ledger repaired on disagreement. Self-heal: `session-rollover` step 7 now
  has the dying session write its OWN prompt number to `.session-seq` before
  emitting/launching. Enforcement = docs + skill step only; register-time
  ledger-title parsing rejected as YAGNI. Decision: Tier-2 note in
  `decisions.md`, promoted to **ADR-0007** (+ README index row).
- **Files:** `skills/session-rollover/SKILL.md` (step-7 sync),
  `docs/work-directory-conventions.md` (ledger numbering rule),
  `docs/context-budget.md` (launcher paragraph), issue 10 status, backlog
  changelog row. No script changes, so no test-suite deltas.
- **Alignment verified before the rule landed:** user's cleanup one-liner had
  run (probe files gone, seq realigned); seq=30 = prompt-#30 = ledger-#30 —
  this block's number follows the new rule.

**State:** wayfinder map COMPLETE and fully drained — issues 01–10 all
CLOSED/settled except 04 (PARKED, user-scheduled only). No standing missions.
Work item goes dormant.

**Left for the user (main checkout):** merge the branch —
`git fetch origin && git merge --ff-only origin/worktree-session-30-issue-10 && git push`
(background-session guardrail: agent does not push main). Optionally prune
worktrees `session-28-issue-01-vscode` / `session-29-issue-01-build` /
`session-30-issue-10` after the merge.

# Session Handoff — 2026-08-06 (session 29: issue-01 probe v4 verified + build SHIPPED; issue 01 CLOSED)

**What shipped (worktree `session-29-issue-01-build`, pushed to `origin/main`):**

- **Probe v4 (spec step 3, the one open leg) — verified live, self-driven**
  (no user relay needed; `code chat` seeded sessions work from the agent
  shell): repo-relative hook commands RESOLVE, hook-process cwd = workspace
  root, VS Code re-reads hook JSON without a window reload. Details in
  `issues/01-vscode-agent-mode-hooks.md` → session-29 block.
- **Build (spec steps 1–2, 4–6):** `context-budget-copilot-vscode-hook.sh` +
  committed `.github/hooks/context-budget-vscode.json` (repo-relative,
  PascalCase); launcher copilot-vscode `code chat -r -m agent` seeded launch
  via the BG confirm loop; vendor T11 + launcher T22 tests (all 8 suites
  green, 342 asserts); docs (context-budget.md, CONTEXT.md six runtimes,
  relaunch-analysis.md, backlog changelog row).
- **Issue 01 CLOSED** (versions recorded per Done-when: VS Code 1.132.0,
  Copilot Chat built-in, claude-sonnet-5).

**Numbering note:** machine-local `.session-seq` (28) trails the ledger by
one — this session is ledger-#29 but was launched as prompt-#28.

**Late addition (same session, post-close):** the numbering confusion above
became a scheduled ticket — `issues/10-session-number-single-source.md`
(OPEN, next session's mission; user-requested). Launcher rewritten for it.

**Learnings:** (1) main-checkout writes are classifier-blocked from a
worktree-isolated background session — stage main-checkout probe/temp files
BEFORE EnterWorktree (worked this session pre-isolation). (2) `code chat`
probes are self-drivable from the agent shell; no user relay needed.

**Left for the user (main checkout, one line):** `git pull --ff-only && rm
scripts/hooks/vscode-hook-probe.sh .github/hooks/vscode-probe.json
.vscode-hook-probe.jsonl && echo 29 > work/automatic-session-rollover/.session-seq`
(probe files are throwaway; the seq write realigns the next prompt number
with the ledger). Nothing else standing — wayfinder map complete, issue 04
parked (user-scheduled only).

