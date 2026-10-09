# Catchup prompt — template-maintenance (paste into a new agent session)

> **This file is the LAUNCHER.** Forward-only, REPLACED at each rollover.
> Provenance lives in `handoff.md`. Convention: docs/work-directory-conventions.md.

## >>> START HERE <<<

Mission: fix three cards, **L63, L64, L65**, filed by `harness-engineering`
(ticket 04's map of guides and checks), then cut the release (**L54**). Each card's Evidence/Fix line says
what to do — grep the ID in `docs/template-workspace-backlog.html`
(targeted read). Expect this to run unattended under
`scripts/session-loop.sh template-maintenance`. Proceed without asking.

1. `scripts/context-budget.sh register --project template-maintenance`, then
   `git log --oneline -3` and `git status --short`.
2. Work in order L63 → L64 → L65 → L54. For each: make the fix, verify it,
   resolve the card (badge → Resolved, `Fixed:` line, `class="resolved"`,
   move to the archive's Low section, scorecard −1 open +1 resolved,
   "Last updated", change-log row), one commit `Fix <ID>: …` with a
   `Decision:` trailer.
   - **L63** — doc edit; regenerate `docs/workspace-structure.html` the way
     `harness-engineering` ticket 04 did (see its ticket/commit `67c5455`).
     The optional tree-entry check is in scope only if small.
   - **L64, L65** add new checks, so they follow the rules
     `harness-engineering` just shipped: test-first, and each check ships
     with a suite that makes it fail (`docs/workspace-structure.md` →
     "Authoring a Team Capability"). Wire each into `scripts/run-checks.sh`
     (fast tier if it runs in seconds) and add a row to "Guides and Checks
     — One Map". L65 may be a case in an existing suite instead of a new
     script — prefer that if it fits.
   - **L54** — last, only after L63–L65 are done and `scripts/run-checks.sh`
     exits 0. Set the value line of `TEMPLATE_VERSION` to today's date
     (`date +%F`); keep its comment lines. Resolve the card in the same
     commit, `Fix L54: bump TEMPLATE_VERSION to <date>`. Run
     `scripts/tests/test-template-version.sh`. No changelog file (user
     decision: `git log --since=<date>` is the record).
3. After each card: `scripts/context-budget.sh record --label "<ID> done"`;
   on 1 or 2, roll over with this launcher rewritten to the remaining cards.
4. All done: `scripts/run-checks.sh` exits 0 and `scripts/check-drift.sh`
   reports nothing new; ledger block; stop door (`skills/checkpoint/SKILL.md`,
   `scripts/context-budget.sh close`). Leave the next launcher as "standing —
   take direction from the user": the user pushes `main` and checks the
   first CI run; if CI fails, fix it without changing the date.

Ledger: one block on top of `handoff.md`; keep two, archive the third;
`python3 scripts/check-ledger.py work/template-maintenance` must exit 0.

## Constraints

- **L54 is approved** (user, 2026-10-08): bump once, as the last commit
  before the user's push. Rule going forward: bump on each push of
  template-facing changes; `work/`-only changes need none.
- Surgical: fix what each card names, nothing adjacent. Plain bash/python3.
- Don't push main. Report how far ahead of origin it is.
