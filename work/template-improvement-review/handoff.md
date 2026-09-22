<!--
PURPOSE: This is the LEDGER (provenance log). Append-only, newest block on
TOP. Each "# Session Handoff" block records what happened in one session.
Read the TOP block only; older blocks are in handoff-archive.md. Forward
"what to do next" belongs in next-session.md, NOT here.
Convention: docs/work-directory-conventions.md.
-->

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

# Session Handoff — 16 (2026-09-21): Stage 4 wave F (phase 8: mirrors removed, skill/docs/ADRs on the record, doc-consistency test) done by one agent; merged to `stage4`

**Summary.** One general-purpose agent in `.claude/worktrees/s4-phase-8` (off
`stage4` 5c7edc0). It was cut off once by a transient API 529 after its sixth
commit, resumed with one message and finished: seven commits (plan f381eb0;
mirrors 12ba7d8; settings/ignore/env f685889; doc + doc test 8c3d6d9; skill
7512cf2; CONTEXT/ops-knowledge/ADRs 4621ae7; evidence e84ac10), ~420K agent
tokens. Returned DONE_WITH_CONCERNS, no user questions. Merged `--no-ff`
9cfa3d5; full run on `stage4`: 22 shell suites + Python ledger suite all
green, no lock flake. Tracker row 8 done; Tier-2 note in `decisions.md`;
report `dispatch/phase-8.md`; plan + Evidence + Concerns in
`plans/phase-8.md` (on `stage4`). Bookkeeping commit c47edeb on `main`.
Agent worktree and branch removed. `stage4` is 30 commits ahead of `main`;
all eight phases merged. Nothing pushed; `main` ahead 27 after this
rollover's commit. Parent cost ~60K at register → ~112K at the wave record.

**User instruction (2026-09-21, binding):** keep running overnight, roll
over and start the next session automatically; the user checks back in the
morning. So this rollover is `--loop-mode handsoff` even though the cutover
was planned attended: session 17 does every unattended-safe cutover step and
expresses the human-only step by rolling over `--loop-mode interactive`,
never by idling (the watchdog kills an idle child after
`SESSION_LOOP_KILL_AFTER`=4h).

**Decisions.** Phase 8 (decisions.md 2026-09-21): record is the only state;
`--emit` takes no path and prints `cmd: <line>`; `/clear` seed = `register`
stdout on a pending bind (stub-verified only); doc-consistency test over one
doc section and two script surfaces; ADR-0010/0011/0012 new, 0007/0008
superseded, 0004/0005/0006/0009 amended; the "three Open change-log entries"
never existed. Parent: merged on the agent's green run, re-ran every suite
on `stage4` before closing.

**Learnings:**
- A 529-terminated agent keeps its worktree and transcript; one SendMessage
  with "re-read disk, continue from your last report block" resumed it
  cleanly. Check `git log` and the dispatch report before resuming.
- The cutover must land launcher and supervisor together: stage4's `--emit`
  takes no path, the old supervisor on `main` passes one.
- `scripts/attach-session.sh` and `scripts/statusline-context-budget.sh`
  still read `.active-session` (their suites use fixtures). Not a mirror;
  follow-up onto the record's `session` block, else the statusline shows no
  project segment for record-bound sessions.

**Open / next.** Session 17 = cutover. Unattended-safe first: rehearse
`main`+`stage4` merge, counter import and every suite in a scratch clone;
write a one-page cutover runbook. The attended `--clear` (confirms the
`/clear` seed) and the new 2-session chain need the human; hand those over
with `--loop-mode interactive`. Chain: the old supervisor (`--max-sessions
15`, restarted at session 15) consumes this `--emit` normally.
