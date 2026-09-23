# Decisions — session-management-followups

Tier-2 decision notes, newest on top. Format and promotion rules:
`skills/decision-log/SKILL.md`. Each ticket that rejects an alternative
appends one note here before its commit.

## 2026-09-22 — the template version marker: `TEMPLATE_VERSION`, one ISO date
**Chose:** a root file `TEMPLATE_VERSION` — `#` comment lines plus exactly one value line holding an ISO date (`YYYY-MM-DD`, the day the template state was cut; `2026-09-22` today). Read by nothing; bumped by hand by whoever cuts a template release; a downstream workspace never edits it and the §5 prune leaves it alone. Named in `docs/template-usage.md` → "Upgrading later" and the `docs/workspace-structure.md` tree. Seams under test (`scripts/tests/test-template-version.sh`): the file's contents, and the §5 prune path run against a copy of the working tree.
**Because:** a date is monotonic without a lookup table and self-locating in the template's own history (`git log --since=<value>` is the upgrade diff), which is the comparison a future upgrade needs; a visible ALLCAPS root file sits next to `LICENSE` and `README.md` where the maintainer bumping it sees it; the comment lines carry its meaning after `docs/template-usage.md` is pruned downstream. Assumed, not chosen by the human: the human has not picked a shape (ticket 03), so this is the smallest one that answers "which generation is this workspace on".
**Rejected:** an integer (monotonic, but meaningless without a table nobody maintains); semver (promises compatibility semantics nobody has defined); a key in `context-budget.env` (per-item overridable, and about the budget); a field in `CONTEXT.md` (every adopter rewrites that file on day 1, §2); a dotfile `.template-version` (hidden, and the convention for tool-owned answer files — this one is human-owned); a bare value line with no comments (self-describing matters once the usage doc is gone); wiring it into `check-workspace-structure.sh` or `setup.sh` (the ticket says read by nothing yet).
**Blast radius:** `TEMPLATE_VERSION` (new), `scripts/tests/test-template-version.sh` (new), `docs/template-usage.md`, `docs/workspace-structure.md`.
**To reverse:** rename or reshape the file, then the "Upgrading later" paragraph and the test's two format checks — nothing else knows the shape. Known limit: day granularity, so two cuts on one day share a value; if that ever bites, append `.N` and widen the check.
**Promote?:** no — revisit when an upgrade tool reads it.

## 2026-09-22 — the addendum heading form stays, as grandfathered history
**Chose:** keep `# Session Handoff addendum — …` accepted by `check-ledger.py` and teach the launcher's `top_ledger_session` the same opener (plus the same strict `# Session Handoff` start the checker requires); the rule is stated once in `docs/work-directory-conventions.md` → "Ledger" and both parsers cite it; a fixture set in `test-check-ledger.py` fails when they disagree.
**Because:** the ticket's recommendation to drop the form rested on "no remaining use", but M36 records a real downstream ledger (the history this grammar was ported from, session 166) that carries an addendum block, and the checker's own rule is never to rewrite history to modernize headings. Dropping the form would make that adopter's ledger fail the gate again.
**Rejected:** dropping the form from the checker and its test (the ticket's recommendation) — breaks a grandfathered downstream history for no gain; leaving the launcher looser than the checker (it read a number from `#  Session Handoff …`, which the checker rejects) — the two must agree on every heading, not just the addendum one.
**Blast radius:** `scripts/launch-next-session.sh` (`top_ledger_session`), `scripts/check-ledger.py` (comment only), `scripts/tests/test-check-ledger.py`, `docs/work-directory-conventions.md`.
**Promote?:** no.

## 2026-09-22 — where the "who owns this item, is it alive" readers live
**Chose:** two reader functions in `scripts/lib/session-lib.sh` (`session_record_owner`, `session_owner_live`), sourced by `attach-session.sh` and `statusline-context-budget.sh`; `context-budget.sh` keeps its own `owner_live()` untouched.
**Because:** the ticket named the lib as the read path, and `context-budget.sh` cannot be sourced (it dispatches a command on execution), so the rule had to live somewhere sourceable; leaving `context-budget.sh` alone keeps the change inside the ticket's remit.
**Rejected:** inlining the pid check in each script — a third and fourth copy of the ADR-0010 rule; refactoring `context-budget.sh` onto the lib readers in the same commit — outside the ticket, and the measurer is the riskiest script to touch. Also rejected: renaming the `locked=` field and the "work-item lock" message — the ticket says keep the output shape.
**Blast radius:** `scripts/lib/session-lib.sh`, `scripts/attach-session.sh`, `scripts/statusline-context-budget.sh`, their three suites.
**Promote?:** no — follow-up candidate: point `context-budget.sh`'s `owner_live()` at the lib reader so the rule has one copy.
