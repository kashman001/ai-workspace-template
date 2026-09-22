<!--
PURPOSE: This is the LEDGER (provenance log). Append-only, newest block on
TOP. Each "# Session Handoff" block records what happened in one session.
Read the TOP block only; older blocks are in handoff-archive.md. Forward
"what to do next" belongs in next-session.md, NOT here.
Convention: docs/work-directory-conventions.md.
-->

# Session Handoff — 1 (2026-09-22): scaffolded from template-improvement-review's open threads; three tickets written, item ready for a session loop

**Summary.** Created by the session that closed `template-improvement-review`
(seq 23 of that item), attended, on the human's request to categorize the
open work and make a work item for it. Four categories sorted (README); only
the engineering follow-through is in scope: tickets 01 (`.active-session`
readers onto the record), 02 (one ledger-heading rule), 03 (template version
marker). `context-budget.env` set to `auto` for the loop. This session did
**not** register on this item, so no record exists: the loop's launcher will
open `seq=2` from this block. No code changed.

**Findings.** `grep -rn '\.active-session' scripts/` confirms the two readers
in ticket 01 read a file the cutover retired; `import-session-seq.sh` deletes
it as an old-script file.

**Decisions.** Ticket 03 is built under a stated assumption rather than
waiting for the human's choice of marker shape; the Decision note is the
reversal point. Rejected: leaving it as a human-only item, because the human
asked for a loop-driven item that finishes the open work.

**Open / next.** Ticket 01. Start the loop with
`scripts/session-loop.sh session-management-followups --max-sessions 3`.
