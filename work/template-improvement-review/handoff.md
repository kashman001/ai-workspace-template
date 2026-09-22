<!--
PURPOSE: This is the LEDGER (provenance log). Append-only, newest block on
TOP. Each "# Session Handoff" block records what happened in one session.
Read the TOP block only; older blocks are in handoff-archive.md. Forward
"what to do next" belongs in next-session.md, NOT here.
Convention: docs/work-directory-conventions.md.
-->

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

# Session Handoff — 18 (2026-09-22): Stage 4 live cutover, attended: runbook steps 0–3 verified on the live checkout; attended `--clear` rollover run (step 4)

**Summary.** No agents; human at the keyboard. Started fresh on the new
scripts, unsupervised (runbook step 3). Verified live: `scripts/fleet.sh`
present; HEAD = 37d4100 (`cutover: merge stage4 into main`); `pgrep -f
session-loop.sh` empty (old supervisor gone); record before register
`{"schema": 1, "seq": 18}` (import done; this item's dir holds only
`.agent-dispatch/` and `.session-loop.log`); `register` → `bound
work/template-improvement-review seq=18 via=project (filled)`, `.session.pid`
34573; `supervised` → `unsupervised`, rc 1. Tracker: cutover row Used 2,
"Now" rewritten. Ledger block 16 archived. Then step 4: this block, the
launcher for 19, one bookkeeping commit, `--check`, `--clear`. Whether the
seed line appeared after `/clear` is session 19's evidence, not mine.

**Findings.** (1) `git status --short` was not empty at step 3: 13
untracked old-script state files (`.rollover-options`, `.session-seq`,
`.session-seq.provenance.json`) in six *other* work items
(automatic-session-rollover, context-decay, devex-review, sdlc-ai-mapping,
template-maintenance, usage-scenarios). The merged `.gitignore` no longer
hides them; runbook step 2 cleaned only this item. Not a blocker here
(nothing on this item reads them). Left untouched: some of those items may
still need `scripts/import-session-seq.sh <item>` before the import script
is retired (ticket 10's last box); the human decides per item. Recorded in
the tracker's cutover row.

**Decisions.** None new. Rejected: deleting the other items' stale files
now (outside this item; deleting `.session-seq` before an import loses that
item's counter).

**Learnings:**
- Session 18 cost ~64K at `register` before any work: the SessionStart
  hooks' injected context (plugin skill text, tool schemas) is the floor
  for a fresh Claude Code session here.

**Open / next.** Session 19, same process after `/clear`: confirm the seed
line and the record fields (runbook step 4), then step 5 (`close` +
`/exit`). Chain of 2 follows (steps 6). Follow-up outside this item: retire
`scripts/import-session-seq.sh` after every live item is imported.
