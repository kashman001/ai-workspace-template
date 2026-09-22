<!--
PURPOSE: This is the LEDGER (provenance log). Append-only, newest block on
TOP. Each "# Session Handoff" block records what happened in one session.
Read the TOP block only; older blocks are in handoff-archive.md. Forward
"what to do next" belongs in next-session.md, NOT here.
Convention: docs/work-directory-conventions.md.
-->

# Session Handoff — 21 (2026-09-22): Stage 4 live cutover, chain leg 2: chain capped, cutover row and ticket 10 closed; rolled over hands-off

**Summary.** No agents; nobody at the keyboard. Second and last child of
the `session-loop.sh --max-sessions 2` chain (runbook step 6). `register`
→ `seq=21 via=project (refreshed)`, 58K at register. Chain evidence:
`.session-loop.log` `session #20 ended rc=143` → `verdict=staged seq=20
successor=21 mode=handsoff` → `starting session #21 (2 of 2)`; record
`.chain.used` 2 of cap 2, `.chain.closed` null, supervisor pid 74444 live
(`kill -0` rc 0); `.launch.predecessor` seq 20, disposition `rolled_over`;
`supervised` rc 0. Ticket 10: import, attended rollover, chain, and
tracker/ledger boxes ticked; retire-import box left open. Tracker: cutover
row `done`, Done 2026-09-22, Commit 37d4100, Used 5; "Now" says Stage 4
complete. Ledger block 19 archived. Launcher for 22 written (capped;
nothing to do). Ended with `record` then `launch-next-session.sh --emit
--loop-mode handsoff`; the supervisor should print `verdict=cap seq=22` and
exit 0.

**Findings.** None new. Session 20 ended `rc=143` (SIGTERM) in the log and
the supervisor still judged it `staged`; that is the hands-off self-kill
path working as designed, not a fault.

**Decisions.** None new.

**Learnings:**
- The whole two-leg chain ran unattended in about two minutes per leg;
  each leg well under WARN.

**Open / next.** Chain capped. Nothing until the human restarts with
`session-loop.sh template-improvement-review --reset-cap`. Follow-up (one
agent commit, after the six other items are imported): retire
`scripts/import-session-seq.sh`, its test, and its "Reason codes" row.
Outside scope: `attach-session.sh` and `statusline-context-budget.sh`
still read `.active-session`.

# Session Handoff — 20 (2026-09-22): Stage 4 live cutover, chain leg 1: supervisor confirmed live under `session-loop.sh --max-sessions 2`; rolled over hands-off

**Summary.** No agents; nobody at the keyboard. First child of the chain the
human started at runbook step 6. `register` → `seq=20 via=project
(refreshed)`, ~63K at register. Chain evidence: `.chain.supervisor.pid`
74444 live (`kill -0` rc 0, started 2026-09-22T15:14:23Z), `.chain.used` 1,
`.chain.cap` 2, `.chain.closed` null; `supervised` rc 0;
`.session-loop.log` shows `staging the first session` then `starting session
#20 (1 of 2)`. Record: `.session.seq` 20, `.launch.pending` null,
`.launch.predecessor.disposition` `stopped` (session 19 left through
`close`), predecessor seq 19. Tracker: cutover row Used 4 with the evidence,
"Now" rewritten. Ledger block 18 archived. Launcher for 21 written. Ended
with `record` then `launch-next-session.sh --emit --loop-mode handsoff`.

**Findings.** None new. Note only: the log file's lines carry a timestamp
and no `session-loop:` prefix; the runbook's table shows the terminal form.
Same lines, not a discrepancy worth a runbook edit.

**Decisions.** None new.

**Learnings:**
- A hands-off chain leg with no new work costs ~63K at register plus the
  bookkeeping; well under WARN.

**Open / next.** Session 21: confirm `verdict=staged seq=20` and
`.chain.used` 2; tick ticket 10; cutover row `done` with 37d4100; roll over
`--emit --loop-mode handsoff` so the supervisor reports `cap seq=22`.
Follow-up outside this item unchanged: import the six other items, then
retire `scripts/import-session-seq.sh`.
