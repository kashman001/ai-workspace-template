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

# Session Handoff — 15 (2026-09-21): Stage 4 wave E (phase 7: probes, stub twins, lock fix, Claude Code acceptance) done by one agent; merged to `stage4`

**Summary.** One general-purpose agent in `.claude/worktrees/s4-phase-7` (off
`stage4` 256b36b), dispatch contract in its prompt. Returned DONE in 68 min,
~295K agent tokens: five commits (plan 54b623c; lock fix fae4746; probes +
twins 30f2632; trust-dialog match f2cebb2; evidence 909dc14). Probes V1/V3/V10
are self-checking scripts under `evaluation/probes/` (one assertion lib);
`scripts/tests/test-probe-twins.sh` (37 asserts) runs the same scripts under a
stub `claude` that honours the real hooks; H1 spent stage + H2 refused hand
`--emit`; `session-lib.sh` lock loop retries a lost race (64 asserts, 5× green).
Claude Code acceptance passed headless in a scratch clone: V1 18/18, V3
`--max-sessions 2` 15/15 (`staged`, `staged`, `cap`). Merged `--no-ff` 5c7edc0;
full run on `stage4`: 21 shell suites + Python ledger suite all green, no lock
flake. Tracker row 7 done; Tier-2 note in `decisions.md`; report
`dispatch/phase-7.md`; plan + Evidence + Concerns in `plans/phase-7.md` (on
`stage4`). Bookkeeping commit 8b4837e on `main`. Agent worktree and branch
removed. Nothing pushed; `main` ahead 25 after this rollover's commit. Parent
cost ~59K at register → ~117K at the wave record.

**Decisions.** Phase 7 (decisions.md 2026-09-21): twin = same probe script
under a stub runtime; stub honours the hooks contract; acceptance in a `git
clone`, not the worktree; V1 via `claude -p` on the launcher's own command,
V3 under `expect`; lock retry only for a lost race; **mirror removal deferred
to phase 8** (third `.session-loop` reader = launcher `invoked_by_supervisor`;
`.next-command` is also `--emit`'s output contract). Parent: merged on the
agent's green run, re-ran every suite on `stage4` before closing (5c7edc0
trailer).

**Learnings:**
- Every script resolves its root via `git rev-parse --git-common-dir`, so
  scripts run from a worktree drive the MAIN checkout's `work/` (only hook-lib
  honours `WORKSPACE_ROOT`). A clone is the safe sandbox for acceptance runs.
  Candidate for `docs/operational-knowledge.md` (phase 8 owns docs prose).
- A supervised session's tool shells (and its subagents) inherit
  `TF_SESSION_LOOP=1` + `TF_SESSION_LOOP_PROJECT`; a hand `--emit` from a
  subagent is refused `no_supervisor`. Phase 8 docs line.
- A real TUI child in a fresh folder needs the folder-trust dialog answered
  once; `claude -p` neither shows nor records it. The probe driver answers it.
- Lock race S8/S10a: fixed, not a flake anymore — any lock-race red is real.

**Open / next.** Wave F = phase 8 alone (ticket 09: skill, docs, ADRs,
ignore file, env, doc test) plus the deferred mirror removal (exact readers +
pins in `plans/phase-7.md` Concerns 1, on `stage4`). Carry-overs into phase 8:
stage4 `.claude/settings.json` clear-seed SessionStart entry; prose naming
`--bg`/`--unstage`/`.rollover-options`; stale `.gitignore` lines; the
`--clear` prompt injector (phase 5 decision 4); vendor configs naming shim
paths (optional). Then session 17 = cutover (attended). Chain: restarted by
the human at session 15 with `--reset-cap` (`--max-sessions 15`), so this
rollover's `--emit` is consumed normally.

# Session Handoff — 14 (2026-09-18): Stage 4 wave D (phase 5, supervisor with three verdicts) done by one agent; merged to `stage4`; chain cap reached

**Summary.** One general-purpose agent in `.claude/worktrees/s4-phase-5` (off
`stage4` 4bb8a5d), dispatch contract in its prompt. Returned DONE_WITH_CONCERNS
in 28 min, ~288K agent tokens: five commits (plan 1966929; `main "$@"` wrapper
f771dd4 with no other change, old suite 222/222 before and after; body +
stub-child suite 4299159; launcher mirror deletions bbd31e6; evidence 6418a82).
Supervisor 1002→381 lines; `test-session-loop.sh` 105 asserts, stub children
staged through the real launcher `--emit`. Merged `--no-ff` 256b36b; full run on
`stage4`: 20 shell suites + Python ledger suite, one red (`test-session-lib.sh`
S10a lock race, lib untouched by the branch), green on two reruns. Tracker row 5
done; Tier-2 note in `decisions.md`; report `dispatch/phase-5.md`; plan +
Evidence + "Concerns for the parent" in `plans/phase-5.md` (on `stage4`).
Bookkeeping commit d14cc8e on `main`. Agent worktree and branch removed.
Nothing pushed; `main` ahead 23 after this rollover's commit. Parent cost ~58K→
~101K at prep.

