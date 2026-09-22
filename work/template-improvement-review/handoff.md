<!--
PURPOSE: This is the LEDGER (provenance log). Append-only, newest block on
TOP. Each "# Session Handoff" block records what happened in one session.
Read the TOP block only; older blocks are in handoff-archive.md. Forward
"what to do next" belongs in next-session.md, NOT here.
Convention: docs/work-directory-conventions.md.
-->

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

# Session Handoff — 17 (2026-09-21): Stage 4 cutover rehearsed in a scratch clone (merge clean, import ok, 23 suites green); runbook written; human-only steps handed over

**Summary.** No agents. Rehearsal in a scratch clone of `main` (a0dbf15):
`git merge --no-ff origin/stage4` clean (115 files, one automatic merge in
`docs/operational-knowledge.md`, no conflict); counter import from a copy of
the live `.session-seq` (17) gave record `{"schema": 1, "seq": 17}`, second
run a no-op; every suite (22 shell with `bash`, plus `test-check-ledger.py`)
rc 0, no `FAIL` line. Wrote `cutover-runbook.md` (one page: the human's steps
0–6 in order, done criteria, rehearsal evidence). Tracker: cutover row
`in progress`, "Now" rewritten. Bookkeeping commit 9ab55ab on `main`.
Nothing pushed; nothing touched on `stage4` or any live script. Cost ~58K
at register → ~125K at WARN (targeted reads of the old and new scripts).

**Findings (all in the runbook).** (1) The merged `.gitignore` no longer
hides `.session-seq*`, so the old counter files must be deleted after the
import; step 2 lists every old state file. (2) The old supervisor is ended
with Ctrl-C at its interactive pause, never by pressing Enter: session 18
must start fresh on the new scripts, unsupervised, or it cannot run the
`--clear` rollover. (3) The chain's bootstrap refuses `owner_live` while a
live session owns the item, so session 19 ends through `close` + `/exit`
before the human starts `session-loop.sh --max-sessions 2`. (4) After the
import the record reads `seq` 18, not 17: this rollover advanced the old
counter when it staged session 18.

**Decisions.** Rehearse in a clone, never the worktree or the live `main`
(Tier 1 trailer on 9ab55ab). Runbook order Ctrl-C → merge → import → delete
old state files → attended session 18 → `--clear` → session 19 `close` →
chain of 2. Rejected: pressing Enter (session 18 would run old scripts from
the tree being merged); keeping session 19 alive while starting the chain
(bootstrap `owner_live`).

**Learnings:**
- The old launcher's `--emit` advances `.session-seq` at staging time, so an
  import taken after a rollover reads the successor's number.
- The rehearsal clone gets `stage4` as `origin/stage4`; merge that ref there.

**Open / next.** Session 18 is attended: wait for the human, run
`cutover-runbook.md` with them from step 0. Chain: the old supervisor
consumes this `--emit --loop-mode interactive` and pauses for Enter; the
runbook's step 0 tells the human to press Ctrl-C at that pause instead.
