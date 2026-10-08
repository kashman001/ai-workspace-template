# Catchup prompt — harness-engineering (paste into a new agent session)

We're resuming `harness-engineering`. Works in any runtime (Claude Code,
Codex, Gemini, OpenCode) — all read `CONTEXT.md` via their entrypoint.

> **This file is the LAUNCHER (catch-up prompt).** Forward-only, and REPLACED
> at each rollover: it holds what to do next, still-binding constraints, and
> pointers — never session history. Past-tense provenance lives in
> `handoff.md` (the append-only ledger). Convention:
> docs/work-directory-conventions.md.

## >>> START HERE <<<

Position: **tickets 01, 02, 03 (L60, `21d03a6`) and 05 (L62, `ca43dec`)
done**; 4 of 5. Remaining: **04 (L61)**, the last ticket — one table of the
workspace's guides and checks, in `docs/workspace-structure.md`. Its
blockers (01–03) are done. Read `skills/writing-for-agents/SKILL.md` if the
ticket touches a skill; read long docs by headings (grep `^## `), not whole.
Expect this to run unattended under `scripts/session-loop.sh
harness-engineering`. Proceed without asking; only stop for something only
a person can decide.

Gate: `scripts/run-checks.sh` exits 0 (full, ~2 min, 38 checks). Editing
`docs/workspace-structure.md` makes the guide HTML stale: run
`scripts/build-guide-html.sh` and commit `docs/workspace-structure.html`.

1. `scripts/context-budget.sh register --project harness-engineering`, then
   `git log --oneline -3` and `git status --short` (another session may be
   working `template-maintenance` on this checkout: re-read the backlog
   files right before each edit, and commit only your own files).
2. Open `work/harness-engineering/issues/04-guides-and-checks-map.md`. Set
   `**Status:** in-progress` and save.
3. Work it per the ticket. One commit, with card L61 resolved in the same
   commit (archive it under Low, scorecard → 2/110/5/0/6, change-log row).
   Set `**Status:** done`, tick the boxes, add a short
   `**Done (date, session N).**` note.
4. `scripts/context-budget.sh record --label "ticket 04 done"`. On 1 or 2,
   roll over (`skills/session-rollover/SKILL.md`) with step 5 below as the
   launcher's position.
5. All five done: ledger block, mark the item finished here and in
   `work/README.md`, then the stop door (`skills/checkpoint/SKILL.md`,
   `scripts/context-budget.sh close`). Report how far `main` is ahead of
   origin.

Every session: one ledger block on top of `handoff.md`, plain numbered
form; keep two, archive the third; `python3 scripts/check-ledger.py
work/harness-engineering` must exit 0.

## Constraints already decided (do not re-litigate)

- Scope is cards M44, M45, L60, L61, L62. Behaviour testing and "harness
  templates" from the article are out of scope (`source-notes.md`).
- Plain bash/python3, no npm/Husky. Agent-agnostic: nothing that works only
  for Claude Code. Pre-commit is opt-in for adopters.
- CI = GitHub Actions (the template lives on GitHub). It can't be verified
  from a session; mark it unverified until the user pushes.
- Choices with a rejected alternative go in `decisions.md` (Tier 2). Decide
  under stated assumptions rather than stopping, except for steps only a
  person can do.
- `scripts/check-drift.sh` (ticket 02) is part of the full gate. Card L63
  is open and not this item's scope.
- New checks ship with a suite that makes them fail (ticket 05 rule).
- Don't push main. At the end, report how far ahead of origin it is.
- Edit `CONTEXT.md` directly, never a symlink. Targeted reads on the
  backlog HTML files and long docs.

## Read these first, in order

1. `work/harness-engineering/README.md`
2. `work/harness-engineering/handoff.md` (top block)
3. The current ticket under `work/harness-engineering/issues/`
4. On demand: `work/harness-engineering/source-notes.md`