**Decisions.** Phase 5 (decisions.md 2026-09-18): spent stage = `staged_invalid
leg=spent`; `no_own_measurement` from the record's `registered_at`; stall guard
watches the three markdown files + `handoff-archive.md`; watchdog kept on the
record; `--reset-cap` standalone; the `--clear` prompt is not the supervisor's.
Two mirrors STILL written because their readers are files phase 5 may not edit:
`.session-loop` marker (measurer `supervised`) and `.next-command` +
`.session-seq.bump.json` (hook-lib turn-end self-kill). Parent: S10a not sent
back (d14cc8e trailer) — third lock-race sighting, the lock fix is phase 7's.

**Learnings:**
- `test-session-lib.sh` lock race, strike three (S8 ×2, S10a ×1): the loop's
  `[ -d "$lock" ] || refuse record_unwritable` fires when the holder releases
  between the failed `mkdir` and the check (`scripts/lib/session-lib.sh:60-61`
  on `stage4`). Fix = retry, not refuse. In tracker row 1 notes.
- Parked (agent, plans/phase-5.md Evidence): bash 3.2 fails to parse a literal
  `(` before `$(… "?" …)` inside double quotes.
- The harness cwd moved into the stage4 worktree again from a `cd` in a
  compound command; `cd` back to the root restores it. Already in
  `docs/operational-knowledge.md`.

**Open / next.** Wave E = phase 7 alone (ticket 08: probes on record fields,
stub-runtime twins, Claude Code acceptance on the throwaway item), plus the
lock fix. Phase 7's plan decides whether it also moves `supervised` to
`chain.supervisor` and hook-lib to `staged.by` (then deletes the two mirrors)
or leaves that to phase 8. Carry-overs unchanged: stage4 `.claude/settings.json`
clear-seed SessionStart entry (phase 8); prose naming `--bg`/`--unstage`/
`.rollover-options` (phase 8); vendor configs naming shim paths (optional);
stale `.gitignore` lines for deleted state files (phase 8). **Chain: this
session was 10 of 10 — the `--emit` at this rollover trips the cap; the
supervisor reports `cap` and stops. Restart: `scripts/session-loop.sh
template-improvement-review --reset-cap`.**

# Session Handoff — 13 (2026-09-18): Stage 4 wave C (phases 4 ∥ 6) done by two agents; merged to `stage4`

**Summary.** Two general-purpose agents in `.claude/worktrees/s4-phase-{4,6}`
(off `stage4` 0a117c6), dispatch contracts in their prompts, file split from
the fleet plan. Phase 6 (hook dispatcher, 67dc8a9) returned DONE in 16 min;
phase 4 (launcher on the record, 5330f86) DONE_WITH_CONCERNS in 23 min — four
handoff notes, no defects. Merged 4 first (26b214c, 21/21 green on `stage4`),
then 6 (4bb8a5d, 20/21: `test-session-lib.sh` S8 lock race, rerun 55/55).
Tracker rows 4 and 6 done; two Tier-2 notes in `decisions.md`; reports in
`dispatch/phase-{4,6}.md`; plans + Evidence in `plans/phase-{4,6}.md` (on
`stage4`). Bookkeeping commit 6ce5d8a on `main`. Agent worktrees and branches
removed. Nothing pushed; `main` ahead 21 after this rollover's commit.

**Decisions.** Phase 6 merge held until phase 4 was green (6ce5d8a trailer).
Phase 4: twelve gates, one record write, `no_supervisor` only for a
`TF_SESSION_LOOP=1` session, `.session-seq` + sidecars write-only for phase 5.
Phase 6: adapter table is a data file, seven wrappers become one-line shims
at their old paths, `jq_missing` on stderr exit 0 (decisions.md 2026-09-18).
S8 flake not sent back (no wave C branch touched the lib or its suite).

**Learnings:**
- Two agents per wave cost the parent ~53K (58K→111K at bookkeeping); agents
  spent ~325K (phase 4) and ~152K (phase 6). Fits one session with headroom.
- `test-session-lib.sh` S8 (3-writer lock race): second sighting, now in the
  tracker row 1 notes for phase 7. Strike three means fix the lock, not rerun.
- `cd` into a worktree moving the harness cwd: bit again, promoted to
  `docs/operational-knowledge.md`.
- Harness agents: "Agent finished" can arrive before its report when the
  agent still has background work; the hand-back message is the real signal.

**Open / next.** Wave D = phase 5 alone (supervisor, three verdicts), one
agent; first commit is the `main "$@"` wrapper on `session-loop.sh`. Carry-
overs for later phases: stage4 `.claude/settings.json` SessionStart entry for
the deleted clear-seed hook (guarded no-op; phase 8), `--clear` prompt in
`launch.pending.prompt` has no injector (phase 5/7 decide), prose naming
`--bg`/`--unstage`/`.rollover-options`/seed file in the skill, docs, ADR-0009,
`CONTEXT.md` (phase 8), vendor configs still name the shim paths (optional).
Chain: session 13 is 9 of 10 — the cap lands at session 14's rollover.

