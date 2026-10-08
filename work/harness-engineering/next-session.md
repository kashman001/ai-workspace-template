# Catchup prompt — harness-engineering (paste into a new agent session)

We're resuming `harness-engineering`. Works in any runtime (Claude Code,
Codex, Gemini, OpenCode) — all read `CONTEXT.md` via their entrypoint.

> **This file is the LAUNCHER (catch-up prompt).** Forward-only, and REPLACED
> at each rollover: it holds what to do next, still-binding constraints, and
> pointers — never session history. Past-tense provenance lives in
> `handoff.md` (the append-only ledger). Convention:
> docs/work-directory-conventions.md.

## >>> START HERE <<<

Position: **item finished** — tickets 01–05 all done (last: 04, L61,
`67c5455`). Nothing to run. Follow-up gaps are open backlog cards **L64**
(plan lint not in the gate) and **L65** (skill frontmatter unchecked); pick
them up under `template-maintenance` or a new item, not here.

If a session lands here anyway: confirm `scripts/run-checks.sh` exits 0,
report how far `main` is ahead of origin, and stop. CI is unverified until
the user pushes.

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
