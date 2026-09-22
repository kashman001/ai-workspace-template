<!--
PURPOSE: This is the LEDGER (provenance log). Append-only, newest block on
TOP. Each "# Session Handoff" block records what happened in one session.
Read the TOP block only; older blocks are in handoff-archive.md. Forward
"what to do next" belongs in next-session.md, NOT here.
Convention: docs/work-directory-conventions.md.
-->

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