# Session Handoff — 12 (2026-09-17): Stage 4 wave B (phase 3, measurer on the record) done by one agent; merged to `stage4`

**Summary.** One general-purpose agent in `.claude/worktrees/s4-phase-3` (off
`stage4`) with the dispatch contract in its prompt. Returned DONE: measurer
`register`/`release`/`close`/`--check` now write the per-item record through
`session_record_update`; registry suite rewritten (187 asserts), numbering
suite rewritten (18); `seq-sync`/`opts-sync`/`rollover-complete` refuse with
a pointer; `rollover-prep.sh`, `capture-rollover-options.sh` and three suites
deleted; measurer 1265→1017 lines. Commit d4fb3b6, merged `--no-ff` 0a117c6.
Full suite on `stage4`: 21 suites, one red (`test-session-loop.sh` D5b-g, a
reap/notify timing race phase 3 never touched), rerun 221/221 green — treated
as a flake (bookkeeping commit e1778da on `main` says so). Agent worktree and
branch removed. Tracker row 3 done; two Tier-2 notes in `decisions.md`;
report in `dispatch/phase-3.md`; plan + Evidence in `plans/phase-3.md` (on
`stage4`). Nothing pushed; `main` ahead 19.

**Decisions.** Registry record stays, per-item side files go; `record`/
`watch`/`supervised` unchanged; `owner_live` is logged not refused;
non-owner `release` exits 1; env binding needs both vars and an equal seq
(decisions.md 2026-09-17, phase 3 notes). D5b-g flake not sent back to the
agent (commit e1778da trailer).

**Learnings:**
- One agent per wave cost the parent ~40K (57K→97K at prep); the agent
  itself spent ~285K tokens over 75 min, most of it the two suite rewrites.
- `test-session-loop.sh` D5b-g can fail under load with a 97 s hold; first
  strike — if it bites again, the alarm-reap race is real, not the test.
- Phase 3 left prose naming `seq-sync` in `launch-next-session.sh` remedy
  text (lines ~323/582/1217, pinned by T23i4/E8d) for phase 4, and skill/
  README/.gitignore mentions for phase 8. Child locks are no longer written
  by `register` (fleet, phase 7).
- The primary session's `cd` into a worktree inside a compound Bash command
  moves the harness cwd there; use `git -C` and absolute paths instead.

**Open / next.** Wave C: phases 4 ∥ 6, two agents on `s4-phase-4` and
`s4-phase-6` from `stage4`; merge 4 before 6. Hazard: phase 4 deletes the
clear-seed hook + its test; phase 6 owns every other hook. Chain: session 12
was 8 of 10; cap lands around session 14.

# Session Handoff — 11 (2026-09-17): Stage 4 wave A (phases 1 ∥ 2) done by a two-agent fleet; merged to `stage4`

**Summary.** Phase 0 marked done (131142a). `stage4` branched from `main`
and checked out only in `.claude/worktrees/stage4`. Wrote
`plans/fleet-plan.md` (waves A–F + cutover, per-agent contract, parent's
merge loop, hazards). Launched two general-purpose agents in parallel, each
in its own worktree (`s4-phase-1`, `s4-phase-2` off `stage4`), with the
dispatch contract from `dispatch-open` in their prompt. Both returned DONE:
phase 1 = `scripts/lib/session-lib.sh` + `test-session-lib.sh` (55 asserts,
race 3×20 → seq 60), commit 8cb363d; phase 2 = `scripts/fleet.sh` (five verbs,
pure move), measurer 1454→1265 lines, three suites renamed `test-fleet-*`,
commit f07f5ea. Merged with `--no-ff` (1e6f857, 5a4aec6); every suite run on
`stage4` after each merge: 24/24 rc=0. Agent worktrees and branches removed.
Dispatch reports in `dispatch/phase-{1,2}.md`. Nothing pushed; main ahead 16+.

**Decisions.** Rollovers hands-off, no per-wave okay (user, mid-session);
`stage4` never checked out in the primary tree; agents' interface/lock and
copy-not-share choices (decisions.md 2026-09-17, four notes).

**Learnings:**
- Two parallel agents plus merges and suites cost the parent ~60K (56K→118K);
  the agent prompts themselves are the big item. One agent per wave is cheap.
- `git branch -d` judges "merged" against the current branch (`main`), so it
  refuses branches merged into `stage4`; check `git branch --merged stage4`
  then `-D`.
- A branch named `stage4/phase-1` cannot coexist with branch `stage4` (ref
  namespace); hence `s4-phase-<n>`.
- The full suite run takes ~8–10 min (`test-session-loop.sh` is ~4 min);
  background it and never merge into the worktree while it runs.
- Phase 2 found Part 4's "~400 lines" was ~190; `fleet.sh` depends on the
  measurer's `check` printing `runtime=`/`artifact=` — phase 3 must keep them.

