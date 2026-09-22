# Decisions — session-management-followups

Tier-2 decision notes, newest on top. Format and promotion rules:
`skills/decision-log/SKILL.md`. Each ticket that rejects an alternative
appends one note here before its commit.

## 2026-09-22 — where the "who owns this item, is it alive" readers live
**Chose:** two reader functions in `scripts/lib/session-lib.sh` (`session_record_owner`, `session_owner_live`), sourced by `attach-session.sh` and `statusline-context-budget.sh`; `context-budget.sh` keeps its own `owner_live()` untouched.
**Because:** the ticket named the lib as the read path, and `context-budget.sh` cannot be sourced (it dispatches a command on execution), so the rule had to live somewhere sourceable; leaving `context-budget.sh` alone keeps the change inside the ticket's remit.
**Rejected:** inlining the pid check in each script — a third and fourth copy of the ADR-0010 rule; refactoring `context-budget.sh` onto the lib readers in the same commit — outside the ticket, and the measurer is the riskiest script to touch. Also rejected: renaming the `locked=` field and the "work-item lock" message — the ticket says keep the output shape.
**Blast radius:** `scripts/lib/session-lib.sh`, `scripts/attach-session.sh`, `scripts/statusline-context-budget.sh`, their three suites.
**Promote?:** no — follow-up candidate: point `context-budget.sh`'s `owner_live()` at the lib reader so the rule has one copy.
