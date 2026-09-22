<!--
PURPOSE: This is the LEDGER (provenance log). Append-only, newest block on
TOP. Each "# Session Handoff" block records what happened in one session.
Read the TOP block only; older blocks are in handoff-archive.md. Forward
"what to do next" belongs in next-session.md, NOT here.
Convention: docs/work-directory-conventions.md.
-->

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