**Open / next.** Wave B: phase 3 (measurer on the record), one agent on
`s4-phase-3` from `stage4`; then wave C. Chain: session 11 was 7 of 10.

# Session Handoff — 10 (2026-09-16): Stage 4 tickets cut; phase 0 tasks 2–5 done; chain ended by a plain quit

**Summary.** Cut ten tickets from Part 4 (`issues/01`–`10`, one per phase +
cutover, edges per "Order and gates"; commit 0c1dd35, no user quiz — the
launcher fixed the granularity). Phase 0 (`plans/phase-0.md`): root
`ROLLOVER_RELAUNCH` flipped to `manual` with a committed per-item `auto`
override for this item; `jq` pinned by `test-check-dependencies.sh` D5;
`SESSION_LOOP_NOTIFY` now resolves from the env file's own location
(`test-session-loop-notify.sh` N4; doc paragraph corrected);
`scripts/import-session-seq.sh` + `test-import-session-seq.sh` (26 asserts)
on a throwaway item. All suites green before commit. **Chain ended:** this
session staged no successor; closing it by hand with nothing staged makes the
old supervisor (pid 72900) log a deliberate quit and exit 0. Nothing pushed.

**Decisions.** Record file `session-state.json` with `schema: 1`; import
compares rather than consumes the counter; notify path via `BASH_SOURCE`
(decisions.md 2026-09-16).

**Learnings:**
- macOS has no `timeout`; a suite loop wrapped in it reports rc=127 for every
  suite and looks like a run. Check the per-suite rc line before trusting it.
- macOS 15+ ships `/usr/bin/jq`, so a "jq absent" test needs a PATH built
  without it, not just a bare PATH.
- Tickets + phase 0 + bookkeeping fit one session (WARN at ~125K) only
  because the big scripts were grepped, never read.

**Open / next.** User direction after the session summary (2026-09-17): plan
the remaining phases as a dependency graph and execute them in parallel with
a fleet of agents. Then: one wave per session, rolling over through the LIVE
supervisor (chain kept; `main` frozen, waves on `stage4`). Session 11: mark phase 0 `done`, write `plans/fleet-plan.md` (waves
1∥2 → 3 → 4∥6 → 5 → 7 → 8 → cutover), get the go, launch wave A.

# Session Handoff — 9 (2026-09-15/16): Stage 4 planned (Part 4) and ACCEPTED; tracker in place; rollover at WARN

**Summary.** Republished design v2 page (version 2) with D1–D3 shown as
settled. User gave the go for Stage 4. One Plan agent drafted **Part 4**
(findings file line 765, ~80 lines): 9 phases + cutover, each a vertical slice
with its proving test, touches/deletes, session estimate 18 likely / 15–19
range (10–12 if phase tasks are delegated to subagents). Session review
applied three corrections (`/clear` rotation already probed in Stage 2 →
ADR close-out in phase 8; clear-seed hook + `.pending-clear-seed` deleted in
phase 4; ADR promotion added to phase 8). Created **`stage4-tracker.md`**
("Now" line + per-phase row: status/est/used/commit) and README pointers.
Decision note on plan shape appended. Committed 07a47bb. **User accepted
Part 4** ("Part 4 is approved") and asked to roll over now. Nothing pushed.

**Decisions.** User: Stage 4 go; Part 4 accepted. Session: phase-level plan
+ just-in-time `plans/phase-<n>.md` + tracker (decisions.md 2026-09-15).

**Learnings:**
- Republishing an owned artifact: `Artifact read` returns the raw HTML; the
  previous session's scratchpad copy was byte-equivalent, so patch + republish
  cost ~10K. Don't rebuild pages from markdown when a local copy exists.
- A ~1K-word Part 4 append plus its scaffolding pushed the parent from 93K to
  129K; a plan-writing session should not also publish a page.
- The Plan agent's draft was factually right about the scripts but re-opened a
  question already closed by probe evidence — verify "open item" claims against
  the ledger before accepting a plan.

**Open / next.** `/to-tickets` on Part 4; then phase 0. Supervisor pid 72900
still live on the old loop script: session 10 is the interactive pause where
the chain is ended deliberately (quit with nothing staged) as phase 0's first
step; session 11 onward is started by hand until cutover.

# Session Handoff — 8 (2026-09-15): Stage 3 done (Part 3) + readable design v2; awaiting 3 user decisions and go for Stage 4

