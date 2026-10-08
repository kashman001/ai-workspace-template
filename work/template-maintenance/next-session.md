# Catchup prompt — template-maintenance (paste into a new agent session)

> **This file is the LAUNCHER.** Forward-only, REPLACED at each rollover.
> Provenance lives in `handoff.md`. Convention: docs/work-directory-conventions.md.

## >>> START HERE <<<

Mission: fix seven small doc-gap cards, **L53–L59**, filed 2026-10-08 from
`work/context-memory-hardening/doc-gap-review.md` (each card's Evidence/Fix
says what to do; the review file has the context). Expect this to run
unattended under `scripts/session-loop.sh template-maintenance`. Proceed
without asking.

1. `scripts/context-budget.sh register --project template-maintenance`, then
   `git log --oneline -3` and `git status --short`. Another session may be
   working `harness-engineering` on this checkout: re-read the backlog files
   right before each edit, and commit only your own files.
2. For each card in order L53, L55, L56, L57, L58, L59 (grep the ID in
   `docs/template-workspace-backlog.html`): make the fix, verify it with
   `grep`, resolve the card (badge → Resolved, `Fixed:` line, `class=
   "resolved"`, move to the archive's Low section, scorecard −1 open +1
   resolved, "Last updated", change-log row), one commit `Fix <ID>: …` with
   a `Decision:` trailer.
3. **L54 is the maintainer's call** (when to cut a release and bump
   `TEMPLATE_VERSION`). Don't bump it. Leave the card open and list it for
   the user in the ledger.
4. After each card: `scripts/context-budget.sh record --label "<ID> done"`;
   on 1 or 2, roll over with this launcher rewritten to the remaining cards.
5. All done: run every `scripts/tests/test-*` suite (`bash`/`python3`, not
   `./`) and `scripts/check-workspace-structure.sh`; ledger block; stop door
   (`skills/checkpoint/SKILL.md`, `scripts/context-budget.sh close`). Leave
   the next launcher as "standing — take direction from the user".

Ledger: one block on top of `handoff.md`; keep two, archive the third;
`python3 scripts/check-ledger.py work/template-maintenance` must exit 0.

## Constraints

- Doc edits only. Surgical: fix what each card names, nothing adjacent.
- Don't push main. Report how far ahead of origin it is.
- Older history (options brief, M27–M29) is closed; don't reload it.

## Read these first

1. The card (grep its ID in the backlog HTML — targeted read).
2. `work/context-memory-hardening/doc-gap-review.md` (short).
