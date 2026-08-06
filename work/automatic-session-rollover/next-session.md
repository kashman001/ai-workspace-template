# Catchup prompt — Automatic Session Rollover (paste into a new agent session)

> **This file is the LAUNCHER (catch-up prompt).** Forward-only, REPLACED at
> each rollover. Past-tense provenance lives in `handoff.md` (append-only
> ledger, newest block on top). Convention: docs/work-directory-conventions.md.

## Mission

**Resolve issue 10 — one source of truth for session numbers**
(`issues/10-session-number-single-source.md`): the machine-local
`.session-seq`, the `handoff.md` ledger titles, and worktree names drifted
apart (user hit the confusion live in session 29). Decide the canonical
source WITH the user (ticket carries the leanings + rejected-alternative
candidates), realign the three, record the decision (`/decision`), and
encode the rule where sessions will actually see it. Small, mostly-docs
ticket — one session should close it.

**Numbering caveat for YOU:** your bootstrap prompt may call you #29 or #30
depending on whether the user's cleanup one-liner (session-29 handoff block)
ran before your launch. By the ledger you are session **30**. Reconciling
this is literally your mission — title your own ledger block with the number
the DECISION produces.

## Read these, in order

1. `issues/10-session-number-single-source.md` — the whole ticket (short).
2. `handoff.md` top block — session-29 record (context + the user cleanup
   one-liner that may or may not have run).
3. At build time only: `scripts/launch-next-session.sh` (seq handling,
   ~lines 116–129) and `skills/session-rollover/SKILL.md` step 7 (where the
   rule likely lands).

## Do NOT reload

- Issue 01 and all other issue tickets — CLOSED/settled; the map is
  COMPLETE. Reference only.
- Research corpus (`research/*`, `vendor-hooks-research.md`,
  `relaunch-analysis.md`), `map.md` — settled provenance.
- Sessions ≤28 handoff blocks, `handoff-archive.md`.
- Issue 04 — parked by the user; never schedule unprompted.

## State snapshot (at session-29 rollover, 2026-08-06)

- Issue-01 build shipped and CLOSED on `origin/main` (`9c6fb89`, `9126d6b`);
  all 8 test suites green (342 asserts). Session-29 rollover commit lands
  after this file.
- USER'S main checkout: may still carry throwaway probe files
  (`scripts/hooks/vscode-hook-probe.sh`, `.github/hooks/vscode-probe.json`,
  `.vscode-hook-probe.jsonl`) pending the cleanup one-liner; do not recreate
  them.
- Worktrees: `session-29-issue-01-build` (pushed, disposable after this
  rollover). No live dispatches; no child agents.

## First actions

1. **Freshness guard:** `git fetch origin` then
   `git log --oneline HEAD..origin/main` — MUST be empty; else
   `git pull --ff-only` and RE-READ this launcher.
2. `scripts/context-budget.sh register --project automatic-session-rollover`
   — expect `role=primary`.
3. Open issue 10 and start the decision conversation with the user.

## At session end

Lock releases mechanically (launcher script or SessionEnd hook). Manual
fallback: `scripts/context-budget.sh release --project automatic-session-rollover`.
