<!--
PURPOSE: This is the LEDGER (provenance log). Append-only, newest block on
TOP. Each "# Session Handoff" block records what happened in one session.
Read the TOP block only; older blocks are in handoff-archive.md. Forward
"what to do next" belongs in next-session.md, NOT here.
Convention: docs/work-directory-conventions.md.
-->

# Session Handoff — 3 (2026-10-08)

1. Ticket 03 (L60) done, commit `21d03a6`: checkpoint → "Classify before
   you write" gains "Promote a repeat to a check"; gotchas may carry an
   `**Enforced by:**` line (defined in the `operational-knowledge.md`
   header), back-filled on three entries. decision-log unchanged (it
   already points to checkpoint).
2. Ticket 05 (L62) done, commit `ca43dec`: the fail-test rule lives in
   `docs/workspace-structure.md` → "Authoring a Team Capability". Audit
   table in the ticket. Three new suites: `test-check-repo-context.sh`,
   `test-check-service-access.sh`, `test-check-workspace-structure.sh`.
   Guide HTML regenerated. run-checks 38/0/0. Scorecard 3/109/5/0/6.
3. Two Tier-2 notes added to `decisions.md`.
4. Rolled over at WARN (121K) after ticket 05. Next: ticket 04 (L61), the
   last one.

Learnings:
- "Has a suite" is not "has a suite that makes it fail": the structure
  check's only suite asserted a warning, never exit 1.

# Session Handoff — 2 (2026-10-08)

1. Ticket 02 (M45) done, commit `87b5776`: `scripts/check-drift.sh`
   (dead backticked paths, gotchas past review age, CONTEXT.md over 16,000
   bytes, unindexed docs; ADR hits warn). Suite
   `scripts/tests/test-check-drift.sh` D1–D4. Checkpoint step 1 now runs
   it; CI gains a weekly schedule. Full run-checks 35/0/0. Card M45
   archived; new open card **L63** (two removed scripts in the
   `workspace-structure.md` tree). Scorecard 5/107/5/0/6. Two Tier-2 notes.
2. First run on `main`: one ADR-0009 warning, nothing failing. L58/L59
   were already fixed by `template-maintenance`.
3. Rolled over at 116K by pre-flight (not WARN): ticket 03 is doc-heavy
   and would have ended near STOP. Next: ticket 03 (L60).

Learnings:
- Bash 3.2 (macOS) fails to parse a `case` with `pat)` arms inside
  `$( … )` ("syntax error near `;;`"); use `if` there.