**Summary.** Opened by presenting the Part 2 review page. The user's review
findings were about the document, not the design: too long; too much internal
jargon; must be readable independent of the workspace; introduce concepts with
diagrams or simple explanations. On the user's "go", Stage 3 ran as three
parallel reviewers (planned two + a developer/implementer lens, added because
the user asked whether a developer had reviewed it): architect, scenario/flow,
developer — reports `evaluation/stage3-{architect-review,scenario-evaluation,
developer-review}.md` (108/148/107 lines; 121K/132K/130K agent tokens). All
three: sound with amendments. A fork synthesized **Part 3** (findings file
line 688, 76 lines) and rewrote the design as **`evaluation/stage3-design-v2.md`**
(158 lines, 4 mermaid diagrams, 12-term glossary, no ID codes in the body,
three DECISION items in place). Part 2 left untouched (deviation from the
launcher's "edit in place", recorded in the commit trailer). Committed 2dc0d6e.
Design v2 published as a private page: https://claude.ai/artifact/2VMbASSbqw1JN4JTeC9jrb. Nothing pushed.

**Decisions.** User: Stage 3 go with three reviewers + simplicity mandate
(decisions.md 2026-09-15). Consensus adopted into v2 (not yet user-accepted):
`--bg` launch path deleted; verdict rewritten on `launch.predecessor`; prep/
verify verbs replaced by inline launcher checks + `--check`; `opts-sync`
deleted; pid liveness sole oracle; WARN asks iff relaunch manual/off; unread
record fields and ~a third of reason codes cut. Open for the user (v2 §
"Decisions needed"): D1 logout code path on codex/copilot (rec: drop), D2
resumed predecessor after staging (rec: occupation rule, no number spent),
D3 copilot/gemini identity heuristic (rec: accept).

**Learnings:**
- The user reads deliverables only if short, plain, self-contained, and
  diagram-led; saved as memory `review-docs-plain-language`. Every future
  user-facing doc here: one-page summary first, glossary, pointers as footnotes.
- All three reviewers independently found the same (b)/(d) contradiction
  (bump nulls `session`, verdict reads it) — a single design agent misses
  cross-section consistency; parallel lenses catch it.
- Fork-synthesis kept the parent under WARN: parent read only the three
  summaries + design v2; the fork read the 363 report lines.

**Open / next.** User decides D1–D3 and gives the go for Stage 4
(implementation plan, Part 4). Precondition for any code: decision 12 (end
supervisor pid 72900 at its next interactive pause) — still live on old code.

# Session Handoff — 7 (2026-09-14): Stage 2 design drafted (Part 2); awaiting user review

**Summary.** Ran the two authorised probes (one agent, isolated temp dir with its
own hook config; report `evaluation/stage2-probes.md`): **V2 = ROTATES** —
`/clear` fires SessionEnd(reason=clear) then SessionStart(source=clear) with a
new session id and a new transcript JSONL, the old file frozen; **`claude --bg`
env = SURVIVES-ONLY-IF-THE-LAUNCH-SPAWNS-THE-DAEMON** — the var reaches the hook
on a cold start, but a second `--bg` 40 s later replayed the first launch's
stale value (daemon pre-forks spares from the spawning caller's env). So
`--clear` stays (ADR-0009 amended, open item closed) and the handshake file is
NOT retired (launcher line ~1184's rationale is mis-stated, the mechanism is
right). Then one general-purpose agent drafted **Part 2** (sections a–m per
the launcher) from the architect's §7(d) seed + the 17 accepted decisions +
§1b.7; appended to `session-management-review-findings.md` (lines 371–679;
source copy `evaluation/stage2-design-part2.md`). Status header updated. No
scripts, skills, docs or ADRs touched; nothing pushed.

**Decisions.** None new by the user this session. The design proposes (for
review, not decided): 7 kept concepts; record field owners launcher→`seq`/
`launch`/`staged`, context-budget.sh→`session`/`options`, session-loop.sh→
`chain`; `--clear` kept; handshake relocated into `launch.pending` + a
`pending_elsewhere` refusal; support matrix claude supported (attended +
supervised), codex/copilot-CLI unverified, gemini attended-unverified /
supervised-unsupported; ADR-0010/0011/0012 proposals.

**Learnings:**
- Probe cost 91K agent tokens / 8 min; design agent 232K / 11.5 min. Parent
  stayed under WARN by reading only headers + agent summaries.
- `/clear` transcript caveats for measurement: filter records by camelCase
  `sessionId` (snake_case `session_id` on some new-file records is stale);
  the `/clear` command record lands in the NEW file; no transcript is written
  when `CLAUDE_CODE_CHILD_SESSION` is inherited (probe needed `env -u`).
- `tmux` is not installed on this machine; `expect` drove the TUI fine.

**Review artifact (session 7, after commit eab995a).** Part 2 + the probe
appendix published as a private claude.ai page for the user's review:
https://claude.ai/artifact/4KeTb5seRPdSS8AtEKQmmV (title "Session Redesign
Part 2"; 13 sections a–m + appendix; source HTML in the session scratchpad,
not in the repo). Rolled over at WARN (137K) on the user's instruction; the
successor opens by presenting the URLs and answers review questions
(`--loop-mode interactive`).

**Open / next.** User reviews Part 2. On go: Stage 3 (fresh architect +
scenario/flow agents over the design, verdicts → Part 3). Part 2 §(m) lists 5
open questions for Stage 3. Supervisor pid 72900 hazard unchanged (decision 12).

# Session Handoff — 6 (2026-09-14): Stage 1 evaluation done and accepted; process re-sequenced to four stages

**Summary.** Started on the launcher's "write Part 2 (the plan)" and dispatched
three Plan agents; the user redirected mid-turn: update from origin (already
current — PRs #54–#60 were merged in session 5; origin had nothing new), then
**no implementation planning until the suggested changes are reviewed and
evaluated**. Stopped the Plan agents, ran three evaluation agents instead
(re-evaluation of F1–F10/S1–S10 against current main; independent architect
review of D-A..D-G; scenario + flow evaluation vs S1–S10, E/I catalog, three
loops). Synthesized as **Part 1b** in `session-management-review-findings.md`;
full reports in `evaluation/stage1-*.md`. User then set the process to four
stages (research/evaluate → design/architecture → evaluate the design vs
scenarios/flows + architect → plan implementation), added the binding
constraint **reliable/repeatable/reproducible without trusting the agent**
(§1b.7 + Tier-2 note in decisions.md), and **accepted all 17 recommendations
in §1b.5**. Committed Stage 1; rolled at WARN.

**Decisions (user, 2026-09-14).** Four-stage process (findings status header);
§1b.5 decisions 1–17 all accepted as recommended (three record writers with
field ownership; never reclaim numbers; orphan → abandoned + N+1; pid liveness;
run V2 before deciding `--clear`; delete both mode markers; keep `--takeover`;
chain budget its own block; Copilot = CLI; Gemini attended-only; fleet →
`scripts/fleet.sh`, delete `watch`, drop child-lock hierarchy; end the
pid-72900 chain before editing `session-loop.sh` + `main "$@"` wrapper first;
log text free-form, `reason=<code>`; D-F = escalation-time append; template
defaults manual / KILL_AFTER=0 / jq req; record gitignored with `user`;
authorise the `--bg` env probe). Tier-2 note written for the reliability
constraint (Promote?: maybe).

**Learnings:**
- The three evaluation agents cost 223K / 359K / 357K tokens and returned
  ≤600-word summaries + 165–282-line reports; the parent stayed under WARN only
  by reading the summaries and one section of one report. Same shape next time.
- Nothing in PRs #54–#60 invalidated a finding; #60 re-added an inference
  mechanism (F2 got worse). `docs/session-chain-scenarios.md` and
  `work/session-loop-hardening/` are cited but do not exist here.
- **Live hazard:** supervisor pid 72900 started before a213b3d changed
  `session-loop.sh` under it (bash reads by offset); it left an orphan
  `.next-command.json`. This rollover still goes through it (no edits to that
  file were made). End the chain deliberately before touching that file.
- `rollover-prep.sh` takes `<project>` before `--reason`; the launcher's
  "First actions" line had the order right, my first call did not.

**Open / next.** Stage 2 = write the design and architecture (Part 2). See
next-session.md. Counter: `seq-sync` noop expected (launcher started this
session as #6).

**Suggested skills.** Fresh `Agent` (general-purpose) to draft the design from
the architect's §7(d) seed + accepted decisions; then Stage 3 = architect +
scenario agents on the design; `decision` for anything new.

# Session Handoff — 5 (2026-09-14): L46 shipped; session-management review findings done, rolled at WARN before the plan

**Summary.** Item was closed; user reopened it with a new request. (1) Found
and fixed **L46**: session-loop round-2 runtime files (`.session-seq.bump.json`,
`.session-loop.budget`, `.session-loop.alarm-stop`) were never gitignored —
`8d2d542`, card archived, scorecard 0/88/4/0/6, main pushed by user earlier
(was 0 ahead; now 1 ahead). (2) User asked for a **holistic review of the
session-management / context-budget / multi-session subsystem** (context decay,
session-loop, launch-next-session, context tracking): findings → plan →
execution. Ran three parallel Explore agents (internals; operating model +
DevX; git history + incident evidence), spot-checked the load-bearing claims,
and wrote the findings to `session-management-review-findings.md` (this dir;
mirror of the plan-mode file `~/.claude/plans/now-what-i-want-cheerful-tide.md`).
User reviewed the findings and gave direction (§5 of that file). Rolled at WARN
(~125K) before the plan phase, at the user's choice. Session ran in **plan
mode** (read-only) throughout the review.

**Decisions (user, 2026-09-14).** Appetite = cleanup **and** structural
redesign (single launcher-owned per-session lifecycle record). Runtimes
first-class = Claude, Codex, GitHub Copilot, Gemini; opencode/others folded in
only if cheap, else follow-up. Fleet dispatch machinery = **keep**; user asks
how best to maintain it (plan must answer). No Tier-2 note yet — these are
scope choices for a plan not yet written; capture as Tier-2 when the plan
lands.

**Learnings:**
- The three review agents cost ~135–195K tokens each but returned dense
  ~2.5K-word reports; running them in parallel from a fresh-ish session was the
  right shape — the parent still hit WARN from reading the reports + spot
  checks + writing findings.
- `.pending-clear-seed` is not gitignored (found by the internals agent; not
  fixed — plan-mode session). `SESSION_LOOP_NOTIFY` in `context-budget.env`
  resolves `${ROOT:-.}` differently in its three sourcing sites. ADR-0009's
  "/clear rotates the transcript?" question is still unverified.
- `capture-rollover-options.sh` maps plan mode to `default` approval — fine.

**Open / next.** Successor writes **Part 2 (the plan)** per §6 of the findings
file, then presents it for approval; execution planning (tickets / new work
item, likely `session-management-redesign`) follows approval. Uncommitted:
nothing besides this rollover's own files. Supervisor live (pid 72900); this
rollover emitted `--loop-mode interactive` because the plan ends in a
user-approval question.

**Suggested skills.** Plan agents (`Agent` type `Plan`, ≤3, perspectives in
§6); `to-tickets` / `create-work-item` after approval; `decision` for the
scope choices once the plan is accepted.

# Session Handoff — 4 (2026-09-10): L45 probed live, merged to main, item complete (checkpoint)

**Summary.** Live end-to-end probe of L45 via `Agent(isolation: worktree)`:
the `work/learn-agentic-workflows` symlink appeared in the worktree, the
probe write landed in the real directory, `.git/info/exclude` gained the
exact `work/learn-agentic-workflows` line, and the worktree was auto-cleaned
as "unchanged" while the write survived — the exact case the card named.
Result recorded as a bullet in `operational-knowledge.md` (`7a98718`), then
`fix/l45-gitignored-work-dirs` merged into main `--no-ff` (`5fd5480`).
23/23 suites green on merged main; structure + ledger checks clean. Backlog
row and archived card updated with the merge; `work/README.md` status row
flipped to Complete. Local fix branch deleted (merged).

**Decisions.** None new; promotion scan clean (no `Promote?: yes|maybe`).

**Learnings:**
- The worktree's branch is cut from `origin/main`, which predates the fix,
  so it had no `scripts/link-local-work.sh` — yet the link appeared. Hooks
  run the *main checkout's* lib (`CLAUDE_PROJECT_DIR` in the hook wiring;
  the lib's root resolver walks to the git common dir). The fix therefore
  holds in worktrees cut from any base.
- The harness's worktree guard refuses compound `git -C "$PWD" …; pwd`
  commands inside an isolated subagent; single commands pass.

**Open / next.** Item **complete**. Only outstanding: pushing main (13
ahead of `origin/main`) — the user's call, not done. `review.md` §E lists
user-only items. `.claude/worktrees/learn-agentic-workflows-s2` still holds
a stale real copy of that item (by design; delete it to get the link).
`review/template-improvement-review-s1` is merged but not deleted.

**Suggested skills.** None — no successor session planned. If reopened:
`checkpoint` after the push.

# Session Handoff — 3 (2026-09-10): L45 built and committed on a branch; rollover at WARN

**Summary.** Built backlog **L45** test-first in one commit `5f51898` on
`fix/l45-gitignored-work-dirs` (off main `6f8c6c2`; not merged, not pushed).
New `scripts/link-local-work.sh` symlinks every ignored `work/<item>/` from
the main checkout into a git worktree; called unthrottled from the shared
hook lib (all six runtimes' per-tool hooks) and from `context-budget.sh
register`. Suite `test-link-local-work.sh` 30/30; all 22 suites green,
structure + ledger checks clean; guide HTML rebuilt. Card L45 archived,
scorecard 0 open / 87 resolved, change-log row added. Docs:
`work-directory-conventions.md` (local-only items + worktrees),
`operational-knowledge.md` (new entry), `workspace-structure.md` tree line.
Rolled over at WARN (130K).

**Decisions.** Tier-2 note (top of `decisions.md`): share-in by symlink; the
card's "repo guard" does not exist in repo code — the redirect is the
runtime's own worktree isolation — so exemption was impossible, and
copy-back loses the auto-cleaned "unchanged" worktree case.

**Learnings:**
- A `work/<item>/` ignore pattern (trailing slash) matches directories only;
  a symlink at that path shows as `??` in the worktree. The script registers
  the exact path in the shared `.git/info/exclude` after linking.
- Claude Code's Write/Edit tools write through a symlinked *directory*
  (verified in scratchpad); the CONTEXT.md refusal is for symlinked files.
- `work/learn-agentic-workflows` is excluded via `.git/info/exclude`, not
  `.gitignore`; the fix handles both.

**Open / next.** Not yet done: a live end-to-end probe in a real worktree
session (register + hook wiring under Claude Code's isolation), merging the
branch into main, and `checkpoint`. `.claude/worktrees/learn-agentic-workflows-s2`
still holds a stale manual copy of that item — it will stay a real dir (by
design) until deleted. Push of main remains the user's call.

**Suggested skills.** verification-before-completion, checkpoint.
# Session Handoff — 2 (2026-09-10): post-checkpoint — user approval, merged to main, rollover to build L45

**Summary.** After the checkpoint the user approved every request in it
("go build it"). Recorded in `decisions.md` (top note), then the branch was
merged into local main (`0cba137`, --no-ff; main now 7 ahead of origin/main,
**not pushed** — outward-facing, left to the user). Rolled over at WARN
(135K) so L45 is built with headroom, not in the dumb zone.

**Current state.** On `main`, clean tree, suites green at the branch tip
(main's tip = that tip + merge commit). Backlog 1 open (L45) / 86 resolved.

**Decisions.** The five build-under-assumption choices stand (user
approval). L45's fix direction is delegated to session 3 after it reads the
repo guard.

**Next.** Session 3 builds L45 per `next-session.md`; then checkpoint or
roll over. Push of main stays the user's call.

**Suggested skills.** brainstorming (briefly, for the L45 direction), tdd,
decision-log, checkpoint.

# Session Handoff — 2 (2026-09-10): review list drained — cards archived, L45 filed, C2–C12 fixed; checkpoint

**Summary.** Mission fully delivered in one commit `39224b8` on
`review/template-improvement-review-s1` (not merged, not pushed — merging is
the user's call); origin/main (PR #44, M38) merged into the branch at
checkpoint, backlog conflicts resolved, M38's missing change-log row added. Suites 21/21 green
(`test-turn-end-exit.sh` skips 4 tty assertions without a controlling
terminal), structure + ledger checks clean.

**Shipped.** M27/M28/M29/L38/L39 flipped Resolved with `Fixed:` lines and
moved to the archive; new card **L45** (gitignored work dirs lost in
worktree-forced background sessions, from A10); scorecard 1 open / 86
resolved (incl. M38 from PR #44); two change-log rows. C2–C12 applied by one subagent pass (see
`review.md` §C, all "done (session 2)"); `skills/vendored-skills.md` also
gained `design-for-testability`. `work/template-maintenance/next-session.md`
carries a supersede note (options-brief walk no longer needed).
`work/README.md` rows for both items updated.

**Decisions.** Commit trailer only: `probe-results.md` citations repointed
to the session-loop spec's "Open questions" table because the file was never
committed (C2c). No new Tier-2 note.

**Open / next.** Nothing left for an agent in this item. Remaining items are
user-only (`review.md` §E) plus: merge this branch; decide L45's fix
direction (guard exemption vs. copy-back); review the five build-under-
assumption choices in `decisions.md`. Item state: **complete pending merge**.

**Learnings:**
- Session 1's "main is 3 ahead of origin" snapshot was stale by session 2:
  local main had been pushed and origin/main had gained PR #44, which also
  edited the backlog files. Run `git fetch && git log main..origin/main` at
  start, before touching the backlog, rather than trusting the launcher's
  branch arithmetic. PR #44 also skipped its change-log row (rule 6 applied).
- The review's C2 claim about `docs/adr/0008:125` was wrong (it cites
  `decisions.md`, a provenance line, not `probe-results.md`); the subagent
  verified before editing, which is the right discipline for stale-line
  findings.

# Session Handoff — 1 (2026-09-10): pooled review written, housekeeping + 5 design-gap cards built

**Summary.** Created this item; surveyed every `work/*` item, the 5 open
backlog cards + options brief, ran a fresh-eyes template review; baseline
and post-change suites all green (21 suites + ledger checker + structure).
Everything landed in one commit `dc1f334` on branch
`review/template-improvement-review-s1` (not merged, not pushed — the
user's global rule is branch-first; merging is their call).

**Shipped.** See `review.md` for the full table. A1–A9 housekeeping done
(work index rows, context-decay ledger path, stale claims, banners, routing
pointers). Built: M27 `skills/design-for-testability` + command + CONTEXT.md
bullet + optional spec heading; M28 `uat.md` slot in
`docs/work-directory-conventions.md`; M29 `docs/postmortems/` + pointers;
L39 posture section in `docs/agents/issue-tracker.md`; L38 routed into
`work/quality-gates/README.md`. Context-decay savings validation run:
verdict negative (`work/context-decay/savings-validation-2026-09-10.md`).

**Decisions.** `decisions.md` (build-under-assumptions; ASR seq 31→32).

**Open / next.** Backlog cards M27/M28/M29/L38/L39 still show Open in
`docs/template-workspace-backlog.html` — resolve + archive + scorecard
(5→0 open, 80→85 resolved) is session 2's first job. Then fresh-eyes fixes
C2–C12 and the new A10 card. Successor's session-2 preamble was written
by session 1 (ad-hoc start: counter `created` at 1 this session).

**Suggested skills.** decision-log (if any new choice), checkpoint at end.

**Learnings:**
- Subagent survey claimed an unmerged `feat/clear-in-place-rollover`
  branch; disk showed none. Verify branch claims with `git branch -r --no-merged`.
- Fresh-eyes reviewer found `docs/workspace-structure.md`'s docs tree lists
  neither `adr/` nor `postmortems/` (fold into C3).

# Session Handoff — 1 (2026-09-10): scaffolded; pooling open threads

Work item created. Survey of all `work/*` items, the 5 open backlog cards,
the options brief, and a baseline run of every test suite in progress.
Immediate next step: write `review.md`, then start delivering.
