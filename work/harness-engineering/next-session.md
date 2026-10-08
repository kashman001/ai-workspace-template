# Catchup prompt — harness-engineering (paste into a new agent session)

We're resuming `harness-engineering`. Works in any runtime (Claude Code,
Codex, Gemini, OpenCode) — all read `CONTEXT.md` via their entrypoint.

> **This file is the LAUNCHER (catch-up prompt).** Forward-only, and REPLACED
> at each rollover: it holds what to do next, still-binding constraints, and
> pointers — never session history. Past-tense provenance lives in
> `handoff.md` (the append-only ledger). Convention:
> docs/work-directory-conventions.md.

## >>> START HERE <<<

Position: **no ticket started.** Five tickets under `issues/`, worked in
number order: 01 (M44) → 02 (M45) → 03 (L60) → 05 (L62, blocked by 01) →
04 (L61, last: blocked by 01–03). Expect this to run unattended under
`scripts/session-loop.sh harness-engineering`. Proceed without asking; only
stop for something only a person can decide.

1. `scripts/context-budget.sh register --project harness-engineering`, then
   `git log --oneline -3` and `git status --short` (another session may be
   working `template-maintenance` on this checkout: re-read the backlog
   files right before each edit, and commit only your own files).
2. Take the next ticket in the order above whose `**Status:**` is `todo`
   and whose blockers are `done`. Set it to `in-progress` and save.
3. Work it per the ticket, test-first where it says so. One commit, with
   its backlog card resolved in the same commit. Set `**Status:** done`,
   tick the boxes, add a short `**Done (date, session N).**` note.
4. `scripts/context-budget.sh record --label "ticket NN done"` and act on
   the exit code. On 0, take the next ticket. On 1 or 2, roll over
   (`skills/session-rollover/SKILL.md`) with this launcher rewritten to the
   new position.
5. When all five are `done`: ledger block, mark the item finished here and
   in `work/README.md`, then the stop door (`skills/checkpoint/SKILL.md`,
   `scripts/context-budget.sh close`).

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
- Don't push main. At the end, report how far ahead of origin it is.
- Edit `CONTEXT.md` directly, never a symlink. Targeted reads on the
  backlog HTML files and long docs.

## Read these first, in order

1. `work/harness-engineering/README.md`
2. `work/harness-engineering/handoff.md` (top block)
3. The current ticket under `work/harness-engineering/issues/`
4. On demand: `work/harness-engineering/source-notes.md`
