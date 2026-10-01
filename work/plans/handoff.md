<!--
PURPOSE: This is the LEDGER (provenance log). Append-only, newest block on
TOP. Each "# Session Handoff" block records what happened in one session.
Read the TOP block only; older blocks are in handoff-archive.md. Forward
"what to do next" belongs in next-session.md, NOT here.
Convention: docs/work-directory-conventions.md.
-->

# Session Handoff — 18 (2026-09-30): ticket 13 done — a closed chain.plan yields to the one open plan; rolled hands-off at 89 K, ahead of ticket 14

1. Registered `seq=18`. Ticket 13 test-first: T6g–j (`plan.sh`, closed `chain.plan` + one open plan) and P5a–d (`session-loop.sh`, the s18 layout) red; old T6c asserted the bug and was rewritten to "an open chain.plan beats another open plan".
2. Fix in `scripts/plan.sh` `resolve_plan` and the binding block of `scripts/session-loop.sh`: a record-sourced closed `chain.plan` rebinds to the single open plan; several open → exit 2 / `plan_invalid leg=ambiguous`; none open → binding kept (so `plan_closed` still fires); `--plan` never overridden. `plan.sh new` prints `--plan <name>` (T5k). Wording in both headers, `docs/plans.md` → Resolution, `docs/context-budget.md` → Plans.
3. Suites: test-plan 243, test-session-loop 144, test-doc-consistency 17, test-template-version 9, test-check-ledger 29. Tier-2 note in `decisions.md` (refuse-and-name-`--plan` and plan.sh-writes-the-record rejected). Commit 9c60b69.
4. Rolled over at 89 K: ticket 14 has four sub-items and is budgeted as its own session. Archived block 16.

Suggested skills: `tdd` for ticket 14 (one failing test per sub-item in `scripts/tests/test-plan.sh`).

Learnings:
- `plan.sh note` stamps lines `- s<n> · <text>`; grep for `· <text>` in tests.

# Session Handoff — 17 (2026-09-30): ticket 12 done — ledger lint catches a duplicated block, checkpoint runs the check; rolled hands-off at 94 K, ahead of ticket 13

1. Registered `seq=17`. Ticket 12: fixtures for both s16 shapes added to `scripts/tests/test-check-ledger.py`. The splice into the purpose comment was already caught; the duplicate was not (red, 27/29).
2. `scripts/check-ledger.py` gained `check_duplicates`. A first version keyed on the title before the colon flagged three legitimate same-day pairs in `work/template-improvement-review`, so it was narrowed to verbatim duplicate headings. The clean baseline now carries a legal same-day pair. 29/29; repo-wide exit 0. Tier-2 note in `decisions.md` (prefix key and body hash rejected; TEMPLATE_VERSION bump deferred to ticket 15).
3. `skills/checkpoint/SKILL.md` step 2 anchors ledger writes on `-->`, deletes a stale block on a redo, and runs the checker; added a matching verification bullet. Backlog changelog row (no card). Suites: test-plan 238, test-session-loop 140, test-doc-consistency 17, test-template-version 9. Commit 7de9aef.
4. Rolled over at 94 K (below WARN) on purpose: ticket 13 is a full session's work. Archived blocks 15–11.

Suggested skills: `tdd` for ticket 13 (failing test first in `scripts/tests/test-plan.sh` / `test-session-loop.sh`).

Learnings:
- `scripts/tests/test-plan.sh` and `test-session-loop.sh` are not executable; run them with `bash`.
