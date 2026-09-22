<!--
PURPOSE: This is the LEDGER (provenance log). Append-only, newest block on
TOP. Each "# Session Handoff" block records what happened in one session.
Read the TOP block only; older blocks are in handoff-archive.md. Forward
"what to do next" belongs in next-session.md, NOT here.
Convention: docs/work-directory-conventions.md.
-->

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


# Session Handoff — 19 (2026-09-22): Stage 4 live cutover, attended: `--clear` rollover confirmed (runbook step 4); closed through the stop door for the chain (step 5)

**Summary.** No agents; human at the keyboard. Same Claude Code process as
session 18 after `/clear`. Step 4 evidence: the SessionStart:clear hook
fired and its output carried the seed line (`Work item
template-improvement-review - rollover session #19. Read
work/template-improvement-review/next-session.md and continue from First
actions`); record `.session.seq` 19, `.launch.pending` null,
`.launch.predecessor.disposition` `rolled_over`, predecessor seq 18 with
session 18's session id; `register` re-run → `seq=19 via=project
(refreshed)`, pid 34573 unchanged (same process). Tracker: cutover row Used
3, "Now" rewritten. Ledger block 17 archived. Launcher for 20 written. Then
step 5: `close` (exit 0) and the human runs `/exit`, then
`scripts/session-loop.sh template-improvement-review --max-sessions 2`.

**Findings.** (1) The seed line is delivered as hook `additionalContext`,
which reaches the agent's context and not the human's terminal: after
`/clear` the human saw nothing and reported "the expected hook did not
fire", while the agent had the seed. The mechanism works; the runbook's
"what to look for" was addressed to the wrong reader. Runbook step 4
amended with one sentence (the agent confirms the seed; the human sees
nothing). No script change needed.

**Decisions.** None new.

**Learnings:**
- Session 19 measured ~60K at `register` before work (hook context floor,
  consistent with session 18's ~64K).

**Open / next.** Human: `/exit`, then start the chain (runbook step 6).
Session 20 confirms the supervisor; 21 records the final evidence and ticks
ticket 10. Follow-up outside this item unchanged: import the six other
items, then retire `scripts/import-session-seq.sh`.
