<!--
PURPOSE: This is the LEDGER (provenance log). Append-only, newest block on
TOP. Each "# Session Handoff" block records what happened in one session.
Read the TOP block only; older blocks are in handoff-archive.md. Forward
"what to do next" belongs in next-session.md, NOT here.
Convention: docs/work-directory-conventions.md.
-->

# Session Handoff — 22 (2026-09-22): post-cap restart; retire-import follow-up checked and found blocked (six items still on the old counter); closed through the stop door

**Summary.** No agents; hands-off session started by the human via
`session-loop.sh template-improvement-review --reset-cap`. `register` →
`seq=22 via=project (refreshed)`, 59K at register. Checked the one open
follow-up's precondition (ticket 10, last box): every live item with a
`.session-seq` must be imported before `import-session-seq.sh` is retired.
Six are not — none has a `session-state.json`: automatic-session-rollover
(old 32), context-decay (7), devex-review (8), learn-agentic-workflows (3),
template-maintenance (16), usage-scenarios (6). The launcher's list named
sdlc-ai-mapping instead of learn-agentic-workflows; sdlc-ai-mapping carries
only `.rollover-options`, no counter. Nothing retired; ticket 10 stays
`ready-for-agent` with one box open. Ledger block 20 archived; tracker
"Now" and launcher corrected. Ended with `record` then
`context-budget.sh close` (stop door), no rollover.

**Findings.** None new. The stale item name in the launcher was a
transcription slip in session 21, not a script fault.

**Decisions.** None new.

**Learnings:**
- The import precondition is cheap to verify: `ls work/*/.session-seq` plus
  a check for a sibling `session-state.json` per item.

**Open / next.** Same as before: retire `scripts/import-session-seq.sh`,
`scripts/tests/test-import-session-seq.sh`, and its "Reason codes" row in
`docs/context-budget.md` once the six items above are imported (the human
or their own sessions run `scripts/import-session-seq.sh <project>` on
each). Outside scope: `attach-session.sh` and
`statusline-context-budget.sh` still read `.active-session`.

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
