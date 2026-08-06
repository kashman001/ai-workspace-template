# Catchup prompt — Automatic Session Rollover (paste into a new agent session)

We're resuming automatic-session-rollover. Works in any runtime (Claude Code,
Codex, Gemini, OpenCode, Copilot) — all read `CONTEXT.md` via their entrypoint.

> **This file is the LAUNCHER (catch-up prompt).** Forward-only, and REPLACED
> at each rollover: it holds what to do next, still-binding constraints, and
> pointers — never session history. Past-tense provenance lives in
> `handoff.md` (the append-only ledger). Convention:
> docs/work-directory-conventions.md.

## First actions

1. `git pull --ff-only` if the checkout lags origin/main.
2. `scripts/context-budget.sh register --project automatic-session-rollover`
   — re-acquires the work-item lock the predecessor released.
3. Read the plan's Tasks 7–8 + Global Constraints:
   `work/automatic-session-rollover/plans/2026-08-05-vendor-hook-deployments.md`.
4. Continue execution with `superpowers:subagent-driven-development` — the SDD
   ledger `.superpowers/sdd/2026-08-05-vendor-hook-deployments/progress.md`
   records Tasks 1–6 complete; resume at **Task 7**, then Task 8, then the
   plan-wide **final whole-branch review** (merge-base = `a1d5c8f`'s parent…
   use `git merge-base` guidance in the SDD skill; branch work is all on main,
   range `13201b5..HEAD` covers plan commits).

## Mission: finish the plan — Task 7 (option inheritance), Task 8 (docs + gate), final review

**Tasks 1–6 are DONE** (commits `4a39bf8`, `6a78138`, `4543645`, `93e9d45`,
`f9579fe`, `9fa16b7`) — all five runtime hooks shipped, suite
`test-vendor-budget-hooks.sh` 37 asserts green. Do not redo them; the SDD
ledger holds per-task review results and deferred minors for the final review.

Remaining:
- **Task 7:** `.rollover-options` persist-and-replay in
  `scripts/launch-next-session.sh` + rollover-skill step. VERIFY vendor flags
  against live `--help` before wiring (plan Step 3 lists the exact greps).
- **Task 8:** docs/context-budget.md vendor-hooks section, CLAUDE.md update,
  backlog rows, decisions.md Tier-2 notes, full 3-suite verification gate.
- **Final SDD whole-branch review** (most capable model) over all plan
  commits, triaging the ledger's deferred minors.

## Constraints already decided (do not re-litigate)

- The plan's **Global Constraints** section is authoritative (ADR-0003/0004;
  escalation-only / throttled / fail-open; bash-3.2 empty-array form).
- Standing push-to-main approval applies.
- VS Code agent-mode verification OUT of scope → `issues/01-vscode-agent-mode-hooks.md`.
- Machine gotchas (do NOT re-diagnose): codex global config pins unavailable
  model (`-m gpt-5.5` to smoke); gemini has no auth on this machine;
  `opencode run` re-appends `$schema` to `.opencode/opencode.json` — all in
  docs/operational-knowledge.md.
- At session end / rollover: release the lock (`scripts/context-budget.sh
  release --project automatic-session-rollover`).

## Do NOT reload

- `handoff-archive.md` — sessions 1–7 provenance, superseded.
- Task 2–6 briefs/reports under `.superpowers/sdd/…/` — reviewed and closed;
  only `progress.md` matters (deferred minors for the final review).
- `vendor-hooks-research.md`, `smoke-test-*.md` — consumed by Tasks 2–6;
  Task 7 needs only live `--help` output.
- `relaunch-analysis.md`, `docs/adr/0001*/0002*` — background only.
- Items #1/#2 design questions — settled; `decisions.md` tail has the notes.

## State snapshot (at session-9 rollover, 2026-08-06)

- Branch `main`, pushed through the session-9 rollover commit. Working tree
  clean; only the live `.active-session` lock is untracked, by design.
- Suites green: vendor-budget-hooks 37, launch-next-session 28, registry 13.
- `~/.copilot/config.json` now lists this workspace in `trustedFolders`
  (added during Task 6 smoke check — machine state, intentional).
- Cleanup candidate (low priority): leftover merged worktree
  `.claude/worktrees/vendor-hook-deployments` + its branch.
- Machine: claude, codex 0.142.4, gemini 0.46.0, opencode 1.18.14, copilot
  CLI 1.0.78, sqlite3 present. No running background processes.
- Work-item lock released at rollover; successor re-acquires via First
  action 2.
