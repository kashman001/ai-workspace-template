<!--
PURPOSE: This is the LEDGER (provenance log). Append-only, newest block on
TOP. Each "# Session Handoff" block records what happened in one session.
Read the TOP block only; older blocks are in handoff-archive.md. Forward
"what to do next" belongs in next-session.md, NOT here.
Convention: docs/work-directory-conventions.md.
-->

# Session Handoff — 17 (2026-09-30): ticket 12 done — ledger lint catches a duplicated block, checkpoint runs the check; rolled hands-off at 94 K, ahead of ticket 13

1. Registered `seq=17`. Ticket 12: fixtures for both s16 shapes added to `scripts/tests/test-check-ledger.py`. The splice into the purpose comment was already caught; the duplicate was not (red, 27/29).
2. `scripts/check-ledger.py` gained `check_duplicates`. A first version keyed on the title before the colon flagged three legitimate same-day pairs in `work/template-improvement-review`, so it was narrowed to verbatim duplicate headings. The clean baseline now carries a legal same-day pair. 29/29; repo-wide exit 0. Tier-2 note in `decisions.md` (prefix key and body hash rejected; TEMPLATE_VERSION bump deferred to ticket 15).
3. `skills/checkpoint/SKILL.md` step 2 anchors ledger writes on `-->`, deletes a stale block on a redo, and runs the checker; added a matching verification bullet. Backlog changelog row (no card). Suites: test-plan 238, test-session-loop 140, test-doc-consistency 17, test-template-version 9. Commit 7de9aef.
4. Rolled over at 94 K (below WARN) on purpose: ticket 13 is a full session's work. Archived blocks 15–11.

Suggested skills: `tdd` for ticket 13 (failing test first in `scripts/tests/test-plan.sh` / `test-session-loop.sh`).

Learnings:
- `scripts/tests/test-plan.sh` and `test-session-loop.sh` are not executable; run them with `bash`.

# Session Handoff — 16 (2026-09-27/30): ledger defects fixed; then, the dogfood plan having closed, ticket 11 done, L48 verdict, findings → tickets 12–15; rolled hands-off at WARN

1. Registered `seq=16` (person restarted after the cap). `plan.sh status --project jev-integration`: `01-gated-integration` open, wave 1 of 3, 0/6 done, frontier `01-decision-note`; jev chain closed (`quit_plain`, 2026-09-25 22:23Z), no supervisor running. No `plan_closed` line, so ticket 11 stays open — launcher step 2 applied.
2. Found the s15 redo had left its stale first pass in `work/jev-integration/handoff.md` (session-6 block twice, both 6→7 bridges; the stale one claimed session 6 never closed). Removed the stale copy; its one unique fact (two supervisor processes) folded into the kept bridge. Commit 5f35266.
3. Found the s15 block of *this* ledger spliced into the header comment. Moved it out to its proper place above block 14; header restored.
4. Both recorded under "Dogfood findings" in `decisions.md` as a candidate ticket 12 (ledger lint). Suites green: test-plan 238, test-session-loop 140, test-doc-consistency 17, test-template-version 9. Nothing pushed.
5. Checkpointed (ac9e447); the user returned 2026-09-30 and asked to finish the remaining work. The dogfood plan had closed meanwhile (`plan_closed seq=17`, 2026-09-29; 18/18, 8 sessions, no split). Ticket 11 closed against that evidence; L48 verdict written (adopt as a plans-skill recipe, keep `wayfinder`); the 12 findings triaged into tickets 12 (ledger lint), 13 (default plan is the open one: plan.sh + session-loop), 14 (plan.sh ergonomics), 15 (docs/skill wording, incl. the L48 recipe). Status lines updated. Commit ecfac2e.
6. Found `scripts/check-ledger.py` already exists and passes both ledgers; ticket 12 narrowed to fixtures for the two s16 shapes + the checkpoint skill step. Rolled over hands-off at WARN (~120K); the user exited.

Learnings:
- A ledger write that anchors on the first `# Session Handoff` match hits the header comment's example text; anchor on `-->` (end of the header) instead.
- After any ledger write, `grep -c '^# Session Handoff'` against the expected count is a two-second check that would have caught both defects.
